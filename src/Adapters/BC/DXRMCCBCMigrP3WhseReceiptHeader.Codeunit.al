#if not ESCUDEA and not BCDX
codeunit 60102 "DXR MCC BC Migr P3 WhseRcptHd"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyWhseReceiptHeaderFields(): 4 renumbered tableextension fields, fill-only-if-blank
    // (idempotent).
    //
    // Fixed 2026-08-27: same whole-table UPDLOCK problem, and the same fix, as
    // "DXR MCC BC Migr P3 Customer" - see that codeunit's header for the full rationale and the
    // Learn references. Warehouse Receipt Header is a live transactional table, so the old
    // full-table update lock blocked warehouse operators for the duration of the run.
    Permissions = tabledata "Warehouse Receipt Header" = RIMD;

    trigger OnRun()
    var
        WhseReceiptHeaderRec: Record "Warehouse Receipt Header";
        WhseReceiptHeaderToUpdate: Record "Warehouse Receipt Header";
        RowsSinceCommit: Integer;
    begin
        WhseReceiptHeaderRec.SetLoadFields(
            "No.",
            "Customer No._DXR", "Customer No._Old",
            "Vendor No._DXR", "Vendor No._Old",
            "Vendor Name_DXR", "Vendor Name_Old",
            "Customer Name_DXR", "Customer Name_Old");
        if not WhseReceiptHeaderRec.FindSet(false) then
            exit;
        repeat
            if RowNeedsMigration(WhseReceiptHeaderRec) then
                if WhseReceiptHeaderToUpdate.Get(WhseReceiptHeaderRec."No.") then begin
                    if (WhseReceiptHeaderToUpdate."Customer No._DXR" = '') and (WhseReceiptHeaderToUpdate."Customer No._Old" <> '') then
                        WhseReceiptHeaderToUpdate."Customer No._DXR" := WhseReceiptHeaderToUpdate."Customer No._Old";

                    if (WhseReceiptHeaderToUpdate."Vendor No._DXR" = '') and (WhseReceiptHeaderToUpdate."Vendor No._Old" <> '') then
                        WhseReceiptHeaderToUpdate."Vendor No._DXR" := WhseReceiptHeaderToUpdate."Vendor No._Old";

                    if (WhseReceiptHeaderToUpdate."Vendor Name_DXR" = '') and (WhseReceiptHeaderToUpdate."Vendor Name_Old" <> '') then
                        WhseReceiptHeaderToUpdate."Vendor Name_DXR" := WhseReceiptHeaderToUpdate."Vendor Name_Old";

                    if (WhseReceiptHeaderToUpdate."Customer Name_DXR" = '') and (WhseReceiptHeaderToUpdate."Customer Name_Old" <> '') then
                        WhseReceiptHeaderToUpdate."Customer Name_DXR" := WhseReceiptHeaderToUpdate."Customer Name_Old";

                    WhseReceiptHeaderToUpdate.Modify(false);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until WhseReceiptHeaderRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsMigration(var WhseReceiptHeaderRec: Record "Warehouse Receipt Header"): Boolean
    begin
        exit(
            ((WhseReceiptHeaderRec."Customer No._DXR" = '') and (WhseReceiptHeaderRec."Customer No._Old" <> '')) or
            ((WhseReceiptHeaderRec."Vendor No._DXR" = '') and (WhseReceiptHeaderRec."Vendor No._Old" <> '')) or
            ((WhseReceiptHeaderRec."Vendor Name_DXR" = '') and (WhseReceiptHeaderRec."Vendor Name_Old" <> '')) or
            ((WhseReceiptHeaderRec."Customer Name_DXR" = '') and (WhseReceiptHeaderRec."Customer Name_Old" <> '')));
    end;
}

#endif
