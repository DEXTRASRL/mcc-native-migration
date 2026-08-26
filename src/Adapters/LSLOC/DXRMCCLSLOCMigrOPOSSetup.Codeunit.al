#if not ESCUDEA and not BCDX
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
    //
    // "DXR_Gaps Setup" (52165) is Access = Internal in DR-Localization, and MCC has no
    // internalsVisibleTo grant from DR-Localization (confirmed via DR-Localization\Localization\
    // app.json - only "LS Central DR Localization" itself and a handful of other apps are
    // granted). Zero-RecordRef therefore requires a thin typed wrapper: LSLOC's own public
    // "DXR_LS Migr. Dispatcher" (54506) now exposes RunOPOSSetupFromGapsSetup(), a same-package
    // pass-through to the existing (and still Access = Internal) "DXR_LS OPOS Print Setup Upgr."
    // (54513) Execute() - no logic duplicated, no new codeunit created in LSLOC.
    Permissions =
        tabledata User = R,
        tabledata "Access Control" = RIM,
        tabledata "DXR_Gaps Setup" = RI;

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
        GapsSetup: Record "DXR_Gaps Setup";
        LSLOCDispatcher: Codeunit "DXR_LS Migr. Dispatcher";
    begin
        // The LSLOC worker reads the DRLOC singleton with an unconditional Get(). A newly-created
        // company can legitimately have no row yet, so establish the empty-key singleton before
        // crossing the public wrapper boundary instead of allowing a normal missing setup row to
        // abort the complete Setup run.
        if not GapsSetup.Get('') then begin
            GapsSetup.Init();
            GapsSetup."Key" := '';
            GapsSetup.Insert(false);
        end;

        LSLOCDispatcher.RunOPOSSetupFromGapsSetup();
    end;
}

#endif
