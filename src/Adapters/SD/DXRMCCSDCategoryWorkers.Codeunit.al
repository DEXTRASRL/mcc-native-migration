// codeunit 60437 "DXR MCC SD Customer Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC SD Migr Customer";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-SD-CUSTOMER-MASTER-20260825.');
//     end;
// }

// codeunit 60438 "DXR MCC SD Sales Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC SD Migr SalesHeader";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-SD-SALES-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60439 "DXR MCC SD Whse Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC SD Migr WhseShipHdr";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-SD-WHSE-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60440 "DXR MCC SD GJL Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC SD Migr GenJnlLine";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-SD-GJL-ACCOUNTING-20260825.');
//     end;
// }
