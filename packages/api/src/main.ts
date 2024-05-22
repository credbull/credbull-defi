import { VERSION_NEUTRAL, VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import * as Sentry from '@sentry/node';
import { ProfilingIntegration } from '@sentry/profiling-node';
// Adjust path as needed
import helmet from 'helmet';

import { AppModule } from './app.module';
import { logger } from './utils/logger';
import { TomlConfigService } from './utils/tomlConfig';

// eslint-disable-next-line @typescript-eslint/no-var-requires
const compression = require('compression');

// TODO: move this to config
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

  const tomlConfigService = app.get(TomlConfigService);

  app.useLogger(logger);

  app.enableVersioning({
    defaultVersion: VERSION_NEUTRAL,
    type: VersioningType.HEADER,
    header: 'accept-version',
  });

  app.use(compression());
  app.use(helmet());
  app.enableCors();

  //   const client = createClient(config.services.supabase.url, config.env.SUPABASE_SERVICE_ROLE_KEY);

  const docConfig = new DocumentBuilder()
    .setTitle('Credbull API')
    .setDescription('Backend api for Credbull services')
    .setVersion(tomlConfigService.config.api.version!)
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, docConfig);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(tomlConfigService.config.api.port!, '0.0.0.0');
})();
