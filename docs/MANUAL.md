# Manual técnico — DXR Migration Control Center (MCC)

> Basado en lectura directa del código fuente en `src/` (app.json versión 2.2.0.6, publisher Dextra, `target: Cloud`, `application: 28.0.0.0`). Cada afirmación cita el objeto/procedimiento real de donde sale. Donde el código no define algo (p. ej. eventos publicados), se dice explícitamente en vez de inventarlo.

## 1. Qué es MCC

MCC es un **registro central + lanzador** para todas las migraciones de datos de renumeración de IDs `DXR_` del portafolio Dextra (`app.json`, campo `description`). No migra datos por sí mismo: cada extensión dependiente ya tiene sus propios "dispatcher codeunits" de migración (fases, phase dispatchers, etc.); MCC los cataloga, los invoca en el orden correcto, cuenta filas antes/después para detectar gaps, y deja un historial ejecutable/auditable.

- **Dependencias declaradas** (`app.json`): "Facturacion Electronica" (`4ccf94f0-…`) y "Base App DR Localization" (`b269ef93-…`).
- **Rango de IDs propio**: 60000–65000 (`app.json.idRanges`). Los objetos internos usan ese rango; el resto de codeunits/tablas dentro de `#if not ESCUDEA and not BCDX` / `#if not BCDX` pertenecen a extensiones de terceros que MCC referencia por ID en su `permissionset` (ver §5).
- **Símbolo `BCDX`**: `preprocessorSymbols = ["BCDX"]` en `app.json`. Con `BCDX` activo se compila un subconjunto reducido de codeunits de terceros (ver `DXRMCCPermissionSet.PermissionSet.al`, bloques `#if not ESCUDEA and not BCDX` / `#if not BCDX`) — es decir, esta compilación específica excluye referencias a extensiones ausentes en este entorno.

## 2. Modelo de datos (tablas)

| Tabla | ID | Rol |
|---|---|---|
| `DXR MCC Extension` | 60000 | Una fila por extensión del portafolio: `Code`, `Name`, `App ID` (Guid), `Order No.` (orden de dependencia), FlowFields `Total Concepts`/`Total Gap`/`Last Run DateTime`. |
| `DXR MCC Concept` | 60001 | Una fila por unidad de migración verificable: `Extension Code`, `Phase Code`, `Sequence No.`, `Dispatcher Codeunit ID`, `Legacy Table ID`, `New Table ID`, `Old/Migrated Record Count`, `Gap`, `Status` (Not Counted/Pending/Running/Completed/Completed With Gaps/Error/Not Row-Based/Completed (Fallback)/Skipped), `Category` (Setup/Master/Accounting/Historic/Other/Reporting — "Master/Accounting" queda solo como valor legado), `Execution Band` (Normal / Deferred-Bulk), `Blocked`/`Blocked Reason`, `Upgrade Tags` (mantenido a mano por el operador), `Retired`. |
| `DXR MCC Run Request` | 60003 | Una fila por ejecución en background (Scope: Concept/Extension/Portfolio/Category/RecountAll). Trae checkpointing (`Checkpoint Key`, `Processed Count`), heartbeat (`Last Heartbeat`), reintentos (`Attempt No.`), cancelación cooperativa (`Cancel Requested`), notificación (`Notified`), y timing por categoría (`Setup/Master/Accounting/Historic/Other/Reporting Started/Completed At`+`Duration`+`Phase Status`), más soporte multi-tenant (`Tenant Run ID`, `Company Sequence`, `Tenant Chain`). |
| `DXR MCC Migration Lock` | 60004 | Mutex global cross-company: una única fila fija por `Lock Code = 'DXR-MCC-MIGRATION-GLOBAL.'`, guardada en una "compañía coordinadora" (la primera compañía por nombre, ver `GetCoordinatorCompany`). |
| `DXR MCC Run Log` | 60002 | Historial de auditoría por concepto/paso ejecutado (referenciada por `DXR MCC Executor` y `DXR MCC Portfolio Perm. Mgt.`). |
| `DXR MCC Bulk Checkpoint` | — | Checkpoint de reanudación fila-a-fila (`Last Source Record ID`, `Processed Count`, `Inserted Count`, `Completed`) usado por `DXR MCC Fallback Migrator` para reanudar copias masivas sin repetir filas. |

