import { Schema } from './schema';
import { User } from './user';

// Login as the Admin User and get all Vault Entities.
export async function getVaultEntities(config: any, admin: User, id: string): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);

  return fetch(`${config.api.url}/vaults/vault-entities/${id}`, {
    headers: { Authorization: `Bearer ${admin.accessToken}` },
  }).then((response) => response.json());
}

// Logs in as the Admin User and whitelists the `address` for `user_id`?
export async function whitelist(config: any, admin: User, address: string, user_id: string): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.ADDRESS.parse(address);

  return fetch(`${config.api.url}/accounts/whitelist`, {
    method: 'POST',
    body: JSON.stringify({ address, user_id }),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${admin.accessToken}` },
  }).then((response) => response.json());
}
