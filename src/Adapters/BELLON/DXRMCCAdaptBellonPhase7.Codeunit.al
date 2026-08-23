codeunit 60061 "DXR MCC Adapt Bellon Phase7"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase7: Codeunit "Bellon Migr. Phase 7 TabExt";
    begin
        Phase7.Run();
    end;
}
