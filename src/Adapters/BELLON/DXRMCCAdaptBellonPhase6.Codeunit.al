codeunit 60060 "DXR MCC Adapt Bellon Phase6"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase6: Codeunit "Bellon Migr. Phase 6 Table ID";
    begin
        Phase6.Run();
    end;
}
