#if not ESCUDEA and not BCDX
codeunit 60129 "DXR MCC DESLS Migr Worker"
{
    // Native local migration - ported verbatim from Despacho LS's own "DXR_Desp LS Migr Worker"
    // (codeunit 53963, Access = Internal): permission-set assignment + its own 2 MigrateTableNN()
    // legacy-table restores. Does NOT include the sibling's own Phase 1 logic - see
    // "DXR MCC DESLS Migr Phase1" for that (kept as its own codeunit since, unlike Despacho Base,
    // this sibling has no Phase2-before-Phase1 ordering constraint to preserve).
    Permissions =
        tabledata User = R,
        tabledata "Access Control" = RIM,
        tabledata "DXR-DE Document Generic" = RM,
        tabledata "DXR_Document Generic" = RIMD,
        tabledata "DXR_Desp LS MigrStat (Legacy)" = RM,
        tabledata "DXR_Despacho LS Migr Status" = RIMD;

    trigger OnRun()
    begin
        RunSetup();
        RunHistoric();
        RunOther();
    end;

    procedure RunSetup()
    begin
        AssignPermissionSetsToAllUsers();
    end;

    procedure RunHistoric()
    begin
        MigrateTable02();
    end;

    procedure RunOther()
    begin
        MigrateTable01();
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserRec: Record User;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-PermSetRepair-28.3-20260820') then
            exit;

        // Hardcoded Despacho LS's real app ID (from its own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        if UserRec.FindSet() then
            repeat
                AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_Despacho LS', DESLSAppId());
            until UserRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-PermSetRepair-28.3-20260820');
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

    local procedure DESLSAppId(): Guid
    begin
        exit('adb067e6-0e65-4ab0-8d61-160e7df7763f');
    end;

    // Table 1: old id 50870 "DXR-DE Document Generic" -> new "DXR_Document Generic"
    local procedure MigrateTable01()
    var
        OldRec: Record "DXR-DE Document Generic";
        NewRec: Record "DXR_Document Generic";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DESPACHOLS-TABLEMIGR-01-50870-28.3') then
            exit;

        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Entry No.") then begin
                    NewRec.Init();
                    NewRec."Entry No." := OldRec."Entry No.";
                    NewRec."Doc. Date" := OldRec."Doc. Date";
                    NewRec."Doc. Time" := OldRec."Doc. Time";
                    NewRec."Reqd. Date" := OldRec."Reqd. Date";
                    NewRec."Ship to Name" := OldRec."Ship to Name";
                    NewRec."Ship to Address" := OldRec."Ship to Address";
                    NewRec."Ship to Address 2" := OldRec."Ship to Address 2";
                    NewRec."Address Ship Ref" := OldRec."Address Ship Ref";
                    NewRec."Ship to Post Code" := OldRec."Ship to Post Code";
                    NewRec."Shipment Method Code" := OldRec."Shipment Method Code";
                    NewRec."Store No." := OldRec."Store No.";
                    NewRec."Location" := OldRec."Location";
                    NewRec."Document Reference" := OldRec."Document Reference";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DESPACHOLS-TABLEMIGR-01-50870-28.3');
    end;

    // Table 2: old id 50871 "DXR_Desp LS MigrStat (Legacy)" -> new "DXR_Despacho LS Migr Status"
    local procedure MigrateTable02()
    var
        OldRec: Record "DXR_Desp LS MigrStat (Legacy)";
        NewRec: Record "DXR_Despacho LS Migr Status";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DESPACHOLS-TABLEMIGR-02-50871-28.3') then
            exit;

        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Company Name", OldRec."Phase") then begin
                    NewRec.Init();
                    NewRec."Company Name" := OldRec."Company Name";
                    NewRec."Phase" := OldRec."Phase";
                    NewRec."Version" := OldRec."Version";
                    NewRec."Progress" := OldRec."Progress";
                    NewRec."Result" := OldRec."Result";
                    NewRec."Error Message" := OldRec."Error Message";
                    NewRec."Attempts" := OldRec."Attempts";
                    NewRec."Scheduled At" := OldRec."Scheduled At";
                    NewRec."Started At" := OldRec."Started At";
                    NewRec."Finished At" := OldRec."Finished At";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DESPACHOLS-TABLEMIGR-02-50871-28.3');
    end;
}

#endif
