codeunit 60070 "DXR MCC Adapt DRLOC Phase3"
{
    // Typed reference to DR-Localization's own migration codeunit - see
    // "DXR MCC Adapt DRLOC Phase2" for the full design rationale. "DXR_Migr.
    // Phase 3 Purchase" (52212) is Access = Public, no internalsVisibleTo
    // needed.
    trigger OnRun()
    var
        Phase3: Codeunit "DXR_Migr. Phase 3 Purchase";
    begin
        Phase3.Run();
    end;
}
