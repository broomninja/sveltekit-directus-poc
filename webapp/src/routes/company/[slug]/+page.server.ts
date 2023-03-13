import type { PageServerLoad } from './$types';
import { logger } from '$lib/utils/logger';
import { getFeedbacksByCompanySlug } from '$lib/directus/directusAPI';

export const load = (async ({ locals, params }) => {
    const companySlug = params.slug;

    logger.debug(`[/company/slug/+page.server.ts] loading feedbacks for company slug: ${companySlug}`);

    try {
        const feedbackLimit = 4;
        const page = 1;

        // these API calls will run in parallel
        const getFeedbacksSortByMostVoted = async () => {
            return await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'MOST_VOTED');
        };
        const getFeedbacksSortByMostCommented = async () => {
            return await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'MOST_COMMENTED');
        };
        const getFeedbacksSortByNewest = async () => {
            return await getFeedbacksByCompanySlug(companySlug, feedbackLimit, page, 'NEWEST');
        };
        
        return {
            companySlug,
            feedbackLimit,
            feedbacksMostVoted: getFeedbacksSortByMostVoted(),
            feedbacksMostCommented: getFeedbacksSortByMostCommented(),
            feedbacksNewest: getFeedbacksSortByNewest(),
        };
    } catch (err: any) {
        logger.error('[/company/slug/+page.server.ts] - ' + err.message);
    }
}) satisfies PageServerLoad;
