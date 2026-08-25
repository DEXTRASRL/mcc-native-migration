codeunit 60321 "DXR MCC BPOS P2 Setup"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC BellonPOS Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BPOS-P2-SETUP-20260825.') then exit;
        Worker.RunSetup(); Tag.SetUpgradeTag('DXR-MCC-BPOS-P2-SETUP-20260825.');
    end;
}

codeunit 60322 "DXR MCC BPOS P2 Historic"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC BellonPOS Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BPOS-P2-HIST-20260825.') then exit;
        Worker.RunHistoric(); Tag.SetUpgradeTag('DXR-MCC-BPOS-P2-HIST-20260825.');
    end;
}

codeunit 60323 "DXR MCC BPOS P2 Other"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC BellonPOS Migr Phase2"; Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-BPOS-P2-OTHER-20260825.') then exit;
        Worker.RunOther(); Tag.SetUpgradeTag('DXR-MCC-BPOS-P2-OTHER-20260825.');
    end;
}
