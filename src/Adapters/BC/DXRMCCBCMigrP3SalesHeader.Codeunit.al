#if not ESCUDEA and not BCDX
codeunit 60101 "DXR MCC BC Migr P3 SalesHdr"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopySalesHeaderFields(): 1 renumbered tableextension field, fill-only-if-blank (idempotent).
    Permissions = tabledata "Sales Header" = RIMD;

    trigger OnRun()
    var
        SalesHeaderRec: Record "Sales Header";
        RowsSinceCommit: Integer;
    begin
        if not SalesHeaderRec.FindSet(true) then
            exit;
        repeat
            if (SalesHeaderRec."Reference Address_DXR" = '') and (SalesHeaderRec."Reference Address_Old" <> '') then begin
                SalesHeaderRec."Reference Address_DXR" := SalesHeaderRec."Reference Address_Old";
                SalesHeaderRec.Modify(false);
            end;

            RowsSinceCommit += 1;
            if RowsSinceCommit >= 500 then begin
                Commit();
                RowsSinceCommit := 0;
            end;
        until SalesHeaderRec.Next() = 0;
        Commit();
    end;
}

#endif
