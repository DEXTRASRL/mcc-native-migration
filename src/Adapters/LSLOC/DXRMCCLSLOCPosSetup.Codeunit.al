
codeunit 60171 "DXR MCC LSLOC POS Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-POSSETUP-20260825.') then
            exit;
        Worker.RunPOSSetup();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-POSSETUP-20260825.');
    end;
}

