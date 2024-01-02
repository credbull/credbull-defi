import { Inject, Injectable, Scope } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { REQUEST } from '@nestjs/core';
import { SupabaseClient, createClient } from '@supabase/supabase-js';
import { Request } from 'express';
import { ExtractJwt } from 'passport-jwt';

import { Database } from '../../types/supabase';

@Injectable({ scope: Scope.REQUEST })
export class SupabaseService {
  private supabase: SupabaseClient<Database>;
  private supabaseAdmin: SupabaseClient<Database>;

  constructor(
    private readonly config: ConfigService,
    @Inject(REQUEST) private readonly request: Request,
  ) {}

  client() {
    if (this.supabase) return this.supabase;

    this.supabase = createClient<Database, 'public'>(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_ANON_KEY'),
      {
        auth: { persistSession: false },
        global: {
          headers: {
            Authorization: `Bearer ${ExtractJwt.fromAuthHeaderAsBearerToken()(this.request)}`,
          },
        },
      },
    );
    return this.supabase;
  }

  admin() {
    if (this.supabaseAdmin) return this.supabaseAdmin;

    this.supabaseAdmin = createClient<Database, 'public'>(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
      {
        auth: { persistSession: false },
      },
    );
    return this.supabaseAdmin;
  }
}
