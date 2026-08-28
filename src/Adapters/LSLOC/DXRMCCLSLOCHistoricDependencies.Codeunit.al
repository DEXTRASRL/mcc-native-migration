// #if not ESCUDEA and not BCDX
// codeunit 60179 "DXR MCC LSLOC Hist Deps"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC LSLOC Migr DepFields";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-HISTDEPS-20260825.') then
//             exit;
//         Worker.RunHistoricDependencies();
//         UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-HISTDEPS-20260825.');
//     end;
// }
// 
// #endif
// 
