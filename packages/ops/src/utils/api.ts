import { Schema } from './schema';

export function headers(session?: Awaited<ReturnType<typeof login>>) {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
}

export async function login(config: any, email: string, password: string): Promise<any> {
  Schema.CONFIG_API_URL.parse(config);
  Schema.EMAIL.parse(email);
  Schema.NON_EMPTY_STRING.parse(password);

  return fetch(`${config.api.url}/auth/api/sign-in`, {
    method: 'POST',
    body: JSON.stringify({ email, password }),
    ...headers(),
  }).then((response) => response.json());
}
