#if not ESCUDEA and not BCDX
codeunit 60075 "DXR MCC SD Migr WhseShipHdr"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyWarehouseShipmentHeaderSpecialDispatch() (field
    // 59000->54747 on its own "DXR_Whse. Shipment Header Ext" table extension).
    Permissions = tabledata "Warehouse Shipment Header" = RM;

    trigger OnRun()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        RowsSinceCommit: Integer;
    begin
        if WhseShptHeader.FindSet(true) then
            repeat
                if WhseShptHeader."Special Dispatch_DXR" <> WhseShptHeader."Special Dispatch DXR" then begin
                    WhseShptHeader."Special Dispatch_DXR" := WhseShptHeader."Special Dispatch DXR";
                    WhseShptHeader.Modify(false);
                end;
                RowsSinceCommit += 1;
                if RowsSinceCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until WhseShptHeader.Next() = 0;
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
