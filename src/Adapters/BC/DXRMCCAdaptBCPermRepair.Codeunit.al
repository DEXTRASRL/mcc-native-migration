codeunit 60024 "DXR MCC Adapt BC Perm Repair"
{
    // Typed reference to Base Controls' own migration codeunit - see "DXR MCC Adapt BC Phase1"
    // for the full design rationale. Requires Base Controls' app.json to grant MCC
    // internalsVisibleTo (56413 is Access = Internal).
    trigger OnRun()
    var
        PermRepair: Codeunit "DXR_BC Migr Perm Repair";
    begin
        PermRepair.Run();
    end;
}
