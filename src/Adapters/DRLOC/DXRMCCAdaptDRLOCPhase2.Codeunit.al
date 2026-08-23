codeunit 60069 "DXR MCC Adapt DRLOC Phase2"
{
    // Typed reference to DR-Localization's own migration codeunit (2026-08-23,
    // portfolio-wide dependency + typed-reference design pattern - see SD/DXP
    // adapters for the full rationale; compile-time safety only, no runtime
    // permission effect). "DXR_Migr. Phase 2 Fiscal" (52210) declares no
    // Access property (Public by default), so no internalsVisibleTo grant
    // was needed in DR-Localization's app.json.
    //
    // Wraps the whole Phase 2 dispatcher, not the per-step breakout envisioned
    // by this plan's original Tasks 2.1-2.3 (see docs/superpowers/plans/
    // 2026-08-23-mcc-native-migration.md "REALIZED GRANULARITY") - matches
    // the coarser per-dispatcher pattern used for every other extension in
    // this portfolio pass.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr. Phase 2 Fiscal";
    begin
        Phase2.Run();
    end;
}
