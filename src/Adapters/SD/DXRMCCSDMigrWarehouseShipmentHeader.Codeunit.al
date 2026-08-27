#if not ESCUDEA and not BCDX
codeunit 60075 "DXR MCC SD Migr WhseShipHdr"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyWarehouseShipmentHeaderSpecialDispatch() (field
    // 59000->54747 on its own "DXR_Whse. Shipment Header Ext" table extension).
    Permissions = tabledata "Warehouse Shipment Header" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer". Warehouse Shipment Header is live transactional data, so the
    // old full-table update lock blocked warehouse operators for the duration of the run.
    trigger OnRun()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptHeaderToUpdate: Record "Warehouse Shipment Header";
        RowsSinceCommit: Integer;
    begin
        WhseShptHeader.SetLoadFields("No.", "Special Dispatch_DXR", "Special Dispatch DXR");
        if not WhseShptHeader.FindSet(false) then
            exit;
        repeat
            if WhseShptHeader."Special Dispatch_DXR" <> WhseShptHeader."Special Dispatch DXR" then
                if WhseShptHeaderToUpdate.Get(WhseShptHeader."No.") then begin
                    WhseShptHeaderToUpdate."Special Dispatch_DXR" := WhseShptHeaderToUpdate."Special Dispatch DXR";
                    WhseShptHeaderToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until WhseShptHeader.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
