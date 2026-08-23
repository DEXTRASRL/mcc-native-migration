codeunit 60051 "DXR MCC Adapt FE Phase11"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52542 is Access = Internal).
    trigger OnRun()
    var
        Phase11: Codeunit "DXR_Migr. Phase 11 Tables";
    begin
        Phase11.Run();
    end;
}
