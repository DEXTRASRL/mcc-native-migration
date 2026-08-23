codeunit 60072 "DXR MCC Adapt DRLOC Phase5"
{
    // Typed reference to DR-Localization's own migration codeunit - see
    // "DXR MCC Adapt DRLOC Phase2" for the full design rationale. "DXR_Migr.
    // Phase 5 Ledger" (52216) is Access = Public, no internalsVisibleTo
    // needed.
    trigger OnRun()
    var
        Phase5: Codeunit "DXR_Migr. Phase 5 Ledger";
    begin
        Phase5.Run();
    end;
}
