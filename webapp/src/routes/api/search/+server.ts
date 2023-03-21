import { json, type RequestHandler } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { MeiliSearch } from 'meilisearch';
import { MEILI_SEARCH_API_URL, MEILI_SEARCH_API_KEY } from '$env/static/private';
import DOMPurify from 'isomorphic-dompurify';

const searchClient = new MeiliSearch({
    host: MEILI_SEARCH_API_URL,
    apiKey: MEILI_SEARCH_API_KEY,
});

const indexFeedback = searchClient.index('index_feedback');

// /api/search GET

export const GET: RequestHandler = async (event) => {
    const options: ResponseInit = {
        status: 418,
        headers: {
            X: 'not-valid-request',
            'Content-Type': 'application/json',
        },
    };
    return new Response(JSON.stringify({ result: {} }), options);
};

// /api/search POST

export const POST: RequestHandler = async ({ url, request }) => {
    const data = await request.json();
    let query = data['query'] ?? '';

    query = DOMPurify.sanitize(query.trim());

    if (!query || query.trim().length === 0) {
        // do not throw error, simply return empty results
        return json({
            result: {},
            query,
        });
    }

    // logger.debug(`[/api/search] search query: "${query}"`);

    const searchResult = await indexFeedback.search(query);

    // logger.debug(`[/api/search] search result: ${JSON.stringify(searchResult, null, 2)}`);

    return json({
        result: searchResult,
        query,
    });
};
