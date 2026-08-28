// #if not ESCUDEA and not BCDX
// codeunit 60072 "DXR MCC SD Migr SalesHeader"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopySalesHeaderSpecialDispatch() (field 59000->54747 on
//     // its own "DXR_Sales Header Ext" table extension).
//     Permissions = tabledata "Sales Header" = RM;
// 
//     trigger OnRun()
//     var
//         SalesHeader: Record "Sales Header";
//         RowsSinceCommit: Integer;
//     begin
//         if SalesHeader.FindSet(true) then
//             repeat
//                 if SalesHeader."Special Dispatch_DXR" <> SalesHeader."Special Dispatch DXR" then begin
//                     SalesHeader."Special Dispatch_DXR" := SalesHeader."Special Dispatch DXR";
//                     SalesHeader.Modify(false);
//                 end;
//                 RowsSinceCommit += 1;
//                 if RowsSinceCommit >= BatchSize() then begin
//                     Commit();
//                     RowsSinceCommit := 0;
//                 end;
//             until SalesHeader.Next() = 0;
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
