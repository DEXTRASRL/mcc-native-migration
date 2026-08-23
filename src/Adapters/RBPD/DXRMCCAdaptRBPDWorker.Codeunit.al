codeunit 60025 "DXR MCC Adapt RBPD Worker"
{
    // Typed reference to RecaudoBPD's own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see the SD/DXP adapters for the full
    // rationale, including the correction that this does NOT grant any runtime permission
    // benefit over the plain Codeunit.Run(56308) by ID it replaces; the real benefit is
    // compile-time safety against renames/removals in RecaudoBPD's own repo). Requires
    // RecaudoBPD's app.json to grant MCC internalsVisibleTo (56308 is Access = Internal).
    trigger OnRun()
    var
        Worker: Codeunit "DXR_Recaudo Migr Worker";
    begin
        Worker.Run();
    end;
}
