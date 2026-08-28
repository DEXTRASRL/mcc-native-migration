// #if not ESCUDEA and not BCDX
// codeunit 60076 "DXR MCC SD Migr GenJnlLine"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopyGenJournalLineSpecialDispatch() (field 59000->54747 on
//     // its own "DXR_Gen. Journal Line Ext" table extension).
//     Permissions = tabledata "Gen. Journal Line" = RM;
// 
//     trigger OnRun()
//     var
//         GenJnlLine: Record "Gen. Journal Line";
//         RowsSinceCommit: Integer;
//     begin
//         if GenJnlLine.FindSet(true) then
//             repeat
//                 if GenJnlLine."Special Dispatch_DXR" <> GenJnlLine."Special Dispatch DXR" then begin
//                     GenJnlLine."Special Dispatch_DXR" := GenJnlLine."Special Dispatch DXR";
//                     GenJnlLine.Modify(false);
//                 end;
//                 RowsSinceCommit += 1;
//                 if RowsSinceCommit >= BatchSize() then begin
//                     Commit();
//                     RowsSinceCommit := 0;
//                 end;
//             until GenJnlLine.Next() = 0;
//     end;
// 
//     local procedure BatchSize(): Integer
//     begin
//         exit(500);
//     end;
// }
// 
// #endif
// 
