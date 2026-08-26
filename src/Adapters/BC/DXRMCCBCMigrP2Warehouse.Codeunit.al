/*
codeunit 60092 "DXR MCC BC Migr P2 Warehouse"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopyWarehouseControlsSetup(): restores from the *Old2 snapshot (newer generation than
    // Phase 1's source), skipping when Old2's row is blank/default (2026-08-22 fix, preserves
    // real data Phase 1 may already have written) and overwriting the active row when Old2 has
    // real configuration - Old2 is a frozen legacy snapshot, so this stays idempotent in effect
    // even though it re-Modifies on every run.
    Permissions = tabledata "DXR_Warehouse Ctrl Setup Old2" = R,
                  tabledata "DXR_Warehouse Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Warehouse Ctrl Setup Old2";
        NewSetup: Record "DXR_Warehouse Controls Setup";
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
        NewSetup."WHS. Receipt Posting Date" := OldSetup."WHS. Receipt Posting Date";
        NewSetup."WHS. Shipment Posting Date" := OldSetup."WHS. Shipment Posting Date";
        NewSetup."Validate Transfer Reopen" := OldSetup."Validate Transfer Reopen";
        NewSetup."Show Vendor in Shipment" := OldSetup."Show Vendor in Shipment";
        NewSetup."Show Customer in Receipt" := OldSetup."Show Customer in Receipt";
        NewSetup."Show Receipt Detail" := OldSetup."Show Receipt Detail";
        NewSetup."Show Shipment Detail" := OldSetup."Show Shipment Detail";
        NewSetup."Show Customer in Shipment" := OldSetup."Show Customer in Shipment";
        NewSetup."Show Vendor in Receipt" := OldSetup."Show Vendor in Receipt";
        NewSetup."Show Customer in Ship List" := OldSetup."Show Customer in Ship List";
        NewSetup."Show Vendor in Ship List" := OldSetup."Show Vendor in Ship List";
        NewSetup."Show Customer in Rcpt List" := OldSetup."Show Customer in Rcpt List";
        NewSetup."Show Vendor in Rcpt List" := OldSetup."Show Vendor in Rcpt List";
        NewSetup."Show Ship Factbox" := OldSetup."Show Ship Factbox";
        NewSetup."Show Rcpt Factbox" := OldSetup."Show Rcpt Factbox";
        NewSetup."Show Receipt Totals" := OldSetup."Show Receipt Totals";
        NewSetup."Show Shipment Totals" := OldSetup."Show Shipment Totals";

        if NewSetupExists then
            NewSetup.Modify(false)
        else
            NewSetup.Insert(false);
    end;

    local procedure IsOldSetupRowBlank(var OldSetup: Record "DXR_Warehouse Ctrl Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."WHS. Receipt Posting Date") and
            (not OldSetup."WHS. Shipment Posting Date") and
            (not OldSetup."Validate Transfer Reopen") and
            (not OldSetup."Show Vendor in Shipment") and
            (not OldSetup."Show Customer in Receipt") and
            (not OldSetup."Show Receipt Detail") and
            (not OldSetup."Show Shipment Detail") and
            (not OldSetup."Show Customer in Shipment") and
            (not OldSetup."Show Vendor in Receipt") and
            (not OldSetup."Show Customer in Ship List") and
            (not OldSetup."Show Vendor in Ship List") and
            (not OldSetup."Show Customer in Rcpt List") and
            (not OldSetup."Show Vendor in Rcpt List") and
            (not OldSetup."Show Ship Factbox") and
            (not OldSetup."Show Rcpt Factbox") and
            (not OldSetup."Show Receipt Totals") and
            (not OldSetup."Show Shipment Totals"));
    end;
}

*/
