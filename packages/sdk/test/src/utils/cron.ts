import { Schema } from './schema';

export async function distributeFixedYieldVault(config: any): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.CONFIG_CRON.parse(config);

  return fetch(`${config.api.url}/vaults/mature-outstanding`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${config.secret.CRON_SECRET}` },
  });
}
