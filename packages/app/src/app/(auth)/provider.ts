import { AuthBindings } from '@refinedev/core';
import { Provider, SupabaseClient } from '@supabase/supabase-js';
import { z } from 'zod';

import { supabase } from '@/clients/supabase.client';

import { Routes } from '@/utils/routes';

export const ProviderContext = z.object({
  client: z.custom<SupabaseClient>(),
  origin: z.function().args(z.void()).returns(z.string()),
});
type ProviderContext = z.infer<typeof ProviderContext>;

const AuthParams = z.object({
  email: z.string().email(),
  password: z.string(),
  providerName: z.custom<Provider>((v) => typeof v === 'string').optional(),
});

export const LoginParams = AuthParams;
type LoginParams = z.infer<typeof LoginParams>;

async function login(ctx: ProviderContext, params: LoginParams) {
  const { client, origin } = ctx;
  const { providerName } = params;

  if (providerName) {
    const { data, error } = await client.auth.signInWithOAuth({
      provider: providerName,
      options: { redirectTo: `${origin()}${Routes.CODE_CALLBACK}` },
    });

    if (error) return { success: false, error };
    if (data?.url) return { success: true, redirectTo: data?.url };
  }

  const { data, error } = await client.auth.signInWithPassword(params);

  if (error) return { success: false, error };
  if (data?.session) return { success: true, redirectTo: Routes.DASHBOARD };
  return {
    success: false,
    error: { name: 'Login failed', message: 'Invalid username or password' },
  };
}

export const RegisterParams = AuthParams.omit({ providerName: true });
type RegisterParams = z.infer<typeof RegisterParams>;

async function register(ctx: ProviderContext, params: RegisterParams) {
  const { client, origin } = ctx;

  try {
    const { data, error } = await client.auth.signUp({
      ...params,
      options: { emailRedirectTo: `${origin()}${Routes.CODE_CALLBACK}` },
    });

    if (error) return { success: false, error };
    if (data) return { success: true, redirectTo: Routes.LOGIN };
  } catch (error: any) {
    return { success: false, error };
  }

  return {
    success: false,
    error: { message: 'Register failed', name: 'Invalid email or password' },
  };
}

export const ForgotPasswordParams = AuthParams.pick({ email: true });
type ForgotPasswordParams = z.infer<typeof ForgotPasswordParams>;

async function forgotPassword(ctx: ProviderContext, params: ForgotPasswordParams) {
  const { client, origin } = ctx;

  try {
    const { data, error } = await client.auth.resetPasswordForEmail(params.email, {
      redirectTo: `${origin()}${Routes.UPDATE_PASSWORD}`,
    });

    if (error) return { success: false, error };
    if (data) return { success: true };
  } catch (error: any) {
    return { success: false, error };
  }

  return {
    success: false,
    error: { message: 'Forgot password failed', name: 'Invalid email' },
  };
}

export const UpdatePasswordParams = AuthParams.pick({ password: true });
type UpdatePasswordParams = z.infer<typeof UpdatePasswordParams>;

async function updatePassword(ctx: ProviderContext, params: UpdatePasswordParams) {
  const { client } = ctx;

  try {
    const { data, error } = await client.auth.updateUser(params);

    if (error) return { success: false, error };
    if (data) return { success: true, redirectTo: Routes.DASHBOARD };
  } catch (error: any) {
    return { success: false, error };
  }

  return {
    success: false,
    error: { message: 'Update password failed', name: 'Invalid password' },
  };
}

async function logout({ client }: ProviderContext) {
  const { error } = await client.auth.signOut();

  if (error) return { success: false, error };
  return { success: true, redirectTo: Routes.HOME };
}

async function check({ client }: ProviderContext) {
  const { data } = await client.auth.getUser();

  if (data.user) return { authenticated: true };
  return { authenticated: false, redirectTo: Routes.LOGIN };
}

async function getPermissions({ client }: ProviderContext) {
  const user = await client.auth.getUser();

  if (user) return user.data.user?.role;
  return null;
}

async function getIdentity({ client }: ProviderContext) {
  const { data } = await client.auth.getUser();

  if (data?.user) return { ...data.user, name: data.user.email };
  return null;
}

async function onError(error: any) {
  console.error(error);
  return { error };
}

export const createProvider = (ctx: ProviderContext): AuthBindings => {
  return {
    login: async (params: LoginParams) => login(ctx, params),
    register: async (params: RegisterParams) => register(ctx, params),
    forgotPassword: async (params: ForgotPasswordParams) => forgotPassword(ctx, params),
    updatePassword: async (params: UpdatePasswordParams) => updatePassword(ctx, params),
    logout: async () => logout(ctx),
    check: async () => check(ctx),
    getPermissions: async () => getPermissions(ctx),
    getIdentity: async () => getIdentity(ctx),
    onError: async (error: any) => onError(error),
  };
};

export const provider: AuthBindings = createProvider({ client: supabase, origin: () => window.location.origin });
