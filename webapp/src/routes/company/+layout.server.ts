import type { LayoutServerLoad } from './[slug]/$types';
import { logger } from '$lib/utils/logger';
import { getCompanyBySlug } from '$lib/directus/directusAPI';

export const load: LayoutServerLoad = (async ( { params }) => {

    const slug = params.slug;

    logger.debug('[/company/+layout.server.ts] loading company by slug: ' + slug);

    try {

        // we only need top level company info like name/slug, do not pull feedback data back
        const feedbackLimit = 0;

        const getCompany = async () => {
            return await getCompanyBySlug(slug, feedbackLimit);
        };
        
        return {
            company: getCompany(),
        };
    } catch (err: any) {
        logger.error('[/company/+layout.server.ts] - ' + err.message);
    }

}) satisfies LayoutServerLoad;

