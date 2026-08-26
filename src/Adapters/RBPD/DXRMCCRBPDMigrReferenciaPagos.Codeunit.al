#if not ESCUDEA and not BCDX
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
                    NewRec."Entry No. DXR-IB" := OldRec."Entry No. DXR-IB";
                    NewRec."No. DXR-IB" := OldRec."No. DXR-IB";
                    NewRec."Name DXR-IB" := OldRec."Name DXR-IB";
                    NewRec."VAT Registration No. DXR-IB" := OldRec."VAT Registration No. DXR-IB";
                    NewRec."Document Type DXR-IB" := OldRec."Document Type DXR-IB";
                    NewRec."Document No. DXR-IB" := OldRec."Document No. DXR-IB";
                    NewRec."VAT Amount DXR-IB" := OldRec."VAT Amount DXR-IB";
                    NewRec."Amount DXR-IB" := OldRec."Amount DXR-IB";
                    NewRec."Remaining Amount DXR-IB" := OldRec."Remaining Amount DXR-IB";
                    NewRec."Currency Code DXR-IB" := OldRec."Currency Code DXR-IB";
                    NewRec."Posting Date DXR-IB" := OldRec."Posting Date DXR-IB";
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}

#endif
