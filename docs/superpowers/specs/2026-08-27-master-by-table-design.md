# Diseño: ejecución de maestros (e históricos) centralizada POR TABLA

Fecha: 2026-08-27
Estado: aprobado en conversación, pendiente de plan de implementación

## 1. Problema

MCC agenda el trabajo **por extensión**. "Run All Master" ejecuta el paso Master de cada
extensión, y cada uno abre y recorre por su cuenta las tablas maestras que le tocan.

Medición sobre el repositorio (script sobre `src/Adapters/**/*.al`, buscando `Record "X"`,
`Database::"X"` y `tabledata X`):

| Tabla maestra | Extensiones que la recorren |
|---|---|
| **Customer** | **7** — BC, BELLON, DESB, DRLOC, PCM, SD, TU |
| **Item** | **6** — BC, BELLON, DESB, DRLOC, FE, LSLOC |
| LSC POS Terminal | 4 — BELLONPOS, DXP, LSFE, LSLOC |
| Bank Account | 3 — BELLON, DRLOC, VP |
| Vendor | 3 — BELLON, DRLOC, VP |
| 16 tablas más | 1-2 cada una |

**47 recorridos completos sobre 21 tablas maestras.** Customer se recorre entera siete veces,
cada una tomando su propio lock. Consecuencias observadas en producción:

- Lentitud: BC-P3 Customer tardó 419 s y BC-P3 Item 327 s en una corrida real, sobre tablas
  que en su mayoría no tenían nada que migrar.
- Contención: dos extensiones que escriben Customer se serializan entre sí; la segunda espera.
- La categoría Master aparece "congelada" sin estarlo, porque MCC no puede emitir heartbeat
  mientras `Codeunit.Run()` está activo.
- Los conceptos de migración por campos muestran `Legacy/New Table ID = 0`, así que el Run Log
  siempre dice "No aplica" y `0/0`: no hay señal de progreso ni de completitud.

## 2. Objetivo

Que la categoría Master haga **una sola pasada por tabla**, aplicando en esa pasada los campos
de todas las extensiones, y que reporte un número real de trabajo pendiente.

## 3. Diseño

### 3.1 Un codeunit por tabla maestra

Familia nueva bajo `src/Master/`, un objeto por tabla:

```
DXR MCC Master Customer      (7 bloques: BELLON, BC, DESB, DRLOC, PCM, SD, TU)
DXR MCC Master Item          (6 bloques)
DXR MCC Master Contact       (1 bloque)
...  21 en total
```

Cada codeunit:

- Declara `Permissions` **sólo de su tabla**. Sustituye bloques como los 301 `tabledata` de
  BELLON Phase2 por uno acotado y auditable.
- Se gobierna con **un tag nuevo por tabla**: `DXR-MCC-MASTER-<TABLA>-20260827`.
- Recorre la tabla **una vez**: `SetLoadFields` con la unión de los campos de todos los bloques,
  `FindSet(false)` (sin UPDLOCK), y por fila evalúa cada bloque; si algún bloque marcó cambio,
  relee la fila con `Get()` bajo bloqueo, reaplica los bloques sobre la fila bloqueada y hace
  `Modify(false)`. Commit cada 500 filas **modificadas**.

Es el patrón ya validado en `DXR MCC BC Migr P3 Customer` y en `MigrateSalesLineFields` de
PCM Phase5: leer sin lock, bloquear sólo lo que cambia, y reevaluar los guards sobre la fila
bloqueada para no reintroducir una pérdida de actualización.

### 3.2 Estructura interna de cada codeunit

```al
procedure ApplyBELLON(var Rec: Record Customer): Boolean
procedure ApplyBC(var Rec: Record Customer): Boolean
...
```

Cada bloque devuelve si cambió algo. El bucle llama a cada bloque dos veces: una sobre la copia
sin bloqueo (para detectar) y otra sobre la fila releída (para aplicar). Se llama a la MISMA
función en ambos casos, de forma que las dos evaluaciones no puedan divergir.

### 3.3 El código se mueve, no se duplica

