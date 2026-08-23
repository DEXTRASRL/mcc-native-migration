codeunit 60042 "DXR MCC Adapt RC Phase1"
{
    // Typed reference to Retail Controls' own migration codeunit (2026-08-23,
    // portfolio-wide dependency + typed-reference design pattern - see SD/DXP
    // adapters for the full rationale; compile-time safety only, no runtime
    // permission effect). Requires Retail Controls' app.json to grant MCC
    // internalsVisibleTo (54734 is Access = Internal).
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_Migr Phase1 Setup Retro";
    begin
        Phase1.Run();
    end;
}
