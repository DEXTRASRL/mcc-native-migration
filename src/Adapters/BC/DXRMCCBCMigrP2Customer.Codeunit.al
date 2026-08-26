#if not ESCUDEA and not BCDX
codeunit 60097 "DXR MCC BC Migr P2 Customer"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopyCustomerControlsSetup() - see "DXR MCC BC Migr P2 Warehouse" for the full rationale.
    Permissions = tabledata "DXR_Customer Ctrl Setup Old2" = R,
                  tabledata "DXR_Customer Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Customer Ctrl Setup Old2";
        NewSetup: Record "DXR_Customer Controls Setup";
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
        NewSetup."Mandatory Currency Code" := OldSetup."Mandatory Currency Code";

        if NewSetupExists then
            NewSetup.Modify(false)
        else
            NewSetup.Insert(false);
    end;

    local procedure IsOldSetupRowBlank(var OldSetup: Record "DXR_Customer Ctrl Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."Mandatory Currency Code"));
    end;
}

#endif
