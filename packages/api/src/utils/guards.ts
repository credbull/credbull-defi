import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthGuard, PassportStrategy } from '@nestjs/passport';
import { HeaderAPIKeyStrategy } from 'passport-headerapikey';

@Injectable()
export class CronStrategy extends PassportStrategy(HeaderAPIKeyStrategy, 'cron-secret') {
  constructor(private readonly config: ConfigService) {
    super(
      { prefix: 'Bearer ', header: 'Authorization' },
      true,
      (apiKey: string, done: (error?: Error, data?: boolean) => void) => this.validate(apiKey, done),
    );
  }

  public validate = (apiKey: string, done: (error?: Error, data?: boolean) => void) => {
    if (apiKey !== this.config.getOrThrow('CRON_SECRET')) {
      done(new UnauthorizedException(), false);
      return;
    }

    done(undefined, true);
  };
}

@Injectable()
export class CronGuard extends AuthGuard('cron-secret') {}
