codeunit 60039 "DXR MCC Adapt DESB Phase2"
{
    // Typed reference to Despacho Base's own migration codeunit - see
    // "DXR MCC Adapt DESB Worker" for the full design rationale and a note on the redundant
    // (but harmless, tag-gated) double-invocation with the Worker adapter.
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_Despacho Migr Phase 2";
    begin
        Phase2.Run();
    end;
}
