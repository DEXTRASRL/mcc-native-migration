// codeunit 60098 "DXR MCC BC Migr P2 StatusHist"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
//     // CopyMigrStatusHistory(): "DXR_BC Migr Status" is keyed by (Company Name, Phase No.), not a
//     // single '' row - real FindSet loop, insert-only-if-absent by that composite key.
//     Permissions = tabledata "DXR_BC Migr Status Old2" = R,
//                   tabledata "DXR_BC Migr Status" = RIM;

//     trigger OnRun()
//     var
//         OldStatus: Record "DXR_BC Migr Status Old2";
//         NewStatus: Record "DXR_BC Migr Status";
//     begin
//         if not OldStatus.FindSet(false) then
//             exit;
//         repeat
//             if not NewStatus.Get(OldStatus."Company Name", OldStatus."Phase No.") then begin
//                 NewStatus.Init();
//                 NewStatus."Company Name" := OldStatus."Company Name";
//                 NewStatus."Phase No." := OldStatus."Phase No.";
//                 NewStatus.Description := OldStatus.Description;
//                 NewStatus.Status := OldStatus.Status;
//                 NewStatus."Started At" := OldStatus."Started At";
//                 NewStatus."Completed At" := OldStatus."Completed At";
//                 NewStatus."Error Message" := OldStatus."Error Message";
//                 NewStatus.Attempts := OldStatus.Attempts;
//                 NewStatus.Insert(false);
//             end;
//         until OldStatus.Next() = 0;
//     end;
// }
