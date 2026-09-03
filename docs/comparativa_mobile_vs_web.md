# Comparativa Exhaustiva: Mobile (Flutter) vs Web (Angular)

> **Fecha:** 2 de Septiembre, 2026  
> **Proyecto:** Haven - Residential Management Program  
> **Objetivo:** Identificar las discrepancias funcionales, pantallas faltantes y estado de desarrollo entre ambas plataformas.

---

## 📊 Resumen Ejecutivo

| Módulo / Funcionalidad | Mobile (Flutter) | Web (Angular) | Estado / Discrepancia |
| :--- | :---: | :---: | :--- |
| **Gestión de Viviendas (CRUD)** | ✅ Sí (`viviendas_list.dart`) | ❌ No existe | **Exclusivo de Mobile**. Falta implementarlo en Web. |
| **Acceso a Viviendas en Admin** | ✅ Tarjeta "🏠 Inmuebles" | ❌ No existe | Falta la tarjeta de acceso en el Dashboard de Admin Web. |
| **Mi Perfil (Edición de datos)** | ⚠️ Comentado / Deshabilitado | ✅ Sí (`/perfil`) | **Web está más avanzado**. En Mobile está comentado en código. |
| **Detalle de Residente (Drawer)** | ❌ No existe | ✅ Sí (`residentes-detalle`) | **Exclusivo de Web**. Mobile solo tiene tabla estática. |
| **Alta Manual de Residentes (Admin)** | 🗑️ Eliminado (`admin_form.dart` borrado) | ⚠️ Sigue presente (`residentes-form`) | Mobile ya se adaptó al nuevo modelo de auto-registro; Web aún tiene el formulario antiguo. |
| **Login con Google (OAuth)** | ✅ Sí | ✅ Sí | Ambos sincronizados con Supabase Auth. |
| **Login tradicional (Email/Password)** | ✅ Sí (con toggle Residente/Staff) | ✅ Sí (con toggle Residente/Staff) | Funcionalidad idéntica. |
| **Menú de Usuario (Avatar/Dropdown)** | ⚠️ Botones planos en Header | ✅ Dropdown flotante (`UserMenuComponent`) | Web tiene mejor ergonomía de navegación. |
| **Dashboards de Residente y Vigilante** | ✅ Vistas base | ✅ Vistas base | Ambos con estado inicial similar. |

---

## 📱 1. ¿Qué tiene Mobile que NO tiene Web? (Extras de Mobile)

### A. Módulo Completo de Gestión de Viviendas (`viviendas_list.dart`)
Mobile ya cuenta con una vista dedicada para administrar el inventario de casas/departamentos:
* **Listado de Viviendas:** Consume `GET /api/Viviendas` desde el microservicio `Viviendas.Api`.
* **Crear Vivienda:** Modal de formulario que envía `numeroCasa` y `tipo` vía `POST /api/Viviendas`.
* **Editar Vivienda:** Permite actualizar datos del inmueble vía `PUT /api/Viviendas/{id}`.
* **Eliminar Vivienda:** Acción destructiva con confirmación vía `DELETE /api/Viviendas/{id}`.
* **Acceso desde Admin Dashboard:** Tarjeta azul con icono `🏠` etiquetada como **"INMUEBLES · Gestión de Viviendas"**.

> 💡 **Impacto en Web:** En Web no existe ninguna ruta, servicio ni componente para `/viviendas`. Si el administrador entra desde Web, no puede gestionar las viviendas.

### B. Eliminación anticipada del Formulario de Alta de Residentes
* En el commit reciente de `main`, el equipo de Mobile **eliminó por completo `admin_form.dart`**.
* En la lista de residentes de Mobile (`residentes_list.dart`), **ya no existe el botón "Agregar residente"** ni el botón "Agregar primer residente" en el estado vacío.
* El texto del empty state en Mobile dice: *"Los residentes que se registren en la plataforma aparecerán aquí"*.

---

## 💻 2. ¿Qué tiene Web que NO tiene Mobile? (Extras de Web / De menos en Mobile)

### A. Módulo "Mi Perfil" Completamente Implementado
* **Web:** Tiene la página `/perfil` con formulario reactivo para Nombre, Apellidos y Teléfono, validaciones, badges de estado y conexión real al endpoint `/api/auth/completar-perfil`.
* **Mobile (De menos):**
  * En `mobile/lib/Widgets/header_bar.dart` (líneas 113-157), el botón que navega a `PerfilScreen` **está comentado en código**:
    ```dart
    /*
    // Funcionalidad de editar residente / perfil comentada temporalmente
    InkWell(
      onTap: () { Navigator.push(..., PerfilScreen(...)); },
      ...
    */
    ```
  * En `mobile/lib/Pages/perfil_screen.dart` (líneas 37-47), la función para guardar cambios `_save()` **también está comentada**:
    ```dart
    Future<void> _save() async {
      // Funcionalidad de editar residente comentada temporalmente
      /*
      if (!_formKey.currentState!.validate()) return;
      await widget.controller.completarPerfil(...);
      */
    }
    ```
  * **Conclusión:** La app móvil NO permite a los usuarios editar su perfil porque los desarrolladores comentaron la función para evitar el error del backend.

### B. Slide-Over Drawer de "Detalle de Residente" (`residentes-detalle.component.ts`)
* **Web:** Al hacer clic en cualquier fila del directorio de residentes, se despliega suavemente un Drawer lateral a media pantalla (`520px`) con:
  * Avatar con iniciales dinámicas.
  * Tag de estatus (Activo / Inactivo).
  * Rol del usuario (Residente Haven).
  * Teléfono, correo electrónico, fecha de alta e identificador único (UUID).
  * Accesibilidad completa (`aria-modal`, cierre con tecla `Esc` y clic exterior).
* **Mobile (De menos):** Solo muestra un `DataTable` plano. Las filas **no son clickeables** y no hay vista ni modal para inspeccionar el detalle del residente.

### C. Menú de Usuario Flotante (`user-menu.component.ts`)
* **Web:** Cuenta con un componente desacoplado e independiente en la cabecera con avatar responsivo, dropdown flotante, navegación rápida a Mi Perfil y botón estilizado de Logout.
* **Mobile:** Tiene elementos fijos en el `HeaderBar` que ocupan espacio horizontal y esconden textos en pantallas pequeñas.

### D. Formulario Antiguo de Alta Manual de Residentes (`residentes-form.component.ts`)
* **Web:** Todavía mantiene el drawer de creación de residentes (con campo de email y contraseña temporal) y la ruta `/dashboard/admin/residentes/nuevo`.
* **Mobile:** Ya lo eliminó por completo.

---

## 🎯 Conclusiones y Próximos Pasos Recomendados

1. **Para equiparar Web con Mobile:**
   * Crear el módulo **Viviendas** en Web (listar, agregar, editar, eliminar) consumiendo el nuevo servicio `https://viviendas-api.onrender.com/api/Viviendas`.
   * Agregar la tarjeta de **Gestión de Viviendas** en `admin-dashboard.component.ts`.

2. **Para limpiar Web (alineado al nuevo modelo de Onboarding):**
   * Quitar el botón de **"Agregar residente"** en la cabecera y el empty state de `residentes-list.component.ts`.
   * Desactivar o retirar el componente `residentes-form.component.ts` (igual que hizo Mobile con `admin_form.dart`).

3. **Para Mobile cuando el Backend se estabilice:**
   * Descomentar el botón de `Mi Perfil` en `header_bar.dart`.
   * Descomentar la llamada `completarPerfil` en `perfil_screen.dart`.
