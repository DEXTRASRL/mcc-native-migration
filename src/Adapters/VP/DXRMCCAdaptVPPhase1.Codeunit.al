codeunit 60026 "DXR MCC Adapt VP Phase1"
{
    // Typed reference to Vendor Payloads' own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see SD/DXP adapters for the full rationale;
    // compile-time safety only, no runtime permission effect). Requires Vendor Payloads' app.json
    // to grant MCC internalsVisibleTo (all 7 phase codeunits are Access = Internal).
    //
    // IMPORTANT (2026-08-23): deliberately calls Phase1 DIRECTLY, not "DXR_VP Migration
    // Dispatcher" (52720). That dispatcher's own OnRun only advances ONE phase per call
    // (RunNextPendingPhase - see its own header comment) and reschedules the rest via
    // Scheduler.ScheduleImmediateRerun() as a SEPARATE async Job Queue entry - a single
    // Codeunit.Run(52720) would report success after only Phase 1 ran, while Phases 2-7 stay
    // Pending until Vendor Payloads' own Job Queue infrastructure picks them up independently,
    // outside MCC's control and timing. Calling each phase's own Run(...) procedure directly
    // (matching the registry's existing per-phase row granularity) avoids this - each concept
    // completes fully, synchronously, exactly as it did before this typed-reference change.
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_VP Migration Phase1 Setup";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase1.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
