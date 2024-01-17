'use client';

import { Button, LoadingOverlay } from '@mantine/core';
import { useLogin, useNotification } from '@refinedev/core';
import { AuthPage } from '@refinedev/mantine';
import { useCallback, useState } from 'react';

export function SignInForm() {
  const [visible, setVisible] = useState(false);
  const { mutateAsync, isLoading } = useLogin();
  const { open } = useNotification();

  const sendMagicLink = useCallback(async () => {
    const emailInput = document.querySelector('[name=email]') as HTMLInputElement | undefined;

    if (!emailInput || !emailInput?.value) {
      open?.({ type: 'error', message: 'Please provide an email address' });
      return;
    }

    if (emailInput && emailInput.value) {
      setVisible(true);
      await mutateAsync({ email: emailInput.value, providerName: 'link' });
      setVisible(false);
      open?.({ type: 'success', message: 'Magic link sent to your email' });
    }
  }, [mutateAsync, open]);

  return (
    <>
      <div style={{ width: 400 }}>
        <LoadingOverlay visible={visible} overlayBlur={2} />
      </div>

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
        formProps={{
          onSubmit: async (values) => {
            setVisible(true);
            await mutateAsync(values);
            setVisible(false);
          },
        }}
      />
    </>
  );
}
