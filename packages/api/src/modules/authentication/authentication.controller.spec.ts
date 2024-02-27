import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { SupabaseAdminService } from '../../clients/supabase/supabase-admin.service';
import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Config } from '../../utils/module';

import { AuthenticationController } from './authentication.controller';
import { AuthenticationModule } from './authentication.module';

describe('AuthenticationController', () => {
  let controller: AuthenticationController;
  let admin: DeepMockProxy<SupabaseClient>;

  beforeEach(async () => {
    admin = mockDeep<SupabaseClient>();

    const service = { client: () => ({}), admin: () => admin };

    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), AuthenticationModule],
    })
      .overrideProvider(SupabaseService)
      .useValue(service)
      .overrideProvider(SupabaseAdminService)
      .useValue(service)
      .compile();

    controller = await module.resolve<AuthenticationController>(AuthenticationController);
  });

  it('should throw supabase error when there is an error refreshing the token', async () => {
    const data = { refresh_token: '' };

    admin.auth.refreshSession.mockResolvedValueOnce({ error: new Error('error') } as any);

    try {
      await controller.refreshToken(data);
    } catch (e) {
      expect(e.response.message).toBe('error');
      expect(e.status).toBe(500);
    }
  });

  it('should throw when there is no session', async () => {
    const data = { refresh_token: '' };

    admin.auth.refreshSession.mockResolvedValueOnce({ data: {} } as any);

    try {
      await controller.refreshToken(data);
    } catch (e) {
      expect(e.response.message).toBe("Couldn't refresh session");
      expect(e.status).toBe(500);
    }
  });

  it('should return the tokens for a new session', async () => {
    const data = { refresh_token: '' };
    const session = { refresh_token: 'refresh_token', access_token: 'access_token', user: { id: 'id' } };

    admin.auth.refreshSession.mockResolvedValueOnce({ data: { session } } as any);

    const { refresh_token, access_token } = await controller.refreshToken(data);

    expect(refresh_token).toBe(session.refresh_token);
    expect(access_token).toBe(session.access_token);
  });
});
