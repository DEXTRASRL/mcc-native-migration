#if not ESCUDEA and not BCDX
codeunit 60258 "DXR MCC RC Setup"
{
    trigger OnRun()
    var
        Phase1: Codeunit "DXR MCC RC Migr Phase1";
        Phase5: Codeunit "DXR MCC RC Migr Phase5";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-RC-SETUP-20260825.') then
            exit;

        Phase1.RunSetup();
        Phase5.RunSetup();
        UpgradeTag.SetUpgradeTag('DXR-MCC-RC-SETUP-20260825.');
    end;
}

codeunit 60259 "DXR MCC RC Historic"
{
    trigger OnRun()
    var
        Phase5: Codeunit "DXR MCC RC Migr Phase5";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-RC-HISTORIC-20260825.') then
            exit;

        Phase5.RunHistoric();
        UpgradeTag.SetUpgradeTag('DXR-MCC-RC-HISTORIC-20260825.');
    end;
}

codeunit 60260 "DXR MCC RC Other"
{
    trigger OnRun()
    var
        Phase1: Codeunit "DXR MCC RC Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-RC-OTHER-20260825.') then
            exit;

        Phase1.RunOther();
        UpgradeTag.SetUpgradeTag('DXR-MCC-RC-OTHER-20260825.');
    end;
}

codeunit 60382 "DXR MCC RC Accounting"
{
    trigger OnRun()
    var
        Phase2: Codeunit "DXR MCC RC Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-RC-ACCOUNTING-20260825.') then
            exit;

        Phase2.Run();
        UpgradeTag.SetUpgradeTag('DXR-MCC-RC-ACCOUNTING-20260825.');
    end;
}

#endif
