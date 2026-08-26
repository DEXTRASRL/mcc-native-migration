#if not ESCUDEA and not BCDX
codeunit 60254 "DXR MCC DESLS Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESLS Migr Worker";
        Phase1: Codeunit "DXR MCC DESLS Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESLS-SETUP-20260825.') then
            exit;

        Worker.RunSetup();
        Phase1.RunSetup();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESLS-SETUP-20260825.');
    end;
}

codeunit 60255 "DXR MCC DESLS Master"
{
    trigger OnRun()
    var
        Phase1: Codeunit "DXR MCC DESLS Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESLS-MASTER-20260825.') then
            exit;

        Phase1.RunMaster();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESLS-MASTER-20260825.');
    end;
}

codeunit 60256 "DXR MCC DESLS Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESLS Migr Worker";
        Phase1: Codeunit "DXR MCC DESLS Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESLS-HISTORIC-20260825.') then
            exit;

        Worker.RunHistoric();
        Phase1.RunHistoric();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESLS-HISTORIC-20260825.');
    end;
}

codeunit 60381 "DXR MCC DESLS Accounting"
{
    trigger OnRun()
    var
        Phase1: Codeunit "DXR MCC DESLS Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESLS-ACCOUNTING-20260825.') then
            exit;

        Phase1.RunAccounting();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESLS-ACCOUNTING-20260825.');
    end;
}

codeunit 60257 "DXR MCC DESLS Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESLS Migr Worker";
        Phase1: Codeunit "DXR MCC DESLS Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESLS-OTHER-20260825.') then
            exit;

        Worker.RunOther();
        Phase1.RunOther();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESLS-OTHER-20260825.');
    end;
}

#endif
