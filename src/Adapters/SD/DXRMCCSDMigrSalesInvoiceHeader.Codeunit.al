// #if not ESCUDEA and not BCDX
// codeunit 60073 "DXR MCC SD Migr SalesInvHdr"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopySalesInvoiceHeaderSpecialDispatch() (field
//     // 59000->54747 on its own "DXR_Sales Invoice Header Ext" table extension).
//     Permissions = tabledata "Sales Invoice Header" = RM;
// 
//     trigger OnRun()
//     var
//         SalesInvHeader: Record "Sales Invoice Header";
//         RowsSinceCommit: Integer;
//     begin
//         if SalesInvHeader.FindSet(true) then
//             repeat
//                 if SalesInvHeader."Special Dispatch_DXR" <> SalesInvHeader."Special Dispatch DXR" then begin
//                     SalesInvHeader."Special Dispatch_DXR" := SalesInvHeader."Special Dispatch DXR";
//                     SalesInvHeader.Modify(false);
//                 end;
//                 RowsSinceCommit += 1;
//                 if RowsSinceCommit >= BatchSize() then begin
//                     Commit();
//                     RowsSinceCommit := 0;
//                 end;
//             until SalesInvHeader.Next() = 0;
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
