codeunit 60335 "DXR MCC FE P7 Purch Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-PURCHSETUP-20260825.') then
            exit;
        Worker.RunNCFPurchaseSetup();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-PURCHSETUP-20260825.');
    end;
}

codeunit 60336 "DXR MCC FE P7 Sales Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-SALESSETUP-20260825.') then
            exit;
        Worker.RunNCFSalesSetup();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-SALESSETUP-20260825.');
    end;
}

codeunit 60337 "DXR MCC FE P7 NCF Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-NCFSETUP-20260825.') then
            exit;
        Worker.RunNCFSetup();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-NCFSETUP-20260825.');
    end;
}

codeunit 60338 "DXR MCC FE P7 Payment Rel."
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-PAYMENTREL-20260825.') then
            exit;
        Worker.RunPaymentMethodRelation();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-PAYMENTREL-20260825.');
    end;
}

codeunit 60339 "DXR MCC FE P7 Purch CrMemo"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-PCRMEMOLINE-20260825.') then
            exit;
        Worker.RunPurchCrMemoLineWithholding();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-PCRMEMOLINE-20260825.');
    end;
}

codeunit 60340 "DXR MCC FE P7 Purch Inv. Line"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-PINVLINE-20260825.') then
            exit;
        Worker.RunPurchInvLineWithholding();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-PINVLINE-20260825.');
    end;
}

codeunit 60341 "DXR MCC FE P7 Sales Line"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-SALESLINE-20260825.') then
            exit;
        Worker.RunSalesLineWithholding();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-SALESLINE-20260825.');
    end;
}

codeunit 60342 "DXR MCC FE P7 Sales Inv. Line"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-SINVLINE-20260825.') then
            exit;
        Worker.RunSalesInvoiceLineWithholding();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-SINVLINE-20260825.');
    end;
}

codeunit 60343 "DXR MCC FE P7 Sales CrMemoLn"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC FE Migr Phase7";
        Tag: Codeunit "Upgrade Tag";
    begin
        if Tag.HasUpgradeTag('DXR-MCC-FE-P7-SCRMEMOLINE-20260825.') then
            exit;
        Worker.RunSalesCrMemoLineWithholding();
        Tag.SetUpgradeTag('DXR-MCC-FE-P7-SCRMEMOLINE-20260825.');
    end;
}
