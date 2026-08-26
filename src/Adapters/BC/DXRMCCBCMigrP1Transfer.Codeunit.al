// #if not ESCUDEA and not BCDX
// codeunit 60090 "DXR MCC BC Migr P1 Transfer"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
//     // CopyTransferControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
//     Permissions = tabledata "DXR Transfer Controls Setup" = R,
//                   tabledata "DXR_Transfer Controls Setup" = RIM;

//     trigger OnRun()
//     var
//         OldSetup: Record "DXR Transfer Controls Setup";
//         NewSetup: Record "DXR_Transfer Controls Setup";
//     begin
//         if not OldSetup.Get('') then
//             exit;
//         if NewSetup.Get('') then
//             exit;
//         NewSetup.Init();
//         NewSetup.Code := OldSetup.Code;
//         NewSetup.Active := OldSetup.Active;
//         NewSetup."Change Expected Date" := OldSetup."Change Expected Date";
//         NewSetup."Skip Zero Qty to Ship Lines" := OldSetup."Skip Zero Qty to Ship Lines";
//         NewSetup.Insert(false);
//     end;
// }

// #endif
