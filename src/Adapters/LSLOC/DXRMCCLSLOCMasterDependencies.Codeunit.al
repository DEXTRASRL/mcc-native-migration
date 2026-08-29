#if not ESCUDEA and not BCDX
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

codeunit 60358 "DXR MCC LSLOC Accounting Dep"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC LSLOC Migr DepFields"; UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-ACCOUNTINGDEPS-20260825.') then exit;
        Worker.RunAccountingDependencies();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-ACCOUNTINGDEPS-20260825.');
    end;
}

#endif
