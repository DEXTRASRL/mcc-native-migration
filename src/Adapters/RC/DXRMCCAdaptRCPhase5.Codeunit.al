codeunit 60046 "DXR MCC Adapt RC Phase5"
{
    // Typed reference to Retail Controls' own migration codeunit - see
    // "DXR MCC Adapt RC Phase1" for the full design rationale. Requires
    // Retail Controls' app.json to grant MCC internalsVisibleTo (56508 is
    // Access = Internal).
    trigger OnRun()
    var
        Phase5: Codeunit "DXR_Migr Phase5 Setup Tables";
    begin
        Phase5.Run();
    end;
}
