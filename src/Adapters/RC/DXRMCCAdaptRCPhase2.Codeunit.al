codeunit 60043 "DXR MCC Adapt RC Phase2"
{
    // Typed reference to Retail Controls' own migration codeunit - see
    // "DXR MCC Adapt RC Phase1" for the full design rationale. Requires
    // Retail Controls' app.json to grant MCC internalsVisibleTo (54744 is
    // Access = Internal).
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Migr Phase2 Documents";
    begin
        Phase2.Run();
    end;
}
