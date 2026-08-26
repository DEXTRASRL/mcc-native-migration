#if not ESCUDEA and not BCDX
codeunit 60134 "DXR MCC RC Migr Phase4"
{
    // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase4 PermSet
    // Repair" (56504/56505, Access = Internal) - see "DXR MCC RC Migr Phase1" for the outer-tag
    // rationale.
    Permissions =
        tabledata User = R,
        tabledata "Access Control" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PERMSET-ASSIGN-REPAIR-20260820') then
            exit;

        AssignPermissionSetsToAllUsers();

        UpgradeTag.SetUpgradeTag('DXR-RC-PERMSET-ASSIGN-REPAIR-20260820');
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded Retail Controls' real app ID (from its own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        if not UserRec.FindSet() then
            exit;
        repeat
            AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_Retail Controls', RCAppId());
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

    local procedure RCAppId(): Guid
    begin
        exit('6e53178d-a25a-4432-9b46-977d98c087fc');
    end;
}

#endif
