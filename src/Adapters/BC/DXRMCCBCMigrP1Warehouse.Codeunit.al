// #if not ESCUDEA and not BCDX
// codeunit 60086 "DXR MCC BC Migr P1 Warehouse"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
//     // CopyWarehouseControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
//     Permissions = tabledata "DXR Warehouse Controls Setup" = R,
//                   tabledata "DXR_Warehouse Controls Setup" = RIM;
// 
//     trigger OnRun()
//     var
//         OldSetup: Record "DXR Warehouse Controls Setup";
//         NewSetup: Record "DXR_Warehouse Controls Setup";
//     begin
//         if not OldSetup.Get('') then
//             exit;
//         if NewSetup.Get('') then
//             exit;
//         NewSetup.Init();
//         NewSetup.Code := OldSetup.Code;
//         NewSetup.Active := OldSetup.Active;
//         NewSetup."WHS. Receipt Posting Date" := OldSetup."WHS. Receipt Posting Date";
//         NewSetup."WHS. Shipment Posting Date" := OldSetup."WHS. Shipment Posting Date";
//         NewSetup."Validate Transfer Reopen" := OldSetup."Validate Transfer Reopen";
//         NewSetup."Show Vendor in Shipment" := OldSetup."Show Vendor in Shipment";
//         NewSetup."Show Customer in Receipt" := OldSetup."Show Customer in Receipt";
//         NewSetup."Show Receipt Detail" := OldSetup."Show Receipt Detail";
//         NewSetup."Show Shipment Detail" := OldSetup."Show Shipment Detail";
//         NewSetup."Show Customer in Shipment" := OldSetup."Show Customer in Shipment";
//         NewSetup."Show Vendor in Receipt" := OldSetup."Show Vendor in Receipt";
//         NewSetup."Show Customer in Ship List" := OldSetup."Show Customer in Ship List";
//         NewSetup."Show Vendor in Ship List" := OldSetup."Show Vendor in Ship List";
//         NewSetup."Show Customer in Rcpt List" := OldSetup."Show Customer in Rcpt List";
//         NewSetup."Show Vendor in Rcpt List" := OldSetup."Show Vendor in Rcpt List";
//         NewSetup."Show Ship Factbox" := OldSetup."Show Ship Factbox";
//         NewSetup."Show Rcpt Factbox" := OldSetup."Show Rcpt Factbox";
//         NewSetup."Show Receipt Totals" := OldSetup."Show Receipt Totals";
//         NewSetup."Show Shipment Totals" := OldSetup."Show Shipment Totals";
//         NewSetup.Insert(false);
//     end;
// }
// 
// #endif
// 
