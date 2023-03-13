import type { CookieSerializeOptions } from 'cookie';
import type { Cookies } from '@sveltejs/kit';
import { BaseStorage, type StorageOptions } from '@directus/sdk';
import { logger } from '$lib/utils/logger';

const COOKIE_OPTS: CookieSerializeOptions = {
  path: '/',
  httpOnly: true,
  sameSite: 'strict',
  secure: process.env.NODE_ENV === 'production',
};

// Create a new storage class to use with the SDK
// Needed for the SSR to play nice with the SDK
export class CookieStorage extends BaseStorage {
  // private deletedKeys = new Set<string>();
  private cookie: Cookies;

  constructor(private cookies: Cookies, options?: StorageOptions) {
    super(options);
    this.cookie = cookies;
  }

  get(key: string) {
    const value = this.cookie.get(key);
    //logger.debug('[directusCookieAuth.CookieStorage.get] - cookie.get: ' + key + ' = ' + value);
    return value || null;
  }
  set(key: string, value: string) {
    this.cookie.set(key, value, COOKIE_OPTS);
    //logger.debug('[directusCookieAuth.CookieStorage.set] - cookie.set: ' + key + ' = ' + value);
    return value;
  }
  delete(key: string) {
    // Bug in sveltejs/kit, see https://github.com/sveltejs/kit/issues/6792
    //this.cookie.delete(key);
    this.cookie.set(key, '', { ...COOKIE_OPTS, maxAge: 0 });
    //logger.debug('[directusCookieAuth.CookieStorage.delete] - cookie.delete: ' + key);
    return null;
  }
}
