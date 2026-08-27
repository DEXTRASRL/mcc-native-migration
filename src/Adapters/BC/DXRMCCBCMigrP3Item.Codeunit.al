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

    // Fixed 2026-08-27 (Task 4, motor por tabla): el cuerpo de este trigger se movio a
    // "DXR MCC Master Item" (60451).ApplyBC() - ese codeunit hace un solo recorrido de Item para
    // los 5 bloques que si migraron (BC, BELLON, DESB, DRLOC, FE) en vez de uno por extension.
    // No-op deliberado, no se borra: RunPortfolio/RunConcept siguen invocando este codeunit por
    // su ID (60100) via Codeunit.Run.
    trigger OnRun()
    begin
    end;

    local procedure RowNeedsMigration(var ItemRec: Record Item): Boolean
    begin
        exit(
            ((ItemRec."Payment Terms Code_DXR" = '') and (ItemRec."Payment Terms Code_Old" <> '')) or
            ((not ItemRec."Allow Decimals_DXR") and ItemRec."Allow Decimals_Old"));
    end;
}

#endif
