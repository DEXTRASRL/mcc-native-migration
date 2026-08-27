#if not ESCUDEA and not BCDX
codeunit 60103 "DXR MCC BC Migr P3 WhseShipHd"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyWhseShipmentHeaderFields(): 4 renumbered tableextension fields, fill-only-if-blank
    // (idempotent).
    Permissions = tabledata "Warehouse Shipment Header" = RIMD;

    trigger OnRun()
    var
        WhseShipmentHeaderRec: Record "Warehouse Shipment Header";
        Modified: Boolean;
        RowsSinceCommit: Integer;
    begin
        if not WhseShipmentHeaderRec.FindSet(true) then
            exit;
        repeat
            Modified := false;

            if (WhseShipmentHeaderRec."Customer No._DXR" = '') and (WhseShipmentHeaderRec."Customer No._Old" <> '') then begin
                WhseShipmentHeaderRec."Customer No._DXR" := WhseShipmentHeaderRec."Customer No._Old";
                Modified := true;
            end;

            if (WhseShipmentHeaderRec."Vendor No._DXR" = '') and (WhseShipmentHeaderRec."Vendor No._Old" <> '') then begin
                WhseShipmentHeaderRec."Vendor No._DXR" := WhseShipmentHeaderRec."Vendor No._Old";
                Modified := true;
            end;

            if (WhseShipmentHeaderRec."Vendor Name_DXR" = '') and (WhseShipmentHeaderRec."Vendor Name_Old" <> '') then begin
                WhseShipmentHeaderRec."Vendor Name_DXR" := WhseShipmentHeaderRec."Vendor Name_Old";
                Modified := true;
            end;

            if (WhseShipmentHeaderRec."Customer Name_DXR" = '') and (WhseShipmentHeaderRec."Customer Name_Old" <> '') then begin
                WhseShipmentHeaderRec."Customer Name_DXR" := WhseShipmentHeaderRec."Customer Name_Old";
                Modified := true;
            end;

            if Modified then
                WhseShipmentHeaderRec.Modify(false);

            RowsSinceCommit += 1;
            if RowsSinceCommit >= 500 then begin
                Commit();
                RowsSinceCommit := 0;
            end;
        until WhseShipmentHeaderRec.Next() = 0;
        Commit();
    end;
}

#endif
