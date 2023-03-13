import type { PageServerLoad } from '../$types';
import type { Actions, RequestEvent } from '@sveltejs/kit';
import { redirect, error, fail } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { getCompanyBySlug } from '$lib/directus/directusAPI';
import { z } from 'zod';
import DOMPurify from 'isomorphic-dompurify';
import { TitleConstraint, FeedbackContentConstraint, IdConstraint, SlugConstraint } from '$lib/validation/feedback';

//
// Create a new feedback for a company
//

export const load = (async ({ locals, params, url }) => {
    const slug = params.slug;

    logger.debug('[/company/slug/feedback/new/+page.server.ts] loading company slug: ' + slug);

    let user = locals.user;

    // do not show new feedback form if user is not signed in
    if (!user) {
        throw redirect(303, `/login?redirectUrl=${url.pathname}` );
    }

    try {
        // we do not need the existing feedbacks for this
        const feedbackLimit = 0;
        const getCompany = async () => {
            return await getCompanyBySlug(slug, feedbackLimit);
        };
        
        return {
            user,
            company: getCompany(),
        };
    } catch (err: any) {
        logger.error('[/company/slug/feedback/new/+page.server.ts] - ' + err.message);
    }
}) satisfies PageServerLoad;

const schema = z.object({
    title: TitleConstraint,
    content: FeedbackContentConstraint,
    userId: IdConstraint,
    companyId: IdConstraint,
    companySlug: SlugConstraint,
});

export const actions = {
    createFeedback: async (event) => {
        logger.debug('[/company/slug/feedback/new/createFeedback] - start');

        // const data = await event.request.json();
        const data = await event.request.formData();

        const formData = Object.fromEntries(data);
        const directus = event.locals.directus;

        const userId = formData['userId'];
        const companyId = formData['companyId'];
        const companySlug = formData['companySlug'];

        // logger.debug(`[/company/slug/feedback/new/createFeedback] - formData ${JSON.stringify(formData,null,2)}`);

        const currentUser = event.locals.user;
        if (!currentUser) {
            return new Response(
                JSON.stringify({
                    error: 'UNKNOWN_USER',
                    errorMessage:
                        'Only authenticated user is allowed perform this action. Please login and try again.',
                }),
                { status: 400 },
            );
        }
    
        // could be stale data being passed in from browser, or probably a bug elsewhere
        if (currentUser.id !== userId) {
            logger.error(
                `[/company/slug/feedback/new/createFeedback] User id mismatch: current user ${currentUser.id} and userId ${userId}`,
            );
    
            return new Response(
                JSON.stringify({
                    error: 'UNKNOWN_USER',
                    errorMessage: 'User ID does not match with authenticated user.',
                }),
                { status: 400 },
            );
        }
        
        const validation = schema.safeParse(formData);
    
        if (!validation.success) {
            return new Response(
                JSON.stringify({
                    error: 'VALIDATION_FAILED',
                    errorMessage: 'Please check your content and try again.',
                }),
                { status: 400 },
            );
        }

        const cleanTitle = DOMPurify.sanitize(validation.data.title);
        const cleanContent = DOMPurify.sanitize(validation.data.content);
    
        logger.debug(
            `[/company/slug/feedback/new/createFeedback] creating feedback for user ${userId} on company ${companyId}}`,
        );
    
        const result = await directus.createFeedback(userId, companyId, cleanTitle, cleanContent);
    
        logger.debug(`[/company/slug/feedback/new/createFeedback] createFeedback result: ${result}`);
    
        // return to the corresponding company page

        // we must do redirect outside the try/catch block
        // see https://github.com/sveltejs/kit/issues/8689
        if (result) {
            const redirectUrl = `/company/${companySlug}`; 
            logger.debug(`[/company/slug/feedback/new/createFeedback] - redirecting to ${redirectUrl}`);
            throw redirect(303, redirectUrl);
        }

        return fail(400, {actionError: 'CREATE_FEEDBACK_FAILED', actionErrorMessage: 'Error when creating feedback. Please try again.'});
    },

} satisfies Actions;
