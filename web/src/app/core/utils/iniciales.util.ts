export function getInitials(nombre?: string, apellidos?: string): string {
  const n = (nombre || '').trim().charAt(0);
  const a = (apellidos || '').trim().charAt(0);
  const res = `${n}${a}`.toUpperCase();
  return res || 'R';
}
