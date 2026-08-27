#if not ESCUDEA and not BCDX
codeunit 60074 "DXR MCC SD Migr SalesShipHdr"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopySalesShipmentHeaderSpecialDispatch() (field
    // 59000->54747 on its own "DXR_Sales Shipment Headr Ext" table extension).
    Permissions = tabledata "Sales Shipment Header" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer".
    trigger OnRun()
    var
        SalesShptHeader: Record "Sales Shipment Header";
        SalesShptHeaderToUpdate: Record "Sales Shipment Header";
        RowsSinceCommit: Integer;
    begin
        SalesShptHeader.SetLoadFields("No.", "Special Dispatch_DXR", "Special Dispatch DXR");
        if not SalesShptHeader.FindSet(false) then
            exit;
        repeat
            if SalesShptHeader."Special Dispatch_DXR" <> SalesShptHeader."Special Dispatch DXR" then
                if SalesShptHeaderToUpdate.Get(SalesShptHeader."No.") then begin
                    SalesShptHeaderToUpdate."Special Dispatch_DXR" := SalesShptHeaderToUpdate."Special Dispatch DXR";
                    SalesShptHeaderToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until SalesShptHeader.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
