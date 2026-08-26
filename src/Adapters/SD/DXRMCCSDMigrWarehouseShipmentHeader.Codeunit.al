/*
codeunit 60075 "DXR MCC SD Migr WhseShipHdr"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyWarehouseShipmentHeaderSpecialDispatch() (field
    // 59000->54747 on its own "DXR_Whse. Shipment Header Ext" table extension).
    Permissions = tabledata "Warehouse Shipment Header" = RM;

    trigger OnRun()
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
    begin
        if WhseShptHeader.FindSet(true) then
            repeat
                WhseShptHeader."Special Dispatch_DXR" := WhseShptHeader."Special Dispatch DXR";
                WhseShptHeader.Modify(false);
            until WhseShptHeader.Next() = 0;
    end;
}

*/
