import { z } from 'zod';

export const envVariables = z.object({
  API_BASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string(),
  NEXT_PUBLIC_TARGET_NETWORK: z.string(),
  SUPABASE_SERVICE_ROLE_KEY: z.string(),
  BOB_EMAIL: z.string().email(),
  BOB_PASSWORD: z.string(),
  BOB_PRIVATE_KEY: z.string(),
  ADMIN_EMAIL: z.string().email(),
  ADMIN_PASSWORD: z.string(),
  PUBLIC_OWNER_ADDRESS: z.string().optional(),
  PUBLIC_OPERATOR_ADDRESS: z.string().optional(),
  ADDRESSES_CUSTODIAN: z.string().optional(),
  ADDRESSES_ACTIVITY_REWARD: z.string().optional(),
  ADDRESSES_TREASURY: z.string().optional(),
});

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof envVariables> {}
  }
}
