codeunit 60086 "DXR MCC BC Migr P1 Warehouse"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
    // CopyWarehouseControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
    Permissions = tabledata "DXR Warehouse Controls Setup" = R,
                  tabledata "DXR_Warehouse Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR Warehouse Controls Setup";
        NewSetup: Record "DXR_Warehouse Controls Setup";
    begin
        if not OldSetup.Get('') then
            exit;
        if NewSetup.Get('') then
            exit;
        NewSetup.TransferFields(OldSetup, true);
        NewSetup.Insert(false);
    end;
}
