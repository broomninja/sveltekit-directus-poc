import type { Handle } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { building } from '$app/environment';

export const logRequest = (async ({ event, resolve }) => {
    
    const startTime = Date.now();

    const doLogRequest = event.locals.growthbook?.isOn('admin-log-request');

    if (doLogRequest) {
        logger.debug('===================== HOOK BEGIN =====================');
    }
    const response = await resolve(event);

    let clientIP = 'Unknown';
    try {
        if (!building) {
            clientIP = event.getClientAddress();
        }
    }
    catch (e: any) {
        // error could be thrown when request is coming from kit server itself
        logger.warn(`Problem getting client IP: ${e.message}`);
    }

    if (doLogRequest) {
        logger.info({
            startTime: new Date(startTime).toISOString(),
            event: 'response',
            method: event.request.method,
            IP: clientIP,
            url: event.url,
            duration: `${Date.now() - startTime}ms`,
            status: response.status,
        });
        logger.debug('====================== HOOK END ======================\n');
    }

    return response;
}) satisfies Handle;
