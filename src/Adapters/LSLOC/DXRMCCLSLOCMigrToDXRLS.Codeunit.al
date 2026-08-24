codeunit 60162 "DXR MCC LSLOC Migr ToDXRLS"
{
    // Native local migration - ported verbatim from LS Central DR Localization's own
    // "DXR_LS TableExt Fields Upgrade" (54510) + "DXR_LS Legacy Tables Upgrade" (54511), both
    // Access = Internal, bundled together here under one Upgrade Tag exactly as the sibling's own
    // Dispatcher does ('LS_TO_DXR_LS' phase: TableExtFieldsUpgrade.Execute() then
    // LegacyTablesUpgrade.Execute(), same tag for both).
    Permissions =
        tabledata "Gen. Journal Line" = M,
        tabledata Item = M,
        tabledata "LSC Hospitality Type" = M,
        tabledata "LSC Label Functions" = M,
        tabledata "LSC POS Print Setup Header" = M,
        tabledata "LSC POS Terminal" = M,
        tabledata "LSC POS Transaction" = M,
        tabledata "LSC Sales Type" = M,
        tabledata "LSC Store" = M,
        tabledata "LSC Store Inventory Line" = M,
        tabledata "LSC Transaction Header" = M,
        tabledata Field = R,
        tabledata "LSDX POS Setup" = R,
        tabledata "DXR_LS POS Setup" = RIMD,
        tabledata "LSDXTender Types Relation" = R,
        tabledata "DXR_LS Tender Types Relation" = RIMD,
        tabledata "LSDX OPOS Print Setup" = R,
        tabledata "DXR_LS OPOS Print Setup" = RIMD,
        tabledata "LSDX POS 607 Diagnostic" = R,
        tabledata "DXR_LS POS 607 Diagnostic" = RIMD,
        tabledata "LSDX LS NCF Process Reg." = R,
        tabledata "DXR_LS NCF Process Reg." = RIMD;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LS-MIGRATION-20260623') then
            exit;

        TableExtFieldsExecute();
        LegacyTablesExecute();

        UpgradeTag.SetUpgradeTag('DXR-LS-MIGRATION-20260623');
    end;

    // ===== "DXR_LS TableExt Fields Upgrade" (54510) =====

    local procedure TableExtFieldsExecute()
    begin
        CopySameTableFieldRange(Database::"Gen. Journal Line", 54300, 54500, 1);
        CopySameTableFieldRange(Database::Item, 54300, 54500, 1);
        CopySameTableFieldRange(Database::"LSC Hospitality Type", 54300, 54500, 2);
        CopySameTableFieldRange(Database::"LSC Label Functions", 54300, 54500, 1);
        CopySameTableFieldRange(Database::"LSC POS Print Setup Header", 54300, 54500, 1);
        CopySameTableFieldRange(Database::"LSC POS Terminal", 54300, 54500, 10);
        CopySameTableFieldRange(Database::"LSC POS Terminal", 54370, 54510, 3);
        CopySameTableFieldRange(Database::"LSC POS Transaction", 54300, 54500, 1);
        CopySameTableFieldRange(Database::"LSC POS Transaction", 54302, 54502, 4);
        CopySameTableFieldRange(Database::"LSC Sales Type", 54300, 54500, 2);
        CopySameTableFieldRange(Database::"LSC Store", 54300, 54500, 9);
        CopySameTableFieldRange(Database::"LSC Store Inventory Line", 54300, 54500, 1);
        CopySameTableFieldRange(Database::"LSC Transaction Header", 54300, 54500, 8);
        CopySameTableFieldRange(Database::"LSC Transaction Header", 54309, 54509, 5);
        CopySameTableFieldRange(Database::"LSC Transaction Header", 54315, 54515, 2);

        MigrateSameTableEnumFields();
    end;

    local procedure CopySameTableFieldRange(TableId: Integer; SourceStartFieldNo: Integer; TargetStartFieldNo: Integer; FieldCount: Integer)
    var
        RecRef: RecordRef;
        FieldOffset: Integer;
    begin
        RecRef.Open(TableId);
        if RecRef.FindSet(true) then
            repeat
                for FieldOffset := 0 to FieldCount - 1 do
                    CopyFieldIfExists(RecRef, SourceStartFieldNo + FieldOffset, TargetStartFieldNo + FieldOffset);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
    begin
        if not FieldNoExists(RecRef.Number, SourceFieldNo) then
            exit;
        SourceFieldRef := RecRef.Field(SourceFieldNo);
        TargetFieldRef := RecRef.Field(TargetFieldNo);
        TargetFieldRef.Value := SourceFieldRef.Value;
    end;

    local procedure FieldNoExists(TableNo: Integer; FieldNo: Integer): Boolean
    var
        FieldRec: Record Field;
    begin
        exit(FieldRec.Get(TableNo, FieldNo));
    end;

    local procedure MigrateSameTableEnumFields()
    var
        POSTerminal: Record "LSC POS Terminal";
        POSTransaction: Record "LSC POS Transaction";
        TransactionHeader: Record "LSC Transaction Header";
    begin
        if POSTerminal.FindSet(true) then
            repeat
                POSTerminal."Ext. POS Type_DXR" := Enum::"DXR_LS POS Type".FromInteger(POSTerminal."LSDXExt. POS Type".AsInteger());
                POSTerminal.Modify(false);
            until POSTerminal.Next() = 0;

        if POSTransaction.FindSet(true) then
            repeat
                POSTransaction."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(POSTransaction."LSDX Tipo Doc. Fiscal".AsInteger());
                POSTransaction."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(POSTransaction."LSDX Tipo Identificacion".AsInteger());
                POSTransaction.Modify(false);
            until POSTransaction.Next() = 0;

        if TransactionHeader.FindSet(true) then
            repeat
                TransactionHeader."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(TransactionHeader."LSDX Tipo Doc. Fiscal".AsInteger());
                TransactionHeader."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(TransactionHeader."LSDX Tipo Identificacion".AsInteger());
                TransactionHeader.Modify(false);
            until TransactionHeader.Next() = 0;
    end;

    // ===== "DXR_LS Legacy Tables Upgrade" (54511) =====

    local procedure LegacyTablesExecute()
    begin
        CopyStandaloneTable(Database::"LSDX POS Setup", Database::"DXR_LS POS Setup");
        CopyStandaloneTable(Database::"LSDXTender Types Relation", Database::"DXR_LS Tender Types Relation");
        CopyStandaloneTable(Database::"LSDX OPOS Print Setup", Database::"DXR_LS OPOS Print Setup");
        CopyStandaloneTable(Database::"LSDX POS 607 Diagnostic", Database::"DXR_LS POS 607 Diagnostic");
        CopyStandaloneTable(Database::"LSDX LS NCF Process Reg.", Database::"DXR_LS NCF Process Reg.");
    end;

    local procedure CopyStandaloneTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourceFieldRef: FieldRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        TargetExists: Boolean;
    begin
        SourceRef.Open(SourceTableId);
        TargetRef.Open(TargetTableId);
        SourceKeyRef := SourceRef.KeyIndex(1);

        if SourceRef.FindSet() then
            repeat
                TargetRef.Reset();
                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
                    TargetPkFieldRef := TargetRef.Field(SourcePkFieldRef.Number);
                    TargetPkFieldRef.SetRange(SourcePkFieldRef.Value);
                end;

                TargetExists := TargetRef.FindFirst();
                if not TargetExists then
                    TargetRef.Init();

                for FieldIndex := 1 to SourceRef.FieldCount() do begin
                    SourceFieldRef := SourceRef.FieldIndex(FieldIndex);
                    if TargetRef.FieldExist(SourceFieldRef.Number) then
                        CopyFieldValueIfExists(SourceRef, TargetRef, SourceFieldRef.Number, SourceFieldRef.Number);
                end;

                if TargetExists then
                    TargetRef.Modify(false)
                else
                    TargetRef.Insert(false);
            until SourceRef.Next() = 0;

        TargetRef.Close();
        SourceRef.Close();
    end;

    local procedure CopyFieldValueIfExists(SourceRef: RecordRef; var TargetRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        EnumOrdinal: Integer;
    begin
        if not SourceRef.FieldExist(SourceFieldNo) or not TargetRef.FieldExist(TargetFieldNo) then
            exit;

        SourceFieldRef := SourceRef.Field(SourceFieldNo);
        TargetFieldRef := TargetRef.Field(TargetFieldNo);
        if TargetFieldRef.Class <> FieldClass::Normal then
            exit;

        if TargetFieldRef.Type = FieldType::Option then begin
            if Evaluate(EnumOrdinal, Format(SourceFieldRef.Value, 0, 2)) then
                TargetFieldRef.Value := EnumOrdinal;
        end else
            TargetFieldRef.Value := SourceFieldRef.Value;
    end;
}
