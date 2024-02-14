import { LoggingInterceptor } from '@algoan/nestjs-logging-interceptor';
import { WinstonModule, utilities } from 'nest-winston';
import * as winston from 'winston';

const baseFormats = [winston.format.timestamp(), winston.format.ms()];

const finalFormat =
  process.env.NODE_ENV === 'production' //
    ? winston.format.json()
    : utilities.format.nestLike('api', { colors: true });

export const factory = () =>
  WinstonModule.createLogger({
    format: winston.format.combine(...baseFormats, winston.format.json()),
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(...baseFormats, finalFormat),
      }),
    ],
  });

export const logger = factory();

export const interceptor = new LoggingInterceptor({
  mask: { requestHeader: { cookie: true } },
});
