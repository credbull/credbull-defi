import { PostgrestError } from '@supabase/supabase-js';
import { SiweError } from 'siwe';

export type ServiceResponse<T> = { error?: Error | PostgrestError | SiweError | null; data?: T | null };
