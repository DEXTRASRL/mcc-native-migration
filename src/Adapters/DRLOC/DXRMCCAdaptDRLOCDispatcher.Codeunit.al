// codeunit 60069 "DXR MCC Adapt DRLOC Dispatch"
// {
//     // Typed reference to DR-Localization's own migration codeunit (2026-08-23,
//     // portfolio-wide dependency + typed-reference design pattern - see SD/DXP
//     // adapters for the full rationale; compile-time safety only, no runtime
//     // permission effect). "DXR_Migr. Phase Dispatcher" (52208) declares no
//     // Access property (Public by default), so no internalsVisibleTo grant
//     // was needed in DR-Localization's app.json.
//     //
//     // CORRECTED 2026-08-23 (independent review, Critical finding): the first
//     // version of this wiring pointed 5 separate adapters directly at each
//     // Phase 2-6 codeunit (52210/52212/52214/52216/52257), bypassing this real
//     // dispatcher (52208) entirely. That lost 3 things 52208 alone provides:
//     // (1) EnsurePhase1Completed() - Errors out unless DRLOC-P1's Upgrade Tag
//     // is already set, the hard-blocking prerequisite the registry's own
//     // DRLOC-P1 comment describes; (2) a global cross-company migration lock
//     // (LockMgt.TryAcquireLock, 12h duration) preventing a race against
//     // DR-Localization's own auto-scheduled background dispatcher task; (3) a
//     // multi-company coordinator-company gate (IsFirstPendingCompanyInChain)
//     // that some Phase 2 steps (DGII-RNC Database, NAV POS Customer) silently
//     // no-op without. None of Phase 2-6's own OnRun bodies enforce any of
//     // this - it lives ONLY in 52208. Fixed by wiring to 52208 instead, same
//     // shape as SD's dispatcher (one adapter, one Codeunit.Run, internally
//     // orchestrates every phase in order, each independently Upgrade-Tag-
//     // gated so re-running only does the phases still pending - matches
//     // MCC's own per-dispatcher IsDispatcherAlreadyDone dedup exactly).
//     //
//     // Typed by numeric ID, not by name: Price Controls Mgt. independently
//     // declares its own, unrelated codeunit also named "DXR_Migr. Phase
//     // Dispatcher" (AL0275 ambiguous reference otherwise) - both extensions
//     // are MCC dependencies, so the name alone doesn't resolve.
//     trigger OnRun()
//     var
//         Dispatcher: Codeunit 52208;
//     begin
//         Dispatcher.Run();
//     end;
// }
