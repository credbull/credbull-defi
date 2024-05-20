import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class SupabaseStrategy extends PassportStrategy(Strategy) {
  // TODO: decide if we keep ConfigService or fold it into TomlConfigService
  // downside is if we add to TomlConfigService, we inject ConfigService in a lot of places
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.getOrThrow('SUPABASE_JWT_SECRET'),
    });
  }

  async validate(request: Request) {
    return request;
  }
}
