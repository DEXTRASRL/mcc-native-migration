codeunit 60058 "DXR MCC Adapt Bellon Phase4"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase4: Codeunit "Bellon Migr. Phase 4 PermSet";
    begin
        Phase4.Run();
    end;
}
