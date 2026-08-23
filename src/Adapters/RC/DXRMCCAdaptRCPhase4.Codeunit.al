codeunit 60045 "DXR MCC Adapt RC Phase4"
{
    // Typed reference to Retail Controls' own migration codeunit - see
    // "DXR MCC Adapt RC Phase1" for the full design rationale. Requires
    // Retail Controls' app.json to grant MCC internalsVisibleTo (56504 is
    // Access = Internal).
    trigger OnRun()
    var
        Phase4: Codeunit "DXR_Migr Phase4 PermSet Repair";
    begin
        Phase4.Run();
    end;
}
