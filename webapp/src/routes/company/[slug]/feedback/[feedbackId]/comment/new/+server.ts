import { json, type RequestHandler } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { z } from 'zod';
import DOMPurify from 'isomorphic-dompurify';
import { CommentContentConstraint, IdConstraint } from '$lib/validation/feedback';

const schema = z.object({
    content: CommentContentConstraint,
    userId: IdConstraint,
    feedbackId: IdConstraint,
});

//
// Handles creation of comments when replying to a feedback
//
export const POST: RequestHandler = async (event) => {
    const data = await event.request.json();
    const directus = event.locals.directus;
    const userId = data['userId'];
    const content = data['content'];
    const feedbackId = data['feedbackId'];
    const paramFeedbackId = event.params.feedbackId;

    const currentUser = event.locals.user;
    if (!currentUser) {
        return new Response(
            JSON.stringify({
                error: 'UNKNOWN_USER',
                errorMessage:
                    'Only authenticated user is allowed perform this action. Please login and try again.',
            }),
            { status: 400 },
        );
    }

    // could be stale data being passed in from browser, or probably a bug elsewhere
    if (currentUser.id !== userId) {
        logger.error(
            `[/feedback/[feedbackId]/comment/new] User id mismatch: current user ${currentUser.id} and userId ${userId}`,
        );

        return new Response(
            JSON.stringify({
                error: 'UNKNOWN_USER',
                errorMessage: 'User ID does not match with authenticated user.',
            }),
            { status: 400 },
        );
    }

    // this condition should not exist
    if (paramFeedbackId !== feedbackId) {
        logger.error(
            `[/feedback/[feedbackId]/comment/new] Feedback id mismatch: param ${paramFeedbackId} and feedbackId ${feedbackId}`,
        );

        return new Response(
            JSON.stringify({
                error: 'UNKNOWN_FEEDBACK',
                errorMessage: 'Feedback ID does not match with URL parameter.',
            }),
            { status: 400 },
        );
    }

    const validation = schema.safeParse(data);

    if (!validation.success) {
        return new Response(
            JSON.stringify({
                error: 'VALIDATION_FAILED',
                errorMessage: 'Please check your content and try again.',
            }),
            { status: 400 },
        );
    }

    const cleanContent = DOMPurify.sanitize(validation.data.content);

    logger.debug(
        `[/feedback/[feedbackId]/comment/new] creating comment for user ${userId} on feedback ${feedbackId}`,
    );

    const result = await directus.createCommentForFeedback(userId, feedbackId, cleanContent);

    logger.debug(`[/feedback/[feedbackId]/comment/new] createCommentForFeedback result: ${result}`);

    return json({ success: result });
};