## 3. Codeunits centrales y flujo de ejecución

### 3.1 Registro (`DXR MCC Registry Loader`, cod. 60012)

`OnRun` ejecuta, en orden: `LoadExtensions()` → `LoadConcepts()` → `UnblockDespachoBase()`. Es **idempotente**: usa dos helpers internos —

- `InsExt(Code2, Name2, AppIdText, OrderNo, Notes2)`: hace upsert por `Code` en `DXR MCC Extension`.
- `InsConcept(ExtCode, PhaseCode, SeqNo, Desc, DispatcherId, LegacyId, NewId, CategoryCode)`: hace upsert por la tripleta `(Extension Code, Phase Code, Sequence No.)` en `DXR MCC Concept`. `CategoryCode` es texto corto (`'SETUP'`,`'MA'`,`'MASTER'`,`'ACCOUNTING'`,`'HIST'`,`'REPORTING'`, cualquier otro → `Other`), traducido por `CategoryOption()`.

Estos dos helpers son **`local procedure`**: solo el propio Registry Loader puede llamarlos; una extensión externa no puede invocarlos directamente (ver §6 sobre cómo registrar datos desde fuera).

Se invoca desde dos puntos:

- `DXR MCC Registry Install` (cod. 60019, `Subtype = Install`) → `OnInstallAppPerCompany`.
- `DXR MCC Registry Upgrade` (cod. 60020, `Subtype = Upgrade`) → `OnUpgradePerCompany`.
- Manualmente vía la acción **"Reload Registry"** en la página principal (60020, `DXR Migration Control Center`).

### 3.2 Ejecución (`DXR MCC Executor`, cod. 60011)

Punto único de orquestación. Procedimientos públicos relevantes:

- `RunConcept` / `RunExtension` / `RunCategory` / `RunPortfolio` / `RecountAllConcepts`: ejecutan de forma **síncrona** (con `ProgressWindow` de BC) cuando se llaman desde una acción de página (`RunRequestEntryNo = 0`), o de forma **silenciosa** (sin diálogo, actualizando `Current Step`/`Last Heartbeat` en el Run Request) cuando corren dentro de una tarea en background.
- `ScheduleConcept` / `ScheduleExtension` / `ScheduleCategory` / `SchedulePortfolio` / `ScheduleRecountAll`: crean un `DXR MCC Run Request`, adquieren el lock global (`TryAcquireGlobalLock`) y programan `DXR MCC Background Runner` vía `TaskScheduler.CreateTask` con un timeout de **12 horas** (`MigrationTaskTimeout()`).
- `RunPortfolio` recorre **6 pases de categoría en orden fijo**: `Setup → Master → Accounting → Historic → Other → Reporting` (ordinal 0 a 5). Cada pase corre `RunCategory` sobre **todo el portafolio**, en orden de `Extension."Order No."`, antes de pasar al siguiente pase. Razón documentada en el propio código: datos master/transaccionales/históricos de cualquier extensión pueden referenciar filas de Setup de esa misma extensión o de una anterior, así que Setup debe completarse en todo el portafolio antes de que arranque cualquier otra categoría.
- Dentro de cada categoría, `RunCategory` además separa en dos **bandas de ejecución** (`Execution Band`): `Normal` (0) corre completa en todo el portafolio antes que `Deferred/Bulk` (1) — así las tablas históricas pesadas no bloquean trabajo pequeño.
- Un mismo `Dispatcher Codeunit ID` puede cubrir varias filas de `DXR MCC Concept` (varias tablas en una sola llamada). El Executor invoca cada dispatcher **una sola vez** por grupo (`RunDispatcherGroup`), marca todos sus conceptos como `Running`, ejecuta `Codeunit.Run(DispatcherCodeunitId)`, y luego verifica/cuenta cada concepto del grupo por separado.
- Al terminar el pase `Setup` de una categoría/portafolio, se invoca automáticamente `DXR MCC Portfolio Perm. Mgt.AssignAllPortfolioPermissionSets` (ver §3.4).
- **Bloqueo de codeunits `Subtype = Upgrade`**: `RunDispatcher` mantiene una lista propia (`IsKnownUpgradeCodeunit`) de codeunits marcados `Subtype = Upgrade` en el portafolio, porque BC bloquea `Codeunit.Run()` sobre ellos fuera del proceso de publish/schema-sync (confirmado en el propio comentario del código, con un crash real reproducido el 2026-08-22). Si el dispatcher de un concepto es uno de esos, el Executor nunca lo ejecuta — hay que marcarlo `Blocked` con esa razón.

