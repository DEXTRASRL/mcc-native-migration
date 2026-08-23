codeunit 60021 "DXR MCC Adapt BC Phase1"
{
    // Typed reference to Base Controls' own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see the equivalent SD/DXP adapters for the
    // full rationale, including the correction that this does NOT grant any runtime permission
    // benefit over the plain Codeunit.Run(54858) by ID it replaces; the real benefit is
    // compile-time safety against renames/removals in Base Controls' own repo). Requires Base
    // Controls' app.json to grant MCC internalsVisibleTo (54858 is Access = Internal).
    //
    // Calls .Run() (invokes OnRun, which does the Copy* work directly) rather than the sibling
    // .RunPhase1() wrapper (which adds status tracking + its own self Codeunit.Run for write-
    // transaction isolation, then sets an Upgrade Tag) - matches MCC's prior, already-approved
    // behavior exactly (raw Codeunit.Run(54858) also invokes OnRun only). Phase 1 itself IS
    // idempotent (skips already-migrated rows via `if NewSetup.Get('') then exit`) - this
    // change is purely the invocation mechanism, no behavior change. NOTE: this idempotency
    // claim is per-phase, not portfolio-wide for BC - see "DXR MCC Adapt BC Phase2" for a real
    // exception found by independent review (2026-08-23).
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_BC Migr Phase 1";
    begin
        Phase1.Run();
    end;
}
