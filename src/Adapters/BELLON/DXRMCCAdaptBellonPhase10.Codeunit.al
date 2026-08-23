codeunit 60064 "DXR MCC Adapt Bellon Phase10"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase10: Codeunit "Bellon Migr. Phase 10 OldDdp2";
    begin
        Phase10.Run();
    end;
}
