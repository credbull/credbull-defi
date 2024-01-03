import { ExecutionContext, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { Request } from 'express';
import { ExtractJwt } from 'passport-jwt';

import { SupabaseService } from '../supabase.service';

export const SupabaseRoles = Reflector.createDecorator<string[]>();

@Injectable()
export class SupabaseGuard extends AuthGuard('jwt') {
  constructor(
    private readonly reflector: Reflector,
    private readonly config: ConfigService,
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
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
      ExtractJwt.fromAuthHeaderAsBearerToken()(request),
    );

    const { data } = await client.auth.getUser();
    return data.user?.user_metadata.roles || [];
  }

  private matchRoles(roles: string[], userRoles: string[]): boolean {
    return !!roles.find((role) => !!userRoles.find((item) => item === role));
  }
}
