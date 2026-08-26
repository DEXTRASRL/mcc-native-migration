// #if not ESCUDEA and not BCDX
// codeunit 60431 "DXR MCC RBPD CLE Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr CustLedgEnt";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-CLE-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60432 "DXR MCC RBPD GJL Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr GenJnlLine";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-GJL-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60433 "DXR MCC RBPD Pay Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr PagosProv";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-PAY-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60434 "DXR MCC RBPD Ref Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr RefPagos";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-REF-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60435 "DXR MCC RBPD Docs Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr DocsPend";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-DOCS-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60436 "DXR MCC RBPD Cash Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC RBPD Migr CashRcptExt";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.Run();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-RBPD-CASH-ACCOUNTING-20260825.');
//     end;
// }

// #endif
