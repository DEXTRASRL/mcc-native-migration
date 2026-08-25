codeunit 60324 "DXR MCC DRLOC P2 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P2-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P2-SETUP-20260825.');
    end;
}

codeunit 60325 "DXR MCC DRLOC P2 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P2-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P2-MASTER-20260825.');
    end;
}

codeunit 60326 "DXR MCC DRLOC P3 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase3"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P3-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P3-MASTER-20260825.');
    end;
}

codeunit 60327 "DXR MCC DRLOC P3 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase3"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P3-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P3-HIST-20260825.');
    end;
}

codeunit 60328 "DXR MCC DRLOC P4 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase4"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P4-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P4-MASTER-20260825.');
    end;
}

codeunit 60329 "DXR MCC DRLOC P4 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase4"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P4-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P4-HIST-20260825.');
    end;
}

codeunit 60330 "DXR MCC DRLOC P5 Master"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase5"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P5-MASTER-20260825.') then exit;
        Worker.RunMaster(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P5-MASTER-20260825.');
    end;
}

codeunit 60331 "DXR MCC DRLOC P5 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase5"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P5-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P5-HIST-20260825.');
    end;
}

codeunit 60332 "DXR MCC DRLOC P6 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P6-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P6-SETUP-20260825.');
    end;
}

codeunit 60333 "DXR MCC DRLOC P6 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P6-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P6-HIST-20260825.');
    end;
}

codeunit 60334 "DXR MCC DRLOC P6 Other"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase6"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P6-OTHER-20260825.') then exit;
        Worker.RunOther(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P6-OTHER-20260825.');
    end;
}

codeunit 60350 "DXR MCC DRLOC P2 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P2-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P2-ACCOUNTING-20260825.');
    end;
}

codeunit 60351 "DXR MCC DRLOC P3 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase3"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P3-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P3-ACCOUNTING-20260825.');
    end;
}

codeunit 60352 "DXR MCC DRLOC P4 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase4"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P4-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P4-ACCOUNTING-20260825.');
    end;
}

codeunit 60353 "DXR MCC DRLOC P5 Accounting"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC DRLOC Migr Phase5"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-DRLOC-P5-ACCOUNTING-20260825.') then exit;
        Worker.RunAccounting(); Tag.SetUpgradeTag('DXR-MCC-DRLOC-P5-ACCOUNTING-20260825.');
    end;
}
