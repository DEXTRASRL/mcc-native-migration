// =============================================================================================
// DRAFT ADAPTER - "Requisitions" (App ID 4805fd15-75a5-46a2-952f-39c1c4eab821), Adapter code REQ.
// Thin per-category wrappers around DXRMCCREQMigrDispatcher.Codeunit.al's RunSetup/RunMaster/
// RunOther/RunHistoric, mirroring src/Adapters/TU/DXRMCCTUCategoryWorkers.Codeunit.al and
// src/Adapters/PCM/DXRMCCPCMCategoryWorkers.Codeunit.al. Each is the "Dispatcher Codeunit ID" a
// human should register on the matching Concept row (see the InsConcept block proposed in
// DXRMCCREQMigrDispatcher.Codeunit.al's header comment). Wrapped in /* */ - draft, not enabled.
// =============================================================================================


codeunit 60651 "DXR MCC REQ Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC REQ Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-REQ-SETUP-CAT-20260826.');
    end;
}

codeunit 60652 "DXR MCC REQ Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC REQ Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-REQ-MASTER-CAT-20260826.');
    end;
}

codeunit 60653 "DXR MCC REQ Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC REQ Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunOther();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-REQ-OTHER-CAT-20260826.');
    end;
}

codeunit 60654 "DXR MCC REQ Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC REQ Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-REQ-HIST-CAT-20260826.');
    end;
}
