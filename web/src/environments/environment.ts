export const environment = {
  production: true,
  supabaseUrl: (import.meta as any).env?.['NG_APP_SUPABASE_URL'] || 'https://qunkgbmxmxmjponyxzdu.supabase.co',
  supabaseKey: (import.meta as any).env?.['NG_APP_SUPABASE_ANON_KEY'] || 'sb_publishable_2an39B-QMQpwkuaCYfg1Bw_EgWoC-SF',
  apiUrl: (import.meta as any).env?.['NG_APP_API_URL'] || 'https://residential-management-program-1.onrender.com'
};
