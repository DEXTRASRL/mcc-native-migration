# MCC Full-Portfolio Native Migration — Design Spec

**Status:** Approved by user 2026-08-24 (design discussed and confirmed in-conversation; AskUserQuestion decisions recorded below). Supersedes/extends `docs/superpowers/plans/2026-08-23-mcc-native-migration.md` (kept as evidence/reference — its Discovery Summary and per-extension findings are still authoritative, only its *delivery order* changes).

## Goal

Make "DXR Migration Control Center" (MCC) the single, typed, centralized execution point for every legacy→`DXR_` data migration across the full Dextra BC portfolio (`C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\*`), with two hard requirements from the user:

1. **Zero `RecordRef`/`FieldRef` in the primary migration path.** Every adapter — new or already written — migrates data through typed `Record` variables with explicit, named field assignments (`New."Field_DXR" := Old."Field";`), never a generic reflection loop. This is what "no tener margen de error" means concretely: a compile-time-checked field pairing, not a runtime-discovered one.
2. **Execution organized into 3 generic, portfolio-wide phases**, run in this order: **Setup → Master/Accounting → Historic**, with the DGII/RNC Database migration (the largest, highest-risk single concept in the portfolio) as the deliberate last step of Historic.

## Decisions already locked in (do not re-litigate)

- **Fallback engine (`DXR MCC Fallback Migrator`) stays exactly as-is** — untouched, `RecordRef`-based, automatic last-resort safety net only (fires when a typed adapter errors or leaves a count gap). It is not a primary-path shortcut and is explicitly exempt from the "zero RecordRef" rule.
- **Physical folder layout stays per-extension** (`src/Adapters/<EXT>/...`). The "3 phases" are an *execution/scheduling* concept (the `Category` field + `Run All Setup/Master-Accounting/Historic` buttons that already exist in `DXRMCCConcept.Table.al` and `DXRMCCMain.Page.al`), not a folder reorganization. Do not move existing adapter files between folders.
- **Delivery order is category-first, across the whole portfolio, not extension-first.** Phase A finishes when every Setup-category concept in every extension has a typed adapter — not when one extension is 100% done. This deliberately reframes (does not discard) the per-extension Roadmap already researched in the 2026-08-23 plan: that Roadmap's per-extension findings are the *evidence backlog* this plan consumes; its *ordering* is superseded by the category-first plan below.
- **`DXR_Legacy_Field_Mapping.md` is NOT the source of truth.** It is a decayed, curated summary (confirmed: explicitly says "full 427-field detail available on request" with no such detail actually present in the file). The real source of truth for every legacy↔`_DXR` field pair is **the AL source of the extension itself** under `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\<extension>\`, specifically the `ObsoleteReason` string on the legacy field and the matching field declared in the `_DXR`-suffixed tableextension/table. Every field pair used in a written adapter must cite the file:line it was confirmed from.

## Scope confirmed via direct inspection (2026-08-23/24)

- **17 extensions currently registered in MCC**: BC, BELLON, BELLONPOS, DESB, DESLS, DPP, DRLOC, DXP, FE, LSFE, LSLOC, PCM, RBPD, RC, SD, TU, VP — 705 `DXR MCC Concept` rows total (`DXRMCCRegistryLoader.Codeunit.al`, `grep -c InsConcept` = 705).
- **Extensions with real DXR_ migration surface (per `DXR_Legacy_Field_Mapping.md`'s own 21-extension index) that are NOT registered in MCC at all**, found by cross-referencing that index against the 17 codes above:
  - Email-Sender (`EmailSender\`)
  - Retail-Email-Sender (folder TBD — confirm under `Retail Controls\` or its own root during Phase 0)
  - DX Bank Reconciliation (`BC-Bank-Consolidation\`)
  - VendorPay_API (folder TBD — likely under `vendorpayload\` alongside VP, confirm during Phase 0)
  - VendorPay_TXT (folder TBD — same as above)
  - These become **Phase 0** work: confirmed registration, not assumed.
- **Already-"native" extensions that still violate the zero-RecordRef rule** (confirmed by direct grep of `: *RecordRef` / `: *FieldRef` in their adapter files, despite being described as "converted to native local migration" in recent commits): **BELLON, BELLONPOS, LSFE, LSLOC**. Their table-extension field-group copy procedures (e.g. `MigrateTableExt_CustomerFields`, `MigrateTableExt_ItemFields`, ~87 such procedures in BELLON alone covering ~427 fields) use a generic `RecRef.Open(Database::"X")` + `FieldIndex` reflection loop. These are in-scope for remediation, not exempt just because they were already touched.
- `DXR MCC Concept.Category` (Setup/Master-Accounting/Historic/Other) already exists as a field, already drives `Run All Setup/Master-Accounting/Historic` on `DXRMCCMain.Page.al` via `Executor.ScheduleCategory(...)`. This plan does not build that mechanism — it completes and corrects the data behind it.
- DGII-RNC Database is `DRLOC-P2` seq 15 (`InsConcept('DRLOC', 'DRLOC-P2', 15, 'DGII-RNC Database legacy table restore (54119 -> 52156)', 60069, 54119, 52156, 'MA')` — currently tagged `'MA'`. **Must be recategorized to `Historic` and explicitly ordered last within it**, per user instruction.

## Target architecture (unchanged core, corrected data + logic)

```
DXR MCC Concept (705+ rows, Category corrected)
   -> Dispatcher Codeunit ID -> Codeunit.Run()
        -> native MCC adapter codeunit, src/Adapters/<EXT>/...
              trigger OnRun()
              var
                  Legacy: Record "<LegacyTable>";   // typed, never RecordRef
                  New:    Record "<NewTable>";       // or same Record for tableextension groups
              begin
                  if Legacy.FindSet() then
                      repeat
                          New."Field1_DXR" := Legacy."LegacyField1";
                          New."Field2_DXR" := Legacy."LegacyField2";
                          ...
                          New.Modify();  // or New.Insert(false) / TransferFields for whole-row clones
                      until Legacy.Next() = 0;
              end;
