import { generateMock } from '@anatine/zod-mock';
import { SupabaseClient } from '@supabase/supabase-js';
import { describe, expect, it } from 'vitest';
import { mockDeep } from 'vitest-mock-extended';

import {
  ForgotPasswordParams,
  LoginWithMagicLinkParams,
  LoginWithPasswordParams,
  LoginWithSocialParams,
  RegisterParams,
  createProvider,
} from '@/app/(auth)/provider';

describe('provider', () => {
  const fixture = () => {
    const client = mockDeep<SupabaseClient>();
    const provider = createProvider({ client, origin: () => '/root' });
    return { client, provider };
  };

  it('should login using a email and password when a social provider is not given', async () => {
    const { client, provider } = fixture();

    client.auth.signInWithPassword.mockResolvedValueOnce({ data: { session: {} }, error: null } as any);

    const params = generateMock(LoginWithPasswordParams);
    await provider.login?.(params);

    expect(client.auth.signInWithOAuth.mock.calls.length).toBe(0);
    expect(client.auth.signInWithPassword.mock.calls.length).toBe(1);
  });

  it('should login using a magic link when a provider and email are given', async () => {
    const { client, provider } = fixture();

    client.auth.signInWithOtp.mockResolvedValueOnce({ data: { session: {} }, error: null } as any);

    const params = generateMock(LoginWithMagicLinkParams);
    await provider.login?.(params);

    expect(client.auth.signInWithOtp.mock.calls.length).toBe(1);
    expect(client.auth.signInWithPassword.mock.calls.length).toBe(0);
  });

  it('should login using a oauth when a social provider is given', async () => {
    const { client, provider } = fixture();

    client.auth.signInWithOAuth.mockResolvedValueOnce({ data: { url: '/url' }, error: null } as any);

    const params = generateMock(LoginWithSocialParams);
    params.providerName = 'twitter';
    await provider.login?.(params);

    expect(client.auth.signInWithOAuth.mock.calls.length).toBe(1);
    expect(client.auth.signInWithPassword.mock.calls.length).toBe(0);
  });

  it('should redirect to supabase when a social provider is given', async () => {
    const { client, provider } = fixture();

    client.auth.signInWithOAuth.mockResolvedValueOnce({ data: { url: '/url' }, error: null } as any);

    const params = generateMock(LoginWithSocialParams);
    params.providerName = 'twitter';
    const { redirectTo } = await provider.login?.(params);

    expect(redirectTo).toBe('/url');
  });

  it('should ask to redirect to code callback route when registering', async () => {
    const { client, provider } = fixture();

    client.auth.signUp.mockResolvedValueOnce({ data: { user: {} } as any, error: null });

    const params = generateMock(RegisterParams);
    await provider.register?.(params);

    expect((client.auth.signUp.mock.lastCall?.[0].options as any).emailRedirectTo).toBe('/root/code/callback');
  });

  it('should ask to redirect to update password route when resetting a password', async () => {
    const { client, provider } = fixture();

    client.auth.resetPasswordForEmail.mockResolvedValueOnce({ data: '', error: null });

    const params = generateMock(ForgotPasswordParams);
    await provider.forgotPassword?.(params);

    expect(client.auth.resetPasswordForEmail.mock.lastCall?.[1]?.redirectTo).toBe('/root/update-password');
  });
});
