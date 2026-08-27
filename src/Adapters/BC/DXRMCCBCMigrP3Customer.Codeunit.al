#if not ESCUDEA and not BCDX
codeunit 60099 "DXR MCC BC Migr P3 Customer"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
    // CopyCustomerFields(): 3 renumbered tableextension fields, fills only when the new _DXR
    // field is still blank/default - never overwrites an already-set value (idempotent).
    //
    // Fixed 2026-08-27 (concept BC-P3 seq 8 observed stuck at Status = Running, Duration 0, no
    // error). The loop used to be `Customer.FindSet(true)` over the WHOLE table with no filter and
    // no partial-record hint. Per Learn ("Record.FindSet"): FindSet "will request all rows at once",
    // and with ForUpdate = true it reads them "using IsolationLevel::UpdLock (SQL UPDLOCK)". So this
    // took an update lock on every customer row - including the overwhelming majority that have
    // nothing to migrate - and held it for the whole run. "DXR MCC Bellon Migr Phase2"'s
    // MigrateTableExt_CustomerFields writes the SAME table, so the two serialize against each other
    // and whichever starts second simply waits. Learn's own "How to reduce database locking" guidance
    // is the fix applied here: read WITHOUT the update lock, and take the lock only on the rows that
    // actually change.
    //   * SetLoadFields limits the read to the seven fields this migration touches. Learn recommends
    //     partial records "especially when looping through several records or when table extensions
    //     are defined on the table" - Customer carries many tableextensions in this portfolio, and
    //     without this every one of their companion tables was joined in for every row.
    //   * FindSet(false) reads without UPDLOCK.
    //   * The row is re-read with Get() and locked only when it genuinely needs a value copied.
    //   * The commit counter now advances per MODIFIED row instead of per scanned row, so a run that
    //     has nothing to do performs zero writes and zero commits instead of one commit per 500 rows.
    // No migration semantics change: same three fields, same fill-only-if-blank guards, same result.
    Permissions = tabledata Customer = RIMD;

    // Fixed 2026-08-27 (Task 3, motor por tabla): el cuerpo de este trigger se movio a
    // "DXR MCC Master Customer" (60450).ApplyBC() - ese codeunit hace un solo recorrido de
    // Customer para los 6 bloques que si migraron (BELLON, BC, DESB, DRLOC, PCM, SD) en vez de
    // uno por extension. No-op deliberado, no se borra: RunPortfolio/RunConcept siguen invocando
    // este codeunit por su ID (60099) via Codeunit.Run.
    trigger OnRun()
    begin
    end;

    local procedure RowNeedsMigration(var CustomerRec: Record Customer): Boolean
    begin
        exit(
            ((not CustomerRec."Mandatory Order No._DXR") and CustomerRec."Mandatory Order No._Old") or
            ((CustomerRec."Exp. Exemption Card_DXR" = 0D) and (CustomerRec."Exp. Exemption Card_Old" <> 0D)) or
            ((CustomerRec."Reference Address_DXR" = '') and (CustomerRec."Reference Address_Old" <> '')));
    end;
}

#endif
