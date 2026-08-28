// #if not ESCUDEA and not BCDX
// codeunit 60442 "DXR MCC DESB Sales Price Bulk"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DESB Migr Worker";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-SALES-PRICE-BULK-20260825.') then
//             exit;
// 
//         Worker.RunSalesPriceView();
//         UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-SALES-PRICE-BULK-20260825.');
//     end;
// }
// 
// #endif
// 
