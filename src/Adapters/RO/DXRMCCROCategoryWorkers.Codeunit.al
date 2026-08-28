// DRAFT - NOT ENABLED. Thin per-category workers for the RO adapter - see
// DXRMCCROMigrDispatcher.Codeunit.al for the actual field-copy logic and the full analysis.


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
