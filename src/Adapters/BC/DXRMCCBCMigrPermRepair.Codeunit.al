// codeunit 60104 "DXR MCC BC Migr PermRepair"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Perm Repair" -
//     // assigns Base Controls' own "DXR_BaseControls" permission set to every user who doesn't
//     // already have it, via a direct Access Control upsert. Same correctness fix as
//     // "DXR MCC SD Migr PermSetAssign": the original used NavApp.GetCurrentModuleInfo() to get
//     // its own app ID, which would resolve to MCC's ID (wrong) running here - Base Controls' real
//     // app ID (from its own app.json) is hardcoded instead.
//     Permissions = tabledata User = R,
//                   tabledata "Access Control" = RIM;

//     trigger OnRun()
//     var
//         UserRec: Record User;
//         AccessControl: Record "Access Control";
//         BaseControlsAppId: Guid;
//     begin
//         BaseControlsAppId := 'e8b1de99-1c7d-454d-b0bc-7cc1dc7b86ae';
//         if not UserRec.FindSet() then
//             exit;
//         repeat
//             AccessControl.SetRange("User Security ID", UserRec."User Security ID");
//             AccessControl.SetRange("Role ID", 'DXR_BaseControls');
//             AccessControl.SetRange(Scope, AccessControl.Scope::System);
//             AccessControl.SetRange("App ID", BaseControlsAppId);
//             AccessControl.SetRange("Company Name", CompanyName());
//             if AccessControl.IsEmpty() then begin
//                 AccessControl.Init();
//                 AccessControl."User Security ID" := UserRec."User Security ID";
//                 AccessControl."Role ID" := 'DXR_BaseControls';
//                 AccessControl.Scope := AccessControl.Scope::System;
//                 AccessControl."App ID" := BaseControlsAppId;
//                 AccessControl."Company Name" := CompanyName();
//                 AccessControl.Insert(true);
//             end;
//         until UserRec.Next() = 0;
//     end;
// }
