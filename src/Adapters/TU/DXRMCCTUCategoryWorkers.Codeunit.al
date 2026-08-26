// codeunit 60234 "DXR MCC TU Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC TU Migr Dispatcher";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-TU-SETUP-20260825.');
//     end;
// }

// codeunit 60235 "DXR MCC TU Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC TU Migr Dispatcher";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-TU-MA-20260825.');
//     end;
// }

// codeunit 60430 "DXR MCC TU Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC TU Migr Dispatcher";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-TU-ACCOUNTING-20260825.');
//     end;
// }
