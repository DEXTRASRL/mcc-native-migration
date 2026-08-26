/*
codeunit 60105 "DXR MCC RBPD Migr CustLedgEnt"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Worker".MigrateCustLedgerEntryField() - copies "IB No. Authorizacion"
    // from the legacy tableextension field to the active "DXR-IB" field, only where the
    // legacy field has a real value.
    Permissions = tabledata "Cust. Ledger Entry" = RM;

    trigger OnRun()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetFilter("IB No. Authorizacion_Old", '<>%1', '');
        CustLedgerEntry.SetLoadFields("Entry No.", "IB No. Authorizacion_Old", "IB No. Authorizacion DXR-IB");
        if CustLedgerEntry.FindSet(true) then
            repeat
                CustLedgerEntry."IB No. Authorizacion DXR-IB" := CustLedgerEntry."IB No. Authorizacion_Old";
                CustLedgerEntry.Modify(false);
            until CustLedgerEntry.Next() = 0;
    end;
}

*/
