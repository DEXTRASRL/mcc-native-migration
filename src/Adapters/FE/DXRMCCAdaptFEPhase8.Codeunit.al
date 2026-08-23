codeunit 60048 "DXR MCC Adapt FE Phase8"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52539 is Access = Internal).
    trigger OnRun()
    var
        Phase8: Codeunit "DXR_Migr. Phase 8 Master";
    begin
        Phase8.Run();
    end;
}
