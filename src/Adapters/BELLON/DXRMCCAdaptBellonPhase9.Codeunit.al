codeunit 60063 "DXR MCC Adapt Bellon Phase9"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase9: Codeunit "Bellon Migr. Phase 9 TransferH";
    begin
        Phase9.Run();
    end;
}
