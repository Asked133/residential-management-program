# Residential Management Program (Sistema de Gestion Residencial)

![Estado del Proyecto](https://img.shields.io/badge/Estado-Desarrollo_Activo-blue)
![Licencia](https://img.shields.io/badge/Licencia-MIT-green)
![Curso](https://img.shields.io/badge/Curso-Topico_1:_Microservicios_--_7o_Semestre-purple)

Plataforma integral para la administracion de fraccionamientos, condominios y residencias. El sistema busca mejorar la comunicacion entre administradores y residentes, gestionar el cobro de cuotas, controlar el acceso de visitantes y facilitar la reserva de areas comunes.

Actualmente, el proyecto se encuentra en desarrollo activo, con un enfoque en la aplicacion movil construida en Flutter y respaldada por Supabase.

---

## Alcance y Modulos del Sistema

El proyecto contempla la implementacion de los siguientes modulos funcionales, los cuales ya se estan reflejando en las pantallas de la aplicacion movil:

### 1. Gestion de Residentes y Propiedades
* Registro de viviendas (casas, departamentos, lotes).
* Catalogo de residentes (propietarios e inquilinos) y contactos de emergencia.
* Detalle e informacion por vivienda.

### 2. Administracion Financiera y Cuotas
* Generacion de cuotas ordinarias y extraordinarias.
* Seguimiento de estados de cuenta individuales y del condominio.
* Registro e historial de pagos.

### 3. Control y Reserva de Amenidades
* Calendario e interfaz de reservacion para areas comunes.
* Control de reglamentos y horarios de uso.

### 4. Control de Acceso y Visitas
* Panel para vigilantes y control de seguridad.
* Registro de visitas esperadas y proveedores.
* Generacion de pases de acceso temporal.

### 5. Avisos e Incidencias
* Tablon de anuncios y boletines informativos.
* Sistema de tickets para reporte y seguimiento de fallas en areas comunes.

---

## Tecnologias Principales

* **Frontend Movil:** Flutter / Dart
* **Backend y Base de Datos:** Supabase (PostgreSQL, Auth)
* **Integracion Continua (CI/CD):** GitHub Actions
* **Testing:** flutter_test, integration_test, mocktail

---

## Estructura del Repositorio

```text
residential-management-program/
├── .github/              # Flujos de trabajo de GitHub Actions (CI/CD)
├── docs/                 # Documentacion del proyecto (especificaciones)
├── mobile/               # Codigo fuente de la aplicacion Flutter
│   ├── lib/              # Logica de negocio, pantallas, servicios y widgets
│   ├── test/             # Pruebas unitarias y de widgets (cobertura de 9 pantallas)
│   └── integration_test/ # Pruebas End-to-End (E2E)
├── web/                  # Codigo de la version web
├── backend/              # Infraestructura del proyecto 
└── README.md             # Documentacion principal del repositorio
```

---

## CI/CD y Pruebas Automatizadas

El proyecto cuenta con un flujo completo de integracion y despliegue continuo configurado en `.github/workflows/`:

* **Flutter CI:** Ejecuta analisis de codigo (Linter), pruebas unitarias, pruebas de widgets y pruebas de integracion nativas en Linux en cada commit o Pull Request en el directorio `mobile/`. Ademas, envia notificaciones en tiempo real a Discord con el estado del build.
* **Google Play Deploy:** Flujo manual que incrementa automaticamente la version de la aplicacion (`build_number`) en el `pubspec.yaml`, compila el Android App Bundle (AAB) firmado y lo publica en las diferentes pistas de Google Play Console (Internal, Alpha, Beta o Production).

La aplicacion mantiene una arquitectura orientada a pruebas, contando con configuraciones de `Unit Tests` y `Widget Tests` a traves de Mocktail para todas sus vistas principales, y un entorno seguro para ejecutar `Integration Tests` E2E sin ensuciar la base de datos de produccion.

---

## Notas de Desarrollo

> [!NOTE]
> Este documento se actualizara conforme se vayan integrando los modulos web y backend al flujo de trabajo actual, y se definan nuevos requerimientos formales en la carpeta `docs/product/`.
