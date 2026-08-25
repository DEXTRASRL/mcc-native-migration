# MCC Full-Portfolio Native Migration — Completion Roadmap

**Status as of 2026-08-24 (mid-session).** This is a living execution roadmap, not a new plan — it
sits alongside `2026-08-24-mcc-full-portfolio-native-migration.md` (the original Task A.1-D.1 plan)
and `2026-08-24-mcc-full-portfolio-native-migration-design.md` (the spec) and gives the concrete,
up-to-date sequencing for finishing the whole objective, informed by everything learned executing
Tasks A.1-A.4 and the first half of B.1. Update this doc as each stage completes; treat counts here
as a snapshot, re-verify against the live registry before trusting an exact number late in execution.

## The objective, restated

Every migration action across the ~21-extension DXR portfolio should be: (1) tracked as a row in
MCC's own registry, (2) executed by code that lives INSIDE MCC using typed `Record` variables only
(zero RecordRef/FieldRef/TransferFields), with (3) zero dependency on any sibling extension's own
background dispatcher or bridge codeunit to actually move data — MCC alone, compiled and published,
should be able to run every migration. DGII-RNC Database is deliberately the last item, reserved for
Task D.1, because it's the largest/highest-risk single action in the whole portfolio.

## What's already done

- **Task A.4 (Setup-phase sweep): 100% complete.** Every `Category = 'SETUP'` row across all 21
  extensions runs typed, native code inside MCC. ~250 concepts converted across BELLON (106),
  DXP, DRLOC, FE, LSLOC, VP, BC, DESB, PCM, TU, RBPD, RC, DESLS, SD, BELLONPOS, LSFE.
- **Architecture pivot: cross-repo "bridge" codeunits retired.** DR-Localization (DRLOC) and Price
  Controls Mgt (PCM) now grant MCC's app ID `internalsVisibleTo` directly — MCC can declare typed
  `Record` variables on ANY of their tables, including fields other extensions added via their own
  tableextensions of those tables (empirically proven). Every existing bridge-calling adapter
  (DRLOC's Payment Method Relation, PCM's Prices Ctrl Setup, LSLOC's 5 dependency-field concepts,
  FE's 4 NCF/Payment concepts, BELLON's 3 NCF Setup concepts) has been retrofitted to call zero
  sibling-repo code. The old bridge codeunits themselves remain in their own repos, orphaned/unused
  — harmless, not deleted.
