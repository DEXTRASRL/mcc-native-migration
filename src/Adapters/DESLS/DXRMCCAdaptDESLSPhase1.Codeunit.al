codeunit 60041 "DXR MCC Adapt DESLS Phase1"
{
    // Typed reference to Despacho LS's own migration codeunit - see "DXR MCC Adapt DESLS Worker"
    // for the full design rationale.
    trigger OnRun()
    var
        Phase1: Codeunit "DXR_Desp LS Migr Phase 1";
    begin
        Phase1.Run();
    end;
}
