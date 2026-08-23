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
    // (matching the registry's existing per-phase row granularity) avoids this.
    //
    // CORRECTED 2026-08-23 (independent review): this is NOT purely a compile-time-safety
    // upgrade for VP like it is for BC/RBPD/TU. None of the 7 VP phase codeunits declares a
    // `trigger OnRun` at all (only the `Run(...)` procedure above) - so MCC's PRIOR raw
    // Codeunit.Run(52721..52726/52730) invoked an empty implicit OnRun and returned success
    // while migrating NOTHING. All 46 VP concepts were silently no-op successes before this
    // adapter existed, same bug class already found and fixed for SD/DXP. This adapter is a
    // real functional fix: the first MCC run after this change will move real production data
    // for VP-P1 through VP-P7 for the first time, not re-verify an already-completed migration.
    // Each phase is internally Upgrade-Tag-gated and idempotent, so this is safe to (re-)run.
    // (Side note: because these adapters call each phase directly, "DXR_VP Migration Status"
    // rows are never advanced by MCC's own runs - that table stays whatever VP's own Job Queue
    // dispatcher last left it at. Cosmetic only; every phase step still short-circuits on its
    // own Upgrade Tag regardless of who calls it.)
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
