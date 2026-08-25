codeunit 60012 "DXR MCC Registry Loader"
{
    // Manual, idempotent seed-data loader for the Extension (60000) and Concept (60001) registries.
    // Not an Upgrade-subtype codeunit - this hub has no schema of its own to upgrade, only its own
    // reference data to (re)populate. Invoked via the "Reload Registry" action on page 60020.
    // Concepts whose Legacy/New Table ID are both 0 and have a real dispatcher are field-level
    // migrations: row counts are not a meaningful gap signal, so Counter marks them Not Row-Based.
    // Rows with no dispatcher and no table IDs are historical/informational markers and are
    // Skipped; they must never be presented as if MCC had verified a runtime migration.
    // Order No. is the operator-approved portfolio migration sequence. Values 10..190 preserve
    // the exact dependency order (Localization Base through Bellon Customization POS); 170 is
    // deliberately reserved for Mail Connector, which has no authoritative registry code,
    // App ID, concepts, or local adapter in this repository yet. Additional registered modules
    // not present in that approved sequence use 900+ so they never interleave with it.
    //
    // Category (added 2026-08-22, alongside Run All Setup/Master-Accounting/Historic on page
    // 60020): classifies each concept by the KIND of table(s) it moves data for, so those three
    // actions - and Run Portfolio's own restructured Setup-then-Master/Accounting-then-Historic-
    // then-Other pass order - can filter across the whole portfolio instead of only within one
    // extension. 'SETUP'/'MA'/'HIST'/'OTHER' short codes below map onto the Category option
    // (Setup/"Master/Accounting"/Historic/Other) via CategoryOption() - kept as short call-site
    // text rather than the Option's own '::' syntax because that requires a typed variable in
    // scope and would make this already-long call list far harder to scan. 'OTHER' is the honest
    // answer for any concept whose own single dispatcher genuinely spans more than one category in
    // one sweep (a phase-level dispatcher covering Setup + transactional + historic tables
    // together) - see the Category field's own comment on table 60001 for why those are excluded
    // from the three category-specific actions rather than force-fit into one.
    //
    // FULL-PHASE COVERAGE PASS (2026-08-22): the user found several extensions were only tracking
    // a SUBSET of their real migration phases (a phase-level dispatcher summarized in one row, or
    // a whole phase missing from the registry entirely - e.g. Special Dispatch's Phase 3 permission
    // repair, Bellon's Phase 2/4/11/12, Vendor Payloads' Phase 1-6, DXPAYMENT-BC's Phase 1-4, Retail
    // Controls' Phase 1-4, Base Controls' Phase 1). A 7-way parallel audit (one read-only pass per
    // extension cluster) confirmed every gap below against the actual dispatcher/phase codeunit
    // source, not assumption. IMPORTANT CONSTRAINT applied throughout this pass: an existing
    // (Extension Code, Phase Code, Sequence No.) triple is NEVER reused for a different logical
    // item and NEVER renumbered - InsConcept matches/updates by that exact triple, so changing it
    // would leave the old row as a permanent orphan instead of updating it. Every correction below
    // updates an existing triple in place (Description/Dispatcher/Table IDs/Category only); every
    // new item gets a brand new Sequence No. continuing after that extension's prior max. A few
    // large phases (Bellon Phase 6/7/10, most of DRLOC's per-table IDs, FE's field-map-driven
    // phases, LSLOC's 3 delegate codeunits) could not be safely expanded to full per-table
    // granularity in this pass - the source audit found real per-table lists but could not resolve
    // every numeric Legacy/New Table ID with full confidence in the time available, and this
    // registry would rather stay honest about a gap than risk a wrong table ID in a system whose
    // explicit purpose is guaranteeing no data loss. Those are called out with an inline "IDs
    // pending" or "needs follow-up read" note rather than a guessed number - do not fill in a guess
    // later without re-reading the actual source procedure.

    trigger OnRun()
    begin
        LoadExtensions();
        LoadConcepts();
        UnblockDespachoBase();
    end;

    local procedure LoadExtensions()
    begin
        InsExt('BC', 'Base Controls', 'e8b1de99-1c7d-454d-b0bc-7cc1dc7b86ae', 90, '');
        InsExt('DRLOC', 'Base App DR Localization', 'b269ef93-1340-452e-bc44-732c5dacd1c8', 10,
            'FOUNDATION extension. 28.3.5.3: fixed 118 NCF/fiscal field cross-table ID collisions (Sales+Purchase families) causing live TransferFields crash. All 7 dependents recompiled clean against it: Bellon Customization, Despacho Base, Despacho LS, Facturacion Electronica, LS Facturacion Electronica, LS Central DR Localization, TransUnion. CORRECTION (2026-08-22): earlier same-day work briefly changed DXR_Cash Journal Receipt List/DXR_Gaps Setup table IDs from 52132/52165 to 54184/54195, reasoning from git history alone that the renumber had drifted off true production - the user confirmed 52132/52165 IS what''s actually deployed (changing them broke publish with a metadata error) and explicitly asked for the IDs to stay untouched; reverted, DO NOT change these two IDs again without new evidence from an actual deployment error, not git archaeology. The real DescuentoProntoPago problem (see DPP''s note) was a stale local .alpackages cache, unrelated to these IDs.');
        InsExt('LSLOC', 'LS Central DR Localization', 'b18ab944-2133-4326-bcd7-a235e0a8bdef', 20,
            'Depends on Base App DR Localization, LS Central. 28.3.3.5: recompiled clean against DRLOC 28.3.5.3 (no live NCF call-site fixes needed here). CORRECTION: earlier note claiming zero migration infrastructure was wrong (bad grep path). Full dispatcher/lock/status-page system already exists (DXR_LS Migr. Dispatcher, gated by DX28PREFIX, which is enabled), covering all ~20 Base\old\ legacy objects across 3 phases. requerimiento-normalizacion-al-controlada.md explicitly excludes Tables.old/TableExts.old/Enums.old from naming normalization, but that never blocked this data migration. 2026-08-22: fixed 2 on-prem-only pageextension defects (LSDXConsumer607Ext/LSDXSales607Ext extending a nonexistent object name, latent - app targets Cloud only).');
        InsExt('VP', 'Vendor Payloads', 'f64305eb-aae2-4479-8726-e604fe48c051', 110, '');
        InsExt('DPP', 'DescuentoProntoPago', 'ce7641c4-fd8b-4c0c-960b-32b3eaf255c7', 900,
            '2026-08-22: TableExtensions 54285/54286 (Cash Journal Receipt List/Gaps Setup) were failing to deploy with "field removal not allowed" on every field - 2 fix attempts needed. 1st attempt (wrong): assumed a stale local .alpackages cache, refreshed it, compiled clean locally - but a SECOND live deployment (job 150ad38e-3ca5-45a9-9480-be9519b87411) failed the exact same way on 28.5.5.3, proving local compile success against symbols does not validate a live tenant''s actual deployed schema. TRUE ROOT CAUSE (confirmed via that 2nd error, not git archaeology): these DPP fields are deployed against the LEGACY tables "DXCash Journal Receipt List"/"DXGaps Setup" (Tables.old in DR-Localization, ObsoleteState=Pending), not the active "DXR_Cash Journal Receipt List"/"DXR_Gaps Setup" - proven by "DPP Gaps Setup"''s own TableExt object NAME already exactly matching the tenant''s reported name yet still failing, isolating the cause to extends-target, not naming. Fix (28.5.5.4): retargeted both TableExtensions to the legacy tables; moved the 3+7 fields'' display off the active-table pages (DXR_Journal Receipt List/DXR_Gaps Setup) onto 2 new standalone legacy pages; retyped the 4 codeunit/report files that read/write these fields to the legacy Record types (2 of those are DR-Localization event-subscriber signatures that must stay typed on the active table by contract - those use a separate legacy-table Record matched by "Document No.", the shared sole primary key, with a RecordRef-based get-or-insert that copies every matching standard field by number so downstream Document No./Posting Date/Account No. lookups still find the row). DR-Localization''s own table IDs were NOT touched, per explicit instruction - see DRLOC''s note. Registry correction: this extension''s previously-registered DPP-P5/DPP-P6 concepts (dispatcher IDs 53650/53652) do not exist anywhere in this repo''s source - retired in place, replaced by DPP-UPG which reflects the one real migration action that does exist.');
        InsExt('RBPD', 'RecaudoBPD', '', 910, '');
        InsExt('SD', 'Special Dispatch', '18373840-6093-4765-8799-491f61accb2b', 160,
            '28.3.3.7: fixed the same class of bug as DESB/PCM - the 2026-08-18 global ID renumber had changed both the true production field IDs AND their names (BC schema sync requires both to stay identical to what''s deployed, confirmed via AppSourceCop AS0005 "Fields must not change name" - not ID-only as first assumed) across all 8 tableextensions, and had also renumbered the tableextension object IDs themselves off their true originals. Both layers reverted to true production values (traced via git history back to the pre-renumber commit); recompiled clean. 2026-08-22: found Phase 3 (permission set assignment, inline in dispatcher 54779) entirely unregistered, and Phase 1''s single row was collapsing 8 distinct table field-restores into one description - both fixed below.');
        InsExt('DXP', 'DXPAYMENT-BC', '36b9c68f-cc27-46b1-bf63-4400a31c5f61', 130,
            '2026-08-22: found Phases 1-4 (52310/52311/52312/52321) entirely unregistered - only Phase 5/6 were tracked. Phase1/3/4 all restore the same 9 payment/promotion tables across 3 different legacy generations (pre-DXR, exhausted-SaaS-range DXR_, and a 3rd renumber). RESOLVED 2026-08-23: confirmed Phase 5 (the most recent generation) is the business-confirmed source of truth on any key shared with Phase 1/3 - fixed at the source (this extension''s own repo): Runner reordered to run Phase 5 first, plus a retroactive-repair pass (own Upgrade Tag) for companies that already ran the old order. All 46 concepts now dispatch through "DXR MCC Adapt DXP Dispatcher" (60020), a typed reference to this extension''s Runner (52313).');
        InsExt('PCM', 'Price Controls Mgt.', '0ef94c34-cbc6-41d8-ab1a-258e9085707d', 150,
            '28.3.4.7: same class of bug as SD/DESB (field name+ID both drifted from true production by the 2026-08-18 renumber). Fixed via the "restore legacy shell as a separate parallel tableextension at the true original id+name" pattern (Phase 5 codeunit "DXR_Migr. Phase 5 Id Renum", 54620) for Workflow (the one table whose true field was genuinely lost) - but discovered the OTHER 6 restored shells (ApprovalEntry/Customer/SalesHeaderSnapshot/SalesLine/SalesLineSnapshot/StorePrcGrp) were redundant duplicates: their true fields were already correctly preserved at true id+name inside the active tableextension all along, and the separate shell just caused an AL0155 "already defined" collision once its field names were corrected to match. Removed those 6 redundant shells; kept only Workflow''s. Recompiled clean. 2026-08-22: found 3 entire sibling phases (Phase 2/3/4, dispatchers 54612/54613/54614) unregistered - the dispatcher "DXR_Migr. Phase Dispatcher" (54615) runs all 4 phases in sequence, only Phase 5 was tracked.');
        InsExt('TU', 'TransUnion', '7c42bd17-42ea-4c0a-b6db-e7034ad57faf', 140,
            'Depends on Base App DR Localization. 28.3.2.5: recompiled clean against DRLOC 28.3.5.3, no live call-site fixes needed. Closes out this session''s dependent-recompile sweep. 2026-08-22: audited for phase completeness - already complete, its single dispatcher (53605) and 3 registered concepts match its actual 3-loop source exactly.');
        InsExt('DESB', 'Despacho Base', 'c7a48d32-662c-4e8a-a315-494b174556cf', 50,
            '28.3.4.17: same class of bug as SD/PCM, but on a much larger surface (28 table extensions, 29 fields, plus 4 more table extensions - SalesHeaderExt/SalesLineExt/TransferHeaderExt/DXRDESalesInvLineExt - carrying the separate TransferFields collision fix, which needed the same id+name true-original treatment on top of its own existing _Old2/_Reloc relocation logic). Also found and fixed 2 rounds of collateral damage from the bulk field-name revert: (1) the ACTIVE "Despachador" table (53868) got its own object name wrongly reverted to the LEGACY table''s name ("DXR-DE Despachador", table 50807), causing an AL0197 duplicate-object-name collision, requiring ~30 file scoped re-fixes across Pages/Reports/PermissionSet/other Tables to restore correct old-vs-new references; (2) two Codigo Auditoria fields (TransferHeaderExt/TransferReceiptHdr/DXRDETransferShptHdrExt) turned out to actually be Code[20] in the real deployed tenant, not Code[10] as this repo''s earliest committed history showed - BC''s own "reduced length" deployment error was the ground truth there, not git archaeology; widened accordingly (never reduce - only widen when the two disagree). Recompiled clean. 28.3.4.19 (2026-08-22): fixed a real write-transaction crash in "DXR_Despacho Migr Dispatcher".RunPendingPhasesWithStatusTracking - StartPhase()''s own Modify(true) was left open when Codeunit.Run()''s return value was used right after it, with no Commit() between; this is the SAME codeunit MCC calls for every DESB-P1 concept (dispatcher 53681 -> Worker -> this procedure), so it was very likely the real cause behind "Run All Setup moves nothing for Despacho Base." Also found the permission-set-assignment step (in Worker 53681) entirely unregistered.');
        InsExt('BELLON', 'Bellon Customization', 'a9734a52-02bb-4e3d-8150-2f9ee4b50530', 180,
            'Depends on Base App DR Localization. 2026-08-22: found 4 entire phases unregistered (Phase 2/4/11/12, dispatchers 56119/56121/56128/56129) out of an 11-phase chain (Phase 2 through Phase 12, no standalone Phase 1 - it''s just a completion-tag gate). Phase 2 alone covers 174 individual table/field-group restores (103+4 table pairs, 67 tableextension field groups), added below in full. Phase 6 (111 tables, same set as Phase 2''s 103-table batch but from a second renumbering incident, IDs 59231-59345->53301-53415 sequential) and Phase 7 (its real table count doesn''t reconcile against the registry''s "87" - audited at 55) and Phase 10 (188 fields/14 tables, not independently confirmed as the same 14 tables as Phase 3''s dedup list) are flagged with their existing summary row corrected to note the caveat rather than expanded to guessed per-table rows - see each row''s own text for what still needs a follow-up read before it can be split safely.');
        InsExt('BELLONPOS', 'Bellon Customization POS', '6b2c910b-6607-4ffa-859e-1ba16790e4d8', 190,
            'Depends on Bellon Customization, LS Central, Retail Controls, Facturacion Electronica, LS Facturacion Electronica, DX-Payments, Base Controls. Standalone migration dispatcher/lock/status infra ("Bellon POS Phase Dispatcher", cod. 56205), same architecture as BELLON but far smaller scope: Phase 1 (base, pre-existing) + Phase 2 only (Legacy Norm, cod. 56212). 2026-08-22: Phase 2 was under-described - it also restores 3 legacy tables (50300/50301/50302->53563/53564/53565) not mentioned in the old registry text at all; added below (table names not yet resolved from source, IDs are confirmed).');
        InsExt('DESLS', 'Despacho LS', 'adb067e6-0e65-4ab0-8d61-160e7df7763f', 60,
            'COMPILES CLEAN as of 28.3.2.10. 2026-08-22, two real bugs found here (not just a stale symbol cache like most of this session''s other repos): (1) this repo''s OWN "Normalizacion despacho LS" commit had retargeted 10 of its 11 tableextensions from extending Despacho Base''s legacy tables to the active ones while correctly duplicating fields, then a later renumber commit moved the object IDs too - both drifts fixed by splitting each into a legacy-extending (true id, old field, Pending) + active-extending (new field) pair, mirroring the DESB/SD/PCM fix pattern. (2) "DXR_Desp LS Migr Phase 1" (53924) was rewritten to read each old field from its true legacy table via RecordRef (was previously reading a single, now cross-table-broken, typed record) - this needs Read permission on those 10 legacy tables, which "DXR_Desp LS Migr Worker" (53963, the actual TaskScheduler/page entry point - Permissions propagate down its call stack to Phase 1) did not have; added. GENERAL LESSON for the whole portfolio: any extension depending on Despacho Base/Special Dispatch/Price Controls Mgt. needs its own local .alpackages copy refreshed after ANY change to that dependency, not just after a naming/object rename - a stale symbol cache reproduces the dependency''s old (already-fixed) schema errors even though the dependency itself is fine. 2026-08-22: found Phase 1 (53924, 14 field-restore tables) entirely unregistered - the 2 existing rows are a DIFFERENT phase (the renumbered-table restore inline in Worker 53963), both correct, kept as-is.');
        InsExt('RC', 'Retail Controls', '', 100,
            'Depends on Base Controls. 2026-08-22: found Phases 1-4 (54734/54744/56502/56504) entirely unregistered - only Phase 5 was tracked. Phase 3 is a real retroactive fix (field-ID collision across 6 tableextensions), same class of bug as DESB/SD/PCM elsewhere in this portfolio.');
        InsExt('FE', 'Facturacion Electronica', '4ccf94f0-8e86-437f-99fc-a4eeda4a5122', 30,
            'Depends on Base App DR Localization. 28.3.5.1: fixed 4 dangling NCF field refs (Sales Invoice/Cr.Memo Header _DXR->_DXR_V2) after DRLOC 28.3.5.3. 7-phase dispatcher (Phase 7 Bootstrap - Phase 13 NCF Cleanup), own DXR_Migration Status page already implements the Run Migration Now pattern. 2026-08-22 follow-up completed: P7''s earlier "may be a no-op" suspicion was confirmed real - DXR_Upgrade_Clean.Codeunit.al''s MigrateLegacyDependencyTableFields had wrong target field numbers (55501-55504 instead of the real 52333/52334) for all 4 of its table pairs (NCF Purchase/Sales/general Setup, Payment Method Relation), so it ran "successfully" (tag set) while copying zero data - confirmed by the user hitting exactly this on DXR_Payment Method Relation. Fixed in EF 28.3.6.1 (corrected field numbers + tag bumped to DXR-EF-LEGACY-DEPS-20260822 to force re-run) and split into 4 individually-tracked rows here (FE-P7 seq1/304-306) instead of one opaque "Phase 7 Bootstrap" bucket. P8/P9/P10 also expanded to one row per table (seq2-4, 307-319), read directly from each phase''s own CopySameTableFields FieldMap.Add() calls - none of those had the wrong-field-number bug (only the Phase 7 dependency-migration procedure did).');
        InsExt('LSFE', 'LS Facturacion Electronica', '4e2e9532-7e97-4f5e-af6e-1b5f2e51b9e2', 40,
            'Depends on Facturacion Electronica, LS Central DR Localization, Base App DR Localization. 28.5.0.3: fixed same NCF dangling refs after dependency chain refresh. Own DXR_LSFE Migration Status page already implements the Run Migration Now pattern (2 background repairs: PermSet assignment, POS contingency + legacy field migration). 2026-08-22: audited - LSFE-P2''s description bundles 2 things but its source is one inline OnRun trigger with no separable sub-steps found; left as one row rather than splitting blind.');
        // 2026-08-24 (Task 0.1, Phase 0 registry-completeness audit): 4 extensions confirmed to have
        // real DXR_ migration surface (ObsoleteReason.*DXR_/_DXR" hits in their source) but were
        // entirely missing from this registry until now. Only seeded here - no concepts yet, that's
        // a later task. VendorPay_TXT (sibling of VendorPay_API under vendorpayload\DxPayloads-BC\)
        // is explicitly excluded per direct user ruling, not evaluated.
        InsExt('ES', 'Base Email Sender', '40bf4f60-a31e-4104-a36c-bc3b36f8c9ed', 70, '');
        InsExt('RES', 'Retail Email Sender', '85fc1f3a-6b23-4f45-8465-c5067449b097', 80,
            'Depends on Base Email Sender, LS Central, LS Central System App.');
        InsExt('BANKREC', 'DX Bank Reconciliation', '3f45e9d8-89f4-4be2-b687-f69908d8ad63', 920, '');
        InsExt('VPAPI', 'VendorPay API', '1dda7edb-4946-4c91-a426-810b5635ddad', 120,
            'Depends on Vendor Payloads (VP).');
    end;

    local procedure LoadConcepts()
    begin
        // ---- BC: Base Controls (Phase 1 gen-1 legacy restore + Phase 2 current + Phase 3 fields + Perm repair) ----
        InsConcept('BC', 'BC-P2', 1, 'Warehouse Controls Setup: legacy row restore', 60092, 56407, 54798, 'SETUP');
        InsConcept('BC', 'BC-P2', 2, 'Purchase Controls Setup: legacy row restore', 60093, 56408, 54800, 'SETUP');
        InsConcept('BC', 'BC-P2', 3, 'Sales Controls Setup: legacy row restore', 60094, 56409, 54802, 'SETUP');
        InsConcept('BC', 'BC-P2', 4, 'Vendor Controls Setup: legacy row restore', 60095, 56410, 54804, 'SETUP');
        InsConcept('BC', 'BC-P2', 5, 'Transfer Controls Setup: legacy row restore', 60096, 56411, 54806, 'SETUP');
        InsConcept('BC', 'BC-P2', 6, 'Customer Controls Setup: legacy row restore', 60097, 56412, 54807, 'SETUP');
        InsConcept('BC', 'BC-P2', 7, 'Migr Status history restore', 60098, 56413, 54810, 'HIST');
        InsConcept('BC', 'BC-P3', 8, 'Customer: Mandatory Order No./Exp. Exemption Card/Reference Address field restore (3 fields)', 60099, 0, 0, 'MA');
        InsConcept('BC', 'BC-P3', 9, 'Item: Payment Terms Code/Allow Decimals field restore (2 fields)', 60100, 0, 0, 'MA');
        InsConcept('BC', 'BC-P3', 10, 'Sales Header: Reference Address field restore', 60101, 0, 0, 'MA');
        InsConcept('BC', 'BC-P3', 11, 'Warehouse Receipt Header: Customer/Vendor No./Name field restore (4 fields)', 60102, 0, 0, 'MA');
        InsConcept('BC', 'BC-P3', 12, 'Warehouse Shipment Header: Customer/Vendor No./Name field restore (4 fields)', 60103, 0, 0, 'MA');
        // CORRECTED 2026-08-22: these 6 rows had Legacy Table ID = 0 even though dispatcher 54858
        // genuinely reads from these gen-1 tables (confirmed via direct source read of "DXR_BC
        // Migr Phase 1.Codeunit.al") - meant MCC never counted/gap-checked them. Real IDs added;
        // no ID-to-name sequential order (verified each against its own file, not assumed).
        InsConcept('BC', 'BC-P1', 13, 'Warehouse Controls Setup: legacy row restore (gen-1, "DXR Warehouse Controls Setup" 56401 -> active "DXR_Warehouse Controls Setup" 54798, runs before Phase 2)', 60086, 56401, 54798, 'SETUP');
        InsConcept('BC', 'BC-P1', 14, 'Purchase Controls Setup: legacy row restore (gen-1, "DXR Purchase Controls Setup" 56406 -> active "DXR_Purchase Controls Setup" 54800)', 60087, 56406, 54800, 'SETUP');
        InsConcept('BC', 'BC-P1', 15, 'Sales Controls Setup: legacy row restore (gen-1, "DXR Sales Controls Setup" 56402 -> active "DXR_Sales Controls Setup" 54802)', 60088, 56402, 54802, 'SETUP');
        InsConcept('BC', 'BC-P1', 16, 'Vendor Controls Setup: legacy row restore (gen-1, "DXR Vendor Controls Setup" 56404 -> active "DXR_Vendor Controls Setup" 54804)', 60089, 56404, 54804, 'SETUP');
        InsConcept('BC', 'BC-P1', 17, 'Transfer Controls Setup: legacy row restore (gen-1, "DXR Transfer Controls Setup" 56403 -> active "DXR_Transfer Controls Setup" 54806)', 60090, 56403, 54806, 'SETUP');
        InsConcept('BC', 'BC-P1', 18, 'Customer Controls Setup: legacy row restore (gen-1, "DXR Customer Controls Setup" 56405 -> active "DXR_Customer Controls Setup" 54807)', 60091, 56405, 54807, 'SETUP');
        InsConcept('BC', 'BC-PERM', 19, 'Permission set assignment repair (all users, DXR_BaseControls)', 60104, 0, 0, 'OTHER');

        // ---- DRLOC: Base App DR Localization ----
        InsConcept('DRLOC', 'DRLOC-P2', 1, 'RETIRED 2026-08-24: this coarse row bridged to DR-Localization''s own dispatcher (52208) via Codeunit 60069 - superseded now that Phase 2''s entire real scope (48 actions, seq9-18/93-106/etc.) is natively ported into MCC codeunit 60165. Keeping this row pointed at 60069 would still invoke DRLOC''s own dispatcher (and its EnsurePhase1Completed hard-block) every run, exactly the cross-repo bridge dependency this whole campaign exists to eliminate. Retired in place rather than deleted, matching the DPP-P5/DPP-P6 precedent above.', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P3', 2, 'RETIRED 2026-08-24: superseded now that Phase 3''s entire real scope (12 actions, seq19-30) is natively ported into MCC codeunit 60167. Same bridge-elimination reasoning as DRLOC-P2 seq1 above.', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P4', 3, 'RETIRED 2026-08-24: superseded now that Phase 4''s entire real scope (9 actions, seq31-39) is natively ported into MCC codeunit 60168. Same bridge-elimination reasoning as DRLOC-P2 seq1 above.', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P5', 4, 'RETIRED 2026-08-25: coarse bridge superseded by the native, category-specific Phase 5 concepts.', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P6', 5, 'RETIRED 2026-08-25: coarse bridge superseded by the native, category-specific Phase 6 concepts.', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-NCF', 6, 'RETIRED: Sales-family NCF cross-table field-ID schema correction (20 fields); runtime field restoration is tracked by DRLOC-P4 seq31-33', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-NCF', 7, 'RETIRED: Purchase-family NCF cross-table field-ID schema correction (98 fields); runtime field restoration is tracked by DRLOC-P3 seq19-24', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P1', 8, 'Internal Closure Migration (Subtype=Upgrade, hard blocking prerequisite that Phase 2-6''s dispatcher checks via EnsurePhase1Completed - Codeunit.Run() cannot invoke it outside schema-sync; mark Blocked with this reason, it runs on its own publish/upgrade cycle only)', 0, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P2', 9, 'Bootstrap: CompanyInformation fields', 60165, 0, 0, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 10, 'Bootstrap: BankAccount/Customer/Vendor fields', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 11, 'Bootstrap: GL/UserSetup/Journal fields', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 12, 'Bootstrap: NCF Setup tables', 60165, 0, 0, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 13, 'Payment Method Relation legacy table restore (54133 -> 52180)', 60164, 54133, 52180, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 14, 'Item NCF Category backfill (V27 data)', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 15, 'DGII-RNC Database legacy table restore (54119 -> 52156)', 0, 54119, 52156, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 16, 'NAV POS Customer legacy table restore (54128 -> 52175)', 60165, 54128, 52175, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 17, 'Extract Cards legacy table restore (54120 -> 52160)', 60165, 54120, 52160, 'MA');
        InsConcept('DRLOC', 'DRLOC-P2', 18, 'Gubernamentales(623) legacy table restore (54155 -> 52220)', 60165, 54155, 52220, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 19, 'Purchase Header field restore (bulk)', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 20, 'Purchase Line field restore (bulk + FlowFields)', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 21, 'Purch. Inv. Header field restore (bulk + FlowFields + special conversions)', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 22, 'Purch. Inv. Line field restore', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 23, 'Purch. Cr. Memo Hdr field restore (bulk + FlowFields)', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 24, 'Purch. Cr. Memo Line field restore', 60167, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 25, 'Archived Purchase 606 legacy table restore (54105 -> 52113)', 60167, 54105, 52113, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P3', 26, 'ITBIS Purchase (606) legacy table restore (54125 -> 52169)', 60167, 54125, 52169, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 27, 'Purchase Line Settlement legacy table restore (54139 -> 52193)', 60167, 54139, 52193, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 28, 'Purchase WS Settlement legacy table restore (54141 -> 52196)', 60167, 54141, 52196, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 29, 'Vendor Withholding Header legacy table restore (54144 -> 52202)', 60167, 54144, 52202, 'MA');
        InsConcept('DRLOC', 'DRLOC-P3', 30, 'Withholding Vendor Lines legacy table restore (54149 -> 52211)', 60167, 54149, 52211, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 31, 'Sales Header/Line field restore', 60168, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 32, 'Sales Invoice Header/Line field restore', 60168, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 33, 'Sales Cr. Memo Header field restore', 60168, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 34, 'Cust. Ledger Entry field restore (bulk + FlowFields)', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 35, 'Archived Sales 607 legacy table restore (54106 -> 52115)', 60168, 54106, 52115, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P4', 36, 'ITBIS Sales (607) legacy table restore (54126 -> 52171)', 60168, 54126, 52171, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 37, 'Consumer (02) Sales (607) legacy table restore (54112 -> 52136)', 60168, 54112, 52136, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 38, 'Customer Withholding Lines legacy table restore (54117 -> 52147)', 60168, 54117, 52147, 'MA');
        InsConcept('DRLOC', 'DRLOC-P4', 39, 'Cash Journal Receipt List legacy table restore ("DXCash Journal Receipt List" 54111 Pending -> active "DXR_Cash Journal Receipt List" 52132 - CORRECTED 2026-08-22, was briefly logged here as ->54184, that was wrong, see DRLOC''s Extension Notes)', 60168, 54111, 52132, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 40, 'Bank Account/Check Ledger Entry field restore', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 41, 'G/L Entry/G/L Register field restore', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 42, 'Gen. Journal Line/Item Ledger Entry field restore', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 43, 'Price List Line/Reversal Entry field restore', 60165, 0, 0, 'MA');
        // "+ withholding migration repair" in this description does NOT match real source: that call
        // (DXR_Vend. Withhold Migr Repair.Repair()) lives in DXR_Migr_Phase_5_Ledger's OWN main-line
        // OnRun(), not in RunOrphanedFieldMigrationsRetroactive() - it is intentionally NOT ported
        // into codeunit 60165 (see that codeunit's own header comment, "seq44 naming note"). Only the
        // Bulk+FlowFields field restore is covered by this row/codeunit.
        InsConcept('DRLOC', 'DRLOC-P5', 44, 'Vendor Ledger Entry field restore (bulk + FlowFields)', 60165, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 45, 'Vendor withholding migration repair + Detailed Cust. Ledg. Entry field restore', 60169, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 46, 'Arch. Withholding Gov. Hdr legacy table restore (54108 -> 52120)', 60169, 54108, 52120, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P5', 47, 'Archived Bank Charges Hdr legacy table restore (54102 -> 52107)', 60169, 54102, 52107, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 48, 'Withholding Govern. Header legacy table restore (54147 -> 52207)', 60169, 54147, 52207, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 49, 'V27 data: recent fiscal corrections', 60169, 0, 0, 'MA');
        InsConcept('DRLOC', 'DRLOC-P6', 50, 'API Dgi Setup legacy table restore (54159 -> 52231, via generic MigrateTable(caption,sourceId,destId) loop)', 60170, 54159, 52231, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P6', 51, 'EF Send Registry restore', 60170, 54174, 52247, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 52, 'NCF Fiscal Queue restore', 60170, 54173, 52246, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 53, 'Omitted standard table fields restore', 60170, 0, 0, 'OTHER');
        InsConcept('DRLOC', 'DRLOC-P2', 54, 'Payment Methods 606-607 legacy table restore (54134 -> 52181)', 60165, 54134, 52181, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 55, 'Purchase Type Relation legacy table restore (54140 -> 52242)', 60165, 54140, 52242, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 56, 'Tender Types Relation legacy table restore (54142 -> 52198)', 60165, 54142, 52198, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 57, 'Income Types Setup legacy table restore (54123 -> 52166)', 60165, 54123, 52166, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 58, 'ISR withholding Type legacy table restore (54124 -> 52167)', 60165, 54124, 52167, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 59, 'Type of Income legacy table restore (54143 -> 52200, active field renamed Type of Income_DXR)', 60165, 54143, 52200, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 60, 'Customer Withholding Setup legacy table restore (54118 -> 52152)', 60165, 54118, 52152, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 61, 'Vendor Withholding Setup legacy table restore (54146 -> 52205)', 60165, 54146, 52205, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 62, 'Proporcionality 606 legacy table restore (54137 -> 52188)', 60165, 54137, 52188, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 63, 'Proporcionality Group 606 legacy table restore (54138 -> 52191)', 60165, 54138, 52191, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P2', 64, 'POS-Nav Setup legacy table restore (54136 -> 52185)', 60165, 54136, 52185, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P5', 65, 'Arch. C.C. Charges Header legacy table restore (54100 -> 52259)', 60169, 54100, 52259, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P5', 66, 'Arch. C.C. Charges Lines legacy table restore (54101 -> 52260)', 60169, 54101, 52260, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P5', 67, 'Arch. Withhold. Gov. Lines legacy table restore (54107 -> 52117)', 60169, 54107, 52117, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P5', 68, 'Bank Charges Header legacy table restore (54109 -> 52124)', 60169, 54109, 52124, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 69, 'Cred. Card Charges Header legacy table restore (54113 -> 52140)', 60169, 54113, 52140, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 70, 'Cred. Card Charges Lines legacy table restore (54114 -> 52142)', 60169, 54114, 52142, 'MA');
        InsConcept('DRLOC', 'DRLOC-P5', 71, 'Message Log Table legacy table restore (54127 -> 52173)', 60169, 54127, 52173, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P5', 72, 'Withholding Govern. Lines legacy table restore (54148 -> 52209)', 60169, 54148, 52209, 'MA');
        InsConcept('DRLOC', 'DRLOC-P6', 73, 'Archived Bank Charges Lines legacy table restore (54103 -> 52109 - CORRECTED 2026-08-24: an earlier session wrongly logged this as ->52128 ("shares destination with Bank Charges Lines" - that claim was false, disproven during Phase 6 Batch 2 implementation/review). Real source targets "DXR_Arch Bank Charges Lines" (52109), a DIFFERENT table than seq76''s "DXR_Bank Charges Lines" (52128) - confirmed via direct table-ID declarations in both real .Table.al files.)', 60170, 54103, 52109, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 74, 'Archived Consumer Sales 607 legacy table restore (54104 -> 52111)', 60170, 54104, 52111, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 75, 'Archived Purchase 606 Buffer legacy table restore (54152 -> 52217)', 60170, 54152, 52217, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 76, 'Bank Charges Lines legacy table restore (54110 -> 52128)', 60170, 54110, 52128, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 77, 'Bank Commission Setup legacy table restore (54172 -> 52245)', 60170, 54172, 52245, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P6', 78, 'Cash Receipt Header legacy table restore (54170 -> 52243)', 60170, 54170, 52243, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 79, 'Cash Receipt Line legacy table restore (54171 -> 52244)', 60170, 54171, 52244, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 80, 'Consumer Sales 607 Buffer legacy table restore (54150 -> 52213)', 60170, 54150, 52213, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 81, 'Customer Withholding Entries legacy table restore (54115 -> 52143, active name shortened to DXR_Cust Withhold Entries)', 60170, 54115, 52143, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 82, 'Customer Withholding Header legacy table restore (54116 -> 52144, active name shortened to DXR_Cust Withhold Header)', 60170, 54116, 52144, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 83, 'Dependencies Metadata legacy table restore (54157 -> 52225)', 60170, 54157, 52225, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P6', 84, 'Detalle Servicio Adquirido legacy table restore (54154 -> 52219)', 60170, 54154, 52219, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 85, 'DGI API Services legacy table restore (54160 -> 52233)', 60170, 54160, 52233, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 86, 'DGI API Services FindByName legacy table restore (54161 -> 52234)', 60170, 54161, 52234, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 87, 'DGII Temp Table legacy table restore (54162 -> 52235)', 60170, 54162, 52235, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 88, 'History Purchase Header legacy table restore (54163 -> 52237)', 60170, 54163, 52237, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 89, 'History Purchase Line legacy table restore (54164 -> 52239)', 60170, 54164, 52239, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 90, 'NCF Process Registration legacy table restore (54166 -> 52241)', 60170, 54166, 52241, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 91, 'Purchase Type Relation V27 legacy table restore (54167 "DX Purchase Type Relation" space-variant -> 52242, same destination as DRLOC-P2''s Purchase Type Relation)', 60170, 54167, 52242, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-P6', 92, 'Report Logs legacy table restore (54158 -> 52228)', 60170, 54158, 52228, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 93, 'Report Sales 607 Buffer legacy table restore (54151 -> 52215)', 60170, 54151, 52215, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 94, 'Sending Pay Services Abroad 609 legacy table restore (54156 -> 52222)', 60170, 54156, 52222, 'HIST');
        InsConcept('DRLOC', 'DRLOC-P6', 95, 'Tipo Servicio Adquirido legacy table restore (54153 -> 52218)', 60170, 54153, 52218, 'SETUP');
        // 9 legacy tables found 2026-08-22 with ZERO migration concept anywhere in the prior
        // registry (no dispatcher ever moved their data, no Counter ever checked their row count)
        // - discovered via a full Tables.old/ sweep against every existing InsConcept row.
        // Dispatcher Codeunit ID left 0 deliberately: no dispatcher currently reads these tables,
        // so MCC's own generic Fallback Migrator (a RecordRef row-by-row copy by matching field
        // number) is the only mechanism that will actually move their rows - LogAndCount now
        // triggers that fallback for any real table-pair concept with Dispatcher Codeunit ID = 0
        // (fixed in the Executor the same day this gap was found). "DXGaps Setup" (54122) is very
        // likely the exact "old table has data, new table doesn't" case the user personally
        // observed and reported.
        InsConcept('DRLOC', 'DRLOC-GAP', 96, 'Dx Consumer Totals legacy table restore (54165 -> 52240)', 0, 54165, 52240, 'MA');
        InsConcept('DRLOC', 'DRLOC-GAP', 97, 'DXFiscal Receipt Types legacy table restore (54121 -> 52163)', 0, 54121, 52163, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 98, 'DXGaps Setup legacy table restore (54122 -> 52165) - had ZERO tracking before 2026-08-22, likely the exact gap the user personally observed', 0, 54122, 52165, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 99, 'DXNCF Purchase Setup legacy table restore (54130 -> 52177)', 0, 54130, 52177, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 100, 'DXNCF Sales Setup legacy table restore (54131 -> 52178)', 0, 54131, 52178, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 101, 'DXNCF Setup legacy table restore (54132 -> 52179)', 0, 54132, 52179, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 102, 'DXNCF Categories legacy table restore (54129 -> 52176, active name NCFCategories_DXR)', 0, 54129, 52176, 'SETUP');
        InsConcept('DRLOC', 'DRLOC-GAP', 103, 'DXPayroll Interface Temp legacy table restore (54135 -> 52183)', 0, 54135, 52183, 'HIST');
        // This table restore is already the first sub-step of Phase 5's native vendor-withholding
        // repair. Route the audit row to that same dispatcher instead of running a second generic
        // fallback copy over the same table pair.
        InsConcept('DRLOC', 'DRLOC-GAP', 104, 'Vendor withholding repair: legacy ledger 54145 -> 52204 plus Vendor Ledger Entry field/document-type correction', 60169, 54145, 52204, 'MA');
        // Found 2026-08-22 answering the user's direct question "y lo ncf category de las
        // cuentas, estan?" - G/L Account has field "DXNCF Categories" (Pending, obsolete) whose
        // value needs copying into the active field "NCFCategories_DXR" on the same table row.
        // Confirmed covered functionally (DRLOC-P2's dispatcher 52210 already has G/L Account +
        // both fields in its own Permissions block), but had no own Concept row - added for
        // visibility/audit, same category as the sibling Item NCF Category backfill (seq14).
        InsConcept('DRLOC', 'DRLOC-P2', 105, 'G/L Account: NCF Category field restore (DXNCF Categories -> NCFCategories_DXR, same row)', 60165, 0, 0, 'MA');
        // Found 2026-08-24 (Batch 4 task): DR-Localization's own RunOrphanedFieldMigrationsRetroactive()
        // calls MigrateFields_ApplicationAreaSetup() unconditionally, alongside the other 12 field
        // restores this batch ports, but this table had ZERO registry row anywhere in MCC before now
        // (confirmed via grep, zero matches) - a genuine untracked gap, same class as seq96-104 above.
        InsConcept('DRLOC', 'DRLOC-P2', 106, 'Application Area Setup field restore (Dextra Business Central/LS Central/Empty Labels flags)', 60165, 0, 0, 'SETUP');

        // ---- VP: Vendor Payloads (Phase 1-6 legacy population + Phase 7 Id Cutover, 23 table pairs) ----
        InsConcept('VP', 'VP-P7', 1, 'VP Setup legacy table restore', 60121, 55325, 52684, 'SETUP');
        InsConcept('VP', 'VP-P7', 2, 'VP Payload Header legacy table restore', 60121, 55326, 52687, 'MA');
        InsConcept('VP', 'VP-P7', 3, 'VP Payload Journal Lines legacy table restore', 60121, 55327, 52689, 'MA');
        InsConcept('VP', 'VP-P7', 4, 'VP VendorPay Group legacy table restore', 60121, 55328, 52691, 'SETUP');
        InsConcept('VP', 'VP-P7', 5, 'VP Historic Payload Header legacy table restore', 60121, 55329, 52693, 'HIST');
        InsConcept('VP', 'VP-P7', 6, 'VP Historic Payload Lines legacy table restore', 60121, 55330, 52695, 'HIST');
        InsConcept('VP', 'VP-P7', 7, 'VP Hist VendorPay Group legacy table restore', 60121, 55331, 52697, 'HIST');
        InsConcept('VP', 'VP-P7', 8, 'VP Logs legacy table restore', 60121, 55332, 52699, 'HIST');
        InsConcept('VP', 'VP-P7', 9, 'VP Jounal Bank Account legacy table restore', 60121, 55333, 52701, 'MA');
        InsConcept('VP', 'VP-P7', 10, 'VP Order Item Status legacy table restore', 60121, 55334, 52703, 'MA');
        InsConcept('VP', 'VP-P7', 11, 'VP Order Status Log legacy table restore', 60121, 55335, 52705, 'HIST');
        InsConcept('VP', 'VP-P7', 12, 'VP Bank legacy table restore', 60121, 55336, 52706, 'MA');
        InsConcept('VP', 'VP-P7', 13, 'VP Currency Relation legacy table restore', 60121, 55337, 52707, 'SETUP');
        InsConcept('VP', 'VP-P7', 14, 'VP Carga Masiva Beneficiarios BPD legacy table restore', 60121, 55338, 52708, 'MA');
        InsConcept('VP', 'VP-P7', 15, 'VP Hist Carga Mas Benef BPD legacy table restore', 60121, 55339, 52709, 'HIST');
        InsConcept('VP', 'VP-P7', 16, 'VP Hist Linea Carga Mas Benef BPD legacy table restore', 60121, 55340, 52710, 'HIST');
        InsConcept('VP', 'VP-P7', 17, 'VP Hist. Beneficiarios BPD legacy table restore', 60121, 55341, 52711, 'HIST');
        InsConcept('VP', 'VP-P7', 18, 'VP Lineas Carga Masiva Ben.BPD legacy table restore', 60121, 55342, 52712, 'MA');
        InsConcept('VP', 'VP-P7', 19, 'VP Provincia legacy table restore', 60121, 55343, 52713, 'SETUP');
        InsConcept('VP', 'VP-P7', 20, 'VP API Log Entry legacy table restore', 60121, 55344, 52714, 'HIST');
        InsConcept('VP', 'VP-P7', 21, 'VP Order No Rel Payment legacy table restore', 60121, 55345, 52715, 'MA');
        InsConcept('VP', 'VP-P7', 22, 'VP Response Log legacy table restore', 60121, 55346, 52716, 'HIST');
        InsConcept('VP', 'VP-P7', 23, 'VP Migration Status legacy table restore', 60121, 55347, 52717, 'HIST');
        InsConcept('VP', 'VP-P1', 24, 'VP Setup legacy table restore (gen-1, runs before Phase 7''s own cutover)', 60115, 55300, 52684, 'SETUP');
        InsConcept('VP', 'VP-P1', 25, 'VP Bank legacy table restore (gen-1)', 60115, 55311, 52706, 'MA');
        InsConcept('VP', 'VP-P1', 26, 'VP Currency Relation legacy table restore (gen-1)', 60115, 55312, 52707, 'SETUP');
        InsConcept('VP', 'VP-P1', 27, 'VP Provincia legacy table restore (gen-1)', 60115, 55318, 52713, 'SETUP');
        InsConcept('VP', 'VP-P2', 28, 'VP Payload Header legacy table restore (gen-1)', 60116, 55301, 52687, 'MA');
        InsConcept('VP', 'VP-P2', 29, 'VP Payload Journal Lines legacy table restore (gen-1)', 60116, 55302, 52689, 'MA');
        InsConcept('VP', 'VP-P2', 30, 'VP VendorPay Group legacy table restore (gen-1, + NCF/Memo/Remarks BLOB substep)', 60116, 55303, 52691, 'MA');
        InsConcept('VP', 'VP-P2', 31, 'VP Jounal Bank Account legacy table restore (gen-1)', 60116, 55308, 52701, 'MA');
        InsConcept('VP', 'VP-P2', 32, 'VP Order Item Status legacy table restore (gen-1)', 60116, 55309, 52703, 'MA');
        InsConcept('VP', 'VP-P2', 33, 'VP Order Status Log legacy table restore (gen-1)', 60116, 55310, 52705, 'HIST');
        InsConcept('VP', 'VP-P2', 34, 'VP Order No Rel Payment legacy table restore (gen-1, object name VPOrderNoRelPayment)', 60116, 55319, 52715, 'MA');
        InsConcept('VP', 'VP-P3', 35, 'VP Historic Payload Header legacy table restore (gen-1)', 60117, 55304, 52693, 'HIST');
        InsConcept('VP', 'VP-P3', 36, 'VP Historic Payload Lines legacy table restore (gen-1)', 60117, 55305, 52695, 'HIST');
        InsConcept('VP', 'VP-P3', 37, 'VP Historic VendorPay Group legacy table restore (gen-1, + Memo/Remarks BLOB substep)', 60117, 55306, 52697, 'HIST');
        InsConcept('VP', 'VP-P4', 38, 'VP Carga Masiva Beneficiarios BPD legacy table restore (gen-1)', 60118, 55313, 52708, 'MA');
        InsConcept('VP', 'VP-P4', 39, 'VP Lineas Carga Masiva Ben.BPD legacy table restore (gen-1)', 60118, 55317, 52712, 'MA');
        InsConcept('VP', 'VP-P4', 40, 'VP Hist Carga Mas Benef BPD legacy table restore (gen-1)', 60118, 55314, 52709, 'HIST');
        InsConcept('VP', 'VP-P4', 41, 'VP Hist Linea Carga Mas Benef BPD legacy table restore (gen-1)', 60118, 55315, 52710, 'HIST');
        InsConcept('VP', 'VP-P4', 42, 'VP Hist. Beneficiarios BPD legacy table restore (gen-1)', 60118, 55316, 52711, 'HIST');
        InsConcept('VP', 'VP-P5', 43, 'VP Logs legacy table restore (gen-1)', 60119, 55307, 52699, 'HIST');
        InsConcept('VP', 'VP-P5', 44, 'VP API Log Entry legacy table restore (gen-1)', 60119, 55324, 52714, 'HIST');
        InsConcept('VP', 'VP-P5', 45, 'VP Response Log legacy table restore (gen-1, + Response/Request Body BLOB substep)', 60119, 55323, 52716, 'HIST');
        InsConcept('VP', 'VP-P6', 46, 'Tableextension field cutover: Bank Account/Gen. Journal Line/Post Code/User Setup/Vendor/Vendor Bank Account/Purchase Header (7 tables, _DXR field pairs)', 60120, 0, 0, 'OTHER');

        // ---- DPP: DescuentoProntoPago (registry correction 2026-08-22 - see Extension Notes) ----
        InsConcept('DPP', 'DPP-P5', 1, 'RETIRED 2026-08-22: dispatcher 53650 does not exist anywhere in DescuentoProntoPago-OLD source - this was a stale/incorrect registry entry. See DPP-UPG for the extension''s one real migration action.', 0, 0, 0, 'OTHER');
        InsConcept('DPP', 'DPP-P6', 2, 'RETIRED 2026-08-22: dispatcher 53652 does not exist anywhere in DescuentoProntoPago-OLD source - this was a stale/incorrect registry entry. See DPP-UPG for the extension''s one real migration action.', 0, 0, 0, 'OTHER');
        InsConcept('DPP', 'DPP-UPG', 3, 'Cash Journal Receipt List: DPP Disc. PP Amount restore from DPPDisc. Cash Payment ("DPP Upgrade Manager" 54283/52120102, Subtype=Upgrade - Codeunit.Run() cannot invoke it outside schema-sync; mark Blocked with this reason, it runs automatically on next publish/upgrade only)', 54283, 0, 0, 'HIST');

        // ---- RBPD: RecaudoBPD ----
        InsConcept('RBPD', 'RBPD-P1', 1, 'Cust. Ledger Entry legacy tableextension (DXR-IB Cust. Led) restore', 60105, 0, 0, 'MA');
        InsConcept('RBPD', 'RBPD-P1', 2, 'Gen. Journal Line legacy tableextension (DXR-IB Gen. Jrnl Line) restore', 60106, 0, 0, 'MA');
        InsConcept('RBPD', 'RBPD-P2', 3, 'IbankingSetup legacy table restore ("DXR-IB IbankingSetup" -> "DXR_IbankingSetup")', 60107, 54646, 54665, 'SETUP');
        InsConcept('RBPD', 'RBPD-P2', 4, 'History legacy table restore (Header+Details pair: "DXR-IB IbankingHistoryHeader" 54633 + "...Details" 54628 -> "DXR_IbankingHistoryHeader" 54666 + "...Details" 54667 - Header IDs tracked here, Details moves alongside it)', 60108, 54633, 54666, 'HIST');
        InsConcept('RBPD', 'RBPD-P2', 5, 'PagosProveedores legacy table restore ("DXR-IB PagosProveedores" -> "DXR_PagosProveedores")', 60109, 54638, 54668, 'MA');
        InsConcept('RBPD', 'RBPD-P2', 6, 'ReferenciaPagos legacy table restore ("DXR-IB IbankingReferenciaPagos" -> "DXR_IbankingReferenciaPagos")', 60110, 54642, 54669, 'MA');
        InsConcept('RBPD', 'RBPD-P2', 7, 'RecaudoDocsPendientes legacy table restore ("DXR-IB Recaudo Docs Pendientes" -> "DXR_Recaudo Docs Pendientes")', 60111, 54649, 54670, 'MA');
        InsConcept('RBPD', 'RBPD-P2', 8, 'CashReceiptExt legacy table restore ("DXR-IB Cash Receipt Ext" -> "DXR_Cash Receipt Ext")', 60112, 54655, 54671, 'MA');
        InsConcept('RBPD', 'RBPD-P2', 9, 'MiddlewareSetup legacy table restore ("DXR-IB MiddlewareSetup" -> "DXR_MiddlewareSetup")', 60113, 54657, 54672, 'SETUP');
        InsConcept('RBPD', 'RBPD-P3', 10, 'Middleware Configuration Consolidation (IbankingSetup -> MiddlewareSetup field copy)', 60114, 0, 0, 'SETUP');
        InsConcept('RBPD', 'RBPD-P2', 11, 'History Details legacy table restore ("DXR-IB IbankingHistoryDetails" 54628 -> "DXR_IbankingHistoryDetails" 54667) - found 2026-08-22, the Details half of RBPD-P2 seq4''s Header+Details pair had no row of its own, so its count/gap was never independently tracked', 60108, 54628, 54667, 'HIST');

        // ---- SD: Special Dispatch (dispatcher codeunit IDs verified 2026-08-22 directly against
        // source - this repo's own progress.json claimed 59116/59117/59118, which is stale/wrong;
        // the real ones are 54779 (dispatcher)/54780 (Phase 1)/54781 (Phase 2), all of which were
        // also sitting at the DispatcherCodeunitId=0 placeholder in this registry until now, meaning
        // Run Portfolio/Run All Setup/etc silently skipped Special Dispatch entirely) ----
        InsConcept('SD', 'SD-P1', 1, 'Customer: Special Dispatch field restore (59000->54747)', 60070, 0, 0, 'MA');
        InsConcept('SD', 'SD-P2', 2, 'Phase 2: legacy table restore (DXR_Dispatch Module Setup)', 60071, 59114, 54778, 'SETUP');
        InsConcept('SD', 'SD-P1', 3, 'Sales Header: Special Dispatch field restore (59000->54747)', 60072, 0, 0, 'MA');
        InsConcept('SD', 'SD-P1', 4, 'Sales Invoice Header: Special Dispatch field restore (59000->54747)', 60073, 0, 0, 'HIST');
        InsConcept('SD', 'SD-P1', 5, 'Sales Shipment Header: Special Dispatch field restore (59000->54747)', 60074, 0, 0, 'HIST');
        InsConcept('SD', 'SD-P1', 6, 'Warehouse Shipment Header: Special Dispatch field restore (59000->54747)', 60075, 0, 0, 'MA');
        InsConcept('SD', 'SD-P1', 7, 'Gen. Journal Line: Special Dispatch field restore (59000->54747)', 60076, 0, 0, 'MA');
        InsConcept('SD', 'SD-P1', 8, 'User Setup: Invoice Permission field restore (59000->54747)', 60077, 0, 0, 'SETUP');
        InsConcept('SD', 'SD-P1', 9, 'LSC Store: Print Header Doc. field restore (59000->54747)', 60078, 0, 0, 'SETUP');
        // CORRECTED 2026-08-23: 54779 "DXR_SD_Migr_Phase_Dispatcher" is NO LONGER Subtype=Upgrade -
        // fixed at the source (SD's own repo, commit edfdc91) by removing the Subtype=Upgrade
        // property and the now-illegal empty OnUpgradePerCompany trigger. The dispatcher was also
        // redesigned so all real migration work (Phase 3 permission-set assignment, then Phase 1,
        // then Phase 2) now runs from its own OnRun, invoked via ordinary Codeunit.Run() like any
        // other MCC dispatcher - no schema-sync/publish dependency remains. All 3 SD phases
        // therefore now share this single dispatcher call.
        InsConcept('SD', 'SD-P3', 10, 'Assign DXR_DispatchControls permission set to all users (native local migration in MCC, hardcodes Special Dispatch''s real app ID)', 60079, 0, 0, 'SETUP');

        // ---- DXP: DXPAYMENT-BC ----
        InsConcept('DXP', 'DXP-P5', 1, 'Payment Setup legacy table restore', 60084, 54700, 52275, 'SETUP');
        InsConcept('DXP', 'DXP-P5', 2, 'Promotion Bin Card legacy table restore', 60084, 54701, 52276, 'MA');
        InsConcept('DXP', 'DXP-P5', 3, 'Store Payments legacy table restore', 60084, 54702, 52277, 'MA');
        InsConcept('DXP', 'DXP-P5', 4, 'Payment Process Logs legacy table restore', 60084, 54703, 52278, 'HIST');
        InsConcept('DXP', 'DXP-P5', 5, 'Promo Bin Header legacy table restore', 60084, 54704, 52279, 'MA');
        InsConcept('DXP', 'DXP-P5', 6, 'Promotion Bin Items Lines legacy table restore', 60084, 54705, 52280, 'MA');
        InsConcept('DXP', 'DXP-P5', 7, 'Promotion Bin Lines legacy table restore', 60084, 54706, 52281, 'MA');
        InsConcept('DXP', 'DXP-P5', 8, 'Promotion Bin Setup legacy table restore', 60084, 54707, 52282, 'SETUP');
        InsConcept('DXP', 'DXP-P5', 9, 'Error Audit Log legacy table restore', 60084, 54708, 52283, 'HIST');
        InsConcept('DXP', 'DXP-P6', 10, 'LSC Infocode field restore (renumbered generation)', 60085, 0, 0, 'SETUP');
        // CORRECTED 2026-08-22: was one collapsed "41 fields... OTHER" row - split into its 5
        // real independent TryCopyTableFields() calls (confirmed via direct source read of
        // DXR_MigrPhase6Fields.Codeunit.al), each classified by what it actually configures
        // instead of dumped into OTHER. LSC Tender Type specifically was flagged by the user as
        // needing to be confirmed covered by "Run All Setup" - it wasn't, now it is.
        InsConcept('DXP', 'DXP-P6', 39, 'LSC POS Terminal field restore (renumbered generation)', 60085, 0, 0, 'SETUP');
        InsConcept('DXP', 'DXP-P6', 40, 'LSC POS Trans. Line field restore (renumbered generation)', 60085, 0, 0, 'MA');
        InsConcept('DXP', 'DXP-P6', 41, 'LSC Tender Type field restore (renumbered generation)', 60085, 0, 0, 'SETUP');
        InsConcept('DXP', 'DXP-P6', 42, 'LSC Trans. Payment Entry field restore (renumbered generation)', 60085, 0, 0, 'MA');
        InsConcept('DXP', 'DXP-P2', 12, 'LSC Infocode field restore (same-table)', 60081, 0, 0, 'SETUP');
        // CORRECTED 2026-08-22: same split as DXP-P6 above, confirmed via DXR_MigrPhase2Fields
        // .Codeunit.al's own 5 independent TryCopyTableFields() calls.
        InsConcept('DXP', 'DXP-P2', 43, 'LSC POS Terminal field restore (same-table)', 60081, 0, 0, 'SETUP');
        InsConcept('DXP', 'DXP-P2', 44, 'LSC POS Trans. Line field restore (same-table)', 60081, 0, 0, 'MA');
        InsConcept('DXP', 'DXP-P2', 45, 'LSC Tender Type field restore (same-table)', 60081, 0, 0, 'SETUP');
        InsConcept('DXP', 'DXP-P2', 46, 'LSC Trans. Payment Entry field restore (same-table)', 60081, 0, 0, 'MA');
        // DXP-P1/P3/P5 all independently converge on the SAME final active tables (52275-52283)
        // from 3 different legacy generations - confirmed 2026-08-22 by reading all 3 dispatcher
        // codeunits directly, each idempotent via Dest.Get() before insert, so all 3 are safe to
        // run in any order/all 3. DXP-P4 is P1's own real prerequisite (populates the "DX ..."
        // 5474x tables P1 then reads as ITS source) - runs before P1, not parallel to it.
        // CORRECTED 2026-08-22: the "5421x" numbers below were never real table IDs - they're
        // digits embedded in the table's own NAME string (e.g. `table 54760 "DX Payment Setup
        // 54211"`), a leftover tag from a prior renumbering. RecordRef.Open(54211) would have
        // failed "table not found" for every one of these 9 rows. Confirmed via direct source
        // read of every table declaration in DXPAYMENT-BC.
        InsConcept('DXP', 'DXP-P4', 14, 'DX Payment Setup legacy table restore (54760 -> 54748, feeds DXP-P1)', 60083, 54760, 54748, 'SETUP');
        InsConcept('DXP', 'DXP-P4', 15, 'DX Promotion Bin Card legacy table restore (54761 -> 54749, feeds DXP-P1)', 60083, 54761, 54749, 'MA');
        InsConcept('DXP', 'DXP-P4', 16, 'Store Payments DX legacy table restore (54762 -> 54750, feeds DXP-P1)', 60083, 54762, 54750, 'MA');
        InsConcept('DXP', 'DXP-P4', 17, 'Payment Process Logs legacy table restore (54763 -> 54751, feeds DXP-P1)', 60083, 54763, 54751, 'HIST');
        InsConcept('DXP', 'DXP-P4', 18, 'DX Promo Bin Header legacy table restore (54764 -> 54752, feeds DXP-P1)', 60083, 54764, 54752, 'MA');
        InsConcept('DXP', 'DXP-P4', 19, 'DX Promo Bin ItemsLines legacy table restore (54765 -> 54753, feeds DXP-P1)', 60083, 54765, 54753, 'MA');
        InsConcept('DXP', 'DXP-P4', 20, 'DX Promotion Bin Lines legacy table restore (54766 -> 54754, feeds DXP-P1)', 60083, 54766, 54754, 'MA');
        InsConcept('DXP', 'DXP-P4', 21, 'DX Promotion Bin Setup legacy table restore (54767 -> 54755, feeds DXP-P1)', 60083, 54767, 54755, 'SETUP');
        InsConcept('DXP', 'DXP-P4', 22, 'DX Error Audit Log legacy table restore (54768 -> 54756, feeds DXP-P1)', 60083, 54768, 54756, 'HIST');
        InsConcept('DXP', 'DXP-P1', 11, 'DX Payment Setup legacy table restore (54748 -> active DXR_Payment Setup 52275)', 60080, 54748, 52275, 'SETUP');
        InsConcept('DXP', 'DXP-P1', 23, 'DX Promotion Bin Card legacy table restore (54749 -> active DXR_Promotion Bin Card 52276)', 60080, 54749, 52276, 'MA');
        InsConcept('DXP', 'DXP-P1', 24, 'Store Payments DX legacy table restore (54750 -> active DXR_Store Payments 52277)', 60080, 54750, 52277, 'MA');
        InsConcept('DXP', 'DXP-P1', 25, 'Payment Process Logs legacy table restore (54751 -> active DXR_Payment Process Logs 52278)', 60080, 54751, 52278, 'HIST');
        InsConcept('DXP', 'DXP-P1', 26, 'DX Promo Bin Header legacy table restore (54752 -> active DXR_Promo Bin Header 52279)', 60080, 54752, 52279, 'MA');
        InsConcept('DXP', 'DXP-P1', 27, 'DX Promotion Bin Items Lines legacy table restore (54753 -> active DXR_Promotion Bin Items Lines 52280)', 60080, 54753, 52280, 'MA');
        InsConcept('DXP', 'DXP-P1', 28, 'DX Promotion Bin Lines legacy table restore (54754 -> active DXR_Promotion Bin Lines 52281)', 60080, 54754, 52281, 'MA');
        InsConcept('DXP', 'DXP-P1', 29, 'DX Promotion Bin Setup legacy table restore (54755 -> active DXR_Promotion Bin Setup 52282)', 60080, 54755, 52282, 'SETUP');
        InsConcept('DXP', 'DXP-P1', 30, 'DX Error Audit Log legacy table restore (54756 -> active DXR_Error Audit Log 52283)', 60080, 54756, 52283, 'HIST');
        // CORRECTED 2026-08-22: same class of bug as DXP-P4 above - "5422x" was a name-embedded
        // tag, not a real table ID. Real IDs confirmed via direct source read.
        InsConcept('DXP', 'DXP-P3', 13, 'DXR_Payment Setup 54769 legacy table restore (2nd generation, -> active DXR_Payment Setup 52275)', 60082, 54769, 52275, 'SETUP');
        InsConcept('DXP', 'DXP-P3', 31, 'DXR_Promotion Bin Card 54770 legacy table restore (2nd generation, -> active DXR_Promotion Bin Card 52276)', 60082, 54770, 52276, 'MA');
        InsConcept('DXP', 'DXP-P3', 32, 'DXR_Store Payments 54771 legacy table restore (2nd generation, -> active DXR_Store Payments 52277)', 60082, 54771, 52277, 'MA');
        InsConcept('DXP', 'DXP-P3', 33, 'DXR_Payment Process Logs 54772 legacy table restore (2nd generation, -> active DXR_Payment Process Logs 52278)', 60082, 54772, 52278, 'HIST');
        InsConcept('DXP', 'DXP-P3', 34, 'DXR_Promo Bin Header 54773 legacy table restore (2nd generation, -> active DXR_Promo Bin Header 52279)', 60082, 54773, 52279, 'MA');
        InsConcept('DXP', 'DXP-P3', 35, 'DXR_Promo Bin ItemsLines 54774 legacy table restore (2nd generation, -> active DXR_Promotion Bin Items Lines 52280)', 60082, 54774, 52280, 'MA');
        InsConcept('DXP', 'DXP-P3', 36, 'DXR_Promotion Bin Lines 54775 legacy table restore (2nd generation, -> active DXR_Promotion Bin Lines 52281)', 60082, 54775, 52281, 'MA');
        InsConcept('DXP', 'DXP-P3', 37, 'DXR_Promotion Bin Setup 54776 legacy table restore (2nd generation, -> active DXR_Promotion Bin Setup 52282)', 60082, 54776, 52282, 'SETUP');
        InsConcept('DXP', 'DXP-P3', 38, 'DXR_Error Audit Log 54777 legacy table restore (2nd generation, -> active DXR_Error Audit Log 52283)', 60082, 54777, 52283, 'HIST');

        // ---- PCM: Price Controls Mgt. (dispatcher "DXR_Migr. Phase Dispatcher" 54615 runs
        // Phase2/54612 -> Phase3/54613 -> Phase4/54614 -> Phase5/54620 in sequence) ----
        InsConcept('PCM', 'PCM-P5', 1, 'Approval History legacy table restore (has real transactional data)', 60125, 57024, 54609, 'HIST');
        InsConcept('PCM', 'PCM-P5', 2, 'LSC Offers FB legacy table restore (Temporary shell, no data)', 60125, 57023, 54607, 'SETUP');
        InsConcept('PCM', 'PCM-P5', 3, 'Prices Factbox legacy table restore (Temporary shell, no data)', 60125, 57021, 54603, 'SETUP');
        InsConcept('PCM', 'PCM-P5', 4, 'Prices Ctrl Setup legacy table restore (single-row setup)', 60125, 57022, 54605, 'SETUP');
        InsConcept('PCM', 'PCM-P5', 5, 'Customer: PRC Store field restore (1 field) - true field already preserved in the active tableextension, no separate legacy shell needed (see Extension Notes)', 60125, 0, 0, 'MA');
        InsConcept('PCM', 'PCM-P5', 6, 'LSC Store Price Group field restore (3 fields: Precio Fijado/Excluir Store Prices/Excluir Cust. Prices) - true fields already preserved in the active tableextension', 60125, 0, 0, 'SETUP');
        InsConcept('PCM', 'PCM-P5', 7, 'Approval Entry field restore (3 fields: Workflow Code/Workflow Instance ID/Posting Date) - true fields already preserved in the active tableextension', 60125, 0, 0, 'OTHER');
        InsConcept('PCM', 'PCM-P5', 8, 'Workflow: Approval Type field restore (1 field) - the one table whose true field was genuinely lost, restored via a separate legacy shell tableextension (57004) at its true id+name', 60125, 0, 0, 'SETUP');
        InsConcept('PCM', 'PCM-P5', 9, 'Sales Header Snapshot field restore (10 fields) - true fields already preserved in the active tableextension', 60125, 0, 0, 'MA');
        InsConcept('PCM', 'PCM-P5', 10, 'Sales Line field restore (12 fields) + Sales Line Snapshot field restore (20 fields) - true fields already preserved in the active tableextension', 60125, 0, 0, 'MA');
        InsConcept('PCM', 'PCM-P2', 11, 'Customer: PRC Store field restore (1 field, Phase 2 pass - runs before Phase 5''s own pass)', 60122, 0, 0, 'MA');
        InsConcept('PCM', 'PCM-P2', 12, 'LSC Store Price Group field restore (3 fields, Phase 2 pass)', 60122, 0, 0, 'SETUP');
        InsConcept('PCM', 'PCM-P3', 13, 'Approval Entry field restore (Workflow Code/Instance ID/Posting Date, Phase 3 pass)', 60123, 0, 0, 'OTHER');
        InsConcept('PCM', 'PCM-P3', 14, 'Workflow: PRC Approval Type field restore (Phase 3 pass)', 60123, 0, 0, 'SETUP');
        InsConcept('PCM', 'PCM-P4', 15, 'Sales Header: 10 snapshot fields restore (Phase 4 pass)', 60124, 0, 0, 'MA');
        InsConcept('PCM', 'PCM-P4', 16, 'Sales Line: 12 operational + 20 snapshot fields restore (Phase 4 pass)', 60124, 0, 0, 'MA');

        // ---- TU: TransUnion ----
        InsConcept('TU', 'TU-P1', 1, 'Transunion Setup legacy table restore', 60126, 57304, 53601, 'SETUP');
        InsConcept('TU', 'TU-P1', 2, 'Transunion Header legacy table restore', 60126, 57305, 53602, 'MA');
        InsConcept('TU', 'TU-P1', 3, 'Customer/Cust. Ledger Entry duplicated field restore (10 fields)', 60126, 0, 0, 'MA');
        // Resolved 2026-08-24 (Task A.4): confirmed the non-"Old2" originals (57300/57301) are
        // NOT Access = Internal (unlike 57304/57305) and ARE already read directly by 60126's own
        // MigrateLegacyTables() - typed Record "Transunion Setup"/"Transunion Header", zero
        // RecordRef, gated by the same TableMigrationTag() step as the rest of 60126's OnRun.
        // That IS "MCC's own fallback" the earlier comment anticipated - it just wasn't wired to
        // this row yet. Dispatcher Codeunit ID repointed from 0 to 60126 accordingly (seq1 already
        // shares 60126, so this causes no double-processing - see IsDispatcherAlreadyDone's
        // per-dispatcher dedup in DXR MCC Executor).
        InsConcept('TU', 'TU-GAP', 4, 'Transunion Setup legacy table restore, gen-0 (57300 -> 53601, same final target as TU-P1 seq1)', 60126, 57300, 53601, 'SETUP');
        InsConcept('TU', 'TU-GAP', 5, 'Transunion Header legacy table restore, gen-0 (57301 -> 53602, same final target as TU-P1 seq2)', 60126, 57301, 53602, 'MA');

        // ---- DESB: Despacho Base (38 table pairs + 2 collision-fix phases + permission repair) ----
        InsConcept('DESB', 'DESB-P1', 1, 'Additional Truck legacy table restore', 60127, 50809, 53837, 'MA');
        InsConcept('DESB', 'DESB-P1', 2, 'Codigos de Auditoria legacy table restore', 60127, 50836, 53838, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 3, 'Criterio Encuesta legacy table restore', 60127, 50820, 53839, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 4, 'Delivered to Acc. Lines legacy table restore', 60127, 50817, 53853, 'HIST');
        InsConcept('DESB', 'DESB-P1', 5, 'Despachador legacy table restore', 60127, 50807, 53868, 'MA');
        InsConcept('DESB', 'DESB-P1', 6, 'Dispatch Line legacy table restore', 60127, 50808, 53843, 'MA');
        InsConcept('DESB', 'DESB-P1', 7, 'Dispatch Setup legacy table restore', 60127, 50800, 53845, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 8, 'Dispatch Notification Queue legacy table restore', 60127, 50851, 53844, 'OTHER');
        InsConcept('DESB', 'DESB-P1', 9, 'Delivered to Acc. Hdr legacy table restore', 60127, 50818, 53852, 'HIST');
        InsConcept('DESB', 'DESB-P1', 10, 'Escalas - Tipos Docs legacy table restore', 60127, 50823, 53848, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 11, 'Linea Enc. Registradas legacy table restore', 60127, 50822, 53850, 'HIST');
        InsConcept('DESB', 'DESB-P1', 12, 'Linea Encuesta legacy table restore', 60127, 50821, 53851, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 13, 'Despacho Migr Status legacy table restore', 60127, 50852, 53869, 'HIST');
        InsConcept('DESB', 'DESB-P1', 14, 'Webhook Configuration legacy table restore', 60127, 50826, 53878, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 15, 'Entrega Fact. CxC - Hdr legacy table restore', 60127, 50837, 53846, 'HIST');
        InsConcept('DESB', 'DESB-P1', 16, 'Entrega Fact. CxC - Lns legacy table restore', 60127, 50838, 53847, 'HIST');
        InsConcept('DESB', 'DESB-P1', 17, 'Fiscal Printers Brands legacy table restore', 60127, 50828, 53849, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 18, 'Log Reimpresiones Cond legacy table restore', 60127, 50830, 53854, 'HIST');
        InsConcept('DESB', 'DESB-P1', 19, 'Motive Code legacy table restore', 60127, 50814, 53855, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 20, 'Non-Delivery Reason legacy table restore', 60127, 50831, 53856, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 21, 'Pick Logs legacy table restore', 60127, 50832, 53857, 'HIST');
        InsConcept('DESB', 'DESB-P1', 22, 'Pickup Historic legacy table restore', 60127, 50833, 53858, 'HIST');
        InsConcept('DESB', 'DESB-P1', 23, 'Pickup List legacy table restore', 60127, 50834, 53859, 'OTHER');
        InsConcept('DESB', 'DESB-P1', 24, 'Posted Additional Truck legacy table restore', 60127, 50819, 53860, 'HIST');
        InsConcept('DESB', 'DESB-P1', 25, 'Posted Transport Header legacy table restore', 60127, 50811, 53861, 'HIST');
        InsConcept('DESB', 'DESB-P1', 26, 'Posted Transport Line legacy table restore', 60127, 50816, 53862, 'HIST');
        InsConcept('DESB', 'DESB-P1', 27, 'Preparador legacy table restore', 60127, 50835, 53863, 'MA');
        InsConcept('DESB', 'DESB-P1', 28, 'Routes legacy table restore', 60127, 50825, 53864, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 29, 'Sales Price View legacy table restore', 60127, 50824, 53865, 'MA');
        InsConcept('DESB', 'DESB-P1', 30, 'Shipment Header legacy table restore', 60127, 50813, 53866, 'MA');
        InsConcept('DESB', 'DESB-P1', 31, 'Shipment Line legacy table restore', 60127, 50815, 53867, 'MA');
        InsConcept('DESB', 'DESB-P1', 32, 'Transportation Staff legacy table restore', 60127, 50803, 53876, 'MA');
        InsConcept('DESB', 'DESB-P1', 33, 'Transport Comment legacy table restore', 60127, 50810, 53871, 'OTHER');
        InsConcept('DESB', 'DESB-P1', 34, 'Transport - Cost legacy table restore', 60127, 50804, 53870, 'MA');
        InsConcept('DESB', 'DESB-P1', 35, 'Transport Header legacy table restore', 60127, 50801, 53872, 'MA');
        InsConcept('DESB', 'DESB-P1', 36, 'Transport Line legacy table restore', 60127, 50806, 53873, 'MA');
        InsConcept('DESB', 'DESB-P1', 37, 'Transport Log''s legacy table restore', 60127, 50812, 53874, 'HIST');
        InsConcept('DESB', 'DESB-P1', 38, 'Transport Routes legacy table restore', 60127, 50805, 53875, 'SETUP');
        InsConcept('DESB', 'DESB-P1', 39, 'Truck legacy table restore', 60127, 50802, 53877, 'MA');
        InsConcept('DESB', 'DESB-P2', 40, 'Sales Header 6-field TransferFields collision fix (relocated to _Old2)', 60128, 0, 0, 'MA');
        InsConcept('DESB', 'DESB-P2', 41, 'Transfer Header 14-field TransferFields collision fix (relocated to _Reloc, all live call sites repointed)', 60128, 0, 0, 'MA');
        InsConcept('DESB', 'DESB-PERM', 42, 'Assign DXR_Despacho Base permission set to all users', 60127, 0, 0, 'SETUP');

        // ---- BELLON: Bellon Customization (11-phase chain, Phase2 through Phase12, no standalone
        // Phase1 - it's a completion-tag gate only, nothing to register) ----
        InsConcept('BELLON', 'BELLON-P3', 1, 'Sales/Purchase 14-table field-ID dedup (CRITICAL: was blocking Phase 2->3+ from ever running - the crash-fix)', 60147, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P5', 2, 'Customer+Item field restore (79 fields: 46 Customer + 33 Item)', 60149, 0, 0, 'MA');
        // Expanded 2026-08-22 from 1 collapsed row into 114 individual rows - full list read
        // directly from the 114 MigrateLegacyTableData(LegacyId, NewId) calls inside
        // BellonUpgradeProcess.MigrateAllRenumberedDXRTables() (codeunit 59221, invoked by
        // dispatcher 56123), cross-checked against every Tables.old2/*.al file. Every New ID
        // matches an existing BELLON-P2 row exactly - Tables.old and Tables.old2 are two
        // different legacy generations that both feed the same final active tables, confirmed,
        // not inferred. This was the single largest coverage gap found in the whole portfolio
        // audit and the most likely candidate for what the user personally observed (an old
        // table with data whose new counterpart was empty) given its size alone.
        InsConcept('BELLON', 'BELLON-P6', 3, 'DXR_Agente Old2 legacy table restore (59231 -> 53301)', 60150, 59231, 53301, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 157, 'DXR_AGR Log Old2 legacy table restore (59232 -> 53302)', 60150, 59232, 53302, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 158, 'DXR_AGR Setup Old2 legacy table restore (59233 -> 53303)', 60150, 59233, 53303, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 159, 'DXR_Ajuste Inventario Config Old2 legacy table restore (59234 -> 53304)', 60150, 59234, 53304, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 160, 'DXR_Archivo - Discrepancias Old2 legacy table restore (59235 -> 53305)', 60150, 59235, 53305, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 161, 'DXR_Area de Trabajo Old2 legacy table restore (59236 -> 53306)', 60150, 59236, 53306, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 162, 'DXR_Bancos - Extracto Bancario Old2 legacy table restore (59237 -> 53307)', 60150, 59237, 53307, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 163, 'DXR_Bank Old2 legacy table restore (59238 -> 53308)', 60150, 59238, 53308, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 164, 'DXR_Bank Relation Old2 legacy table restore (59239 -> 53309)', 60150, 59239, 53309, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 165, 'DXR_Black List Promotion Old2 legacy table restore (59240 -> 53310)', 60150, 59240, 53310, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 166, 'DXR_Cabecera Discrepancia Old2 legacy table restore (59241 -> 53311)', 60150, 59241, 53311, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 167, 'DXR_Carga Masiva Benef BPD Old2 legacy table restore (59242 -> 53312)', 60150, 59242, 53312, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 168, 'DXR_Categoria Servicios Old2 legacy table restore (59243 -> 53313)', 60150, 59243, 53313, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 169, 'DXR_Cilindros Old2 legacy table restore (59244 -> 53314)', 60150, 59244, 53314, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 170, 'DXR_Cilindros - Setup Old2 legacy table restore (59245 -> 53315)', 60150, 59245, 53315, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 171, 'DXR_Comentario - Discrepancias Old2 legacy table restore (59247 -> 53317, 59246/Codigos de Auditoria has no Tables.old2 counterpart - confirmed skip, not an omission)', 60150, 59247, 53317, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 172, 'DXR_Conf. Extracto Bancario Old2 legacy table restore (59248 -> 53318)', 60150, 59248, 53318, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 173, 'DXR_Config. NCF Ventas Old2 legacy table restore (59249 -> 53319)', 60150, 59249, 53319, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 174, 'DXR_Config. NCF Ventas STD Old2 legacy table restore (59250 -> 53320)', 60150, 59250, 53320, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 175, 'DXR_Config. Polizas Old2 legacy table restore (59251 -> 53321)', 60150, 59251, 53321, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 176, 'DXR_Configuracion CB Old2 legacy table restore (59252 -> 53322)', 60150, 59252, 53322, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 177, 'DXR_Config - Discr Old2 legacy table restore (59253 -> 53323)', 60150, 59253, 53323, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 178, 'DXR_Config Encuestas - POS Old2 legacy table restore (59254 -> 53324)', 60150, 59254, 53324, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 179, 'DXR_Config Req Old2 legacy table restore (59255 -> 53325)', 60150, 59255, 53325, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 180, 'DXR_Configuracion - MEDALLIA Old2 legacy table restore (59256 -> 53326)', 60150, 59256, 53326, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 181, 'DXR_Conf. Pagos Ecommerce Azul Old2 legacy table restore (59257 -> 53327)', 60150, 59257, 53327, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 182, 'DXR_Control Proc por Almacen Old2 legacy table restore (59258 -> 53328)', 60150, 59258, 53328, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 183, 'DXR_Conversion Costo Old2 legacy table restore (59259 -> 53329)', 60150, 59259, 53329, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 184, 'DXR_Departamento - Discr Old2 legacy table restore (59260 -> 53330)', 60150, 59260, 53330, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 185, 'DXR_Detalle - Extr Bancario Old2 legacy table restore (59261 -> 53331)', 60150, 59261, 53331, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 186, 'DXR_Draw Setup Old2 legacy table restore (59262 -> 53332)', 60150, 59262, 53332, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 187, 'DXR_Email Source Tmpl Rel Old2 legacy table restore (59263 -> 53333)', 60150, 59263, 53333, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 188, 'DXR_Entrega Fact CxC - Lines Old2 legacy table restore (59264 -> 53334)', 60150, 59264, 53334, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 189, 'DXR_Envio Compras Old2 legacy table restore (59265 -> 53335)', 60150, 59265, 53335, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 190, 'DXR_EPagos Setup Old2 legacy table restore (59266 -> 53336)', 60150, 59266, 53336, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 191, 'DXR_Exclude Filter Journal Old2 legacy table restore (59267 -> 53337)', 60150, 59267, 53337, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 192, 'DXR_Excluir Term - ItemSearch Old2 legacy table restore (59268 -> 53338)', 60150, 59268, 53338, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 193, 'DXR_File Structure Old2 legacy table restore (59269 -> 53339)', 60150, 59269, 53339, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 194, 'DXR_Forma de Pago Old2 legacy table restore (59270 -> 53340)', 60150, 59270, 53340, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 195, 'DXR_HisCargaMasivaBenefBPD Old2 legacy table restore (59271 -> 53341)', 60150, 59271, 53341, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 196, 'DXR_Grupo Venta Old2 legacy table restore (59272 -> 53342)', 60150, 59272, 53342, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 197, 'DXR_HisLinCargaMasivaBenefBPD Old2 legacy table restore (59273 -> 53343)', 60150, 59273, 53343, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 198, 'DXR_Hist. Beneficiarios BPD Old2 legacy table restore (59274 -> 53344)', 60150, 59274, 53344, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 199, 'DXR_Hist. Cabecera Discr Old2 legacy table restore (59275 -> 53345)', 60150, 59275, 53345, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 200, 'DXR_Hist. de Ganadores Old2 legacy table restore (59276 -> 53346)', 60150, 59276, 53346, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 201, 'DXR_Hist. Int Consump. Header Old2 legacy table restore (59277 -> 53347)', 60150, 59277, 53347, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 202, 'DXR_Hist. Int Consump. Line Old2 legacy table restore (59278 -> 53348)', 60150, 59278, 53348, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 203, 'DXR_Hist. Linea Discrepancia Old2 legacy table restore (59279 -> 53349)', 60150, 59279, 53349, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 204, 'DXR_Historico Enc Requisicion Old2 legacy table restore (59280 -> 53350)', 60150, 59280, 53350, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 205, 'DXR_Historico - Extr Bancario Old2 legacy table restore (59281 -> 53351)', 60150, 59281, 53351, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 206, 'DXR_Historico Requisicion Line Old2 legacy table restore (59282 -> 53352)', 60150, 59282, 53352, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 207, 'DXR_Hist Pre-Requisicion Old2 legacy table restore (59283 -> 53353)', 60150, 59283, 53353, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 208, 'DXR_Hist Pre-Requisicion Line Old2 legacy table restore (59284 -> 53354)', 60150, 59284, 53354, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 209, 'DXR_Int Consump Header Old2 legacy table restore (59285 -> 53355)', 60150, 59285, 53355, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 210, 'DXR_Internal Consumption Line Old2 legacy table restore (59286 -> 53356)', 60150, 59286, 53356, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 211, 'DXR_Internal Consumption Log Old2 legacy table restore (59287 -> 53357)', 60150, 59287, 53357, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 212, 'DXR_Inventory Masks Old2 legacy table restore (59288 -> 53358)', 60150, 59288, 53358, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 213, 'DXR_Item HTML Old2 legacy table restore (59289 -> 53359)', 60150, 59289, 53359, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 214, 'DXR_Item Image View Old2 legacy table restore (59290 -> 53360)', 60150, 59290, 53360, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 215, 'DXR_ItemNo Desliquidacion Old2 legacy table restore (59291 -> 53361)', 60150, 59291, 53361, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 216, 'DXR_Journal Promotion Tickets Old2 legacy table restore (59292 -> 53362)', 60150, 59292, 53362, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 217, 'DXR_Linea Discrepancia Old2 legacy table restore (59293 -> 53363)', 60150, 59293, 53363, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 218, 'DXR_Lin Carga Masiva Ben. BPD Old2 legacy table restore (59294 -> 53364)', 60150, 59294, 53364, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 219, 'DXR_LineRQBuffer Old2 legacy table restore (59295 -> 53365)', 60150, 59295, 53365, 'OTHER');
        InsConcept('BELLON', 'BELLON-P6', 220, 'DXR_Log - Bank Statement Old2 legacy table restore (59296 -> 53366)', 60150, 59296, 53366, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 221, 'DXR_Log Email Old2 legacy table restore (59297 -> 53367)', 60150, 59297, 53367, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 222, 'DXR_Log Transaccion Azul Old2 legacy table restore (59298 -> 53368)', 60150, 59298, 53368, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 223, 'DXR_Log Transaccion Medallia Old2 legacy table restore (59299 -> 53369)', 60150, 59299, 53369, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 224, 'DXR_Log Transfer error Old2 legacy table restore (59300 -> 53370)', 60150, 59300, 53370, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 225, 'DXR_Marcas Old2 legacy table restore (59301 -> 53371)', 60150, 59301, 53371, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 226, 'DXR_Member Management Setup Old2 legacy table restore (59302 -> 53372)', 60150, 59302, 53372, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 227, 'DXR_Motivo Cierre - Discr Old2 legacy table restore (59303 -> 53373)', 60150, 59303, 53373, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 228, 'DXR_Motivo Discrepancia Old2 legacy table restore (59304 -> 53374)', 60150, 59304, 53374, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 229, 'DXR_Movimientos de Cilindro Old2 legacy table restore (59305 -> 53375)', 60150, 59305, 53375, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 230, 'DXR_Order Item Status Old2 legacy table restore (59306 -> 53376)', 60150, 59306, 53376, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 231, 'DXR_Posted Jnl Promo Tickets Old2 legacy table restore (59307 -> 53377)', 60150, 59307, 53377, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 232, 'DXR_Pre Req LineNoStockValid Old2 legacy table restore (59308 -> 53378)', 60150, 59308, 53378, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 233, 'DXR_Pre Req no Stock Valid Old2 legacy table restore (59309 -> 53379)', 60150, 59309, 53379, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 234, 'DXR_Pre-Requisicion Old2 legacy table restore (59310 -> 53380)', 60150, 59310, 53380, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 235, 'DXR_Pre-Requisicion Line Old2 legacy table restore (59311 -> 53381)', 60150, 59311, 53381, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 236, 'DXR_Pre-Req Line No Stock Old2 legacy table restore (59312 -> 53382)', 60150, 59312, 53382, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 237, 'DXR_Pre-Requisicion no Stock Old2 legacy table restore (59313 -> 53383)', 60150, 59313, 53383, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 238, 'DXR_Printing Invoice Log Old2 legacy table restore (59314 -> 53384)', 60150, 59314, 53384, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 239, 'DXR_Profesion Old2 legacy table restore (59315 -> 53385)', 60150, 59315, 53385, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 240, 'DXR_Promotion Setup Old2 legacy table restore (59316 -> 53386)', 60150, 59316, 53386, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 241, 'DXR_Promotion Tickets Relation Old2 legacy table restore (59317 -> 53387)', 60150, 59317, 53387, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 242, 'DXR_Provincia Old2 legacy table restore (59318 -> 53388)', 60150, 59318, 53388, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 243, 'DXR_Requisicion Old2 legacy table restore (59319 -> 53389)', 60150, 59319, 53389, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 244, 'DXR_Requisicion Comment Line Old2 legacy table restore (59320 -> 53390)', 60150, 59320, 53390, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 245, 'DXR_Requisicion Line Old2 legacy table restore (59321 -> 53391)', 60150, 59321, 53391, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 246, 'DXR_Sales Dept Old2 legacy table restore (59322 -> 53392)', 60150, 59322, 53392, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 247, 'DXR_Sales Groups Old2 legacy table restore (59323 -> 53393)', 60150, 59323, 53393, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 248, 'DXR_Sales SubGroups Old2 legacy table restore (59324 -> 53394)', 60150, 59324, 53394, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 249, 'DXR_Send Email Log Old2 legacy table restore (59325 -> 53395)', 60150, 59325, 53395, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 250, 'DXR_Std POS DASCOM Paymt Eqv Old2 legacy table restore (59326 -> 53396)', 60150, 59326, 53396, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 251, 'DXR_Standard POS Gen. Comments Old2 legacy table restore (59327 -> 53397)', 60150, 59327, 53397, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 252, 'DXR_Standard POS Users Old2 legacy table restore (59328 -> 53398)', 60150, 59328, 53398, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 253, 'DXR_Store Statement Posting Old2 legacy table restore (59329 -> 53399)', 60150, 59329, 53399, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 254, 'DXR_Summary Recon Setup Old2 legacy table restore (59330 -> 53400)', 60150, 59330, 53400, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 255, 'DXR_Tasas BC Old2 legacy table restore (59331 -> 53401)', 60150, 59331, 53401, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 256, 'DXR_Tickets By Offer Old2 legacy table restore (59332 -> 53402)', 60150, 59332, 53402, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 257, 'DXR_Tickets Entry Old2 legacy table restore (59333 -> 53403)', 60150, 59333, 53403, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 258, 'DXR_Tipo de Contenedor Old2 legacy table restore (59334 -> 53404)', 60150, 59334, 53404, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 259, 'DXR_Tipo Gas Old2 legacy table restore (59335 -> 53405)', 60150, 59335, 53405, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 260, 'DXR_Tipos o Agentes Old2 legacy table restore (59336 -> 53406)', 60150, 59336, 53406, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 261, 'DXR_Trans. Archive Line Old2 legacy table restore (59337 -> 53407)', 60150, 59337, 53407, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 262, 'DXR_Tratados Arancelarios Old2 legacy table restore (59338 -> 53408)', 60150, 59338, 53408, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 263, 'DXR_UserApproverByBuyerGroup Old2 legacy table restore (59339 -> 53409)', 60150, 59339, 53409, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 264, 'DXR_UserByBuyerGroup Old2 legacy table restore (59340 -> 53410)', 60150, 59340, 53410, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 265, 'DXR_UserLogs Old2 legacy table restore (59341 -> 53411)', 60150, 59341, 53411, 'HIST');
        InsConcept('BELLON', 'BELLON-P6', 266, 'DXR_UserPromo Apps Old2 legacy table restore (59342 -> 53412)', 60150, 59342, 53412, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 267, 'DXR_Valoracion de Inventario Old2 legacy table restore (59343 -> 53413)', 60150, 59343, 53413, 'MA');
        InsConcept('BELLON', 'BELLON-P6', 268, 'DXR_VAT Bus. Settings Old2 legacy table restore (59344 -> 53414)', 60150, 59344, 53414, 'SETUP');
        InsConcept('BELLON', 'BELLON-P6', 269, 'DXR_Printing Invoice Log BO Old2 legacy table restore (59345 -> 53415)', 60150, 59345, 53415, 'HIST');
        // Phase 13/14 added 2026-08-23: real phases in Bellon Customization's own Dispatcher
        // (56112, runs them last, after Phase 11) that no old MCC delegation adapter ever called -
        // each old adapter called a specific sibling phase codeunit directly, never the sibling's
        // own Dispatcher, and Phase 13/14 had no direct-call adapter of their own. A genuine,
        // real gap in this MCC extension's coverage, predating the native-migration pivot - not
        // something the native port invented. Native codeunits 60157/60158 were ported and
        // compiled clean before these rows existed; see their own header comments for full detail.
        InsConcept('BELLON', 'BELLON-P13', 270, 'Item Charge Assignment (Purch): Monto Cargo Liq. Old->DXR bridge field restore', 60157, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P13', 271, 'DXR_Cash Journal Receipt List (52132) Old->DXR bridge field restore (4 fields)', 60157, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P13', 272, 'DXR_NCF Setup (52179) Old->DXR bridge field restore (2 fields)', 60157, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P13', 273, 'Vendor: 13-field legacy->DXR direct restore (no _Old bridge ever declared for these)', 60157, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P14', 274, 'Contact: 13-field cross-table ID collision bridge restore (incl. the reported crash field, Next Order Selection)', 60158, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P14', 275, 'Transfer Header: 3-field cross-table ID collision bridge restore', 60158, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P14', 276, 'Sales Header: 1-field cross-table ID collision bridge restore (PriceReleaseControlFlag)', 60158, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P14', 277, 'Purchase Line: 1-field cross-table ID collision bridge restore (Transito)', 60158, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P7', 4, '55 tableextension field restore (audited count - registry previously said "87 tables/171 fields", that figure did not reconcile; ApprovalEntry/AssemblySetup/BankAccReconciliation(+Line)/BankAccount(+LedgerEntry)/CheckLedgerEntry/CompanyInformation/CountryRegion/Currency(+ExchangeRate)/CustLedgerEntry/CustomerPriceGroup/GenJournalBatch/GenJournalLine/GenProductPostingGroup/GeneralLedgerSetup/IssuedReminderHeader/ItemCategory/ItemChargeAssignmentPurch/ItemSpecialGroups/ListadoRecibodeIngreso/Location/MemberContact/MemberPointOffer/NCFSetup/PaymentMethod/PeriodicDiscount/PostedStatement/ProductGroup/PurchCommentLine(+Archive)/PurchInvLine/ReasonCodeTableExt/ReplenJournalLines/ReplenTemplate/RetailSetup/RetailUser/SalesPrice/SalesReceivablesSetup/SalesType/SalespersonPurchaser/ShiptoAddress/Statement/Store/TariffNumber/TenderType/TransSalesEntry/TransactionHeader/TransferReceiptHeader/TransferShipmentHeader/UserSetup/ValueEntry/Vendor/WarehouseReceiptLine - excl. Customer/Item/Sales/Purchase/Contact, those are P5/P3/P8)', 60151, 0, 0, 'OTHER');
        InsConcept('BELLON', 'BELLON-P8', 5, 'Contact field restore (19 fields)', 60152, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P9', 6, 'Transfer Header field restore (2 fields, posting-copy ID collision fix) - Release 2 (retire colliding original) still deferred: unlike P10, these are LIVE active fields on both sides, not dead bridges, so relocating one needs a call-site audit first', 60153, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P10', 7, 'Sales/Purchase _Old + _BE_DXR bridge dedup - CORRECTED 2026-08-22: confirmed the same 14 tables as BELLON-P3 (Phase 10''s own header comment says so explicitly). MigrateAllSalesPurchOldDedup2 is now a deliberate no-op tag-setter, not an active field-copy - the 100 "_Old" bridge fields were confirmed (git history + explicit user sign-off) to have never reached a published tenant, so they were marked ObsoleteState=Removed directly instead of migrated. Kept as its own concept for audit-trail completeness, not because it moves any data.', 60154, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P4', 8, 'Assign DXR_Bellon Perms permission set to all users (Phase 4)', 60148, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P11', 9, 'Config. NCF Compras field restore (1 field, 52120034)', 60155, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P11', 10, 'SalesHeaderOrderListFromBo field restore (1 field, 54101)', 60155, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P11', 11, 'Config. NCF Ventas legacy field-name correction (table 50032->53319)', 60146, 50032, 53319, 'SETUP');
        InsConcept('BELLON', 'BELLON-P11', 12, 'Config. NCF Ventas STD legacy field-name correction (table 50033->53320)', 60146, 50033, 53320, 'SETUP');
        // CORRECTED 2026-08-22: 53455/53449 are tableextension IDs (extending "DXR_NCF Setup"/
        // "DXR_Cash Journal Receipt List"), not table IDs - RecordRef.Open() needs a real table.
        // These are field-container additions; the fields live on the base tables the extensions
        // target, so this is a field-only concept like the others in this phase, not a genuine
        // table-pair. Legacy/New Table ID corrected to 0/0.
        InsConcept('BELLON', 'BELLON-P11', 13, 'BE NCF Setup field restore (tableextension 53455 extends DXR_NCF Setup, field-only)', 60155, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P11', 14, 'BE Listado Recibo de Ingreso field restore (tableextension 53449 extends DXR_Cash Journal Receipt List, field-only)', 60155, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P12', 15, 'Purchase Header collision bridge (3 fields: 50000->57800, 50004->57801, 50005->57802)', 60156, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 16, 'Agente legacy table restore', 60146, 50001, 53301, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 17, 'AGR Log legacy table restore', 60146, 50004, 53302, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 18, 'AGR Setup legacy table restore', 60146, 50005, 53303, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 19, 'Ajuste Inventario Config legacy table restore', 60146, 50006, 53304, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 20, 'Archivo - Discrepancias legacy table restore', 60146, 50007, 53305, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 21, 'Area de Trabajo legacy table restore', 60146, 50008, 53306, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 22, 'Bancos - Extracto Bancario legacy table restore', 60146, 50009, 53307, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 23, 'Bank legacy table restore', 60146, 50010, 53308, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 24, 'Bank Relation legacy table restore', 60146, 50011, 53309, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 25, 'Black List Promotion legacy table restore', 60146, 50012, 53310, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 26, 'Cabecera Discrepancia legacy table restore', 60146, 50013, 53311, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 27, 'Carga Masiva Beneficiarios BPD legacy table restore', 60146, 50016, 53312, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 28, 'Categoria Servicios legacy table restore', 60146, 50020, 53313, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 29, 'Cilindros legacy table restore', 60146, 50021, 53314, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 30, 'Cilindros - Setup legacy table restore', 60146, 50022, 53315, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 31, 'Codigos de Auditoria legacy table restore', 60146, 50024, 53316, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 32, 'Comentario - Discrepancias legacy table restore', 60146, 50025, 53317, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 33, 'Conf. Extracto Bancario legacy table restore', 60146, 50029, 53318, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 34, 'Config. NCF Ventas legacy table restore', 60146, 50032, 53319, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 35, 'Config. NCF Ventas STD legacy table restore', 60146, 50033, 53320, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 36, 'Config. Polizas legacy table restore', 60146, 50034, 53321, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 37, 'Configuracion CB legacy table restore', 60146, 50035, 53322, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 38, 'Configuracion - Discrepancias legacy table restore', 60146, 50036, 53323, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 39, 'Configuracion Encuestas - POS legacy table restore', 60146, 50037, 53324, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 40, 'Configuraciones Requisicion legacy table restore', 60146, 50038, 53325, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 41, 'Configuracion - MEDALLIA legacy table restore', 60146, 50039, 53326, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 42, 'Conf. Pagos Ecommerce Azul legacy table restore', 60146, 50040, 53327, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 43, 'Control Procesos por Almacen legacy table restore', 60146, 50042, 53328, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 44, 'Conversion Costo legacy table restore', 60146, 50043, 53329, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 45, 'Departamento - Discrepancias legacy table restore', 60146, 50048, 53330, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 46, 'Detalle - Extracto Bancario legacy table restore', 60146, 50050, 53331, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 47, 'Draw Setup legacy table restore', 60146, 50052, 53332, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 48, 'Email Source Template Relation legacy table restore', 60146, 50055, 53333, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 49, 'Entrega Facturas CxC - Lines legacy table restore', 60146, 50057, 53334, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 50, 'Envio Compras legacy table restore', 60146, 50058, 53335, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 51, 'EPagos Setup legacy table restore', 60146, 50061, 53336, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 52, 'Exclude Filter Journal legacy table restore', 60146, 50063, 53337, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 53, 'Excluir Terminos - ItemSearch legacy table restore', 60146, 50064, 53338, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 54, 'File Structure legacy table restore', 60146, 50065, 53339, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 55, 'Forma de Pago legacy table restore', 60146, 50068, 53340, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 56, 'HisCargaMasivaBeneficiariosBPD legacy table restore', 60146, 50071, 53341, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 57, 'Grupo Venta legacy table restore', 60146, 50072, 53342, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 58, 'HisLineasCargaMasivaBenefBPD legacy table restore', 60146, 50073, 53343, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 59, 'Hist. Beneficiarios BPD legacy table restore', 60146, 50074, 53344, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 60, 'Hist. Cabecera Discrepancia legacy table restore', 60146, 50075, 53345, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 61, 'Hist. de Ganadores legacy table restore', 60146, 50076, 53346, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 62, 'Hist. Internal Consump. Header legacy table restore', 60146, 50077, 53347, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 63, 'Hist. Internal Consump. Line legacy table restore', 60146, 50078, 53348, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 64, 'Hist. Linea Discrepancia legacy table restore', 60146, 50079, 53349, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 65, 'Historico Enc Requisicion legacy table restore', 60146, 50081, 53350, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 66, 'Historico - Extracto Bancario legacy table restore', 60146, 50082, 53351, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 67, 'Historico Requisicion Line legacy table restore', 60146, 50084, 53352, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 68, 'Hist Pre-Requisicion legacy table restore', 60146, 50085, 53353, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 69, 'Hist Pre-Requisicion Line legacy table restore', 60146, 50086, 53354, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 70, 'Internal Consumption Header legacy table restore', 60146, 50093, 53355, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 71, 'Internal Consumption Line legacy table restore', 60146, 50094, 53356, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 72, 'Internal Consumption Log legacy table restore', 60146, 50095, 53357, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 73, 'BE Inventory Masks legacy table restore', 60146, 50096, 53358, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 74, 'Item HTML legacy table restore', 60146, 50098, 53359, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 75, 'Item Image View legacy table restore', 60146, 50099, 53360, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 76, 'ItemNo Desliquidacion legacy table restore', 60146, 50100, 53361, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 77, 'Journal Promotion Tickets legacy table restore', 60146, 50102, 53362, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 78, 'Linea Discrepancia legacy table restore', 60146, 50103, 53363, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 79, 'Lineas Carga Masiva Ben. BPD legacy table restore', 60146, 50107, 53364, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 80, 'LineRQBuffer legacy table restore', 60146, 50109, 53365, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 81, 'Log - Bank Statement legacy table restore', 60146, 50111, 53366, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 82, 'Log Email legacy table restore', 60146, 50112, 53367, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 83, 'Log Transaccion Azul legacy table restore', 60146, 50115, 53368, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 84, 'Log Transaccion Medallia legacy table restore', 60146, 50116, 53369, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 85, 'Log Transfer error legacy table restore', 60146, 50117, 53370, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 86, 'Marcas legacy table restore', 60146, 50118, 53371, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 87, 'Member Management Setup legacy table restore', 60146, 50119, 53372, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 88, 'Motivo Cierre - Discrepancias legacy table restore', 60146, 50121, 53373, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 89, 'Motivo Discrepancia legacy table restore', 60146, 50122, 53374, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 90, 'Movimientos de Cilindro legacy table restore', 60146, 50123, 53375, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 91, 'Order Item Status legacy table restore', 60146, 50127, 53376, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 92, 'Posted Jnl Promotion Tickets legacy table restore', 60146, 50132, 53377, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 93, 'Pre Req LineNoStockValid legacy table restore', 60146, 50135, 53378, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 94, 'Pre Req no Stock Valid legacy table restore', 60146, 50136, 53379, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 95, 'Pre-Requisicion legacy table restore', 60146, 50137, 53380, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 96, 'Pre-Requisicion Line legacy table restore', 60146, 50138, 53381, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 97, 'Pre-Requisicion Line No Stock legacy table restore', 60146, 50139, 53382, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 98, 'Pre-Requisicion no Stock legacy table restore', 60146, 50140, 53383, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 99, 'Printing Invoice Log legacy table restore', 60146, 50141, 53384, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 100, 'Profesion legacy table restore', 60146, 50142, 53385, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 101, 'Promotion Setup legacy table restore', 60146, 50143, 53386, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 102, 'Promotion Tickets Relation legacy table restore', 60146, 50144, 53387, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 103, 'Provincia legacy table restore', 60146, 50145, 53388, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 104, 'Requisicion legacy table restore', 60146, 50151, 53389, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 105, 'Requisicion Comment Line legacy table restore', 60146, 50152, 53390, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 106, 'Requisicion Line legacy table restore', 60146, 50153, 53391, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 107, 'Sales Dept legacy table restore', 60146, 50154, 53392, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 108, 'Sales Groups legacy table restore', 60146, 50155, 53393, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 109, 'Sales SubGroups legacy table restore', 60146, 50159, 53394, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 110, 'Send Email Log legacy table restore', 60146, 50160, 53395, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 111, 'Standard POS DASCOM Paymt Eqv legacy table restore', 60146, 50165, 53396, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 112, 'Standard POS Gen. Comments legacy table restore', 60146, 50168, 53397, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 113, 'Standard POS Users legacy table restore', 60146, 50172, 53398, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 114, 'Store Statement Posting legacy table restore', 60146, 50173, 53399, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 115, 'Summary Reconciliation Setup legacy table restore', 60146, 50174, 53400, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 116, 'Tasas BC legacy table restore', 60146, 50176, 53401, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 117, 'Tickets By Offer legacy table restore', 60146, 50177, 53402, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 118, 'Tickets Entry legacy table restore', 60146, 50178, 53403, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 119, 'Tipo de Contenedor legacy table restore', 60146, 50180, 53404, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 120, 'Tipo Gas legacy table restore', 60146, 50181, 53405, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 121, 'Tipos o Agentes legacy table restore', 60146, 50182, 53406, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 122, 'Trans. Archive Line legacy table restore', 60146, 50186, 53407, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 123, 'Tratados Arancelarios legacy table restore', 60146, 50195, 53408, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 124, 'UserApproverByBuyerGroup legacy table restore', 60146, 50197, 53409, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 125, 'UserByBuyerGroup legacy table restore', 60146, 50198, 53410, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 126, 'UserLogs legacy table restore', 60146, 50199, 53411, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 127, 'UserPromo Apps legacy table restore', 60146, 50200, 53412, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 128, 'Valoracion de Inventario legacy table restore', 60146, 50201, 53413, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 129, 'VAT Bus. Settings legacy table restore', 60146, 50202, 53414, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 130, 'Printing Invoice Log BO legacy table restore', 60146, 50206, 53415, 'HIST');
        InsConcept('BELLON', 'BELLON-P2', 131, 'AGR Extended Item legacy table restore (batch 2)', 60146, 50002, 55006, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 132, 'Comision_Grupo_Vendedor legacy table restore (batch 2)', 60146, 50027, 55005, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 133, 'Inventory View legacy table restore (batch 2)', 60146, 50097, 55004, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 134, 'Operaciones Tipo Comprobante2 legacy table restore (batch 2)', 60146, 50126, 55007, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 135, 'Sales/Purchase old-generation bridge copy (MigrateAllSalesPurchOldGenBridge - confirmed no-op: both source _BE_DXR and destination _Old fields across all 14 tables are ObsoleteState = Removed, no live tenant data ever existed; see codeunit 60166 header comment)', 60166, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 136, 'Tableextension field-group restore: ApprovalEntry/AssemblyHeader/AssemblySetup/VendorLedgerEntry (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 137, 'Tableextension field-group restore: BankAccReconciliation(+Line)/BankAccount/BankAccountLedgerEntry (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 138, 'Tableextension field-group restore: LSCBarcodes/CheckLedgerEntry/CompanyInformation/CountryRegion (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 139, 'Tableextension field-group restore: Currency(+ExchangeRate)/CustLedgerEntry/Customer/CustomerPriceGroup (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 140, 'Tableextension field-group restore: GenJournalBatch/GenJournalLine/GenProductPostingGroup/GeneralLedgerSetup (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 141, 'Tableextension field-group restore: IssuedReminderHeader(+Line)/Item/ItemCategory (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 142, 'Tableextension field-group restore: ItemChargeAssignmentPurch/ItemJournalBatch(+Line)/ItemLedgerEntry (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 143, 'Tableextension field-group restore: LSCItemSpecialGroups/DXCashJournalReceiptList/Location (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 144, 'Tableextension field-group restore: LSCMemberContact/LSCMemberPointOffer(+Line) (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 145, 'Tableextension field-group restore: DXVendorWithholdingLedgerEntry/DXNCFSetup (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 146, 'Tableextension field-group restore: LSCPOSTransLine/LSCPOSTransaction/PaymentMethod (Leg-Norm pass)', 60146, 0, 0, 'OTHER');
        InsConcept('BELLON', 'BELLON-P2', 147, 'Tableextension field-group restore: LSCPeriodicDiscount/PostedAssemblyHeader/LSCPostedStatement (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 148, 'Tableextension field-group restore: LSCRetailProductGroup/PurchCommentLine(+Archive)/PurchInvLine (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 149, 'Tableextension field-group restore: ReasonCode/LSCReplenJournalLines/LSCReplenTemplate (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 150, 'Tableextension field-group restore: LSCRetailSetup/LSCRetailUser/SalesPrice(+Worksheet) (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 151, 'Tableextension field-group restore: SalesReceivablesSetup/LSCSalesType/SalespersonPurchaser (Leg-Norm pass)', 60146, 0, 0, 'SETUP');
        InsConcept('BELLON', 'BELLON-P2', 152, 'Tableextension field-group restore: ShiptoAddress/LSCStatement/LSCSTORE (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 153, 'Tableextension field-group restore: TariffNumber/LSCTenderType/LSCTransSalesEntry (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 154, 'Tableextension field-group restore: LSCTransactionHeader/TransferHeader/TransferLine (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 155, 'Tableextension field-group restore: TransferReceiptHeader/TransferShipmentHeader/UserSetup (Leg-Norm pass)', 60146, 0, 0, 'MA');
        InsConcept('BELLON', 'BELLON-P2', 156, 'Tableextension field-group restore: ValueEntry/Vendor/WarehouseReceiptLine (Leg-Norm pass)', 60146, 0, 0, 'MA');

        // ---- BELLONPOS: Bellon Customization POS ----
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 1, 'LSC Membership Card field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 2, 'BE DX Setup field restore', 60159, 0, 0, 'SETUP');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 3, 'LSC Coupon Header field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 4, 'LSC POS Trans. Line field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 5, 'LSC POS Command field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 6, 'LSC POS Terminal field restore', 60159, 0, 0, 'SETUP');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 7, 'LSC POS Transaction field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 8, 'LSC Trans. Sales Entry field restore', 60159, 0, 0, 'OTHER');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 9, 'LSC Trans Server Table Log field restore', 60159, 0, 0, 'HIST');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 10, 'POS Trans. Grouped RTC legacy table restore', 60159, 50300, 53563, 'HIST');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 11, 'POS Trans RTC legacy table restore', 60159, 50301, 53564, 'HIST');
        InsConcept('BELLONPOS', 'BELLONPOS-P2', 12, 'POS Trans. / Invalid Items RTC legacy table restore', 60159, 50302, 53565, 'HIST');

        // ---- DESLS: Despacho LS ----
        InsConcept('DESLS', 'DESLS-P1', 1, 'Document Generic legacy table restore', 60129, 50870, 53945, 'OTHER');
        InsConcept('DESLS', 'DESLS-P1', 2, 'Despacho LS Migr Status legacy table restore', 60129, 50871, 53946, 'HIST');
        // CORRECTED 2026-08-22: New Table IDs 53943/53945 didn't exist (53943 was a transposed
        // digit, 53945 was actually DocumentGeneric - a different table already used at
        // DESLS-P1 seq1). Real active IDs confirmed via source: DXR_Dispatch Line=53843,
        // DXR_Dispatch Setup=53845 (both in Despacho Base, cross-extension reference).
        InsConcept('DESLS', 'DESLS-P1FLD', 3, 'Dispatch Line: Store No./Document Reference field restore (50808 -> 53843)', 60130, 50808, 53843, 'MA');
        InsConcept('DESLS', 'DESLS-P1FLD', 4, 'Dispatch Setup: Enable Manual Gen. Doc. field restore (50800 -> 53845)', 60130, 50800, 53845, 'SETUP');
        InsConcept('DESLS', 'DESLS-P1FLD', 5, 'Log Reimpresiones Cond (table 50830): Staff ID field restore', 60130, 0, 0, 'HIST');
        InsConcept('DESLS', 'DESLS-P1FLD', 6, 'LSC Staff: 3 fields restore (Reprint Shipments/invoices, Del Dispatch Document)', 60130, 0, 0, 'SETUP');
        InsConcept('DESLS', 'DESLS-P1FLD', 7, 'LSC Retail User: Almacen Despacho field restore', 60130, 0, 0, 'SETUP');
        InsConcept('DESLS', 'DESLS-P1FLD', 8, 'Pickup Historic (table 50833): Store No. field restore', 60130, 0, 0, 'HIST');
        InsConcept('DESLS', 'DESLS-P1FLD', 9, 'Pickup List (table 50834): Store No. field restore', 60130, 0, 0, 'OTHER');
        InsConcept('DESLS', 'DESLS-P1FLD', 10, 'Posted Transport Line (table 50816): Store/Document Reference field restore', 60130, 0, 0, 'HIST');
        InsConcept('DESLS', 'DESLS-P1FLD', 11, 'LSC Retail Product Group: Comision_Cobro field restore', 60130, 0, 0, 'MA');
        InsConcept('DESLS', 'DESLS-P1FLD', 12, 'Transport Header (table 50801): Store field restore', 60130, 0, 0, 'MA');
        InsConcept('DESLS', 'DESLS-P1FLD', 13, 'Shipment Header (table 50813): Store No. field restore', 60130, 0, 0, 'MA');
        InsConcept('DESLS', 'DESLS-P1FLD', 14, 'Transport Line (table 50806): Store No./Document Reference field restore', 60130, 0, 0, 'MA');
        InsConcept('DESLS', 'DESLS-P1FLD', 15, 'Transport Log''s (table 50812): Document Reference field restore', 60130, 0, 0, 'HIST');
        InsConcept('DESLS', 'DESLS-P1FLD', 16, 'User Setup: Grupo Precios Tope/Supervisor field restore', 60130, 0, 0, 'SETUP');
        InsConcept('DESLS', 'DESLS-PERM', 17, 'Assign DXR_Despacho LS permission set to all users', 60129, 0, 0, 'SETUP');

        // ---- RC: Retail Controls ----
        InsConcept('RC', 'RC-P5', 1, 'LYT Controls Setup legacy table restore', 60135, 56529, 54726, 'SETUP');
        InsConcept('RC', 'RC-P5', 2, 'Pos Controls Setup legacy table restore', 60135, 56530, 54728, 'SETUP');
        InsConcept('RC', 'RC-P5', 3, 'Internal Migr Status legacy table restore', 60135, 56543, 54736, 'HIST');
        InsConcept('RC', 'RC-P1', 4, 'LYT Controls Setup legacy row restore (Setup Retro pass, runs before Phase 5''s own pass) - CORRECTED 2026-08-22, had zero Legacy/New Table ID before ("LYT. Controls Setup" 56500 -> active "DXR_LYT Controls Setup" 54726, same final target RC-P5 seq1 also feeds)', 60131, 56500, 54726, 'SETUP');
        InsConcept('RC', 'RC-P1', 5, 'Pos Controls Setup legacy row restore (Setup Retro pass) - CORRECTED 2026-08-22, had zero Legacy/New Table ID before ("Pos Controls Setup" 56501 -> active "DXR_Pos Controls Setup" 54728, same final target RC-P5 seq2 also feeds)', 60131, 56501, 54728, 'SETUP');
        InsConcept('RC', 'RC-P1', 6, 'Purchase/Sales Controls Setup field restore (cross-repo _DXR fields)', 60131, 0, 0, 'SETUP');
        InsConcept('RC', 'RC-P1', 7, 'LSC POS Func. Profile field restore', 60131, 0, 0, 'OTHER');
        InsConcept('RC', 'RC-P2', 8, 'Sales Header field restore (Documents Retro pass, high volume, batched 500/commit)', 60132, 0, 0, 'MA');
        InsConcept('RC', 'RC-P2', 9, 'Purchase Header field restore (Documents Retro pass, high volume, batched)', 60132, 0, 0, 'MA');
        InsConcept('RC', 'RC-P2', 10, 'Sales Invoice Header field restore (Documents Retro pass, high volume, batched)', 60132, 0, 0, 'MA');
        InsConcept('RC', 'RC-P3', 11, 'Cross-table field-ID collision retro-fix (ID Collision Retro: Sales Header/Sales Invoice Header/Purchase Header/LSC POS Func. Profile/DXR_Sales Controls Setup/DXR_Purchase Controls Setup, 9 fields, 54675-54677->56531-56538)', 60133, 0, 0, 'OTHER');
        InsConcept('RC', 'RC-P4', 12, 'Permission set assignment repair (all users, DXR_Retail Controls, PermSet Repair)', 60134, 0, 0, 'OTHER');

        // ---- FE: Facturacion Electronica ----
        // FE-P7/P8/P9/P10 expanded 2026-08-22 (follow-up completed - previously phase-level only,
        // flagged above as needing a dedicated read of each FieldMap dictionary). Read directly:
        // DXR_Upgrade_Clean.Codeunit.al's MigrateLegacyDependencyTableFields (Phase 7's 4 cross-
        // table field copies - the exact procedure whose wrong target field numbers caused
        // "DXR_Payment Method Relation" and the 3 NCF Setup tables to silently receive zero EF
        // field data, fixed this same session) and DXR_Migr_Phase_8/9/10's own CopySameTableFields
        // FieldMap.Add() calls (each phase's real per-table field list). P7 now carries its exact
        // Legacy/New table IDs for logging and one dispatcher per table. Its former 60136 entry
        // point also traversed five unbounded document-line tables while Current Step still showed
        // only the first NCF Purchase Setup concept; that unrelated repair is now its own row.
        // seq1-4 keep their original triples (same logical item, just corrected to the FIRST of
        // several sub-items each phase actually does - never repurposed to a different concept);
        // seq304+ are new, continuing after this extension's prior max (FE-P12 seq303).
        InsConcept('FE', 'FE-P7', 1, 'NCF Purchase Setup field restore (DXNCF Purchase Setup 54130 -> DXR_NCF Purchase Setup 52177, fields 55502->52334/55501->52333)', 60335, 54130, 52177, 'SETUP');
        InsConcept('FE', 'FE-P7', 304, 'NCF Sales Setup field restore (DXNCF Sales Setup 54131 -> DXR_NCF Sales Setup 52178, fields 55502->52334/55501->52333)', 60336, 54131, 52178, 'SETUP');
        InsConcept('FE', 'FE-P7', 305, 'NCF Setup field restore (DXNCF Setup 54132 -> DXR_NCF Setup 52179, field 55501->52333)', 60337, 54132, 52179, 'SETUP');
        InsConcept('FE', 'FE-P7', 306, 'Payment Method Relation field restore (DXPayment Method Relation 54133 -> DXR_Payment Method Relation 52180, fields 55502->52334/55501->52333)', 60338, 54133, 52180, 'SETUP');
        InsConcept('FE', 'FE-P7', 320, 'Purch. Cr. Memo Line Applies Withholding field repair', 60339, Database::"Purch. Cr. Memo Line", Database::"Purch. Cr. Memo Line", 'HIST');
        InsConcept('FE', 'FE-P7', 321, 'Purch. Inv. Line Applies Withholding field repair', 60340, Database::"Purch. Inv. Line", Database::"Purch. Inv. Line", 'HIST');
        InsConcept('FE', 'FE-P7', 322, 'Sales Line Applies Withholding field repair', 60341, Database::"Sales Line", Database::"Sales Line", 'MA');
        InsConcept('FE', 'FE-P7', 323, 'Sales Invoice Line Applies Withholding field repair', 60342, Database::"Sales Invoice Line", Database::"Sales Invoice Line", 'HIST');
        InsConcept('FE', 'FE-P7', 324, 'Sales Cr.Memo Line Applies Withholding field repair', 60343, Database::"Sales Cr.Memo Line", Database::"Sales Cr.Memo Line", 'HIST');
        InsConcept('FE', 'FE-P8', 2, 'Currency field restore (Currency Type_DXR, 1 field)', 60137, 0, 0, 'SETUP');
        InsConcept('FE', 'FE-P8', 307, 'Item field restore (Applies for ISC_DXR/Tax Type_DXR, 2 fields, batched)', 60137, 0, 0, 'MA');
        InsConcept('FE', 'FE-P8', 308, 'Post Code field restore (Township/County Code_DXR, 2 fields)', 60137, 0, 0, 'SETUP');
        InsConcept('FE', 'FE-P8', 309, 'Unit of Measure field restore (UOM Type_DXR, 1 field)', 60137, 0, 0, 'SETUP');
        InsConcept('FE', 'FE-P8', 310, 'VAT Posting Setup field restore (Tax Indicator_DXR, 1 field)', 60137, 0, 0, 'SETUP');
        InsConcept('FE', 'FE-P9', 3, 'Purch. Cr. Memo Hdr. field restore (15 fields)', 60138, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P9', 311, 'Purch. Cr. Memo Line field restore (3 fields)', 60138, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P9', 312, 'Purch. Inv. Header field restore (17 fields)', 60138, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P9', 313, 'Purch. Inv. Line field restore (3 fields)', 60138, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P9', 314, 'Purchase Header field restore (NCF Mod. Reason_DXR, 1 field, open documents)', 60138, 0, 0, 'MA');
        InsConcept('FE', 'FE-P10', 4, 'Sales Cr.Memo Header field restore (15 fields)', 60139, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P10', 315, 'Sales Cr.Memo Line field restore (3 fields)', 60139, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P10', 316, 'Sales Header field restore (2 fields incl. NCF Mod. Reason_DXR, open documents)', 60139, 0, 0, 'MA');
        InsConcept('FE', 'FE-P10', 317, 'Sales Invoice Header field restore (16 fields)', 60139, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P10', 318, 'Sales Invoice Line field restore (3 fields)', 60139, 0, 0, 'HIST');
        InsConcept('FE', 'FE-P10', 319, 'Sales Line field restore (3 fields, open documents)', 60139, 0, 0, 'MA');
        InsConcept('FE', 'FE-P11', 5, 'EF Administration Setup legacy table restore (55501 -> 52468)', 60140, 55501, 52468, 'SETUP');
        InsConcept('FE', 'FE-P13', 7, 'Phase 13 NCF Cleanup: ClearInvalidNCFAffectedValues', 60142, 0, 0, 'MA');
        // Expanded 2026-08-22: FE-P11/P12 were phase-level only (0/0), covering 35 legacy tables
        // with zero individual row-count/gap tracking. Full list read directly from
        // DXR_Migr_Phase_11_Tables.Codeunit.al (dispatcher 52542) and
        // DXR_Migr_Phase_12_History.Codeunit.al (dispatcher 52522)'s own Database::"X" calls.
        InsConcept('FE', 'FE-P11', 270, 'EF Archived E Documents legacy table restore (55502 -> 52470)', 60140, 55502, 52470, 'HIST');
        InsConcept('FE', 'FE-P11', 271, 'EF Archived Sent Request legacy table restore (55503 -> 52472, custom scoring-merge logic not a plain copy)', 60140, 55503, 52472, 'HIST');
        InsConcept('FE', 'FE-P11', 272, 'EF Bulk Credit Memo Entry legacy table restore (55532 -> 52474)', 60140, 55532, 52474, 'MA');
        InsConcept('FE', 'FE-P11', 273, 'EF Bulk Credit Memo Log legacy table restore (55533 -> 52476)', 60140, 55533, 52476, 'HIST');
        InsConcept('FE', 'FE-P11', 274, 'EF Bulk NCF Import Entry legacy table restore (55575 -> 52478)', 60140, 55575, 52478, 'MA');
        InsConcept('FE', 'FE-P11', 275, 'EF Codigos Item legacy table restore (55504 -> 52479, custom key-based merge)', 60140, 55504, 52479, 'MA');
        InsConcept('FE', 'FE-P11', 276, 'EF Currency Type legacy table restore (55505 -> 52480, custom key-based merge)', 60140, 55505, 52480, 'SETUP');
        InsConcept('FE', 'FE-P11', 277, 'EF Descuentos O Recargos legacy table restore (55506 -> 52481)', 60140, 55506, 52481, 'MA');
        InsConcept('FE', 'FE-P11', 278, 'EF Detalle Bienes o Servicios legacy table restore (55507 -> 52482)', 60140, 55507, 52482, 'MA');
        InsConcept('FE', 'FE-P11', 279, 'EF Encabezado legacy table restore (55508 -> 52483)', 60140, 55508, 52483, 'MA');
        InsConcept('FE', 'FE-P11', 280, 'EF Formas de Pago legacy table restore (55509 -> 52485)', 60140, 55509, 52485, 'SETUP');
        InsConcept('FE', 'FE-P11', 281, 'EF Form Type legacy table restore (55529 -> 52484)', 60140, 55529, 52484, 'SETUP');
        InsConcept('FE', 'FE-P11', 282, 'EF Imp. Adicionales - Encab. legacy table restore (55510 -> 52486)', 60140, 55510, 52486, 'MA');
        InsConcept('FE', 'FE-P11', 283, 'EF Impuestos Adicionales - DBS legacy table restore (55511 -> 52487)', 60140, 55511, 52487, 'MA');
        InsConcept('FE', 'FE-P11', 284, 'EF Income Validation Type legacy table restore (55512 -> 52488)', 60140, 55512, 52488, 'SETUP');
        InsConcept('FE', 'FE-P11', 285, 'EF Informacion Referencia legacy table restore (55513 -> 52489)', 60140, 55513, 52489, 'MA');
        InsConcept('FE', 'FE-P11', 286, 'EF Log Message legacy table restore (55514 -> 52490)', 60140, 55514, 52490, 'HIST');
        InsConcept('FE', 'FE-P11', 287, 'EF Modification Code Type legacy table restore (55515 -> 52491)', 60140, 55515, 52491, 'SETUP');
        InsConcept('FE', 'FE-P11', 288, 'EF Paginacion legacy table restore (55516 -> 52492)', 60140, 55516, 52492, 'SETUP');
        InsConcept('FE', 'FE-P11', 289, 'EF Payment Type Form legacy table restore (55517 -> 52493)', 60140, 55517, 52493, 'SETUP');
        InsConcept('FE', 'FE-P11', 290, 'EF Process Request legacy table restore (55518 -> 52494)', 60140, 55518, 52494, 'MA');
        InsConcept('FE', 'FE-P11', 291, 'EF Receipt Acknowledgement legacy table restore (55519 -> 52496)', 60140, 55519, 52496, 'HIST');
        InsConcept('FE', 'FE-P11', 292, 'EF Resend Document Queue legacy table restore (55531 -> 52498)', 60140, 55531, 52498, 'MA');
        InsConcept('FE', 'FE-P11', 293, 'EF Resend Job Log legacy table restore (55530 -> 52499)', 60140, 55530, 52499, 'HIST');
        InsConcept('FE', 'FE-P11', 294, 'EF Response Documents legacy table restore (55520 -> 52500)', 60140, 55520, 52500, 'MA');
        InsConcept('FE', 'FE-P11', 295, 'EF Subcantidad legacy table restore (55521 -> 52504)', 60140, 55521, 52504, 'MA');
        InsConcept('FE', 'FE-P11', 296, 'EF SubDescuento legacy table restore (55522 -> 52501)', 60140, 55522, 52501, 'MA');
        InsConcept('FE', 'FE-P11', 297, 'EF SubRecargo legacy table restore (55523 -> 52502)', 60140, 55523, 52502, 'MA');
        InsConcept('FE', 'FE-P11', 298, 'EF SubTotales Informativos legacy table restore (55524 -> 52503)', 60140, 55524, 52503, 'MA');
        InsConcept('FE', 'FE-P11', 299, 'EF Tax Coding Type legacy table restore (55525 -> 52505)', 60140, 55525, 52505, 'SETUP');
        InsConcept('FE', 'FE-P11', 300, 'EF Telefono Emisor legacy table restore (55526 -> 52506)', 60140, 55526, 52506, 'SETUP');
        InsConcept('FE', 'FE-P11', 301, 'EF Township legacy table restore (55527 -> 52507)', 60140, 55527, 52507, 'SETUP');
        InsConcept('FE', 'FE-P11', 302, 'EF Unit of Measure Type legacy table restore (55528 -> 52508)', 60140, 55528, 52508, 'SETUP');
        InsConcept('FE', 'FE-P12', 6, 'EF Payload Text Chunk legacy table restore (55703 -> 52524)', 60141, 55703, 52524, 'HIST');
        InsConcept('FE', 'FE-P12', 303, 'EF ATEB Send Registry legacy table restore (55610 -> 52509, has an enum re-mapping step)', 60141, 55610, 52509, 'HIST');

        // ---- LSFE: LS Facturacion Electronica (2 on-demand background repairs, both scheduled by the "Run Migration Now" action on DXR_LSFE Migration Status) ----
        InsConcept('LSFE', 'LSFE-P1', 1, 'Assign PermSet to all users (background worker, runs synchronously when invoked directly)', 60144, 0, 0, 'SETUP');
        InsConcept('LSFE', 'LSFE-P2', 2, 'Legacy fields to DXR + POS contingency-authority repair (background worker, runs synchronously when invoked directly)', 60145, 0, 0, 'OTHER');

        // ---- LSLOC: LS Central DR Localization. Each registry concept points to the smallest
        // callable MCC dispatcher available. In particular, setup field restores must never share
        // one dispatcher: doing so held Label Functions plus the following setup tables in the
        // same transaction while Current Step misleadingly advanced to another concept. ----
        InsConcept('LSLOC', 'LSLOC-OPOS', 1, 'OPOS Setup: DXR_Gaps Setup -> DXR_LS OPOS Print Setup field copy (fixes the documented SOLUCION_NCF_UPGRADE.md silent-migration-failure incident)', 60161, 0, 0, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 2, 'Gen. Journal Line field range restore (same-table, via "DXR_LS TableExt Fields Upgrade" 54510)', 60174, Database::"Gen. Journal Line", Database::"Gen. Journal Line", 'MA');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 3, 'Archived Consumer Sales 607 dependency-field sync (54104 field range -> 52111, target rows must pre-exist, via "DXR_LS Dependency Fields Upgr." 54512)', 60178, 0, 0, 'MA');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 4, 'LSDX POS Setup legacy table restore (54300 -> 54492, via "DXR_LS Legacy Tables Upgrade" 54511)', 60171, 54300, 54492, 'SETUP');
        // Breakdown read directly from "DXR_LS TableExt Fields Upgrade" (54510),
        // "DXR_LS Dependency Fields Upgr." (54512), and "DXR_LS Legacy Tables Upgrade" (54511).
        // MCC-owned normal codeunits expose their operations safely outside schema sync and keep
        // idempotence at one Upgrade Tag per callable unit.
        InsConcept('LSLOC', 'LSLOC-TOLOC', 5, 'Item field range restore (same-table)', 60174, Database::Item, Database::Item, 'MA');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 6, 'LSC Hospitality Type field range restore (same-table)', 60172, Database::"LSC Hospitality Type", Database::"LSC Hospitality Type", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 7, 'LSC Label Functions field range restore (same-table)', 60180, Database::"LSC Label Functions", Database::"LSC Label Functions", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 8, 'LSC POS Print Setup Header field range restore (same-table)', 60181, Database::"LSC POS Print Setup Header", Database::"LSC POS Print Setup Header", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 9, 'LSC POS Terminal field range restore (same-table, 2 ranges)', 60182, Database::"LSC POS Terminal", Database::"LSC POS Terminal", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 10, 'LSC POS Transaction field range restore (same-table, 2 ranges)', 60175, Database::"LSC POS Transaction", Database::"LSC POS Transaction", 'OTHER');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 11, 'LSC Sales Type field range restore (same-table)', 60183, Database::"LSC Sales Type", Database::"LSC Sales Type", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 12, 'LSC Store field range restore (same-table)', 60184, Database::"LSC Store", Database::"LSC Store", 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 13, 'LSC Store Inventory Line field range restore (same-table)', 60174, Database::"LSC Store Inventory Line", Database::"LSC Store Inventory Line", 'MA');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 14, 'LSC Transaction Header field range restore (same-table, 3 ranges)', 60175, Database::"LSC Transaction Header", Database::"LSC Transaction Header", 'OTHER');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 15, 'Consumer Sales 607 Buffer dependency-field sync (54150 -> 52213, target rows must pre-exist)', 60178, 0, 0, 'MA');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 16, 'Gaps Setup dependency-field sync (54122 -> 52165, target rows must pre-exist - same table pair as DRLOC-GAP seq98''s full-row restore, different action)', 60177, 0, 0, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 17, 'NCF Setup dependency-field sync (54132 -> 52179, target rows must pre-exist)', 60177, 0, 0, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 18, 'Report Sales 607 Buffer dependency-field sync (54151 -> 52215, target rows must pre-exist)', 60179, 0, 0, 'HIST');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 19, 'Archived Sales 607 dependency-field sync (54106 -> 52115, target rows must pre-exist)', 60179, 0, 0, 'HIST');
        InsConcept('LSLOC', 'LSLOC-DEPFLD', 20, 'NCF Sales Setup dependency-field sync (54131 -> 52178, target rows must pre-exist)', 60177, 0, 0, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 21, 'LSDXTender Types Relation legacy table restore (54301 -> 54493)', 60173, 54301, 54493, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 22, 'LSDX OPOS Print Setup legacy table restore (54302 -> 54494)', 60173, 54302, 54494, 'SETUP');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 23, 'LSDX POS 607 Diagnostic legacy table restore (54324 -> 54495)', 60176, 54324, 54495, 'HIST');
        InsConcept('LSLOC', 'LSLOC-TOLOC', 24, 'LSDX LS NCF Process Reg. legacy table restore (54328 -> 54496)', 60176, 54328, 54496, 'HIST');
    end;

    local procedure InsExt(Code2: Code[20]; Name2: Text[100]; AppIdText: Text; OrderNo: Integer; Notes2: Text)
    var
        Ext: Record "DXR MCC Extension";
        AppIdGuid: Guid;
    begin
        // Notes2 is an unbounded Text on purpose: a literal longer than Ext.Notes' Text[250]
        // passed directly to a Text[250] parameter throws a runtime "length of the string...
        // must be less than or equal to 250" error at the call site (confirmed - this broke
        // Reload Registry entirely for every extension, not just the one whose note overflowed,
        // since LoadExtensions() is one straight-line procedure). CopyStr here truncates instead
        // of crashing, and doing it once in InsExt means no future note-length edit can repeat
        // this - callers don't need to remember to check.
        if AppIdText <> '' then
            Evaluate(AppIdGuid, AppIdText);
        if Ext.Get(Code2) then begin
            Ext.Name := Name2;
            Ext."App ID" := AppIdGuid;
            Ext."Order No." := OrderNo;
            Ext.Notes := CopyStr(Notes2, 1, MaxStrLen(Ext.Notes));
            Ext.Modify(true);
        end else begin
            Ext.Init();
            Ext.Code := Code2;
            Ext.Name := Name2;
            Ext."App ID" := AppIdGuid;
            Ext."Order No." := OrderNo;
            Ext.Notes := CopyStr(Notes2, 1, MaxStrLen(Ext.Notes));
            Ext.Insert(true);
        end;
    end;

    local procedure InsConcept(ExtCode: Code[20]; PhaseCode: Code[20]; SeqNo: Integer; Desc: Text; DispatcherId: Integer; LegacyId: Integer; NewId: Integer; CategoryCode: Code[10])
    var
        Concept: Record "DXR MCC Concept";
    begin
        DispatcherId := ResolveCategoryDispatcher(ExtCode, DispatcherId, CategoryCode);
        // Blocked/Blocked Reason are NOT set here - they are operator-controlled state (via the
        // Concept Subform) reflecting whether an extension currently compiles/publishes. Reloading
        // the registry must never silently re-block or re-unblock a concept the operator already
        // triaged; only description/dispatcher/table-ID/category metadata is refreshed from source.
        Concept.SetRange("Extension Code", ExtCode);
        Concept.SetRange("Phase Code", PhaseCode);
        Concept.SetRange("Sequence No.", SeqNo);
        if Concept.FindFirst() then begin
            Concept.Description := CopyStr(Desc, 1, MaxStrLen(Concept.Description));
            Concept."Dispatcher Codeunit ID" := DispatcherId;
            Concept."Legacy Table ID" := LegacyId;
            Concept."New Table ID" := NewId;
            Concept.Category := CategoryOption(CategoryCode);
            Concept.Retired := (DispatcherId = 0) and (LegacyId = 0) and (NewId = 0);
            Concept.Modify(true);
        end else begin
            Concept.Init();
            Concept."Extension Code" := ExtCode;
            Concept."Phase Code" := PhaseCode;
            Concept."Sequence No." := SeqNo;
            Concept.Description := CopyStr(Desc, 1, MaxStrLen(Concept.Description));
            Concept."Dispatcher Codeunit ID" := DispatcherId;
            Concept."Legacy Table ID" := LegacyId;
            Concept."New Table ID" := NewId;
            Concept.Category := CategoryOption(CategoryCode);
            Concept.Retired := (DispatcherId = 0) and (LegacyId = 0) and (NewId = 0);
            Concept.Status := Concept.Status::"Not Counted";
            Concept.Insert(true);
        end;
    end;

    local procedure ResolveCategoryDispatcher(ExtCode: Code[20]; DispatcherId: Integer; CategoryCode: Code[10]): Integer
    begin
        case ExtCode of
            'DXP':
                case DispatcherId of
                    60080: exit(CategoryDispatcher(CategoryCode, 60200, 60201, 60202, 0));
                    60081: exit(CategoryDispatcher(CategoryCode, 60203, 60204, 0, 0));
                    60082: exit(CategoryDispatcher(CategoryCode, 60205, 60206, 60207, 0));
                    60083: exit(CategoryDispatcher(CategoryCode, 60208, 60209, 60210, 0));
                    60084: exit(CategoryDispatcher(CategoryCode, 60211, 60212, 60213, 0));
                    60085: exit(CategoryDispatcher(CategoryCode, 60214, 60215, 0, 0));
                end;
            'VP':
                case DispatcherId of
                    60115: exit(CategoryDispatcher(CategoryCode, 60216, 60217, 0, 0));
                    60116: exit(CategoryDispatcher(CategoryCode, 0, 60218, 60219, 0));
                    60118: exit(CategoryDispatcher(CategoryCode, 0, 60220, 60221, 0));
                    60121: exit(CategoryDispatcher(CategoryCode, 60222, 60223, 60224, 60225));
                end;
            'PCM':
                case DispatcherId of
                    60122: exit(CategoryDispatcher(CategoryCode, 60226, 60227, 0, 0));
                    60123: exit(CategoryDispatcher(CategoryCode, 60228, 0, 0, 60229));
                    60125: exit(CategoryDispatcher(CategoryCode, 60230, 60231, 60232, 60233));
                end;
            'TU':
                if DispatcherId = 60126 then
                    exit(CategoryDispatcher(CategoryCode, 60234, 60235, 0, 0));
            'FE':
                case DispatcherId of
                    60137: exit(CategoryDispatcher(CategoryCode, 60300, 60301, 0, 0));
                    60138: exit(CategoryDispatcher(CategoryCode, 0, 60302, 60303, 0));
                    60139: exit(CategoryDispatcher(CategoryCode, 0, 60304, 60305, 0));
                    60140: exit(CategoryDispatcher(CategoryCode, 60306, 60307, 60308, 0));
                end;
            'BELLON':
                case DispatcherId of
                    60146: exit(CategoryDispatcher(CategoryCode, 60309, 60310, 60311, 60312));
                    60150: exit(CategoryDispatcher(CategoryCode, 60313, 60314, 60315, 60316));
                    60155: exit(CategoryDispatcher(CategoryCode, 60317, 60318, 0, 0));
                    60157: exit(CategoryDispatcher(CategoryCode, 60319, 60320, 0, 0));
                end;
            'BELLONPOS':
                if DispatcherId = 60159 then
                    exit(CategoryDispatcher(CategoryCode, 60321, 0, 60322, 60323));
            'DRLOC':
                case DispatcherId of
                    60165: exit(CategoryDispatcher(CategoryCode, 60324, 60325, 0, 0));
                    60167: exit(CategoryDispatcher(CategoryCode, 0, 60326, 60327, 0));
                    60168: exit(CategoryDispatcher(CategoryCode, 0, 60328, 60329, 0));
                    60169: exit(CategoryDispatcher(CategoryCode, 0, 60330, 60331, 0));
                    60170: exit(CategoryDispatcher(CategoryCode, 60332, 0, 60333, 60334));
                end;
            'DESB':
                if DispatcherId = 60127 then
                    case CategoryCode of
                        'SETUP': exit(60250);
                        'MA': exit(60251);
                        'HIST': exit(60252);
                        'OTHER': exit(60253);
                    end;
            'DESLS':
                if DispatcherId in [60129, 60130] then
                    case CategoryCode of
                        'SETUP': exit(60254);
                        'MA': exit(60255);
                        'HIST': exit(60256);
                        'OTHER': exit(60257);
                    end;
            'RC':
                if DispatcherId in [60131, 60135] then
                    case CategoryCode of
                        'SETUP': exit(60258);
                        'HIST': exit(60259);
                        'OTHER': exit(60260);
                    end;
        end;
        exit(DispatcherId);
    end;

    local procedure CategoryDispatcher(CategoryCode: Code[10]; SetupId: Integer; MasterId: Integer; HistoricId: Integer; OtherId: Integer): Integer
    begin
        case CategoryCode of
            'SETUP': if SetupId <> 0 then exit(SetupId);
            'MA': if MasterId <> 0 then exit(MasterId);
            'HIST': if HistoricId <> 0 then exit(HistoricId);
            'OTHER': if OtherId <> 0 then exit(OtherId);
        end;
        Error('No category dispatcher is registered for category %1.', CategoryCode);
    end;

    local procedure CategoryOption(CategoryCode: Code[10]): Option Setup,"Master/Accounting",Historic,Other
    var
        Concept: Record "DXR MCC Concept";
    begin
        case CategoryCode of
            'SETUP':
                exit(Concept.Category::Setup);
            'MA':
                exit(Concept.Category::"Master/Accounting");
            'HIST':
                exit(Concept.Category::Historic);
            else
                exit(Concept.Category::Other);
        end;
    end;

    local procedure UnblockDespachoBase()
    var
        Concept: Record "DXR MCC Concept";
    begin
        // One-time correction: earlier registry versions hardcoded every DESB concept as Blocked
        // because Despacho Base didn't compile yet. It compiles clean as of 28.3.4.17 - clear the
        // stale block left over from that period so its phases can actually run.
        Concept.SetRange("Extension Code", 'DESB');
        Concept.SetRange(Blocked, true);
        Concept.SetRange("Blocked Reason", 'Extension does not currently compile - see Extension Notes.');
        if not Concept.FindSet(true) then
            exit;
        repeat
            Concept.Blocked := false;
            Concept."Blocked Reason" := '';
            Concept.Modify(true);
        until Concept.Next() = 0;
    end;
}
