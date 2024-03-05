'use client';

import {
  AppShell,
  Burger,
  Footer,
  Group,
  Header,
  MediaQuery,
  NavLink,
  Navbar,
  ScrollArea,
  Text,
  Title,
} from '@mantine/core';
import { User } from '@supabase/gotrue-js/dist/module/lib/types';
import { IconBug, IconBusinessplan, IconChevronRight, IconLogout } from '@tabler/icons';
import Link from 'next/link';
import { useSelectedLayoutSegment } from 'next/navigation';
import { Dispatch, ReactNode, SetStateAction, useEffect, useState, useTransition } from 'react';

import { createClient } from '@/clients/supabase.client';

import { Routes } from '@/utils/routes';

import { signOut } from '@/app/(auth)/actions';
import { LinkWallet } from '@/app/(protected)/dashboard/link-wallet';

const AppHeader = ({ opened, setOpened }: { opened: boolean; setOpened: Dispatch<SetStateAction<boolean>> }) => {
  const [user, setUser] = useState<User | undefined>(undefined);

  useEffect(() => {
    const supabase = createClient();

    supabase.auth.getSession().then(({ data }) => {
      setUser(data.session?.user);
    });
  }, []);

  return (
    <Header height={{ base: 50, md: 70 }} p="md">
      <div style={{ display: 'flex', alignItems: 'center', height: '100%' }}>
        <MediaQuery largerThan="sm" styles={{ display: 'none' }}>
          <Burger opened={opened} onClick={() => setOpened((o) => !o)} size="sm" mr="xl" />
        </MediaQuery>

        <Group position="apart" grow w="100%">
          <Title order={1}>Credbull DeFI</Title>
          <LinkWallet user={user} />
        </Group>
      </div>
    </Header>
  );
};

const AppNavbar = ({ opened }: { opened: boolean }) => {
  const [, startTransition] = useTransition();
  const segment = useSelectedLayoutSegment();

  return (
    <Navbar p="md" hiddenBreakpoint="sm" hidden={!opened} width={{ sm: 200, lg: 300 }}>
      <Navbar.Section mt="xs">
        <Title order={3}>Menu</Title>
      </Navbar.Section>

      <Navbar.Section mx="-xs" px="xs">
        <NavLink
          component={Link}
          href={Routes.DASHBOARD_WITH_UPSIDE}
          label="Lend"
          icon={<IconBusinessplan size={16} stroke={1.5} />}
          rightSection={<IconChevronRight size={12} stroke={1.5} />}
          variant="subtle"
          active={segment === null}
        />

        <Text></Text>
      </Navbar.Section>
      <Navbar.Section grow component={ScrollArea} mx="-xs" px="xs">
        <NavLink
          component={Link}
          href={Routes.DEBUG}
          label="Debug"
          icon={<IconBug size={16} stroke={1.5} />}
          rightSection={<IconChevronRight size={12} stroke={1.5} />}
          variant="subtle"
          active={segment === 'debug'}
        />
      </Navbar.Section>

      <Navbar.Section>
        <NavLink
          onClick={() => startTransition(() => signOut())}
          label="Sign out"
          icon={<IconLogout size={16} stroke={1.5} />}
        />
      </Navbar.Section>
    </Navbar>
  );
};

const AppFooter = () => {
  return (
    <Footer height={60} p="md">
      <Group position="center" spacing="xs">
        <Text size="xs" color="gray" weight={500}>
          © 2024 Credbull DeFI
        </Text>
      </Group>
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
