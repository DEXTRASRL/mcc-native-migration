codeunit 60020 "DXR MCC Adapt DXP Dispatcher"
{
    // Typed reference to DX-Payments' own migration Runner (2026-08-23, portfolio-wide dependency +
    // typed-reference design pattern): MCC declares a real app.json dependency on DX-Payments, and
    // DX-Payments grants MCC "internalsVisibleTo" (its Runner and phase codeunits are
    // Access = Internal - see DXR_MigrPhaseRunner.Codeunit.al and DXR_MigrPhase1Tables/.../
    // DXR_MigrPhase6Fields.Codeunit.al in that extension's own repo, all of which already declare
    // their own correct Permissions). Same rationale as "DXR MCC Adapt SD Dispatcher": indirect
    // permission through the compiled reference graph, no longer dependent on DX-Payments' own
    // permission sets being separately assigned to whoever runs MCC.
    //
    // References the Runner (52313, plain codeunit, NOT Subtype=Upgrade), not the 6 individual
    // Phase codeunits directly: 52313's own OnRun already orchestrates the retroactive precedence
    // repair plus all 6 phases in the correct order (Phase5 before Phase1/2/3/4/6 - see that
    // extension's commits 3d1b88c/608dd6e/0c499f0), each phase/repair self-guarded by its own
    // Upgrade Tag, so calling it once here is equivalent to and no more expensive than MCC's
    // previous plain Codeunit.Run(52313) by ID - only the permission-grant mechanism changes.
    trigger OnRun()
    var
        Runner: Codeunit "DXR_DXP_Migr_Phase_Runner";
    begin
        Runner.Run();
    end;
}
