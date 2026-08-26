// codeunit 60175 "DXR MCC LSLOC Other Fields"
// {
//     trigger OnRun()
//     var
//         Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-OTHERFIELDS-20260825.') then
//             exit;
//         Worker.RunOtherFields();
//         UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-OTHERFIELDS-20260825.');
//     end;
// }
