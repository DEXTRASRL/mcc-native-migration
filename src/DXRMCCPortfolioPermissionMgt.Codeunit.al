codeunit 60441 "DXR MCC Portfolio Perm. Mgt."
{
    Permissions =
        tabledata "DXR MCC Extension" = R,
        tabledata "DXR MCC Run Log" = RI,
        tabledata User = R,
        tabledata "Metadata Permission Set" = R,
        tabledata "Access Control" = RIM;

    procedure AssignAllPortfolioPermissionSets(RunRequestEntryNo: Integer; var AssignedCount: Integer; var ExistingCount: Integer; var PermissionSetCount: Integer; var UserCount: Integer)
    var
        Extension: Record "DXR MCC Extension";
        UserRec: Record User;
        MetadataPermissionSet: Record "Metadata Permission Set";
        SeenPermissionSets: Dictionary of [Text, Boolean];
    begin
        AssignedCount := 0;
        ExistingCount := 0;
        PermissionSetCount := 0;
        UserCount := UserRec.Count();

        if Extension.FindSet(false) then
            repeat
                AssignAppPermissionSets(
                    Extension."App ID", UserRec, MetadataPermissionSet, SeenPermissionSets,
                    AssignedCount, ExistingCount, PermissionSetCount);
            until Extension.Next() = 0;

        LogResult(RunRequestEntryNo, AssignedCount, ExistingCount, PermissionSetCount, UserCount);
        Commit();
    end;

    local procedure AssignAppPermissionSets(AppId: Guid; var UserRec: Record User; var MetadataPermissionSet: Record "Metadata Permission Set"; var SeenPermissionSets: Dictionary of [Text, Boolean]; var AssignedCount: Integer; var ExistingCount: Integer; var PermissionSetCount: Integer)
    var
        PermissionSetKey: Text;
    begin
        if IsNullGuid(AppId) then
            exit;

        MetadataPermissionSet.Reset();
        MetadataPermissionSet.SetRange("App ID", AppId);
        MetadataPermissionSet.SetRange(Assignable, true);
        if not MetadataPermissionSet.FindSet(false) then
            exit;

        repeat
            PermissionSetKey := LowerCase(Format(AppId)) + '|' + MetadataPermissionSet."Role ID";
            if not SeenPermissionSets.ContainsKey(PermissionSetKey) then begin
                SeenPermissionSets.Add(PermissionSetKey, true);
                PermissionSetCount += 1;
                AssignPermissionSetToUsers(
                    UserRec, AppId, CopyStr(MetadataPermissionSet."Role ID", 1, 20),
                    AssignedCount, ExistingCount);
            end;
        until MetadataPermissionSet.Next() = 0;
    end;

    local procedure AssignPermissionSetToUsers(var UserRec: Record User; AppId: Guid; RoleId: Code[20]; var AssignedCount: Integer; var ExistingCount: Integer)
    begin
        UserRec.Reset();
        if not UserRec.FindSet(false) then
            exit;

        repeat
            if EnsureAssignment(UserRec."User Security ID", AppId, RoleId) then
                AssignedCount += 1
            else
                ExistingCount += 1;
        until UserRec.Next() = 0;
    end;

    local procedure EnsureAssignment(UserSecurityId: Guid; AppId: Guid; RoleId: Code[20]): Boolean
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", RoleId);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetRange("App ID", AppId);
        AccessControl.SetRange("Company Name", CompanyName());
        if not AccessControl.IsEmpty() then
            exit(false);

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := RoleId;
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := AppId;
        AccessControl."Company Name" := CompanyName();
        exit(AccessControl.Insert(true));
    end;

    local procedure LogResult(RunRequestEntryNo: Integer; AssignedCount: Integer; ExistingCount: Integer; PermissionSetCount: Integer; UserCount: Integer)
    var
        RunLog: Record "DXR MCC Run Log";
    begin
        RunLog.Init();
        RunLog."Concept Entry No." := 0;
        RunLog."Extension Code" := 'MCC';
        RunLog."Phase Code" := 'PERMISSIONS';
        RunLog."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(RunLog."Company Name"));
        RunLog."Run DateTime" := CurrentDateTime();
        RunLog.Status := RunLog.Status::Completed;
        RunLog."Migrated Record Count" := AssignedCount;
        RunLog."Run Request Entry No." := RunRequestEntryNo;
        RunLog."Concept Description" := CopyStr(
            StrSubstNo('Portfolio permission sets assigned: %1 new, %2 existing, %3 permission sets, %4 users.', AssignedCount, ExistingCount, PermissionSetCount, UserCount),
            1, MaxStrLen(RunLog."Concept Description"));
        RunLog."User ID" := CopyStr(UserId(), 1, MaxStrLen(RunLog."User ID"));
        RunLog.Insert(true);
    end;
}
