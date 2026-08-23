codeunit 60071 "DXR MCC SD Migr DispModSetup"
{
    // Native local migration - ported from Special Dispatch's own
    // "DXR_SD_Migr_Phase2_LegacyTable".Execute(), which used generic RecordRef/FieldRef reflection
    // (GetCommonCompatibleFieldNos) to copy every common field between the two tables. Written here
    // as a typed TransferFields upsert instead: both tables (legacy 59114 "Dispatch Module Setup"
    // and active 54778 "DXR_Dispatch Module Setup") share an identical field layout (same field
    // numbers 50000-50007, same "Key" primary key), so TransferFields matches every field 1:1 by
    // number, same as the original reflection-based copy did.
    Permissions = tabledata "Dispatch Module Setup" = R,
                  tabledata "DXR_Dispatch Module Setup" = RIM;

    trigger OnRun()
    var
        Old: Record "Dispatch Module Setup";
        New: Record "DXR_Dispatch Module Setup";
    begin
        if Old.FindSet() then
            repeat
                if New.Get(Old."Key") then begin
                    New.TransferFields(Old, false);
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.TransferFields(Old, true);
                    New.Insert(false);
                end;
            until Old.Next() = 0;
    end;
}
