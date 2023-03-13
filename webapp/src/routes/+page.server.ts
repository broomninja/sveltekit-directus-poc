import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getTopCompanies } from '$lib/directus/directusAPI';
import { logger } from '$lib/utils/logger';

export const load = (async ({ locals }) => {
    try {
        
        // load companies sorted by number of feedbacks descendingly,
        // children feedbacks are sorted by voter count descendingly
        const companyLimit = 10;
        const feedbackLimitPerCompany = 8;
        const getCompanies = async () => {
            return await getTopCompanies(companyLimit, feedbackLimitPerCompany);
        };

        // const feedbacks = await getFeedbacks(companies.)

        return {
            user: locals.user,
            companies: getCompanies(),
            feedbackLimitPerCompany,
        };
    } catch (err: any) {
        logger.error('[/+page.server.ts] - ' + err.message);
    }
}) satisfies PageServerLoad;
