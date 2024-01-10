import { AccountStatusDto, WalletDto } from '@credbull/api';
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

      const response = await fetch(buildURL('/accounts/status'), headers);
      return response.json();
    },
    linkWallet: async (message: string, signature: string): Promise<WalletDto> => {
      const { headers } = await authHeaders(supabase);
      const body = JSON.stringify({ message, signature });

      const response = await fetch(buildURL('/accounts/link-wallet'), {
        headers: { ...headers, 'Content-Type': 'application/json' },
        method: 'POST',
        body,
      });

      return response.json();
    },
  };
};
