codeunit 60113 "DXR MCC RBPD Migr MidwareSet"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateMiddlewareSetup().
    Permissions = tabledata "DXR-IB MiddlewareSetup" = R,
                  tabledata "DXR_MiddlewareSetup" = RIM;

    trigger OnRun()
    var
        OldRec: Record "DXR-IB MiddlewareSetup";
        NewRec: Record "DXR_MiddlewareSetup";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Primary Key") then begin
                    NewRec.Init();
                    NewRec.TransferFields(OldRec, true);
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
