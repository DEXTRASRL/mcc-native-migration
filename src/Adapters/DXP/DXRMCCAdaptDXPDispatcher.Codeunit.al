codeunit 60020 "DXR MCC Adapt DXP Dispatcher"
{
    // Typed reference to DX-Payments' own migration Runner (2026-08-23, portfolio-wide dependency +
    // typed-reference design pattern): MCC declares a real app.json dependency on DX-Payments.
    // Unlike Special Dispatch's dispatcher, this Runner has NO Access property at all (defaults to
    // Public per AL's Access Property docs - confirmed by reading DXR_MigrPhaseRunner.Codeunit.al
    // directly) - a dependency alone is sufficient to compile this typed reference, no
    // internalsVisibleTo needed. (One WAS added to DX-Payments' app.json by mistake, then reverted
    // in that repo's own commit e1bf849 once this was confirmed - do not re-add it.)
    //
    // CORRECTED 2026-08-23 (do not re-add the removed claim without re-reading Microsoft's own
    // "Permissions Property" doc first): this typed reference does NOT grant any runtime
    // permission benefit over the plain Codeunit.Run(52313) by ID it replaces - see the equivalent,
    // longer correction comment in "DXR MCC Adapt SD Dispatcher" for the full explanation (Microsoft
    // doc citation, why "indirect permission through the compiled reference graph" was wrong). What
    // actually solves DX-Payments' own permission gap is unrelated to this file:
    // EnsurePermissionSetsAssignedIfNeeded() in that extension's Runner already assigns the right
    // permission set to all users as its own first step, every run - that worked before this typed
    // reference existed too. The real (and only) benefit here is compile-time safety: a rename, ID
    // change, or removal of DX-Payments' Runner now breaks MCC's OWN build immediately.
    //
    // References the Runner (52313, plain codeunit, NOT Subtype=Upgrade), not the 6 individual
    // Phase codeunits directly: 52313's own OnRun already orchestrates the retroactive precedence
    // repair plus all 6 phases in the correct order (Phase5 before Phase1/2/3/4/6 - see that
    // extension's commits 3d1b88c/608dd6e/0c499f0), each phase/repair self-guarded by its own
    // Upgrade Tag, so calling it once here is equivalent to and no more expensive than MCC's
    // previous plain Codeunit.Run(52313) by ID.
    trigger OnRun()
    var
        Runner: Codeunit "DXR_DXP_Migr_Phase_Runner";
    begin
        Runner.Run();
    end;
}
