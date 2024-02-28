import { Inject, Injectable, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { REQUEST } from '@nestjs/core';
import { createClient } from '@supabase/supabase-js';
import { Request } from 'express';
import { ExtractJwt } from 'passport-jwt';

import { Database } from '../../types/supabase';

@Injectable({ scope: Scope.TRANSIENT })
export class SupabaseService {
  constructor(
    private readonly config: ConfigService,
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
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
      ExtractJwt.fromAuthHeaderAsBearerToken()(this.request),
    );
  }
}
