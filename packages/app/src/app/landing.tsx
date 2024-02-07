'use client';

import { Button, Card, Flex, Group, Text, Title } from '@mantine/core';
import Link from 'next/link';

import { Routes } from '@/utils/routes';

export function Landing() {
  return (
    <Flex w="100%" h="100vh" direction="column" justify="center" align="center">
      <Card w="35%" withBorder shadow="md">
        <Group position="center">
          <Title>Credbull DeFi</Title>
        </Group>
        <Group position="center" mt="lg">
          <Flex direction="column" align="center">
            <Text c="dimmed" fw={500} fz="1rem">
              The world is becoming more volatile{' '}
            </Text>
            <Text fw={500} fz="1.5rem" fs="italic">
              Your investments don’t need to be..{' '}
            </Text>
          </Flex>
        </Group>

        <Group mt={30} position="center">
          <Button component={Link} radius="md" size="lg" href={Routes.LOGIN}>
            Join us
          </Button>
        </Group>
      </Card>
    </Flex>
  );
}
