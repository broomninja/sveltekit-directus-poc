import type { HandleServerError } from '@sveltejs/kit';
import { authHandler } from '$lib/middleware/auth';
import { metrics } from '$lib/middleware/metrics';
import { growthbookHandler, getGrowthBook } from '$lib/middleware/growthbook';
import { logRequest } from '$lib/middleware/logRequest';
import { logger } from '$lib/utils/logger';
import { sequence } from '@sveltejs/kit/hooks';

// server init
const _serverGB = await getGrowthBook();
logger.debug("[hooks.server.ts] Server initialization done.");

// logRequest - response time logging will be performed by resever proxy in prod
export const handle = sequence(growthbookHandler, logRequest, metrics, authHandler);

export const handleError = (({ error, event }) => {
	const err = error as Error;
    if (err?.message.match(/^Not found:/)) {
		return;
	}
	logger.error({
		event: 'error',
		err: {
			message: err?.message ?? 'Unknown error',
			stack: err?.stack ?? null,
		},
		method: event.request.method,
		url: event.url,
	});

}) satisfies HandleServerError;

// graceful shutdown
process.on('SIGINT', () => process.exit())  // ctrl-C
process.on('SIGTERM', () => process.exit()) // docker stop
