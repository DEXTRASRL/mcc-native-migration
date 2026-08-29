#if not ESCUDEA and not BCDX
codeunit 60180 "DXR MCC LSLOC Label Functions"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-LABELFUNCTIONS-20260825.') then
            exit;
        Worker.RunLabelFunctionsFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-LABELFUNCTIONS-20260825.');
    end;
}

codeunit 60181 "DXR MCC LSLOC Print Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-PRINTSETUPHEADER-20260825.') then
            exit;
        Worker.RunPOSPrintSetupHeaderFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-PRINTSETUPHEADER-20260825.');
    end;
}

codeunit 60182 "DXR MCC LSLOC POS Terminal"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-POSTERMINAL-20260825.') then
            exit;
        Worker.RunPOSTerminalFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-POSTERMINAL-20260825.');
    end;
}

codeunit 60183 "DXR MCC LSLOC Sales Type"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-SALESTYPE-20260825.') then
            exit;
        Worker.RunSalesTypeFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-SALESTYPE-20260825.');
    end;
}

codeunit 60184 "DXR MCC LSLOC Store Fields"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-STOREFIELDS-20260825.') then
            exit;
        Worker.RunStoreFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-STOREFIELDS-20260825.');
    end;
}

#endif
