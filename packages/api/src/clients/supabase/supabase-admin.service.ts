import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient } from '@supabase/supabase-js';

import { Database } from '../../types/supabase';

@Injectable()
export class SupabaseAdminService {
  constructor(private readonly config: ConfigService) {}

  admin() {
    return createClient<Database, 'public'>(
      this.config.getOrThrow('NEXT_PUBLIC_SUPABASE_URL'),
      this.config.getOrThrow('SUPABASE_SERVICE_ROLE_KEY'),
      {
        auth: { persistSession: false },
      },
    );
  }
}
