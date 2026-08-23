codeunit 60068 "DXR MCC Adapt LSLOC Dispatch"
{
    // Typed reference to LS Central DR Localization's own migration codeunit
    // (2026-08-23, portfolio-wide dependency + typed-reference design pattern -
    // see SD/DXP adapters for the full rationale; compile-time safety only, no
    // runtime permission effect). "DXR_LS Migr. Dispatcher" (54506) declares no
    // Access property (Public by default), so no internalsVisibleTo grant was
    // needed in its app.json - the dependency entry alone is sufficient. Its
    // own OnRun orchestrates all 3 of this extension's migration phases
    // (OPOS Setup, LS-to-DXR_LS field/table restore, dependency-field sync),
    // each gated by its own Upgrade Tag - matches every LSLOC registry row
    // sharing this one dispatcher, same shape as SD's dispatcher.
    //
    // NOTE (independent review, 2026-08-23): if 54506's own global lock is
    // held elsewhere (e.g. its own auto-scheduled background task) when MCC
    // calls this, its OnRun reschedules a retry and exits WITHOUT an error -
    // MCC will log this run as Completed even though nothing happened this
    // time. Self-healing (a later run/the Fallback Migrator closes any real
    // gap), not a correctness bug, but can produce a transient "Completed"
    // status that did no work - same accepted shape as DRLOC's dispatcher
    // (see "DXR MCC Adapt DRLOC Dispatch").
    trigger OnRun()
    var
        Dispatcher: Codeunit "DXR_LS Migr. Dispatcher";
    begin
        Dispatcher.Run();
    end;
}
