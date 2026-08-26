/*
codeunit 60079 "DXR MCC SD Migr PermSetAssign"
{
    // Native local migration - ported from Special Dispatch's own
    // "DXR_SD_Migr_Phase_Dispatcher".AssignPermissionSetsToAllUsers(): assigns Special Dispatch's
    // own "DXR_DispatchControls" permission set to every user in the company who doesn't already
    // have it, via a direct Access Control upsert (same shape as every other DXR retroactive
    // permission-set-assignment phase in this portfolio).
    //
    // IMPORTANT correctness note: the original SD code got its own module/app ID via
    // NavApp.GetCurrentModuleInfo() - that call returns the ID of whichever extension's code is
    // CURRENTLY EXECUTING. Ported as-is, running inside MCC, it would return MCC's own app ID, not
    // Special Dispatch's - silently granting an Access Control row for the wrong app and never
    // actually unlocking "DXR_DispatchControls" for anyone. Special Dispatch's real app ID
    // (confirmed from its own app.json) is hardcoded below instead.
    Permissions = tabledata User = R,
                  tabledata "Access Control" = RIM;

    trigger OnRun()
    var
        UserRec: Record User;
        AccessControl: Record "Access Control";
        SpecialDispatchAppId: Guid;
    begin
        SpecialDispatchAppId := '18373840-6093-4765-8799-491f61accb2b';
        if not UserRec.FindSet() then
            exit;
        repeat
            AccessControl.SetRange("User Security ID", UserRec."User Security ID");
            AccessControl.SetRange("Role ID", 'DXR_DispatchControls');
            AccessControl.SetRange(Scope, AccessControl.Scope::System);
            AccessControl.SetRange("App ID", SpecialDispatchAppId);
            AccessControl.SetRange("Company Name", CompanyName());
            if AccessControl.IsEmpty() then begin
                AccessControl.Init();
                AccessControl."User Security ID" := UserRec."User Security ID";
                AccessControl."Role ID" := 'DXR_DispatchControls';
                AccessControl.Scope := AccessControl.Scope::System;
                AccessControl."App ID" := SpecialDispatchAppId;
                AccessControl."Company Name" := CompanyName();
                AccessControl.Insert(true);
            end;
        until UserRec.Next() = 0;
    end;
}

*/
