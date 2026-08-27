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

    // Fixed 2026-08-27: FindSet(true) over the WHOLE Customer table read every row under
    // IsolationLevel::UpdLock (Learn "Record.FindSet") and, with no SetLoadFields, joined every
    // tableextension companion table for every row; the commit counter also advanced per row READ
    // instead of per row MODIFIED. Now reads partial + unlocked and locks only rows that change.
    trigger OnRun()
    var
        Cust: Record Customer;
        CustToUpdate: Record Customer;
        Blank: Record Customer;
        RowsSinceCommit: Integer;
    begin
        Cust.SetLoadFields("No.", "Special Dispatch_DXR", "Special Dispatch DXR");
        if not Cust.FindSet(false) then
            exit;
        repeat
            if Cust."Special Dispatch_DXR" <> Cust."Special Dispatch DXR" then
                if CustToUpdate.Get(Cust."No.") then begin
                    // Fixed 2026-08-27 (never-overwrite): the dirty-check above only avoids a no-op
                    // write - it does not stop a re-run from overwriting an already-populated _DXR
                    // value with the legacy one.
                    if CustToUpdate."Special Dispatch_DXR" = Blank."Special Dispatch_DXR" then
                        CustToUpdate."Special Dispatch_DXR" := CustToUpdate."Special Dispatch DXR";
                    CustToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until Cust.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
