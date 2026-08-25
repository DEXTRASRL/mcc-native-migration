codeunit 60300 "DXR MCC FE P8 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase8"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P8-SETUP-20260825.') then exit;
        Worker.RunSetup();
        Tag.SetUpgradeTag('DXR-MCC-FE-P8-SETUP-20260825.');
    end;
}

codeunit 60301 "DXR MCC FE P8 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase8"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P8-MASTER-20260825.') then exit;
        Worker.RunMaster();
        Tag.SetUpgradeTag('DXR-MCC-FE-P8-MASTER-20260825.');
    end;
}

codeunit 60302 "DXR MCC FE P9 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase9"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P9-MASTER-20260825.') then exit;
        Worker.RunMaster();
        Tag.SetUpgradeTag('DXR-MCC-FE-P9-MASTER-20260825.');
    end;
}

codeunit 60303 "DXR MCC FE P9 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase9"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P9-HIST-20260825.') then exit;
        Worker.RunHistoric();
        Tag.SetUpgradeTag('DXR-MCC-FE-P9-HIST-20260825.');
    end;
}

codeunit 60304 "DXR MCC FE P10 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase10"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P10-MASTER-20260825.') then exit;
        Worker.RunMaster();
        Tag.SetUpgradeTag('DXR-MCC-FE-P10-MASTER-20260825.');
    end;
}

codeunit 60305 "DXR MCC FE P10 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase10"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P10-HIST-20260825.') then exit;
        Worker.RunHistoric();
        Tag.SetUpgradeTag('DXR-MCC-FE-P10-HIST-20260825.');
    end;
}

codeunit 60306 "DXR MCC FE P11 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P11-SETUP-20260825.') then exit;
        Worker.RunSetup();
        Tag.SetUpgradeTag('DXR-MCC-FE-P11-SETUP-20260825.');
    end;
}

codeunit 60307 "DXR MCC FE P11 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P11-MASTER-20260825.') then exit;
        Worker.RunMaster();
        Tag.SetUpgradeTag('DXR-MCC-FE-P11-MASTER-20260825.');
    end;
}

codeunit 60308 "DXR MCC FE P11 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P11-HIST-20260825.') then exit;
        Worker.RunHistoric();
        Tag.SetUpgradeTag('DXR-MCC-FE-P11-HIST-20260825.');
    end;
}

codeunit 60354 "DXR MCC FE P9 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase9"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P9-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-FE-P9-ACCOUNTING-20260825.');
    end;
}

codeunit 60355 "DXR MCC FE P10 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase10"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P10-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-FE-P10-ACCOUNTING-20260825.');
    end;
}

codeunit 60356 "DXR MCC FE P11 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC FE Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P11-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-FE-P11-ACCOUNTING-20260825.');
    end;
}
