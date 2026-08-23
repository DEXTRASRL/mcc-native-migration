codeunit 60066 "DXR MCC Adapt Bellon Phase12"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase12: Codeunit "Bellon Migr. Phase 12 PHFix";
    begin
        Phase12.Run();
    end;
}
