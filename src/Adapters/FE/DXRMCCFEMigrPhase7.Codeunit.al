codeunit 60136 "DXR MCC FE Migr Phase7"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 7 Bootstrap".OnRun(), which delegates entirely to "DXR_Upgrade".
    // ExecutePhase1DependencyMigration() (codeunit "DXR_Upgrade", Subtype = Upgrade,
    // Access = Internal). Copies 4 pairs of NCF/Payment setup fields (registry rows FE-P7 seq1/
    // 304/305/306, all SETUP, in scope) plus a later-added "Applies Withholding_DXR" fill on 5
    // line tables (untracked repair step, no registry row, out of scope - left exactly as
    // before, matching the LSLOC precedent of leaving out-of-scope in-file code untouched).
    //
    // The 4 in-scope target tables (DXR_NCF Purchase Setup 52177, DXR_NCF Sales Setup 52178,
    // DXR_NCF Setup 52179, DXR_Payment Method Relation 52180) are owned by DR-Localization and
    // Access = Internal there; MCC has no internalsVisibleTo grant from DR-Localization (confirmed
    // by reading DR-Localization/Localization/app.json's internalsVisibleTo list), so it cannot
    // see them as typed Records. Investigated (per this task's own instructions) whether this
    // matches the LSLOC precedent (Task A.4-LSLOC): confirmed yes - the actual "_DXR" fields being
    // migrated (Alternal No. Series_DXR/Alt No. Series NC_DXR/Base URL_DXR/Payment Type_DXR/
    // Payment Type Form_DXR) are declared on FE's OWN tableextensions of those 4 DR-Localization
    // tables (EFDxNcfPurchaseSetup/EFDxNcfSalesSetup/EFNcfSetup/EFPaymentMethodRelation.TableExt.al),
    // not on DR-Localization's own base tables - fields DR-Localization's own package cannot see
    // either. Zero-RecordRef therefore requires a thin typed wrapper: FE's own new public
    // "DXR_EF MCC Migr Bridge" (52544, added for this task, mirroring LSLOC's "DXR_LS Migr.
    // Dispatcher" bridge pattern) now exposes RunDependencyFieldSync_NCFPurchaseSetup/
    // NCFSalesSetup/NCFSetup/PaymentMethodRelation(), each a direct typed field copy living
    // inside FE's own package (which DOES have internalsVisibleTo from DR-Localization, and owns
    // the target fields).
    Permissions =
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Cr.Memo Line" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625') then
            exit;

        if UpgradeTag.HasUpgradeTag('DXR-EF-LEGACY-DEPS-20260822') then begin
            UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625');
            exit;
        end;

        MigrateLegacyDependencyTableFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-LEGACY-DEPS-20260822');
        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625');
    end;

    local procedure MigrateLegacyDependencyTableFields()
    var
        FEMigrBridge: Codeunit "DXR_EF MCC Migr Bridge";
    begin
        // seq1: DXNCF Purchase Setup (54130) -> DXR_NCF Purchase Setup (52177): Alternal No.
        // Series_DXR (55501->52333), Alt No. Series NC_DXR (55502->52334).
        FEMigrBridge.RunDependencyFieldSync_NCFPurchaseSetup();

        // seq304: DXNCF Sales Setup (54131) -> DXR_NCF Sales Setup (52178): same field pair.
        FEMigrBridge.RunDependencyFieldSync_NCFSalesSetup();

        // seq305: DXNCF Setup (54132) -> DXR_NCF Setup (52179): Base URL_DXR only.
        FEMigrBridge.RunDependencyFieldSync_NCFSetup();

        // seq306: DXPayment Method Relation (54133) -> DXR_Payment Method Relation (52180):
        // Payment Type_DXR (55501->52333), Payment Type Form_DXR (55502->52334).
        FEMigrBridge.RunDependencyFieldSync_PaymentMethodRelation();

        // "Applies Withholding_DXR" (52335) fill on the 5 line tables - same table on both sides
        // (field 55504 -> 52335), added 2026-08-22 after Phase 9/10's FieldMap was found missing
        // it (their completion tags short-circuit true on the legacy umbrella tag for any tenant
        // that already ran, so relying on Phase 9/10 alone would not reach an already-migrated
        // company).
        CopyLegacyDependencyTableFieldsSameTable(Database::"Purch. Cr. Memo Line", 55504, 52335);
        CopyLegacyDependencyTableFieldsSameTable(Database::"Purch. Inv. Line", 55504, 52335);
        CopyLegacyDependencyTableFieldsSameTable(Database::"Sales Line", 55504, 52335);
        CopyLegacyDependencyTableFieldsSameTable(Database::"Sales Invoice Line", 55504, 52335);
        CopyLegacyDependencyTableFieldsSameTable(Database::"Sales Cr.Memo Line", 55504, 52335);
    end;

    // CopyLegacyDependencyTableFieldsSameTable/CopyFieldValueIfExists below remain RecordRef-based
    // by design: they serve only the out-of-scope "Applies Withholding_DXR" same-table fill (no
    // MCC registry row - see the class header comment), left untouched per this task's scope
    // rules. The generic cross-table RecordRef helper that used to serve the 4 in-scope NCF/
    // Payment concepts (CopyLegacyDependencyTableFields) has been removed - replaced by
    // "DXR_EF MCC Migr Bridge" calls above.
    local procedure CopyLegacyDependencyTableFieldsSameTable(TableId: Integer; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableId);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldValueIfExists(RecRef, RecRef, SourceFieldNo, TargetFieldNo);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CopyFieldValueIfExists(SourceRef: RecordRef; var TargetRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        if not SourceRef.FieldExist(SourceFieldNo) then
            exit;

        if not TargetRef.FieldExist(TargetFieldNo) then
            exit;

        SourceFieldRef := SourceRef.Field(SourceFieldNo);
        TargetFieldRef := TargetRef.Field(TargetFieldNo);

        if TargetFieldRef.Class = FieldClass::Normal then
            TargetFieldRef.Value := SourceFieldRef.Value;
    end;
}
