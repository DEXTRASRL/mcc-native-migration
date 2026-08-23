# MCC Native Migration Adapters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give "DXR Migration Control Center" (MCC) a compile-time (typed) path into every legacy→DXR_ migration across the Dextra BC portfolio, so it stops depending on the executing user/task already holding each target extension's own permission set, stops silently no-op'ing on dispatcher codeunits that lack a real `OnRun`, and can run/commit/log at real per-table granularity instead of one giant blocking call per phase.

**Architecture:** MCC keeps its existing registry (`DXR MCC Concept` → `Dispatcher Codeunit ID` → `Codeunit.Run()`) completely unchanged. What changes is *what* `Dispatcher Codeunit ID` points at: instead of pointing at an extension's own phase/dispatcher codeunit (opaque ID, no compile-time reference, sometimes missing `OnRun` entirely, sometimes bundling 18 tables into one call), it points at a small **native MCC "adapter" codeunit** that has a real `trigger OnRun`, lives inside MCC, and calls the target extension's *real, already-correct* migration procedure directly and typed (`Record "Legacy X"`, not `RecordRef`). This requires MCC to declare each target extension as an `app.json` dependency. One adapter = one concept = one table/step, so MCC gets real per-concept commit/log for free through the existing `LogAndCount`/`Commit()` machinery already fixed in this session. **We do NOT re-implement the field-by-field migration logic that's already correct** (confirmed typed and correct in ~80% of the portfolio by the discovery pass below) — we only give MCC a proper, typed, granular way to *call* it. We only write new logic where the discovery pass found the original is missing, broken, or unreachable (see per-extension findings).

**Explicit exclusion (per user instruction):** any codeunit confirmed `Subtype = Upgrade` is never made an adapter target for `Codeunit.Run()` — the platform hard-blocks that outside its own publish/schema-sync cycle and there is no code-level workaround. Where an Upgrade-subtype codeunit's real logic is already exposed to a **normal, sibling codeunit** via public procedure calls (confirmed pattern: DRLOC's 52210 calls into 52189's public procedures directly, Bellon's Phase-2/6/7 wrappers call into `BellonUpgradeProcess`'s public procedures directly), MCC adapts to *that sibling*, never to the Upgrade codeunit itself. Where no such sibling exists, the concept stays `Blocked` with a reason, exactly as already documented in the registry.

**Tech Stack:** AL (Business Central 28.x, runtime 17.0), no new external dependencies. New: `app.json` dependencies on the target extensions being adapted in each phase.

**Spec:** This document is self-derived from a 5-agent discovery pass across the whole portfolio (2026-08-23) plus direct source reads of `DXRMCCExecutor.Codeunit.al`, `DXRMCCRegistryLoader.Codeunit.al`, `DXRMCCCounter.Codeunit.al`, `DXRMCCFallbackMigrator.Codeunit.al` earlier the same session. No separate spec file exists; findings are cited inline per task with file:line evidence.

## Global Constraints

- Never call `Codeunit.Run()` on a codeunit confirmed `Subtype = Upgrade`. Confirmed IDs (do not add these as adapter targets, ever): `52248, 36003045, 52189, 36003049, 51962, 36002776, 52255, 36003047, 53669, 59221, 53562, 52587, 36003121, 53600, 54856, 54662, 54599, 54742, 54743, 54534, 53923, 54445, 36003619, 52773, 54779, 52743, 52667, 52120396, 53648, 52119593, 54283` (54283 added this plan — see Task 1.3, was missing from `IsKnownUpgradeCodeunit`).
- Never duplicate field-mapping logic that discovery already confirmed correct and typed — call it, don't rewrite it.
- Every adapter codeunit gets its own real `trigger OnRun` (fixes the "no OnRun = silent no-op" bug class found in SD/DXP).
- One adapter = one `DXR MCC Concept` row's granularity of work (never bundle 18 tables behind one adapter the way legacy dispatchers do) — this is what fixes DRLOC's "stuck, nothing in the logs" behavior.
- Every new `app.json` dependency addition must use the real `id`/`publisher`/`name`/`version` read directly from that extension's own `app.json` — never guessed or copied from the registry's free-text notes.
- Existing `DXRMCCExecutor.Codeunit.al` dispatch mechanism (`RunDispatcher` → `Codeunit.Run(DispatcherCodeunitId)`) is NOT modified by this plan — adapters are designed to slot into it unchanged.
- Do not touch a source extension's own dispatcher/phase codeunits unless a task explicitly says to (only DRLOC Task 2.1 and the BELLON POS follow-up in the Roadmap require a source-extension edit, both called out explicitly).

---

## Discovery Summary (evidence backing every phase below)

5 parallel read-only agents audited all 16 legacy extensions against MCC's registry on 2026-08-23. Full per-concept classification tables are in the Roadmap appendix at the end of this document. Headline findings:

