# Motor de migración por tabla — Plan de implementación (tanda 1)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Que la categoría Master recorra cada tabla UNA sola vez aplicando los campos de todas las extensiones, en vez de una vez por extensión.

**Architecture:** Un codeunit por tabla bajo `src/Master/`. Recorre la tabla una vez con `SetLoadFields` + `FindSet(false)` (sin UPDLOCK); por fila evalúa un bloque por extensión; si algo cambió, relee con `Get()` bajo bloqueo, reaplica los MISMOS bloques y hace `Modify`. Un upgrade tag nuevo por tabla. El código de copia se MUEVE desde los adaptadores por extensión; no se duplica.

**Tech Stack:** AL / Business Central 28 (runtime 17). Compilador `alc.exe` de la extensión AL de VS Code. Verificación con scripts Python sobre el árbol de código y sobre `git`.

**Spec:** `docs/superpowers/specs/2026-08-27-master-by-table-design.md`

## Global Constraints

- Rango de IDs libre: **60450-60600** (máximo usado hoy: 60446). Un ID por tabla.
- Compilador: `C:\Users\rpena\.vscode\extensions\ms-dynamics-smb.al-17.0.2273547\bin\win32\alc.exe`
- Compilar con `/project:"<repo>" /packagecachepath:"<repo>\.alpackages" /out:"$env:TEMP\<tarea>.app"`. Usar un `/out` distinto por tarea para no chocar entre agentes.
- Los warnings `AL0432` ("marked for removal") son **esperados** en este proyecto y NO son errores. Filtrar errores reales con el regex `': error [A-Z]{2}\d+'`.
- **No hay framework de pruebas AL en uso.** El ciclo de prueba de cada tarea es: (1) compilador en verde, (2) `tools/check_loadfields.py` sin huecos, (3) `tools/check_assignments.py` sin pérdidas contra git. Los tres son obligatorios.
- Política de copia obligatoria: **nunca sobrescribir un destino que ya tiene valor**, comparando contra un `Record` en blanco nunca leído de base (`Blank`). Es correcto para Text, Code, Decimal, Integer, Boolean, Date, DateTime y Option por igual.
- **Prohibido** cambiar qué campos se migran, el orden entre tablas, o los nombres de upgrade tags existentes.
- Omitido por decisión previa, NO reactivar: `Item HTML` y sus 3 BLOB, `Item Image View` e `Inventory View` (LinkedObject = vistas SQL externas).
- Todo BLOB que sí se migre requiere `CalcFields` (o `FieldRef.CalcField()`) antes de leerse; sin eso se escribe vacío en silencio.
- **AL no tiene operadores booleanos con cortocircuito** (Learn, "Boolean (logical) operators"). Nunca escribir `if TryResolve(...) and (Var.Algo)`: si el Try falla, `Var` sigue sin inicializar y el runtime revienta igual. Usar `if` anidados.

---

## Inventario de origen (tanda 1)

Bloques que se mueven a `Master Customer` (60450):

| Bloque | Origen exacto |
|---|---|
| BELLON | `src/Adapters/BELLON/DXRMCCBellonMigrPhase2.Codeunit.al:4505` `MigrateTableExt_CustomerFields` |
| BC | `src/Adapters/BC/DXRMCCBCMigrP3Customer.Codeunit.al` (cuerpo de `OnRun`) |
| DESB | `src/Adapters/DESB/DXRMCCDESBMigrPhase2.Codeunit.al:320` `MigrateTable_Customer` |
| DRLOC | `src/Adapters/DRLOC/DXRMCCDRLOCMigrPhase2.Codeunit.al:443` `MigrateCustomerFields` |
| PCM | `src/Adapters/PCM/DXRMCCPCMMigrPhase2.Codeunit.al:32` `MigrateCustomerFields` |
| SD | `src/Adapters/SD/DXRMCCSDMigrCustomer.Codeunit.al` |
| TU | `src/Adapters/TU/DXRMCCTUMigrDispatcher.Codeunit.al:212` `MigrateOriginalCustomerFields` |

Bloques que se mueven a `Master Item` (60451): BC, BELLON, DESB, DRLOC, FE, LSLOC.

---

### Task 1: Herramientas de verificación

