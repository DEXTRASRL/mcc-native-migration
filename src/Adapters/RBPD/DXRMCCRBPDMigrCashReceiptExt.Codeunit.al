#if not ESCUDEA and not BCDX
codeunit 60112 "DXR MCC RBPD Migr CashRcptExt"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateCashReceiptExt().
    Permissions = tabledata "DXR-IB Cash Receipt Ext" = R,
                  tabledata "DXR_Cash Receipt Ext" = RIM;

    // Fixed 2026-08-27: the loop had no Commit at all, so a whole-table restore ran as ONE
    // unbounded transaction. Bounded to 500 INSERTED rows; safe because every insert is already
    // guarded by "if not NewRec.Get(...)", so a re-run after a partial commit skips what exists.
    trigger OnRun()
    var
        OldRec: Record "DXR-IB Cash Receipt Ext";
        NewRec: Record "DXR_Cash Receipt Ext";
        RowsSinceCommit: Integer;
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Document No.") then begin
                    NewRec.Init();
                    NewRec."Document No." := OldRec."Document No.";
                    NewRec."IB No. Authorizacion DXR-IB" := OldRec."IB No. Authorizacion DXR-IB";
                    NewRec."IB ISRecaudo DXR-IB" := OldRec."IB ISRecaudo DXR-IB";
                    NewRec."Posting Date" := OldRec."Posting Date";
                    NewRec."Account No." := OldRec."Account No.";
                    NewRec.Amount := OldRec.Amount;
                    NewRec."External Document No." := OldRec."External Document No.";
                    NewRec."Currency Code" := OldRec."Currency Code";
                    NewRec.Insert(true);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
            until OldRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;
}

#endif