### 3.3 Background Runner (`DXR MCC Background Runner`, cod. 60013)

`TableNo = "DXR MCC Run Request"`, disparado únicamente por `TaskScheduler` (nunca desde una acción de página directamente). `OnRun`:

1. Si `Cancel Requested` ya estaba marcado, cancela sin empezar.
2. Marca `Status = Running`, sella `Started At`/`Last Heartbeat`, `Commit()`.
3. `TryRunScope` (TryFunction) despacha según `Scope` a `Executor.RunConcept/RunExtension/RunPortfolio/RunCategory/RecountAllConcepts`.
4. Si tuvo éxito → `Completed`/`Failed` según si hubo errores; libera el lock (`ForceReleaseLockForRunRequest`); si es parte de una cadena multi-tenant (`Tenant Chain`), continúa con `DXR MCC Tenant Run Mgt.ContinueTenantChain`.
5. Si falló → reintenta hasta `MaxAttempts() = 5` veces, con un retardo fijo de **5 segundos** entre intentos (`RetryDelay`, reducido desde un backoff exponencial de 1–30 min tras feedback explícito del usuario). El reintento reanuda desde el `Checkpoint Key` guardado, no repite trabajo ya confirmado por los upgrade tags internos de cada dispatcher.
6. `Last Heartbeat` + `Executor.ReconcileStaleRunningRequests` detectan tareas muertas (matadas por la plataforma, p. ej. el timeout SaaS de 12h de `TaskScheduler`) y las marcan `Failed` en vez de dejarlas `Running` para siempre.

### 3.4 Locking cross-company (`DXR MCC Migration Lock Mgt.`, cod. 60016)

Mutex global de una sola fila (`Lock Code = 'DXR-MCC-MIGRATION-GLOBAL.'`), guardado siempre en la "compañía coordinadora" (`GetCoordinatorCompany`: la primera compañía por nombre). `TryAcquireLock`/`ReleaseLock`/`ForceReleaseLockForRunRequest`/`RenewLockForRunRequest` — impide que dos ejecuciones (misma o distinta compañía) corran dispatchers en paralelo sobre las mismas tablas. `Expires At` permite auto-liberación si una sesión muere sin liberar el lock.

### 3.5 Permission sets del portafolio (`DXR MCC Portfolio Perm. Mgt.`, cod. 60441)

`AssignAllPortfolioPermissionSets` recorre **todas** las filas de `DXR MCC Extension`, para cada `App ID` no nulo consulta `Metadata Permission Set` filtrando `Assignable = true`, y asigna cada permission set encontrado a **todos los usuarios** de la compañía actual vía `Access Control` (evita duplicados con `EnsureAssignment`). Se ejecuta automáticamente al finalizar el pase `Setup` de `RunCategory`/`RunPortfolio` — no requiere asignación manual de permission sets tras un run de Setup completo.

### 3.6 Fallback genérico (`DXR MCC Fallback Migrator`, cod. 60015)

Si, tras contar (`DXR MCC Counter`), un concepto de tipo tabla-a-tabla (`Legacy Table ID <> New Table ID`, ambos ≠ 0) queda con gap, `Executor.LogAndCount` invoca `FallbackMigrator.TryRestoreConcept`. Este:

