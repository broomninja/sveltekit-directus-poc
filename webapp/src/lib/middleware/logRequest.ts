import type { Handle } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';

export const logRequest = (async ({ event, resolve }) => {
    
    const startTime = Date.now();

    const doLogRequest = event.locals.growthbook?.isOn('admin-log-request');

    if (doLogRequest) {
        logger.debug('===================== HOOK BEGIN =====================');
    }
    const response = await resolve(event);

    if (doLogRequest) {
        logger.info({
            startTime: new Date(startTime).toISOString(),
            event: 'response',
            method: event.request.method,
            url: event.url,
            duration: `${Date.now() - startTime}ms`,
            status: response.status,
        });
        logger.debug('====================== HOOK END ======================\n');
    }

    return response;
}) satisfies Handle;