| Finding | Impact | Where fixed in this plan |
|---|---|---|
| SD-P1/P2 (9 concepts) and DXP-P1-P4 (32 concepts) point at codeunits with **no `trigger OnRun`** — `Codeunit.Run()` silently no-ops and returns success. Zero rows have ever migrated via MCC for these 41 concepts. | 41 concepts falsely reportable as "Completed" while doing nothing, portfolio-wide highest-severity single finding | **Phase 1** (this plan, first) |
| DPP's `Subtype=Upgrade` codeunit 54283 is missing from `IsKnownUpgradeCodeunit` in Executor | Live crash risk identical to the SD 54779 incident already fixed this session | **Task 1.3** |
| DRLOC-P2 (52210) bundles 18 concepts into one blocking `Codeunit.Run()` call with no internal commit visible to MCC — a slow/large step (RNC database backfill) can exceed a session timeout, silently rolling back MCC's entire Concept/RunLog transaction for that whole scope even though 52210's own internal batches already persisted real data | Explains exactly "se traba en Company Information, no sigue iterando, no se refleja en los logs" | **Phase 2** |
| ~80% of the portfolio's real migration procedures (DESB Worker/Phase1, DESLS Phase1-partial, RC Phase1/2/4/5, most of BC, RBPD, most of BELLON P2/P6/P7, LSFE) already use typed `Record`, already have correct/adequate `Permissions`, and are already logically correct | These do NOT need re-implementation — only a thin native `OnRun` adapter that calls their existing public procedure, once MCC has a dependency on them | Roadmap Phase 3+ (mechanical, low risk) |
| Bellon POS's real migration codeunit (`DXR_POS Upgrade Process`) has **no `Permissions` property at all** for the tables it touches | Confirmed real bug in that extension, independent of MCC | Roadmap, flagged as a BELLONPOS source-extension fix, not an MCC workaround |
| DXP-P3 and DXP-P5 both restore the same target tables (52275-52283) from two different legacy generations with no enforced ordering; Phase3 checks Phase1's tag, Phase5 doesn't | Silent "whichever runs first wins" data precedence bug — **not a code bug to silently fix**, needs a business decision on source-of-truth generation | Flagged as **BLOCKING QUESTION** before Phase 4 (DXP) — see Roadmap |
| VP's Phase 1-6 (gen-1) and Phase 7 (23 tables) migrate the same 23 destination tables from two source generations; Phase 7's own merge is already "fill gaps, never overwrite" and explicitly safe run in either order | Not a bug — but porting both as 46 separate adapters would be needless duplication | Roadmap: collapse to 23 adapters, each trying gen-1 source then `_Old` shell source in sequence |
| BELLON Phase 10 dispatcher (56127) is a **confirmed deliberate no-op** ("MigrateAllSalesPurchOldDedup2 is now a deliberate no-op tag-setter") | Not a bug, do not "fix" | Roadmap: leave concept as `Not Row-Based`/informational, do not build an adapter |
| DRLOC-NCF seq6/seq7 and SD-P3 already represent code-level fixes/permission-repairs, not row-based runtime actions | Confirmed correctly falls to `"Not Row-Based"` after this session's earlier Executor fix — no adapter needed, just an operator `Blocked` flag for tidiness | Roadmap note only |

---

## File Structure

```
DXR-Migration-Control-Center/
  app.json                                    Modify: add dependencies incrementally, one per phase
  src/
    Adapters/
      DRLOC/
        DXRMCCAdaptDRLOCCompanyInfo.Codeunit.al       Create (Phase 2)
        DXRMCCAdaptDRLOCPaymentMethodRel.Codeunit.al  Create (Phase 2)
        DXRMCCAdaptDRLOCRncDatabase.Codeunit.al       Create (Phase 2)
        ... one file per DRLOC concept being adapted (Roadmap Phase 2 continuation)
      SD/
        DXRMCCAdaptSDPhase1FieldDup.Codeunit.al       Create (Phase 1)
        DXRMCCAdaptSDPhase2LegacyTable.Codeunit.al    Create (Phase 1)
      DXP/
        DXRMCCAdaptDXPPhase1Tables.Codeunit.al        Create (Phase 1)
        DXRMCCAdaptDXPPhase2Tables.Codeunit.al        Create (Phase 1)
        DXRMCCAdaptDXPPhase3Tables.Codeunit.al        Create (Phase 1, blocked pending business decision)
        DXRMCCAdaptDXPPhase4Tables.Codeunit.al        Create (Phase 1)
      <Extension>/...                                  Create (one folder per Roadmap phase, added incrementally)
    DXRMCCExecutor.Codeunit.al                  No change (dispatch mechanism already fits adapters)
    DXRMCCRegistryLoader.Codeunit.al            Modify: repoint "Dispatcher Codeunit ID" per concept, per phase
  docs/superpowers/plans/
    2026-08-23-mcc-native-migration.md          This file
```

