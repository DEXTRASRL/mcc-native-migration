// codeunit 60112 "DXR MCC RBPD Migr CashRcptExt"
// {
//     // Native local migration - ported from Recaudo BPD's own
//     // "DXR_Recaudo Migr Phase1 Migr".MigrateCashReceiptExt().
//     Permissions = tabledata "DXR-IB Cash Receipt Ext" = R,
//                   tabledata "DXR_Cash Receipt Ext" = RIM;

//     trigger OnRun()
//     var
//         OldRec: Record "DXR-IB Cash Receipt Ext";
//         NewRec: Record "DXR_Cash Receipt Ext";
//     begin
//         if OldRec.FindSet() then
//             repeat
//                 if not NewRec.Get(OldRec."Document No.") then begin
//                     NewRec.Init();
//                     NewRec."Document No." := OldRec."Document No.";
//                     NewRec."IB No. Authorizacion DXR-IB" := OldRec."IB No. Authorizacion DXR-IB";
//                     NewRec."IB ISRecaudo DXR-IB" := OldRec."IB ISRecaudo DXR-IB";
//                     NewRec."Posting Date" := OldRec."Posting Date";
//                     NewRec."Account No." := OldRec."Account No.";
//                     NewRec.Amount := OldRec.Amount;
//                     NewRec."External Document No." := OldRec."External Document No.";
//                     NewRec."Currency Code" := OldRec."Currency Code";
//                     NewRec.Insert(true);
//                 end;
//             until OldRec.Next() = 0;
//     end;
// }