Sin esto no se puede validar ninguna tarea siguiente. Va primera por eso.

**Files:**
- Create: `tools/check_loadfields.py`
- Create: `tools/check_assignments.py`

**Interfaces:**
- Produces: dos scripts CLI que devuelven exit code 0 = OK, 1 = falla.

- [ ] **Step 1: Escribir `tools/check_loadfields.py`**

Para cada variable `Record` con `SetLoadFields`, compara los campos declarados contra todos los referenciados sobre esa variable en su procedimiento. Un campo leído o escrito y ausente de la lista **compila bien y falla en ejecución**: es el error más probable del refactor.

```python
import re, sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
code = "\n".join(re.sub(r'//.*$', '', line) for line in src.split("\n"))

gaps = 0
for m in re.finditer(r'(\w+)\.SetLoadFields\(([^;]*?)\);', code, re.S):
    var = m.group(1)
    declared = set(re.findall(r'"[^"]+"', m.group(2)))
    start = code.rfind("procedure", 0, m.start())
    end = code.find("\n    end;", m.end())
    body = code[start:end if end > 0 else len(code)]
    used = set(re.findall(r'%s\.("[^"]+")' % re.escape(var), body))
    missing = used - declared
    if missing:
        gaps += 1
        print("HUECO %s: %s" % (var, sorted(missing)))

print("OK - sin huecos" if not gaps else "FALLA - %d huecos" % gaps)
sys.exit(1 if gaps else 0)
```

- [ ] **Step 2: Escribir `tools/check_assignments.py`**

Compara el conjunto de asignaciones `destino := origen` entre git y el árbol de trabajo, normalizando el nombre de la variable Record. Detecta que no se perdió ni se torció ninguna copia al mover código entre codeunits.

```python
import re, subprocess, sys

ASSIGN = re.compile(r'(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*:=\s*(\w+)\.("[^"]+"|[A-Za-z_]\w*)\s*;')

def pairs(text):
    out = set()
    for line in text.split("\n"):
        if line.strip().startswith("//"):
            continue
        m = ASSIGN.search(line)
        if m:
            out.add((m.group(2), m.group(4)))
    return out

ref, files = sys.argv[1], sys.argv[2:]
old, new = set(), set()
for f in files:
    shown = subprocess.run(["git", "show", "%s:%s" % (ref, f)],
                           capture_output=True, text=True).stdout
    old |= pairs(shown)
    try:
        new |= pairs(open(f, encoding="utf-8").read())
    except FileNotFoundError:
        pass

lost, added = old - new, new - old
for d, s in sorted(lost):
    print("PERDIDA  %s := %s" % (d, s))
for d, s in sorted(added):
    print("NUEVA    %s := %s" % (d, s))
print("OK - conjunto de copias intacto" if not lost else "FALLA - %d copias perdidas" % len(lost))
sys.exit(1 if lost else 0)
```

- [ ] **Step 3: Probar las herramientas contra un archivo que ya usa el patrón**

Run: `python tools/check_loadfields.py src/Adapters/BC/DXRMCCBCMigrP3Customer.Codeunit.al`
Expected: `OK - sin huecos`

- [ ] **Step 4: Commit**

```bash
git add tools/check_loadfields.py tools/check_assignments.py
git commit -m "tools: verificadores de SetLoadFields y de conjunto de copias"
```

---

### Task 2: Convertir a never-overwrite las copias de maestros aún incondicionales

**Requisito previo del motor nuevo.** Con un tag por tabla, una compañía ya migrada reaplica todos los bloques; toda copia incondicional se vuelve una vía de pisar un valor bueno con vacío.

**Files:**
- Modify: los procedimientos de maestros del inventario que aún hagan `X_DXR := X` sin guarda.

**Interfaces:**
- Consumes: `tools/check_assignments.py` (Task 1)
- Produces: todos los bloques de maestros cumplen `if X_DXR = Blank.X_DXR then X_DXR := <origen>;`

- [ ] **Step 1: Localizar las copias incondicionales**

Run: `grep -rnE '^\s+\w+\."[^"]+_DXR"\s*:=' src/Adapters/ | grep -v "= Blank\."`

- [ ] **Step 2: Aplicar la guarda**

