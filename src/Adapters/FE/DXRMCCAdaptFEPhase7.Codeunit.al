codeunit 60047 "DXR MCC Adapt FE Phase7"
{
    // Typed reference to Facturacion Electronica's own migration codeunit
    // (2026-08-23, portfolio-wide dependency + typed-reference design pattern -
    // see SD/DXP adapters for the full rationale; compile-time safety only, no
    // runtime permission effect). Requires FE's app.json to grant MCC
    // internalsVisibleTo (52543 is Access = Internal).
    trigger OnRun()
    var
        Phase7: Codeunit "DXR_Migr. Phase 7 Bootstrap";
    begin
        Phase7.Run();
    end;
}
