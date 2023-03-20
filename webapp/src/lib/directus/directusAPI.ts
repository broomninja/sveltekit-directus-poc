// Handles all non-session based API calls to Directus backend
// This is used on the server side only.
//
// User registration requires specific permissions therefore has to
// be handled by this server instance.
//
// For all *user session* based API calls, please use directusCookieAuth
//

import { logger } from '$lib/utils/logger';
import { Directus } from '@directus/sdk';
import type { ID } from '@directus/sdk';
import { DIRECTUS_API_URL, DIRECTUS_API_TOKEN, DIRECTUS_FRONTEND_USER_ROLE } from '$env/static/private';
import type { TransportResponse } from '@directus/sdk';

const STORAGE_PREFIX = 'webapp_;';

// TODO: move these to types
const DATA_COMPANY = '/items/ddb_company';
const DATA_FEEDBACK = '/items/ddb_feedback';
const DATA_VOTE = '/items/ddb_vote';
const DATA_COMMENT = '/items/ddb_comment';

if (!DIRECTUS_API_TOKEN) {
    throw new Error('Please define SECRET_DIRECTUS_TOKEN in the environment');
}

if (!DIRECTUS_API_URL) {
    throw new Error('Please define DIRECTUS_API_URL in the environment');
} else {
    // logger.debug("Public Directus URL = " + DIRECTUS_API_URL);
}

if (!DIRECTUS_FRONTEND_USER_ROLE) {
    throw new Error('Please define DIRECTUS_FRONTEND_USER_ROLE_ID in the environment');
}

export const directusAPI = new Directus(DIRECTUS_API_URL, {
    auth: {
        staticToken: DIRECTUS_API_TOKEN,
    },
    storage: {
        prefix: STORAGE_PREFIX,
    },
});

// user registration has to be handled by a priviledged API user
// because the webuser has no permission to create an user object
export async function registerUser(
    firstName: string,
    lastName: string,
    email: string,
    password: string,
): Promise<boolean> {
    logger.debug(`[directusAPI.registerUser] - getting role id for ${DIRECTUS_FRONTEND_USER_ROLE}`);

    const result = await directusAPI.roles.readByQuery({
        fields: ['id', 'name'],
        filter: {
            name: {
                _eq: DIRECTUS_FRONTEND_USER_ROLE,
            },
        },
        limit: 1,
    });

    logger.debug(`[directusAPI.registerUser] - got role = ${JSON.stringify(result, null, 2)}`);

    const role = result?.data?.[0] || null;

    if (role) {
        logger.debug(`[directusAPI.registerUser] - creating user using role id: ${role?.id}`);

        const createUserResult = await directusAPI.users.createOne({
            first_name: firstName,
            last_name: lastName,
            email,
            password,
            role: role.id,
        });

        logger.debug(
            `[directusAPI.registerUser] - created user: ${JSON.stringify(
                createUserResult,
                null,
                2,
            )}`,
        );

        return !!createUserResult?.email;
    } else {
        throw new Error('Error loading user role when registering user');
    }
}

