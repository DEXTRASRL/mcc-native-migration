#if not ESCUDEA and not BCDX
codeunit 60101 "DXR MCC BC Migr P3 SalesHdr"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopySalesHeaderFields(): 1 renumbered tableextension field, fill-only-if-blank (idempotent).
    //
    // Fixed 2026-08-27: same whole-table UPDLOCK problem, and the same fix, as
    // "DXR MCC BC Migr P3 Customer" - see that codeunit's header for the full rationale and the
    // Learn references. Sales Header is a live transactional table, so holding an update lock over
    // all of it also blocked ordinary order entry for the duration of the run, not just other
    // migrations.
    Permissions = tabledata "Sales Header" = RIMD;

    trigger OnRun()
    var
        SalesHeaderRec: Record "Sales Header";
        SalesHeaderToUpdate: Record "Sales Header";
        RowsSinceCommit: Integer;
    begin
        SalesHeaderRec.SetLoadFields("Document Type", "No.", "Reference Address_DXR", "Reference Address_Old");
        SalesHeaderRec.SetFilter("Reference Address_Old", '<>%1', '');
        SalesHeaderRec.SetRange("Reference Address_DXR", '');
        if not SalesHeaderRec.FindSet(false) then
            exit;
        repeat
            if SalesHeaderToUpdate.Get(SalesHeaderRec."Document Type", SalesHeaderRec."No.") then
                if (SalesHeaderToUpdate."Reference Address_DXR" = '') and (SalesHeaderToUpdate."Reference Address_Old" <> '') then begin
                    SalesHeaderToUpdate."Reference Address_DXR" := SalesHeaderToUpdate."Reference Address_Old";
                    SalesHeaderToUpdate.Modify(false);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until SalesHeaderRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;
}

#endif
