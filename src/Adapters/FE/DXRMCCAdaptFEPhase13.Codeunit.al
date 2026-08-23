codeunit 60053 "DXR MCC Adapt FE Phase13"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52525 is Access = Internal).
    trigger OnRun()
    var
        Phase13: Codeunit "DXR_Migr. Phase 13 NCF Cleanup";
    begin
        Phase13.Run();
    end;
}
