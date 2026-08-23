codeunit 60059 "DXR MCC Adapt Bellon Phase5"
{
    // Typed reference to Bellon Customization's own migration codeunit - see
    // "DXR MCC Adapt Bellon Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase5: Codeunit "Bellon Migr. Phase 5 CustItem";
    begin
        Phase5.Run();
    end;
}
