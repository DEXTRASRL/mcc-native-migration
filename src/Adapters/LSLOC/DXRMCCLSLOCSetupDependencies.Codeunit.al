// #if not ESCUDEA and not BCDX
// codeunit 60177 "DXR MCC LSLOC Setup Deps"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC LSLOC Migr DepFields";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-SETUPDEPS-20260825.') then
//             exit;
//         Worker.RunSetupDependencies();
//         UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-SETUPDEPS-20260825.');
//     end;
// }
// 
// #endif
// 
