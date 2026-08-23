codeunit 60052 "DXR MCC Adapt FE Phase12"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52522 is Access = Internal).
    trigger OnRun()
    var
        Phase12: Codeunit "DXR_Migr. Phase 12 History";
    begin
        Phase12.Run();
    end;
}
