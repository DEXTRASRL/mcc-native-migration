// #if not ESCUDEA and not BCDX
// codeunit 60154 "DXR MCC Bellon Migr Phase10"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 10 OldDdp2" (56127) -> "Bellon Upgrade Process".MigrateAllSalesPurchOldDedup2().
//     // CONFIRMED NO-OP in the current source: this was meant to be a "true dedup, part 2" bridge
//     // for the Sales/Purchase 14-table family's "_Old" fields (52787-52803, created by Phase 3),
//     // but git history confirmed migration/v28.3 never merged into deploy/production - the entire
//     // 51801-54999 ID range these fields lived in was never part of any successfully published
//     // version, so the 100 "_Old" fields were marked ObsoleteState = Removed directly instead. The
//     // 14 per-table procedures are kept in source, unused, as documentation only. Preserved here as
//     // a trivial tag-setting no-op, matching the real source's own current behavior exactly and
//     // keeping this registry concept (BELLON-P10) satisfiable.
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-SalesPurchOldDedup2') then
//             exit;
// 
//         // No-op - see header comment. The source columns these 14 procedures would have read
//         // from no longer exist post-publish (ObsoleteState = Removed, same release).
// 
//         UpgradeTag.SetUpgradeTag('DXR-SalesPurchOldDedup2');
//     end;
// }
// 
// #endif
// 
