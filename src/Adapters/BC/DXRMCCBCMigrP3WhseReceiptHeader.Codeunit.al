#if not ESCUDEA and not BCDX
codeunit 60102 "DXR MCC BC Migr P3 WhseRcptHd"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyWhseReceiptHeaderFields(): 4 renumbered tableextension fields, fill-only-if-blank
    // (idempotent).
    Permissions = tabledata "Warehouse Receipt Header" = RIMD;

    trigger OnRun()
    var
        WhseReceiptHeaderRec: Record "Warehouse Receipt Header";
        Modified: Boolean;
    begin
        if not WhseReceiptHeaderRec.FindSet(true) then
            exit;
        repeat
            Modified := false;

            if (WhseReceiptHeaderRec."Customer No._DXR" = '') and (WhseReceiptHeaderRec."Customer No._Old" <> '') then begin
                WhseReceiptHeaderRec."Customer No._DXR" := WhseReceiptHeaderRec."Customer No._Old";
                Modified := true;
            end;

            if (WhseReceiptHeaderRec."Vendor No._DXR" = '') and (WhseReceiptHeaderRec."Vendor No._Old" <> '') then begin
                WhseReceiptHeaderRec."Vendor No._DXR" := WhseReceiptHeaderRec."Vendor No._Old";
                Modified := true;
            end;

            if (WhseReceiptHeaderRec."Vendor Name_DXR" = '') and (WhseReceiptHeaderRec."Vendor Name_Old" <> '') then begin
                WhseReceiptHeaderRec."Vendor Name_DXR" := WhseReceiptHeaderRec."Vendor Name_Old";
                Modified := true;
            end;

            if (WhseReceiptHeaderRec."Customer Name_DXR" = '') and (WhseReceiptHeaderRec."Customer Name_Old" <> '') then begin
                WhseReceiptHeaderRec."Customer Name_DXR" := WhseReceiptHeaderRec."Customer Name_Old";
                Modified := true;
            end;

            if Modified then
                WhseReceiptHeaderRec.Modify(false);
        until WhseReceiptHeaderRec.Next() = 0;
    end;
}

#endif
