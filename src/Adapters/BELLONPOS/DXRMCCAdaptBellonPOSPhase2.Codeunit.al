codeunit 60067 "DXR MCC Adapt BellonPOS Ph2"
{
    // Typed reference to Bellon Customization POS's own migration codeunit
    // (2026-08-23, portfolio-wide dependency + typed-reference design pattern -
    // see SD/DXP adapters for the full rationale; compile-time safety only, no
    // runtime permission effect). Access = Public (like the sibling Bellon
    // Customization phase codeunits), so no internalsVisibleTo grant was
    // needed.
    trigger OnRun()
    var
        Phase2: Codeunit "Bellon POS Migr Phase2 LegNorm";
    begin
        Phase2.Run();
    end;
}
