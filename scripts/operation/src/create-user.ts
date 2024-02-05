import * as makeChannel from './make-channel';
import { supabase } from './utils/helpers';

export const main = (scenarios: { channel: boolean }, params?: { email: string }) => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    if (!params?.email) throw new Error('Email is required');

    const client = supabase({ admin: true });
    const password = (Math.random() + 1).toString(36);

    const auth = await client.auth.signUp({
      email: params?.email,
      password,
      options: { emailRedirectTo: `${process.env.APP_BASE_URL}/forgot-password` },
    });
    if (auth.error) throw auth.error;

    if (scenarios.channel) {
      makeChannel.main(scenarios, params);
    }

    console.log('corporate account created');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
