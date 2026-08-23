codeunit 60057 "DXR MCC Adapt Bellon Phase3"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase3: Codeunit "Bellon Migr. Phase 3 Dedup";
    begin
        Phase3.Run();
    end;
}
