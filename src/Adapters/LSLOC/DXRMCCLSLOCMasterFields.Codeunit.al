#if not ESCUDEA and not BCDX
codeunit 60174 "DXR MCC LSLOC Master Fields"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-MASTERFIELDS-20260825.') then
            exit;
        Worker.RunMasterFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-MASTERFIELDS-20260825.');
    end;
}

codeunit 60357 "DXR MCC LSLOC Accounting Fld"
{
    trigger OnRun()
    var Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS"; UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-ACCOUNTINGFIELDS-20260825.') then exit;
        Worker.RunAccountingFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-ACCOUNTINGFIELDS-20260825.');
    end;
}

#endif
