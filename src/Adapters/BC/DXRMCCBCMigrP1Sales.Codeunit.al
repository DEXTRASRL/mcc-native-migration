codeunit 60088 "DXR MCC BC Migr P1 Sales"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
    // CopySalesControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
    Permissions = tabledata "DXR Sales Controls Setup" = R,
                  tabledata "DXR_Sales Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR Sales Controls Setup";
        NewSetup: Record "DXR_Sales Controls Setup";
    begin
        if not OldSetup.Get('') then
            exit;
        if NewSetup.Get('') then
            exit;
        NewSetup.TransferFields(OldSetup, true);
        NewSetup.Insert(false);
    end;
}
