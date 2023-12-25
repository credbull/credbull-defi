import { type NextRequest, NextResponse } from 'next/server';

import { createClient } from '@/clients/supabase.middleware';

export async function middleware(request: NextRequest) {
  try {
    const { supabase, response } = createClient(request);
    await supabase.auth.getSession();

    return response;
  } catch (e) {
    return NextResponse.next({ request: { headers: request.headers } });
  }
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
