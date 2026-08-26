// #if not ESCUDEA and not BCDX
// codeunit 60091 "DXR MCC BC Migr P1 Customer"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 1".
//     // CopyCustomerControlsSetup(): gen-1 legacy singleton restore, insert-only-if-absent.
//     Permissions = tabledata "DXR Customer Controls Setup" = R,
//                   tabledata "DXR_Customer Controls Setup" = RIM;

//     trigger OnRun()
//     var
//         OldSetup: Record "DXR Customer Controls Setup";
//         NewSetup: Record "DXR_Customer Controls Setup";
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

// #endif