```

Two adapter shapes, both zero-RecordRef:
1. **Whole-table clone** (legacy table → new `DXR_` table, identical layout): typed `Record` on both sides, `TransferFields(Legacy, true)` where the layout is truly 1:1 (already the pattern used in the existing plan's Task 2.3), or explicit per-field assignment where any field was renamed.
2. **Tableextension field-group copy** (fields added to a base table like Customer/Item/Sales Header): **one typed `Record` variable on the base table itself** (extension fields live on it), explicit `"Field_DXR" := "LegacyField"` per field, replacing the current `RecRef.Open(Database::"Customer")` reflection loop entirely.

## Delivery order (4 phases, category-first, portfolio-wide)

- **Phase 0 — Portfolio completeness audit.** Confirm and register the 5 unregistered extensions found above (or fewer/more, this is a verification step, not an assumption) into `DXRMCCExtension.Table` seed + `DXRMCCConcept` rows, following the exact same evidence discipline as the existing plan's Discovery pass (real `app.json` id/publisher/name/version, real dispatcher codeunit IDs, real Category classification). No adapters written yet in this phase — just accurate registration so nothing is invisible to Phase A-D.
- **Phase A — Setup**, all extensions (18 total after Phase 0). Every concept tagged `Category = Setup` gets a typed, direct-field, native MCC adapter. Smallest, lowest-risk phase (config/setup tables, low row volume) — proves the pattern end-to-end before scaling.
- **Phase B — Master/Accounting**, all extensions. Includes the RecordRef remediation of BELLON/BELLONPOS/LSFE/LSLOC's table-extension field groups (Customer/Item/Vendor/etc. are Master-Accounting by nature).
- **Phase C — Historic**, all extensions **except** DGII-RNC Database.
- **Phase D — DGII-RNC Database** (`DRLOC-P2` seq 15), alone, last. Highest volume/risk item in the portfolio (per existing Discovery: this is the same table implicated in the "se traba en Company Information, no sigue iterando" bug — must be broken out of DRLOC's bundled 18-step dispatcher into its own adapter as part of this phase, consistent with the existing plan's DRLOC-P2 breakout work).

Each phase gets its own detailed, checkbox-based task list at the same fidelity as the existing 2026-08-23 plan's Task 1.x/2.x sections when that phase's implementation plan is written (`writing-plans`) — this spec fixes the *architecture and order*, not every one of the ~700 remaining concepts' exact field lists (those are confirmed per-concept by research agents at write time, cited with file:line evidence, per the pipeline below).

## Agent/skill pipeline (subagent-driven-development)

| Stage | Agent | Governing skill |
|---|---|---|
| Per-phase orchestration | `dxr-migration-orchestrator` | `dxr-phased-data-migration` |
| Confirm real extension identity (id/publisher/name/version) before adding as dependency | `dxr-extension-registry` | — |
| Field-pair evidence mining (source `ObsoleteReason`, not the `.md`) — parallel, per extension/table | `dxr-repository-intelligence` + `dxr-technical-researcher` | `dxr-source-provenance` |
| `_DXR` naming confirmation / collision check before writing an adapter | `dxr-naming-normalization` | — |
| New codeunit ID allocation (60000-60100 range), collision-safe across parallel agents | — | `dxr-id-allocation-registry` |
| Producer/consumer contract between MCC and each source extension | — | `dxr-cross-extension-reference-map` |
| Symbol refresh after a new `app.json` dependency | — | `dxr-symbol-management` |
| Write the typed adapter codeunit | `al-developer` / `CoderAgent` (atomic subtask) | `dxr-legacy-object-migration` |
| Retroactive repair if the concept already ran with an Upgrade Tag in production (BELLON/BELLONPOS/LSFE/LSLOC) | `dxr-retroactive-migration-repair` | — |
| Format/lint before compile | `al-format-lint` | `al-appsource-format` |
| Incremental compile order + error classification | `dxr-compilation-validation` | — |
| Field-ID collision between sibling tables (edge case only) | `dxr-cross-table-field-id-collision` | — |
| Code review before commit | `CodeReviewer` / `review` | — |
| Commit | `git-committer` | — |

**Shared-file contention rule:** `DXRMCCRegistryLoader.Codeunit.al`, `DXRMCCPermissionSet.PermissionSet.al`, and `app.json` are touched by every concept in a batch. Research + adapter-writing fan out fully in parallel (each new `.al` file has zero collision risk); a single serialized "wire-up" step per batch applies all registry repoints + permission grants + dependency additions together, governed by `dxr-multiagent-migration-contract`'s lock model. Never let two parallel agents edit these 3 files concurrently.

## Verification (no automated test harness exists in this repo, confirmed by prior discovery)

Two-part gate per concept, matching the existing plan's own standard:
1. Evidence gate: the field pair(s) used were confirmed from real source (`ObsoleteReason` line cited), not guessed and not taken from the `.md` alone.
2. Runtime gate: clean compile + `DXR MCC Run Log` shows non-zero `Migrated Record Count` where the legacy table has real rows, for that specific concept, independent of any other concept's run state.

## Explicit non-goals

- Not rewriting `DXR MCC Fallback Migrator`.
- Not moving existing adapter files into category-named folders.
- Not touching a source extension's own dispatcher/phase codeunits unless a task explicitly requires it (same constraint as the existing 2026-08-23 plan).
- Not inventing field pairs — every pair traces to a source citation.