Añadir `Blank: Record <Tabla>;` al bloque `var` y envolver cada asignación:

```al
if Rec."Campo_DXR" = Blank."Campo_DXR" then
    Rec."Campo_DXR" := Rec."Campo Legacy";
```

- [ ] **Step 3: Verificar que el conjunto de copias no cambió**

Run: `python tools/check_assignments.py HEAD <archivos tocados>`
Expected: `OK - conjunto de copias intacto` — la guarda no altera el par destino←origen.

- [ ] **Step 4: Compilar**

Expected: `ERRORES: 0`

- [ ] **Step 5: Commit**

```bash
git commit -am "fix: never-overwrite en copias de maestros (requisito del motor por tabla)"
```

---

### Task 3: `DXR MCC Master Customer` (60450) — piloto

Es la tabla con más bloques (7) y la que más duele. Va primero para validar el patrón.

**Files:**
- Create: `src/Master/DXRMCCMasterCustomer.Codeunit.al`
- Modify: los 7 orígenes del inventario
- Modify: `src/DXRMCCPermissionSet.PermissionSet.al`

**Interfaces:**
- Consumes: ambos scripts de Task 1; política never-overwrite de Task 2.
- Produces: `codeunit 60450 "DXR MCC Master Customer"` con `local procedure RowNeedsWork(var Customer: Record Customer): Boolean` y siete `local procedure ApplyXXX(var Customer: Record Customer): Boolean`.

- [ ] **Step 1: Crear el codeunit con la forma canónica**

```al
codeunit 60450 "DXR MCC Master Customer"
{
    Permissions = tabledata Customer = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(MasterTag()) then
            exit;
        MigrateCustomer();
        UpgradeTag.SetUpgradeTag(MasterTag());
    end;

    local procedure MasterTag(): Code[250]
    begin
        exit('DXR-MCC-MASTER-CUSTOMER-20260827');
    end;

    local procedure MigrateCustomer()
    var
        Customer: Record Customer;
        CustomerToUpdate: Record Customer;
        RowsSinceCommit: Integer;
    begin
        Customer.SetLoadFields("No.");
        if not Customer.FindSet(false) then
            exit;
        repeat
            if RowNeedsWork(Customer) then
                if CustomerToUpdate.Get(Customer."No.") then
                    if RowNeedsWork(CustomerToUpdate) then begin
                        CustomerToUpdate.Modify(false);
                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
        until Customer.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsWork(var Customer: Record Customer): Boolean
    var
        Changed: Boolean;
    begin
        Changed := ApplyBELLON(Customer) or Changed;
        Changed := ApplyBC(Customer) or Changed;
        Changed := ApplyDESB(Customer) or Changed;
        Changed := ApplyDRLOC(Customer) or Changed;
        Changed := ApplyPCM(Customer) or Changed;
        Changed := ApplySD(Customer) or Changed;
        Changed := ApplyTU(Customer) or Changed;
        exit(Changed);
    end;
}
```

`RowNeedsWork` se llama DOS veces por fila: sobre la copia sin bloqueo (detectar) y sobre la fila releída bajo bloqueo (aplicar). Es la MISMA función en ambos casos, para que las dos evaluaciones no puedan divergir — evita la pérdida de actualización que hubo que corregir en `PCM Phase5`.

`Changed := ApplyX(...) or Changed;` es deliberado: como AL no cortocircuita, garantiza que los siete bloques se ejecuten siempre.

- [ ] **Step 2: Mover cada bloque**

Por cada fila del inventario: copiar el cuerpo del procedimiento origen a `ApplyXXX(var Customer: Record Customer): Boolean`, sustituyendo su `Modify`/commit propio por `exit(Changed)`. Quitar el cuerpo del adaptador origen y dejar el procedimiento como no-op documentado — **no borrarlo**, porque otras rutas lo invocan.

- [ ] **Step 3: Completar el `SetLoadFields`**

Run: `python tools/check_loadfields.py src/Master/DXRMCCMasterCustomer.Codeunit.al`
Expected: `OK - sin huecos`. Si reporta huecos, añadir los campos que falten y repetir hasta que pase.

- [ ] **Step 4: Verificar que no se perdió ninguna copia**

