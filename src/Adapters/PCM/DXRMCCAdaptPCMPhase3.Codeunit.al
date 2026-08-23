codeunit 60034 "DXR MCC Adapt PCM Phase3"
{
    // Typed reference to Price Controls Mgt.'s own migration codeunit - see
    // "DXR MCC Adapt PCM Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase3: Codeunit "DXR_Migr. Phase 3 Approval";
    begin
        Phase3.Run();
    end;
}
