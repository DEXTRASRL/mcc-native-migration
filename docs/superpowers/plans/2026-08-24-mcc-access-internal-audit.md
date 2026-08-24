# MCC Access=Internal Portfolio Audit (Task 0.2)

Determines, per registered extension, whether MCC (an external app) can declare
`Record "DXR_SomeTable"` directly against that extension's migration-target tables
("Direct" pattern), or must instead call a public procedure on the source extension's
OWN migration codeunit which does the typed copy internally ("Thin-Wrapper" pattern) —
and, for extensions that need Thin-Wrapper, whether a public entry point into that
codeunit chain actually exists today.

Scope: all 21 extensions currently seeded in `src\DXRMCCRegistryLoader.Codeunit.al`'s
`LoadExtensions()` (17 that existed before this plan + the 4 Task 0.1 added: ES, RES,
BANKREC, VPAPI). `VendorPay_TXT` remains explicitly excluded (Task 0.1 scope note).

## Method

1. For each extension, `grep -rl "Access = Internal"` restricted to `*.Table.al` /
   `*.TableExt.al` / `*.TableExtension.al` files under its real project folder —
   narrower than the brief's whole-source loop, because a hit on an unrelated codeunit
   or page doesn't block a `Record` declaration; only a hit on the *table object itself*
   does.
2. Cross-referenced every table-level hit against that extension's actual registered
   migration concepts (`InsConcept` rows in the registry) to confirm the internal
   table is a genuine migration source/target, not an unrelated internal table.
3. For every extension with 1+ genuine table-level hits, read the Access modifier on
   ALL of that extension's own migration-namespace codeunits (dispatcher, phase
   codeunits, worker) — not just the top-level dispatcher — since a Thin-Wrapper only
   works if AT LEAST ONE of them is callable (not `Access = Internal`, and not
   `Subtype = Upgrade` alone blocking `Codeunit.Run()`).

## CORRECTION (2026-08-24, discovered mid-Task A.4 while working BC)

This audit's method (Step 2/3) never checked whether MCC's own app ID
(`a5b9bf50-7945-4455-8df4-3be9c7431a7b`) was already present in a target extension's own
`internalsVisibleTo` list — a THIRD path, independent of both "Direct" (table not Internal) and
"Thin-Wrapper" (source codeunit exposes a public procedure): if MCC is granted `internalsVisibleTo`
by the source extension, MCC can declare `Record` directly on that extension's `Access = Internal`
tables itself, with zero source-repo changes needed at all.

**Confirmed via direct `app.json` grep, 2026-08-24:**
- **BC, RC, TU, FE — all 4 extensions this audit classified "Blocked" — already grant MCC
  `internalsVisibleTo`.** None of them are actually Blocked. BC is confirmed Direct-viable by
  existing, already-working code (`DXRMCCBCMigrP2Warehouse.Codeunit.al` already declares
  `Record "DXR_Warehouse Ctrl Setup Old2"`/`Record "DXR_Warehouse Controls Setup"` directly and
  compiles, despite both tables being genuinely `Access = Internal` - confirmed via
  `WarehouseControlsSetup.Table.al:3`/`WarehouseControlsSetupGen2.Table.al:3`). RC and TU and FE
  were not yet re-verified against real code (BC was, since this is the correction's origin point)
  but their `app.json` grants are confirmed identical in kind - treat as Direct-viable, re-confirm
  per-table when a task actually reaches one of their internal tables, same evidence discipline as
  every other task in this plan.
- **DRLOC and PCM do NOT have this grant** (re-confirmed, matches original audit) - their
  Thin-Wrapper resolutions (Task A.3, Task A.4-PCM) were genuinely necessary, not extra work.
- **TU's Task A.4 thin-wrapper (new codeunit `DXR_TU Setup Gen2 Migration`, 53607, in TU's own
  repo) turned out to be MORE work than strictly necessary** - TU also grants MCC
  `internalsVisibleTo`, so a Direct fix (typed `Record` declared straight in MCC, no new TU-side
  codeunit) would have worked too. Not reverting this - the thin-wrapper is still correct, compiles,
  passed review, and adds a defensible extra layer of encapsulation - but flagging so this mistake
  (checking source codeunit access without checking internalsVisibleTo first) isn't repeated.

**Revised classification for BC/RC/TU/FE: Direct** (via `internalsVisibleTo`), not Blocked.
**New rule for every future task in this plan touching an `Access = Internal` table:** check the
target extension's own `app.json` for MCC's app ID in `internalsVisibleTo` BEFORE assuming a
Thin-Wrapper (new source-side codeunit) is required - only fall back to Thin-Wrapper when that
grant is genuinely absent (confirmed so far only for DRLOC and PCM).

## Key portfolio-wide finding (beyond what the brief anticipated)

