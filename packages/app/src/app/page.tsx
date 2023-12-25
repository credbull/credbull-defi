import Link from 'next/link';

import { Routes } from '@/utils/routes';

export default function Index() {
  return <Link href={Routes.LOGIN}>Login</Link>;
}
