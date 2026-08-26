/*
codeunit 60093 "DXR MCC BC Migr P2 Purchase"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopyPurchaseControlsSetup() - see "DXR MCC BC Migr P2 Warehouse" for the full rationale.
    Permissions = tabledata "DXR_Purchase Ctrl Setup Old2" = R,
                  tabledata "DXR_Purchase Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Purchase Ctrl Setup Old2";
        NewSetup: Record "DXR_Purchase Controls Setup";
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
        NewSetup."Mandatory Purchaser Code" := OldSetup."Mandatory Purchaser Code";
        NewSetup."Purch. Warehouse Qty" := OldSetup."Purch. Warehouse Qty";
        NewSetup."Purch. Received Lines" := OldSetup."Purch. Received Lines";
        NewSetup."Purch. Date overdue" := OldSetup."Purch. Date overdue";
        NewSetup."Posting Date + Delivery" := OldSetup."Posting Date + Delivery";
        NewSetup."Date of arrival" := OldSetup."Date of arrival";
        NewSetup."Trim Barcode" := OldSetup."Trim Barcode";
        NewSetup."Mandatory Shipment Method Code" := OldSetup."Mandatory Shipment Method Code";
        NewSetup."Purch. Allow Delete Manually" := OldSetup."Purch. Allow Delete Manually";
        NewSetup."Purch. Archive on Delete" := OldSetup."Purch. Archive on Delete";
        NewSetup."Mandatory Direct unit cost" := OldSetup."Mandatory Direct unit cost";
        NewSetup."Dates FactBox" := OldSetup."Dates FactBox";
        NewSetup."Validate Docs. Approval" := OldSetup."Validate Docs. Approval";
        NewSetup."Validate Docs. Release" := OldSetup."Validate Docs. Release";
        NewSetup."Mandatory Country/Region Code" := OldSetup."Mandatory Country/Region Code";
        NewSetup."Restrict Non Qty to Receipt" := OldSetup."Restrict Non Qty to Receipt";
        NewSetup."Restrict Non Qty to Assign" := OldSetup."Restrict Non Qty to Assign";
        NewSetup."Restrict Non Qty On Posted Doc" := OldSetup."Restrict Non Qty On Posted Doc";
        NewSetup."Sales Sell/Buy Mismatch" := OldSetup."Sales Sell/Buy Mismatch";
        NewSetup."Purch. Post Date to workdate" := OldSetup."Purch. Post Date to workdate";
        NewSetup."Purch. Mandatory Currency Code" := OldSetup."Purch. Mandatory Currency Code";
        NewSetup."Validate Document Date" := OldSetup."Validate Document Date";

        if NewSetupExists then
            NewSetup.Modify(false)
        else
            NewSetup.Insert(false);
    end;

    local procedure IsOldSetupRowBlank(var OldSetup: Record "DXR_Purchase Ctrl Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."Mandatory Purchaser Code") and
            (not OldSetup."Purch. Warehouse Qty") and
            (not OldSetup."Purch. Received Lines") and
            (not OldSetup."Purch. Date overdue") and
            (not OldSetup."Posting Date + Delivery") and
            (not OldSetup."Date of arrival") and
            (not OldSetup."Trim Barcode") and
            (not OldSetup."Mandatory Shipment Method Code") and
            (not OldSetup."Purch. Allow Delete Manually") and
            (not OldSetup."Purch. Archive on Delete") and
            (not OldSetup."Mandatory Direct unit cost") and
            (not OldSetup."Dates FactBox") and
            (not OldSetup."Validate Docs. Approval") and
            (not OldSetup."Validate Docs. Release") and
            (not OldSetup."Mandatory Country/Region Code") and
            (not OldSetup."Restrict Non Qty to Receipt") and
            (not OldSetup."Restrict Non Qty to Assign") and
            (not OldSetup."Restrict Non Qty On Posted Doc") and
            (not OldSetup."Sales Sell/Buy Mismatch") and
            (not OldSetup."Purch. Post Date to workdate") and
            (not OldSetup."Purch. Mandatory Currency Code") and
            (not OldSetup."Validate Document Date"));
    end;
}

*/
