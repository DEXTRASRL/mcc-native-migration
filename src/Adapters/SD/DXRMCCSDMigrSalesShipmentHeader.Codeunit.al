// #if not ESCUDEA and not BCDX
// codeunit 60074 "DXR MCC SD Migr SalesShipHdr"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopySalesShipmentHeaderSpecialDispatch() (field
//     // 59000->54747 on its own "DXR_Sales Shipment Headr Ext" table extension).
//     Permissions = tabledata "Sales Shipment Header" = RM;
// 
//     trigger OnRun()
//     var
//         SalesShptHeader: Record "Sales Shipment Header";
//         RowsSinceCommit: Integer;
//     begin
//         if SalesShptHeader.FindSet(true) then
//             repeat
//                 if SalesShptHeader."Special Dispatch_DXR" <> SalesShptHeader."Special Dispatch DXR" then begin
//                     SalesShptHeader."Special Dispatch_DXR" := SalesShptHeader."Special Dispatch DXR";
//                     SalesShptHeader.Modify(false);
//                 end;
//                 RowsSinceCommit += 1;
//                 if RowsSinceCommit >= BatchSize() then begin
//                     Commit();
//                     RowsSinceCommit := 0;
//                 end;
//             until SalesShptHeader.Next() = 0;
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
