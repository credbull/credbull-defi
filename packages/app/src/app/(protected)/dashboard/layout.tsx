'use client';

import {
  AppShell,
  Box,
  Burger,
  Button,
  Footer,
  Group,
  Header,
  MediaQuery,
  Navbar,
  ScrollArea,
  Text,
} from '@mantine/core';
import { Dispatch, ReactNode, SetStateAction, useState, useTransition } from 'react';

import { signOut } from '@/app/(auth)/actions';
import { LinkWallet } from '@/app/(protected)/dashboard/link-wallet';

const AppHeader = ({ opened, setOpened }: { opened: boolean; setOpened: Dispatch<SetStateAction<boolean>> }) => {
  return (
    <Header height={{ base: 50, md: 70 }} p="md">
      <div style={{ display: 'flex', alignItems: 'center', height: '100%' }}>
        <MediaQuery largerThan="sm" styles={{ display: 'none' }}>
          <Burger opened={opened} onClick={() => setOpened((o) => !o)} size="sm" mr="xl" />
        </MediaQuery>

        <Group position="apart" grow w="100%">
          <Text>Credbull</Text>

          <LinkWallet />
        </Group>
      </div>
    </Header>
  );
};

const AppNavbar = ({ opened }: { opened: boolean }) => {
  const [, startTransition] = useTransition();

  return (
    <Navbar p="md" hiddenBreakpoint="sm" hidden={!opened} width={{ sm: 200, lg: 300 }}>
      <Navbar.Section mt="xs">
        <Text>Menu</Text>
      </Navbar.Section>

      <Navbar.Section grow component={ScrollArea} mx="-xs" px="xs">
        <Text>Dashboard</Text>
        <Text>Settings</Text>
      </Navbar.Section>
      <Navbar.Section>
        <Button onClick={() => startTransition(() => signOut())}>Logout</Button>
      </Navbar.Section>
    </Navbar>
  );
};

const AppFooter = () => {
  return (
    <Footer height={60} p="md">
      Footer
    </Footer>
  );
};

export default function AppLayout(props: { children: ReactNode }) {
  const [opened, setOpened] = useState(false);

  return (
    <AppShell
      navbarOffsetBreakpoint="sm"
      header={<AppHeader opened={opened} setOpened={setOpened} />}
      navbar={<AppNavbar opened={opened} />}
      footer={<AppFooter />}
    >
      {props.children}
    </AppShell>
  );
}
