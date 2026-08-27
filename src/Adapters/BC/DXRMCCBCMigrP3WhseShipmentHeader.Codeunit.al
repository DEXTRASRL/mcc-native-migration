#if not ESCUDEA and not BCDX
codeunit 60103 "DXR MCC BC Migr P3 WhseShipHd"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyWhseShipmentHeaderFields(): 4 renumbered tableextension fields, fill-only-if-blank
    // (idempotent).
    //
    // Fixed 2026-08-27: same whole-table UPDLOCK problem, and the same fix, as
    // "DXR MCC BC Migr P3 Customer" - see that codeunit's header for the full rationale and the
    // Learn references. Warehouse Shipment Header is a live transactional table, so the old
    // full-table update lock blocked warehouse operators for the duration of the run.
    Permissions = tabledata "Warehouse Shipment Header" = RIMD;

    trigger OnRun()
    var
        WhseShipmentHeaderRec: Record "Warehouse Shipment Header";
        WhseShipmentHeaderToUpdate: Record "Warehouse Shipment Header";
        RowsSinceCommit: Integer;
    begin
        WhseShipmentHeaderRec.SetLoadFields(
            "No.",
            "Customer No._DXR", "Customer No._Old",
            "Vendor No._DXR", "Vendor No._Old",
            "Vendor Name_DXR", "Vendor Name_Old",
            "Customer Name_DXR", "Customer Name_Old");
        if not WhseShipmentHeaderRec.FindSet(false) then
            exit;
        repeat
            if RowNeedsMigration(WhseShipmentHeaderRec) then
                if WhseShipmentHeaderToUpdate.Get(WhseShipmentHeaderRec."No.") then begin
                    if (WhseShipmentHeaderToUpdate."Customer No._DXR" = '') and (WhseShipmentHeaderToUpdate."Customer No._Old" <> '') then
                        WhseShipmentHeaderToUpdate."Customer No._DXR" := WhseShipmentHeaderToUpdate."Customer No._Old";

                    if (WhseShipmentHeaderToUpdate."Vendor No._DXR" = '') and (WhseShipmentHeaderToUpdate."Vendor No._Old" <> '') then
                        WhseShipmentHeaderToUpdate."Vendor No._DXR" := WhseShipmentHeaderToUpdate."Vendor No._Old";

                    if (WhseShipmentHeaderToUpdate."Vendor Name_DXR" = '') and (WhseShipmentHeaderToUpdate."Vendor Name_Old" <> '') then
                        WhseShipmentHeaderToUpdate."Vendor Name_DXR" := WhseShipmentHeaderToUpdate."Vendor Name_Old";

                    if (WhseShipmentHeaderToUpdate."Customer Name_DXR" = '') and (WhseShipmentHeaderToUpdate."Customer Name_Old" <> '') then
                        WhseShipmentHeaderToUpdate."Customer Name_DXR" := WhseShipmentHeaderToUpdate."Customer Name_Old";

                    WhseShipmentHeaderToUpdate.Modify(false);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until WhseShipmentHeaderRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsMigration(var WhseShipmentHeaderRec: Record "Warehouse Shipment Header"): Boolean
    begin
        exit(
            ((WhseShipmentHeaderRec."Customer No._DXR" = '') and (WhseShipmentHeaderRec."Customer No._Old" <> '')) or
            ((WhseShipmentHeaderRec."Vendor No._DXR" = '') and (WhseShipmentHeaderRec."Vendor No._Old" <> '')) or
            ((WhseShipmentHeaderRec."Vendor Name_DXR" = '') and (WhseShipmentHeaderRec."Vendor Name_Old" <> '')) or
            ((WhseShipmentHeaderRec."Customer Name_DXR" = '') and (WhseShipmentHeaderRec."Customer Name_Old" <> '')));
    end;
}

#endif
