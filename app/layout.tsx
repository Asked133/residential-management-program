import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Haven — Gestión de Condominios',
  description: 'Panel de administración SaaS para gestión de condominios',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="es">
      <body>{children}</body>
    </html>
  );
}
