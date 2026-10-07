import { createClient, SupabaseClient } from '@supabase/supabase-js';

export function createSupabaseClient(
  url: string,
  key: string,
  accessToken?: string,
): SupabaseClient {
  return createClient(url, key, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    ...(accessToken
      ? { global: { headers: { Authorization: `Bearer ${accessToken}` } } }
      : {}),
  });
}
