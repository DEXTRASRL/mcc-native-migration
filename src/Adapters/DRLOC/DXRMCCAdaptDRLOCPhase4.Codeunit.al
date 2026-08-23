codeunit 60071 "DXR MCC Adapt DRLOC Phase4"
{
    // Typed reference to DR-Localization's own migration codeunit - see
    // "DXR MCC Adapt DRLOC Phase2" for the full design rationale. "DXR_Migr.
    // Phase 4 Sales" (52214) is Access = Public, no internalsVisibleTo
    // needed.
    trigger OnRun()
    var
        Phase4: Codeunit "DXR_Migr. Phase 4 Sales";
    begin
        Phase4.Run();
    end;
}
