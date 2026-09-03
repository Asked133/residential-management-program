export const environment = {
  production: false,
  supabaseUrl: 'https://qunkgbmxmxmjponyxzdu.supabase.co',
  supabaseKey: 'sb_publishable_2an39B-QMQpwkuaCYfg1Bw_EgWoC-SF',
  services: {
    default: 'https://viviendas-api.onrender.com',
    usuarios: 'https://usuarios-api-n1qi.onrender.com',
    viviendas: 'https://viviendas-api.onrender.com',
    condominios: 'https://viviendas-api.onrender.com'
  },
  get apiUrl(): string { return this.services.default; },
  get usuariosApiUrl(): string { return this.services.usuarios; }
};



