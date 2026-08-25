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
                    NewRec."OrderNr DXR-IB" := OldRec."OrderNr DXR-IB";
                    NewRec."Approved DXR-IB" := OldRec."Approved DXR-IB";
                    NewRec."IdentityTypeId DXR-IB" := Enum::"DXR_Ibanking Identity Type".FromInteger(OldRec."IdentityTypeId DXR-IB".AsInteger());
                    NewRec."IdentityNr DXR-IB" := OldRec."IdentityNr DXR-IB";
                    NewRec."Name1 DXR-IB" := OldRec."Name1 DXR-IB";
                    NewRec."Name2 DXR-IB" := OldRec."Name2 DXR-IB";
                    NewRec."CurrencyId DXR-IB" := OldRec."CurrencyId DXR-IB";
                    NewRec."CurrencySymbol DXR-IB" := OldRec."CurrencySymbol DXR-IB";
                    NewRec."PayeeId DXR-IB" := OldRec."PayeeId DXR-IB";
                    NewRec."PayeeFullName DXR-IB" := OldRec."PayeeFullName DXR-IB";
                    NewRec."Reference DXR-IB" := OldRec."Reference DXR-IB";
                    NewRec."NCF DXR-IB" := OldRec."NCF DXR-IB";
                    NewRec."DocumentClassId DXR-IB" := OldRec."DocumentClassId DXR-IB";
                    NewRec."DocumentDate DXR-IB" := OldRec."DocumentDate DXR-IB";
                    NewRec."PaymentDate DXR-IB" := OldRec."PaymentDate DXR-IB";
                    NewRec."PaymentMethodId DXR-IB" := Enum::"DXR_Ibanking Payment Method".FromInteger(OldRec."PaymentMethodId DXR-IB".AsInteger());
                    NewRec."BankAccountFromKey DXR-IB" := OldRec."BankAccountFromKey DXR-IB";
                    NewRec."BankAccountToKey DXR-IB" := OldRec."BankAccountToKey DXR-IB";
                    NewRec."NetAmount DXR-IB" := OldRec."NetAmount DXR-IB";
                    NewRec."Memo DXR-IB" := OldRec."Memo DXR-IB";
                    NewRec."Remarks DXR-IB" := OldRec."Remarks DXR-IB";
                    NewRec."Vendor No. DXR-IB" := OldRec."Vendor No. DXR-IB";
                    NewRec."Sent Payments DXR-IB" := OldRec."Sent Payments DXR-IB";
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
