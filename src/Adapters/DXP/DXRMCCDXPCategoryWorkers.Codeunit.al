// codeunit 60200 "DXR MCC DXP P1 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P1-SETUP-20260825.');
//     end;
// }

// codeunit 60201 "DXR MCC DXP P1 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P1-MA-20260825.');
//     end;
// }

// codeunit 60202 "DXR MCC DXP P1 Historic"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunHistoric();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P1-HIST-20260825.');
//     end;
// }

// codeunit 60203 "DXR MCC DXP P2 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase2";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P2-SETUP-20260825.');
//     end;
// }

// codeunit 60204 "DXR MCC DXP P2 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase2";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P2-MA-20260825.');
//     end;
// }

// codeunit 60205 "DXR MCC DXP P3 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase3";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P3-SETUP-20260825.');
//     end;
// }

// codeunit 60206 "DXR MCC DXP P3 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase3";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P3-MA-20260825.');
//     end;
// }

// codeunit 60207 "DXR MCC DXP P3 Historic"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase3";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunHistoric();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P3-HIST-20260825.');
//     end;
// }

// codeunit 60208 "DXR MCC DXP P4 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase4";
//         FinalWorker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         FinalWorker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P4-SETUP-20260825.');
//     end;
// }

// codeunit 60209 "DXR MCC DXP P4 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase4";
//         FinalWorker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         FinalWorker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P4-MA-20260825.');
//     end;
// }

// codeunit 60210 "DXR MCC DXP P4 Historic"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase4";
//         FinalWorker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunHistoric();
//         FinalWorker.RunHistoric();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P4-HIST-20260825.');
//     end;
// }

// codeunit 60211 "DXR MCC DXP P5 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase5";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P5-SETUP-20260825.');
//     end;
// }

// codeunit 60212 "DXR MCC DXP P5 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase5";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P5-MA-20260825.');
//     end;
// }

// codeunit 60213 "DXR MCC DXP P5 Historic"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase5";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunHistoric();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P5-HIST-20260825.');
//     end;
// }

// codeunit 60214 "DXR MCC DXP P6 Setup"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase6";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunSetup();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P6-SETUP-20260825.');
//     end;
// }

// codeunit 60215 "DXR MCC DXP P6 Master"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase6";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunMaster();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;

//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P6-MA-20260825.');
//     end;
// }

// codeunit 60420 "DXR MCC DXP P1 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P1-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60421 "DXR MCC DXP P2 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase2";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P2-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60422 "DXR MCC DXP P3 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase3";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P3-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60423 "DXR MCC DXP P4 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase4";
//         FinalWorker: Codeunit "DXR MCC DXP Migr Phase1";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         FinalWorker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P4-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60424 "DXR MCC DXP P5 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase5";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P5-ACCOUNTING-20260825.');
//     end;
// }

// codeunit 60425 "DXR MCC DXP P6 Accounting"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC DXP Migr Phase6";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(Tag()) then
//             exit;
//         Worker.RunAccounting();
//         UpgradeTag.SetUpgradeTag(Tag());
//     end;
//     local procedure Tag(): Code[250]
//     begin
//         exit('DXR-MCC-DXP-P6-ACCOUNTING-20260825.');
//     end;
// }
