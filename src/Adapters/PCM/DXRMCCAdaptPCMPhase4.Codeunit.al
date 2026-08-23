codeunit 60035 "DXR MCC Adapt PCM Phase4"
{
    // Typed reference to Price Controls Mgt.'s own migration codeunit - see
    // "DXR MCC Adapt PCM Phase2" for the full design rationale.
    trigger OnRun()
    var
        Phase4: Codeunit "DXR_Migr. Phase 4 Sales Docs";
    begin
        Phase4.Run();
    end;
}
