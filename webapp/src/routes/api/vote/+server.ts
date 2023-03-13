import { json, type RequestHandler } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';

// /api/vote GET

export const GET: RequestHandler = async (event) => {
    const options: ResponseInit = {
        status: 418,
        headers: {
            X: 'not-valid-request',
            'Content-Type': 'application/json',
        },
    };
    return new Response(JSON.stringify({ success: false }), options);
};

// /api/vote POST

export const POST: RequestHandler = async (event) => {
    const data = await event.request.json();
    const directus = event.locals.directus;
    const action = data['action'];
    const userId = data['userId'];
    const feedbackId = data['feedbackId'];
    const voteId = data['voteId'];

    const currentUser = event.locals.user;
    if (!currentUser) {
        return new Response(
            JSON.stringify({ error: 'UNKNOWN_USER', errorMessage: 'Only authenticated user is allowed perform this action. Please login and try again.' }),
            { status: 400 },
        );
    }

    // could be stale data being passed in from browser, or probably a bug elsewhere
    if (currentUser.id !== userId) {
        logger.error(
            `[/api/vote] User id mismatch: current user ${currentUser.id} and userId ${userId}`,
        );

        return new Response(
            JSON.stringify({
                error: 'UNKNOWN_USER',
                errorMessage: 'User ID does not match with authenticated user.',
            }),
            { status: 400 },
        );
    }

    let result;

    switch (action) {
        case 'createVote':
            logger.debug(`[/api/vote] Saving vote for user ${userId} on feedback ${feedbackId}`);
            result = await directus.createVote(userId, feedbackId);
            logger.debug(`[/api/vote] createVote result: ${result}`);
            break;

        case 'removeVote':
            logger.debug(`[/api/vote] Removing vote for user ${userId} on feedback ${feedbackId}`);
            result = await directus.removeVote(userId, feedbackId, voteId);
            logger.debug(`[/api/vote] removeVote result: ${result}`);
            break;

        default:
            logger.warn(`[/api/vote] Unknown action ${action}`);

            return new Response(
                JSON.stringify({
                    error: 'UNKNOWN_ACTION',
                    errorMessage: `Action ${action} is not recognised.`,
                }),
                { status: 500 },
            );
    }

    return json({ success: result });
};
