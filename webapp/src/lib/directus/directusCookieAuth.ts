import { Directus } from '@directus/sdk';
import type { ID } from '@directus/sdk';
import { DIRECTUS_API_URL } from '$env/static/private';
import type { DirectusUsers } from '$lib/directus/types';
import { logger } from '$lib/utils/logger';
import { CookieStorage } from '$lib/directus/cookieStorage';
import type { Cookies } from '@sveltejs/kit';
import { getUserVoteByUserIdFeedbackId, getVoteById } from './directusAPI';

if (!DIRECTUS_API_URL) {
    throw new Error('Please define DIRECTUS_API_URL in the environment');
}

const DATA_VOTE = 'ddb_vote';
const DATA_COMMENT = 'ddb_comment';
const DATA_FEEDBACK = 'ddb_feedback';

export type AuthError =
    | undefined
    | 'INVALID_PAYLOAD'
    | 'INVALID_OTP'
    | 'INVALID_CREDENTIALS'
    | 'USER_SUSPENDED';

export class DirectusClient {
    private directus;

    constructor(cookies: Cookies) {
        this.directus = new Directus(DIRECTUS_API_URL, {
            storage: new CookieStorage(cookies, { prefix: 'directusCookie_' }),
            auth: { mode: 'json' },
        });
    }

    async login(email: string, password: string) {
        logger.debug(
            `[directusCookieAuth.login] - login begins: ${JSON.stringify(email, null, 2)}`,
        );
        const user = await this.directus.auth.login({ email, password });
        logger.debug(
            `[directusCookieAuth.login] - login returns: ${JSON.stringify(user, null, 2)}`,
        );
        return user;
    }

    async logout() {
        const refresh_token = this.directus.storage.get('auth_refresh_token');
        logger.debug(`[directusCookieAuth.logout] - begins, refresh_token = ${refresh_token}`);
        const user = await this.directus.auth.logout();
        logger.debug(`[directusCookieAuth.logout] - user = ${JSON.stringify(user)}`);
        return user;
    }

    async currentUser() {
        try {
            logger.debug('[directusCookieAuth.currentUser] - begins');
            const token = await this.directus.auth.token;

            logger.debug(`[directusCookieAuth.currentUser] - auth token = ${token}`);
            logger.debug(
                `[directusCookieAuth.currentUser] - auth mode = ${this.directus.auth.mode}`,
            );
            // logger.debug(
            //     '[directusCookieAuth.currentUser] - storage = ' +
            //         JSON.stringify(this.directus.storage, null, 2),
            // );

            const side = typeof window === 'undefined' ? 'server' : 'client';
            // If there's a token but we don't have a user, fetch the user
            // if (!isAuthed && token) {
            if (token) {
                logger.debug(`[directusCookieAuth.currentUser] - fetching user from ${side}`);
                let user = await this.directus.users.me.read(
                    //) as DirectusUsers; //
                    {
                        fields: ['id', 'email', 'first_name', 'last_name', 'role'],
                    },
                );
                const userRole = await this.getRole(user);
                if (!!userRole?.name) {
                    user.role = userRole.name;
                }
                logger.debug('[directusCookieAuth.currentUser] - ends - Auth Success!');
                return user;
            }
        } catch (err: any) {
            logger.info(
                `[directusCookieAuth.currentUser] - ends - NOT AUTHENTICATED: ${err.message}`,
            );
        }
        return null;
    }

    private async getRole(user: any): Promise<any> {
        const role_id = user?.role;
        if (role_id) {
            // TODO: only get the role name field
            return await this.directus.roles.readOne(role_id);
        }
        return null;
    }

    // isLoggedIn() {
    //   const userAccessToken = directusClient.auth.storage.auth_token;
    //   logger.debug("[directusCookieAuth.isLoggedIn] - userAccessToken = " + userAccessToken);
    //   if (userAccessToken != null) {
    //     return true;
    //   } else return false;
    // },

    // returns an error if user has already voted for the same feedback
    async createVote(userId: ID, feedbackId: ID) {
        logger.debug(`[directusCookieAuth.createVote] - ${userId} is voting for ${feedbackId}`);

        if (!userId || !feedbackId) {
            logger.error(`Error saving vote - missing user id ${userId} or feedback id ${feedbackId}`);
            return false;
        }

        try {
            const db_vote = await this.directus.items(DATA_VOTE);

            // first check if the vote already exists for this user/feedback pair
            const existingVote = await getUserVoteByUserIdFeedbackId(userId, feedbackId);
            if (!!existingVote) {
                logger.error(`Error saving vote - vote record exists for user ${userId} and feedback ${feedbackId}`);
                return false;
            }

            const vote = await db_vote.createOne({
                voted_for: feedbackId,
                voted_by: userId,
            });

            return true;
        } catch (err: any) {
            logger.error(
                `[directusCookieAuth.createVote] - Error creating vote for feedback ${feedbackId} by ${userId}`,
                err,
            );
        }
        return false;
    }

