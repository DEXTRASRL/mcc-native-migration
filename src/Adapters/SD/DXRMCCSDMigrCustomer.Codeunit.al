#if not ESCUDEA and not BCDX
codeunit 60070 "DXR MCC SD Migr Customer"
{
    // Native local migration (2026-08-23, per user directive to stop delegating via .Run() and
    // instead have MCC perform the actual field copy itself): ported from Special Dispatch's own
    // "DXR_SD_Migr_Phase1_FieldDup".CopyCustomerSpecialDispatch(), which used generic
    // RecordRef/FieldRef reflection over field numbers 59000/54747. Written here as typed Record
    // field access instead - the field names ("Special Dispatch DXR"/"Special Dispatch_DXR") are
    // real, compiled fields on Special Dispatch's own "DXR_Customer Ext" (59000) table extension,
    // visible here because Special Dispatch is a real app.json dependency of MCC.
    Permissions = tabledata Customer = RM;

    trigger OnRun()
    var
        Cust: Record Customer;
        RowsSinceCommit: Integer;
    begin
        if Cust.FindSet(true) then
            repeat
                if Cust."Special Dispatch_DXR" <> Cust."Special Dispatch DXR" then begin
                    Cust."Special Dispatch_DXR" := Cust."Special Dispatch DXR";
                    Cust.Modify(false);
                end;
                RowsSinceCommit += 1;
                if RowsSinceCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until Cust.Next() = 0;
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
