codeunit 60073 "DXR MCC Adapt DRLOC Phase6"
{
    // Typed reference to DR-Localization's own migration codeunit - see
    // "DXR MCC Adapt DRLOC Phase2" for the full design rationale. "DXR_Migr.
    // Phase 6 History" (52257) is Access = Public, no internalsVisibleTo
    // needed.
    trigger OnRun()
    var
        Phase6: Codeunit "DXR_Migr. Phase 6 History";
    begin
        Phase6.Run();
    end;
}
