import { mockTokenAddress } from '@/app/(protected)/dashboard/actions';
import { Debug } from '@/app/(protected)/dashboard/debug/debug-new';

export default async function DebugRoot() {
  const data = await mockTokenAddress();
  return <Debug mockTokenAddress={data} />;
}
