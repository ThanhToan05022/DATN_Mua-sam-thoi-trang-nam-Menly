class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://lihnuaymkrwmgdspnkux.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_QayBQo9iCpdtkNg16h6EFQ_m_DD8vXs',
  );
}
