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
    // Access = Internal there. DR-Localization now grants MCC's own app ID internalsVisibleTo
    // directly (see DR-Localization/Localization/app.json), so MCC can declare typed Record
    // variables on all 4 directly - including the "_DXR" fields FE itself added via its own
    // tableextensions on those tables (EFDxNcfPurchaseSetup/EFDxNcfSalesSetup/EFNcfSetup/
    // EFPaymentMethodRelation.TableExt.al): the internalsVisibleTo grant covers the whole table,
    // not just fields DR-Localization's own package declared. The 4 legacy source tables
    // (DXNCF Purchase Setup 54130, DXNCF Sales Setup 54131, DXNCF Setup 54132, DXPayment Method
    // Relation 54133) are also owned by DR-Localization but have no Access modifier (default
    // Public), so they were always directly declarable. Zero RecordRef/FieldRef/TransferFields:
    // each of the 4 procedures below is a direct typed field copy, replicated verbatim from FE's
    // now-retired "DXR_EF MCC Migr Bridge" (52544, left in place in FE's own repo, unused) - the
    // cross-repo bridge this codeunit used to call into is no longer needed.
    Permissions =
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Cr.Memo Line" = RM,
        tabledata "DXNCF Purchase Setup" = R,
        tabledata "DXR_NCF Purchase Setup" = RM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RM,
        tabledata "DXPayment Method Relation" = R,
        tabledata "DXR_Payment Method Relation" = RM;

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
    begin
        // seq1: DXNCF Purchase Setup (54130) -> DXR_NCF Purchase Setup (52177): Alternal No.
        // Series_DXR (55501->52333), Alt No. Series NC_DXR (55502->52334).
        MigrateNCFPurchaseSetupDependencyFields();

        // seq304: DXNCF Sales Setup (54131) -> DXR_NCF Sales Setup (52178): same field pair.
        MigrateNCFSalesSetupDependencyFields();

        // seq305: DXNCF Setup (54132) -> DXR_NCF Setup (52179): Base URL_DXR only.
        MigrateNCFSetupDependencyFields();

        // seq306: DXPayment Method Relation (54133) -> DXR_Payment Method Relation (52180):
        // Payment Type_DXR (55501->52333), Payment Type Form_DXR (55502->52334).
        MigratePaymentMethodRelationDependencyFields();

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

    /// <summary>
    /// Fills "Alternal No. Series_DXR"/"Alt No. Series NC_DXR" on "DXR_NCF Purchase Setup" from
    /// the legacy "DXNCF Purchase Setup" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFPurchaseSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Purchase Setup";
        NewSetup: Record "DXR_NCF Purchase Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if NewSetup.Get(LegacySetup.DXCodigo) then begin
                    NewSetup."Alternal No. Series_DXR" := LegacySetup."EF Alternal No. Series";
                    NewSetup."Alt No. Series NC_DXR" := LegacySetup."EF Alternal No. Series NC";
                    NewSetup.Modify(false);
                end;
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Alternal No. Series_DXR"/"Alt No. Series NC_DXR" on "DXR_NCF Sales Setup" from the
    /// legacy "DXNCF Sales Setup" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFSalesSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Sales Setup";
        NewSetup: Record "DXR_NCF Sales Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if NewSetup.Get(LegacySetup.Codigo) then begin
                    NewSetup."Alternal No. Series_DXR" := LegacySetup."EF Alternal No. Series";
                    NewSetup."Alt No. Series NC_DXR" := LegacySetup."EF Alternal No. Series NC";
                    NewSetup.Modify(false);
                end;
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Base URL_DXR" on "DXR_NCF Setup" from the legacy "DXNCF Setup" table, for every row
    /// that already exists on the target (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Setup";
        NewSetup: Record "DXR_NCF Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if NewSetup.Get(LegacySetup."Primary Key") then begin
                    NewSetup."Base URL_DXR" := LegacySetup."EF Base URL";
                    NewSetup.Modify(false);
                end;
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Payment Type_DXR"/"Payment Type Form_DXR" on "DXR_Payment Method Relation" from the
    /// legacy "DXPayment Method Relation" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts). "EF Payment Type" (enum "EF Payment
    /// Type": Cash=1/Credit=2/Free=3) and "Payment Type_DXR" (enum "DXR_Payment Type": same
    /// value names/ordinals) are structurally identical enums, so the ordinal round-trip via
    /// AsInteger()/FromInteger() below is safe.
    /// </summary>
    local procedure MigratePaymentMethodRelationDependencyFields()
    var
        LegacyRelation: Record "DXPayment Method Relation";
        NewRelation: Record "DXR_Payment Method Relation";
    begin
        if LegacyRelation.FindSet() then
            repeat
                if NewRelation.Get(LegacyRelation.Code, LegacyRelation."Payment Method Code") then begin
                    NewRelation."Payment Type_DXR" := Enum::"DXR_Payment Type".FromInteger(LegacyRelation."EF Payment Type".AsInteger());
                    NewRelation."Payment Type Form_DXR" := LegacyRelation."EF Payment Type Form";
                    NewRelation.Modify(false);
                end;
            until LegacyRelation.Next() = 0;
    end;

    // CopyLegacyDependencyTableFieldsSameTable/CopyFieldValueIfExists below remain RecordRef-based
    // by design: they serve only the out-of-scope "Applies Withholding_DXR" same-table fill (no
    // MCC registry row - see the class header comment), left untouched per this task's scope
    // rules. The generic cross-table RecordRef helper that used to serve the 4 in-scope NCF/
    // Payment concepts (CopyLegacyDependencyTableFields) has been removed - replaced by the 4
    // typed Direct procedures above.
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
