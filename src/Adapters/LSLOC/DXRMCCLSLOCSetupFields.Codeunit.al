codeunit 60172 "DXR MCC LSLOC Setup Fields"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-SETUPFIELDS-20260825.') then
            exit;
        Worker.RunSetupFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-SETUPFIELDS-20260825.');
    end;
}
