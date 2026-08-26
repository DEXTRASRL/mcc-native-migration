// codeunit 60132 "DXR MCC RC Migr Phase2"
// {
//     // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase2
//     // Documents" (54744/54745, Access = Internal) - see "DXR MCC RC Migr Phase1" for the outer-tag
//     // rationale. Batched with a periodic Commit (500 rows) since these are potentially
//     // high-volume document tables; no per-record resume cursor, same limitation as the source.
//     Permissions =
//         tabledata "Sales Header" = RIM,
//         tabledata "Purchase Header" = RIM,
//         tabledata "Sales Invoice Header" = RIM;

//     var
//         BatchSize: Integer;

//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE2-DOCUMENTS-RETROACTIVE-20260817') then
//             exit;

//         BatchSize := 500;
//         CopySalesHeaderField();
//         CopyPurchaseHeaderField();
//         CopySalesInvoiceHeaderField();

//         UpgradeTag.SetUpgradeTag('DXR-RC-PHASE2-DOCUMENTS-RETROACTIVE-20260817');
//     end;

//     local procedure CopySalesHeaderField()
//     var
//         SalesHeader: Record "Sales Header";
//         Processed: Integer;
//     begin
//         if not SalesHeader.FindSet(true) then
//             exit;
//         repeat
//             SalesHeader."POS Special Order_DXR" := SalesHeader."POS Special Order";
//             SalesHeader.Modify();
//             Processed += 1;
//             if Processed mod BatchSize = 0 then
//                 Commit();
//         until SalesHeader.Next() = 0;
//     end;

//     local procedure CopyPurchaseHeaderField()
//     var
//         PurchHeader: Record "Purchase Header";
//         Processed: Integer;
//     begin
//         if not PurchHeader.FindSet(true) then
//             exit;
//         repeat
//             PurchHeader.Toggle_DXR := PurchHeader.Toggle;
//             PurchHeader.Modify();
//             Processed += 1;
//             if Processed mod BatchSize = 0 then
//                 Commit();
//         until PurchHeader.Next() = 0;
//     end;

//     local procedure CopySalesInvoiceHeaderField()
//     var
//         SalesInvHeader: Record "Sales Invoice Header";
//         Processed: Integer;
//     begin
//         if not SalesInvHeader.FindSet(true) then
//             exit;
//         repeat
//             SalesInvHeader."POS Special Order_DXR" := SalesInvHeader."POS Special Order";
//             SalesInvHeader.Modify();
//             Processed += 1;
//             if Processed mod BatchSize = 0 then
//                 Commit();
//         until SalesInvHeader.Next() = 0;
//     end;
// }
