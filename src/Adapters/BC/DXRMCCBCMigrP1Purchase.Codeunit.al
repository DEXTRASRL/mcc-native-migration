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
        NewSetup.TransferFields(OldSetup, true);
        NewSetup.Insert(false);
    end;
}
