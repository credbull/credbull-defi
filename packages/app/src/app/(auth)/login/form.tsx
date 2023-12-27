'use client';

import { Button } from '@mantine/core';
import { useLogin, useNotification } from '@refinedev/core';
import { AuthPage } from '@refinedev/mantine';
import { useCallback } from 'react';

export function SignInForm() {
  const { mutateAsync, isLoading } = useLogin();
  const { open } = useNotification();

  const sendMagicLink = useCallback(async () => {
    const emailInput = document.querySelector('[name=email]') as HTMLInputElement | undefined;

    if (!emailInput || !emailInput?.value) {
      open?.({ type: 'error', message: 'Please provide an email address' });
      return;
    }

    if (emailInput && emailInput.value) {
      await mutateAsync({ email: emailInput.value, providerName: 'link' });
      open?.({ type: 'success', message: 'Magic link sent to your email' });
    }
  }, [mutateAsync, open]);

  return (
    <AuthPage
      type="login"
      title="Credbull DeFI"
      providers={[
        { name: 'discord', label: 'Discord' },
        { name: 'twitter', label: 'Twitter' },
      ]}
      rememberMe={
        <Button
          variant="white"
          color="gray"
          pl={0}
          compact={true}
          style={{ textDecoration: 'underline' }}
          disabled={isLoading}
          onClick={sendMagicLink}
        >
          Send Magic Link?
        </Button>
      }
    />
  );
}
