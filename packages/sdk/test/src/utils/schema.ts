import { z } from 'zod';

// Component Zod Schema for validatiing configuration and parameters.
export abstract class Schema {
  static EMAIL = z.string().email();
  static NON_EMPTY_STRING = z.string().trim().min(1);
  static ADDRESS = z.string().regex(/^(0x)?[0-9a-fA-F]{40,40}$/);

  static CONFIG_API_URL = z.object({
    api: z.object({
      url: z.string().url(),
    }),
  });

  static CONFIG_ADMIN_USER = z.object({
    users: z.object({
      admin: z.object({
        email_address: this.EMAIL,
      }),
    }),
    secret: z.object({
      ADMIN_PASSWORD: this.NON_EMPTY_STRING,
    }),
  });

  static CONFIG_ADMIN_PRIVATE_KEY = z.object({
    secret: z.object({
      ADMIN_PRIVATE_KEY: this.NON_EMPTY_STRING,
    }),
  });

  static CONFIG_CRON = z.object({
    secret: z.object({
      CRON_SECRET: this.NON_EMPTY_STRING,
    }),
  });
}
