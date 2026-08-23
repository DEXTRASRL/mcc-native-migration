codeunit 60019 "DXR MCC Adapt SD Dispatcher"
{
    // Typed reference to Special Dispatch's own migration dispatcher (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern): MCC declares a real app.json dependency on
    // Special Dispatch, and Special Dispatch grants MCC "internalsVisibleTo" (its dispatcher and
    // phase codeunits are Access = Internal - see DXR_SD_Migr_Phase_Dispatcher.Codeunit.al and
    // DXR_SD_Migr_Phase1_FieldDup/Phase2_LegacyTable.Codeunit.al in that extension's own repo).
    // This gives every user with Execute (X) on THIS codeunit indirect permission, through the
    // compiled reference graph, on every table Special Dispatch's migration touches - without
    // needing Special Dispatch's own permission sets separately assigned to whoever runs MCC.
    //
    // Deliberately references the DISPATCHER (54779), not the individual Phase1/Phase2 codeunits
    // (54780/54781) directly: 54779's own OnRun already orchestrates Phase3 -> Phase1 -> Phase2 in
    // the correct order (fixed 2026-08-23, see that extension's commit edfdc91 - Subtype=Upgrade
    // removed since OnUpgradePerCompany no longer does any real work) and each phase self-guards
    // by its own Upgrade Tag, so calling it once here is equivalent to and no more expensive than
    // MCC's previous plain Codeunit.Run(54779) by ID - the only thing that changes is the
    // permission-grant mechanism (typed/indirect vs relying on the invoking user's own assigned
    // permission sets).
    trigger OnRun()
    var
        Dispatcher: Codeunit "DXR_SD_Migr_Phase_Dispatcher";
    begin
        Dispatcher.Run();
    end;
}
