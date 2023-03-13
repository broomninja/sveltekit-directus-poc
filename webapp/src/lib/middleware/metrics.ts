import type { Handle } from '@sveltejs/kit';
import { collectDefaultMetrics, Counter, register } from 'prom-client';

register.clear()
collectDefaultMetrics();

const requests = new Counter({
  name: "app_requests_total",
  help: "Requests made to app server",
  labelNames: ["method", "path"]
});


export const metrics = (async ({ event, resolve }) => {

    requests.inc()
    requests.inc({method: event.request.method, path: event.url.pathname})

    const response = await resolve(event);
    return response;

}) satisfies Handle;