export const environment = {
  production: false,
  supabaseUrl: 'https://qunkgbmxmxmjponyxzdu.supabase.co',
  supabaseKey: 'sb_publishable_2an39B-QMQpwkuaCYfg1Bw_EgWoC-SF',
  services: {
    default: 'https://residential-management-program-1.onrender.com',
    usuarios: 'https://usuarios-api-n1qi.onrender.com',
    viviendas: 'https://residential-management-program-1.onrender.com',
    condominios: 'https://residential-management-program-1.onrender.com'
  },
  get apiUrl(): string { return this.services.default; },
  get usuariosApiUrl(): string { return this.services.usuarios; }
};



