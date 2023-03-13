import type { Handle } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import cross_fetch from 'cross-fetch';
import { GROWTHBOOK_API_URL, GROWTHBOOK_API_KEY } from '$env/static/private';

// vite does not support require, but if we use import it will give TypeError at runtime.
// using workaround for now
import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const { GrowthBook, setPolyfills } = require('@growthbook/growthbook');

setPolyfills({
    // Required for Node 17 or earlier
    fetch: globalThis.fetch || cross_fetch,
    // Required when using encrypted feature flags and Node 18 or lower
    SubtleCrypto: crypto.subtle,
    // Optional, can make feature rollouts faster
    // EventSource: require('eventsource'),
});

export const getGrowthBook = async (trackingCallbackFn = () => {}) => {
    const instance = new GrowthBook({
        apiHost: GROWTHBOOK_API_URL,
        clientKey: GROWTHBOOK_API_KEY,
        trackingCallback: trackingCallbackFn,
    });
    // Clean up at the end of the request
    // Wait for features to load (will be cached in-memory for future requests)
    try {
        await instance.loadFeatures();
    } catch (e) {
        logger.error(
            '[middleware/growthbook/getInstance] Failed to load features from GrowthBook',
            e,
        );
    }
    return instance;
};

export const growthbookHandler = (async ({ event, resolve }) => {
    // trackingCallback: (experiment, result) => {
    //     // TODO: Use metrics counter
    //     logger.log('[middleware/growthbook] Viewed Experiment', {
    //         experimentId: experiment.key,
    //         variationId: result.variationId,
    //     });
    // },

    const clientGB = await getGrowthBook();

    event.locals.growthbook = clientGB;

    const response = await resolve(event);

    event.locals.growthbook?.destroy();

    return response;
}) satisfies Handle;
