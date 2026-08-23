codeunit 60040 "DXR MCC Adapt DESLS Worker"
{
    // Typed reference to Despacho LS's own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see SD/DXP adapters for the full rationale;
    // compile-time safety only, no runtime permission effect). Requires Despacho LS's app.json
    // to grant MCC internalsVisibleTo (53963 is Access = Internal).
    //
    // NOTE: same shape as Despacho Base's Worker/Phase2 pair (see "DXR MCC Adapt DESB Worker") -
    // this Worker's own OnRun already calls "DXR_Desp LS Migr Dispatcher".
    // RunPendingPhasesWithStatusTracking() internally, which likely already runs Phase 1 (53924)
    // too. The registry also has 14 rows pointing directly at Phase 1 (see
    // "DXR MCC Adapt DESLS Phase1") - preserved as-is, pre-existing registry structure.
    trigger OnRun()
    var
        Worker: Codeunit "DXR_Desp LS Migr Worker";
    begin
        Worker.Run();
    end;
}
