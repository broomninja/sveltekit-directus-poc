import { createLogger, transports, format } from 'winston';
import LokiTransport from 'winston-loki';
import { PUBLIC_LOG_LEVEL } from '$env/static/public';

const { combine, timestamp, label, printf, colorize } = format;

const loggerOptions = {
    level: PUBLIC_LOG_LEVEL ?? 'info',
};

const customFormat = printf(({ level, message, timestamp }) => {
    return `[${timestamp}] ${level}: ${message}`;
});

const transportOptions = {
    transports: [
        new transports.Console({
            format: combine(
                timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
                colorize({ all: true }),
                customFormat,
            ),
        }),
    ],
};

export const logger = createLogger({ ...loggerOptions, ...transportOptions });

if (process.env.NODE_ENV === 'production') {
    // logger.add(
    //     new LokiTransport({
    //         host: 'http://127.0.0.1:3100',
    //         labels: { app: 'APP_NAME' },
    //         json: true,
    //         format: format.json(),
    //         replaceTimestamp: true,
    //         onConnectionError: (err) => console.error(err),
    //     }),
    // );
}

//   import createLogger from 'pino';
//   import { PUBLIC_LOG_LEVEL } from '$env/static/public';

//   const loggerOptions = {
//       level: PUBLIC_LOG_LEVEL ?? 'info',
//   };

//   const developmentOptions =
//       process.env.NODE_ENV === 'production'
//           ? {}
//           : {
//                 transport: {
//                     target: 'pino-pretty',
//                     options: {
//                         translateTime: 'SYS:dd-mm-yyyy HH:MM:ss:l',
//                         colorize: true,
//                     },
//                 },
//                 transport: {
//                     target: 'pino-loki',
//                     options: {
//                         host: 'http://localhost:3100',
//                         batching: false,
//                         labels: { application: 'APP_NAME' },
//                     },
//                 },
//             };

//   export const logger = createLogger({ ...loggerOptions, ...developmentOptions });
