codeunit 60038 "DXR MCC Adapt DESB Worker"
{
    // Typed reference to Despacho Base's own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see SD/DXP adapters for the full rationale;
    // compile-time safety only, no runtime permission effect). Requires Despacho Base's app.json
    // to grant MCC internalsVisibleTo (53681 is Access = Internal).
    //
    // NOTE: Worker's own OnRun already calls "DXR_Despacho Migr Dispatcher".
    // RunPendingPhasesWithStatusTracking() internally, which runs BOTH Phase 2 (53908) and
    // Phase 1 in sequence, each gated by its own Upgrade Tag. The registry also has 2 separate
    // rows pointing directly at Phase 2 (see "DXR MCC Adapt DESB Phase2") - this means Phase 2
    // gets invoked twice in a full portfolio run (once via this Worker, once directly). Harmless
    // (Phase 2's own tag-gate makes the second call a no-op) but redundant - pre-existing
    // registry structure, unchanged by this typed-reference switch, not fixed here since it's
    // outside this task's scope (see the ledger for this session's plan).
    trigger OnRun()
    var
        Worker: Codeunit "DXR_Despacho Migr Worker";
    begin
        Worker.Run();
    end;
}
