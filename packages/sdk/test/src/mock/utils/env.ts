import { z } from 'zod';

export const envVariables = z.object({
  ADMIN_PRIVATE_KEY: z.string(),
});

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace NodeJS {
    interface ProcessEnv extends z.infer<typeof envVariables> {}
  }
}
