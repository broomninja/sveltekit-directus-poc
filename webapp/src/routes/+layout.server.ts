import type { LayoutServerLoad } from './$types';
import { logger } from '$lib/utils/logger';

export const load: LayoutServerLoad = (async (event) => {

    return {
        user: event?.locals?.user ?? null,
    };
    
}) satisfies LayoutServerLoad;
