import { registerUser } from '$lib/directus/directusAPI';
import type { PageServerLoad } from './$types';
import { redirect, error, fail } from '@sveltejs/kit';
import type { Actions, RequestEvent } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { z, ZodError } from 'zod';
import { EmailConstraint, PasswordConstraint, ConfirmPasswordConstraint, 
         FirstNameConstraint, LastNameConstraint, RelativeUrlConstraint } from '$lib/validation/auth';

export const load = (async (event: RequestEvent) => {

    const redirectUrl = event.url.searchParams.get("redirectUrl") as string;
    logger.debug(`[/register/+page.server.ts] - redirectUrl: ${redirectUrl}`);

    // do not show page if already signed in
    if (!!event.locals.user) {
        throw redirect(303, redirectUrl ?? '/');
    }

    return {
        redirectUrl,
    }

}) satisfies PageServerLoad;

const schema = z.object({
    firstName: FirstNameConstraint,
    lastName: LastNameConstraint,
    email: EmailConstraint,
    password: PasswordConstraint,
    confirmPassword: ConfirmPasswordConstraint,
    redirectUrl: RelativeUrlConstraint,
})
.refine((data) => data.password === data.confirmPassword, {
    message: "Passwords don't match",
    path: ["confirmPassword"], // path of error
});

export const actions = {
    default: async (event) => {

        logger.debug('[/register/+page.server.ts] - register start');

        const formData = Object.fromEntries(await event.request.formData());
        const directus = event.locals.directus;

        let success = false;
        try {
            logger.debug('[/register/+page.server.ts] - validating form');

            // this can throw a validation error in which case we wont bother
            // sending the request to API
            const result = schema.parse(formData);
            const { firstName, lastName, email, password } = result;

            logger.debug('[/register/+page.server.ts] - calling registerUser');
            const newUser = await registerUser(firstName, lastName, email, password);

            logger.debug('[/register/+page.server.ts] - newUser = ' + newUser);

            if (newUser) {
                const user = await directus.login(email, password);
                if (!!user?.access_token) { 
                    logger.debug('[/register/+page.server.ts] - register success!');
                    success = true;
                }
            } 

        } catch (err: any) {
            if (err instanceof ZodError) {
                logger.debug('[/register/+page.server.ts] - form validation error');

                const { fieldErrors: errors } = err.flatten();
                const { password, confirmPassword, ...rest } = formData;
                                // normal return will return status code 200, frontend code will
                // not be able to retrieve the error for display
                return {
                    status: 400,
                    data: rest,
                    errors,
                };
                // return fail(400, {actionError:'REGISTER_FAILED', actionErrorMessage: 'Sign up failed. Please try again.'});
            }

            // TODO: refactor these to custom Transport from directus/sdk 
            if (!!err.parent?.code && 
                 (err.parent?.code === 'ECONNREFUSED' || err.parent?.code === 'ECONNRESET')
               ) {
                // cannot connect to Directus API
                logger.error('[/login/+page.server.ts/login] - error during login: ' + JSON.stringify(err, null, 2));

                return fail(500, {actionError:'REGISTER_FAILED', actionErrorMessage: 'Error processing user sign up. Please try again later.'});
            }
        }

        // we must do redirect outside the try/catch block
        // see https://github.com/sveltejs/kit/issues/8689
        if (success) {
            const redirectUrl = formData.redirectUrl as string ?? '/';
            logger.debug(`[/register/+page.server.ts] - redirecting to ${redirectUrl}`);
            throw redirect(303, redirectUrl);
        }

        return fail(400, {actionError: 'REGISTER_FAILED', actionErrorMessage: 'Sign up failed. Please try again.'});

    },
} satisfies Actions;
