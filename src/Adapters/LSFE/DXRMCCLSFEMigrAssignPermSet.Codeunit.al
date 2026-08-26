#if not BCDX
codeunit 60144 "DXR MCC LSFE Migr PermSet"
{
    // Native local migration - ported verbatim from LS Facturacion Electronica's own
    // "DXR_LSFE Migr. Assign PermSet" (52589) -> "DXR_LSFE Upgrade".
    // EnsurePermissionSetsAssignedToAllUsersIfNeeded() (internal procedure call on a typed
    // Subtype = Upgrade codeunit variable - never .Run()/OnRun on it, same pre-existing pattern
    // the deleted delegation adapter itself already used and documented as safe).
    Permissions =
        tabledata User = R,
        tabledata "Access Control" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('LSEF-ASSIGN-PERMISSIONSETS-ALL-USERS-20260820') then
            exit;

        AssignPermissionSetsToAllUsers();

        UpgradeTag.SetUpgradeTag('LSEF-ASSIGN-PERMISSIONSETS-ALL-USERS-20260820');
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded LS Facturacion Electronica's real app ID (from its own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        if not UserRec.FindSet() then
            exit;
        repeat
            AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_LSFE Permissions', LSFEAppId());
        until UserRec.Next() = 0;
    end;

    local procedure AssignPermissionSetToUser(UserSecurityId: Guid; PermissionSetId: Code[20]; AppId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", PermissionSetId);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetRange("App ID", AppId);
        AccessControl.SetRange("Company Name", CompanyName());
        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := PermissionSetId;
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := AppId;
        AccessControl."Company Name" := CompanyName();
        AccessControl.Insert(true);
    end;

    local procedure LSFEAppId(): Guid
    begin
        exit('4e2e9532-7e97-4f5e-af6e-1b5f2e51b9e2');
    end;
}

#endif