Each adapter codeunit owns exactly one responsibility: call one real, existing procedure, typed, with a real `OnRun`. New adapters are added to a per-extension folder so the growing dependency list stays easy to audit against `app.json`.

---

## Task 1.0: Confirm real app.json identity for SD and DXP (prerequisite for Phase 1)

**Files:**
- Read: `Special dispatch\Special-Distpach\Pedidos Especiales\app.json` (path per Discovery; confirm exact folder name first with `ls`)
- Read: `DXPAYMENT-BC\app.json`
- Modify: `DXR-Migration-Control-Center\app.json`

**Interfaces:**
- Produces: exact `{id, publisher, name}` for SD and DXP, plus the deployed `version` string MCC's `packagecachepath` should target — later tasks in Phase 1 consume these to add `dependencies` entries.

- [ ] **Step 1: Read both app.json files and copy their exact id/publisher/name/version verbatim** (do not transcribe from the registry's free-text notes, which are not guaranteed byte-exact)

- [ ] **Step 2: Add both as dependencies in MCC's app.json**

```json
"dependencies": [
  {
    "id": "18373840-6093-4765-8799-491f61accb2b",
    "publisher": "<exact publisher from SD's app.json>",
    "name": "<exact name from SD's app.json>",
    "version": "<exact version from SD's app.json>"
  },
  {
    "id": "36b9c68f-cc27-46b1-bf63-4400a31c5f61",
    "publisher": "<exact publisher from DXP's app.json>",
    "name": "<exact name from DXP's app.json>",
    "version": "<exact version from DXP's app.json>"
  }
]
```

(`id` values are already confirmed from `DXRMCCRegistryLoader.Codeunit.al:64,66` — `publisher`/`name`/`version` are not, hence Step 1.)

- [ ] **Step 3: Run `al_download symbols` / refresh `.alpackages`** so MCC's compiler cache has SD's and DXP's symbol packages available (via the AL extension's own "Download Symbols" or the `alc.exe` toolchain already confirmed working in this session — see Task 1.5 for the exact compile command)

- [ ] **Step 4: Commit**

```bash
git add app.json
git commit -m "build: add SD and DXP as MCC dependencies for native adapter codeunits"
```

---

## Task 1.1: SD adapters — Phase 1 (Field Dup) and Phase 2 (Legacy Table)

**Files:**
- Read: `Special dispatch\...\Base\Migration\DXR_SD_Migr_Phase1_FieldDup.Codeunit.al` (confirm exact public procedure signature — Discovery confirmed it exposes `procedure Execute()` at line 24, not `trigger OnRun`)
- Read: `Special dispatch\...\Base\Migration\DXR_SD_Migr_Phase2_LegacyTable.Codeunit.al` (confirm `procedure Execute()` at line 14)
- Create: `src\Adapters\SD\DXRMCCAdaptSDPhase1FieldDup.Codeunit.al`
- Create: `src\Adapters\SD\DXRMCCAdaptSDPhase2LegacyTable.Codeunit.al`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — SD-P1 (seq 1,3-9) and SD-P2 (seq 2) `InsConcept` rows

