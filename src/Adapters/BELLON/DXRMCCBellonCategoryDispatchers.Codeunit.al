#if not ESCUDEA and not BCDX
codeunit 60309 "DXR MCC Bellon P2 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P2-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P2-SETUP-20260825.');
    end;
}

codeunit 60310 "DXR MCC Bellon P2 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P2-MASTER-NAME-FALLBACK-20260826.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P2-MASTER-NAME-FALLBACK-20260826.');
    end;
}

codeunit 60311 "DXR MCC Bellon P2 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P2-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P2-HIST-20260825.');
    end;
}

codeunit 60312 "DXR MCC Bellon P2 Other"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P2-OTHER-20260825.') then exit;
        Worker.RunOther(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P2-OTHER-20260825.');
    end;
}

codeunit 60313 "DXR MCC Bellon P6 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P6-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P6-SETUP-20260825.');
    end;
}

codeunit 60314 "DXR MCC Bellon P6 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P6-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P6-MASTER-20260825.');
    end;
}

codeunit 60315 "DXR MCC Bellon P6 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P6-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P6-HIST-20260825.');
    end;
}

codeunit 60316 "DXR MCC Bellon P6 Other"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P6-OTHER-20260825.') then exit;
        Worker.RunOther(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P6-OTHER-20260825.');
    end;
}

codeunit 60317 "DXR MCC Bellon P11 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P11-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P11-SETUP-20260825.');
    end;
}

codeunit 60318 "DXR MCC Bellon P11 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P11-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P11-MASTER-20260825.');
    end;
}

codeunit 60319 "DXR MCC Bellon P13 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase13"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P13-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P13-SETUP-20260825.');
    end;
}

codeunit 60320 "DXR MCC Bellon P13 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase13"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P13-MASTER-NAME-FALLBACK-20260826.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P13-MASTER-NAME-FALLBACK-20260826.');
    end;
}

codeunit 60383 "DXR MCC Bellon P2 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P2-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P2-ACCOUNTING-20260825.');
    end;
}

codeunit 60384 "DXR MCC Bellon P6 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P6-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P6-ACCOUNTING-20260825.');
    end;
}

codeunit 60385 "DXR MCC Bellon P11 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase11"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P11-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P11-ACCOUNTING-20260825.');
    end;
}

codeunit 60386 "DXR MCC Bellon P13 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase13"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P13-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P13-ACCOUNTING-20260825.');
    end;
}

codeunit 60387 "DXR MCC Bellon P14 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase14"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P14-MASTER-NAME-FALLBACK-20260826.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P14-MASTER-NAME-FALLBACK-20260826.');
    end;
}

codeunit 60388 "DXR MCC Bellon P14 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC Bellon Migr Phase14"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BELLON-P14-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-BELLON-P14-ACCOUNTING-20260825.');
    end;
}

#endif
