# MCC Native Migration Adapters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give "DXR Migration Control Center" (MCC) a compile-time (typed) path into every legacy→DXR_ migration across the Dextra BC portfolio, so it stops depending on the executing user/task already holding each target extension's own permission set, stops silently no-op'ing on dispatcher codeunits that lack a real `OnRun`, and can run/commit/log at real per-table granularity instead of one giant blocking call per phase.

**Architecture:** MCC keeps its existing registry (`DXR MCC Concept` → `Dispatcher Codeunit ID` → `Codeunit.Run()`) completely unchanged. What changes is *what* `Dispatcher Codeunit ID` points at: instead of pointing at an extension's own phase/dispatcher codeunit (opaque ID, no compile-time reference, sometimes missing `OnRun` entirely, sometimes bundling many tables into one call), it points at a small **native MCC "adapter" codeunit** that has a real `trigger OnRun`, lives inside MCC, and calls the target extension's *real, already-correct* migration procedure directly and typed (`Codeunit "<Real Name>"`, not a raw ID). This requires MCC to declare each target extension as an `app.json` dependency (plus `internalsVisibleTo` from that extension, when its migration codeunit is `Access = Internal`). **We do NOT re-implement the field-by-field migration logic that's already correct** — we only give MCC a proper, typed way to *call* it. We only write new logic where discovery found the original is missing, broken, or unreachable (see per-extension findings).

