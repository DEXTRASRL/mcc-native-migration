// codeunit 60096 "DXR MCC BC Migr P2 Transfer"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
//     // CopyTransferControlsSetup() - see "DXR MCC BC Migr P2 Warehouse" for the full rationale.
//     Permissions = tabledata "DXR_Transfer Ctrl Setup Old2" = R,
//                   tabledata "DXR_Transfer Controls Setup" = RIM;

//     trigger OnRun()
//     var
//         OldSetup: Record "DXR_Transfer Ctrl Setup Old2";
//         NewSetup: Record "DXR_Transfer Controls Setup";
//         NewSetupExists: Boolean;
//     begin
//         if not OldSetup.Get('') then
//             exit;
//         if IsOldSetupRowBlank(OldSetup) then
//             exit;

//         NewSetupExists := NewSetup.Get('');
//         if not NewSetupExists then
//             NewSetup.Init();

//         NewSetup."Code" := OldSetup."Code";
//         NewSetup.Active := OldSetup.Active;
//         NewSetup."Change Expected Date" := OldSetup."Change Expected Date";
//         NewSetup."Skip Zero Qty to Ship Lines" := OldSetup."Skip Zero Qty to Ship Lines";

//         if NewSetupExists then
//             NewSetup.Modify(false)
//         else
//             NewSetup.Insert(false);
//     end;

//     local procedure IsOldSetupRowBlank(var OldSetup: Record "DXR_Transfer Ctrl Setup Old2"): Boolean
//     begin
//         exit(
//             (not OldSetup.Active) and
//             (not OldSetup."Change Expected Date") and
//             (not OldSetup."Skip Zero Qty to Ship Lines"));
//     end;
// }
