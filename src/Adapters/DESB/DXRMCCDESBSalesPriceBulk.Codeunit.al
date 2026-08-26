#if not ESCUDEA and not BCDX
codeunit 60442 "DXR MCC DESB Sales Price Bulk"
{
    trigger OnRun()
    // 2026-08-26: disabled per user instruction - Sales Price View restore is no longer needed for
    // DESB. Left commented (not deleted) so the object/dispatcher ID stays reserved and traceable;
    // see DXRMCCRegistryLoader's DESB-P1 seq29, also commented out to match.
    // var
    //     Worker: Codeunit "DXR MCC DESB Migr Worker";
    //     UpgradeTag: Codeunit "Upgrade Tag";
    // begin
    //     if UpgradeTag.HasUpgradeTag('DXR-MCC-DESB-SALES-PRICE-BULK-20260825.') then
    //         exit;

    //     Worker.RunSalesPriceView();
    //     UpgradeTag.SetUpgradeTag('DXR-MCC-DESB-SALES-PRICE-BULK-20260825.');
    // end;
    begin
    end;
}

#endif
