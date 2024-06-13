import { login } from './api';
import { Schema } from './schema';

// Login as the Admin User and get all Vault Entities.
export async function getVaultEntities(config: any, id: string): Promise<any> {
  Schema.CONFIG_API_URL.merge(Schema.CONFIG_ADMIN_USER).parse(config);

  return login(config, config.users.admin.email_address, config.secret.ADMIN_PASSWORD).then(
    async ({ access_token }) => {
      return fetch(`${config.api.url}/vaults/vault-entities/${id}`, {
        headers: { Authorization: `Bearer ${access_token}` },
      }).then(async (response) => {
        return response.json();
      });
    },
  );
}

// Logs in as the Admin User and whitelists the `address` for `user_id`?
export async function whitelist(config: any, address: string, user_id: string): Promise<any> {
  Schema.CONFIG_API_URL.merge(Schema.CONFIG_ADMIN_USER).parse(config);
  Schema.ADDRESS.parse(address);

  return login(config, config.users.admin.email_address, config.secret.ADMIN_PASSWORD).then(
    async ({ access_token }) => {
      return fetch(`${config.api.url}/accounts/whitelist`, {
        method: 'POST',
        body: JSON.stringify({ address, user_id }),
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${access_token}` },
      }).then(async (response) => {
        return response.json();
      });
    },
  );
}
