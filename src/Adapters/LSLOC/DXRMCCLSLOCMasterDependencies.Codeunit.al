codeunit 60178 "DXR MCC LSLOC Master Deps"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr DepFields";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-MASTERDEPS-20260825.') then
            exit;
        Worker.RunMasterDependencies();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-MASTERDEPS-20260825.');
    end;
}
