import { json, type RequestHandler } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { getFeedbacksByCompanySlug } from '$lib/directus/directusAPI';
import { null_to_empty } from 'svelte/internal';

//
// Used by /company/[slug] page for fetching feedbacks in different orders
// 
// Also supports 'Load more' feature which is similar to infinite scrolling
// but using a 'Load more' button instead
//

export const GET: RequestHandler = async ({ url }) => {

    logger.debug(`[/api/feedback/+server.ts] param = ${url.searchParams.get('companySlug')}`);
    
    const companySlug = url.searchParams.get('companySlug');
    const feedbackLimit = Number(url.searchParams.get('limit'));
    const page = Number(url.searchParams.get('page'));

    if (!companySlug) {
        return new Response(
            JSON.stringify({ error: 'PARAM_ERROR', errorMessage: 'Missing company slug parameter (companySlug)' }),
            { status: 400 },
        );
    }

    if (!feedbackLimit || feedbackLimit < 0) {
        return new Response(
            JSON.stringify({ error: 'PARAM_ERROR', errorMessage: 'Error in feedback limit parameter (feedbackLimit)' }),
            { status: 400 },
        );
    }

    if (!page || page < 0) {
        return new Response(
            JSON.stringify({ error: 'PARAM_ERROR', errorMessage: 'Error in page parameter (page)' }),
            { status: 400 },
        );
    }

    try {

        logger.debug(`[/api/feedback/+server.ts] loading feedbacks for company slug: ${companySlug}`);

        const getFeedbacksSortByMostVoted = async () => {
            const result = await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'MOST_VOTED');
            //logger.debug(`[/api/feedback/+server.ts] getFeedbacksSortByMostVoted : ${JSON.stringify(result, null, 2)}`);
            return result;
        };
        const getFeedbacksSortByMostCommented = async () => {
            const result = await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'MOST_COMMENTED');
            //logger.debug(`[/api/feedback/+server.ts] getFeedbacksSortByMostCommented : ${JSON.stringify(result, null, 2)}`);
            return result;
        };
        const getFeedbacksSortByNewest = async () => {
            const result = await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'NEWEST');
            //logger.debug(`[/api/feedback/+server.ts] getFeedbacksSortByNewest : ${JSON.stringify(result, null, 2)}`);
            return result;
        };
        
        const response = (await Promise.allSettled([getFeedbacksSortByMostVoted(), 
                                                    getFeedbacksSortByMostCommented(), 
                                                    getFeedbacksSortByNewest()])) as {
			status: string;
			value?: Response;
		}[];

		if (response.filter((val) => val.status !== 'fulfilled').length > 0) {
			throw new Error('Not all getFeedbacks can be fulfilled.');
		}

		const feedbacksMostVoted: any = await response[0].value;
		const feedbacksMostCommented: any = await response[1].value;
		const feedbacksNewest: any = await response[2].value;

        return json({
            feedbacksMostVoted,
            feedbacksMostCommented,
            feedbacksNewest,
        });

    } catch (err: any) {
        logger.error('[/api/feedback/server.ts] - ' + err.message);
    }

    return new Response(
        JSON.stringify({ error: 'ERROR_LOADMORE_FEEDBACK', errorMessage: 'Error loading addition feedbacks from API' }),
        { status: 400 },
    );
};