- **BELLON-P2 tableextension field-group MA campaign: 14/14 concepts complete** (49 procedures,
  ~36 real shadow-field bugs found and fixed, including a systemic bug affecting 100% of Customer's
  and Item's fields). BELLON-P2's 37 whole-table-clone MA concepts also complete. Only `seq135`
  ("Sales/Purchase old-generation bridge copy") remains in BELLON-P2's own MA scope — see below,
  it's now understood to be a much bigger item than its single registry row suggested.
- **LSLOC's entire MA scope: 5/5 complete.**

## In flight

- **DRLOC native-porting campaign** (user priority #1). DRLOC's registry ROW tracking is already
  100% complete (every real action across its 5 phase codeunits — Phase 2 Fiscal, 3 Purchase, 4
  Sales, 5 Ledger, 6 History — has a row), but only 1 of ~120 distinct actions (Payment Method
  Relation) has had its logic actually copied into MCC. The other ~119 still work by MCC calling
  into DRLOC's own dispatcher (`Codeunit 52208`) via the forwarding adapter `DXRMCCAdaptDRLOCDispatcher`
  (60069) — DRLOC's app must still be installed/running for those to execute. This campaign copies
  each action's field-mapping logic (already typed/correct in DRLOC's own source — this is
  primarily careful transcription, not RecordRef conversion, though shadow-field verification stays
  mandatory) into new MCC-native codeunits, one per DRLOC phase (`60165`-`60169` reserved), and
  repoints each ported row's Dispatcher Codeunit ID away from `60069`.

  | Phase | Distinct actions | Ported so far |
  |---|---|---|
  | 2 – Fiscal | 48 | 1 done (Payment Method Relation) + 13 dispatched (Batch 1, in review) |
  | 3 – Purchase | 12 | 0 |
  | 4 – Sales | 9 | 0 |
  | 5 – Ledger | 24 (1 bundled V27 row = 12 individual fixes) | 0 |
  | 6 – History | 27 | 0 |

  Phase 1 does not apply — it's BC's own platform-native Subtype=Upgrade codeunit, cannot be
  `Codeunit.Run()` by MCC, correctly excluded (registry `seq8`, marked accordingly).
  **DGII-RNC Database (`seq15`, part of Phase 2) is explicitly excluded from this campaign** — it's
  reserved for Task D.1 per the original plan.

## Next up (user priority #2, right after DRLOC)

- **BELLON's Sales/Purchase old-generation bridge** (`seq135`). Not yet dispatched. 14 procedures
  (8 Sales-family: SalesHeader, SalesInvoiceHeader, SalesCrMemoHeader, SalesShipmentHeader,
  SalesLine, SalesInvoiceLine, SalesHeaderArchive, SalesLineArchive; 6 Purchase-family:
  PurchaseHeader, PurchInvHeader, PurchRcptHeader, PurchaseHeaderArchive, PurchaseLine,
  PurchRcptLine) currently live only in BELLON's own `BellonUpgradeProcess.Codeunit.al`
  (`MigrateAllSalesPurchOldGenBridge` and its 14 sub-procedures), completely unported. `seq135` is
  today a placeholder row with no real implementation behind it. Same native-porting treatment as
  DRLOC: read each real procedure, transcribe into a new typed MCC codeunit, verify shadow-fields,
  set correct Permissions, repoint the registry row.

## Remaining Task B.1 scope after DRLOC + the BELLON bridge (ordinary MA sweep, the other 11 extensions)

Registry counts as of this snapshot (re-verify before trusting late in execution):

| Extension | MA rows remaining |
|---|---|
| BELLON (P6 + small codeunits, non-bridge) | ~49 (106 total MA-ish minus the 51 already done minus the 14-procedure bridge counted above — re-verify exact split between P2 remainder/P6/singletons) |
| DXP | 24 |
| FE | 21 |
| VP | 17 |
| DESB | 14 |
| RBPD | 6 |
| PCM | 5 |
| SD | 4 |
| TU | 3 |
| RC | 3 |
| BC | 5 |
| DESLS | 5 |

Same proven pattern as the Setup sweep and BELLON-P2's MA campaign: per-extension investigation
(confirm which rows are genuinely RecordRef-in-MCC vs. forwarding-to-sibling-repo — DRLOC-style
gaps could exist elsewhere too, worth a quick per-extension check before assuming "ordinary"
RecordRef conversion is all that's needed), batch dispatch (~15-20 concepts per batch for simple
field-group/whole-table work, smaller for anything requiring cross-repo reads), compile+review+
fix-loop per batch, same rigor — elevated shadow-field/Permissions scrutiny wherever Item/Vendor/
Customer/other master-data tables appear.

## Task C.1 — Historic-phase sweep (not started)

`Category = 'HIST'` rows, ~157 total across the portfolio (BELLON 52, DRLOC 29, VP 21, FE 16, DESB
12, DXP 8, BC/BELLONPOS/DESLS/LSLOC/SD/RBPD/RC/PCM/DPP smaller counts each). Per the plan's Global
Constraint, this phase does not start until Task B.1 (MA) is fully checked off and re-verified.
DRLOC's own Phase 6 History logic (27 actions) is likely double-covered here — its `HIST`-category
rows and the DRLOC native-porting campaign above may overlap; when Task C.1 begins, re-check
whether DRLOC's Historic rows were already ported as part of the native-porting campaign (if the
campaign's Phase 6 batch already happened) before re-dispatching them.

## `Category = 'OTHER'` rows (~40 total, ruling needed)

Neither the original plan's Task A.4/B.1/C.1 nor this roadmap currently assigns `OTHER`-category
rows to any phase — they were consistently found to be intentionally out-of-scope wherever
encountered (BELLONPOS's 6, LSLOC's 2, etc.) during this session's investigations. Before declaring
the whole objective complete, get an explicit ruling on whether `OTHER` rows need any treatment, or
whether the category exists for something this plan was never meant to touch (e.g. one-time
schema/ID-collision fixes like DRLOC's `seq6`/`seq7`, which are NOT recurring migration actions).

## Task D.1 — DGII-RNC Database (final task, last of everything)

Explicitly gated on Task C.1 being fully complete, per the original plan and the user's original
instruction that this is the largest/highest-risk single item in the portfolio. Not touched by any
work above — the DRLOC native-porting campaign explicitly skips `seq15`.

## Sequencing summary

1. ~~**DRLOC native-porting campaign**~~ — **DONE (2026-08-25).** All 6 phases complete: Phase 2
   (48/48), Phase 3 (12/12), Phase 4 (9/9), Phase 5 (19/24), Phase 6 (27/27) = 115/120 real
   registry-tracked actions natively ported into MCC codeunits 60165-60170, zero cross-repo bridge
   dependency remaining. Also retired 3 stale coarse "phase" bridge rows (DRLOC-P2/P3/P4, seq1-3) and
   fixed a portfolio-wide missing-Execute-permission gap (DRLOC's 6 codeunits + BELLON's
   SPOldGenBridge) found along the way. **Open items, not blocking anything below:**
   - Phase 5's `seq49` (V27 data corrections) has 2 of 11 sub-procedures deliberately deferred
     (`Repair606CardChargeVLEs`/`Repair606BankChargeVLEs`, which depend on a ~1500-line, dialog-
     coupled, live NCF-sequence-generation procedure in a separate DRLOC codeunit — same risk class
     as DGII-RNC). `seq49` and DRLOC-P5's own coarse bridge row (`seq4`) stay pointed at `60069`
     until this gets its own dedicated task.
   - MCC's own `DPP` Extension Notes registry comment (line ~62) looks stale/inaccurate against DPP's
     real current source — a small documentation-correction follow-up, unrelated to DRLOC itself.
   - `DGII-RNC Database` (`DRLOC-P2 seq15`) stays excluded, per Task D.1 below.
2. ~~**BELLON Sales/Purchase old-generation bridge**~~ — **DONE** (`seq135`, confirmed a real no-op,
   commit `950e4cd`).
3. **Ordinary Task B.1 MA sweep** for the remaining 11 extensions (BELLON P6/small, DXP, FE, VP,
   DESB, RBPD, PCM, SD, TU, RC, BC, DESLS) — re-verify each extension isn't hiding its own
   DRLOC-style "forwards to a sibling repo" gap before assuming the ordinary RecordRef-conversion
   pattern applies. **Next task.**
4. **Task C.1** — Historic-phase sweep, all extensions, after B.1 is fully re-verified complete.
5. **Resolve the `OTHER`-category ruling.**
6. **Task D.1** — DGII-RNC Database, the final task.
7. Final whole-branch review (`superpowers:finishing-a-development-branch`) once everything above is
   done and the SDD workspace's own final review passes clean.
