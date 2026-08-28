// #if not ESCUDEA and not BCDX
// codeunit 60176 "DXR MCC LSLOC Hist Tables"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-HISTTABLES-20260825.') then
//             exit;
//         Worker.RunHistoricTables();
//         UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-HISTTABLES-20260825.');
//     end;
// }
// 
// #endif
// 
