import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

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
      .compile();

    controller = await module.resolve<AuthenticationController>(AuthenticationController);
  });

  it('should throw supabase error when there is an error refreshing the token', async () => {
    const data = { refreshToken: '' };

    admin.auth.refreshSession.mockResolvedValueOnce({ error: 'error' } as any);

    try {
      await controller.refreshToken(data);
    } catch (e) {
      expect(e.response.message).toBe('error');
      expect(e.status).toBe(400);
    }
  });

  it('should throw when there is no session', async () => {
    const data = { refreshToken: '' };

    admin.auth.refreshSession.mockResolvedValueOnce({ data: {} } as any);

    try {
      await controller.refreshToken(data);
    } catch (e) {
      expect(e.response.message).toBe("Couldn't refresh session");
      expect(e.status).toBe(500);
    }
  });

  it('should return the tokens for a new session', async () => {
    const data = { refreshToken: '' };
    const session = { refresh_token: 'refresh_token', access_token: 'access_token' };

    admin.auth.refreshSession.mockResolvedValueOnce({ data: { session } } as any);

    const { refreshToken, accessToken } = await controller.refreshToken(data);

    expect(refreshToken).toBe(session.refresh_token);
    expect(accessToken).toBe(session.access_token);
  });
});
