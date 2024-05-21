import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

import { TomlConfigService } from '../../../utils/tomlConfig';

@Injectable()
export class SupabaseStrategy extends PassportStrategy(Strategy) {
  constructor(tomlConfigService: TomlConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: tomlConfigService.config.secret.SUPABASE_JWT_SECRET.value,
    });
  }

  async validate(request: Request) {
    return request;
  }
}
