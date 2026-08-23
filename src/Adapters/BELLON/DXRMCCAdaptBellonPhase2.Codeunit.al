codeunit 60056 "DXR MCC Adapt Bellon Phase2"
{
    // Typed reference to Bellon Customization's own migration codeunit
    // (2026-08-23, portfolio-wide dependency + typed-reference design pattern -
    // see SD/DXP adapters for the full rationale; compile-time safety only, no
    // runtime permission effect). Unlike most other extensions in this
    // portfolio, Bellon Customization's phase codeunits (56119-56129) are all
    // Access = Public, so no internalsVisibleTo grant was needed in its
    // app.json - the dependency entry alone is sufficient.
    trigger OnRun()
    var
        Phase2: Codeunit "Bellon Migr. Phase 2 Leg Norm";
    begin
        Phase2.Run();
    end;
}
