codeunit 60050 "DXR MCC Adapt FE Phase10"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52541 is Access = Internal).
    trigger OnRun()
    var
        Phase10: Codeunit "DXR_Migr. Phase 10 Sales";
    begin
        Phase10.Run();
    end;
}
