# 🏛️ Haven — Sistema de Diseño Web y Guía de Vistas por Rol

**Fecha:** Febrero 2026  
**Alcance:** Exclusivamente Frontend Web (`web/`) con guía de referencia visual para Mobile  
**Autor:** César Gómez (Web Developer)

---

## 🎯 1. Principios de Diseño y Alcance del Sprint

El sistema visual de **Haven** mantiene una estética limpia, ergonómica y funcional basada en la paleta Slate y componentes directos, sin sobrecargar con módulos no solicitados:

1. **Autenticación Diferenciada**:
   - **Portal Residentes (Predeterminado)**: Acceso para condóminos con credenciales y opción de acceso con Google.
   - **Acceso Institucional (Admin & Caseta)**: Acceso restringido por política condominal; **Google Auth está deshabilitado** y se requiere correo corporativo y contraseña.
   - **Navegación Rápida Demo**: Botones de redirección directa (`/dashboard/admin`, `/dashboard/residente`, `/dashboard/vigilante`) para verificar todas las pantallas con un solo click.

2. **Paneles y Vistas por Rol (`web/src/app/features/dashboard/`)**:
   - **Panel de Administración (`/dashboard/admin`)**:
     - Vista central con acceso directo a la **Gestión y Registro de Residentes** (`/dashboard/admin/residentes`) y drawer lateral de alta express.
     - Switcher superior de vistas.
   - **Portal Residente (`/dashboard/residente`)**:
     - Pantalla de bienvenida para condóminos con acceso a sus datos de vivienda y accesos.
     - Switcher superior de vistas.
   - **Control de Caseta / Vigilancia (`/dashboard/vigilante`)**:
     - Pantalla de control de caseta para guardias y seguridad de accesos.
     - Switcher superior de vistas.

---

## 🎨 2. Paleta de Colores y Tokens

| Token | Hex | Uso en Haven |
| :--- | :--- | :--- |
| **Slate Dark** | `#0F172A` | Fondos de botones principales, tipografía de encabezados |
| **Slate Border** | `#E2E8F0` | Bordes de tarjetas y separadores |
| **Slate Light** | `#F8FAFC` / `#F1F3F7` | Fondo principal de dashboards y portal de login |
| **Emerald Accent** | `#059669` | Distintivo del Portal Residente y acciones positivas |
| **Amber Accent** | `#D97706` | Distintivo de Caseta / Vigilancia y advertencias |
| **Indigo Accent** | `#4F46E5` | Distintivo del Panel de Administración |

---

## 📦 3. Registro de Rutas y Navegación

| Ruta | Componente | Rol Autorizado |
| :--- | :--- | :--- |
| `/login` | `LoginComponent` | Público (Pestañas: Residente / Admin) |
| `/dashboard/admin` | `AdminDashboardComponent` | `administrador` |
| `/dashboard/admin/residentes` | `ResidentesListComponent` | `administrador` |
| `/dashboard/residente` | `ResidenteDashboardComponent` | `residente` |
| `/dashboard/vigilante` | `VigilanteDashboardComponent` | `vigilante` |

---
*Documento alineado estrictamente a los requerimientos del sprint y al diseño base de Haven.*
