# Residential Management Program (Sistema de Gestion Residencial)

Proyecto integral para la administracion de fraccionamientos, condominios y residencias. El sistema busca centralizar y mejorar la comunicacion entre administradores y residentes, gestionar el cobro de cuotas, controlar el acceso de visitantes y facilitar la reserva de areas comunes a traves de multiples plataformas.

El desarrollo se encuentra activo y esta dividido en tres componentes principales que conforman el ecosistema completo: una aplicacion movil, un portal web y la infraestructura backend.

---

## Estructura del Repositorio

El proyecto utiliza una arquitectura monorepo organizada en los siguientes directorios principales:

```text
residential-management-program/
├── backend/              # Infraestructura y logica de servidor (API, base de datos)
├── mobile/               # Aplicacion movil (iOS/Android/Linux) para residentes y personal
├── web/                  # Portal web administrativo
├── docs/                 # Documentacion tecnica y requerimientos del proyecto
└── README.md             # Documentacion principal del repositorio
```

---

## Modulos del Sistema

El sistema implementa las siguientes funciones core a traves de sus distintas plataformas:

### 1. Gestion de Residentes y Propiedades
* Registro completo de viviendas (casas, departamentos, lotes).
* Directorio de residentes, propietarios, inquilinos y contactos de emergencia.
* Administracion de la informacion detallada de cada unidad habitacional.

### 2. Administracion Financiera y Cuotas
* Modulo de cobranza y emision de cuotas ordinarias o extraordinarias.
* Seguimiento de los estados de cuenta, tanto individuales como del condominio.
* Registro, conciliacion e historial de pagos realizados.

### 3. Control y Reserva de Amenidades
* Interfaz compartida para la visualizacion y apartado de areas comunes.
* Administracion de cupos, reglamentos y restricciones de horarios.

### 4. Control de Acceso y Visitas
* Panel especializado para el personal de vigilancia.
* Registro anticipado de visitas y proveedores por parte de los residentes.
* Creacion y validacion de accesos temporales.

### 5. Avisos e Incidencias
* Tablon virtual de anuncios y comunicados oficiales.
* Sistema de levantamiento de tickets para el reporte de fallas en la infraestructura comun.

---

## Tecnologias

El stack tecnologico del proyecto abarca:
* **Frontend Movil:** Flutter y Dart, disenado para multiples plataformas.
* **Frontend Web:** Desarrollo del panel de administracion web.
* **Backend y Base de Datos:** Supabase (PostgreSQL) para la persistencia de datos, autenticacion y reglas de seguridad.

---

## Notas de Desarrollo

> [!NOTE]
> La documentacion especifica de producto, historias de usuario y diagramas arquitectonicos se encuentra dentro del directorio `docs/`. Este archivo se mantendra como una referencia de alto nivel del repositorio completo.