- Copia por `RecordRef`/`FieldRef` **solo campos que coinciden por nombre y tipo** (nunca por número de campo — evita escribir en un campo equivocado si un ID fue reutilizado).
- Es **reconciliación, no sobrescritura**: si la clave primaria del origen ya existe en el destino, la salta (`TryInsertOrSkip`); nunca sobreescribe una fila existente.
- Procesa en lotes (`Concept."Batch Size"`, o 500 por defecto) con checkpoint en `DXR MCC Bulk Checkpoint` (`Last Source Record ID`), así que reanuda sin repetir filas tras un timeout/cancelación.
- No aplica a conceptos "solo de campos" (`Legacy Table ID = New Table ID = 0`) — esos quedan como `Not Row-Based` y dependen del dispatcher propio de la extensión.

### 3.7 Conteo (`DXR MCC Counter`, cod. 60010)

`CountConcept` abre `Legacy Table ID`/`New Table ID` por `RecordRef` y cuenta filas. Si alguna tabla no puede abrirse (extensión no publicada aquí, ID renombrado, etc.) el resultado es `Status = Error` explícito — nunca un `-1` mezclado en la resta que pudiera leerse como "se perdieron registros". Caso especial: `ExtensionCode = 'DESB'` delega el conteo a `DXR MCC DESB Migr Worker.CountTable` porque ese adapter tiene permisos propios sobre las tablas legacy que un `RecordRef` genérico bajo el llamador interactivo no siempre tiene.

## 4. Flujo de una migración de portafolio, de punta a punta

1. **Registro**: al instalar/actualizar MCC (o al pulsar "Reload Registry"), `DXR MCC Registry Loader` puebla/actualiza `DXR MCC Extension` y `DXR MCC Concept` con datos hardcodeados en el propio codeunit.
2. **Disparo**: un operador pulsa una acción "Run…" en las páginas de MCC (concepto, extensión, categoría o portafolio completo), o "Recount All". Eso llama a un `Schedule*` del Executor.
3. **Programación**: se crea un `DXR MCC Run Request`, se adquiere el lock global, y se programa `DXR MCC Background Runner` vía `TaskScheduler` (timeout 12h).
4. **Ejecución en background**: el Background Runner despacha al Executor según el `Scope`. El Executor recorre extensiones en orden de dependencia (`Order No.`) y, dentro de cada una, categorías/bandas, invocando cada `Dispatcher Codeunit ID` una vez por grupo.
5. **Verificación**: tras cada dispatcher, `DXR MCC Counter` cuenta filas Legacy/New y calcula `Gap`. Si queda gap y el par de tablas es genérico, `DXR MCC Fallback Migrator` intenta cerrarlo.
6. **Registro de auditoría**: cada paso se escribe en `DXR MCC Run Log`; el progreso vivo (`Current Step`, `Last Heartbeat`, `Checkpoint Key`, `Processed Count`) se actualiza en el propio `DXR MCC Run Request`.
7. **Permisos**: al cerrar el pase Setup, se asignan automáticamente los permission sets de todas las extensiones registradas a todos los usuarios.
8. **Cierre**: el Run Request termina en `Completed`/`Failed`/`Cancelled`; si falló por algo transitorio, reintenta hasta 5 veces.
9. **Notificación al usuario** — ver aviso importante en §5.

## 5. ⚠️ Estado actual de la notificación de finalización (`DXR MCC Completion Notify`, cod. 60017)

Este es el archivo que tienes abierto (`src/DXRMCCCompletionNotify.Codeunit.al`) y **tiene un cambio local sin commitear** que lo desactiva:

```diff
 [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
 local procedure OnCompanyOpen()
 begin
-    ShowPendingCompletionIfAny();
+    
 end;
```

En el HEAD del repo (`git diff`), el cuerpo de `OnCompanyOpen()` está **vacío** — la llamada a `ShowPendingCompletionIfAny()` fue removida. Como resultado, tal como está el working tree ahora mismo:

- El subscriber sigue enganchado a `Company Triggers.OnCompanyOpen`, pero no hace nada.
- `ShowPendingCompletionIfAny()` sigue existiendo y sigue siendo correcto (confirmado por `grep`: no hay ninguna otra llamada a este procedimiento en todo `src/`), pero **nadie la invoca** — es código muerto en este momento.
- Por lo tanto, el banner de notificación "DXR Migration Control Center: … finalizó" **no se muestra** hasta que se restaure esa llamada.