The brief's DRLOC reference case (pervasive internal tables, but a NORMAL-access
dispatcher) turns out to be the **exception**, not the pattern most other extensions
follow. Four extensions — **BC, RC, FE, TU** — have pervasive `Access = Internal` on
their real migration-target tables **AND** every single one of their own
migration-namespace codeunits is *also* `Access = Internal`. For those four, neither
Direct nor Thin-Wrapper is viable today: MCC cannot declare `Record` on the tables,
and it cannot call any procedure on the source extension either, because there is no
public entry point. This is a real blocker, not a stylistic choice — later
adapter-writing tasks (A.4/B.1/C.1/D.1) for these four extensions will need the source
extension itself to expose one new public procedure before an adapter can be written at
all. Flagged as a concern below, not escalated, per the task's own guidance that a
clear (if inconvenient) finding doesn't need escalation — only genuine ambiguity does.

## Findings table

| Extension | Target tables Access=Internal? | Own migration codeunit(s) Access=Internal? | Adapter shape for MCC |
|---|---|---|---|
| DRLOC (Base App DR Localization) | Yes, pervasive (confirmed pre-existing: CHANGELOG.md:25, `DXR_PaymentMethodRelation.Table.al:11`, `DXR_DGIIRNCDatabase.Table.al`) | No — `DXR_Migr. Phase 2 Fiscal` (52210) confirmed normal access (sanity-re-verified: no `Access = Internal` line) | **Thin-Wrapper**: MCC calls DRLOC's own public phase codeunits |
| PCM (Price Controls Mgt.) | Yes, on the exact PCM-P5 table-pair concepts: legacy `DXRPRCApprovalHistory`/`DXRPRCLSCOffersFB`/`DXRPRCPricesCtrlSetup` (+ their `.old` shells, 6 files) AND active `PRCApprovalHistory`/`PRCLSCOffersFactbox`/`PRCPricesControlSetup`/`PRCPricesFactbox` (4 files) — 10 of 10 tables in that concept group are Internal on BOTH sides | No, for the codeunits that matter — re-verified against all files in `Base/Codeunits/`. Of the 11 "Migr"-named codeunit files, 10 are normal access: `DXR_Migr. Phase Dispatcher` (54615), `DXR_Migr. Phase 5 Id Renum` (54620), Phase 2 Master Data (54612), Phase 3 Approval (54613), Phase 4 Sales Docs (54614), Failure Handler (54611), Phase Tags (54616), Retry Mgt (54617), Scheduler (54618), Status Mgt. (54619). Only `DXR_Migration Lock Mgt.` (54610) is Internal within that 11-file set. Separately (not part of the "Migr"-named set), `DXR_Upgrade` (54599, file `DXRPRCUpgrade.Codeunit.al`) is also Internal — bringing PCM's full migration-namespace codeunit count to 12 (11 Migr-named + 1 Upgrade), of which 2 are Internal (LockMgt, Upgrade) and 10 are normal access | **Thin-Wrapper** for the 4 PCM-P5 table-pair concepts (seq 1-4), MCC calls the public Dispatcher/Phase 5 codeunit. **Direct** for the field-level concepts (Approval Entry, Sales Header/Line, Workflow, Customer, LSC Store Price Group — those extend standard BC tables, not Access=Internal) |
| ES (Base Email Sender) | Yes, on its 3 real migration tables: `DXEmailTemplatesTable`/`EmailTemplateCustomField`/`TemplatesRelatedTables` (active + `.old`, 6 files) | Partial — `DXR_Email Migr Dispatcher` (54059, `Subtype = Upgrade`, not directly callable via `Codeunit.Run()`) is normal access but not a usable entry point; `DXR_Email Migr Worker` (54060) **is normal access and callable** — confirmed no `Access = Internal` on it | **Thin-Wrapper**: MCC calls `DXR_Email Migr Worker`'s public procedure, not the Dispatcher |
| BC (Base Controls) | Yes, on 5 of 6 Phase 2 setup tables (Customer/Sales/Transfer/Vendor/Warehouse Controls Setup — all `Access = Internal`) + `DXR_BC Migr Status` table, PLUS their `.old` Gen-2 legacy shells. **Exception: `DXR_Purchase Controls Setup` (54800) is NOT internal** — verified by direct read, no `Access = Internal` line anywhere in the file | **Yes — ALL 8 of BC's migration codeunits are Access=Internal**: Dispatcher (54856), Phase Runner (56414), Phase 1 (54858), Phase 2 (56415), Phase 3 (56416), Perm Repair (56413), Retry Mgt (54862), Scheduler (54860). No public entry point exists anywhere in the migration namespace | **BLOCKED for 6 of 7 tables** (Thin-Wrapper not viable — no public codeunit to call; Direct not viable — tables are Internal). **Direct works only for Purchase Controls Setup** (the one non-internal table). Concern, not ambiguous: needs BC to add one public procedure before those 6 concepts get an adapter |
| RC (Retail Controls) | Yes, pervasive on its exact table-pair migration targets: `DXR_LYT Controls Setup`/`DXR_Pos Controls Setup`/`DXR_Internal Migr Status` (active files) + `.old` shell — matches RC-P1/P5 concepts exactly (3 of 3 real table-pair concepts) | **Yes — ALL 10 of RC's migration-namespace codeunits are Access=Internal**, including `DXR_Migr Phase Dispatcher` (54732/54733), Phase1-5, Scheduler, Install Mgt, Phase Tags, Upgrade Mgt. No public entry point | **BLOCKED** for the 3 table-pair concepts (RC-P1 seq4-5, RC-P5 seq1-3) — same class of gap as BC. **Direct works** for RC's field-level concepts (Sales/Purchase Header, Sales Invoice Header, LSC POS Func. Profile — standard BC tables, not internal) |
| TU (TransUnion) | Mixed and asymmetric: the TU-P1 concept's LEGACY SOURCE tables (57304/57305, actually named `DXR_Transunion Setup Old2`/`DXR_Transunion Header Old2`) ARE `Access = Internal`; the ACTIVE DESTINATION tables (53601/53602, `DXR_Transunion Setup`/`DXR_Transunion Header`) are NOT internal | **Yes — ALL 6 of TU's codeunits are Access=Internal**, including `DXR_TU Migr Dispatcher` (53605), Cust. Ledger Entry Mgt., Events, Install, Upgrade, Upgrade Tag Mgt. No public entry point | **BLOCKED**: MCC can declare `Record` on the destination table, but the legacy SOURCE data lives in an Internal table it can't read, and there's no public codeunit to call for it either. TU-P1's 2 table-pair rows (seq 1-2) and the Customer/Cust. Ledger Entry field-restore row (seq 3, on standard tables) — only seq 3 is currently Direct-viable |
| FE (Facturacion Electronica) | Yes, pervasive: 38 of the real "EF*" migration-target tables (EFAdministrationSetup, EFArchivedEDocuments, EFEncabezado, EFCodigosItem, etc. — confirmed these are exactly the tables FE-P11's ~30 legacy-table-restore concepts target) are `Access = Internal` on the active side (plus their `.old` legacy counterparts, ~70 of 104 table files total) | **Yes — ALL 15 of FE's migration-namespace codeunits are Access=Internal**: `DXR_Migr. Dispatcher` (52537), Phase 7 Bootstrap through Phase 13 NCF Cleanup (52539-52543, 52522, 52525), Failure Handler, Phase Tags, Scheduler, Status Mgt., Upgrade/Upgrade Tags, Legacy Reject Bg Runner. No public entry point | **BLOCKED** for the large majority of FE's concepts (all of FE-P7, FE-P11, FE-P12, FE-P13, and the table-restore rows within P9/P10) — largest blocked surface in the portfolio by concept count. FE-P8/P9/P10's field-level rows (Currency, Item, Post Code, UOM, VAT Posting Setup, Purch./Sales Header/Line field additions on standard tables) remain Direct-viable since those extend standard BC tables |
| SD (Special Dispatch) | 1 of 11 target tables: `DXR_SD_Migr_Status` (SD-P2 seq2's destination, table pairing 59114->54778) — the other 10 field-restore targets (Customer, Sales Header, Sales/Warehouse Shipment Header, Gen. Journal Line, User Setup, LSC Store) are standard BC tables, not internal | Yes — all 5 of SD's migration codeunits (`DXR_SD_Migr_Phase_Dispatcher` 54779, Phase1_FieldDup, Phase2_LegacyTable, InstallCodeunit, Scheduler) are Access=Internal | **Direct** for 10 of 11 concepts (standard-table field restores + the Migr Status table's own destination is reachable, but its own SOURCE table 59114 needs checking — not yet confirmed internal). One exception flagged: no public entry exists if `DXR_SD_Migr_Status` turns out to need Thin-Wrapper too |
| DESB (Despacho Base) | 1 of 113 target tables: `DXRDespachoPhase1RdyBuf` (a Phase-1 readiness buffer table, isolated) | **Yes — ALL 7 of DESB's migration codeunits are Access=Internal** (re-verified against every file in `src\Base\Codeunits\Upgrade\`): `DXR_Despacho Migr Dispatcher` (53669), `DXR_Despacho Migr Phase 1` (53670), `DXR_Despacho Migr Phase 2` (53908), `DXR_Despacho Migr Retry Mgt` (53671), `DXR_Despacho Migr Scheduler` (53672), `DXR_Despacho Migr Worker` (53681), `DXR_Despacho Phase1 Readiness` (53909). No public entry point exists anywhere in the migration namespace | **Direct** for 112 of 113 tables (overwhelming majority — same class as the confirmed BELLON baseline). One exception flagged (buffer table) with no public entry currently, low priority since it's a working buffer, not user data |
| BELLON (Bellon Customization) | No — 1 isolated match in entire source, not on a table (confirmed pre-existing per brief) | N/A | **Direct** (confirmed reference case) |
| BELLONPOS (Bellon Customization POS) | No — 0 table-level hits. The 1 hit found in Step 1's broader source scan is on `BellonPOSMigrationLockMgt.Codeunit.al` (a lock-management codeunit, not a table) | N/A (no internal target tables to wrap) | **Direct** |
| LSLOC (LS Central DR Localization) | No — 0 table-level hits (8 general source hits, none on `*.Table.al`/`*.TableExt.al`) | N/A | **Direct** |
| VP (Vendor Payloads) | No — 0 table-level hits (21 general source hits, none on tables) | N/A | **Direct** |
| DPP (DescuentoProntoPago) | No — 0 hits anywhere in source | N/A | **Direct** (separate, unrelated concern: its one live concept, DPP-UPG, is `Subtype = Upgrade` and can't be invoked via `Codeunit.Run()` — a scheduling constraint, not an Access=Internal one) |
| RBPD (RecaudoBPD) | No — 0 table-level hits (3 general hits, none on tables) | N/A | **Direct** |
| DXP (DXPAYMENT-BC) | No — 0 table-level hits (7 general hits, none on tables) | N/A | **Direct** |
| DESLS (Despacho LS) | No — 0 table-level hits (3 general hits, none on tables) | N/A | **Direct** |
| LSFE (LS Facturacion Electronica) | No — 0 table-level hits (5 general hits, none on tables) | N/A | **Direct** |
| RES (Retail Email Sender) | No — 0 hits anywhere in source | N/A | **Direct** |
| BANKREC (DX Bank Reconciliation) | No — 0 table-level hits (6 general hits, none on tables) | N/A | **Direct** |
| VPAPI (VendorPay API) | No — 0 table-level hits (1 general hit, not on a table) | N/A | **Direct** |

## Summary counts (21 extensions)

- **Direct** (no internal tables, or only trivially isolated ones with no viable
  wrapper needed): LSLOC, VP, DPP, RBPD, DXP, BELLON, BELLONPOS, DESLS, LSFE, RES,
  BANKREC, VPAPI = **12**
- **Direct with one flagged exception table** (overwhelming majority of tables are
  fine; a single table has no viable access path at all right now): SD, DESB = **2**
- **Thin-Wrapper, viable today** (internal tables, but a public codeunit exists to
  call): DRLOC, PCM, ES = **3**
- **Blocked** (internal tables AND every migration codeunit in the namespace is also
  Access=Internal — no adapter of either shape can be written until the source
  extension exposes one public procedure): BC, RC, TU, FE = **4**

12 + 2 + 3 + 4 = 21.

## Self-review

- Every one of the 21 currently-registered extensions (cross-checked directly against
  `LoadExtensions()`'s `InsExt` calls in `src\DXRMCCRegistryLoader.Codeunit.al`, not
  the brief's own 13-item bash loop, which predates Task 0.1's 4 additions and also
  never listed RBPD/DXP/PCM/TU/DESB/BELLON/BELLONPOS/DESLS/FE/LSFE by their real
  top-level folder names) has a row above.
- DRLOC is Thin-Wrapper and BELLON is Direct, matching the two pre-confirmed reference
  points exactly, including DRLOC's dispatcher-access claim being independently
  re-verified here (not just cited) since it's this whole audit's founding assumption.
- For every extension with 1+ table-level Access=Internal hits, its own migration
  codeunit(s) were checked (not just the top-level dispatcher — every codeunit in the
  migration namespace), per Step 2's instruction. Four extensions (BC, RC, TU, FE) came
  back with EVERY codeunit internal — a materially different, more restrictive
  situation than DRLOC's, so they're marked "Blocked" rather than "Thin-Wrapper" to
  avoid later tasks assuming a wrapper call is possible when it currently is not.
- BC's finding is not fully uniform (5 of 6 setup tables internal, 1 not) — this was
  investigated directly (confirmed by reading `PurchaseControlsSetup.Table.al` in
  full) rather than left as a guess; it is a clean majority/exception split, not
  genuine ambiguity, so it did not require escalation.
- TU's finding is asymmetric (source internal, destination not) — also investigated
  directly by reading both table files' `table` declarations and IDs to confirm they
  correspond to the exact IDs TU-P1's registry concept uses (57304/57305 ->
  53601/53602).
