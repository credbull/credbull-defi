import { Schema } from './schema';
import { User } from './user';

// Logs in as the Admin User and whitelists the `address` for `user_id`?
export async function whitelist(config: any, admin: User, address: string, userId: string): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.ADDRESS.parse(address);

  return fetch(`${config.api.url}/accounts/whitelist`, {
    method: 'POST',
    body: JSON.stringify({ address, user_id: userId }),
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${admin.accessToken}` },
  }).then((response) => response.json());
}
