codeunit 60022 "DXR MCC Adapt BC Phase2"
{
    // Typed reference to Base Controls' own migration codeunit - see "DXR MCC Adapt BC Phase1"
    // for the full design rationale (dependency+typed-reference pattern, no runtime permission
    // effect, compile-time safety only). Requires Base Controls' app.json to grant MCC
    // internalsVisibleTo (56415 is Access = Internal).
    //
    // CORRECTED 2026-08-23 (independent review): unlike Phase 1 (skips already-migrated rows)
    // and Phase 3 (only fills blank fields), Phase 2's own Copy* procedures ALWAYS overwrite the
    // active setup singletons from the frozen *_Old2 snapshot - Phase 2's own header comment
    // justifies this by "only runs once, gated by this phase's own upgrade tag", but that tag
    // check lives in "DXR_BC Migr Scheduler".RunPhase(), NOT inside Phase 2's own OnRun. This
    // adapter (like the raw Codeunit.Run(56415) it replaces) enters OnRun directly and bypasses
    // that gate - every MCC re-run of a BC-P2 concept re-overwrites the active setup tables,
    // reverting any post-migration edits a user made to them since. This is PRE-EXISTING
    // behavior, unchanged by this typed-reference switch (raw Codeunit.Run(56415) had the exact
    // same gap) - not a regression, but do not assume BC-P2 is idempotent the way BC-P1/P3 are.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_BC Migr Phase 2";
    begin
        Phase2.Run();
    end;
}
