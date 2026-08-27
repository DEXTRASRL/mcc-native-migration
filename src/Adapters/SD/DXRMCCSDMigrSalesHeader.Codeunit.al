#if not ESCUDEA and not BCDX
codeunit 60072 "DXR MCC SD Migr SalesHeader"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopySalesHeaderSpecialDispatch() (field 59000->54747 on
    // its own "DXR_Sales Header Ext" table extension).
    Permissions = tabledata "Sales Header" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer". Sales Header is a live transactional table, so the old
    // full-table update lock also blocked ordinary order entry for the whole run.
    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderToUpdate: Record "Sales Header";
        RowsSinceCommit: Integer;
    begin
        SalesHeader.SetLoadFields("Document Type", "No.", "Special Dispatch_DXR", "Special Dispatch DXR");
        if not SalesHeader.FindSet(false) then
            exit;
        repeat
            if SalesHeader."Special Dispatch_DXR" <> SalesHeader."Special Dispatch DXR" then
                if SalesHeaderToUpdate.Get(SalesHeader."Document Type", SalesHeader."No.") then begin
                    SalesHeaderToUpdate."Special Dispatch_DXR" := SalesHeaderToUpdate."Special Dispatch DXR";
                    SalesHeaderToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until SalesHeader.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
