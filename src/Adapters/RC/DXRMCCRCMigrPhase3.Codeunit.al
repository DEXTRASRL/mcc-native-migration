codeunit 60133 "DXR MCC RC Migr Phase3"
{
    // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase3 ID
    // Collision" (56502/56503, Access = Internal) - see "DXR MCC RC Migr Phase1" for the outer-tag
    // rationale. Fixes a cross-table field-ID collision: the "_DXR" fields added in Phase1/Phase2
    // originally reused IDs 54675-54677 across 6 tableextensions in this repo; the active field
    // now lives at a collision-free ID (56531-56538), and the pre-collision-fix ID was preserved
    // (duplicated+Obsolete, renamed "..._Old"/"..._DXR_Old") so this phase can copy real data left
    // there by an older, collision-affected deploy - but ONLY when that old field is non-blank
    // (Phase1/Phase2 already write the true value straight into the current field in the very same
    // dispatcher pass; an unconditional copy here would wipe that out for a first-time deploy where
    // the old-ID field is simply untouched/default).
    Permissions =
        tabledata "Sales Header" = RIM,
        tabledata "Purchase Header" = RIM,
        tabledata "Sales Invoice Header" = RIM,
        tabledata "LSC POS Func. Profile" = RIM,
        tabledata "DXR_Sales Controls Setup" = RIM,
        tabledata "DXR_Purchase Controls Setup" = RIM;

    var
        BatchSize: Integer;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE3-IDCOLLISION-RETROACTIVE-20260820') then
            exit;

        BatchSize := 500;
        CopySalesHeaderField();
        CopySalesInvoiceHeaderField();
        CopyPurchaseHeaderField();
        CopyLSCPOSFuncProfileFields();
        CopySalesControlsSetupFields();
        CopyPurchaseControlsSetupFields();

        UpgradeTag.SetUpgradeTag('DXR-RC-PHASE3-IDCOLLISION-RETROACTIVE-20260820');
    end;

    local procedure CopySalesHeaderField()
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        Processed: Integer;
        BlankOldValue: Text;
    begin
        if not SalesHeader.FindSet(true) then
            exit;
        BlankOldValue := GetBlankFieldValueFormatted(Database::"Sales Header", SalesHeader.FieldNo("POS Special Order_DXR_Old"));
        repeat
            RecRef.GetTable(SalesHeader);
            CopyFieldValueIfSourceNonBlank(RecRef, SalesHeader.FieldNo("POS Special Order_DXR_Old"), SalesHeader.FieldNo("POS Special Order_DXR"), BlankOldValue);
            RecRef.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until SalesHeader.Next() = 0;
    end;

    local procedure CopySalesInvoiceHeaderField()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        RecRef: RecordRef;
        Processed: Integer;
        BlankOldValue: Text;
    begin
        if not SalesInvHeader.FindSet(true) then
            exit;
        BlankOldValue := GetBlankFieldValueFormatted(Database::"Sales Invoice Header", SalesInvHeader.FieldNo("POS Special Order_DXR_Old"));
        repeat
            RecRef.GetTable(SalesInvHeader);
            CopyFieldValueIfSourceNonBlank(RecRef, SalesInvHeader.FieldNo("POS Special Order_DXR_Old"), SalesInvHeader.FieldNo("POS Special Order_DXR"), BlankOldValue);
            RecRef.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until SalesInvHeader.Next() = 0;
    end;

    local procedure CopyPurchaseHeaderField()
    var
        PurchHeader: Record "Purchase Header";
        RecRef: RecordRef;
        Processed: Integer;
        BlankOldValue: Text;
    begin
        if not PurchHeader.FindSet(true) then
            exit;
        BlankOldValue := GetBlankFieldValueFormatted(Database::"Purchase Header", PurchHeader.FieldNo(Toggle_DXR_Old));
        repeat
            RecRef.GetTable(PurchHeader);
            CopyFieldValueIfSourceNonBlank(RecRef, PurchHeader.FieldNo(Toggle_DXR_Old), PurchHeader.FieldNo(Toggle_DXR), BlankOldValue);
            RecRef.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until PurchHeader.Next() = 0;
    end;

    local procedure CopyLSCPOSFuncProfileFields()
    var
        FuncProfile: Record "LSC POS Func. Profile";
        RecRef: RecordRef;
        BlankTSOldValue: Text;
        BlankPSOOldValue: Text;
    begin
        if not FuncProfile.FindSet(true) then
            exit;
        BlankTSOldValue := GetBlankFieldValueFormatted(Database::"LSC POS Func. Profile", FuncProfile.FieldNo("TS POS Special Order_DXR_Old"));
        BlankPSOOldValue := GetBlankFieldValueFormatted(Database::"LSC POS Func. Profile", FuncProfile.FieldNo("PSO Distribution Location_Old"));
        repeat
            RecRef.GetTable(FuncProfile);
            CopyFieldValueIfSourceNonBlank(RecRef, FuncProfile.FieldNo("TS POS Special Order_DXR_Old"), FuncProfile.FieldNo("TS POS Special Order_DXR"), BlankTSOldValue);
            CopyFieldValueIfSourceNonBlank(RecRef, FuncProfile.FieldNo("PSO Distribution Location_Old"), FuncProfile.FieldNo("PSO Distribution Location_DXR"), BlankPSOOldValue);
            RecRef.Modify();
        until FuncProfile.Next() = 0;
    end;

    local procedure CopySalesControlsSetupFields()
    var
        Setup: Record "DXR_Sales Controls Setup";
        RecRef: RecordRef;
        BlankSpecialOrderOldValue: Text;
        BlankNonDecimalQtyOldValue: Text;
        BlankMandReturnOldValue: Text;
    begin
        if not Setup.FindSet(true) then
            exit;
        BlankSpecialOrderOldValue := GetBlankFieldValueFormatted(Database::"DXR_Sales Controls Setup", Setup.FieldNo("Special POS Order_DXR_Old"));
        BlankNonDecimalQtyOldValue := GetBlankFieldValueFormatted(Database::"DXR_Sales Controls Setup", Setup.FieldNo("Non Decimal Qty on Lines_Old"));
        BlankMandReturnOldValue := GetBlankFieldValueFormatted(Database::"DXR_Sales Controls Setup", Setup.FieldNo("Mand Return Reason Code_Old"));
        repeat
            RecRef.GetTable(Setup);
            CopyFieldValueIfSourceNonBlank(RecRef, Setup.FieldNo("Special POS Order_DXR_Old"), Setup.FieldNo("Special POS Order_DXR"), BlankSpecialOrderOldValue);
            CopyFieldValueIfSourceNonBlank(RecRef, Setup.FieldNo("Non Decimal Qty on Lines_Old"), Setup.FieldNo("Non Decimal Qty on Lines_DXR"), BlankNonDecimalQtyOldValue);
            CopyFieldValueIfSourceNonBlank(RecRef, Setup.FieldNo("Mand Return Reason Code_Old"), Setup.FieldNo("Mand Return Reason Code_DXR"), BlankMandReturnOldValue);
            RecRef.Modify();
        until Setup.Next() = 0;
    end;

    local procedure CopyPurchaseControlsSetupFields()
    var
        Setup: Record "DXR_Purchase Controls Setup";
        RecRef: RecordRef;
        BlankOldValue: Text;
    begin
        if not Setup.FindSet(true) then
            exit;
        BlankOldValue := GetBlankFieldValueFormatted(Database::"DXR_Purchase Controls Setup", Setup.FieldNo("BarCode Length_DXR_Old"));
        repeat
            RecRef.GetTable(Setup);
            CopyFieldValueIfSourceNonBlank(RecRef, Setup.FieldNo("BarCode Length_DXR_Old"), Setup.FieldNo("BarCode Length_DXR"), BlankOldValue);
            RecRef.Modify();
        until Setup.Next() = 0;
    end;

    local procedure CopyFieldValueIfSourceNonBlank(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer; BlankOldValueFormatted: Text)
    var
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
    begin
        OldFieldRef := RecRef.Field(OldFieldNo);
        if Format(OldFieldRef.Value) = BlankOldValueFormatted then
            exit;
        NewFieldRef := RecRef.Field(NewFieldNo);
        NewFieldRef.Value := OldFieldRef.Value;
    end;

    // Computed once per field (not per row): the formatted value of FieldNo on a freshly Init()'d
    // record of TableId, i.e. that field's true type-default. Used to tell "this old-ID field was
    // never written to" apart from "it holds a real value equal to the default".
    local procedure GetBlankFieldValueFormatted(TableId: Integer; FieldNo: Integer): Text
    var
        BlankRecRef: RecordRef;
        BlankFieldRef: FieldRef;
        Result: Text;
    begin
        BlankRecRef.Open(TableId);
        BlankRecRef.Init();
        BlankFieldRef := BlankRecRef.Field(FieldNo);
        Result := Format(BlankFieldRef.Value);
        BlankRecRef.Close();
        exit(Result);
    end;
}