`MigrateTableExt_CustomerFields` sale de BELLON Phase2 y pasa a ser `ApplyBELLON` dentro de
`Master Customer`. Una sola fuente de verdad por tabla.

**Consecuencia aceptada:** "Run Extension BELLON" deja de migrar campos de maestros; esos pasan
a vivir en la categoría Master. Es intencional.

### 3.4 Upgrade tags

Decisión tomada: **un tag nuevo por tabla**, no reutilizar los per-extensión.

Consecuencia lógica, y por tanto **requisito previo de este trabajo**: en una compañía que ya
migró, el tag nuevo no existe, así que se reaplican todos los bloques. Toda copia incondicional
(`X_DXR := X`) se convierte entonces en una vía activa de pisar un valor bueno con vacío. Antes
de activar el motor nuevo hay que convertir las copias de maestros a la política
**"sólo si el destino sigue en su valor por defecto"**, comparando contra un `Record` en blanco
nunca leído de base — que es type-agnostic y correcto para Text, Code, Decimal, Integer,
Boolean, Date, DateTime y Option por igual.

### 3.5 Métrica de completitud (elimina el "No aplica")

Cada codeunit de tabla expone un conteo: **filas donde algún campo viejo tiene valor y su gemelo
`_DXR` sigue vacío**. Ese número es el trabajo pendiente real y sustituye al `0/0` actual en el
Run Log y en el Gap Report, que hoy no informan nada para migraciones por campos.

### 3.6 Registro y ejecución

- Los conceptos Master por extensión se retiran vía `IsExplicitlyRetiredConcept`. Se aprovecha
  para limpiar esa función, que hoy acumula casos sueltos.
- Entran 21 conceptos nuevos, categoría Master, apuntando a los codeunits por tabla, con el
  ID de su tabla como `Legacy Table ID` y `New Table ID` para que el contador tenga referencia.
- `RunPortfolio` concentra el grueso de la migración en la fase de maestros.
- Cada tabla se ejecuta aislada con `Codeunit.Run` y tag propio: una tabla que falle no tumba
  las demás, y el reintento sólo repite lo que falló. Mismo mecanismo ya aplicado en Phase2.

### 3.7 Históricos

Mismo modelo, en una segunda tanda: un codeunit por tabla histórica, misma estructura de
bloques, mismo aislamiento, misma métrica. Se ejecuta después de que Master esté verificado en
el ambiente real, para no mover las dos cosas a la vez.

## 4. Orden de trabajo

1. Convertir a "sólo si vacío" las copias de maestros que aún son incondicionales.
2. `Master Customer` y `Master Item` — 13 de las 47 pasadas.
3. Las 19 tablas maestras restantes.
4. Retirar los conceptos viejos, cargar los nuevos, limpiar `IsExplicitlyRetiredConcept`.
5. Métrica de completitud en el contador y el Gap Report.
6. Históricos, con el mismo modelo.

## 5. Riesgos

| Riesgo | Mitigación |
|---|---|
| Un `SetLoadFields` que omita un campo que el bloque lee o escribe. Compila bien y falla en runtime. | Verificación programática campo por campo por cada bloque, comparando los campos referenciados contra los declarados. Es el error más probable de todo el refactor. |
| Reaplicar bloques en compañías ya migradas (consecuencia del tag por tabla). | Requisito previo del punto 1: nada sobrescribe un destino que ya tiene valor. |
| Perder un campo al mover el código entre codeunits. | Comparación automática de las asignaciones antes/después: mismo conjunto de pares origen→destino, verificado contra git. |
| Regresión en "Run Extension". | Documentado y aceptado: los maestros viven en la categoría Master. |

## 6. Verificación

- Compilación con `alc.exe` tras cada tabla migrada (0 errores; los warnings AL0432 son
  esperados en este proyecto).
- Chequeo automático de cobertura de `SetLoadFields` por bloque.
- Comparación automática del conjunto de asignaciones contra la versión en git.
- Verificación funcional en el ambiente: correr la categoría Master y confirmar que la métrica
  de completitud llega a cero.
