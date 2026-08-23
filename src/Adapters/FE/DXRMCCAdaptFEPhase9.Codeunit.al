codeunit 60049 "DXR MCC Adapt FE Phase9"
{
    // Typed reference to Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt FE Phase7" for the full design rationale. Requires
    // FE's app.json to grant MCC internalsVisibleTo (52540 is Access = Internal).
    trigger OnRun()
    var
        Phase9: Codeunit "DXR_Migr. Phase 9 Purchase";
    begin
        Phase9.Run();
    end;
}
