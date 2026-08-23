codeunit 60109 "DXR MCC RBPD Migr PagosProv"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigratePagosProveedores().
    Permissions = tabledata "DXR-IB PagosProveedores" = R,
                  tabledata "DXR_PagosProveedores" = RIM;

    trigger OnRun()
    var
        OldRec: Record "DXR-IB PagosProveedores";
        NewRec: Record "DXR_PagosProveedores";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."OrderNr DXR-IB") then begin
                    NewRec.Init();
                    NewRec.TransferFields(OldRec, true);
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
