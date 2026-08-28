// #if not ESCUDEA and not BCDX
// codeunit 60088 "DXR MCC BC Migr P1 Sales"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
//     // CopySalesControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
//     Permissions = tabledata "DXR Sales Controls Setup" = R,
//                   tabledata "DXR_Sales Controls Setup" = RIM;
// 
//     trigger OnRun()
//     var
//         OldSetup: Record "DXR Sales Controls Setup";
//         NewSetup: Record "DXR_Sales Controls Setup";
//     begin
//         if not OldSetup.Get('') then
//             exit;
//         if NewSetup.Get('') then
//             exit;
//         NewSetup.Init();
//         NewSetup.Code := OldSetup.Code;
//         NewSetup.Active := OldSetup.Active;
//         NewSetup."Sales Sell/Buy Mismatch" := OldSetup."Sales Sell/Buy Mismatch";
//         NewSetup."Sales Posting Date to workdate" := OldSetup."Sales Posting Date to workdate";
//         NewSetup."Sales No duplicates Items" := OldSetup."Sales No duplicates Items";
//         NewSetup."Sales Mandatory Order No." := OldSetup."Sales Mandatory Order No.";
//         NewSetup."Sales Mandatory Sh. Method" := OldSetup."Sales Mandatory Sh. Method";
//         NewSetup."Sales Block Overdue" := OldSetup."Sales Block Overdue";
//         NewSetup."Sales Block Overdue Date" := OldSetup."Sales Block Overdue Date";
//         NewSetup."Sales Mandatory Resp. Center" := OldSetup."Sales Mandatory Resp. Center";
//         NewSetup."Sales Mandatory LSC Store No" := OldSetup."Sales Mandatory LSC Store No";
//         NewSetup."Sales Allow VAT Amount" := OldSetup."Sales Allow VAT Amount";
//         NewSetup."Sales Mandatory Salesperson" := OldSetup."Sales Mandatory Salesperson";
//         NewSetup."Validate Docs. Approval" := OldSetup."Validate Docs. Approval";
//         NewSetup."Validate Docs. Release" := OldSetup."Validate Docs. Release";
//         NewSetup."Validate Sales Lines Quantity" := OldSetup."Validate Sales Lines Quantity";
//         NewSetup."Item Payment Terms" := OldSetup."Item Payment Terms";
//         NewSetup."Restrict Non Qty To Ship" := OldSetup."Restrict Non Qty To Ship";
//         NewSetup."Restrict Non Qty To Receive" := OldSetup."Restrict Non Qty To Receive";
//         NewSetup."Restrict Non Qty On Posted Doc" := OldSetup."Restrict Non Qty On Posted Doc";
//         NewSetup."Restrict Non Decimal Qty" := OldSetup."Restrict Non Decimal Qty";
//         NewSetup."Exempt group" := OldSetup."Exempt group";
//         NewSetup."Exempt Product group" := OldSetup."Exempt Product group";
//         NewSetup."Handle Shipment M. On Release" := OldSetup."Handle Shipment M. On Release";
//         NewSetup."Sales Mandatory Currency Code" := OldSetup."Sales Mandatory Currency Code";
//         NewSetup."Check Reg. Merc. Expiration" := OldSetup."Check Reg. Merc. Expiration";
//         NewSetup."Mandatory Return Reason" := OldSetup."Mandatory Return Reason";
//         NewSetup.Insert(false);
//     end;
// }
// 
// #endif
// 
