import { SupabaseClient } from '@supabase/supabase-js';
import { describe, expect, it, vi } from 'vitest';
import { mockDeep } from 'vitest-mock-extended';

import { addEntitiesAndDistribution } from './vaults.repository';

describe('Vaults Repository', () => {
  const client = mockDeep<SupabaseClient>();

  it('should configure a vault entity with same address when the upside param is self', async () => {
    const entities = [{ type: 'vault' as const, address: 'self', percentage: 0.8 }];

    const select = vi.fn();
    const insert = vi.fn();
    const builder = { select, insert };

    select.mockResolvedValueOnce({ data: entities });
    select.mockResolvedValueOnce({ data: [] });
    insert.mockReturnValue(builder as any);

    client.from.mockReturnValue(builder as any);

    const { data } = await addEntitiesAndDistribution(
      entities,
      { id: 1, address: 'address', tenant: 'tenant' },
      client,
    );

    expect(data).toBe('Vault created successfully');
    expect(insert).toHaveBeenCalledWith([{ type: 'vault', address: 'address', vault_id: 1, tenant: 'tenant' }]);
  });

  it('should configure a vault entity with address from params', async () => {
    const entities = [{ type: 'vault' as const, address: 'other', percentage: 0.8 }];

    const select = vi.fn();
    const insert = vi.fn();
    const builder = { select, insert };

    select.mockResolvedValueOnce({ data: entities });
    select.mockResolvedValueOnce({ data: [] });
    insert.mockReturnValue(builder as any);

    client.from.mockReturnValue(builder as any);

    const { data } = await addEntitiesAndDistribution(
      entities,
      { id: 1, address: 'address', tenant: 'tenant' },
      client,
    );

    expect(data).toBe('Vault created successfully');
    expect(insert).toHaveBeenCalledWith([{ type: 'vault', address: 'other', vault_id: 1, tenant: 'tenant' }]);
  });
});
