codeunit 60062 "DXR MCC Adapt Bellon Phase8"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase8: Codeunit "Bellon Migr. Phase 8 Contact";
    begin
        Phase8.Run();
    end;
}
