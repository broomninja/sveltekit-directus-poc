import { redirect } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import type { Actions, RequestEvent } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

export const load = ((event: RequestEvent) => {
  throw redirect(302, '/');
}) satisfies PageServerLoad;

export const actions: Actions = {
  default: async (event: RequestEvent) => {
    const directus = event.locals.directus;

    // logger.debug("[/logout/+server.ts] - Before, cookies = " + JSON.stringify(cookies.get('sessionid'), null, 2));
    if (directus) {
      // cookies will be cleared by the directus sdk
      const user = await directus.logout();
    } else {
      logger.warn('[/logout POST] - event.locals.directus not defined');
    }
    // logger.debug("[/logout/+server.ts] - After, cookies = " + JSON.stringify(cookies.get('sessionid'), null, 2));

    throw redirect(302, '/');
  },
};
