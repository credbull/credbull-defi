import { Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthGuard, PassportStrategy } from '@nestjs/passport';
import { HeaderAPIKeyStrategy } from 'passport-headerapikey';

import { TomlConfigService } from './tomlConfig';

@Injectable()
export class CronStrategy extends PassportStrategy(HeaderAPIKeyStrategy, 'cron-secret') {
  constructor(private readonly config: TomlConfigService) {
    super(
      { prefix: 'Bearer ', header: 'Authorization' },
      true,
      (apiKey: string, done: (error?: Error, data?: boolean) => void) => this.validate(apiKey, done),
    );
  }

  public validate = (apiKey: string, done: (error?: Error, data?: boolean) => void) => {
    if (apiKey !== this.config.config.env.CRON_SECRET) {
      done(new UnauthorizedException(), false);
      return;
    }

    done(undefined, true);
  };
}

@Injectable()
export class CronGuard extends AuthGuard('cron-secret') {}
