// #if not ESCUDEA and not BCDX
// codeunit 60089 "DXR MCC BC Migr P1 Vendor"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
//     // CopyVendorControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
//     Permissions = tabledata "DXR Vendor Controls Setup" = R,
//                   tabledata "DXR_Vendor Controls Setup" = RIM;
// 
//     trigger OnRun()
//     var
//         OldSetup: Record "DXR Vendor Controls Setup";
//         NewSetup: Record "DXR_Vendor Controls Setup";
//     begin
//         if not OldSetup.Get('') then
//             exit;
//         if NewSetup.Get('') then
//             exit;
//         NewSetup.Init();
//         NewSetup.Code := OldSetup.Code;
//         NewSetup.Active := OldSetup.Active;
//         NewSetup."Mandatory Currency Code" := OldSetup."Mandatory Currency Code";
//         NewSetup.Insert(false);
//     end;
// }
// 
// #endif
// 
