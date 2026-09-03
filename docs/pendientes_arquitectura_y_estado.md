# 📌 Pendientes y Estado Arquitectónico del Proyecto

Documento de referencia para el equipo y agentes de desarrollo sobre el estado actual de las capas de Backend y la gestión de estado en Móvil.

---

## 1. ⚙️ Estado de la Arquitectura en Backend (`/backend`)

* **Estado actual**:
  - Actualmente el backend está estructurado como un **proyecto único en .NET (Web API)** dentro de `HavenApi.csproj`.
  - La organización interna se basa en carpetas directas:
    - `Controllers/` (puntos de entrada HTTP y autenticación).
    - `DTOs/` (modelos de transferencia de datos).
    - `Data/` (conexión a Supabase / base de datos).
    - `Services/` (lógica de negocio e interfaces como `ISupabaseService`).
* **Pendiente / Precaución**:
  - **No asumir** que ya existe una separación formal en múltiples proyectos/capas (`Domain / Application / Infrastructure / API`).
  - Si se planifica una refactorización hacia *Clean Architecture*, debe acordarse previamente con el equipo para no romper referencias de namespaces ni la configuración actual de despliegue en Docker/Render.

---

## 2. 📱 Manejador de Estado en Flutter Móvil (`/mobile`)

* **Estado actual**:
  - Ángel (Mobile Developer) actualmente utiliza el patrón nativo de Flutter **`ChangeNotifier` con `AnimatedBuilder`** (mediante la clase `AppController extends ChangeNotifier`).
  - No se están utilizando paquetes externos pesados de gestión de estado como `flutter_bloc`, `riverpod`, `provider` ni `get`.
  - Las dependencias activas en `pubspec.yaml` son: `supabase_flutter`, `http`, `flutter_dotenv` y `google_fonts`.
* **Pendiente / Precaución**:
  - **No imponer** un gestor de estado externo nuevo (ej. Bloc o Riverpod) sin consultar y validar con Ángel.
  - Mantener la coherencia del estado utilizando `ChangeNotifier` o la arquitectura reactiva nativa existente para evitar fricciones en el desarrollo móvil.

---

> [!IMPORTANT]
> **Regla para Agentes y Desarrolladores:**
> Siempre verificar el código fuente activo antes de proponer cambios estructurales o añadir paquetes que compitan con la arquitectura existente.
