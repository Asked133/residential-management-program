export const environment = {
  production: true,
  supabaseUrl: (import.meta as any).env?.['NG_APP_SUPABASE_URL'] || 'https://qunkgbmxmxmjponyxzdu.supabase.co',
  supabaseKey: (import.meta as any).env?.['NG_APP_SUPABASE_ANON_KEY'] || 'sb_publishable_2an39B-QMQpwkuaCYfg1Bw_EgWoC-SF',
  services: {
    default: (import.meta as any).env?.['NG_APP_API_URL'] || 'https://viviendas-api.onrender.com',
    usuarios: (import.meta as any).env?.['NG_APP_USUARIOS_API_URL'] || 'https://usuarios-api-n1qi.onrender.com',
    viviendas: (import.meta as any).env?.['NG_APP_VIVIENDAS_API_URL'] || 'https://viviendas-api.onrender.com',
    condominios: (import.meta as any).env?.['NG_APP_CONDOMINIOS_API_URL'] || 'https://viviendas-api.onrender.com'
  },
  get apiUrl(): string { return this.services.default; },
  get usuariosApiUrl(): string { return this.services.usuarios; }
};