Run: `python tools/check_assignments.py HEAD src/Master/DXRMCCMasterCustomer.Codeunit.al` seguido de los 7 archivos origen
Expected: `OK - conjunto de copias intacto`

- [ ] **Step 5: Compilar**

Expected: `ERRORES: 0`

- [ ] **Step 6: Commit**

```bash
git add src/Master/DXRMCCMasterCustomer.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -am "feat: Master Customer en una sola pasada (7 bloques, 7 scans -> 1)"
```

---

### Task 4: `DXR MCC Master Item` (60451)

Misma receta de Task 3 con 6 bloques: BC, BELLON, DESB, DRLOC, FE, LSLOC. PK sigue siendo `"No."`. Tag: `DXR-MCC-MASTER-ITEM-20260827`.

Particularidad de Item: dos pares de BELLON (`Buyer Group Code` e `Inventory2`) son **FlowField en ambos lados** y NO se copian. Confirmarlo antes de mover.

- [ ] **Step 1:** Crear `src/Master/DXRMCCMasterItem.Codeunit.al` con la forma canónica de Task 3 Step 1, cambiando `Customer` por `Item` y el tag.
- [ ] **Step 2:** Mover los 6 bloques.
- [ ] **Step 3:** `python tools/check_loadfields.py src/Master/DXRMCCMasterItem.Codeunit.al` → `OK - sin huecos`
- [ ] **Step 4:** `python tools/check_assignments.py HEAD` + los 6 orígenes → `OK - conjunto de copias intacto`
- [ ] **Step 5:** Compilar → `ERRORES: 0`
- [ ] **Step 6:** `git commit -am "feat: Master Item en una sola pasada (6 bloques, 6 scans -> 1)"`

---

### Task 5: Registro — ejecutar por tabla

**Files:**
- Modify: `src/DXRMCCRegistryLoader.Codeunit.al`

- [ ] **Step 1: Retirar los conceptos Master por extensión de Customer e Item**

En `IsExplicitlyRetiredConcept`, añadirlos y **limpiar la función**: hoy acumula casos sueltos sin agrupar. Reescribirla con una tabla de casos legible.

- [ ] **Step 2: Registrar los conceptos nuevos**

```al
InsConcept('MCC', 'MASTER', 1, 'Customer: migración de campos consolidada (7 extensiones, 1 pasada)', 60450, Database::Customer, Database::Customer, 'MA');
InsConcept('MCC', 'MASTER', 2, 'Item: migración de campos consolidada (6 extensiones, 1 pasada)', 60451, Database::Item, Database::Item, 'MA');
```

- [ ] **Step 3: Compilar**

Expected: `ERRORES: 0`

- [ ] **Step 4: Commit**

```bash
git commit -am "feat: registro apunta Master Customer/Item al motor por tabla"
```

---

## Tandas siguientes (planes aparte)

Cada una produce software funcional por sí sola y aplica la MISMA receta de Task 3:

- **Tanda 2** — 19 tablas maestras restantes (Contact, Location, Currency, Vendor, Bank Account, LSC POS Terminal, ...). 47 pasadas → 21.
- **Tanda 3** — **38 tablas de contabilidad, 106 pasadas → 38.** Las más pesadas: `Sales Header` (8 bloques), `Gen. Journal Line` (6), `Purchase Header` (6), `Sales Invoice Header` (6), `User Setup` (6), `Sales Line` (5), `Cust. Ledger Entry` (4).
- **Tanda 4** — tablas históricas, mismo modelo, más la métrica de completitud del spec §3.5.

## Self-review

- **Cobertura del spec:** §3.1 → Task 3/4. §3.3 → Task 3 Step 2. §3.4 → Task 2. §3.6 → Task 5. §6 → Task 1. §3.5 (métrica) y §3.7 (históricos) quedan declarados para tandas siguientes.
- **Placeholders:** los dos scripts van completos y ejecutables; el codeunit va con su forma real. El único hueco marcado es la unión de campos del `SetLoadFields`, que **es la salida de Task 3 Step 3**, no un TODO.
- **Consistencia de tipos:** `RowNeedsWork(var Record): Boolean` y `ApplyXXX(var Record): Boolean` se usan idénticos en Task 3 y Task 4.
