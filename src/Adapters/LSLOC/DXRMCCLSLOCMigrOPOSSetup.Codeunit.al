codeunit 60161 "DXR MCC LSLOC Migr OPOSSetup"
{
    // Native local migration - ported verbatim from LS Central DR Localization's own
    // "DXR_LS OPOS Print Setup Upgr." (54513, Access = Internal) -> Execute(). Fixes the
    // documented SOLUCION_NCF_UPGRADE.md silent-migration-failure incident (DXR_Gaps Setup ->
    // DXR_LS OPOS Print Setup field copy never actually ran).
    //
    // Also bundles the sibling's own Dispatcher (54506) EnsurePermissionSetsAssignedIfNeeded()
    // step, which has no dedicated LSLOC registry row of its own (unlike the OPOS/ToDXRLS/
    // DepFields phases, all tracked as LSLOC-OPOS/LSLOC-TOLOC/LSLOC-DEPFLD rows) but WAS executed
    // as a real side effect every time the old delegation adapter (60068, calling the whole
    // Dispatcher) ran. Folded into this codeunit - the smallest tracked concept, registry row
    // seq1 - rather than left as an orphan untracked codeunit, so it keeps running unconditionally
    // whenever LSLOC's registry-tracked migration runs, matching the old adapter's exact behavior.
    // "DXR_Gaps Setup" (52165) is Access = Internal in DR-Localization - accessed here purely via
    // RecordRef by numeric table ID, so it cannot be (and does not need to be) named below.
    Permissions =
        tabledata "DXR_LS OPOS Print Setup" = RIMD,
        tabledata User = R,
        tabledata "Access Control" = RIM;

    trigger OnRun()
    begin
        AssignPermissionSetsToAllUsersIfNeeded();
        MigrateOPOSSetupIfNeeded();
    end;

    local procedure AssignPermissionSetsToAllUsersIfNeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LS-PERMSET-ASSIGNMENT-20260820') then
            exit;

        AssignPermissionSetsToAllUsers();

        UpgradeTag.SetUpgradeTag('DXR-LS-PERMSET-ASSIGNMENT-20260820');
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded LS Central DR Localization's real app ID (from its own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        if not UserRec.FindSet() then
            exit;
        repeat
            AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_LS Migr. Task', LSLOCAppId());
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

    local procedure LSLOCAppId(): Guid
    begin
        exit('b18ab944-2133-4326-bcd7-a235e0a8bdef');
    end;

    local procedure MigrateOPOSSetupIfNeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('T20260112.0002-01-12-2026-PY') then
            exit;

        Execute();

        UpgradeTag.SetUpgradeTag('T20260112.0002-01-12-2026-PY');
    end;

    local procedure Execute()
    var
        GapsSetupRef: RecordRef;
        OPOSPrintSetup: Record "DXR_LS OPOS Print Setup";
    begin
        GapsSetupRef.Open(52165); // DXR_Gaps Setup
        if GapsSetupRef.FindFirst() then begin
            if not OPOSPrintSetup.Get() then begin
                OPOSPrintSetup.Init();
                OPOSPrintSetup.Insert();
            end;
            OPOSPrintSetup."Print NCF_DXR" := GapsSetupRef.Field(54500).Value();
            OPOSPrintSetup."Print Company Name_DXR" := GapsSetupRef.Field(54501).Value();
            OPOSPrintSetup."Print Employee and Trans_DXR" := GapsSetupRef.Field(54502).Value();
            OPOSPrintSetup."Print Cashier_DXR" := GapsSetupRef.Field(54503).Value();
            OPOSPrintSetup."Print Site Name_DXR" := GapsSetupRef.Field(54504).Value();
            OPOSPrintSetup."LineBreakInRNC_DXR" := GapsSetupRef.Field(54505).Value();
            OPOSPrintSetup."Print Transaction Time_DXR" := GapsSetupRef.Field(54506).Value();
            OPOSPrintSetup."LineBreakCustomerName_DXR" := GapsSetupRef.Field(54507).Value();
            OPOSPrintSetup."Print Qty Footer_DXR" := GapsSetupRef.Field(54508).Value();
            OPOSPrintSetup."Print Staff Sales Person_DXR" := GapsSetupRef.Field(54509).Value();
            OPOSPrintSetup."Staff Sales Person Label_DXR" := GapsSetupRef.Field(54510).Value();
            OPOSPrintSetup.Modify();
        end;
        GapsSetupRef.Close();
    end;
}
