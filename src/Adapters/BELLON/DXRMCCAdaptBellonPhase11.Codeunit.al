codeunit 60065 "DXR MCC Adapt Bellon Phase11"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase11: Codeunit "Bellon Migr. Phase 11 NCF";
    begin
        Phase11.Run();
    end;
}
