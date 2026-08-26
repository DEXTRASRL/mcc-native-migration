// codeunit 60076 "DXR MCC SD Migr GenJnlLine"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopyGenJournalLineSpecialDispatch() (field 59000->54747 on
//     // its own "DXR_Gen. Journal Line Ext" table extension).
//     Permissions = tabledata "Gen. Journal Line" = RM;

//     trigger OnRun()
//     var
//         GenJnlLine: Record "Gen. Journal Line";
//     begin
//         if GenJnlLine.FindSet(true) then
//             repeat
//                 GenJnlLine."Special Dispatch_DXR" := GenJnlLine."Special Dispatch DXR";
//                 GenJnlLine.Modify(false);
//             until GenJnlLine.Next() = 0;
//     end;
// }
