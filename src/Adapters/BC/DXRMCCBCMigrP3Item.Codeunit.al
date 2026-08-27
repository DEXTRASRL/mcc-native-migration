#if not ESCUDEA and not BCDX
codeunit 60100 "DXR MCC BC Migr P3 Item"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyItemFields(): 2 renumbered tableextension fields, fill-only-if-blank (idempotent).
    //
    // Fixed 2026-08-27: same whole-table UPDLOCK problem, and the same fix, as
    // "DXR MCC BC Migr P3 Customer" - see that codeunit's header for the full rationale and the
    // Learn references. Item is the other table this matters most for here, because
    // "DXR MCC Bellon Migr Phase2".MigrateTableExt_ItemFields writes it too (33 fields), so the two
    // migrations were taking a full-table update lock on Item against each other.
    Permissions = tabledata Item = RIMD;

    trigger OnRun()
    var
        ItemRec: Record Item;
        ItemToUpdate: Record Item;
        RowsSinceCommit: Integer;
    begin
        ItemRec.SetLoadFields(
            "No.",
            "Payment Terms Code_DXR", "Payment Terms Code_Old",
            "Allow Decimals_DXR", "Allow Decimals_Old");
        if not ItemRec.FindSet(false) then
            exit;
        repeat
            if RowNeedsMigration(ItemRec) then
                if ItemToUpdate.Get(ItemRec."No.") then begin
                    if (ItemToUpdate."Payment Terms Code_DXR" = '') and (ItemToUpdate."Payment Terms Code_Old" <> '') then
                        ItemToUpdate."Payment Terms Code_DXR" := ItemToUpdate."Payment Terms Code_Old";

                    if (not ItemToUpdate."Allow Decimals_DXR") and ItemToUpdate."Allow Decimals_Old" then
                        ItemToUpdate."Allow Decimals_DXR" := true;

                    ItemToUpdate.Modify(false);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until ItemRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsMigration(var ItemRec: Record Item): Boolean
    begin
        exit(
            ((ItemRec."Payment Terms Code_DXR" = '') and (ItemRec."Payment Terms Code_Old" <> '')) or
            ((not ItemRec."Allow Decimals_DXR") and ItemRec."Allow Decimals_Old"));
    end;
}

#endif