// returns a list of Companies which have the most feedbacks.
//
// First sort on companies according to the most number of feedbacks,
// then do second level sorting on the children feedbacks according to the most
// voted by users
export async function getTopCompanies<T = any, R = any>(
    companyLimit: number = -1,
    feedbackLimit: number = -1,
): Promise<TransportResponse<T, R>> {
    logger.debug('[directusAPI.getTopCompanies] - getting all companies ');

    // not using the standard sdk call in 'items' like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers

    // ddb_feedback is the table name for feedbacks but it is also the alias
    // name (used in query below) for the O2M virtual field on the ddb_company
    // table, see directus docs on O2M relationships for more details
    try {
        const { data, headers } = await directusAPI.transport.get(DATA_COMPANY, {
            params: {
                limit: companyLimit, // -1 is get ALL
                sort: ['-count(ddb_feedback)', 'name'],
                alias: {
                    feedback: 'ddb_feedback',
                    author: 'author_id',
                    feedback_count: 'count(ddb_feedback)',
                    voter_count: 'count(m2m_voted_by)',
                    comment_count: 'count(o2m_comment)',
                },
                fields: [
                    'id',
                    'name',
                    'slug',
                    'feedback_count',
                    'feedback.id',
                    'feedback.title',
                    'feedback.content',
                    'feedback.date_created',
                    'feedback.author.first_name',
                    'feedback.author.last_name',
                    'feedback.voter_count',
                    'feedback.comment_count',
                ],
                deep: { 
                    feedback: {
                        _limit : feedbackLimit,
                        _sort: ['-count(m2m_voted_by)', 'date_created'],
                    }
                },
                filter: {
                    status: {
                        _eq: 'active',
                    },
                    _or: [
                        {
                            // companies with zero feedbacks
                            ddb_feedback: { _null: true },
                        },
                        {
                            // companies with one or more feedbacks
                            ddb_feedback: {
                                status: { _eq: 'public' },
                            },
                        },
                    ],
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getTopCompanies] total: ${data?.length} - cache = ${headers['x-directus-cache-status']}`,
        );

        return data;
    } catch (err: any) {
        logger.error(
            `[directusAPI.getTopCompanies] - error getting top companies `,
            err,
        );
    }
    return null;
}


export async function getCompanyBySlug<T = any, R = any>(
    slug: string,
    feedbackLimit: number = -1,
): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getCompanyBySlug] - getting company by slug: ${slug}`);

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers

    // ddb_feedback is the table name for feedbacks but it is also the alias
    // name (used in query below) for the O2M virtual field on the ddb_company
    // table, see directus docs on O2M relationships for more details
    try {
        const { data, headers } = await directusAPI.transport.get(DATA_COMPANY, {
            params: {
                limit: 1,
                alias: {
                    feedback: 'ddb_feedback',
                    feedback_count: 'count(ddb_feedback)',
                },
                fields: [
                    'id',
                    'name',
                    'slug',
                    'feedback_count',
                    'feedback.id',
                    'feedback.title',
                    'feedback.date_created',
                    'feedback.author_id.first_name',
                    'feedback.author_id.last_name',
                ],
                deep: { 
                    feedback: {
                        _limit : feedbackLimit,
                    }
                },
                filter: {
                    slug,
                    status: {
                        _eq: 'active',
                    },
                    _or: [
                        {
                            // companies with zero feedbacks
                            ddb_feedback: { _null: true },
                        },
                        {
                            // companies with one or more feedbacks
                            ddb_feedback: {
                                status: { _eq: 'public' },
                            },
                        },
                    ],
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getCompanyBySlug] - cache = ${headers['x-directus-cache-status']}`,
        );

        const company = data?.[0] || null;

        logger.debug(
            `[directusAPI.getCompanyBySlug] - Found company ID: ${company?.id}`,
        );

        return company;
    } catch (err: any) {
        logger.error(
            `[directusAPI.getCompanyBySlug] - error getting company by slug: ${slug}`,
            err,
        );
    }
    return null;
}

// returns Feedback by ID
export async function getFeedbackById<T = any, R = any>(id: ID): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getFeedbackById] - getting feedback by id: ${id}`);

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers

    try {
        const { data, headers } = await directusAPI.transport.get(DATA_FEEDBACK, {
            params: {
                alias: {
                    voter_count: 'count(m2m_voted_by)',
                },
                fields: [
                    'id',
                    'title',
                    'content',
                    'company_id.id',
                    'company_id.name',
                    'company_id.slug',
                    'author_id.first_name',
                    'author_id.last_name',
                    'voter_count',
                    'date_created',
                ],
                filter: {
                    id,
                    status: { 
                        _eq: 'public' 
                    },
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getFeedbackById] - cache = ${headers['x-directus-cache-status']}`,
        );

        const feedback = data?.[0] || null;
        return feedback;
    } catch (err: any) {
        logger.error(`[directusAPI.getFeedbackById] - error getting feedback by id: ${id}`, err);
    }
    return null;
}

// returns the vote id if user has already voted for the given feedback
export async function getUserVoteByUserIdFeedbackId(userId: ID, feedbackId: ID): Promise<boolean> {
    logger.debug(
        `[directusAPI.getUserVoteByUserIdFeedbackId] - checking if user ${userId} has voted for ${feedbackId} already`,
    );

    try {
        const { data, headers } = await directusAPI.transport.get(DATA_VOTE, {
            params: {
                fields: ['id'],
                filter: {
                    voted_for: feedbackId,
                    voted_by: userId,
                },
            },
        });

        logger.debug(`[directusAPI.getUserVoteByUserIdFeedbackId - vote record number = ${data?.length}`);

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getUserVoteByUserIdFeedbackId] - cache = ${headers['x-directus-cache-status']}`,
        );

        return data?.[0] ?? null;
    } catch (err: any) {
        logger.error(
            `[directusAPI.getUserVoteByUserIdFeedbackId] - error in getUserVoteByUserIdFeedbackId user id: ${userId} for feedback ${feedbackId}`,
            err,
        );
    }
    return null;
}

// returns a list of Votes for a given feedback
export async function getVotesByFeedbackId<T = any, R = any>(
    feedbackId: ID,
    limit: number = -1,
): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getVotesByFeedbackId] - getting votes by feedback id: ${feedbackId}`);

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers
    try {
        const { data, headers } = await directusAPI.transport.get(DATA_VOTE, {
            params: {
                limit,
                fields: [
                    'id',
                    'voted_for',
                    'date_created',
                    'voted_by.id',
                    'voted_by.first_name',
                    'voted_by.last_name',
                ],
                filter: {
                    voted_for: {
                        _eq: feedbackId,
                    },
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getVotesByFeedbackId] - cache = ${headers['x-directus-cache-status']}`,
        );

        return data;
    } catch (err: any) {
        logger.error(
            `[directusAPI.getVotesByFeedbackId] - error getting votes by feedback ${feedbackId}`,
            err,
        );
    }
    return null;
}

// returns Vote by ID
export async function getVoteById<T = any, R = any>(id: ID): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getVoteById] - getting vote by id: ${id}`);

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers

    try {
        const { data, headers } = await directusAPI.transport.get(DATA_VOTE, {
            params: {
                fields: [
                    'id',
                    'voted_for',
                    'voted_by',
                    'date_created',
                ],
                filter: {
                    id,
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getVoteById] - cache = ${headers['x-directus-cache-status']}`,
        );

        const vote = data?.[0] || null;
        return vote;
    } catch (err: any) {
        logger.error(`[directusAPI.getVoteById] - error getting vote by id: ${id}`, err);
    }
    return null;
}


// returns a list of Comments for a given feedback
export async function getCommentsByFeedbackId<T = any, R = any>(
    feedbackId: ID,
    limit: number = -1,
): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getCommentsByFeedbackId] - getting comments by feedback id: ${feedbackId}`);

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers
    try {
        const { data, headers } = await directusAPI.transport.get(DATA_COMMENT, {
            params: {
                limit,
                fields: [
                    'id',
                    'content',
                    'date_created',
                    'author_id.id',
                    'author_id.first_name',
                    'author_id.last_name',
                ],
                filter: {
                    feedback_id: {
                        _eq: feedbackId,
                    },
                    status: {
                        _eq: 'active',
                    },
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getCommentsByFeedbackId] - cache = ${headers['x-directus-cache-status']}`,
        );

        return data;
    } catch (err: any) {
        logger.error(
            `[directusAPI.getCommentsByFeedbackId] - error getting comments by feedback ${feedbackId}`,
            err,
        );
    }
    return null;
}