**REALIZED GRANULARITY (2026-08-23, important divergence from the original goal below):** the paragraph above and Task 2.2/2.3's worked examples originally aimed for "one adapter = one `DXR MCC Concept` row" — splitting each extension's bundled phase dispatcher into one adapter per table/step, so MCC could commit/log at real per-table granularity (this was DRLOC's specific "stuck on Company Information, nothing in the logs" motivation). **That fine-grained goal was NOT pursued for the Roadmap extensions actually completed (BC through BELLONPOS, see the Roadmap Execution Log below).** Two consecutive user redirects narrowed the goal instead to: apply the dependency + typed-reference pattern gradually to every extension, one adapter per EXISTING phase/dispatcher codeunit (matching that extension's own current bundling boundary, not per-concept), purely for compile-time safety (a rename/removal in the sibling extension now breaks MCC's own build instead of silently no-op'ing or erroring only at runtime — confirmed against Microsoft's "Permissions Property" and "Using Access Modifiers in AL" docs that `Access = Internal`/dependencies/`internalsVisibleTo` are compile-time-only constructs with zero runtime permission effect). The one exception is VP, where the existing registry granularity was already per-phase-procedure (not per-dispatcher), so VP's 7 adapters match that existing finer boundary — see the Execution Log. The per-concept splitting goal (DRLOC-P2's 18-step breakout, Tasks 2.1-2.3) remains valid and unstarted; it is a separate, deferred piece of work, not superseded by the pattern applied elsewhere.

**Explicit exclusion (per user instruction):** any codeunit confirmed `Subtype = Upgrade` is never made an adapter target for `Codeunit.Run()` — the platform hard-blocks that outside its own publish/schema-sync cycle and there is no code-level workaround. Where an Upgrade-subtype codeunit's real logic is already exposed to a **normal, sibling codeunit** via public procedure calls (confirmed pattern: DRLOC's 52210 calls into 52189's public procedures directly, Bellon's Phase-2/6/7 wrappers call into `BellonUpgradeProcess`'s public procedures directly), MCC adapts to *that sibling*, never to the Upgrade codeunit itself. Where no such sibling exists, the concept stays `Blocked` with a reason, exactly as already documented in the registry.

**Tech Stack:** AL (Business Central 28.x, runtime 17.0), no new external dependencies. New: `app.json` dependencies on the target extensions being adapted in each phase.

**Spec:** This document is self-derived from a 5-agent discovery pass across the whole portfolio (2026-08-23) plus direct source reads of `DXRMCCExecutor.Codeunit.al`, `DXRMCCRegistryLoader.Codeunit.al`, `DXRMCCCounter.Codeunit.al`, `DXRMCCFallbackMigrator.Codeunit.al` earlier the same session. No separate spec file exists; findings are cited inline per task with file:line evidence.

## Global Constraints

- Never call `Codeunit.Run()` on a codeunit confirmed `Subtype = Upgrade`. Confirmed IDs (do not add these as adapter targets, ever): `52248, 36003045, 52189, 36003049, 51962, 36002776, 52255, 36003047, 53669, 59221, 53562, 52587, 36003121, 53600, 54856, 54662, 54599, 54742, 54743, 54534, 53923, 54445, 36003619, 52773, 52743, 52667, 52120396, 53648, 52119593, 54283` (54283 added this plan — see Task 1.3, was missing from `IsKnownUpgradeCodeunit`. **54779 REMOVED from this list 2026-08-23** — Task 1.1 confirmed SD's dispatcher no longer declares `Subtype = Upgrade` at the source, in SD's own separate repo, commit `edfdc91`; do not re-add it here or in `IsKnownUpgradeCodeunit` without re-verifying against that source first — final whole-branch review flagged this exact staleness as a real regression risk for future phases).
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
  app.json                                    Modify: 13 real dependencies added, one per wired extension
  src/
    Adapters/                                          codeunit ID range 60016-60073 (next free: 60074)
      SD/    DXRMCCAdaptSDDispatcher.Codeunit.al                1 adapter  - DONE
      DXP/   DXRMCCAdaptDXPDispatcher.Codeunit.al                1 adapter  - DONE
      BC/    DXRMCCAdaptBCPhase{1,2,3}, ...PermRepair            4 adapters - DONE
      RBPD/  DXRMCCAdaptRBPDWorker.Codeunit.al                   1 adapter  - DONE
      VP/    DXRMCCAdaptVPPhase{1-7}.Codeunit.al                 7 adapters - DONE
      PCM/   DXRMCCAdaptPCMPhase{2,3,4,5}.Codeunit.al            4 adapters - DONE
      TU/    DXRMCCAdaptTUDispatcher.Codeunit.al                 1 adapter  - DONE
      DESB/  DXRMCCAdaptDESBWorker, ...Phase2                    2 adapters - DONE
      DESLS/ DXRMCCAdaptDESLSWorker, ...Phase1                   2 adapters - DONE
      RC/    DXRMCCAdaptRCPhase{1,2,3,4,5}.Codeunit.al           5 adapters - DONE
      FE/    DXRMCCAdaptFEPhase{7,8,9,10,11,12,13}               7 adapters - DONE
      LSFE/  DXRMCCAdaptLSFEPermSet, ...POSContingency           2 adapters - DONE
      BELLON/    DXRMCCAdaptBellonPhase{2..12}                  11 adapters - DONE
      BELLONPOS/ DXRMCCAdaptBellonPOSPhase2.Codeunit.al           1 adapter  - DONE
      LSLOC/     DXRMCCAdaptLSLOCDispatcher.Codeunit.al           1 adapter  - DONE (found late, see Execution Log)
      DRLOC/     DXRMCCAdaptDRLOCPhase{2,3,4,5,6}.Codeunit.al      5 adapters - DONE (see Execution Log)
    # SD and DXP's Adapters/ history (2026-08-23, two reversals - read both before assuming either
    # state): Tasks 1.1/1.2 originally tried typed adapters, hit AL0161 (Access=Internal blocked a
    # typed reference), and fell back to a pure registry repoint with no adapter/dependency at all
    # (commits 27677c8..8fa133d) - reviewed and merge-ready in that form. The USER THEN EXPLICITLY
    # REDIRECTED back to typed adapters as the intended portfolio-wide pattern (commit e872fd8),
    # accepting the AL0161 fix cost (SD's own app.json now grants MCC internalsVisibleTo - a real,
    # necessary companion change in SD's separate repo, commit 750ccd9). DXP got a typed adapter too
    # for consistency, but did NOT need internalsVisibleTo (its Runner has no Access property, so
    # defaults to Public) - one was added by mistake and reverted (DXP repo commit e1bf849).
    # IMPORTANT CORRECTION (2026-08-23, from the redirect's own review): the typed-reference design
    # does NOT grant any runtime permission benefit over a raw Codeunit.Run(ID) call - dependencies
    # and internalsVisibleTo are compile-time-only constructs (confirmed against Microsoft's
    # "Permissions Property" doc). Its real, only benefit is compile-time safety - a rename/removal
    # in the sibling extension now breaks MCC's own build instead of silently no-op'ing at runtime.
    # This pattern was then applied to every extension below for THAT reason - see the correction
    # comments in the SD/DXP adapter codeunit files for the full citation, repeated in later
    # adapters' comments. A SECOND user redirect ("build completo") extended this from "SD/DXP only"
    # to "every extension MCC works on, as a deliberate portfolio-wide design pattern, not only
    # where strictly necessary" - see the Roadmap Execution Log below for what that produced.
    DXRMCCExecutor.Codeunit.al                  No change (dispatch mechanism already fits adapters)
    DXRMCCRegistryLoader.Codeunit.al            Modify: repoint "Dispatcher Codeunit ID" per concept, per phase
  docs/superpowers/plans/
    2026-08-23-mcc-native-migration.md          This file
```

Each adapter codeunit owns exactly one responsibility: call one real, existing procedure, typed, with a real `OnRun`. New adapters are added to a per-extension folder so the growing dependency list stays easy to audit against `app.json`. **Granularity note:** every adapter above wraps one existing phase/dispatcher codeunit (matching that extension's own current bundling boundary), not one `DXR MCC Concept` row — see the Architecture section's "REALIZED GRANULARITY" note above for why this differs from Tasks 2.1-2.3's original per-concept goal.

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

## Task 1.1: SD registry repoint (REDEFINED 2026-08-23 during execution — see below)

**Original design (typed MCC-side adapter codeunits) was ABANDONED mid-execution.** The implementer hit
`AL0161: inaccessible due to its protection level` — `DXR_SD_Migr_Phase1_FieldDup`/`Phase2_LegacyTable`
are `Access = Internal` with no `internalsVisibleTo` grant to MCC, so a typed `Codeunit "DXR_SD_Migr_..."`
reference cannot compile from MCC at all. Verified against Microsoft's own docs ("Using Access Modifiers
in AL"): `Access = Internal` is compile-time only — "the OnRun trigger can be run on internal codeunits
by using Codeunit.Run" at runtime, dynamic `Codeunit.Run(Integer)` is unaffected. This made the whole
adapter approach unnecessary for this specific bug: MCC's existing, unmodified `Codeunit.Run(DispatcherCodeunitId)`
already works fine against `Access = Internal` targets — the real problem was SD's dispatcher (54779)
still being `Subtype = Upgrade` (which DOES block `Codeunit.Run()`/TaskScheduler outside schema-sync,
confirmed by a documented live crash) while 54780/54781 individually had no `OnRun` at all.

**Fixed at the source instead** (SD's own repo, `C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Special dispatch\Special-Distpach\Pedidos Especiales`,
already its own git repo — separate from this plan/worktree, not tracked by this ledger). Also found and
landed 12 files of substantial pre-existing uncommitted work (self-dated 2026-08-20, never committed)
that had already converted Phase1/Phase2 from `DataTransfer`+`Subtype=Upgrade` to `Access=Internal`+manual
`RecordRef` copy, and redesigned the dispatcher to do nothing during `OnUpgradePerCompany` (empty) with
all real work moved to a new `OnRun`. 4 commits landed in SD's repo (local only, not pushed):
- `e523369` — lands the pre-existing 2026-08-20 work as-is
- `edfdc91` — removes `Subtype = Upgrade` + the now-illegal empty `OnUpgradePerCompany` trigger (AL0477)
- `2c35e47` — adds explicit `Permissions` to 54780/54781 (independent review found `DXR_DispatchControls`
  only grants `R` not `M` on 3 tables Phase1 writes to — neither codeunit had its own `Permissions` to
  compensate for losing `Subtype=Upgrade`'s implicit elevated execution context)
- `9218460` — adds `tabledata Field = R` to 54781 (re-review found `GetCommonCompatibleFieldNos` reads
  the system `Field` table, uncovered by any reachable permission set)

All 4 compile clean (`alc.exe` exit 0, zero new errors/warnings) and were independently reviewed
(2 review passes, both Critical findings addressed and re-verified).

**What's actually left for MCC (this task, in this worktree):**

**Files:**
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — SD-P1 (seq 1,3-9, 8 rows), SD-P2 (seq 2, 1 row), SD-P3 (seq 10, 1 row)
- Modify: `app.json` — remove the SD dependency added in Task 1.0 (no longer needed — no typed reference to SD from MCC anymore)

**Interfaces:**
- Consumes: nothing new — MCC's existing `Codeunit.Run(Integer)` dispatch mechanism, unchanged.
- Produces: nothing new — no new codeunit IDs, no adapter files, no permission set changes.

- [ ] **Step 1: Repoint all 10 SD concept rows to the dispatcher.** In `DXRMCCRegistryLoader.Codeunit.al`, change every `InsConcept('SD', 'SD-P1', ...)` row's `DispatcherCodeunitId` argument from `54780` to `54779`, the `InsConcept('SD', 'SD-P2', 2, ...)` row's from `54781` to `54779`, and the `InsConcept('SD', 'SD-P3', 10, ...)` row's from `0` to `54779` — the dispatcher (54779) now orchestrates all 3 phases itself (Phase3→Phase1→Phase2, in that order) inside its own `OnRun`, so every SD concept shares the same single dispatcher call, same pattern MCC already uses elsewhere (e.g. DRLOC-P2's 18 concepts sharing dispatcher 52210) — `IsDispatcherAlreadyDone`'s dedup-by-dispatcher-ID logic already handles one dispatcher ID covering many concepts correctly, no Executor change needed.

- [ ] **Step 2: Update SD-P3's stale description.** Its current text ("Subtype=Upgrade codeunit 54779 - cannot be invoked via Codeunit.Run() from MCC or anywhere outside schema-sync; runs automatically on next publish only") is now factually wrong — 54779 is no longer Subtype=Upgrade. Update the description to reflect that Phase 3 (permission set assignment) now runs as part of 54779's own `OnRun`, first, before Phase 1/2.

- [ ] **Step 3: Revert the SD half of Task 1.0's `app.json` dependency** — remove the `18373840-6093-4765-8799-491f61accb2b` (Special Dispatch) entry from `dependencies`. Leave the DXP entry in place (Task 1.2 hasn't been investigated yet — don't assume it has the same `Access = Internal` blocker until confirmed).

- [ ] **Step 4: Compile** (Task 1.5's command). Expect clean compile, same lone pre-existing warning.

- [ ] **Step 5: Commit**

```bash
git add src/DXRMCCRegistryLoader.Codeunit.al app.json
git commit -m "fix: SD-P1/P2/P3 never migrated data (wrong dispatcher IDs, one had no OnRun) - repoint registry to fixed dispatcher 54779, revert now-unneeded SD dependency"
```

---

## Task 1.2: DXP registry repoint (REDEFINED 2026-08-23 during execution — see below)

**Original design (typed MCC-side adapter codeunits) was ABANDONED before dispatch**, same reason as Task 1.1
(SD): investigating DXP's actual source first (before repeating Task 1.1's blocked cycle) found DXP already
has a plain, non-Upgrade Runner (`DXR_DXP_Migr_Phase_Runner`, codeunit 52313) with a REAL `trigger OnRun()`
that already orchestrates all 6 phases in sequence, and every one of the 6 phase codeunits (52310-52315)
already declares its own correct `Permissions` — DXP never had SD's `Access=Internal`-blocks-typed-reference
problem or SD's missing-Permissions problem. The only real bug was MCC's registry pointing individual
concepts at the wrong (no-`OnRun`) sub-phase codeunits directly instead of at 52313.

**A second, more serious bug was found and fixed at the source** (DXP's own repo,
`C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXPAYMENT-BC`, separate git repo, not tracked by this
ledger, branch `migration/dx-payments-28.3`): DXP-P1/P3/P5 all restore the SAME 9 payment/promotion tables
from 3 different legacy generations, all insert-only-if-absent (never overwrite) — old `OnRun` order let
Phase 1 (oldest generation) always win. User confirmed Phase 5 (most recent generation) is the actual
source of truth. 4 commits landed (local only, not pushed):
- `3d1b88c` — reorders `OnRun()` to run Phase 5 before Phase 1/2/3/4/6 (fixes NEW companies only)
- `608dd6e` — adds a genuine retroactive-repair pass (`RepairPhase5PrecedenceIfNeeded`, own Upgrade Tag,
  evaluated unconditionally like the file's existing `EnsurePermissionSetsAssignedIfNeeded` pattern) with a
  real upsert (`RepairPrecedence` + 9 `RepairXxx` procedures on `DXR_MigrPhase5Tables.Codeunit.al`) — review
  found the simple reorder alone was a silent no-op for any company that already ran the old order
- `0c499f0` — fixes 2 of the 9 `RepairXxx` procedures (`RepairPromoBinHeader`, `RepairStorePayments`) to use
  `Modify(false)` instead of `Modify(true)` — review found `Modify(true)` fired `OnModify()` triggers with
  real side effects (a hard-block guard on already-Enabled promotions; an unwanted replication-counter bump)
- `ad5797a` — documentation completeness fix (comment clarity only)

All 4 compile clean and were independently reviewed (3 review rounds total, final verdict "ready to merge").

**What's actually left for MCC (this task, in this worktree):**

**DONE (2026-08-23) — actual result, corrected from this task's original estimate:** the brief below
originally estimated 49 rows across DXP-P1(10)/P2(6)/P6(6); the implementer found and correctly repointed
the REAL count, 46 rows (DXP-P1: 9, P2: 5, P3: 9, P4: 9, P5: 9, P6: 5) — verified by direct grep, not
fabricated to match the estimate. Commit `8fa133d`. Final whole-branch review independently re-verified 46
is correct. **The DXP-P3 table-ID question in Step 2 below was investigated further by the final review and
is a FALSE ALARM, not a real follow-up** — `54220`/`54769` etc. are digits embedded in the legacy tables'
AL object NAMES (e.g. `table 54769 "DXR_Payment Setup 54220"`), not two different ID schemes; the registry's
`54769-54777` Legacy Table IDs are the actual object IDs and are correct. No further action needed on this.

**Files:**
- Modify: `src\DXRMCCRegistryLoader.Codeunit.al` — all 46 `InsConcept('DXP', ...)` rows (DXP-P1: 9 rows
  currently `52310`, DXP-P2: 5 rows currently `52311`, DXP-P3: 9 rows currently `52312`, DXP-P4: 9 rows
  currently `52321`, DXP-P5: 9 rows currently `52314`, DXP-P6: 5 rows currently `52315`)
- Modify: `app.json` — remove the DXP dependency added in Task 1.0 (no longer needed, same reasoning as
  Task 1.1's SD dependency revert — no typed reference to DXP from MCC)

**Interfaces:**
- Consumes: nothing new — MCC's existing `Codeunit.Run(Integer)` dispatch mechanism, unchanged.
- Produces: nothing new.

- [x] **Step 1: Repoint all 46 DXP concept rows to `52313`.** Grep `InsConcept('DXP',` in
  `DXRMCCRegistryLoader.Codeunit.al` to find every row (they are NOT contiguous — DXP-P5/P6/P2/P4/P1/P3 rows
  are interleaved with other extensions' rows and each other across the file). Change each row's
  `DispatcherCodeunitId` argument (currently `52310`, `52311`, `52312`, `52314`, `52315`, or `52321`
  depending on phase) to `52313`.

- [x] **Step 2: RESOLVED — see the "DONE" note above.** DXP-P3's Legacy Table IDs (54769-54777) are correct
  as-is; the 54220-series digits are name-embedded tags on the legacy tables, not a second ID scheme. No
  registry change needed.

- [x] **Step 3: Revert the DXP half of Task 1.0's `app.json` dependency** — removed the
  `36b9c68f-cc27-46b1-bf63-4400a31c5f61` (DX-Payments) entry from `dependencies`, leaving an empty array
  (both SD and DXP dependencies are now reverted).

- [x] **Step 4: Compile** (Task 1.5's command). Clean, same lone pre-existing warning.

- [x] **Step 5: Commit** — `8fa133d`, "fix: DXP-P1/P2/P3/P4/P5/P6 never migrated data (wrong dispatcher IDs) - repoint all DXP concepts to fixed Runner 52313, revert now-unneeded DXP dependency"

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

- [ ] **Step 3: Confirm via `DXR MCC Run Log`** that all SD-P1/P2/P3 (10 concepts) and all DXP-P1/P2/P3/P4/P5/P6 (46 concepts) now show non-zero `Migrated Record Count` where their legacy tables have real rows — DXP-P3 IS wired (repointed to 52313 along with everything else; the earlier "stays unwired" note was from the abandoned original design and no longer applies, see Task 1.2's "DONE" note). Watch specifically for companies that already ran SD's OLD `OnUpgradePerCompany`-based migration before this fix (see Recommendation 4 in the final whole-branch review, 2026-08-23) — if Phase 1/2/3's Upgrade Tags are already set from that old run, each phase's internal tag guard will correctly no-op, which is expected and NOT itself a sign this fix failed.

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

## Roadmap: original discovery classification vs. what was actually built

The table below is the ORIGINAL discovery-pass estimate (2026-08-23, before execution started) — kept for
historical reference on relative extension size/complexity. **It does not reflect what was actually built.**
The realized granularity is coarser than "TRIVIAL/COMPLEX per concept" implies (see "REALIZED GRANULARITY"
above) — every extension below except VP got exactly one adapter per existing phase/dispatcher codeunit,
not one per concept row, so the COMPLEX/TRIVIAL split never ended up mattering the way this table assumed.
**For the real, as-built result per extension, see the Roadmap Execution Log section immediately below this
table.**

| Order | Ext | Real folder | Concepts (registry) | Original TRIVIAL/COMPLEX estimate | Status |
|---|---|---|---|---|---|
| 1 | DRLOC | `DR-Localization\Localization\src\Base\Codeunits\Uprade\` | 105 | ~55-60 TRIVIAL, ~8-10 COMPLEX, 3 SKIP | **DONE** (93 rows wired; see Execution Log) |
| 2 | BC | `Base-Controls\Base Controls\src\services\migration\` | 19 | 19 TRIVIAL | **DONE** |
| 2 | RBPD | `Recaudo BC\RecaudoBPD\Base\Codeunits\` | 11 | 11 TRIVIAL | **DONE** |
| 3 | VP | `DxPayloads-BC\Vendor Payloads\src\Base\Codeunits\Migration\` | 46 | ~20 TRIVIAL, ~3 COMPLEX | **DONE** |
| 4 | DXP | `DXPAYMENT-BC\Base\CodeUnits\` | 46 | 46 TRIVIAL | **DONE** (Task 1.2) |
| 5 | PCM | `Price-Controls-Mgt\Price Controls Mgt\src\Base\Codeunits\` | 16 | ~10 TRIVIAL, ~6 COMPLEX | **DONE** |
| 5 | TU | `DX-TransUnion\TransUnion\src\Base\Codeunits\` | 5 | 5 TRIVIAL | **DONE** |
| 6 | DESB | `Despacho-Base\Despacho Base\src\Base\Codeunits\Upgrade\` | 71 (registry) / 42 (adapted) | 67 TRIVIAL, 4 COMPLEX, 1 SKIP | **DONE** |
| 6 | DESLS | `Despacho-Base\Despacho LS\src\Base\Codeunits\Upgrade\` | ~14 (est.) / 17 (registry) | ~4 TRIVIAL, 10 COMPLEX | **DONE** |
| 7 | RC | `Retail-Controls\src\services\upgrade\` | ~8 phases (est.) / 12 (registry) | Phase1/2/4/5 moderate, Phase3 COMPLEX | **DONE** |
| 8 | FE | `Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\` | ~40 (est.) / 41 (registry) | ~32 TRIVIAL, 3+ COMPLEX | **DONE** |
| 9 | LSFE | `Facturacion Workspace\BC-Facturacion-Electronica\LS Facturacion Electronica\Base\Codeunit\` | 2 | 2 TRIVIAL | **DONE** |
| 10 | BELLON | `Bellon_Customization\Bellon Customization\src\Base\Codeunits\` | ~257 (est.) / 269 (registry) | ~256 TRIVIAL | **DONE** |
| 11 | BELLONPOS | `Bellon_Customization\Bellon POS\Base\Codeunits\` | 12 | 12 TRIVIAL | **DONE** |
| — | LSLOC | `Localizacion-LS-Central\LS Localizacion Base\Base\Codeunits\Upgrade\` | 24 | not in original discovery pass (missed entirely — found late) | **DONE** |
| — | DPP | `DescuentoProntoPago-OLD\Base\Codeunit\` | 3 | not in original discovery pass | **N/A — no adapter possible or needed** (see below) |

**BLOCKING QUESTIONS from the original discovery pass:**
1. ~~DXP-P3 vs DXP-P5: which legacy generation is the real source of truth for tables 52275-52283?~~ **RESOLVED 2026-08-23** — user confirmed Phase 5 (most recent generation). Fixed at the source in DXP's own repo.
2. ~~Confirm before BELLON: read the 7 un-read Phase bodies before assuming they're safe.~~ **RESOLVED 2026-08-23** — all 11 BELLON phase codeunits read directly; found genuinely simpler than estimated (all `Access = Public`, real `OnRun` bodies, no internalsVisibleTo needed anywhere in that repo — the only extension in the whole portfolio where that's true). See Execution Log.
3. ~~Should DRLOC be brought into this same pattern?~~ **RESOLVED 2026-08-23** — user explicitly confirmed ("y las localizacion vamos agregarlas tambien aqui y hacer que funcionen aqui"). DRLOC's Localization project (Base App DR Localization) is its own already-existing git repo — no new repo initialization was needed, same as every other sibling extension. Wired using the same coarser per-dispatcher pattern as the rest of the portfolio, not the original fine-grained Task 2.1-2.3 per-concept design (see Execution Log).

---

## Roadmap Execution Log (2026-08-23, post-Phase-1 "build completo" redirect)

After Phase 1 (SD + DXP) was reviewed and merge-ready, the user issued two redirects: (1) reverse the
registry-repoint-only fix for SD/DXP back to the original typed-adapter-with-real-dependency design, and
(2) apply that same dependency + typed-reference pattern **gradually, to every extension MCC works on, as a
deliberate design pattern** — not only where strictly necessary — because this guarantees migration by
table/field NAME from each source extension and avoids ever having to recompile all 22+ extensions together.
The process below was repeated per extension, without a fresh SDD implementer dispatch per extension (done
directly, same session, same as SD/DXP): check git status (land any pre-existing uncommitted work if it
compiles clean), verify each source codeunit's real `Access` modifier and entry point directly from its own
source (never assumed), add `internalsVisibleTo` only where `Access = Internal`, add the MCC dependency, add
one typed adapter per existing phase/dispatcher codeunit, repoint that extension's registry rows, compile
MCC clean, commit in both the source repo and MCC. A batched independent review (not per-extension) was
dispatched twice: once after BC+RBPD+VP, once after PCM through BELLONPOS.

**BC** (`Base-Controls\Base Controls`): pre-existing uncommitted Phase2/3/Scheduler+async work landed
(commit `74d0cc3`, compiles clean). `internalsVisibleTo` granted (BC commit `1030d9e`). 4 typed adapters —
Phase1/2/3, PermRepair (60021-60024) — all 4 dispatchers already had real `OnRun` + correct `Permissions`;
pure compile-safety upgrade, 0 confirmed bugs. All 19 BC rows repointed (MCC commit `4761da5`).

**RBPD** (`Recaudo BC\RecaudoBPD`): pre-existing uncommitted Worker+legacy tableext work landed (commit
`53cc466`, compiles clean). `internalsVisibleTo` granted (RBPD commit `0273381`). 1 typed adapter — Worker
(60025), real `OnRun` confirmed. All 11 RBPD rows repointed (MCC commit `b73376b`).

**VP** (`DxPayloads-BC\Vendor Payloads`): clean tree. `internalsVisibleTo` granted (VP commit `189eaca`).
**Architecture lesson, caught before wiring**: VP's own `DXR_VP Migration Dispatcher` (52720) has a real
`OnRun` but only advances ONE phase per call, then reschedules the rest via its own async Job Queue — wiring
MCC to it once would falsely report success after only Phase 1. Wired 7 typed adapters (60026-60032) directly
to each phase's own `Run(var Progress, var Total, var ErrorText): Boolean` procedure instead (the one
extension in the batch where the adapter count matches per-procedure, not per-dispatcher, granularity — this
already matched the registry's existing per-phase rows). Independent review found this is a REAL functional
fix, not just compile-safety: none of VP's 7 phase codeunits had an `OnRun` at all, so MCC's prior raw
`Codeunit.Run()` calls were silent no-ops for all 46 VP concepts (same bug class as the original SD/DXP
finding). All 46 VP rows repointed (MCC commit `2b17cc3`).

**PCM** (`Price-Controls-Mgt\Price Controls Mgt`): pre-existing uncommitted Phase5IdRenumber + legacy tables
landed (commit `98d55ce`, compiles clean). All 4 phase codeunits (Phase2-5) confirmed `Access = Public` — no
`internalsVisibleTo` needed. 4 typed adapters (60033-60036). All 16 PCM rows repointed.

**TU** (`DX-TransUnion\TransUnion`): `internalsVisibleTo` granted (TU commit `6d3d30d`). 1 typed adapter —
Dispatcher (60037), `Access = Internal` confirmed. TU-P1 rows repointed (TU-GAP rows stay Dispatcher=0,
MCC Fallback Migrator, unchanged).

**DESB + DESLS** (sibling projects, one git root `Despacho-Base\`): pre-existing uncommitted work landed
(commit `a949b7e`, 97 files, both projects compile clean). Both `internalsVisibleTo` granted (DESB `b36aa90`,
DESLS `6112d73`). DESB: 2 typed adapters — Worker (60038), Phase2 (60039). DESLS: 2 typed adapters — Worker
(60040), Phase1 (60041). In both, the Worker's own `OnRun` already calls its Dispatcher's
`RunPendingPhasesWithStatusTracking()`, which itself runs Phase2 (or Phase1) internally under its own
Upgrade Tag — the registry's separate direct-to-Phase2/Phase1 rows cause a harmless, independently
tag-gated, redundant double-invocation; documented in the adapter comments, deliberately not "fixed"
(pre-existing registry structure, out of scope). Independently re-verified true by the batched review
(read the Worker's actual `OnRun` body in both repos). ⚠ `Despacho-Base\apps\1-DespachoBase\` is a stale
duplicate copy of DESB at an older version (27.0.0.18 vs the live 28.3.4.21) — confirmed by the review to be
unrelated to this work, but a trap for future greps of this repo. All 42 DESB + 17 DESLS rows repointed.

**RC (Retail Controls)** (`Retail-Controls`): pre-existing uncommitted Phase4/5/Scheduler+legacy tables
landed (commit `f1c206c`, compiles clean). `internalsVisibleTo` granted (RC commit `a8a1831`). 5 typed
adapters — Phase1 Setup Retro/Phase2 Documents/Phase3 ID Collision/Phase4 PermSet Repair/Phase5 Setup Tables
(60042-60046), all `Access = Internal` with real, substantive `OnRun` logic (Phase3/5 are themselves
retroactive repairs of an earlier retroactive repair, well-documented in RC's own source). All 12 RC rows
repointed (MCC commit `16b3d10`).

**FE + LSFE** (sibling projects, one git root `BC-Facturacion-Electronica\`): clean tree. **Both `app.json`
files were blocked by this repo's own blanket `*.json` `.gitignore` rule** (only the two `.Test` app.json
were carved out with `!`) — asked the user, ruling was to force-add (`git add -f`) past the rule rather than
leave the `internalsVisibleTo` grant uncommitted/lost on a fresh clone. Committed as `4f3b14f` (first time
either main app.json has ever been tracked in this repo). FE: 7 typed adapters — Phase7 Bootstrap/8 Master/9
Purchase/10 Sales/11 Tables/12 History/13 NCF Cleanup (60047-60053), all `Access = Internal` with real
`OnRun`; FE's one `Subtype = Upgrade` codeunit (52530 "DXR_Upgrade") was never touched. LSFE: 2 typed
adapters — Assign PermSet (60054), POS Contingency (60055), both `Access = Internal`; their `OnRun` bodies
call NAMED PROCEDURES (not `.Run()`) on a typed `"DXR_LSFE Upgrade"` (52587) variable, which genuinely IS
`Subtype = Upgrade` — this is the one case in the whole portfolio where a Subtype=Upgrade codeunit is
touched at all, done deliberately via procedure call rather than `.Run()`, matching a pre-existing pattern
already used inside LSFE's own source. All 41 FE + 2 LSFE rows repointed (MCC commit `3be35fb`).

**BELLON + BELLONPOS** (sibling projects, one git root `Bellon_Customization\`): pre-existing uncommitted
work landed (commit `ba7697d6` in that repo — new Phase13 OldGap + Phase14 XCollFix migration codeunits,
dispatcher/tag updates, version bumps for both extensions; IDE `.alcache` junk files were staged
accidentally by a broad `git add`, caught and unstaged before commit). Phase13/14 are new migration phases
not yet in MCC's registry — out of scope for this pattern-application pass. All 11 BELLON phase codeunits
(Phase2-12, 56119-56129) AND BELLONPOS's 1 phase codeunit (56212) confirmed `Access = Public` — the only
extension in the whole ~14-extension portfolio where zero `internalsVisibleTo` grants were needed anywhere.
12 typed adapters (60056-60067). All 269 BELLON + 12 BELLONPOS rows repointed, verified via a precise
field-position sed pattern (not a bare word-boundary match) given the huge free-text description corpus
made accidental ID collisions likelier than in smaller extensions — zero collisions found (MCC commit
`e28c87f`).

**LSLOC (LS Central DR Localization)** (`Localizacion-LS-Central\LS Localizacion Base`) — **found and wired
after the fact**: this extension's registry rows (`InsConcept('LSLOC', ...)`, 24 rows) were missed by the
original portfolio pass above — not in the Roadmap table, not touched until the user flagged "aun queda
pendiente las demas extensiones... que tienes aqui en la ruta fisica" (there are still pending extensions
here in the physical path) after the doc-update pass had already started. Pre-existing uncommitted work
landed first (commit `f2b4e7c` in that repo — fixes a malformed `app.json`, a duplicate `runtime` key that
made the file invalid JSON, plus 3 restored legacy `.old` table/tableextension definitions; compiles clean).
Its single Dispatcher (54506) confirmed `Access = Public` (no `internalsVisibleTo` needed, same as
BELLON/BELLONPOS) with a real, substantive `OnRun` that orchestrates all 3 of the extension's migration
phases (OPOS Setup, LS-to-DXR_LS restore, dependency-field sync), each independently Upgrade-Tag-gated. 1
typed adapter (60068, the one case in the whole portfolio where a single dispatcher already covers every
row for its extension, same shape as SD's dispatcher). All 24 LSLOC rows repointed (MCC commit `ecc9c87`).
**Not yet covered by either independent batch review below** — flag for a future review pass alongside
DRLOC.

**Independent batch reviews:**
- Round 1 (after BC+RBPD+VP): confirmed VP's finding (real functional fix, not just compile-safety) and
  found BC's Phase2 comment overstated ("purely compile-safety") — Phase2's own `Copy*` procedures always
  overwrite (pre-existing behavior, gate lives in the Scheduler which MCC's adapter bypasses by calling
  `OnRun` directly, not a regression). Both corrected in adapter comments, commit `75f774b`.
- Round 2 (after PCM through BELLONPOS, all 9 remaining extensions): **zero Critical or Important findings.**
  Every specifically-flagged risk (BELLON's 269-row sed-collision risk, DESB/DESLS Worker redundancy claim,
  LSFE's Subtype=Upgrade procedure-vs-`.Run()` distinction, FE/LSFE's forced `app.json` tracking, the
  `ba7697d6` landed-work claim) was independently re-verified against the real source and confirmed accurate.
  Two Minor/informational notes only (a harmless FE version-skew between two dependents' pins, and the
  DESB stale-duplicate-folder trap noted above) — no fixes required. Verdict: "correct and safe as
  committed."

**DRLOC (DR-Localization, "Base App DR Localization")** (`DR-Localization\Localization`): the one remaining
Roadmap extension — user explicitly confirmed bringing it into the same pattern ("y las localizacion vamos
agregarlas tambien aqui y hacer que funcionen aqui"). Pre-existing uncommitted work landed first (commit
`497c517` in that repo — touches `DXR_UpgradeTagMgt`, `DXR_Field_ID_Alignment_Upgrade`,
`DXR_Internal_Closure_Migration_Upgrade_Clean`, `DXR_Internal_Migr_Phase_Tags`, Phase 2/3/5's own codeunits,
`DXR_PurchaseHeaderExt.TableExt`, and an `app.json` version bump; compiles clean). Read all 5 target phase
codeunits directly: Phase 2 Fiscal (52210), Phase 3 Purchase (52212), Phase 4 Sales (52214), Phase 5 Ledger
(52216), Phase 6 History (52257) all confirmed `Access = Public` (no `internalsVisibleTo` needed) with real,
substantive `OnRun` bodies — none is the repo's `Subtype = Upgrade` codeunit (that's a DIFFERENT codeunit,
DRLOC-P1's "Internal Closure Migration", which correctly stays unwired/`Blocked`, `Dispatcher = 0`, per the
Global Constraints skip-list rule — never touched). 5 typed adapters (60069-60073). All 93 wireable DRLOC
rows (`DRLOC-P2` 23, `-P3` 13, `-P4` 10, `-P5` 19, `-P6` 28) repointed. Two other row groups deliberately left
untouched, both already correctly handled without an adapter: **DRLOC-GAP** (9 rows, `Dispatcher = 0` with
real Legacy/New Table IDs) already flows through MCC's own generic `DXR MCC Fallback Migrator`
(RecordRef-based table-pair reconciliation, fires automatically whenever `Dispatcher = 0` and both table IDs
are nonzero — this mechanism predates this session's adapter work and needs no per-extension wiring at all);
**DRLOC-NCF** (2 rows, `Dispatcher = 0`, both table IDs 0) are genuine code-level fixes with no row-copy
action to point at, correctly `Not Row-Based`. MCC commit `62f5b55`. This closes the Roadmap: every
registry extension code is now either wired, confirmed to need no adapter (DPP — see below), or correctly
handled generically (DRLOC-GAP/NCF/P1).

**DPP (DescuentoProntoPago-OLD)**: confirmed needs no adapter, not a gap. Of its 3 registry rows, 2 are
retired stale entries (`Dispatcher = 0`) and the 1 real row (DPP-UPG) points directly at codeunit 54283,
which IS the portfolio's one `Subtype = Upgrade` codeunit for this extension — per the Global Constraints
rule that codeunit can never become an adapter target, so DPP-UPG correctly stays `Blocked`/manual (runs
automatically on next publish/schema-sync only).

**Not yet done:** neither LSLOC nor DRLOC has been through the same independent-review process as the
earlier batches (BC+RBPD+VP round 1, PCM-through-BELLONPOS round 2) — a review was dispatched for both after
this doc update, covering LSLOC's single adapter and all of DRLOC's wiring (including the Fallback
Migrator/GAP/NCF claims above, independently re-verified against the Executor source, not just asserted).
No review is dispatched against this doc's own edits (documentation, not code).

**Portfolio coverage as of this update:** every registry extension code has now been checked and wired where
possible — SD, DXP, BC, RBPD, VP, PCM, TU, DESB, DESLS, RC, FE, LSFE, BELLON, BELLONPOS, LSLOC, DRLOC (16)
wired with the typed-reference pattern; DPP (1) confirmed to need no adapter. **No extension remains open.**
The Roadmap's original per-concept granularity goal (Tasks 2.1-2.3, DRLOC-P2's 18-step breakout) remains
unimplemented — see "REALIZED GRANULARITY" at the top of this document — but is a separate, lower-priority
piece of work, not required for what "build completo" asked for.

---

## Task 1.5 (reference): compile command used throughout this plan

```bash
"/c/Users/rpena/.vscode/extensions/ms-dynamics-smb.al-17.0.2273547/bin/win32/alc.exe" \
  /project:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center" \
  /packagecachepath:"C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\DXR-Migration-Control-Center\.alpackages" \
  /out:"<scratch path>\mcc_test.app"
```

Confirmed working against the current `.alpackages` cache this session (clean compile, one pre-existing unrelated warning). Every new dependency added by this plan requires that extension's `.app` symbol package to be added to `.alpackages` first (via "Download Symbols" in the AL extension, or manually copying the `.app` file), or this command will fail with an unresolved-reference error, not the "project without a manifest" error seen when `/out` is a POSIX-style path — always use Windows-style paths with this specific `alc.exe`, confirmed earlier this session.
