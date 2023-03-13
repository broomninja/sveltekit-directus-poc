import { register } from 'prom-client';
import type { RequestHandler } from '@sveltejs/kit';

export const GET: RequestHandler = async (_request) => {
    const metrics = await register.metrics();

    return new Response(metrics, {
        status: 200,
        headers: {
            'content-type': register.contentType,
        },
    });
};
