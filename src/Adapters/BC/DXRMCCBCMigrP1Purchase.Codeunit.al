#if not ESCUDEA and not BCDX
codeunit 60087 "DXR MCC BC Migr P1 Purchase"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
    // CopyPurchaseControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
    Permissions = tabledata "DXR Purchase Controls Setup" = R,
                  tabledata "DXR_Purchase Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR Purchase Controls Setup";
        NewSetup: Record "DXR_Purchase Controls Setup";
    begin
        if not OldSetup.Get('') then
            exit;
        if NewSetup.Get('') then
            exit;
        NewSetup.Init();
        NewSetup.Code := OldSetup.Code;
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
        NewSetup.Insert(false);
    end;
}

#endif
