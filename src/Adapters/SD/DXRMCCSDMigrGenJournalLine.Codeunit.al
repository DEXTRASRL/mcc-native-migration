#if not ESCUDEA and not BCDX
codeunit 60076 "DXR MCC SD Migr GenJnlLine"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyGenJournalLineSpecialDispatch() (field 59000->54747 on
    // its own "DXR_Gen. Journal Line Ext" table extension).
    Permissions = tabledata "Gen. Journal Line" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer" - read partial and unlocked, lock only the rows that change,
    // and count commits per MODIFIED row instead of per row read.
    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLineToUpdate: Record "Gen. Journal Line";
        RowsSinceCommit: Integer;
    begin
        GenJnlLine.SetLoadFields("Journal Template Name", "Journal Batch Name", "Line No.",
            "Special Dispatch_DXR", "Special Dispatch DXR");
        if not GenJnlLine.FindSet(false) then
            exit;
        repeat
            if GenJnlLine."Special Dispatch_DXR" <> GenJnlLine."Special Dispatch DXR" then
                if GenJnlLineToUpdate.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", GenJnlLine."Line No.") then begin
                    GenJnlLineToUpdate."Special Dispatch_DXR" := GenJnlLineToUpdate."Special Dispatch DXR";
                    GenJnlLineToUpdate.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
        until GenJnlLine.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
