import { ExecutionContext } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { Strategy } from 'passport-jwt';
import { Mock, beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { Config } from '../../../utils/module';
import { SupabaseModule } from '../supabase.module';
import { SupabaseService } from '../supabase.service';

import { SupabaseGuard, SupabaseRoles } from './supabase.guard';

describe('SupabaseGuard', () => {
  let guard: SupabaseGuard;
  let context: DeepMockProxy<ExecutionContext>;
  let client: DeepMockProxy<SupabaseClient>;
  let verifier: Mock;

  beforeEach(async () => {
    context = mockDeep<ExecutionContext>();

    client = mockDeep<SupabaseClient>();
    SupabaseService.createClientFromToken = () => client;

    verifier = vi.fn();
    (Strategy as any).JwtVerifier = verifier;

    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), SupabaseModule],
      providers: [SupabaseGuard],
    }).compile();

    guard = await module.resolve<SupabaseGuard>(SupabaseGuard);
  });

  it.skip('should throw if there is no access token in the request', async () => {
    context.switchToHttp.mockReturnValue({
      getRequest: () => ({ headers: {} }) as any,
      getResponse: () => ({}) as any,
      getNext: () => ({}) as any,
    });

    try {
      await guard.canActivate(context);
    } catch (e) {
      expect(e.response.message).toBe('Unauthorized');
      expect(e.status).toBe(401);
    }
  });

  it('should be active if there is are no roles in the context handler', async () => {
    verifier.mockImplementationOnce((_token, _secretOrPublicKey, _options, callback) => {
      return callback(null, { sub: 'user_id' });
    });

    context.switchToHttp.mockReturnValue({
      getRequest: () => ({ headers: { authorization: 'bearer token' } }) as any,
      getResponse: () => ({}) as any,
      getNext: () => ({}) as any,
    });

    context.getHandler.mockReturnValue(vi.fn());

    const active = await guard.canActivate(context);
    expect(active).toBe(true);
  });

  it('should not be active if there is are roles in the context handler', async () => {
    verifier.mockImplementationOnce((_token, _secretOrPublicKey, _options, callback) => {
      return callback(null, { sub: 'user_id' });
    });

    context.switchToHttp.mockReturnValue({
      getRequest: () => ({ headers: { authorization: 'bearer token' } }) as any,
      getResponse: () => ({}) as any,
      getNext: () => ({}) as any,
    });

    const handler = vi.fn();
    SupabaseRoles(['admin'])(handler);
    context.getHandler.mockReturnValue(handler);

    client.auth.getUser.mockResolvedValueOnce({ data: { user: { user_metadata: { roles: [] } } } } as any);

    const active = await guard.canActivate(context);
    expect(active).toBe(false);
  });

  it('should be active if the use matches the roles in the context handler', async () => {
    verifier.mockImplementationOnce((_token, _secretOrPublicKey, _options, callback) => {
      return callback(null, { sub: 'user_id' });
    });

    context.switchToHttp.mockReturnValue({
      getRequest: () => ({ headers: { authorization: 'bearer token' } }) as any,
      getResponse: () => ({}) as any,
      getNext: () => ({}) as any,
    });

    client.auth.getUser.mockResolvedValueOnce({ data: { user: { user_metadata: { roles: ['admin'] } } } } as any);

    const handler = vi.fn();
    SupabaseRoles(['admin'])(handler);
    context.getHandler.mockReturnValue(handler);

    const active = await guard.canActivate(context);
    expect(active).toBe(true);
  });
});
