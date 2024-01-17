'use client';

import { Card, Flex, Group, Text, Title } from '@mantine/core';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

import { supabase } from '@/clients/supabase.client';

import { Routes } from '@/utils/routes';

export function CodeCallbackRedirect(props: { access_token: string; refresh_token: string }) {
  const router = useRouter();

  useEffect(() => {
    supabase.auth.setSession(props).then(() => router.replace(Routes.DASHBOARD));
  }, [props, router]);

  return (
    <Flex w="100%" h="100vh" justify="center" align="center">
      <Card w="20%" h="30%" withBorder shadow="md">
        <Flex align="center" justify="center" h="100%" direction="column">
          <Group position="center">
            <Title>Login in..</Title>
          </Group>
          <Group position="center" mt="lg">
            <Flex direction="column" align="center">
              <Text c="dimmed" fw={500} fz="1rem">
                Just a second..
              </Text>
            </Flex>
          </Group>
        </Flex>
      </Card>
    </Flex>
  );
}
