codeunit 60036 "DXR MCC Adapt PCM Phase5"
{
    // Typed reference to Price Controls Mgt.'s own migration codeunit - see
    // "DXR MCC Adapt PCM Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase5: Codeunit "DXR_Migr. Phase 5 Id Renum";
    begin
        Phase5.Run();
    end;
}
