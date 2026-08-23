codeunit 60110 "DXR MCC RBPD Migr RefPagos"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateReferenciaPagos().
    Permissions = tabledata "DXR-IB IbankingReferenciaPagos" = R,
                  tabledata "DXR_IbankingReferenciaPagos" = RIM;

    trigger OnRun()
    var
        OldRec: Record "DXR-IB IbankingReferenciaPagos";
        NewRec: Record "DXR_IbankingReferenciaPagos";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Entry No. DXR-IB") then begin
                    NewRec.Init();
                    NewRec.TransferFields(OldRec, true);
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
