import { PostgrestError } from '@supabase/supabase-js';
import { SiweError } from 'siwe';

export type ServiceResponse<T> = { error?: null; data: T } | { error: Error | PostgrestError | SiweError; data?: null };
