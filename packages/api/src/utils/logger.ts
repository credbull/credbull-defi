import { LoggingInterceptor } from '@algoan/nestjs-logging-interceptor';
import { LoggerService } from '@nestjs/common';
import * as Sentry from '@sentry/node';
import { WinstonModule, utilities } from 'nest-winston';
import * as winston from 'winston';

const baseFormats = [winston.format.timestamp(), winston.format.ms()];

const finalFormat =
  process.env.NODE_ENV === 'production' //
    ? winston.format.json()
    : utilities.format.nestLike('api', { colors: true });

export const factory = () => {
  const logger = WinstonModule.createLogger({
    format: winston.format.combine(...baseFormats, winston.format.json()),
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(...baseFormats, finalFormat),
      }),
    ],
  });

  const error = (message: any, ...optionalParams: any[]): any => {
    Sentry.captureException(message);
    return logger.error(message, ...optionalParams);
  };

  return new Proxy(logger, {
    get: (target: LoggerService, prop: keyof LoggerService) => (prop === 'error' ? error : target[prop]),
  });
};

export const logger = factory();

export const interceptor = new LoggingInterceptor({
  mask: { requestHeader: { cookie: true, authorization: true } },
});

(interceptor as unknown as { logger: any }).logger = logger;
