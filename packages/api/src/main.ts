import { VERSION_NEUTRAL, VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';
import helmet from 'helmet';

import { AppModule } from './app.module';
import { logger } from './utils/logger';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const compression = require('compression');

if (process.env.SENTRY_DSN) {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    integrations: [new ProfilingIntegration()],
    tracesSampleRate: 1.0,
    profilesSampleRate: 1.0,
  });
}

(async function bootstrap() {
  const app = await NestFactory.create(AppModule, { logger: false });

  app.useLogger(logger);

  app.enableVersioning({
    defaultVersion: VERSION_NEUTRAL,
    type: VersioningType.HEADER,
    header: 'accept-version',
  });

  app.use(compression());
  app.use(helmet());
  app.enableCors();

  const config = new DocumentBuilder()
    .setTitle('Credbull API')
    .setDescription('Backend api for Credbull services')
    .setVersion(process.env.APP_VERSION!)
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(process.env.APP_PORT!, '0.0.0.0');
})();
