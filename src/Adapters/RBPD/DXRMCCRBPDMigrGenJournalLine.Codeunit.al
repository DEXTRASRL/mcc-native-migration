#if not ESCUDEA and not BCDX
codeunit 60106 "DXR MCC RBPD Migr GenJnlLine"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Worker".MigrateGenJournalLineFields() - copies "IB No.
    // Authorizacion"/"IB ISRecaudo" from the legacy tableextension fields to the active
    // "DXR-IB" fields. Two passes preserved verbatim: rows with a real authorization
    // number get both fields; rows with only ISRecaudo set (no authorization number) get
    // that field alone.
    Permissions = tabledata "Gen. Journal Line" = RM;

    trigger OnRun()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("IB No. Authorizacion_Old", '<>%1', '');
        GenJournalLine.SetLoadFields("Journal Template Name", "Journal Batch Name", "Line No.",
            "IB No. Authorizacion_Old", "IB ISRecaudo_Old", "IB No. Authorizacion DXR-IB", "IB ISRecaudo DXR-IB");
        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine."IB No. Authorizacion DXR-IB" := GenJournalLine."IB No. Authorizacion_Old";
                GenJournalLine."IB ISRecaudo DXR-IB" := GenJournalLine."IB ISRecaudo_Old";
                GenJournalLine.Modify(false);
            until GenJournalLine.Next() = 0;

        GenJournalLine.Reset();
        GenJournalLine.SetRange("IB No. Authorizacion_Old", '');
        GenJournalLine.SetFilter("IB ISRecaudo_Old", '%1', true);
        GenJournalLine.SetLoadFields("Journal Template Name", "Journal Batch Name", "Line No.",
            "IB ISRecaudo_Old", "IB ISRecaudo DXR-IB");
        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine."IB ISRecaudo DXR-IB" := GenJournalLine."IB ISRecaudo_Old";
                GenJournalLine.Modify(false);
            until GenJournalLine.Next() = 0;
    end;
}

#endif
