codeunit 60159 "DXR MCC BellonPOS Migr Phase2"
{
    // Native local migration - ported verbatim from Bellon Customization POS's own "Bellon POS
    // Migr Phase2 LegNorm" (56212) -> "DXR_POS Upgrade Process".MigrateAllTableExtensionFields() +
    // MigrateAllNormalizedTables() (both internal procedure calls on a typed Subtype = Upgrade
    // codeunit variable - never .Run()/OnRun, same pre-existing pattern the deleted delegation
    // adapter itself already used and documented as safe). No hidden/untracked phases here - the
    // sibling's own Dispatcher only runs Phase 1 (critical/inline, out of scope like every other
    // extension's Phase 1) and this Phase 2, both already fully covered by the deleted adapter.
    Permissions =
        tabledata "BE DX Setup" = RM,
        tabledata "LSC Coupon Header" = RM,
        tabledata "LSC POS Trans. Line" = RM,
        tabledata "LSC POS Command" = RM,
        tabledata "LSC POS Terminal" = RM,
        tabledata "LSC POS Transaction" = RM,
        tabledata "LSC Trans. Sales Entry" = RM,
        tabledata "LSC Trans. Server Table Log" = RM;

    trigger OnRun()
    begin
        MigrateAllTableExtensionFields();
        MigrateAllNormalizedTables();
    end;

    procedure RunSetup()
    begin
        MigrateTableExt_BEDXSetupFields();
        MigrateTableExt_LSCPOSTerminalFields();
    end;

    procedure RunHistoric()
    begin
        MigrateTableExt_LSCTransServerTableLogFields();
        MigrateLegacyTableData(50300, 53563);
        MigrateLegacyTableData(50301, 53564);
        MigrateLegacyTableData(50302, 53565);
    end;

    procedure RunOther()
    begin
        MigrateTableExt_LSCMembershipCardFields();
        MigrateTableExt_LSCCouponHeaderFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSCommandFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_LSCTransSalesEntryFields();
    end;

    local procedure MigrateAllTableExtensionFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BELLONPOS-TABLEEXT-FIELDS-NORM-28.3') then
            exit;

        MigrateTableExt_LSCMembershipCardFields();
        MigrateTableExt_BEDXSetupFields();
        MigrateTableExt_LSCCouponHeaderFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSCommandFields();
        MigrateTableExt_LSCPOSTerminalFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_LSCTransSalesEntryFields();
        MigrateTableExt_LSCTransServerTableLogFields();

        UpgradeTag.SetUpgradeTag('DXR-BELLONPOS-TABLEEXT-FIELDS-NORM-28.3');
    end;

    // "LSC Membership Card": both the legacy field (50000, "Cardholder Name") and the new one
    // ("Cardholder Name_DXR", 53526) are FlowFields (Lookup to "LSC Member Contact".Name) - no
    // physical data to copy, both are calculated. Deliberate no-op, matching the real source.
    local procedure MigrateTableExt_LSCMembershipCardFields()
    begin
    end;

    local procedure MigrateTableExt_BEDXSetupFields()
    var
        Setup: Record "BE DX Setup";
    begin
        if Setup.FindSet(true) then
            repeat
                if (Setup."POS Venta Exonerada ITBIS" <> Setup."POS Venta Exonerada ITBIS_DXR") then
                    Setup."POS Venta Exonerada ITBIS_DXR" := Setup."POS Venta Exonerada ITBIS";
                if (Setup."Filtro Pos Devolucion" <> Setup."Filtro Pos Devolucion_DXR") then
                    Setup."Filtro Pos Devolucion_DXR" := Setup."Filtro Pos Devolucion";
                if (Setup."POS Devolucion Exonerada ITBIS" <> Setup."POS Devolucion Exonerada ITBIS_DXR") then
                    Setup."POS Devolucion Exonerada ITBIS_DXR" := Setup."POS Devolucion Exonerada ITBIS";
                if (Setup."Show SalesPerson on Receipt" <> Setup."Show SalesPerson on Receipt_DXR") then
                    Setup."Show SalesPerson on Receipt_DXR" := Setup."Show SalesPerson on Receipt";
                Setup.Modify(false);
            until Setup.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCCouponHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Coupon Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTransLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Trans. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50015, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSCommandFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Command");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTerminalFields()
    var
        Terminal: Record "LSC POS Terminal";
    begin
        if Terminal.FindSet(true) then
            repeat
                if (Terminal."External Cmd. Print Z by Range" <> Terminal."External Cmd. Print Z by Range_DXR") then
                    Terminal."External Cmd. Print Z by Range_DXR" := Terminal."External Cmd. Print Z by Range";
                if (Terminal."External Cmd. Imp. Factura" <> Terminal."External Cmd. Imp. Factura_DXR") then
                    Terminal."External Cmd. Imp. Factura_DXR" := Terminal."External Cmd. Imp. Factura";
                if (Terminal."External Cmd. Cliente Suspe." <> Terminal."External Cmd. Cliente Suspe._DXR") then
                    Terminal."External Cmd. Cliente Suspe._DXR" := Terminal."External Cmd. Cliente Suspe.";
                Terminal.Modify(false);
            until Terminal.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCPOSTransactionFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Transaction");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50005, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransSalesEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Sales Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransServerTableLogFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Server Table Log");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 53526);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;

    local procedure MigrateAllNormalizedTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BELLONPOS-TABLES-NORM-28.3') then
            exit;

        MigrateLegacyTableData(50300, 53563);
        MigrateLegacyTableData(50301, 53564);
        MigrateLegacyTableData(50302, 53565);

        UpgradeTag.SetUpgradeTag('DXR-BELLONPOS-TABLES-NORM-28.3');
    end;

    // Generic RecordRef copy of every row from a legacy table (ObsoleteState=Pending) to its new
    // DXR_ clone - field IDs are identical between both, so a field-by-field copy by number is
    // safe. Idempotent per table: if the destination already has rows, does not copy again.
    local procedure MigrateLegacyTableData(OldTableId: Integer; NewTableId: Integer)
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
        FieldIdx: Integer;
    begin
        NewRecRef.Open(NewTableId);
        if not NewRecRef.IsEmpty() then begin
            NewRecRef.Close();
            exit;
        end;
        NewRecRef.Close();

        OldRecRef.Open(OldTableId);
        if OldRecRef.FindSet() then
            repeat
                NewRecRef.Open(NewTableId);
                NewRecRef.Init();
                for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                    OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                    if (OldFieldRef.Class() = FieldClass::Normal) and NewRecRef.FieldExist(OldFieldRef.Number()) then begin
                        NewFieldRef := NewRecRef.Field(OldFieldRef.Number());
                        // Only Normal fields on both sides are copied: a FlowField/FlowFilter on
                        // the destination rejects a direct .Value assignment (runtime error), and
                        // one on the source would need CalcFields first - neither is physical data
                        // this clone needs to carry.
                        if NewFieldRef.Class() = FieldClass::Normal then
                            NewFieldRef.Value := OldFieldRef.Value();
                    end;
                end;
                NewRecRef.Insert(false);
                // 2026-08-25 fix: same missing-Close bug as BELLON's identical helper
                // (DXRMCCBellonMigrPhase2/Phase6) - NewRecRef.Open() inside this loop without a
                // per-iteration Close() threw "The record is already open." on the 2nd+ row of any
                // multi-row table still served by this shared helper, aborting the whole OnRun().
                NewRecRef.Close();
            until OldRecRef.Next() = 0;
        OldRecRef.Close();
    end;
}
