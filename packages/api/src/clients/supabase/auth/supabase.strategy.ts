import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import { TomlConfigService } from '../../../utils/tomlConfig';

@Injectable()
export class SupabaseStrategy extends PassportStrategy(Strategy) {
  // TODO: decide if we keep ConfigService or fold it into TomlConfigService
  // downside is if we add to TomlConfigService, we inject ConfigService in a lot of places
  constructor(tomlConfigService: TomlConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: tomlConfigService.config.env.SUPABASE_JWT_SECRET,
    });
  }

  async validate(request: Request) {
    return request;
  }
}
