# MCC Full-Portfolio Native Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every one of MCC's 705+ registered migration concepts (across all 17 portfolio extensions once Phase 0 registers the 4 currently-invisible ones (VendorPay_TXT explicitly excluded per user instruction)) runs through a typed, direct-field native MCC adapter — zero `RecordRef`/`FieldRef` in the primary migration path — executed in exactly 4 portfolio-wide phases in this order: Setup, Master/Accounting, Historic, DGII-RNC Database (last).

**Architecture:** MCC's existing registry (`DXR MCC Concept` → `Dispatcher Codeunit ID` → `Codeunit.Run()`) and `Category` field (Setup/Master-Accounting/Historic/Other, already driving `Run All Setup/Master-Accounting/Historic` on `DXRMCCMain.Page.al`) are unchanged. Each concept's `Dispatcher Codeunit ID` is repointed at a native MCC adapter codeunit (`src/Adapters/<EXT>/...`) with a real `trigger OnRun`. Two adapter shapes, chosen per Task 0.2's per-extension audit: (1) **direct** — MCC declares typed `Record` variables for both legacy and new tables itself and copies named fields; used whenever the target extension's tables are NOT `Access = Internal`. (2) **thin-wrapper** — MCC's adapter has a real `OnRun` but calls one public procedure on the source extension's own (non-Internal) codeunit, which itself must do the typed copy internally; required whenever the target table is `Access = Internal` (confirmed pattern: DRLOC, see Task 0.2).

**Tech Stack:** AL (Business Central 28.x, runtime 17.0). No new external dependencies for extensions already in `app.json`; Phase 0 may add up to 5 new dependencies for the newly-registered extensions.

**Spec:** `docs/superpowers/specs/2026-08-24-mcc-full-portfolio-native-migration-design.md`

## Global Constraints

