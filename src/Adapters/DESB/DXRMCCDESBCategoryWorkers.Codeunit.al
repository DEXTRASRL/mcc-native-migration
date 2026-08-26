#if not ESCUDEA and not BCDX
codeunit 60250 "DXR MCC DESB Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESB Migr Worker";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-SETUP-20260825.') then
            exit;

        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-SETUP-20260825.');
    end;
}

codeunit 60251 "DXR MCC DESB Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESB Migr Worker";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-MASTER-20260825.') then
            exit;

        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-MASTER-20260825.');
    end;
}

codeunit 60252 "DXR MCC DESB Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESB Migr Worker";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-HISTORIC-20260825.') then
            exit;

        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-HISTORIC-20260825.');
    end;
}

codeunit 60380 "DXR MCC DESB Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESB Migr Worker";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-ACCOUNTING-20260825.') then
            exit;

        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-ACCOUNTING-20260825.');
    end;
}

codeunit 60253 "DXR MCC DESB Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC DESB Migr Worker";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-OTHER-20260825.') then
            exit;

        Worker.RunOther();
        UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-OTHER-20260825.');
    end;
}

#endif
