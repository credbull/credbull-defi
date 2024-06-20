import { Database } from '@credbull/api';
import { createClient } from '@supabase/supabase-js';

import { Schema } from './schema';

export function supabaseAdminClient(config: any) {
  Schema.CONFIG_SUPABASE_URL.merge(Schema.CONFIG_SUPABASE_ADMIN).parse(config);

  return createClient<Database, 'public'>(config.services.supabase.url, config.secret!.SUPABASE_SERVICE_ROLE_KEY!);
}
