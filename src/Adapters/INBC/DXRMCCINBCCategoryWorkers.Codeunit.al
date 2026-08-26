// DRAFT - see DXRMCCINBCMigrDispatcher.Codeunit.al for context. Not wired in yet.


#if not ESCUDEA and not BCDX
codeunit 60571 "DXR MCC INBC Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC INBC Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-INBC-SETUP-20260826.');
    end;
}

codeunit 60572 "DXR MCC INBC Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC INBC Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-INBC-MA-20260826.');
    end;
}

codeunit 60573 "DXR MCC INBC Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC INBC Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-INBC-ACCOUNTING-20260826.');
    end;
}

#endif
