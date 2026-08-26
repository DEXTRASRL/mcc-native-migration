#if not ESCUDEA and not BCDX
codeunit 60094 "DXR MCC BC Migr P2 Sales"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopySalesControlsSetup() - see "DXR MCC BC Migr P2 Warehouse" for the full rationale.
    Permissions = tabledata "DXR_Sales Ctrl Setup Old2" = R,
                  tabledata "DXR_Sales Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Sales Ctrl Setup Old2";
        NewSetup: Record "DXR_Sales Controls Setup";
        NewSetupExists: Boolean;
    begin
        if not OldSetup.Get('') then
            exit;
        if IsOldSetupRowBlank(OldSetup) then
            exit;

        NewSetupExists := NewSetup.Get('');
        if not NewSetupExists then
            NewSetup.Init();

        NewSetup."Code" := OldSetup."Code";
        NewSetup.Active := OldSetup.Active;
        NewSetup."Sales Sell/Buy Mismatch" := OldSetup."Sales Sell/Buy Mismatch";
        NewSetup."Sales Posting Date to workdate" := OldSetup."Sales Posting Date to workdate";
        NewSetup."Sales No duplicates Items" := OldSetup."Sales No duplicates Items";
        NewSetup."Sales Mandatory Order No." := OldSetup."Sales Mandatory Order No.";
        NewSetup."Sales Mandatory Sh. Method" := OldSetup."Sales Mandatory Sh. Method";
        NewSetup."Sales Block Overdue" := OldSetup."Sales Block Overdue";
        NewSetup."Sales Block Overdue Date" := OldSetup."Sales Block Overdue Date";
        NewSetup."Sales Mandatory Resp. Center" := OldSetup."Sales Mandatory Resp. Center";
        NewSetup."Sales Mandatory LSC Store No" := OldSetup."Sales Mandatory LSC Store No";
        NewSetup."Sales Allow VAT Amount" := OldSetup."Sales Allow VAT Amount";
        NewSetup."Sales Mandatory Salesperson" := OldSetup."Sales Mandatory Salesperson";
        NewSetup."Validate Docs. Approval" := OldSetup."Validate Docs. Approval";
        NewSetup."Validate Docs. Release" := OldSetup."Validate Docs. Release";
        NewSetup."Validate Sales Lines Quantity" := OldSetup."Validate Sales Lines Quantity";
        NewSetup."Item Payment Terms" := OldSetup."Item Payment Terms";
        NewSetup."Restrict Non Qty To Ship" := OldSetup."Restrict Non Qty To Ship";
        NewSetup."Restrict Non Qty To Receive" := OldSetup."Restrict Non Qty To Receive";
        NewSetup."Restrict Non Qty On Posted Doc" := OldSetup."Restrict Non Qty On Posted Doc";
        NewSetup."Restrict Non Decimal Qty" := OldSetup."Restrict Non Decimal Qty";
        NewSetup."Exempt group" := OldSetup."Exempt group";
        NewSetup."Exempt Product group" := OldSetup."Exempt Product group";
        NewSetup."Handle Shipment M. On Release" := OldSetup."Handle Shipment M. On Release";
        NewSetup."Sales Mandatory Currency Code" := OldSetup."Sales Mandatory Currency Code";
        NewSetup."Check Reg. Merc. Expiration" := OldSetup."Check Reg. Merc. Expiration";
        NewSetup."Mandatory Return Reason" := OldSetup."Mandatory Return Reason";

        if NewSetupExists then
            NewSetup.Modify(false)
        else
            NewSetup.Insert(false);
    end;

    local procedure IsOldSetupRowBlank(var OldSetup: Record "DXR_Sales Ctrl Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."Sales Sell/Buy Mismatch") and
            (not OldSetup."Sales Posting Date to workdate") and
            (not OldSetup."Sales No duplicates Items") and
            (not OldSetup."Sales Mandatory Order No.") and
            (not OldSetup."Sales Mandatory Sh. Method") and
            (not OldSetup."Sales Block Overdue") and
            (Format(OldSetup."Sales Block Overdue Date") = '') and
            (not OldSetup."Sales Mandatory Resp. Center") and
            (not OldSetup."Sales Mandatory LSC Store No") and
            (not OldSetup."Sales Allow VAT Amount") and
            (not OldSetup."Sales Mandatory Salesperson") and
            (not OldSetup."Validate Docs. Approval") and
            (not OldSetup."Validate Docs. Release") and
            (not OldSetup."Validate Sales Lines Quantity") and
            (not OldSetup."Item Payment Terms") and
            (not OldSetup."Restrict Non Qty To Ship") and
            (not OldSetup."Restrict Non Qty To Receive") and
            (not OldSetup."Restrict Non Qty On Posted Doc") and
            (not OldSetup."Restrict Non Decimal Qty") and
            (OldSetup."Exempt group" = '') and
            (OldSetup."Exempt Product group" = '') and
            (not OldSetup."Handle Shipment M. On Release") and
            (not OldSetup."Sales Mandatory Currency Code") and
            (not OldSetup."Check Reg. Merc. Expiration") and
            (not OldSetup."Mandatory Return Reason"));
    end;
}

#endif
