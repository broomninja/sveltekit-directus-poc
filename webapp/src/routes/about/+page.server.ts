import {redirect} from '@sveltejs/kit';
import  type { PageServerLoad } from './$types';

//export const ssr = false;

export const load = (async ({locals}) => {

    return {
        user: locals.user,
    }

}) satisfies PageServerLoad;

