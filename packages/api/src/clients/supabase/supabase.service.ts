import { Inject, Injectable, Scope } from '@nestjs/common';
import { REQUEST } from '@nestjs/core';
import { createClient } from '@supabase/supabase-js';
import { Request } from 'express';
import { ExtractJwt } from 'passport-jwt';

import { Database } from '../../types/supabase';
import { TomlConfigService } from '../../utils/tomlConfig';

@Injectable({ scope: Scope.TRANSIENT })
export class SupabaseService {
  constructor(
    private readonly tomlConfigService: TomlConfigService,
    @Inject(REQUEST) private readonly request: Request,
  ) {}

  static createClientFromToken(publicUrl: string, privateKey: string, token: string | null) {
    return createClient<Database, 'public'>(publicUrl, privateKey, {
      auth: { persistSession: false },
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    });
  }

  client() {
    return SupabaseService.createClientFromToken(
      this.tomlConfigService.config.services.supabase.url,
      this.tomlConfigService.config.services.supabase.anon_key,
      ExtractJwt.fromAuthHeaderAsBearerToken()(this.request),
    );
  }
}