Si esto no fue intencional, la corrección es una sola línea (restaurar `ShowPendingCompletionIfAny();` dentro de `OnCompanyOpen`). Si fue un cambio deliberado (p. ej. para desactivar temporalmente el banner durante pruebas), este documento no debe tomarse como confirmación de que el mecanismo está vivo en producción — verifícalo contra el commit que realmente se publique.

Cuando está activo, el mecanismo es:

- Se dispara una vez por sesión, en `OnCompanyOpen` (elegido explícitamente en vez de una `pageextension` sobre un Role Center, porque el compilador rechaza triggers en páginas `Role Center` — ver comentario en el propio codeunit, error `AL0378`).
- Busca en `DXR MCC Run Request` la fila más reciente (`Scheduled At` descendente) con `Requested By = UserId()` actual, `Notified = false` y `Status` en `Completed`/`Failed`/`Cancelled`.
- Envía un `Notification` con scope local y una acción "Ver Run Requests" que abre la página `DXR MCC Run Requests`.
- Marca `Notified := true` — nunca se vuelve a mostrar para ese mismo Run Request.

## 6. Cómo integrarse desde OTRA extensión AL

**Hallazgo verificado**: no existe **ningún** `[IntegrationEvent]` ni `[BusinessEvent]` publicado en todo `src/` (confirmado por grep sobre los 28 objetos). MCC **no expone un punto de extensión basado en eventos**. La integración real es de dos tipos: (a) registrar datos en las tablas públicas de MCC para que orqueste tu migración, y (b) leer/consultar esas mismas tablas desde tu propio código.

### 6.1 Requisito previo

Tu extensión debe depender de MCC (`app.json.dependencies`, con el `id`/`publisher`/`version` de "DXR Migration Control Center") y tener asignado o incluir el permission set `DXR MCC` (60000, `Assignable = true`, `Access = Public`) — otorga `RIMD` sobre `DXR MCC Extension`, `DXR MCC Concept`, `DXR MCC Run Log`, `DXR MCC Run Request`, `DXR MCC Migration Lock` y `DXR MCC Bulk Checkpoint`.

### 6.2 Registrar tu extensión y tus conceptos de migración

`DXR MCC Extension` (60000) y `DXR MCC Concept` (60001) son tablas normales (no `Access = Internal`), así que tu propia extensión puede insertar/actualizar filas directamente desde su propio codeunit de instalación/upgrade, replicando el mismo patrón que usa `DXR MCC Registry Loader.InsExt`/`InsConcept` (esos dos procedimientos son `local` y no se pueden llamar desde fuera — hay que reproducir la lógica, no invocarla):

```al
codeunit 50100 "My Ext MCC Registration"
{
    Permissions =
        tabledata "DXR MCC Extension" = RIM,
        tabledata "DXR MCC Concept" = RIM;

    procedure RegisterInMCC()
    var
        Extension: Record "DXR MCC Extension";
        Concept: Record "DXR MCC Concept";
    begin
        // Upsert de la extensión (por Code, clave primaria de la tabla)
        if not Extension.Get('MYEXT') then begin
            Extension.Init();
            Extension.Code := 'MYEXT';
            Extension.Insert(true);
        end;
        Extension.Name := 'My Extension';
        Extension."App ID" := <TuAppIdGuid>;   // requerido para que el pase de permisos (§3.5) te descubra
        Extension."Order No." := 200;          // define en qué punto de la secuencia de dependencias corres
        Extension.Modify(true);

        // Upsert de un concepto (clave lógica: Extension Code + Phase Code + Sequence No.)
        Concept.SetRange("Extension Code", 'MYEXT');
        Concept.SetRange("Phase Code", 'MYEXT-P1');
        Concept.SetRange("Sequence No.", 1);
        if not Concept.FindFirst() then begin
            Concept.Init();
            Concept."Extension Code" := 'MYEXT';
            Concept."Phase Code" := 'MYEXT-P1';
            Concept."Sequence No." := 1;
            Concept.Insert(true);
        end;
        Concept.Description := 'My Table: legacy row restore';
        Concept."Dispatcher Codeunit ID" := Codeunit::"My Ext Migration Dispatcher";
        Concept."Legacy Table ID" := Database::"My Legacy Table";
        Concept."New Table ID" := Database::"My New Table";
        Concept.Category := Concept.Category::Setup; // o Master/Accounting/Historic/Other/Reporting
        Concept.Modify(true);
    end;
}
```

