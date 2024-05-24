import { ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { Request } from 'express';
import { ExtractJwt } from 'passport-jwt';

import { TomlConfigService } from '../../../utils/tomlConfig';
import { SupabaseService } from '../supabase.service';

export const SupabaseRoles = Reflector.createDecorator<string[]>();

@Injectable()
export class SupabaseGuard extends AuthGuard('jwt') {
  constructor(
    private readonly tomlConfigService: TomlConfigService,
    private readonly reflector: Reflector,
  ) {
    super();
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isLoggedIn = await (super.canActivate(context) as Promise<boolean>);
    if (!isLoggedIn) return false;

    const assignedRoles = this.reflector.get(SupabaseRoles, context.getHandler());
    if (!assignedRoles) return true;

    const request = context.switchToHttp().getRequest();
    const userRoles = await this.getUserRoles(request);

    return this.matchRoles(assignedRoles, userRoles);
  }

  private async getUserRoles(request: Request): Promise<string[]> {
    const client = SupabaseService.createClientFromToken(
      this.tomlConfigService.config.services.supabase.url,
      this.tomlConfigService.config.secret.SUPABASE_SERVICE_ROLE_KEY.value,
      ExtractJwt.fromAuthHeaderAsBearerToken()(request),
    );

    const { data } = await client.auth.getUser();
    return data.user?.app_metadata.roles || [];
  }

  private matchRoles(roles: string[], userRoles: string[]): boolean {
    return !!roles.find((role) => !!userRoles.find((item) => item === role));
  }
}
