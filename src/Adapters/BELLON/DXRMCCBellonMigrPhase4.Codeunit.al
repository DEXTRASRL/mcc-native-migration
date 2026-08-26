// codeunit 60148 "DXR MCC Bellon Migr Phase4"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 4 PermSet" (56121) -> "Bellon Upgrade Process".EnsurePermissionSetsAssignedIfNeeded()
//     // (internal procedure call on a typed Subtype = Upgrade codeunit variable - never .Run()/
//     // OnRun, same pre-existing pattern the deleted delegation adapter itself already documented
//     // as safe).
//     Permissions =
//         tabledata User = R,
//         tabledata "Access Control" = RIM;

//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('BELLON-MIGR-PERMSET-REPAIR-20260820') then
//             exit;

//         AssignPermissionSetsToAllUsers();

//         UpgradeTag.SetUpgradeTag('BELLON-MIGR-PERMSET-REPAIR-20260820');
//     end;

//     local procedure AssignPermissionSetsToAllUsers()
//     var
//         UserRec: Record User;
//     begin
//         // Hardcoded Bellon Customization's real app ID (from its own app.json) instead of
//         // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
//         // logic runs inside MCC.
//         if not UserRec.FindSet() then
//             exit;
//         repeat
//             AssignPermissionSetToUser(UserRec."User Security ID", PermissionSetCode(), BellonAppId());
//         until UserRec.Next() = 0;
//     end;

//     // The only Assignable = true permission set this extension ships - see
//     // src/BellonPermissions.permissionset.al ("DXR_Bellon Perms", 52790, tabledata * = RIDM).
//     local procedure PermissionSetCode(): Code[20]
//     begin
//         exit('DXR_Bellon Perms');
//     end;

//     local procedure AssignPermissionSetToUser(UserSecurityId: Guid; PermissionSetId: Code[20]; AppId: Guid)
//     var
//         AccessControl: Record "Access Control";
//     begin
//         AccessControl.SetRange("User Security ID", UserSecurityId);
//         AccessControl.SetRange("Role ID", PermissionSetId);
//         AccessControl.SetRange(Scope, AccessControl.Scope::System);
//         AccessControl.SetRange("App ID", AppId);
//         AccessControl.SetRange("Company Name", CompanyName());
//         if not AccessControl.IsEmpty() then
//             exit;

//         AccessControl.Init();
//         AccessControl."User Security ID" := UserSecurityId;
//         AccessControl."Role ID" := PermissionSetId;
//         AccessControl.Scope := AccessControl.Scope::System;
//         AccessControl."App ID" := AppId;
//         AccessControl."Company Name" := CompanyName();
//         AccessControl.Insert(true);
//     end;

//     local procedure BellonAppId(): Guid
//     begin
//         exit('a9734a52-02bb-4e3d-8150-2f9ee4b50530');
//     end;
// }
