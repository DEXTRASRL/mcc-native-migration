codeunit 60044 "DXR MCC Adapt RC Phase3"
{
    // Typed reference to Retail Controls' own migration codeunit - see
    // "DXR MCC Adapt RC Phase1" for the full design rationale. Requires
    // Retail Controls' app.json to grant MCC internalsVisibleTo (56502 is
    // Access = Internal).
    trigger OnRun()
    var
        Phase3: Codeunit "DXR_Migr Phase3 ID Collision";
    begin
        Phase3.Run();
    end;
}
