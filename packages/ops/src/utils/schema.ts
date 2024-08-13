import { z } from 'zod';

// Component Zod Schema for validatiing configuration and parameters.
export abstract class Schema {
  static readonly EMAIL = z.string().email();
  static readonly EMAIL_OPTIONAL = this.EMAIL.nullish().or(z.string().length(0));
  static readonly NON_EMPTY_STRING = z.string().trim().min(1);
  static readonly ADDRESS = z.string().regex(/^(0x)?[0-9a-fA-F]{40,40}$/);
  static readonly PERCENTAGE = z.number().int().positive().gt(0);
  static readonly UPSIDE_VAULT_SPEC = z.union([this.ADDRESS, z.string().regex(/^self$/)]);

  static readonly CONFIG_SUPABASE_URL = z.object({
    services: z.object({
      supabase: z.object({
        url: z.string().url(),
      }),
    }),
  });

  static readonly CONFIG_SUPABASE_ADMIN = z.object({
    secret: z.object({
      SUPABASE_SERVICE_ROLE_KEY: z.string(),
    }),
  });

  static readonly CONFIG_SUPABASE_ANONYMOUS = z.object({
    secret: z.object({
      SUPABASE_ANONYMOUS_KEY: z.string(),
    }),
  });

  static readonly CONFIG_ETHERS_URL = z.object({
    services: z.object({
      ethers: z.object({
        url: z.string().url(),
      }),
    }),
  });

  static readonly CONFIG_API_URL = z.object({
    api: z.object({
      url: z.string().url(),
    }),
  });

  static readonly CONFIG_APP_URL = z.object({
    app: z.object({
      url: z.string().url(),
    }),
  });

  static readonly CONFIG_USER_ADMIN = z.object({
    users: z.object({
      admin: z.object({
        email_address: this.EMAIL,
      }),
    }),
    secret: z.object({
      ADMIN_PASSWORD: this.NON_EMPTY_STRING,
    }),
  });

  static readonly CONFIG_USER_ALICE = z.object({
    users: z.object({
      alice: z.object({
        email_address: this.EMAIL,
      }),
    }),
    secret: z.object({
      ALICE_PASSWORD: this.NON_EMPTY_STRING,
    }),
  });

  static readonly CONFIG_USER_BOB = z.object({
    users: z.object({
      bob: z.object({
        email_address: this.EMAIL,
      }),
    }),
    secret: z.object({
      BOB_PASSWORD: this.NON_EMPTY_STRING,
    }),
  });

  static readonly CONFIG_USERS = this.CONFIG_USER_ADMIN.merge(this.CONFIG_USER_ALICE).merge(this.CONFIG_USER_BOB);

  static readonly CONFIG_ADMIN_PRIVATE_KEY = z.object({
    secret: z.object({
      ADMIN_PRIVATE_KEY: this.NON_EMPTY_STRING,
    }),
  });

  static readonly CONFIG_CRON = z.object({
    secret: z.object({
      CRON_SECRET: this.NON_EMPTY_STRING,
    }),
  });

  static readonly CONFIG_EVM_ADDRESS = z.object({
    evm: z.object({
      address: z.object({
        owner: this.ADDRESS,
        operator: this.ADDRESS,
        custodian: this.ADDRESS,
        treasury: this.ADDRESS,
        activity_reward: this.ADDRESS,
      }),
    }),
  });

  static readonly CONFIG_OPERATION_CREATE_VAULT = z.object({
    operation: z.object({
      createVault: z.object({
        upside_percentage: this.PERCENTAGE,
      }),
    }),
  });
}