- Zero `RecordRef`/`FieldRef` in any adapter's own primary logic (`src/Adapters/**` and any `src/*.al` file that performs a concept's actual field-by-field migration). Three explicit, confirmed exceptions — do not "fix" these, they are legitimate:
  1. `DXR MCC Fallback Migrator` (`src/DXRMCCFallbackMigrator.Codeunit.al`) — automatic last-resort safety net, fires from `DXRMCCExecutor.Codeunit.al` only, never called from adapter code.
  2. `DXR MCC Counter` (`src/DXRMCCCounter.Codeunit.al:57-59`, `TryCountTable`) — generic row counter that must operate on whatever arbitrary `Legacy Table ID`/`New Table ID` the registry names for the Gap Report; cannot be typed by design.
  3. `DXR MCC Upgrade Tag Mgt` (`src/DXRMCCUpgradeTagMgt.Codeunit.al:55-60`, `ClearUpgradeTag`) — table 9999 "Upgrade Tags" is `Access = Internal` to the System Application itself (platform-level restriction affecting every external app, confirmed via compiler error cited in that file's own comment) — `RecordRef.Open(9999)` is the only way any extension can touch it.
- Every new field pair used in code must be confirmed from real AL source under `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\<extension>\` (the `ObsoleteReason` on the legacy field, or the literal field number used in an existing `CopyFieldIfExists`/`CopySingleFieldForAllRows`-style call being replaced) — never from `DXR_Legacy_Field_Mapping.md` alone, which is a decayed summary.
- **Never use `TransferFields`, even for confirmed 1:1 table layouts** (added 2026-08-24, user directive after reviewing real production run errors on BELLON — "The record is already open" and related failures reinforced that every field copy must be fully explicit and auditable, not delegated to a bulk-copy API). Every whole-table clone (previously written with `New.TransferFields(Legacy, true); New.Insert(false);`) must instead assign every real field individually: `New."Field1" := Legacy."Field1"; New."Field2" := Legacy."Field2"; ...` for the table's complete field list, confirmed against real source. This applies to ALL adapters going forward, and retroactively to the 2 already-completed tasks that used `TransferFields` (Task A.3 DRLOC Payment Method Relation, Task A.4 PCM Prices Ctrl Setup) — both get a follow-up fix task.
- **Before writing any adapter, check whether its target table(s) are `Access = Internal`** (Task 0.2 produces this table per extension). If internal: do not declare `Record "<InternalTable>"` in MCC — use the thin-wrapper pattern instead (edit the source extension's own migration codeunit to be typed if it isn't already, expose/confirm a public procedure, call that from MCC). If not internal: declare typed `Record` directly in MCC's adapter.
- New MCC codeunit IDs come from the `idRanges` 60000-60100 block in `app.json`. **Re-verify the current highest ID in use immediately before allocating** (`grep -ohE "codeunit 6[0-9]{4}" src/Adapters/*/*.al src/*.al | grep -oE "6[0-9]{4}" | sort -n | tail -1` — 60163 as of this plan's authoring, but multiple tasks/agents will advance this over time) to avoid collisions; this is exactly what `dxr-id-allocation-registry` governs.
- Never call `Codeunit.Run()` on a codeunit confirmed `Subtype = Upgrade`. Confirmed IDs (do not add as adapter targets): `52248, 36003045, 52189, 36003049, 51962, 36002776, 52255, 36003047, 53669, 59221, 53562, 52587, 36003121, 53600, 54856, 54662, 54599, 54742, 54743, 54534, 53923, 54445, 36003619, 52773, 54779, 52743, 52667, 52120396, 53648, 52119593, 54283` (from `docs/superpowers/plans/2026-08-23-mcc-native-migration.md`, Global Constraints — carried forward unchanged).
- **Shared-file lock:** `src/DXRMCCRegistryLoader.Codeunit.al`, `src/DXRMCCPermissionSet.PermissionSet.al`, and `app.json` are edited by every task in this plan. When running tasks via subagent-driven-development, **serialize edits to these 3 files** — never let two in-flight tasks touch them concurrently; batch a group's registry repoints/permission grants/dependency additions into one edit per group, applied by whichever task finishes its own new-file work last in that batch.
- Compile command (confirmed working against the current `.alpackages` cache):
```bash
"/c/Users/rpena/.vscode/extensions/ms-dynamics-smb.al-17.0.2273547/bin/win32/alc.exe" \
  /project:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\.claude\worktrees\mcc-native-migration" \
  /packagecachepath:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\.claude\worktrees\mcc-native-migration\.alpackages" \
  /out:"<scratch path>\mcc_test.app"
```
Expected: 0 errors. Every new `app.json` dependency requires that extension's `.app` symbol package present in `.alpackages` first (Download Symbols, or `dxr-symbol-management`).
- Verification per concept (no automated test harness exists in this repo): (1) evidence — the field pair(s)/procedure used are cited with file:line; (2) runtime — clean compile + `DXR MCC Run Log` shows non-zero `Migrated Record Count` for that concept where the legacy table has real rows.
- Order of execution across this whole plan: Phase 0 → Task A.1-A.3 (worked examples) → Task A.4 (Setup sweep, all extensions) → Task B.1 (Master/Accounting sweep, all extensions, includes RecordRef remediation) → Task C.1 (Historic sweep, all extensions except DGII-RNC) → Task D.1 (DGII-RNC, alone, last). Do not start a later phase's sweep before the earlier phase's sweep task is fully checked off.

---

## Task 0.1: Register the 4 portfolio extensions currently invisible to MCC

**Scope note (ruling, 2026-08-24):** VendorPay_TXT is explicitly excluded from this task per direct user instruction — do not register it, do not search for it. Only the 4 extensions below are in scope.

**Files:**
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\EmailSender\app.json` (confirm real folder/app.json path first — may be nested, e.g. under a `src` or project subfolder)
- Read: the "Retail-Email-Sender" extension's `app.json` — folder not yet confirmed; search `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\` for it (candidates: under `Retail Controls\` or its own root)
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\BC-Bank-Consolidation\app.json` (DX Bank Reconciliation)
- Read: the "VendorPay_API" extension's `app.json` — folder not yet confirmed; search under `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\vendorpayload\`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` (add `InsExt(...)` calls for each confirmed extension)

**Interfaces:**
- Produces: one new `Code[20]` extension code per confirmed extension (pick a short, all-caps code following the existing convention — e.g. `ES` for Email-Sender, `RES` for Retail-Email-Sender, `BANKREC` for DX Bank Reconciliation, `VPAPI` for VendorPay_API — confirm no collision with the 17 existing codes: BC, BELLON, BELLONPOS, DESB, DESLS, DPP, DRLOC, DXP, FE, LSFE, LSLOC, PCM, RBPD, RC, SD, TU, VP), each with its real `app.json` id/publisher/name, consumed by Task 0.2 and every later task that adds concepts for these extensions.

- [ ] **Step 1: Locate each of the 4 extensions' real project folder and `app.json`**

```bash
find "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON" -maxdepth 4 -iname "app.json" | xargs grep -l "Email-Sender\|EmailSender\|Bank Reconciliation\|VendorPay_API" 2>/dev/null
```

If a name doesn't match (naming may have drifted since `DXR_Legacy_Field_Mapping.md` was written), fall back to `find "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON" -maxdepth 2 -type d -iname "*email*"` / `*vendorpay*` / `*bank*` and inspect each candidate's `app.json` `"name"` field directly.

- [ ] **Step 2: For each of the 4, confirm it genuinely has DXR_ migration objects** (not just a name match) — run inside each candidate folder:

```bash
grep -rl "ObsoleteReason.*DXR_\|_DXR\"" --include="*.al" .
```

If a candidate has zero matches, it has no migration surface — do not register it, note why in the task's commit message instead.

- [ ] **Step 3: Read each confirmed extension's real `app.json`** — copy `id`, `publisher`, `name`, `version` verbatim (do not transcribe from the mapping doc).

- [ ] **Step 4: Add each confirmed extension to the registry seed** in `src\DXRMCCRegistryLoader.Codeunit.al`, following the exact pattern of the existing `InsExt` calls (see line 55, 61 for `InsExt('BC', 'Base Controls', 'e8b1de99-1c7d-454d-b0bc-7cc1dc7b86ae', 0, '')`):

```al
InsExt('ES', 'Email-Sender', '<real-app-id-from-step-3>', <next-order-no>, '');
InsExt('RES', 'Retail-Email-Sender', '<real-app-id-from-step-3>', <next-order-no>, '');
InsExt('BANKREC', 'DX Bank Reconciliation', '<real-app-id-from-step-3>', <next-order-no>, '');
InsExt('VPAPI', 'VendorPay_API', '<real-app-id-from-step-3>', <next-order-no>, '');
```

(Only add the rows that Step 2 actually confirmed — skip any that turn out to be a false positive from the mapping doc's index.)

- [ ] **Step 5: Compile** (Global Constraints compile command). Expected: 0 errors — this step only adds seed rows, no new adapter code yet.

- [ ] **Step 6: Commit**

```bash
git add src/DXRMCCRegistryLoader.Codeunit.al
git commit -m "feat: register portfolio extensions missing from MCC (Email-Sender, Retail-Email-Sender, DX Bank Reconciliation, VendorPay_API)"
```

---

## Task 0.2: Access=Internal audit — determines adapter shape for every later task

**Files:**
- Read: every registered extension's table/tableextension source (search per extension, see Step 1)
- Create: `docs\superpowers\plans\2026-08-24-mcc-access-internal-audit.md` (the produced decision table — a plain findings doc, not a spec/plan itself)

**Interfaces:**
- Consumes: the 18-extension list (17 existing + confirmed subset from Task 0.1).
- Produces: a per-extension `Direct` / `Thin-Wrapper` classification that Task A.4/B.1/C.1/D.1 read before writing any adapter — **do not skip this for an extension before writing its first adapter.**

- [ ] **Step 1: For each of the 18 extensions, search for `Access = Internal` on its own tables/tableextensions**

```bash
for ext_path in "DR-Localization" "Bellon_Customization" "Special dispatch" "DXPAYMENT-BC" "Facturacion Workspace" "Localizacion-LS-Central" "base Controls" "Despacho-Base" "PriceControls" "Recaudo BC" "Retail Controls" "DX-TransUnion" "vendorpayload"; do
  echo "=== $ext_path ==="
  grep -rl "Access = Internal" "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\$ext_path" --include="*.al" 2>/dev/null | wc -l
done
```

(Confirmed already, cite as evidence, do not re-derive: DRLOC — pervasive, `CHANGELOG.md:25` states "All fiscal codeunits and tables of the DR Localization... are now declared Access = Internal", confirmed via direct read of `DXR_PaymentMethodRelation.Table.al:11` and `DXR_DGIIRNCDatabase.Table.al`; BELLON — 1 match only, i.e. not pervasive, direct Record access is fine for its 119 custom tables and 100 tableextensions.)

- [ ] **Step 2: For each extension with 1+ matches, confirm which of ITS OWN migration codeunits (the ones MCC's adapters would call) are or are not themselves `Access = Internal`** — a normal-access codeunit CAN reference that same extension's own `Access = Internal` tables internally (same package); only an EXTERNAL caller (MCC) is blocked from declaring `Record "<InternalTable>"` directly. Record: extension code, table Access modifier, migration codeunit Access modifier.

- [ ] **Step 3: Write the findings doc** with one row per extension:

```markdown
| Extension | Target tables Access=Internal? | Own migration codeunit Access=Internal? | Adapter shape for MCC |
|---|---|---|---|
| DRLOC | Yes (pervasive, confirmed) | No (DXR_Migr_Phase_2_Fiscal is normal access) | Thin-wrapper: MCC calls DRLOC's own public procedure |
| BELLON | No (1 isolated match only) | N/A | Direct: MCC declares typed Record itself |
| ... | ... | ... | ... |
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-08-24-mcc-access-internal-audit.md
git commit -m "docs: Access=Internal audit across portfolio - determines direct vs thin-wrapper adapter shape"
```

---

## Task A.1: Worked example (Direct pattern, bug fix) — BELLON Assembly Setup Tolerance%

**Files:**
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Bellon_Customization\Bellon Customization\src\Extentions\tables\AssemblySetup.TableExt.al` (confirmed: tableextension 53418 "DXR_BE Assembly Setup" extends "Assembly Setup"; field 52000 "Tolerance%" ObsoleteReason "Replaced by Tolerance%_DXR..."; field 52001 "Tolerance%_Old" — NOT the real target; field 52787 "Tolerance%_DXR" — the REAL target, currently never populated by MCC)
- Modify: `src\Adapters\BELLON\DXRMCCBellonMigrPhase2.Codeunit.al` (replace `MigrateTableExt_AssemblySetupFields`, confirmed at the file's line ~333-344, currently `CopyFieldIfExists(RecRef, 52000, 52001)` — copies to the WRONG field, `Tolerance%_Old`, never to `Tolerance%_DXR`)

**Interfaces:**
- Consumes: nothing new (Assembly Setup is a singleton-ish setup table, `Record "Assembly Setup"` already available via standard BC symbols).
- Produces: nothing consumed elsewhere — this is a self-contained bug fix + pattern proof, first of the worked examples the sweep tasks (A.4+) copy the shape from.

- [ ] **Step 1: Confirm the bug by re-reading the current procedure**

```bash
grep -n -A 10 "local procedure MigrateTableExt_AssemblySetupFields" "src/Adapters/BELLON/DXRMCCBellonMigrPhase2.Codeunit.al"
```

Expected match: `CopyFieldIfExists(RecRef, 52000, 52001);` — confirms the target is field 52001 (`Tolerance%_Old`), not 52787 (`Tolerance%_DXR`).

- [ ] **Step 2: Replace the procedure with direct typed fields, targeting the REAL `_DXR` field**

```al
    local procedure MigrateTableExt_AssemblySetupFields()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 52000, 52001))
        // copied "Tolerance%" into "Tolerance%_Old" (field 52001), a dead shadow field - the real
        // active target "Tolerance%_DXR" (field 52787, confirmed via AssemblySetup.TableExt.al's
        // ObsoleteReason on field 52000) was NEVER populated by this codeunit despite it running
        // and reporting success. Direct typed fields close that gap.
        if AssemblySetup.Get() then
            if AssemblySetup."Tolerance%_DXR" <> AssemblySetup."Tolerance%" then begin
                AssemblySetup."Tolerance%_DXR" := AssemblySetup."Tolerance%";
                AssemblySetup.Modify();
            end;
    end;
```

- [ ] **Step 3: Compile** (Global Constraints command). Expected: 0 errors.

- [ ] **Step 4: Publish to a test environment, run "Reload Registry" then run the BELLON-P2 concept covering Assembly Setup**, confirm in `DXR MCC Run Log` it completes and that `Tolerance%_DXR` now holds the same value as `Tolerance%` on the real `Assembly Setup` row (manual field inspection — this table has no automated test harness).

- [ ] **Step 5: Commit**

```bash
git add src/Adapters/BELLON/DXRMCCBellonMigrPhase2.Codeunit.al
git commit -m "fix: BELLON Assembly Setup Tolerance% adapter wrote to dead shadow field, never the real _DXR target - convert to direct typed fields"
```

---

## Task A.2: Worked example (Direct pattern, multi-field-per-table, field names already known) — DXP Phase2

**Correction (2026-08-24, during this plan's own authoring):** the original draft of this task targeted SD's 8 adapters, assuming (per the superseded 2026-08-23 plan's text) they still routed through `DXR_SD_Migr_Phase1_FieldDup`'s `RecordRef`-based `Execute()`. Direct read of all 8 real files in `src/Adapters/SD/` during this plan's authoring confirmed **all 8 are already fully converted** (each already declares typed `Record`, e.g. `src\Adapters\SD\DXRMCCSDMigrCustomer.Codeunit.al:1` is `codeunit 60070 "DXR MCC SD Migr Customer"` with a direct `Record Customer` body, dated "Native local migration (2026-08-23)" in its own header comment) — zero `RecordRef`/`FieldRef` matches across the whole `src/Adapters/SD/` folder. **SD needs no work in this plan** — Task A.4/B.1/C.1's per-extension sweep must skip SD entirely (still verify its concepts' `Category` tags and registry wiring are correct, but do not touch its adapter code). This task is retargeted at DXP instead, a genuinely real, still-unconverted case.

**Files:**
- Read: `src\Adapters\DXP\DXRMCCDXPMigrPhase2.Codeunit.al` (confirmed real, current: `codeunit 60081 "DXR MCC DXP Migr Phase2"`, `RecordRef`/`FieldRef`-based `CopyTableFields` helper, called once per table by 5 `Copy<Table>Fields` procedures — `LSC Infocode`, `LSC POS Terminal`, `LSC POS Trans. Line`, `LSC Tender Type`, `LSC Trans. Payment Entry` — each already lists its real field-name pairs via `FieldNo("<legacy name>")`/`FieldNo("<new name>_DXR")` calls, so no additional field-mapping research is needed for this file, only a mechanical rewrite)
- Modify: `src\Adapters\DXP\DXRMCCDXPMigrPhase2.Codeunit.al`

**Interfaces:**
- Consumes: nothing new — every field name pair is already spelled out in the current file's `AddFieldPair(...)` calls (cited above), just routed through `FieldNo()`+`RecordRef`/`FieldRef` instead of direct assignment.
- Produces: nothing consumed elsewhere — self-contained mechanical conversion, second reference shape (multi-field-per-table, same-table extension fields) for Task A.4+ to copy.

- [ ] **Step 1: Re-read the current file in full** (`src\Adapters\DXP\DXRMCCDXPMigrPhase2.Codeunit.al`) to confirm no field pair has changed since this plan was authored.

- [ ] **Step 2: Replace the whole body with direct typed-field assignments**, one procedure per table, keeping the existing codeunit ID `60081` and the existing `Permissions` clause unchanged:

```al
codeunit 60081 "DXR MCC DXP Migr Phase2"
{
    // Converted 2026-08-24: previously routed 38 field copies across 5 tables through a generic
    // RecordRef/FieldRef CopyTableFields helper (field names were already known via FieldNo() calls
    // - only the copy mechanism was untyped). Direct typed Record assignment, zero RecordRef.
    Permissions = tabledata "LSC Infocode" = RM,
                  tabledata "LSC POS Terminal" = RM,
                  tabledata "LSC POS Trans. Line" = RM,
                  tabledata "LSC Tender Type" = RM,
                  tabledata "LSC Trans. Payment Entry" = RM;

    trigger OnRun()
    begin
        CopyInfocodeFields();
        CopyPOSTerminalFields();
        CopyPOSTransLineFields();
        CopyTenderTypeFields();
        CopyTransPaymentEntryFields();
    end;

    local procedure CopyInfocodeFields()
    var
        Infocode: Record "LSC Infocode";
    begin
        if Infocode.Findset(false) then
            repeat
                Infocode."Refund Card_DXR" := Infocode."DX Refund Card";
                Infocode.Modify(false);
            until Infocode.Next() = 0;
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
    begin
        if PosTerminal.Findset(false) then
            repeat
                PosTerminal."Uses VeriPhone_DXR" := PosTerminal."DX Uses VeriPhone";
                PosTerminal.Puerto_DXR := PosTerminal.DXPuerto;
                PosTerminal.Proveedor_DXR := PosTerminal.DXProveedor;
                PosTerminal."Imprime Ticket_DXR" := PosTerminal."DXImprime Ticket";
                PosTerminal."Puerto Secundario_DXR" := PosTerminal."DXPuerto Secundario";
                PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."DXDireccion IP Secundaria";
                PosTerminal."Direccion IP_DXR" := PosTerminal."DXDireccion IP";
                PosTerminal."Puerto IP_DXR" := PosTerminal."DXPuerto IP";
                PosTerminal."Numero Transaccion_DXR" := PosTerminal."DXNumero Transaccion";
                PosTerminal."Numero Terminal_DXR" := PosTerminal."DXNumero Terminal";
                PosTerminal."Merchant ID_DXR" := PosTerminal."DXMerchant ID";
                PosTerminal.RutaFirma_DXR := PosTerminal.DXRutaFirma;
                PosTerminal.Auth1_DXR := PosTerminal.DXAuth1;
                PosTerminal.Auth2_DXR := PosTerminal.DXAuth2;
                PosTerminal.IpString_DXR := PosTerminal.DXIpString;
                PosTerminal.Rpuerto_DXR := PosTerminal.DXRpuerto;
                PosTerminal.LocalIpString_DXR := PosTerminal.DXLocalIpString;
                PosTerminal.LPuerto_DXR := PosTerminal.DXLPuerto;
                PosTerminal."Cierre Automatico_DXR" := PosTerminal."DXCierre Automatico";
                PosTerminal."Visanet IpString_DXR" := PosTerminal."DX Visanet IpString";
                PosTerminal."Visanet Puerto_DXR" := PosTerminal."DX Visanet Puerto";
                PosTerminal.URLEndPoint_DXR := PosTerminal.DXURLEndPoint;
                PosTerminal."Use Amount In Currency_DXR" := PosTerminal."DX Use Amount In Currency";
                PosTerminal."Local Currency Symbol_DXR" := PosTerminal."DX Local Currency Symbol";
                PosTerminal.Modify(false);
            until PosTerminal.Next() = 0;
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
    begin
        if PosTransLine.Findset(false) then
            repeat
                PosTransLine."VP Approved_DXR" := PosTransLine."DXVP Approved";
                PosTransLine."VP Authorization No._DXR" := PosTransLine."DXVP Authorization No.";
                PosTransLine."VP Lot No._DXR" := PosTransLine."DXVP Lot No.";
                PosTransLine."Cuota Quantity_DXR" := PosTransLine."DXCuota Quantity";
                PosTransLine.Modify(false);
            until PosTransLine.Next() = 0;
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
    begin
        if TenderType.Findset(false) then
            repeat
                TenderType."ReqVeriphoneProcessing_DXR" := TenderType."DXRequiredVeriphoneProcessing";
                TenderType.tPayment_DXR := TenderType.DXtPayment;
                TenderType."Cuota Payment_DXR" := TenderType."DXCuota Payment";
                TenderType."Use Form For Cuotas_DXR" := TenderType."DXUse Form For Cuotas";
                TenderType."InfoCode For Cuotas_DXR" := TenderType."DXInfoCode For Cuotas";
                TenderType.Modify(false);
            until TenderType.Next() = 0;
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
    begin
        if TransPaymentEntry.Findset(false) then
            repeat
                TransPaymentEntry."VP Approved_DXR" := TransPaymentEntry."DXVP Approved";
                TransPaymentEntry."VP Authorization No._DXR" := TransPaymentEntry."DXVP Authorization No.";
                TransPaymentEntry."VP Lot No._DXR" := TransPaymentEntry."DXVP Lot No.";
                TransPaymentEntry."Cuota Quantity_DXR" := TransPaymentEntry."DXCuota Quantity";
                TransPaymentEntry.Modify(false);
            until TransPaymentEntry.Next() = 0;
    end;
}
```

- [ ] **Step 3: Compile** (Global Constraints command). Expected: 0 errors. If any field name above fails to resolve, re-read the real tableextension source for that table under `DXPAYMENT-BC\` to confirm the exact spelling/case before adjusting (do not guess).

- [ ] **Step 4: Publish, Reload Registry, run the DXP-P2 concept**, confirm non-zero `Migrated Record Count` in `DXR MCC Run Log` where the base tables have rows with the legacy fields populated.

- [ ] **Step 5: Commit**

```bash
git add src/Adapters/DXP/DXRMCCDXPMigrPhase2.Codeunit.al
git commit -m "fix: DXP Phase2 field copies routed through generic RecordRef/FieldRef helper despite already knowing every real field name - convert to direct typed assignment"
```

---

## Task A.3: Worked example (Thin-wrapper pattern, Access=Internal) — DRLOC Payment Method Relation

**Files:**
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DR-Localization\Localization\src\Tables.old\DXPaymentMethodRelation.Table.al` (confirmed: table 54133 "DXPayment Method Relation", 3 fields: `Code` Code[10], `Description` Text[100], `"Payment Method Code"` Code[10])
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DR-Localization\Localization\src\Base\Tables\DXR_PaymentMethodRelation.Table.al` (confirmed: table 52180 "DXR_Payment Method Relation", **`Access = Internal`**, identical 3-field layout, wrapped in `#if DX28PREFIX`)
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DR-Localization\Localization\src\Base\Codeunits\Uprade\DXR_Migr_Phase_2_Fiscal.Codeunit.al` in full — confirm its own `Access` modifier (expected: normal, not Internal, since it's invoked externally today) and whether a per-step public procedure for Payment Method Relation already exists; if not, add one.
- Modify (in DRLOC's own repo, not MCC's — separate commit/branch there): `DR-Localization\Localization\src\Base\Codeunits\Uprade\DXR_Migr_Phase_2_Fiscal.Codeunit.al` — add/confirm a public `RunBootstrap_PaymentMethodRelation()` procedure with **typed** `Record "DXR_Payment Method Relation"` / `Record "DXPayment Method Relation"` internally (not RecordRef) — DRLOC's own codeunit CAN reference its own `Access = Internal` table directly, same package.
- Modify (in MCC): `src\Adapters\DRLOC\DXRMCCAdaptDRLOCPaymentMethodRel.Codeunit.al` (create) — thin wrapper only, calls the DRLOC public procedure, never declares `Record "DXR_Payment Method Relation"` itself.
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — DRLOC-P2 seq13 (currently `InsConcept('DRLOC', 'DRLOC-P2', 13, 'Payment Method Relation legacy table restore (54133 -> 52180)', 60069, 54133, 52180, 'SETUP')`, `Dispatcher Codeunit ID` still the shared 60069 dispatcher — repoint to this task's new codeunit ID)
- Modify: `src\DXRMCCPermissionSet.PermissionSet.al`

**Interfaces:**
- Consumes: `"DXR_Migr_Phase_2_Fiscal".RunBootstrap_PaymentMethodRelation()` (public, no parameters, no return value).
- Produces: codeunit ID (verify current max per Global Constraints, e.g. 60164) for MCC's thin-wrapper adapter; this is the reference pattern every other DRLOC concept in Task A.4/B.1/C.1/D.1 follows, since essentially all of DRLOC's targets are `Access = Internal` per Task 0.2.

- [ ] **Step 1: Read `DXR_Migr_Phase_2_Fiscal.Codeunit.al` in full.** Confirm: (a) its own `Access` modifier is not `Internal`; (b) whether Payment Method Relation already has its own callable step (look for a procedure name matching the existing bundled `StartStep`/`RunStep` framework's step list) — if yes, note the exact real procedure name for Step 3 below instead of inventing `RunBootstrap_PaymentMethodRelation`; if no such procedure exists yet, proceed to Step 2.

- [ ] **Step 2 (only if Step 1 found no existing per-step procedure): add one**, typed, no RecordRef, in DRLOC's own codeunit:

```al
    // Exposed 2026-08-24 for DXR MCC's native adapters (see MCC's docs/superpowers/plans/
    // 2026-08-24-mcc-full-portfolio-native-migration.md, Task A.3). DXR_Payment Method Relation
    // is Access=Internal - this procedure must live here, inside DRLOC's own package, since MCC
    // (an external app) cannot declare Record "DXR_Payment Method Relation" itself.
    procedure RunBootstrap_PaymentMethodRelation()
    var
        Legacy: Record "DXPayment Method Relation";
        New: Record "DXR_Payment Method Relation";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Code, Legacy."Payment Method Code") then begin
                    New.Init();
                    New.TransferFields(Legacy, true);
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;
```

(Confirmed 1:1 field layout between the two tables in Step 0's reads — `TransferFields` is safe here, matches the pattern already used successfully elsewhere in this portfolio.)

- [ ] **Step 3: Compile DRLOC standalone** to confirm Step 2's addition alone doesn't break anything (visibility/addition only, no behavior change to existing callers).

- [ ] **Step 4: Commit in DRLOC's own repo**

```bash
git add "src/Base/Codeunits/Uprade/DXR_Migr_Phase_2_Fiscal.Codeunit.al"
git commit -m "feat: expose typed RunBootstrap_PaymentMethodRelation for MCC's native adapter (Access=Internal thin-wrapper pattern)"
```

- [ ] **Step 5: Write MCC's thin-wrapper adapter**

```al
codeunit 60164 "DXR MCC Adapt DRLOC PmtMethod"
{
    // DXR_Payment Method Relation (52180) is Access=Internal in DRLOC - MCC cannot declare
    // Record "DXR_Payment Method Relation" directly. This adapter calls DRLOC's own typed public
    // procedure instead (see DR-Localization's own commit, this same task). MCC's side stays
    // zero-RecordRef trivially, since it is a pure single-call wrapper.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr_Phase_2_Fiscal";
    begin
        Phase2.RunBootstrap_PaymentMethodRelation();
    end;
}
```

- [ ] **Step 6: Repoint the registry** — in `src\DXRMCCRegistryLoader.Codeunit.al`, change DRLOC-P2 seq13's `Dispatcher Codeunit ID` from `60069` to `60164`.

- [ ] **Step 7: Add to `src\DXRMCCPermissionSet.PermissionSet.al`**: `codeunit "DXR MCC Adapt DRLOC PmtMethod" = X,`

- [ ] **Step 8: Compile MCC** (Global Constraints command). Expected: 0 errors — requires DRLOC's updated `.app` symbol package in `.alpackages` first (`dxr-symbol-management`).

- [ ] **Step 9: Publish, Reload Registry, run just this concept**, confirm non-zero `Migrated Record Count` in `DXR MCC Run Log`, independent of the other 17 DRLOC-P2 concepts' run state.

- [ ] **Step 10: Commit in MCC**

```bash
git add src/Adapters/DRLOC/DXRMCCAdaptDRLOCPaymentMethodRel.Codeunit.al src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -m "feat: native thin-wrapper adapter for DRLOC Payment Method Relation - reference pattern for Access=Internal targets"
```

---

## Task A.4: Setup-phase sweep — every remaining `Category = Setup` concept, all extensions

**Files:**
- Read: `src\DXRMCCRegistryLoader.Codeunit.al` (live worklist source, Step 1)
- Create: one adapter `.al` file per concept under `src\Adapters\<EXT>\...`, following whichever pattern Task 0.2 assigned to that extension (Direct — Task A.1/A.2 shape; Thin-wrapper — Task A.3 shape)
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al`, `src\DXRMCCPermissionSet.PermissionSet.al`, `app.json` (batched wire-up per Global Constraints' shared-file lock rule)

**Interfaces:**
- Consumes: Task 0.2's per-extension Direct/Thin-wrapper classification; Task A.1-A.3's two reference code shapes.
- Produces: nothing consumed by a later task in this plan (Task B.1 has its own independent worklist query) — but every future automated run of "Run All Setup" depends on this task's output being complete.

- [ ] **Step 1: Pull the live, current worklist** — do not use a frozen copy, the registry is the source of truth and may have changed since this plan was authored:

```bash
grep "'SETUP'" src/DXRMCCRegistryLoader.Codeunit.al
```

(240 rows as of this plan's authoring, spanning all 17 originally-registered extensions; re-run after Task 0.1 to pick up any Setup concepts the 4 newly-registered extensions add.) For each row, note: Extension Code, Phase Code, Sequence No., Description (usually contains the real legacy/new table IDs or field count), current `Dispatcher Codeunit ID`, `Legacy Table ID`, `New Table ID`.

- [ ] **Step 2: Group the worklist by extension**, and for each extension in turn (recommended order: smallest concept-count first for fast wins — TU(2), BELLONPOS(2), LSFE(1), RBPD(3), RC(5), DESLS(5), PCM(7), VP(7), DXP(14, minus DXP-P2 already fixed by Task A.2), BC(12), DESB(12), LSLOC(13), FE(20), DRLOC(25), BELLON(106) — then any Setup rows Task 0.1's 5 new extensions contributed. **Skip SD entirely** - confirmed already fully converted, see Task A.2's correction note; only verify its concepts' Category tags and registry wiring, do not touch its adapter code):
  - For each concept whose `Legacy Table ID`/`New Table ID` are non-zero (whole-table restore): dispatch a `dxr-repository-intelligence` research agent with this prompt template (fill in the real values from Step 1's row):

    > "Read `<extension's real path under C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\>`. Confirm the real AL table name and full field list for legacy table ID `<Legacy Table ID>` and new table ID `<New Table ID>`. Cite file:line. Report: are the field lists 1:1 identical (safe for `TransferFields`), or renamed/reduced (need explicit per-field list)? If renamed, list every legacy field name -> new field name pair with its ObsoleteReason citation."

    Then write the adapter following Task A.3's `TransferFields`-or-explicit-list shape (Direct) or Task A.3's thin-wrapper shape (if Task 0.2 marked this extension Thin-wrapper) — same structure, real names substituted.

  - For each concept whose `Legacy Table ID`/`New Table ID` are both `0` (tableextension field-group — same signature as Task A.1's Assembly Setup case): dispatch the same research agent type with:

    > "Read the tableextension source in `<extension's real path>` covering the fields described as: `<Description text from the registry row>`. For each field, cite its `ObsoleteReason` line and confirm the exact currently-active `_DXR` target field name and number (not an intermediate `_Old`/`_Old2` shadow field, per the confirmed Task A.1 bug pattern — verify the `_DXR` field is genuinely the one other code in the extension reads from, not an orphan)."

    Then write the adapter following Task A.1's direct-typed-field-assignment shape, one `New."Field_DXR" := Old."Field";` line per confirmed pair, `if <> then` guard + single `Modify()` after the block (not per-field).

- [ ] **Step 3: Batch wire-up per extension** (respects the shared-file lock) — once all of one extension's Setup adapters in this sweep are written and individually compile-clean in isolation, apply in one edit: repoint every one of that extension's Setup rows in `src\DXRMCCRegistryLoader.Codeunit.al` to its new adapter ID, add all new codeunits to `src\DXRMCCPermissionSet.PermissionSet.al`, add the extension to `app.json` `dependencies` if not already present (Task 0.1's pattern).

- [ ] **Step 4: Compile the whole MCC extension** (Global Constraints command) after each extension's batch. Expected: 0 errors before moving to the next extension in Step 2's list.

- [ ] **Step 5: Publish, Reload Registry, run "Run All Setup"**, confirm in `DXR MCC Run Log` that every Setup-category concept for the extension just batched shows non-zero `Migrated Record Count` where the source table has real rows.

- [ ] **Step 6: Commit per extension batch**

```bash
git add src/Adapters/<EXT>/ src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al app.json
git commit -m "feat: native direct-field Setup adapters for <EXT> (N concepts)"
```

- [ ] **Step 7: Repeat Steps 2-6 for every extension in the Step 2 order until the Step 1 worklist is empty** (re-run Step 1's grep to confirm zero `'SETUP'` rows still pointing at a pre-existing legacy dispatcher ID rather than a `src/Adapters/` codeunit — cross-check by grepping each Dispatcher Codeunit ID used against `src/Adapters/*/*.al`'s own declared codeunit IDs).

---

## Task B.1: Master/Accounting-phase sweep — every `Category = MA` concept, all extensions (incl. RecordRef remediation)

**Files:** Same shape as Task A.4, plus explicitly:
- Modify: `src\Adapters\BELLON\DXRMCCBellonMigrPhase2.Codeunit.al`, `...Phase6...al`, `...Phase7...al` (and any other BELLON phase file using the `RecRef.Open(Database::"X")` reflection pattern for a Master/Accounting-category table — Customer, Item, Vendor, Contact, Currency, Gen. Journal Line, etc., per the ~87 `MigrateTableExt_*` procedures found in Phase2 alone)
- Modify: `src\Adapters\BELLONPOS\DXRMCCBellonPOSMigrPhase2.Codeunit.al`
- Modify: `src\Adapters\LSFE\DXRMCCLSFEMigrAssignPermSet.Codeunit.al`, `DXRMCCLSFEMigrPOSContingency.Codeunit.al`
- Modify: `src\Adapters\LSLOC\DXRMCCLSLOCMigrDepFields.Codeunit.al`, `DXRMCCLSLOCMigrOPOSSetup.Codeunit.al`, `DXRMCCLSLOCMigrToDXRLS.Codeunit.al`

**Interfaces:**
- Consumes: Task 0.2's classification, Task A.1/A.3's two reference shapes (same shapes, different category filter).
- Produces: nothing consumed later in this plan.

- [ ] **Step 1: Pull the live worklist**, same mechanism as Task A.4 Step 1, filtered to Master/Accounting:

```bash
grep "'MA'" src/DXRMCCRegistryLoader.Codeunit.al
```

(264 rows as of this plan's authoring.)

- [ ] **Step 2: First, remediate the 4 already-"native" extensions' RecordRef violations** (highest priority within this phase — these currently report `Completed`/success while running generic reflection code, exactly the risk this whole plan exists to remove):
  - For BELLON: `grep -n "RecRef: RecordRef" src/Adapters/BELLON/*.al` to enumerate every `MigrateTableExt_*` / `MigrateLegacyTableData`-style procedure still using the pattern. For each, dispatch a `dxr-repository-intelligence` agent with:

    > "Read the tableextension source for `<table name from the procedure name, e.g. 'Customer' from MigrateTableExt_CustomerFields>` under `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Bellon_Customization\Bellon Customization\src\Extentions\tables\`. List every field with an `ObsoleteReason` pointing at a `_DXR` replacement, its legacy field name/number and confirmed real `_DXR` target field name/number (apply the Task A.1 lesson: verify against an `_Old`/`_Old2` shadow-field trap, don't assume the numerically-adjacent field is the real target)."

    Rewrite each confirmed procedure to Task A.1's direct shape (typed `Record` on the base table, one `New."X_DXR" := New."X";` per confirmed field, single `Modify()`).
  - For BELLONPOS/LSFE/LSLOC: same mechanism, smaller surface (2, 2, 3 files respectively per current `src/Adapters/` listing) — read each file first to confirm whether it already avoids RecordRef (LSFE's 2 files were noted in the design spec as already-typed in the original Discovery pass — verify this claim with a real grep before assuming, per the Task A.2 lesson that "already typed" claims from the 2026-08-23 Discovery were not always accurate) or genuinely needs the same remediation as BELLON.

- [ ] **Step 3: Then sweep the remaining Master/Accounting concepts** across all extensions, same per-extension research→write→batch-wire-up→compile→verify→commit loop as Task A.4 Steps 2-6, filtered to this phase's worklist.

- [ ] **Step 4: Repeat until the Step 1 worklist (re-queried) is empty**, same cross-check as Task A.4 Step 7.

---

## Task C.1: Historic-phase sweep — every `Category = Historic` concept, all extensions except DGII-RNC

**Files:** Same shape as Task A.4/B.1.

**Interfaces:**
- Consumes: Task 0.2's classification, Task A.1/A.3's reference shapes.
- Produces: the exit condition Task D.1 gates on (Historic sweep fully done, DGII-RNC concept excluded).

- [ ] **Step 1: Pull the live worklist, explicitly excluding DGII-RNC**:

```bash
grep "'HIST'" src/DXRMCCRegistryLoader.Codeunit.al | grep -v "DGII-RNC"
```

(163 rows as of this plan's authoring, minus the 1 DGII-RNC row once Task C.2/pre-step below recategorizes it — see Step 2.)

- [ ] **Step 2: Recategorize DGII-RNC Database from `MA` to `Historic`** first (it is currently tagged `'MA'`, confirmed at `src/DXRMCCRegistryLoader.Codeunit.al:130`: `InsConcept('DRLOC', 'DRLOC-P2', 15, 'DGII-RNC Database legacy table restore (54119 -> 52156)', 60069, 54119, 52156, 'MA')`). Change the trailing `'MA'` to `'HIST'` on this exact line. Recompile, confirm this single-field change compiles clean, commit separately before continuing this task's sweep:

```bash
git add src/DXRMCCRegistryLoader.Codeunit.al
git commit -m "fix: recategorize DGII-RNC Database MA->Historic - runs last, per plan's explicit ordering (largest/highest-risk concept in the portfolio)"
```

- [ ] **Step 3: Sweep the remaining Historic concepts** across all extensions, same per-extension research→write→batch-wire-up→compile→verify→commit loop as Task A.4 Steps 2-6, filtered to this phase's worklist (post-Step 2's exclusion).

- [ ] **Step 4: Repeat until the Step 1 worklist (re-queried) is empty.**

---

## Task D.1: DGII-RNC Database — final task, gated on Task C.1 being fully complete

**Files:**
- Read: `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DR-Localization\Localization\src\Base\Tables\DXR_DGIIRNCDatabase.Table.al` (confirmed `Access = Internal`, per Task 0.2's audit — same pattern as Task A.3)
- Read: legacy table ID 54119's real source (search `DR-Localization\Localization\src\Tables.old\` for the table matching that ID)
- Read: `DR-Localization\Localization\src\Base\Codeunits\Uprade\DXR_Migr_Phase_2_Fiscal.Codeunit.al` — confirm whether the "RNC database backfill" step (referenced in `docs/superpowers/plans/2026-08-23-mcc-native-migration.md`'s Discovery Summary as the large/slow step inside the bundled 18-step `52210` dispatcher) already has, or needs, its own callable public procedure, same check as Task A.3 Step 1
- Modify (DRLOC repo): same file, add/confirm a typed `RunBootstrap_DgiiRncDatabase()` public procedure if Step 1 finds none
- Create (MCC): `src\Adapters\DRLOC\DXRMCCAdaptDRLOCDgiiRnc.Codeunit.al`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` (DRLOC-P2 seq15's `Dispatcher Codeunit ID`, currently the shared `60069`)
- Modify: `src\DXRMCCPermissionSet.PermissionSet.al`

**Interfaces:**
- Consumes: `"DXR_Migr_Phase_2_Fiscal".RunBootstrap_DgiiRncDatabase()` (exact name confirmed by Step 1, do not assume).
- Produces: nothing consumed elsewhere — this is the last task in the plan.

**Prerequisite check (do not skip):** confirm Task C.1 is fully checked off and its final worklist re-query returned zero rows before starting this task. This concept is deliberately last because it is the confirmed largest/highest-row-volume single migration in the portfolio (per the 2026-08-23 plan's Discovery: implicated in the "se traba en Company Information, no sigue iterando" bug report, since it currently runs bundled inside the same blocking 18-step call as the much smaller Company Information step).

- [ ] **Step 1: Read `DXR_Migr_Phase_2_Fiscal.Codeunit.al` in full**, locate the RNC/DGII step inside its `StartStep`/`RunStep` framework. Confirm: (a) does it already use typed `Record` internally, or `RecordRef`? (b) is it already independently callable as a public procedure? Record the real procedure name (or absence) and its current implementation shape.

- [ ] **Step 2 (only if needed): expose/rewrite the step as a typed public procedure**, same reasoning as Task A.3 Step 2 — the table is `Access = Internal`, so the typed loop must live inside DRLOC's own codeunit:

```al
    // Exposed/rewritten 2026-08-24 for DXR MCC's native adapter (see MCC's docs/superpowers/
    // plans/2026-08-24-mcc-full-portfolio-native-migration.md, Task D.1 - the deliberately LAST
    // migration in MCC's whole portfolio-wide sequence, due to this table's confirmed size/risk).
    // DXR_DGIIRNCDatabase is Access=Internal - this must live in DRLOC's own package.
    procedure RunBootstrap_DgiiRncDatabase()
    var
        Legacy: Record "<real legacy table name confirmed in Step 1's read>";
        New: Record "DXR_DGIIRNCDatabase";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(<real primary key field(s) confirmed in Step 1's read>) then begin
                    New.Init();
                    New.TransferFields(Legacy, true); // or explicit per-field list if Step 1 found a renamed/reduced layout
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;
```

- [ ] **Step 3: Compile DRLOC standalone.** Expected: 0 errors.

- [ ] **Step 4: Commit in DRLOC's own repo**

```bash
git add "src/Base/Codeunits/Uprade/DXR_Migr_Phase_2_Fiscal.Codeunit.al"
git commit -m "feat: expose typed RunBootstrap_DgiiRncDatabase for MCC's native adapter - last step of the portfolio-wide migration sequence"
```

- [ ] **Step 5: Write MCC's thin-wrapper adapter**

```al
codeunit 60165 "DXR MCC Adapt DRLOC DgiiRnc"
{
    // Deliberately the LAST concept run in MCC's entire portfolio-wide 4-phase sequence (Setup ->
    // Master/Accounting -> Historic -> this) - confirmed the largest/highest-risk single migration
    // in the portfolio. DXR_DGIIRNCDatabase is Access=Internal, same thin-wrapper pattern as Task
    // A.3's DRLOC Payment Method Relation.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr_Phase_2_Fiscal";
    begin
        Phase2.RunBootstrap_DgiiRncDatabase();
    end;
}
```

- [ ] **Step 6: Repoint the registry** — DRLOC-P2 seq15's `Dispatcher Codeunit ID` from `60069` to this codeunit's real ID (verify current max per Global Constraints before finalizing the literal above).

- [ ] **Step 7: Add to `src\DXRMCCPermissionSet.PermissionSet.al`**: `codeunit "DXR MCC Adapt DRLOC DgiiRnc" = X,`

- [ ] **Step 8: Compile MCC** (Global Constraints command). Expected: 0 errors.

- [ ] **Step 9: Publish, Reload Registry, run just this concept in a test company with a real (non-trivial) RNC dataset**, confirm non-zero `Migrated Record Count` in `DXR MCC Run Log`, and confirm it completes independently of the other 17 DRLOC-P2 concepts (proves the bundled-dispatcher blocking bug is fixed for this, the largest step).

- [ ] **Step 10: Commit in MCC**

```bash
git add src/Adapters/DRLOC/DXRMCCAdaptDRLOCDgiiRnc.Codeunit.al src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -m "feat: native thin-wrapper adapter for DGII-RNC Database - final task of the full-portfolio native migration plan"
```

- [ ] **Step 11: Run "Run Portfolio" end-to-end in a test environment**, confirm every concept across all 18 extensions shows `Completed` (or `Completed (Fallback)`, never bare `Error`) in `DXR MCC Run Log`, and that the `DXR MCC Gap Report` shows zero unexplained gaps. This is the plan's final acceptance check.
