codeunit 60055 "DXR MCC Adapt LSFE POS Cont."
{
    // Typed reference to LS Facturacion Electronica's own migration codeunit -
    // see "DXR MCC Adapt LSFE PermSet" for the full design rationale and the
    // Subtype = Upgrade note. Requires LSFE's app.json to grant MCC
    // internalsVisibleTo (52590 is Access = Internal).
    trigger OnRun()
    var
        POSContingency: Codeunit "DXR_LSFE Migr. POS Contingency";
    begin
        POSContingency.Run();
    end;
}
