import { z } from 'zod';

export const envVariables = z.object({
  API_BASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string(),
  NEXT_PUBLIC_TARGET_NETWORK: z.string(),
  NEXT_PUBLIC_TARGET_NETWORK_ID: z.string(),
  SUPABASE_SERVICE_ROLE_KEY: z.string(),
  BOB_EMAIL: z.string().email(),
  BOB_PASSWORD: z.string(),
  BOB_PRIVATE_KEY: z.string(),
  ADMIN_EMAIL: z.string().email(),
  ADMIN_PASSWORD: z.string(),
});

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof envVariables> {}
  }
}
