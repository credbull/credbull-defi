import { AccountStatusDto } from '@credbull/api';
import { SupabaseClient } from '@supabase/supabase-js';

const buildURL = (path: string) => {
  return `${process.env.API_BASE_URL}${path}`;
};

const authHeaders = async (supabase: SupabaseClient) => {
  const { data } = await supabase.auth.getSession();

  return { headers: { Authorization: `Bearer ${data.session!.access_token}` } };
};

export const createClient = (supabase: SupabaseClient) => {
  return {
    accountStatus: async (): Promise<AccountStatusDto> => {
      const headers = await authHeaders(supabase);

      return fetch(buildURL('/accounts/status'), headers).then((res) => res.json());
    },
  };
};
