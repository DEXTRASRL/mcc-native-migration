codeunit 60054 "DXR MCC Adapt LSFE PermSet"
{
    // Typed reference to LS Facturacion Electronica's own migration codeunit
    // (2026-08-23, portfolio-wide dependency + typed-reference design pattern -
    // see SD/DXP adapters for the full rationale; compile-time safety only, no
    // runtime permission effect). Requires LSFE's app.json to grant MCC
    // internalsVisibleTo (52589 is Access = Internal).
    //
    // NOTE: 52589's own OnRun calls named procedures on "DXR_LSFE Upgrade"
    // (52587), which IS Subtype = Upgrade - but those are direct procedure
    // calls on a typed variable, never .Run()/OnRun on that codeunit, so this
    // does not violate the "never invoke Subtype = Upgrade" rule. Pre-existing
    // pattern in LSFE's own source (see 52589's comment).
    trigger OnRun()
    var
        AssignPermSet: Codeunit "DXR_LSFE Migr. Assign PermSet";
    begin
        AssignPermSet.Run();
    end;
}
