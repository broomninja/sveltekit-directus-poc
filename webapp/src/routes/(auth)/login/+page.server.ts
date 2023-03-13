import type { PageServerLoad } from './$types';
import { redirect, error, fail } from '@sveltejs/kit';
import type { Actions, RequestEvent } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { z, ZodError } from 'zod';
import { EmailConstraint, PasswordConstraint, RelativeUrlConstraint } from '$lib/validation/auth';

export const load = (async (event: RequestEvent) => {
    const use_usercode = event.locals.growthbook?.isOn('admin-login-with-usercode');
    logger.debug(`[/login/+page.server.ts] - usercode feature on : ${use_usercode}`);
    const redirectUrl = event.url.searchParams.get('redirectUrl') as string;
    logger.debug(`[/login/+page.server.ts] - redirectUrl: ${redirectUrl}`);

    // do not show login page if already signed in
    if (!!event.locals.user) {
        throw redirect(303, redirectUrl ?? '/');
    }

    return {
        redirectUrl,
    };
}) satisfies PageServerLoad;

const schema = z.object({
    email: EmailConstraint,
    password: PasswordConstraint,
    redirectUrl: RelativeUrlConstraint,
});

export const actions = {
    login: async (event) => {
        logger.debug('[/login/+page.server.ts/login] - login start');

        const formData = Object.fromEntries(await event.request.formData());
        const directus = event.locals.directus;

        let success = false;
        try {
            logger.debug('[/login/+page.server.ts/login] - validating form');

            // this can throw a validation error in which case we wont bother
            // sending the request to API
            const result = schema.parse(formData);
            const { email, password } = result;

            logger.debug('[/login/+page.server.ts/login] - calling auth login');
            const user = await directus.login(email, password);

            if (!!user?.access_token) {
                logger.debug('[/login/+page.server.ts/login] - login success!');
                success = true;
            }
        } catch (err: any) {
            if (err instanceof ZodError) {
                logger.debug('[/login/+page.server.ts/login] - form validation error');

                const { fieldErrors: errors } = err.flatten();
                const { password, ...rest } = formData;
                // normal return will return status code 200, frontend code will
                // not be able to retrieve the error for display
                // return {
                //     status: 400,
                //     data: rest,
                //     errors,
                // };
                return fail(400, {
                    actionError: 'LOGIN_FAILED',
                    actionErrorMessage: 'Login failed. Please try again.',
                });
            }

            // TODO: refactor these to custom Transport from directus/sdk
            if (
                !!err.parent?.code &&
                (err.parent?.code === 'ECONNREFUSED' || err.parent?.code === 'ECONNRESET')
            ) {
                // cannot connect to Directus API
                logger.error(
                    `[/login/+page.server.ts/login] - error during login: ${JSON.stringify(
                        err,
                        null,
                        2,
                    )}`,
                );

                return fail(500, {
                    actionError: 'LOGIN_FAILED',
                    actionErrorMessage: 'Error processing user login. Please try again later.',
                });
            }

            // "INVALID_CREDENTIALS" from directus
            if (err.response?.status === 401) {
                // TODO: add metrics so we can implement strategy to stop brute force login attempts
                logger.warn(`[Login] Login failure: ${JSON.stringify(err, null, 2)}`);
            }
        }

        // we must do redirect outside the try/catch block
        // see https://github.com/sveltejs/kit/issues/8689
        if (success) {
            const redirectUrl = (formData.redirectUrl as string) ?? '/';
            logger.debug(`[/login/+page.server.ts/login] - redirecting to ${redirectUrl}`);
            throw redirect(303, redirectUrl);
        }
        return fail(401, {
            actionError: 'LOGIN_FAILED',
            actionErrorMessage: 'Login failed. Please try again.',
        });
    },

    guestlogin: async (event) => {
        logger.debug('[/login/+page.server.ts] - guestlogin');

        const formData = Object.fromEntries(await event.request.formData());
        const directus = event.locals.directus;
        const growthbook = event.locals.growthbook;

        let userCode = formData.userCode as string;

        let email, password;

        const use_usercode = growthbook?.isOn('admin-login-with-usercode');

        if (use_usercode) {
            if (userCode === '00660e128d94f7a2360e7a24096a7541') {
                email = growthbook?.getFeatureValue(
                    'admin-login-with-usercode-user1-email',
                    'MISSING_EMAIL_USER1',
                );
                password = growthbook?.getFeatureValue(
                    'admin-login-with-usercode-user1-password',
                    'MISSING_PASSWORD_USER1',
                );
                logger.debug(
                    `[/login/+page.server.ts/guestlogin] - setting email/password for ${email}`,
                );
            }
            if (userCode === 'c42b36381ec5f053fdae562cd803abfb') {
                email = growthbook?.getFeatureValue(
                    'admin-login-with-usercode-user2-email',
                    'MISSING_EMAIL_USER2',
                );
                password = growthbook?.getFeatureValue(
                    'admin-login-with-usercode-user2-password',
                    'MISSING_PASSWORDUSER2',
                );
                logger.debug(
                    `[/login/+page.server.ts/guestlogin] - setting email/password for ${email}`,
                );
            }
        } else {
            return fail(401, {
                actionError: 'LOGIN_FAILED',
                actionErrorMessage: 'Guest login not allowed.',
            });
        }

        let success = false;
        try {
            logger.debug('[/login/+page.server.ts] - calling auth login');
            const user = await directus.login(email, password);

            if (!!user?.access_token) {
                success = true;
            }
        } catch (err: any) {
            logger.error(
                `[/login/+page.server.ts/guestlogin] - error during login: ${JSON.stringify(
                    err,
                    null,
                    2,
                )}`,
            );
        }

        if (success) {
            const redirectUrl = (formData.redirectUrl as string) ?? '/';
            logger.debug(`[/login/+page.server.ts/guestlogin] - redirecting to ${redirectUrl}`);
            throw redirect(303, redirectUrl);
        }

        return fail(401, {
            actionError: 'LOGIN_FAILED',
            actionErrorMessage: 'Login failed. Please try again.',
        });
    },
} satisfies Actions;
