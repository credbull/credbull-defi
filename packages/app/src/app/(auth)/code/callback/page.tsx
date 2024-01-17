import CodeCallback from '@/components/auth/code-callback';

export default async function CodeCallbackRoot({ searchParams }: { searchParams: { code?: string } }) {
  return <CodeCallback searchParams={searchParams} />;
}
