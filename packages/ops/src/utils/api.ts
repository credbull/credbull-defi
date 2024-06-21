import { Schema } from './schema';

export const headers = (session?: Awaited<ReturnType<typeof login>>) => {
  return {
    headers: {
      'Content-Type': 'application/json',
      ...(session?.access_token ? { Authorization: `Bearer ${session.access_token}` } : {}),
    },
  };
};

// FIXME (JL,2024-06-19): This logs in Admin or Bob. No consideration for poor Alice!
export const login = async (
  config: any,
  opts?: { admin: boolean },
): Promise<{ access_token: string; user_id: string }> => {
  Schema.CONFIG_API_URL.parse(config);

  let _email: string, _password: string;
  if (opts?.admin) {
    Schema.CONFIG_USER_ADMIN.parse(config);
    _email = config.users.admin.email_address;
    _password = config.secret!.ADMIN_PASSWORD!;
  } else {
    Schema.CONFIG_USER_BOB.parse(config);
    _email = config.users.bob.email_address;
    _password = config.secret!.BOB_PASSWORD!;
  }

  const body = JSON.stringify({ email: _email, password: _password });

  let signIn;
  try {
    signIn = await fetch(`${config.api.url}/auth/api/sign-in`, { method: 'POST', body, ...headers() });
  } catch (error) {
    console.error('Network error or server is down:', error);
    throw error;
  }

  if (!signIn.ok) {
    console.error(`HTTP error! status: ${signIn.status}`);
    throw new Error(`Failed to login: ${signIn.statusText}`);
  }

  const data = await signIn.json();
  console.log(`sign in response: ${JSON.stringify(data)}`);
  return data;
};
