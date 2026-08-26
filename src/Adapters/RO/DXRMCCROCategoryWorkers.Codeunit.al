// DRAFT - NOT YET ENABLED. Category-worker shims for adapter RO (Reportes Operativos), mirroring
// TU's DXRMCCTUCategoryWorkers.Codeunit.al: thin, tag-gated wrappers that call into
// "DXR MCC RO Migr Dispatcher" (60610). IDs picked from the reserved RO block 60610-60629.


codeunit 60611 "DXR MCC RO Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC RO Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-RO-SETUP-20260826.');
    end;
}

codeunit 60612 "DXR MCC RO Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC RO Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-20260826.');
    end;
}

