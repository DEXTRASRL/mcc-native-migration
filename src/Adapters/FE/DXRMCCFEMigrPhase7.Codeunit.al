codeunit 60136 "DXR MCC FE Migr Phase7"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 7 Bootstrap".OnRun(), which delegates entirely to "DXR_Upgrade".
    // ExecutePhase1DependencyMigration() (codeunit "DXR_Upgrade", Subtype = Upgrade,
    // Access = Internal). Copies 4 pairs of NCF/Payment setup fields (owned by DR-Localization,
    // dependency tables of FE) plus a later-added "Applies Withholding_DXR" fill on 5 line tables.
    //
    // All 8 dependency tables (DXNCF Purchase Setup/DXR_NCF Purchase Setup, DXNCF Sales Setup/
    // DXR_NCF Sales Setup, DXNCF Setup/DXR_NCF Setup, DXPayment Method Relation/DXR_Payment Method
    // Relation) are owned by DR-Localization; the 4 "DXR_" (new) sides are Access = Internal there,
    // so this codeunit accesses all 8 purely via RecordRef by numeric table ID (never by name),
    // matching the established pattern for every other sibling's Access = Internal object in this
    // portfolio.
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
    begin
        // DXNCF Purchase Setup (54130) -> DXR_NCF Purchase Setup (52177): Alternal No.
        // Series_DXR (55501->52333), Alt No. Series NC_DXR (55502->52334).
        CopyLegacyDependencyTableFields(54130, 52177, 55501, 52333, 55502, 52334);

        // DXNCF Sales Setup (54131) -> DXR_NCF Sales Setup (52178): same field pair.
        CopyLegacyDependencyTableFields(54131, 52178, 55501, 52333, 55502, 52334);

        // DXNCF Setup (54132) -> DXR_NCF Setup (52179): Base URL_DXR only.
        CopyLegacyDependencyTableFields(54132, 52179, 55501, 52333, 0, 0);

        // DXPayment Method Relation (54133) -> DXR_Payment Method Relation (52180): Payment
        // Type_DXR (55502->52333), Payment Type Form_DXR (55501->52334).
        CopyLegacyDependencyTableFields(54133, 52180, 55502, 52334, 55501, 52333);

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

    local procedure CopyLegacyDependencyTableFields(SourceTableId: Integer; TargetTableId: Integer; SourceFieldNo1: Integer; TargetFieldNo1: Integer; SourceFieldNo2: Integer; TargetFieldNo2: Integer)
    var
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        KeyFieldIndex: Integer;
        AllKeyFieldsMapped: Boolean;
    begin
        SourceRef.Open(SourceTableId);
        TargetRef.Open(TargetTableId);

        SourceKeyRef := SourceRef.KeyIndex(1);

        if SourceRef.FindSet() then
            repeat
                TargetRef.Reset();
                AllKeyFieldsMapped := true;

                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);

                    if TargetRef.FieldExist(SourcePkFieldRef.Number) then begin
                        TargetPkFieldRef := TargetRef.Field(SourcePkFieldRef.Number);
                        TargetPkFieldRef.SetRange(SourcePkFieldRef.Value);
                    end else
                        AllKeyFieldsMapped := false;
                end;

                if AllKeyFieldsMapped then
                    if TargetRef.FindFirst() then begin
                        CopyFieldValueIfExists(SourceRef, TargetRef, SourceFieldNo1, TargetFieldNo1);

                        if (SourceFieldNo2 <> 0) and (TargetFieldNo2 <> 0) then
                            CopyFieldValueIfExists(SourceRef, TargetRef, SourceFieldNo2, TargetFieldNo2);

                        TargetRef.Modify(false);
                    end;
            until SourceRef.Next() = 0;

        TargetRef.Close();
        SourceRef.Close();
    end;

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
