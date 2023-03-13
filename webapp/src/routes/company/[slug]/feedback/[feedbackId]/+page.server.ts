import type { PageServerLoad } from './$types';
import { logger } from '$lib/utils/logger';
import {
    getFeedbackById,
    getVotesByFeedbackId,
    getUserVoteByUserIdFeedbackId,
    getCommentsByFeedbackId,
} from '$lib/directus/directusAPI';

export const load = (async ({ locals, params, depends }) => {
    const user = locals.user;
    const directus = locals.directus;

    const feedbackId = params.feedbackId;

    logger.debug('[/company/[slug]/feedback/[feedbackId]/+page.server.ts] loading feedback id: ' + feedbackId);

    try {

        // check if user has already voted
        const getUserVote = async () => {
            if (!!user) {
                return await getUserVoteByUserIdFeedbackId(user.id, feedbackId);
            }
            return false;
        };

        const getFeedback = async () => { 
            return await getFeedbackById(feedbackId);
        };

        const voteLimit = 20;
        const getVotes = async () => {
            return await getVotesByFeedbackId(feedbackId, voteLimit);
        };

        const commentLimit = 10;
        const getComments = async () => {
            return await getCommentsByFeedbackId(feedbackId, commentLimit);
        };

        // invalidate will be called to update page.svelte
        depends('app:feedback');

        return {
            user,
            feedback: getFeedback(),
            votes: getVotes(),
            voteLimit,
            userVote: getUserVote(),
            comments: getComments(),
        };
    } catch (err: any) {
        logger.error('[/company/[slug]/feedback/[feedbackId]/+page.server.ts] - ' + err.message);
    }
}) satisfies PageServerLoad;