    // only the original voter can remove his/her own votes
    async removeVote(userId: ID, feedbackId: ID, voteId: ID) {
        logger.debug(
            `[directusCookieAuth.removeVote] - ${userId} is removing vote for ${feedbackId}`,
        );

        if (!userId || !feedbackId || !voteId) {
            logger.error(`Error removing vote - missing user id ${userId} or feedback id ${feedbackId} or vote id ${voteId}`);
            return false;
        }

        try {
            // cannot use the normal sdk call directus.items(collection).readOne(voteId) 
            // because Directus will return 403 Forbidden when an ID does not exist
            // in the collection, mainly for security reasons.
            // see https://github.com/directus/directus/discussions/15295#discussioncomment-3511591
            const vote = await getVoteById(voteId);

            logger.debug(
                `[directusCookieAuth.removeVote] - vote to be removed: ${JSON.stringify(
                    vote,
                    null,
                    2,
                )}`,
            );

            if (!vote) {
                throw new Error(`Vote record not found for ID: ${voteId}`);
            }

            if (userId !== vote?.voted_by) {
                throw new Error(`Only original voter can remove his/her votes: check userId ${userId} and votedBy ${vote?.voted_by}`);
            }
            
            const db_vote = await this.directus.items(DATA_VOTE);
            await db_vote.deleteOne(voteId);
            logger.debug('[directusCookieAuth.removeVote] - vote removed');

            return true;

        } catch (err: any) {
            logger.error(
                `[directusCookieAuth.removeVote] - Error removeVote vote for feedback ${feedbackId} by ${userId}`,
                err,
            );
        }
        return false;
    }

    // create a comment for a given feedback
    async createCommentForFeedback(userId: ID, feedbackId: ID, content: string) {
        logger.debug(`[directusCookieAuth.createCommentForFeedback] - author ${userId} for feedback ${feedbackId}`);
        
        if (!userId || !feedbackId || !content) {
            logger.error(`Error creating comment - missing user id ${userId} or feedback id ${feedbackId} or empty content`);
            return false;
        }

        try {
            const db_comment = await this.directus.items(DATA_COMMENT);
            const comment = await db_comment.createOne({
                author_id: userId,
                feedback_id: feedbackId,
                content,
            });

            return true;
        } catch (err: any) {
            logger.error(
                `[directusCookieAuth.createCommentForFeedback] - Error creating comment for feedback ${feedbackId} by ${userId}`,
                err,
            );
        }
        return false;
    }

    // allow comment to be created when replying to another comment (max 1 level)
    async createCommentForComment(userId: ID, commentId: ID, content: string) {
        logger.debug(`[directusCookieAuth.createCommentForComment] - author ${userId} for feedback ${feedbackId}`);
        
        if (!userId || !commentId || !content) {
            logger.error(`Error creating comment - missing user id ${userId} or feedback id ${feedbackId} or empty content`);
            return false;
        }

        try {
            const db_comment = await this.directus.items(DATA_COMMENT);
            const comment = await db_comment.createOne({
                author_id: userId,
                feedback_id: commentId,
                content,
            });

            return true;
        } catch (err: any) {
            logger.error(
                `[directusCookieAuth.createCommentForComment] - Error creating comment for feedback ${feedbackId} by ${userId}`,
                err,
            );
        }
        return false;
    }


    // create a feedback for a company
    async createFeedback(userId: ID, companyId: ID, title: string, content: string) {
        logger.debug(`[directusCookieAuth.createFeedback] - author ${userId} for company ${companyId}`);
        
        if (!userId || !companyId || !title || !content) {
            logger.error(`Error creating feedback - missing user id ${userId} or company id ${companyId} or empty title/content`);
            return false;
        }

        try {
            const db_feedback = await this.directus.items(DATA_FEEDBACK);
            const feedback = await db_feedback.createOne({
                author_id: userId,
                title,
                company_id: companyId,
                content,
            });

            return true;
        } catch (err: any) {
            logger.error(
                `[directusCookieAuth.createCommentForFeedback] - Error creating feedback for company ${companyId} by ${userId}`,
                err,
            );
        }
        return false;
    }

}
