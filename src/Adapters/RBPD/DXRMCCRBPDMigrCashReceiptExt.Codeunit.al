codeunit 60112 "DXR MCC RBPD Migr CashRcptExt"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateCashReceiptExt().
    Permissions = tabledata "DXR-IB Cash Receipt Ext" = R,
                  tabledata "DXR_Cash Receipt Ext" = RIM;

    trigger OnRun()
    var
        OldRec: Record "DXR-IB Cash Receipt Ext";
        NewRec: Record "DXR_Cash Receipt Ext";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Document No.") then begin
                    NewRec.Init();
                    NewRec.TransferFields(OldRec, true);
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
