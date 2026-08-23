codeunit 60023 "DXR MCC Adapt BC Phase3"
{
    // Typed reference to Base Controls' own migration codeunit - see "DXR MCC Adapt BC Phase1"
    // for the full design rationale. Requires Base Controls' app.json to grant MCC
    // internalsVisibleTo (56416 is Access = Internal).
    trigger OnRun()
    var
        Phase3: Codeunit "DXR_BC Migr Phase 3";
    begin
        Phase3.Run();
    end;
}
