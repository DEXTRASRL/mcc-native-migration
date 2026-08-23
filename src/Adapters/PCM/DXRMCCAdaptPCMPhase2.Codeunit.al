codeunit 60033 "DXR MCC Adapt PCM Phase2"
{
    // Typed reference to Price Controls Mgt.'s own migration codeunit (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see SD/DXP adapters for the full rationale;
    // compile-time safety only, no runtime permission effect). Unlike SD, this codeunit has no
    // Access property (defaults to Public) - a dependency alone is sufficient, no
    // internalsVisibleTo needed on Price Controls Mgt.'s side.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr. Phase 2 Master Data";
    begin
        Phase2.Run();
    end;
}
