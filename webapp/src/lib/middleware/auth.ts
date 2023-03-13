import type { Handle } from '@sveltejs/kit';
import { DirectusClient } from '$lib/directus/directusCookieAuth';
import { logger } from '$lib/utils/logger';

export const authHandler = (async ({ resolve, event }) => {
  logger.debug("[middleware/auth handleAuth] - event.url.pathname = " + event.url.pathname);
  logger.debug("[middleware/auth handleAuth] - event.request.method = " + event.request.method);

  const auth_token = event.cookies.get('auth_token');
  logger.debug("[middleware/auth handleAuth] - auth token = " + auth_token);

  const directus = new DirectusClient(event.cookies);
  event.locals.directus = directus;

  if (auth_token) {
    const user = await directus.currentUser();
    logger.debug("[middleware/auth handleAuth] - current user = " + JSON.stringify(user));
    if (!!user?.email) {
      event.locals.user = user;
    }
    else {
      event.locals.user = null;
    }
  }

  const response = await resolve(event);

  event.locals.directus = null;

  return response;

}) satisfies Handle;