**Interfaces:**
- Consumes: `DXR_SD_Migr_Phase1_FieldDup.Execute()` and `DXR_SD_Migr_Phase2_LegacyTable.Execute()` — exact signatures confirmed in Step 1 below (Discovery only confirmed the procedure exists and the codeunit name/file, not the full parameter list — verify before writing the adapter body).
- Produces: two new codeunit IDs (MCC's own ID range 60000-60100 per `app.json:idRanges` — pick the next two free IDs after the highest currently used, e.g. continue from 60016/60017 if 60015 is the current max) that `DXRMCCRegistryLoader.Codeunit.al` will reference as the new `Dispatcher Codeunit ID` for SD-P1/SD-P2.

- [ ] **Step 1: Read both real SD codeunits in full to confirm `Execute()`'s exact signature (parameters, if any) and access modifier (must be `procedure`, not `local procedure`, for MCC to call it cross-extension)**

- [ ] **Step 2: Write the adapter for Phase 1**

```al
codeunit 60016 "DXR MCC Adapt SD Phase1"
{
    // SD's own DXR_SD_Migr_Phase1_FieldDup.Codeunit.al only exposes `procedure Execute()` -
    // no `trigger OnRun`. MCC's Executor.RunDispatcher always calls Codeunit.Run(ID), which
    // invokes OnRun only - on a codeunit with no OnRun declared, the platform runs an empty
    // implicit trigger and returns success, silently migrating nothing. CONFIRMED 2026-08-23:
    // this is why SD-P1 (8 concepts) never moved a single row via MCC. This adapter's only
    // job is to give MCC a real OnRun that calls the real, already-correct Execute().
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_SD_Migr_Phase1_FieldDup";
    begin
        Phase1.Execute();
    end;
}
```

- [ ] **Step 3: Write the adapter for Phase 2** (same shape, targeting `DXR_SD_Migr_Phase2_LegacyTable.Execute()`)

```al
codeunit 60017 "DXR MCC Adapt SD Phase2"
{
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_SD_Migr_Phase2_LegacyTable";
    begin
        Phase2.Execute();
    end;
}
```

- [ ] **Step 4: Repoint the registry** — in `DXRMCCRegistryLoader.Codeunit.al`, change every `InsConcept('SD', 'SD-P1', ...)` row's `DispatcherCodeunitId` argument from `54780` to `60016`, and the `InsConcept('SD', 'SD-P2', 2, ...)` row's from `54781` to `60017`

- [ ] **Step 5: Add both new codeunits to `DXRMCCPermissionSet.PermissionSet.al`**

```al
codeunit "DXR MCC Adapt SD Phase1" = X,
codeunit "DXR MCC Adapt SD Phase2" = X,
```

- [ ] **Step 6: Compile and confirm the SD-P1/P2 rows actually move data on a test run** — compile per Task 1.5's command, then run "Reload Registry" + "Run Extension" for SD in a test company, and confirm via the `DXR MCC Run Log` that `Old Record Count`/`Migrated Record Count` are non-zero where the legacy tables have real rows (this is the concrete regression test for the bug this task fixes — there is no automated test harness in this repo, per Discovery, so this manual verification is the acceptance check)

- [ ] **Step 7: Commit**

```bash
git add src/Adapters/SD/ src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -m "fix: SD-P1/P2 never migrated data (target codeunits had no OnRun) - add native adapters"
```

---

## Task 1.2: DXP adapters — Phase 1, 2, 4 (Phase 3 blocked, see below)

**Files:**
- Read: `DXPAYMENT-BC\Base\CodeUnits\DXR_DXP_Migr_Phase1_Tables.Codeunit.al` (confirm `procedure Run(...): Boolean` signature at line 33)
- Read: `DXPAYMENT-BC\Base\CodeUnits\DXR_DXP_Migr_Phase3_Tables.Codeunit.al` (same shape, line 34 — written but NOT wired to the registry this task, see Step 4)
- Read: whichever DXP codeunits implement Phase2/Phase4 (Discovery confirmed the pattern but only read Phase1/Phase3 in full — read Phase2/Phase4's exact signature before writing their adapters)
- Create: `src\Adapters\DXP\DXRMCCAdaptDXPPhase1.Codeunit.al`
- Create: `src\Adapters\DXP\DXRMCCAdaptDXPPhase2.Codeunit.al`
- Create: `src\Adapters\DXP\DXRMCCAdaptDXPPhase4.Codeunit.al`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — DXP-P1, DXP-P2, DXP-P4 rows only (NOT DXP-P3, see Step 4)

**Interfaces:**
- Consumes: `DXR_DXP_Migr_Phase1_Tables.Run(): Boolean`, and the equivalent for Phase2/Phase4 (confirm exact signature per extension before writing).
- Produces: 3 new codeunit IDs (continue MCC's own range after Task 1.1's 60016/60017, e.g. 60018-60020).

- [ ] **Step 1: Read Phase2/Phase4's real codeunits in full to confirm their exact public procedure signature** (Discovery confirmed Phase1/Phase3 read `procedure Run(...): Boolean` with no `OnRun` - Phase2/Phase4 were not read in full, do not assume the same signature without checking)

- [ ] **Step 2: Write the 3 adapters**, same shape as Task 1.1's, e.g.:

```al
codeunit 60018 "DXR MCC Adapt DXP Phase1"
{
    // DXR_DXP_Migr_Phase1_Tables.Codeunit.al only exposes `procedure Run(...): Boolean`, no
    // OnRun - confirmed 2026-08-23 as the reason DXP-P1 (9 concepts) never moved data via MCC,
    // same bug class as SD (Task 1.1).
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_DXP_Migr_Phase1_Tables";
    begin
        Phase1.Run(); // confirm actual parameter list against the real signature read in Step 1 before finalizing this call
    end;
}
```

- [ ] **Step 3: Repoint the registry** for `InsConcept('DXP', 'DXP-P1', ...)`, `'DXP-P2'`, `'DXP-P4'` rows only, from their current IDs (`52310`, `52311`, `52321`) to the new adapter IDs

- [ ] **Step 4: Do NOT create or wire a DXP-P3 adapter in this task — BLOCKING QUESTION for the user first.** Discovery confirmed DXP-P3 and DXP-P5 both restore the same target tables (52275-52283) from two different legacy generations with no enforced precedence (Phase3 checks Phase1's completion tag before running; Phase5 does not check anything and can silently overwrite-by-skip whichever ran first). Wiring DXP-P3 with the same "give it an OnRun" fix as the others would just make this latent precedence bug start actually firing on real data instead of silently never running. Ask the user: which legacy generation (Phase1/Phase3's `54748→52275` source, or Phase5's `54700→52275` source) is the actual source of truth for these fields, before this concept gets an adapter at all.

- [ ] **Step 5: Add the 3 new codeunits to `DXRMCCPermissionSet.PermissionSet.al`**

- [ ] **Step 6: Compile and verify DXP-P1/P2/P4 move real data**, same manual acceptance check as Task 1.1 Step 6

- [ ] **Step 7: Commit**

```bash
git add src/Adapters/DXP/ src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -m "fix: DXP-P1/P2/P4 never migrated data (target codeunits had no OnRun) - add native adapters; DXP-P3 intentionally left unwired pending source-of-truth decision"
```

---

## Task 1.3: Add DPP's 54283 to Executor's Subtype=Upgrade skip-list

**Files:**
- Modify: `src\DXRMCCExecutor.Codeunit.al:698-723` (`IsKnownUpgradeCodeunit`)

**Interfaces:**
- Consumes: nothing new.
- Produces: nothing new — this is a pure safety-list addition, no other task depends on it.

- [ ] **Step 1: Confirm 54283 is genuinely `Subtype = Upgrade`** by reading `DescuentoProntoPago-OLD\Base\Codeunit\UpgradeManager.Codeunit.al:7` directly (Discovery already confirmed this — this step is a final check before touching a safety list, not a re-investigation)

- [ ] **Step 2: Add it to the list**

```al
    local procedure IsKnownUpgradeCodeunit(CodeunitId: Integer): Boolean
    begin
        exit(CodeunitId in [
            52248, 36003045,  // DXR_Field ID Alignment Upg. (DRLOC)
            ...
            53648, 52119593,  // DXR_Prontopago Migr Upgrade (a separate DPP workspace, not DescuentoProntoPago-OLD)
            54283              // DPP Upgrade Manager (DescuentoProntoPago-OLD) - CONFIRMED 2026-08-23, was
                                // missing from this list despite DPP-UPG (registry seq3) pointing MCC's
                                // RunDispatcher straight at it; same live-crash class as the SD 54779
                                // incident this list already exists to prevent.
        ]);
    end;
```

- [ ] **Step 3: Compile** (see Task 1.5's command)

- [ ] **Step 4: Commit**

```bash
git add src/DXRMCCExecutor.Codeunit.al
git commit -m "fix: add DPP's Subtype=Upgrade codeunit 54283 to the skip-list (was missing, live-crash risk)"
```

---

## Task 1.4: Full Phase 1 compile + regression check

**Files:**
- None new — this task validates Tasks 1.0-1.3 together.

- [ ] **Step 1: Compile the whole extension** (same command already proven to work this session):

```bash
"/c/Users/rpena/.vscode/extensions/ms-dynamics-smb.al-17.0.2273547/bin/win32/alc.exe" \
  /project:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center" \
  /packagecachepath:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\.alpackages" \
  /out:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\<version>.app"
```

Expected: clean compile (0 errors), same lone pre-existing `AL0482` warning on `DXRMCCMain.Page.al:170` as before this plan.

- [ ] **Step 2: Publish to a test environment, run "Reload Registry"** (picks up the repointed Dispatcher Codeunit IDs), then **"Run Extension" for SD and for DXP**

- [ ] **Step 3: Confirm via `DXR MCC Run Log`** that SD-P1/P2 and DXP-P1/P2/P4 now show non-zero `Migrated Record Count` where their legacy tables have real rows (DXP-P3 stays unwired/unchanged per Task 1.2 Step 4)

---

## Task 2.1 (in DRLOC, not MCC): expose per-step public procedures on codeunit 52210

**Files:**
- Read: `DR-Localization\Localization\src\Base\Codeunits\Uprade\DXR_Migr_Phase_2_Fiscal.Codeunit.al` in full — Discovery confirmed a `StartStep`/`RunStep` framework around lines 152-172 driving all 18 steps from inside one `OnRun`, but did not confirm whether each step is already reachable as its own public procedure
- Modify: same file — only if Step 1 finds the steps are NOT already individually public

**Interfaces:**
- Produces: one public procedure per DRLOC-P2 concept (at minimum: `RunBootstrap_CompanyInformation()`, `RunBootstrap_PaymentMethodRelation()`, `RunBootstrap_RncDatabase()`, and the other 15) that Phase 2's adapters (Task 2.2+) call directly — exact names TBD by Step 1's read, do not invent names before confirming.

- [ ] **Step 1: Read the full file.** If each of the 18 steps already has its own callable public procedure (likely, since `52210` itself calls into `52189`'s public procedures per-step already per Discovery), skip Step 2 entirely — this task is a no-op, just document the confirmed procedure names for Task 2.2 to consume.

- [ ] **Step 2 (only if needed): wrap each currently-internal step in a thin public procedure** that calls the same internal logic already used by `StartStep`/`RunStep`, without changing that internal logic's behavior — this is a visibility change only, not a rewrite:

```al
    // Exposed 2026-08-23 for DXR MCC's per-concept adapters (see MCC's docs/superpowers/plans/
    // 2026-08-23-mcc-native-migration.md) - same internal logic as the OnRun-driven step loop,
    // just independently callable so MCC can commit/log after EACH step instead of only after
    // all 18 finish in one blocking call.
    procedure RunBootstrap_CompanyInformation()
    begin
        MigrateFields_CompanyInformation_Bulk();
        MigrateFields_CompanyInformation_SpecialConversions();
    end;
```

(repeat per step — exact internal procedure names to call come from Step 1's read, not from this plan's assumptions)

- [ ] **Step 3: Compile DRLOC standalone** to confirm the visibility change alone doesn't break anything (no behavior change expected)

- [ ] **Step 4: Commit** (in DRLOC's own repo/branch, not MCC's)

```bash
git add "src/Base/Codeunits/Uprade/DXR_Migr_Phase_2_Fiscal.Codeunit.al"
git commit -m "refactor: expose per-step public procedures on Phase 2 dispatcher for MCC's native adapters"
```

---

## Task 2.2: DRLOC-P2 adapters — Company Information (worked example, full detail)

**Files:**
- Modify: `DXR-Migration-Control-Center\app.json` — add DRLOC as a dependency (id `b269ef93-1340-452e-bc44-732c5dacd1c8`, exact publisher/name/version read from DRLOC's own `app.json`, same pattern as Task 1.0)
- Create: `src\Adapters\DRLOC\DXRMCCAdaptDRLOCCompanyInfo.Codeunit.al`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — DRLOC-P2 seq9 (`'Bootstrap: CompanyInformation fields'`)
- Modify: `src\DXRMCCPermissionSet.PermissionSet.al`

**Interfaces:**
- Consumes: `"DXR_Migr_Phase_2_Fiscal".RunBootstrap_CompanyInformation()` (name confirmed by Task 2.1).
- Produces: codeunit ID 60021 (continuing the range) as DRLOC-P2 seq9's new `Dispatcher Codeunit ID`.

- [ ] **Step 1: Write the adapter**

```al
codeunit 60021 "DXR MCC Adapt DRLOC CompInfo"
{
    // Company Information is a singleton (Get() with no key) - this step is instant. The
    // "stuck on Company Information" appearance the user reported is NOT this step being slow;
    // it's that DRLOC-P2's dispatcher (52210) bundles 18 concepts, including a large RNC
    // database backfill, into ONE blocking Codeunit.Run() call, and MCC's progress label never
    // moves past whichever concept happened to be first while that whole call is in flight.
    // Giving Company Information its OWN adapter (this codeunit) is what lets MCC commit/log
    // it independently of however long the OTHER 17 steps take - see docs/superpowers/plans/
    // 2026-08-23-mcc-native-migration.md Phase 2 for the rest of the 18-step breakout.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr_Phase_2_Fiscal";
    begin
        Phase2.RunBootstrap_CompanyInformation();
    end;
}
```

- [ ] **Step 2: Repoint the registry** — in `DXRMCCRegistryLoader.Codeunit.al`, change the `InsConcept('DRLOC', 'DRLOC-P2', 9, 'Bootstrap: CompanyInformation fields', 52210, 0, 0, 'SETUP')` row's `DispatcherCodeunitId` from `52210` to `60021`

- [ ] **Step 3: Add to `DXRMCCPermissionSet.PermissionSet.al`**: `codeunit "DXR MCC Adapt DRLOC CompInfo" = X,`

- [ ] **Step 4: Compile** (Task 1.5's command)

- [ ] **Step 5: Publish to a test environment, Reload Registry, Run Concept for just "Bootstrap: CompanyInformation fields"**, confirm in `DXR MCC Run Log` it completes independently in well under a second, with its own log row, regardless of whether the other 17 DRLOC-P2 concepts have run yet

- [ ] **Step 6: Commit**

```bash
git add app.json src/Adapters/DRLOC/DXRMCCAdaptDRLOCCompanyInfo.Codeunit.al src/DXRMCCRegistryLoader.Codeunit.al src/DXRMCCPermissionSet.PermissionSet.al
git commit -m "feat: native per-concept adapter for DRLOC Company Information - first slice of DRLOC-P2 breakout"
```

---

## Task 2.3: DRLOC-P2 adapters — Payment Method Relation (worked example, table-pair pattern)

**Files:**
- Create: `src\Adapters\DRLOC\DXRMCCAdaptDRLOCPaymentMethodRel.Codeunit.al`
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — DRLOC-P2 seq13
- Modify: `src\DXRMCCPermissionSet.PermissionSet.al`

**Interfaces:**
- Consumes: DRLOC's confirmed `TransferFields`-based restore pattern for `"DXPayment Method Relation"` (54133) → `"DXR_Payment Method Relation"` (52180) — Discovery confirmed this exact pattern (and the same shape for NAV POS Customer, Extract Cards, Gubernamentales(623)).
- Produces: codeunit ID 60022.

- [ ] **Step 1: Confirm the exact real table names** via `AllObjWithCaption` or the DRLOC source directly (Discovery gave IDs and the `TransferFields` pattern but the plan must use the literal AL object names, not paraphrases)

- [ ] **Step 2: Write the adapter** — this is the reference pattern every other "TRIVIAL" table-pair concept in the Roadmap follows:

```al
codeunit 60022 "DXR MCC Adapt DRLOC PmtMethod"
{
    // Reference pattern for every TRIVIAL table-pair concept in the Roadmap (docs/superpowers/
    // plans/2026-08-23-mcc-native-migration.md) - typed Record on both sides (not RecordRef),
    // so this codeunit's own "X" grant in DXR MCC's permission set gives indirect read/write
    // on both tables without needing DRLOC's own permission set assigned to whoever runs this.
    trigger OnRun()
    var
        Legacy: Record "DXPayment Method Relation";
        New: Record "DXR_Payment Method Relation";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."<primary key field name - confirm from Step 1>") then begin
                    New.Init();
                    New.TransferFields(Legacy, true);
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;
}
```

(Primary key field name placeholder above is intentionally left for Step 1's confirmed real name — do not guess it; every other table-pair adapter in later phases follows this exact shape with its own two real table names and confirmed key field.)

- [ ] **Step 3: Repoint DRLOC-P2 seq13's `DispatcherCodeunitId`** from `52210` to `60022`

- [ ] **Step 4: Add to permission set, compile, test-run, commit** (same 4 sub-steps as Task 2.2 Steps 3-6)

---

## Roadmap (Phases 3+): remaining extensions, by discovery classification

Each remaining extension gets its own dependency addition + a batch of adapters following the exact pattern proven in Tasks 2.2/2.3. Per this session's planning scope, **detailed bite-sized tasks for each are written when that phase starts** (standard staged planning for a program this size — the inventory below is the real, evidence-backed input to that write-up, not a placeholder). Order below is by leverage (highest-impact/most-broken first) and by dependency tier (`Order No.` in the registry — Setup-tier extensions before their dependents).

| Order | Ext | Real folder | Concepts | TRIVIAL (thin adapter only) | COMPLEX (needs real porting work) | SKIP (Upgrade / no-op / code-fix-only) | Notes |
|---|---|---|---|---|---|---|---|
| 1 | DRLOC (cont'd) | `DR-Localization\Localization\src\Base\Codeunits\Uprade\` | ~105 | ~55-60 | ~8-10 (Item NCF Category batch, RNC Database batch, Company Info BLOBs, FlowField-only ones - not portable, informational) | 3 (DRLOC-NCF seq6/7 code-fix-only, DRLOC-P1 seq8 Subtype=Upgrade wrapper - already reached via 52210) | Tasks 2.2/2.3 done; remaining ~16 DRLOC-P2 steps + P3/P4/P5/P6 table-pairs follow the same 2 patterns |
| 2 | BC | `Base-Controls\Base Controls\src\services\migration\` | 19 | 19 | 0 | 0 | All 4 dispatchers already 100% typed `Record`; genuinely thinnest phase in the whole portfolio |
| 2 | RBPD | `Recaudo BC\RecaudoBPD\Base\Codeunits\` | 11 | 11 (Worker 56308 confirmed; Phase1/Phase2 internals assumed same pattern - **confirm before committing**) | 0 | 0 | Shares an `AssignPermissionSetToUser` pattern with BC - candidate for one shared MCC helper procedure instead of 2 copies |
| 3 | VP | `DxPayloads-BC\Vendor Payloads\src\Base\Codeunits\Migration\` | 46 → collapse to ~23 real ops | ~20 | ~3 (Phase7's table-level RecordRef merge logic - already correct/safe, port as-is not field-level) | 0 | Phase 1-6 (gen-1) and Phase 7 hit the same 23 targets from 2 source generations - one adapter per target table trying both sources in sequence, not 46 adapters |
| 4 | DXP (cont'd) | `DXPAYMENT-BC\Base\CodeUnits\` | 32 done (Task 1.2) + 14 (P5/P6) | TBD - P5/P6 `OnRun` presence not yet confirmed | 0 confirmed | DXP-P3 (9) blocked on business decision | Confirm P5/P6 `trigger OnRun` presence before assuming Task 1.2's pattern applies unchanged |
| 5 | PCM | `Price-Controls-Mgt\Price Controls Mgt\src\Base\Codeunits\` | 16 | ~10 | ~6 (Phase 5 Id Renum - port ONLY the final Workflow-shell logic, do not reintroduce the 6 already-removed redundant shells per the registry's own note) | 0 |  |
| 5 | TU | `DX-TransUnion\TransUnion\src\Base\Codeunits\` | 5 | 5 (3 via dispatcher 53605 + 2 already MCC-Fallback-covered, Dispatcher=0) | 0 | 0 | Smallest, cleanest extension in the portfolio per Discovery |
| 6 | DESB | `Despacho-Base\Despacho Base\src\Base\Codeunits\Upgrade\` | 71 | 67 (Worker 53681's 39 + Phase1's 28) | 4 (Phase 2's `_Old2`/`_Reloc` collision-relocation logic) | 1 (53669 dispatcher, Subtype=Upgrade - Worker 53681 is the real normal-codeunit entry point already) | ⚠ do not use `apps\1-DespachoBase\src\Core\...` - confirmed stale duplicate folder, use `Despacho-Base\Despacho Base\` only |
| 6 | DESLS | `Despacho-Base\Despacho LS\src\Base\Codeunits\Upgrade\` | ~14 | ~4 | 10 (cross-extension `CopyMatchingRecord` reads from DESB's own legacy tables - port carefully, needs DESB dependency too) | 0 |  |
| 7 | RC | `Retail-Controls\src\services\upgrade\` | ~8 phases | Phase1/2/4/5 (moderate) | Phase3 (ID-collision guard logic, 5 tables incl. LSC POS Func. Profile) | Phase Upgrade Mgt (54742/54743, already in skip-list) | Every file declares Cloud+OnPrem codeunit ID pairs - adapters target the Cloud IDs only unless MCC ever needs an OnPrem build |
| 8 | FE | `Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\` | ~40 | ~32 | 3 confirmed (EF Archived Sent Request's scoring-merge, EF Codigos Item/EF Currency Type's key-based merge, EF ATEB Send Registry's enum re-mapping) + ~16 not yet read (P8/9/10/13) | 0 | P7's field-number bug (this session's own earlier finding, 55501-504→52333/52334) already confirmed fixed in current source - port the fixed version, don't reintroduce the bug |
| 9 | LSFE | `Facturacion Workspace\BC-Facturacion-Electronica\LS Facturacion Electronica\Base\Codeunit\` | 2 | 2 (both already have correct explicit `Permissions`) | 0 | 0 | Cleanest port in the whole portfolio - already does everything right, adapter is pure formality |
| 10 | BELLON | `Bellon_Customization\Bellon Customization\src\Base\Codeunits\` | ~257 | ~256 (P2's 141 + P6's 114 + P7's 1 summarizing 55 tables) | 0 confirmed yet | P10 (56127, confirmed deliberate no-op - do not adapt) + P3/4/5/8/9/11/12 (~7 rows, bodies not yet read - confirm before assuming TRIVIAL) | Largest single extension by concept count; P7's "55 tables in one summary row" should be split into per-table adapters/concepts as part of this phase, not kept as one bundled call (same DRLOC-P2 problem, smaller blast radius since P7 is already the never-overwrite pattern) |
| 11 | BELLONPOS | `Bellon_Customization\Bellon POS\Base\Codeunits\` | 12 | 12 | 0 | 0 | **Source-extension bug, fix at BELLONPOS not via MCC workaround**: `DXR_POS Upgrade Process` has no `Permissions` property for the tables it touches at all - even after MCC gets a typed adapter, BELLONPOS should still declare its own `Permissions` correctly, since other BELLONPOS code paths (its own upgrade cycle) hit the same gap independent of MCC |

**BLOCKING QUESTIONS before their respective phases can complete (ask the user, do not guess):**
1. DXP-P3 vs DXP-P5 (Task 1.2 Step 4): which legacy generation is the real source of truth for tables 52275-52283?
2. Confirm before Phase 10 (BELLON): read the 7 un-read Phase bodies (P3/4/5/8/9/11/12) before assuming they're safe to bulk-classify as TRIVIAL.

---

## Task 1.5 (reference): compile command used throughout this plan

```bash
"/c/Users/rpena/.vscode/extensions/ms-dynamics-smb.al-17.0.2273547/bin/win32/alc.exe" \
  /project:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center" \
  /packagecachepath:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\.alpackages" \
  /out:"<scratch path>\mcc_test.app"
```

Confirmed working against the current `.alpackages` cache this session (clean compile, one pre-existing unrelated warning). Every new dependency added by this plan requires that extension's `.app` symbol package to be added to `.alpackages` first (via "Download Symbols" in the AL extension, or manually copying the `.app` file), or this command will fail with an unresolved-reference error, not the "project without a manifest" error seen when `/out` is a POSIX-style path — always use Windows-style paths with this specific `alc.exe`, confirmed earlier this session.
