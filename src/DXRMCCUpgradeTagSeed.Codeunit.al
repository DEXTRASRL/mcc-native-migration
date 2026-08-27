codeunit 60018 "DXR MCC Upgrade Tag Seed"
{
    // Fills in "DXR MCC Concept"."Upgrade Tags" with verified, source-confirmed tag literals for
    // concepts whose dispatcher gates each row/table individually - never called by Reload Registry
    // (see DXRMCCRegistryLoader.InsConcept, which deliberately never touches this operator field),
    // and never overwrites a value the operator already set: only blank rows are filled. Run
    // explicitly via the "Seed Known Upgrade Tags" action on the main page.
    //
    // Built 2026-08-22 via a portfolio-wide sweep (one investigation per extension) that read each
    // extension's actual dispatcher/upgrade-tag source to find the real HasUpgradeTag/SetUpgradeTag
    // literal gating each concept - never guessed/pattern-derived without verification. A tag shared
    // by several concepts (one phase gating many tables/fields in a single pass) is expected and
    // correct, not a mistake - Force Rerun on any one of those concepts will re-run its siblings too.
    // Concepts deliberately left unseeded (no SeedIfBlank call below) fall into one of: no
    // HasUpgradeTag gate exists at all (compile-time fix, dead code, or platform-only
    // OnUpgradePerCompany with no app-level tag), the concept is bundled under MULTIPLE independent
    // tags with no single literal covering it, or the owning code could not be confidently traced.
    // Extending this list requires the same source-read discipline - do not add a tag without having
    // actually read the literal string in the target extension.
    //
    // Known gap: Bellon Customization's Phase 13 ("Bellon Migr. Phase 13 OldGap", added 2026-08-22
    // in the same session as this sweep) retroactively fixes 3 tables whose concepts already exist
    // under BELLON-P2 with tag 'DXR-BELLON-TABLEEXT-FIELDS-NORM-28.3-1' - Force Rerun on those 3
    // specific concepts would clear that Phase 2 tag and re-run the ORIGINAL (still-incomplete for
    // those 3 fields) logic, not Phase 13's fix. Phase 13 has its own separate tag
    // ('BELLON-MIGR-PHASE13-OLDDXRBRIDGEGAP-COMPLETED-20260822') that isn't wired to any single
    // concept below - identifying exactly which of the ~130 BELLON-P2 sequence numbers correspond to
    // those 3 tables was out of scope for this sweep.
    internal procedure SeedAllKnownTags()
    var
        SeededCount: Integer;
    begin
        SeededCount := 0;
        SeedDespachoBaseP1(SeededCount);
        SeedDespachoBaseOther(SeededCount);
        SeedBaseControls(SeededCount);
        SeedRetailControls(SeededCount);
        SeedDespachoLS(SeededCount);
        SeedDescuentoProntoPago(SeededCount);
        SeedDRLocalization(SeededCount);
        SeedDXPayments(SeededCount);
        SeedFacturacionElectronica(SeededCount);
        SeedLSFacturacionElectronica(SeededCount);
        SeedLSLocalizacionBase(SeededCount);
        SeedPriceControlsMgt(SeededCount);
        SeedIfBlank('REPORTING', 'REPORTING-P1', 1, 'DXR-MCC-REPORTING-ID-MIGRATION-20260825.', SeededCount);
        SeedRecaudoBPD(SeededCount);
        SeedSpecialDispatch(SeededCount);
        SeedTransUnion(SeededCount);
        SeedVendorPayloads(SeededCount);
        SeedBellonCustomization(SeededCount);
        SeedBellonPOS(SeededCount);
        Message('Seeded Upgrade Tags for %1 concept(s) that had it blank. Concepts already carrying an operator-set value were left untouched.', SeededCount);
    end;

    // Despacho Base (DESB), phase DESB-P1, dispatcher codeunit 53681 "DXR_Despacho Migr Worker" ->
    // MigrateRenumberedTablesIfNeeded() -> MigrateTable01..MigrateTable39, each individually gated by
    // its own 'DXR-DESPACHOBASE-TABLEMIGR-<NN>-<LegacyTableId>-28.3' tag (verified 2026-08-22 by
    // reading every MigrateTableNN's HasUpgradeTag/SetUpgradeTag literal directly in
    // DXRDespachoMigrWorker.Codeunit.al - NN is this table's position in that file, NOT the same as
    // this concept's own Sequence No. below, since InsConcept lists these alphabetically by
    // description while MigrateTableNN follows the file's original authoring order). The mapping
    // (Sequence No. -> NN) below was built by matching each concept's Legacy Table ID against the
    // "// Table NN: old id <LegacyTableId>" comment on every one of the 39 procedures - not derived
    // by position/pattern.
    local procedure SeedDespachoBaseP1(var SeededCount: Integer)
    begin
        SeedIfBlank('DESB', 'DESB-P1', 1, 'DXR-DESPACHOBASE-TABLEMIGR-01-50809-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 2, 'DXR-DESPACHOBASE-TABLEMIGR-02-50836-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 3, 'DXR-DESPACHOBASE-TABLEMIGR-03-50820-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 4, 'DXR-DESPACHOBASE-TABLEMIGR-11-50817-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 5, 'DXR-DESPACHOBASE-TABLEMIGR-12-50807-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 6, 'DXR-DESPACHOBASE-TABLEMIGR-13-50808-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 7, 'DXR-DESPACHOBASE-TABLEMIGR-14-50800-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 8, 'DXR-DESPACHOBASE-TABLEMIGR-04-50851-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 9, 'DXR-DESPACHOBASE-TABLEMIGR-05-50818-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 10, 'DXR-DESPACHOBASE-TABLEMIGR-06-50823-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 11, 'DXR-DESPACHOBASE-TABLEMIGR-07-50822-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 12, 'DXR-DESPACHOBASE-TABLEMIGR-08-50821-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 13, 'DXR-DESPACHOBASE-TABLEMIGR-10-50852-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 14, 'DXR-DESPACHOBASE-TABLEMIGR-09-50826-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 15, 'DXR-DESPACHOBASE-TABLEMIGR-15-50837-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 16, 'DXR-DESPACHOBASE-TABLEMIGR-16-50838-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 17, 'DXR-DESPACHOBASE-TABLEMIGR-17-50828-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 18, 'DXR-DESPACHOBASE-TABLEMIGR-18-50830-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 19, 'DXR-DESPACHOBASE-TABLEMIGR-19-50814-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 20, 'DXR-DESPACHOBASE-TABLEMIGR-20-50831-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 21, 'DXR-DESPACHOBASE-TABLEMIGR-21-50832-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 22, 'DXR-DESPACHOBASE-TABLEMIGR-22-50833-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 23, 'DXR-DESPACHOBASE-TABLEMIGR-23-50834-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 24, 'DXR-DESPACHOBASE-TABLEMIGR-24-50819-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 25, 'DXR-DESPACHOBASE-TABLEMIGR-25-50811-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 26, 'DXR-DESPACHOBASE-TABLEMIGR-26-50816-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 27, 'DXR-DESPACHOBASE-TABLEMIGR-27-50835-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 28, 'DXR-DESPACHOBASE-TABLEMIGR-28-50825-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 29, 'DXR-DESPACHOBASE-TABLEMIGR-29-50824-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 30, 'DXR-DESPACHOBASE-TABLEMIGR-30-50813-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 31, 'DXR-DESPACHOBASE-TABLEMIGR-31-50815-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 32, 'DXR-DESPACHOBASE-TABLEMIGR-38-50803-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 33, 'DXR-DESPACHOBASE-TABLEMIGR-32-50810-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 34, 'DXR-DESPACHOBASE-TABLEMIGR-33-50804-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 35, 'DXR-DESPACHOBASE-TABLEMIGR-34-50801-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 36, 'DXR-DESPACHOBASE-TABLEMIGR-35-50806-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 37, 'DXR-DESPACHOBASE-TABLEMIGR-36-50812-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 38, 'DXR-DESPACHOBASE-TABLEMIGR-37-50805-28.3', SeededCount);
        SeedIfBlank('DESB', 'DESB-P1', 39, 'DXR-DESPACHOBASE-TABLEMIGR-39-50802-28.3', SeededCount);
    end;

    // Despacho Base (DESB), the 3 concepts beyond DESB-P1: Sales Header/Transfer Header field
    // restores (dispatcher 53908 "DXR_Despacho Migr Phase 2", per-table Tag() helper) and the
    // permission-set repair (GetPermissionSetRepairTag(), shared between the scheduling gate and
    // DXRDespachoMigrWorker's EnsurePermissionSetsAssignedIfNeeded).
    local procedure SeedDespachoBaseOther(var SeededCount: Integer)
    begin
        SeedIfBlank('DESB', 'DESB-P2', 40, 'DXR-DespachoBase-MigrPhase2-SALESHEADER-NAME-FALLBACK-20260826', SeededCount);
        SeedIfBlank('DESB', 'DESB-P2', 41, 'DXR-DespachoBase-MigrPhase2-TRANSFERHEADER-NAME-FALLBACK-20260826', SeededCount);
        SeedIfBlank('DESB', 'DESB-PERM', 42, 'DXR-DespachoBase-PermSetRepair-28.3-20260820', SeededCount);
    end;

    // Base Controls (BC): DXR_BC Migr Phase 1/2/3, each phase gated by ONE shared tag checked once
    // before running all of that phase's Copy* procedures (DXR_BC Migr Scheduler.RunPhase) - no
    // per-table/per-field tag exists anywhere in these 3 codeunits. BC-PERM has its own dedicated tag.
    local procedure SeedBaseControls(var SeededCount: Integer)
    begin
        SeedIfBlank('BC', 'BC-P2', 1, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 2, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 3, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 4, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 5, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 6, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P2', 7, 'DXR-BC-MIGR-PHASE2-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P3', 8, 'DXR-BC-MIGR-PHASE3-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P3', 9, 'DXR-BC-MIGR-PHASE3-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P3', 10, 'DXR-BC-MIGR-PHASE3-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P3', 11, 'DXR-BC-MIGR-PHASE3-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P3', 12, 'DXR-BC-MIGR-PHASE3-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 13, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 14, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 15, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 16, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 17, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-P1', 18, 'DXR-BC-MIGR-PHASE1-28.3', SeededCount);
        SeedIfBlank('BC', 'BC-PERM', 19, 'DXR-BC-PERMISSIONSET-REPAIR-28.3', SeededCount);
    end;

    // Retail Controls (RC): 5 phases, each gated by one shared tag (DXRInternalMigrPhaseTags).
    local procedure SeedRetailControls(var SeededCount: Integer)
    begin
        SeedIfBlank('RC', 'RC-P5', 1, 'DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820', SeededCount);
        SeedIfBlank('RC', 'RC-P5', 2, 'DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820', SeededCount);
        SeedIfBlank('RC', 'RC-P5', 3, 'DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820', SeededCount);
        SeedIfBlank('RC', 'RC-P1', 4, 'DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P1', 5, 'DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P1', 6, 'DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P1', 7, 'DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P2', 8, 'DXR-RC-PHASE2-DOCUMENTS-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P2', 9, 'DXR-RC-PHASE2-DOCUMENTS-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P2', 10, 'DXR-RC-PHASE2-DOCUMENTS-RETROACTIVE-20260817', SeededCount);
        SeedIfBlank('RC', 'RC-P3', 11, 'DXR-RC-PHASE3-IDCOLLISION-RETROACTIVE-20260820', SeededCount);
        SeedIfBlank('RC', 'RC-P4', 12, 'DXR-RC-PERMSET-ASSIGN-REPAIR-20260820', SeededCount);
    end;

    // Despacho LS (DESLS): 2 whole-table tags (DXR-DESPACHOLS-TABLEMIGR-NN) plus per-table field
    // restores under DXR_DespachoLS Migr Phase1, each with its own tag, plus permission repair.
    local procedure SeedDespachoLS(var SeededCount: Integer)
    begin
        SeedIfBlank('DESLS', 'DESLS-P1', 1, 'DXR-DESPACHOLS-TABLEMIGR-01-50870-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1', 2, 'DXR-DESPACHOLS-TABLEMIGR-02-50871-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 3, 'DXR-DespachoLS-MigrPhase1-DISPATCHLINE-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 4, 'DXR-DespachoLS-MigrPhase1-DISPATCHSETUP-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 5, 'DXR-DespachoLS-MigrPhase1-LOGREIMPRESIONESCOND-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 6, 'DXR-DespachoLS-MigrPhase1-STAFF-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 7, 'DXR-DespachoLS-MigrPhase1-RETAILUSER-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 8, 'DXR-DespachoLS-MigrPhase1-PICKUPHISTORIC-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 9, 'DXR-DespachoLS-MigrPhase1-PICKUPLIST-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 10, 'DXR-DespachoLS-MigrPhase1-POSTEDTRANSPORTLINE-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 11, 'DXR-DespachoLS-MigrPhase1-RETAILPRODUCTGROUP-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 12, 'DXR-DespachoLS-MigrPhase1-TRANSPORTHEADER-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 13, 'DXR-DespachoLS-MigrPhase1-SHIPMENTHEADER-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 14, 'DXR-DespachoLS-MigrPhase1-TRANSPORTLINE-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 15, 'DXR-DespachoLS-MigrPhase1-TRANSPORTLOGS-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-P1FLD', 16, 'DXR-DespachoLS-MigrPhase1-USERSETUP-28.3', SeededCount);
        SeedIfBlank('DESLS', 'DESLS-PERM', 17, 'DXR-DespachoLS-PermSetRepair-28.3-20260820', SeededCount);
    end;

    // DescuentoProntoPago (DPP): Phase 5/6 each have their own tag; the 3rd concept (DPP Upgrade
    // Manager, OLD extension only) has no app-level tag - platform upgrade-codeunit mechanism only.
    local procedure SeedDescuentoProntoPago(var SeededCount: Integer)
    begin
        SeedIfBlank('DPP', 'DPP-P5', 1, 'DXR-Prontopago-28.3-Phase5-Renumber461a341-Tables', SeededCount);
        SeedIfBlank('DPP', 'DPP-P6', 2, 'DXR-Prontopago-28.3-Phase6-Renumber461a341-TableExtensionFields', SeededCount);
    end;

    // Base App DR Localization (DRLOC): phase-level tags for Phase 2-6, individual tags for the
    // standalone DXR_Internal_Closure_Migration_Upgrade_Clean.al table/field procedures (DRLOC-GAP),
    // plus 2 dedicated repair tags (Payment Method Relation, G/L Account NCF Category). Concepts
    // gated by MULTIPLE independent tags, no tag at all (compile-time fixes, dead code, Upgrade-
    // subtype-only), or not confidently traced are deliberately left unseeded.
    local procedure SeedDRLocalization(var SeededCount: Integer)
    begin
        SeedIfBlank('DRLOC', 'DRLOC-P2', 1, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE2-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 2, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 3, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 4, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 5, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 13, 'DX-INTERNAL-CLOSURE-TABLE-PAYMENTMETHODRELATION-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 14, 'DXR-T20260716-BackfillItemNCFCategory', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 15, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE2-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 16, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE2-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 17, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE2-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 18, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE2-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 19, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 20, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 21, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 22, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 23, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 24, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 25, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 26, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 27, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 28, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 29, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P3', 30, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V8-PHASE3-COMPLETED-20260822', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 31, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 32, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 33, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 34, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 35, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 36, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 37, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 38, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P4', 39, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE4-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 40, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 41, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 42, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 43, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 45, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 46, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 47, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 48, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 50, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 51, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 52, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 53, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 54, 'DX-INTERNAL-CLOSURE-TABLE-PAYMENTMETHODS606607-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 55, 'DX-INTERNAL-CLOSURE-TABLE-PURCHASETYPERELATION-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 56, 'DX-INTERNAL-CLOSURE-TABLE-TENDERTYPESRELATION-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 57, 'DX-INTERNAL-CLOSURE-TABLE-INCOMETYPESSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 58, 'DX-INTERNAL-CLOSURE-TABLE-ISRWITHHOLDINGTYPE-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 59, 'DX-INTERNAL-CLOSURE-TABLE-TYPEOFINCOME-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 60, 'DX-INTERNAL-CLOSURE-TABLE-CUSTOMERWITHHOLDINGSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 61, 'DX-INTERNAL-CLOSURE-TABLE-VENDORWITHHOLDINGSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 62, 'DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITY606-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 63, 'DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITYGROUP606-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 64, 'DX-INTERNAL-CLOSURE-TABLE-POSNAVSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 65, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 66, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 67, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 68, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 69, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 70, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 71, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P5', 72, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V7-PHASE5-COMPLETED-20260702', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 73, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 74, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 75, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 76, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 77, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 78, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 79, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 80, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 81, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 82, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 83, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 84, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 85, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 86, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 87, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 88, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 89, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 90, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 91, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 92, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 93, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 94, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P6', 95, 'DX-INTERNAL-CLOSURE-TASKSCHEDULER-V9-PHASE6-HISTORY-COMPLETED-20260720', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 97, 'DX-INTERNAL-CLOSURE-TABLE-FISCALRECEIPTTYPES-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 98, 'DX-INTERNAL-CLOSURE-TABLE-GAPSSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 99, 'DX-INTERNAL-CLOSURE-TABLE-NCFPURCHASESETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 100, 'DX-INTERNAL-CLOSURE-TABLE-NCFSALESSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 101, 'DX-INTERNAL-CLOSURE-TABLE-NCFSETUP-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 102, 'DX-INTERNAL-CLOSURE-TABLE-NCFCATEGORIES-20260522', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-GAP', 104, 'DXR-VEND-WITHHOLD-PRESERVE-DXR-20260721-V2', SeededCount);
        SeedIfBlank('DRLOC', 'DRLOC-P2', 105, 'DXR-GLACCOUNT-NCFCATEGORY-REPAIR-20260822', SeededCount);
    end;

    // DXPAYMENT-BC (DXP): phase-level tags (DXR_DXP_Migr_Phase_Tags), each shared across every
    // concept in that phase - no per-table granularity anywhere in this dispatcher.
    local procedure SeedDXPayments(var SeededCount: Integer)
    begin
        SeedIfBlank('DXP', 'DXP-P5', 1, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 2, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 3, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 4, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 5, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 6, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 7, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 8, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P5', 9, 'DXR-DXPAY-PHASE5-TABLES-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P6', 10, 'DXR-DXPAY-PHASE6-FIELDS-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P6', 39, 'DXR-DXPAY-PHASE6-FIELDS-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P6', 40, 'DXR-DXPAY-PHASE6-FIELDS-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P6', 41, 'DXR-DXPAY-PHASE6-FIELDS-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P6', 42, 'DXR-DXPAY-PHASE6-FIELDS-28.3-20260820', SeededCount);
        SeedIfBlank('DXP', 'DXP-P2', 12, 'DXR-DXPAY-PHASE2-FIELDS-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P2', 43, 'DXR-DXPAY-PHASE2-FIELDS-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P2', 44, 'DXR-DXPAY-PHASE2-FIELDS-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P2', 45, 'DXR-DXPAY-PHASE2-FIELDS-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P2', 46, 'DXR-DXPAY-PHASE2-FIELDS-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 14, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 15, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 16, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 17, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 18, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 19, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 20, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 21, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P4', 22, 'DXR-DXPAY-PHASE4-LEGACY-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 11, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 23, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 24, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 25, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 26, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 27, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 28, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 29, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P1', 30, 'DXR-DXPAY-PHASE1-TABLES-28.3-20260814', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 13, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 31, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 32, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 33, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 34, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 35, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 36, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 37, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
        SeedIfBlank('DXP', 'DXP-P3', 38, 'DXR-DXPAY-PHASE3-TABLES-28.3-20260817', SeededCount);
    end;

    // Facturacion Electronica (FE): phase-level tags (FE-P7 through FE-P13), each shared across
    // every concept in that phase. FE-P7's real gate is ExecutePhase1DependencyMigration's own
    // idempotency tag (a manual re-entry point bypassing the phase-level gate) - see comment in
    // DXR_Upgrade_Clean.Codeunit.al. Nuance: FE-P7/8/9/10/11 also short-circuit true if the legacy
    // umbrella tag 'DXR-EF-MIGRATION-20260526' is set on an already-migrated tenant; the phase's own
    // tag is seeded below as instructed, not the umbrella one.
    local procedure SeedFacturacionElectronica(var SeededCount: Integer)
    begin
        SeedIfBlank('FE', 'FE-P7', 1, 'DXR-EF-LEGACY-DEPS-20260822', SeededCount);
        SeedIfBlank('FE', 'FE-P7', 304, 'DXR-EF-LEGACY-DEPS-20260822', SeededCount);
        SeedIfBlank('FE', 'FE-P7', 305, 'DXR-EF-LEGACY-DEPS-20260822', SeededCount);
        SeedIfBlank('FE', 'FE-P7', 306, 'DXR-EF-LEGACY-DEPS-20260822', SeededCount);
        SeedIfBlank('FE', 'FE-P8', 2, 'DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P8', 307, 'DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P8', 308, 'DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P8', 309, 'DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P8', 310, 'DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P9', 3, 'DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P9', 311, 'DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P9', 312, 'DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P9', 313, 'DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P9', 314, 'DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 4, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 315, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 316, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 317, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 318, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P10', 319, 'DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 5, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P13', 7, 'DXR-EF-TASKSCHEDULER-V7-PHASE7-NCF-AFFECTED-CLEANUP-20260720', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 270, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 271, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 272, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 273, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 274, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 275, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 276, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 277, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 278, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 279, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 280, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 281, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 282, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 283, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 284, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 285, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 286, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 287, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 288, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 289, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 290, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 291, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 292, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 293, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 294, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 295, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 296, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 297, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 298, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 299, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 300, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 301, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P11', 302, 'DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625', SeededCount);
        SeedIfBlank('FE', 'FE-P12', 6, 'DXR-EF-TASKSCHEDULER-V6-PHASE6-HISTORICAL-TABLES-20260720', SeededCount);
        SeedIfBlank('FE', 'FE-P12', 303, 'DXR-EF-TASKSCHEDULER-V6-PHASE6-HISTORICAL-TABLES-20260720', SeededCount);
    end;

    // LS Facturacion Electronica (LSFE): only 1 of 2 concepts has a single clean gating tag.
    local procedure SeedLSFacturacionElectronica(var SeededCount: Integer)
    begin
        SeedIfBlank('LSFE', 'LSFE-P1', 1, 'LSEF-ASSIGN-PERMISSIONSETS-ALL-USERS-20260820', SeededCount);
    end;

    // LS Localizacion Base (LSLOC): 3 phase-level tags (DXR_LS Upgrade Tags), each shared across
    // every concept in that phase.
    local procedure SeedLSLocalizacionBase(var SeededCount: Integer)
    begin
        SeedIfBlank('LSLOC', 'LSLOC-OPOS', 1, 'T20260112.0002-01-12-2026-PY', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 2, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 3, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 4, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 5, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 6, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 7, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 8, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 9, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 10, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 11, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 12, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 13, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 14, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 15, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 16, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 17, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 18, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 19, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-DEPFLD', 20, 'DXR-LS-LEGACY-DEPS-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 21, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 22, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 23, 'DXR-LS-MIGRATION-20260623', SeededCount);
        SeedIfBlank('LSLOC', 'LSLOC-TOLOC', 24, 'DXR-LS-MIGRATION-20260623', SeededCount);
    end;

    // Price Controls Mgt (PCM): per-step tags (DXRPRCMigrPhase2/3/4/5). 2 concepts are structural-
    // only shell tables (LSC Offers FB / Prices Factbox) with no gate at all - left unseeded.
    local procedure SeedPriceControlsMgt(var SeededCount: Integer)
    begin
        SeedIfBlank('PCM', 'PCM-P5', 1, 'DXR-Phase5Step2ApprovalHistory-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 4, 'DXR-Phase5Step1PricesCtrlSetup-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 5, 'DXR-Phase5Step4Customer-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 6, 'DXR-Phase5Step5StorePrcGrp-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 7, 'DXR-Phase5Step3ApprovalEntry-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 8, 'DXR-Phase5Step6Workflow-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 9, 'DXR-Phase5Step7SalesHeader-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P5', 10, 'DXR-Phase5Step8SalesLine-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P2', 11, 'DXR-CustomerFieldsMigrated-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P2', 12, 'DXR-StorePriceGroupFieldsMigrated-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P3', 13, 'DXR-ApprovalEntryFieldsMigrated-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P3', 14, 'DXR-WorkflowFieldsMigrated-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P4', 15, 'DXR-SalesHeaderFieldsMigrated-28.3.0.0', SeededCount);
        SeedIfBlank('PCM', 'PCM-P4', 16, 'DXR-SalesLineFieldsMigrated-28.3.0.0', SeededCount);
    end;

    // Recaudo BPD (RBPD): 3 tags total, all confirmed via DXR_UpgradeTags.codeunit.al.
    local procedure SeedRecaudoBPD(var SeededCount: Integer)
    begin
        SeedIfBlank('RBPD', 'RBPD-P1', 1, 'DXR-RECAUDO-04-CustLedgerGenJnlFieldMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P1', 2, 'DXR-RECAUDO-04-CustLedgerGenJnlFieldMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 3, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 4, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 5, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 6, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 7, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 8, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 9, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P3', 10, 'DXR-RECAUDO-02-MiddlewareMigration-28.3', SeededCount);
        SeedIfBlank('RBPD', 'RBPD-P2', 11, 'DXR-RECAUDO-01-TableMigration-28.3', SeededCount);
    end;

    // Special Dispatch / Pedidos Especiales (SD): 3 phase-level tags (DXR_SD_Migr_Phase_Dispatcher).
    local procedure SeedSpecialDispatch(var SeededCount: Integer)
    begin
        SeedIfBlank('SD', 'SD-P1', 1, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P2', 2, 'DXR-SD-02-LegacyDispatchModuleSetup-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 3, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 4, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 5, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 6, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 7, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 8, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P1', 9, 'DXR-SD-01-FieldDuplication-20260728', SeededCount);
        SeedIfBlank('SD', 'SD-P3', 10, 'DXR-SD-03-PermissionSetAssignment-20260817', SeededCount);
    end;

    // TransUnion (TU): 2 real tags (table migration, field migration). 2 gen-0 gap concepts have
    // Dispatcher Codeunit ID = 0 (never confirmed reachable) and are correctly left unseeded.
    local procedure SeedTransUnion(var SeededCount: Integer)
    begin
        SeedIfBlank('TU', 'TU-P1', 1, 'DXR-TU-01-TableMigration28.3-20260731', SeededCount);
        SeedIfBlank('TU', 'TU-P1', 2, 'DXR-TU-01-TableMigration28.3-20260731', SeededCount);
        SeedIfBlank('TU', 'TU-P1', 3, 'DXR-TU-02-FieldMigration28.3-20260731', SeededCount);
    end;

    // Vendor Payloads (VP): per-table tags across Phase 1-7 (GetStepTag() helper resolved to its
    // real literal). Concepts bundling multiple independent tags (table + BLOB substep, or several
    // per-table field-cutover tags under one "Tableextension field cutover" concept) are left
    // unseeded rather than picking one arbitrarily.
    local procedure SeedVendorPayloads(var SeededCount: Integer)
    begin
        SeedIfBlank('VP', 'VP-P7', 1, 'VP-DXR-MIGR-P7-TBL-SETUP-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 2, 'VP-DXR-MIGR-P7-TBL-PAYLOAD-HEADER-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 3, 'VP-DXR-MIGR-P7-TBL-PAYLOAD-JOURNAL-LINES-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 4, 'VP-DXR-MIGR-P7-TBL-VENDORPAY-GROUP-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 5, 'VP-DXR-MIGR-P7-TBL-HISTORIC-PAYLOAD-HEADER-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 6, 'VP-DXR-MIGR-P7-TBL-HISTORIC-PAYLOAD-LINES-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 7, 'VP-DXR-MIGR-P7-TBL-HIST-VENDORPAY-GROUP-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 8, 'VP-DXR-MIGR-P7-TBL-LOGS-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 9, 'VP-DXR-MIGR-P7-TBL-JOURNAL-BANK-ACCOUNT-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 10, 'VP-DXR-MIGR-P7-TBL-ORDER-ITEM-STATUS-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 11, 'VP-DXR-MIGR-P7-TBL-ORDER-STATUS-LOG-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 12, 'VP-DXR-MIGR-P7-TBL-BANK-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 13, 'VP-DXR-MIGR-P7-TBL-CURRENCY-RELATION-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 14, 'VP-DXR-MIGR-P7-TBL-CARGA-MASIVA-BENEF-BPD-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 15, 'VP-DXR-MIGR-P7-TBL-HIS-CARGA-MASIVA-BENEF-BPD-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 16, 'VP-DXR-MIGR-P7-TBL-HIS-LINEAS-CARGA-MASIVA-BENEF-BPD-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 17, 'VP-DXR-MIGR-P7-TBL-HIST-BENEFICIARIOS-BPD-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 18, 'VP-DXR-MIGR-P7-TBL-LINEAS-CARGA-MASIVA-BENEF-BPD-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 19, 'VP-DXR-MIGR-P7-TBL-PROVINCIA-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 20, 'VP-DXR-MIGR-P7-TBL-API-LOG-ENTRY-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 21, 'VP-DXR-MIGR-P7-TBL-ORDER-NO-REL-PAYMENT-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P7', 22, 'VP-DXR-MIGR-P7-TBL-RESPONSE-LOG-20260820', SeededCount);
        SeedIfBlank('VP', 'VP-P1', 24, 'VP-DXR-MIGR-P1-SETUP-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P1', 25, 'VP-DXR-MIGR-P1-BANK-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P1', 26, 'VP-DXR-MIGR-P1-CURRENCY-RELATION-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P1', 27, 'VP-DXR-MIGR-P1-PROVINCIA-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 28, 'VP-DXR-MIGR-P2-PAYLOAD-HEADER-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 29, 'VP-DXR-MIGR-P2-PAYLOAD-JOURNAL-LINES-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 31, 'VP-DXR-MIGR-P2-JOURNAL-BANK-ACCOUNT-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 32, 'VP-DXR-MIGR-P2-ORDER-ITEM-STATUS-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 33, 'VP-DXR-MIGR-P2-ORDER-STATUS-LOG-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P2', 34, 'VP-DXR-MIGR-P2-ORDER-NO-REL-PAYMENT-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P3', 35, 'VP-DXR-MIGR-P3-HIST-PAYLOAD-HEADER-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P3', 36, 'VP-DXR-MIGR-P3-HIST-PAYLOAD-LINES-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P4', 38, 'VP-DXR-MIGR-P4-CARGA-MASIVA-BENEF-BPD-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P4', 39, 'VP-DXR-MIGR-P4-LINEAS-CARGA-MASIVA-BENEF-BPD-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P4', 40, 'VP-DXR-MIGR-P4-HIS-CARGA-MASIVA-BENEF-BPD-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P4', 41, 'VP-DXR-MIGR-P4-HIS-LINEAS-CARGA-MASIVA-BENEF-BPD-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P4', 42, 'VP-DXR-MIGR-P4-HIST-BENEFICIARIOS-BPD-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P5', 43, 'VP-DXR-MIGR-P5-LOGS-20260728', SeededCount);
        SeedIfBlank('VP', 'VP-P5', 44, 'VP-DXR-MIGR-P5-API-LOG-ENTRY-20260728', SeededCount);
    end;

    // Bellon Customization (BELLON): 12 phase-level tags across BELLON-P2/3/4/5/6/7/8/9/10/11/12,
    // BELLON-P2 alone spans seq 16-156 (naming-normalization tables + tableextension fields, 2
    // sub-batches). See the "Known gap" note at the top of this codeunit re: Phase 13 not being
    // wired to any specific concept here.
    local procedure SeedBellonCustomization(var SeededCount: Integer)
    var
        i: Integer;
    begin
        SeedIfBlank('BELLON', 'BELLON-P3', 1, 'DXR-SalesPurchIdDedup283-NAME-FALLBACK-20260826', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P5', 2, 'BELLON-MIGR-PHASE5-CUSTITEMDXR-COMPLETED-20260820', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P6', 3, 'DXR-BELLON-TABLEID-RENUMBER-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P7', 4, 'DXR-BELLON-TABLEEXT-ID-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P8', 5, 'DXR-BELLON-CONTACT-ID-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P9', 6, 'DXR-BELLON-TRANSFERHDR-ID-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P10', 7, 'DXR-BELLON-SALESPURCH-OLD-DEDUP2-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P4', 8, 'BELLON-MIGR-PERMSET-REPAIR-20260820', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 9, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 10, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 11, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 12, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 13, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P11', 14, 'DXR-BELLON-NCF-RENAME-RESTORE-28.3-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P12', 15, 'BELLON-MIGR-PHASE12-PHCOLLISIONFIX-COMPLETED-20260821', SeededCount);
        for i := 16 to 130 do
            SeedIfBlank('BELLON', 'BELLON-P2', i, 'DXR-BELLON-TABLES-NORM-28.3-1', SeededCount);
        for i := 131 to 134 do
            SeedIfBlank('BELLON', 'BELLON-P2', i, 'DXR-BELLON-TABLES-NORM-28.3-B2-1', SeededCount);
        SeedIfBlank('BELLON', 'BELLON-P2', 135, 'DXR-BELLON-SALESPURCH-OLDGEN-BRIDGE-28.3-1', SeededCount);
        for i := 136 to 156 do
            SeedIfBlank('BELLON', 'BELLON-P2', i, 'DXR-BELLON-TABLEEXT-FIELDS-NORM-28.3-1', SeededCount);
        for i := 157 to 269 do
            SeedIfBlank('BELLON', 'BELLON-P6', i, 'DXR-BELLON-TABLEID-RENUMBER-RESTORE-28.3-1', SeededCount);
    end;

    // Bellon Customization POS (BELLONPOS): 2 shared tags (field-restores vs table-restores).
    local procedure SeedBellonPOS(var SeededCount: Integer)
    var
        i: Integer;
    begin
        for i := 1 to 9 do
            SeedIfBlank('BELLONPOS', 'BELLONPOS-P2', i, 'DXR-BELLONPOS-TABLEEXT-FIELDS-NAME-FALLBACK-20260826', SeededCount);
        for i := 10 to 12 do
            SeedIfBlank('BELLONPOS', 'BELLONPOS-P2', i, 'DXR-BELLONPOS-TABLES-NORM-28.3', SeededCount);
    end;

    local procedure SeedIfBlank(ExtCode: Code[20]; PhaseCode: Code[20]; SeqNo: Integer; Tag: Text[250]; var SeededCount: Integer)
    var
        Concept: Record "DXR MCC Concept";
    begin
        Concept.SetRange("Extension Code", ExtCode);
        Concept.SetRange("Phase Code", PhaseCode);
        Concept.SetRange("Sequence No.", SeqNo);
        if not Concept.FindFirst() then
            exit; // concept not in the registry yet (Reload Registry not run, or renamed) - nothing to seed

        if Concept."Upgrade Tags" <> '' then
            exit; // operator already set something here - never overwrite

        Concept."Upgrade Tags" := Tag;
        Concept.Modify(true);
        SeededCount += 1;
    end;
}
