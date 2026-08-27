#if not ESCUDEA and not BCDX
codeunit 60073 "DXR MCC SD Migr SalesInvHdr"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopySalesInvoiceHeaderSpecialDispatch() (field
    // 59000->54747 on its own "DXR_Sales Invoice Header Ext" table extension).
    Permissions = tabledata "Sales Invoice Header" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer". Sales Invoice Header is one of the largest tables in a live
    // company, so the old full-table update lock was the worst instance of this pattern here.
    trigger OnRun()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvHeaderToUpdate: Record "Sales Invoice Header";
        RowsSinceCommit: Integer;
    begin
        SalesInvHeader.SetLoadFields("No.", "Special Dispatch_DXR", "Special Dispatch DXR");
        if not SalesInvHeader.FindSet(false) then
            exit;
        repeat
            if SalesInvHeader."Special Dispatch_DXR" <> SalesInvHeader."Special Dispatch DXR" then
                if SalesInvHeaderToUpdate.Get(SalesInvHeader."No.") then begin
                    SalesInvHeaderToUpdate."Special Dispatch_DXR" := SalesInvHeaderToUpdate."Special Dispatch DXR";
                    SalesInvHeaderToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until SalesInvHeader.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