// returns a list of feedbacks for a given company
export async function getFeedbacksByCompanySlug<T = any, R = any>(
    companySlug: string,
    limit: number = -1,
    page: number = 1,
    sortBy: string = 'NEWEST',
): Promise<TransportResponse<T, R>> {
    logger.debug(`[directusAPI.getFeedbacksByCompanySlug] - getting feedbacks for company: ${companySlug}`);

    // TODO: move constants to types 
    let sortParams;
    switch (sortBy) {
        case 'NEWEST': 
            sortParams = ['-date_created'];
            break;
        case 'MOST_COMMENTED': 
            sortParams = ['-count(o2m_comment)', 'date_created'];
            break;
        case 'MOST_VOTED': 
            sortParams = ['-count(m2m_voted_by)', 'date_created'];
            break;
        default:
            logger.error(`[directusAPI.getFeedbacksByCompanySlug] - Unknown sortBy ${sortBy}`);
            return null;    
    }

    // not using the standard sdk call in items like:
    //    directusAPI.items('ddb_company').readByQuery( { params: {...} })
    // because we want to capture the response headers
    try {
        const { data, meta, headers } = await directusAPI.transport.get(DATA_FEEDBACK, {
            params: {
                meta: 'filter_count',  // this represents the count of items satisfiying the filter, but ignore the query limit
                limit,
                page,
                alias: {
                    company: 'company_id',
                    author: 'author_id',
                    voter_count: 'count(m2m_voted_by)',
                    comment_count: 'count(o2m_comment)',
                },
                sort: sortParams,
                fields: [
                    'id',
                    'title',
                    'content',
                    'date_created',
                    'author.id',
                    'author.first_name',
                    'author.last_name',
                    'company.id',
                    'company.name',
                    'company.slug',
                    'voter_count',
                    'comment_count',
                ],
                filter: {
                    status: {
                        _eq: 'public',
                    },
                    company_id: {
                        slug: {
                            _eq: companySlug,
                        },
                        status: {
                            _eq: 'active',
                        },
                    },
                },
            },
        });

        // HIT or MISS cache
        // TODO: add metrics
        logger.debug(
            `[directusAPI.getFeedbacksByCompanySlug] - cache = ${headers['x-directus-cache-status']}`,
        );

        // logger.debug(
        //     `[directusAPI.getFeedbacksByCompanySlug] - first record = ${data[0].id} ${data[0].title}`,
        // );

        // data[0]['filter_count'] = meta?.filter_count;
        // logger.debug(
        //     `[directusAPI.getFeedbacksByCompanySlug] - meta = ${JSON.stringify(data, null, 2)}`,
        // );

        return { data, meta };
    } catch (err: any) {
        logger.error(
            `[directusAPI.getFeedbacksByCompanySlug] - error getting feedbacks for company ${companySlug}`,
            err,
        );
    }
    return null;
}