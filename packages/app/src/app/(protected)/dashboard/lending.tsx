'use client';

import { Tables } from '@credbull/api';
import { Badge, Box, Button, Card, Flex, Group, Text } from '@mantine/core';
import { useList } from '@refinedev/core';

function Vault(props: { data: Tables<'vaults'> }) {
  return (
    <Card shadow="sm" p="lg" radius="md" withBorder>
      <Group position="apart" mt="md" mb="xs">
        <Text weight={500}>{props.data.type}</Text>
        <Badge color="pink" variant="light">
          {props.data.status}
        </Badge>
      </Group>

      <Button variant="light" color="blue" fullWidth mt="md" radius="md">
        Lend
      </Button>
    </Card>
  );
}

export function Lending(props: { email?: string; status?: string }) {
  const { data: list, isLoading } = useList<Tables<'vaults'>>({ resource: 'vaults' });

  return (
    <Flex justify="space-around" direction="column" gap="60px">
      <Box>
        Hey, {props.email}! You are {props.status}
      </Box>

      <Flex justify="center">
        {isLoading || !list ? <>Loading...</> : list.data.map((val) => <Vault key={val.id} data={val} />)}
      </Flex>
    </Flex>
  );
}
