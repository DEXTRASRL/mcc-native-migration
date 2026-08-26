// #if not ESCUDEA and not BCDX
// codeunit 60074 "DXR MCC SD Migr SalesShipHdr"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopySalesShipmentHeaderSpecialDispatch() (field
//     // 59000->54747 on its own "DXR_Sales Shipment Headr Ext" table extension).
//     Permissions = tabledata "Sales Shipment Header" = RM;

//     trigger OnRun()
//     var
//         SalesShptHeader: Record "Sales Shipment Header";
//     begin
//         if SalesShptHeader.FindSet(true) then
//             repeat
//                 SalesShptHeader."Special Dispatch_DXR" := SalesShptHeader."Special Dispatch DXR";
//                 SalesShptHeader.Modify(false);
//             until SalesShptHeader.Next() = 0;
//     end;
// }

// #endif
