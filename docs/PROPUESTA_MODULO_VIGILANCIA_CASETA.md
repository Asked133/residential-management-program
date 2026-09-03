# 🛡️ Propuesta y Especificación: Módulo de Vigilancia y Control de Caseta (Haven)

**Estado:** Documentado para sprint futuro  
**Destinatarios:** Equipo de Desarrollo (Web, Mobile y Backend)

---

## 📌 1. Objetivo del Módulo de Vigilancia

Brindar una interfaz ágil, de alto contraste y respuesta en tiempo real para el personal de seguridad en las casetas de acceso (vehicular y peatonal) de **Haven**.

---

## 🎯 2. Requerimientos Funcionales Propuestos

### 1. Registro Rápido de Entrada (Fast Entry)
* **Campos principales:**
  * Nombre del visitante / conductor.
  * Vivienda destino (Ej. *Casa 42 - Privada Roble*).
  * Tipo de acceso: *Visita personal*, *Delivery / Comida (UberEats, Didi)*, *Paquetería (Amazon, MercadoLibre)*, *Servicio técnico*.
  * Placas vehiculares (opcional para peatones).
  * Tipo de identificación retenida (*INE/IFE*, *Licencia*, *Gafete de empresa*, *Sin retención*).
* **Acción:** Registro con un solo click y confirmación de apertura de pluma/barrera.

### 2. Validador de Pase Digital (Fast Pass QR / PIN de Residente)
* Validación de códigos de 6 dígitos generados por los residentes desde su app.
* Escaneo de código QR en caseta con feedback inmediato (muestra residente anfitrión, vivienda y vigencia).

### 3. Bitácora en Vivo de Visitas Activas
* Tabla en tiempo real de personas y vehículos que se encuentran actualmente dentro del condominio.
* Botón de **"Registrar Salida"** con devolución de identificación y cálculo de tiempo de estancia.

### 4. Padrón Vehicular Rápido
* Buscador instantáneo por placas o número de casa para identificar propietarios de vehículos estacionados o sospechosos.

### 5. Botón de Alerta / Incidencias en Caseta
* Notificación directa y de alta prioridad al Administrador General en caso de eventos de seguridad.

---

## 🗄️ 3. Modelo de Datos y Endpoints Sugeridos

```csharp
// DTOs sugeridos para .NET C# / Supabase
public class RegistrarVisitaDto
{
    public string NombreVisitante { get; set; } = string.Empty;
    public string CasaDestino { get; set; } = string.Empty;
    public string? Placas { get; set; }
    public string TipoVisita { get; set; } = "Visita";
    public string? Identificacion { get; set; }
}

public class ValidarPaseDto
{
    public string Pin { get; set; } = string.Empty;
}
```

* `POST /api/caseta/visitas` — Registrar entrada de visita.
* `GET /api/caseta/visitas/activas` — Listar visitantes actualmente en el residencial.
* `PUT /api/caseta/visitas/{id}/salida` — Marcar salida.
* `POST /api/caseta/validar-pase` — Validar PIN de Fast Pass.

---
*Este documento queda archivado como base técnica para la implementación del módulo en el sprint correspondiente.*
