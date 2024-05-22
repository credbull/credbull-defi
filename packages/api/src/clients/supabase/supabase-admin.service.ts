import { Injectable } from '@nestjs/common';
import { createClient } from '@supabase/supabase-js';

import { Database } from '../../types/supabase';
import { TomlConfigService } from '../../utils/tomlConfig';

@Injectable()
export class SupabaseAdminService {
  constructor(private readonly tomlConfigService: TomlConfigService) {}

  admin() {
    return createClient<Database, 'public'>(
      this.tomlConfigService.config.services.supabase.url,
      this.tomlConfigService.config.secret.SUPABASE_SERVICE_ROLE_KEY.value,

      {
        auth: { persistSession: false },
      },
    );
  }
}