Reglas que el Executor asume sobre lo que registres (todas verificadas en `DXRMCCExecutor.Codeunit.al` / `DXRMCCCounter.Codeunit.al`):

- `Dispatcher Codeunit ID` **no puede ser** un codeunit con `Subtype = Upgrade` — el Executor lo bloquea explícitamente (§3.2). Tu dispatcher debe ser un codeunit normal, invocable por `Codeunit.Run()`.
- Si varias filas de `Concept` comparten el mismo `Dispatcher Codeunit ID`, el Executor lo invoca **una sola vez** por ese grupo, no una vez por fila.
- Si `Legacy Table ID = New Table ID = 0` y hay dispatcher, el concepto se cuenta como `Not Row-Based` (correcto para migraciones de solo-campos). Si además no hay dispatcher, queda `Skipped`.
- Si `Legacy Table ID <> New Table ID` (ambos ≠ 0), MCC puede intentar cerrar el gap con su `Fallback Migrator` genérico si tu propio dispatcher no lo cierra del todo (copia por nombre/tipo de campo, nunca sobreescribe).
- `Order No." determina en qué punto de la secuencia de dependencias del portafolio corres tu extensión — usa un valor mayor al de cualquier extensión de la que dependas.

### 6.3 Consumir el resultado de un run desde tu extensión

No hay eventos que suscribir. Las dos vías verificadas en el código son:

1. **Consultar `DXR MCC Run Request` directamente** (mismo patrón que usa `DXR MCC Completion Notify`): filtrar por `Requested By`/`Extension Code`/`Scope` y por `Status` en `Completed/Failed/Cancelled`.
2. **Suscribirte tú mismo a `Company Triggers.OnCompanyOpen`** (u otro punto de entrada propio) y replicar la consulta anterior — MCC no te lo va a empujar por evento.

Ejemplo mínimo de subscriber externo que reacciona a que TU extensión terminó su propio run en MCC:

```al
codeunit 50101 "My Ext MCC Run Watcher"
{
    Permissions = tabledata "DXR MCC Run Request" = R;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure OnCompanyOpen()
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        RunRequest.SetRange("Extension Code", 'MYEXT');
        RunRequest.SetRange(Status, RunRequest.Status::Completed);
        RunRequest.SetCurrentKey("Scheduled At");
        RunRequest.SetAscending("Scheduled At", false);
        if RunRequest.FindFirst() then
            // tu propia lógica post-migración aquí
            ;
    end;
}
```

Nota: esto es exactamente el mismo patrón que `DXR MCC Completion Notify` usa internamente — no es una API pública documentada por MCC, es leer sus tablas con los permisos que el permission set `DXR MCC` ya te concede.

## 7. Requisitos y límites (resumen)

- **Target**: Cloud únicamente (`app.json.target`).
- **Application**: 28.0.0.0, **Platform**: 1.0.0.0, **Runtime**: 17.0.
- **Dependencias obligatorias**: Facturacion Electronica, Base App DR Localization.
- **Rango de IDs**: 60000–65000 para objetos propios de MCC.
- **Timeout de tarea de migración**: 12 horas por intento (`Executor.MigrationTaskTimeout`).
- **Reintentos**: máx. 5 intentos por Run Request, 5 s de espera entre intentos (`DXR MCC Background Runner`).
- **Concurrencia**: una sola ejecución de migración a la vez en todo el portafolio, cross-company (lock global en `DXR MCC Migration Lock`).
- **Codeunits `Subtype = Upgrade`**: nunca invocables como dispatcher desde MCC; deben ejecutarse por su propio punto de entrada o en el próximo publish/schema-sync.
