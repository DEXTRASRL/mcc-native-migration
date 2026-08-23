codeunit 60019 "DXR MCC Adapt SD Dispatcher"
{
    // Typed reference to Special Dispatch's own migration dispatcher (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern): MCC declares a real app.json dependency on
    // Special Dispatch, and Special Dispatch grants MCC "internalsVisibleTo" (its dispatcher is
    // Access = Internal - see DXR_SD_Migr_Phase_Dispatcher.Codeunit.al in that extension's own
    // repo) so this typed reference compiles at all (AL0161 otherwise).
    //
    // CORRECTED 2026-08-23 (do not re-add the claim below without re-reading Microsoft's own
    // "Permissions Property" doc first): this typed reference does NOT grant any runtime
    // permission benefit over the plain Codeunit.Run(54779) by ID it replaces. Dependencies and
    // internalsVisibleTo are compile-time-only constructs (confirmed via "Using Access Modifiers
    // in AL" - Codeunit.Run already worked on Access=Internal codeunits at runtime with zero
    // grants). Per Microsoft's "Permissions Property" doc's own worked example table: a codeunit's
    // declared Permissions property only elevates a user who ALREADY has at least Indirect
    // permission on that table via their own permission set - a user with NONE still gets a
    // runtime error even when the executed codeunit declares Permissions, regardless of whether it
    // was reached via a typed reference or a raw ID. What actually solves the "operator doesn't
    // have Special Dispatch's own permission set assigned" problem is unrelated to this file: SD's
    // dispatcher itself assigns "DXR_DispatchControls" to all users as its own first phase, every
    // time it runs, before it needs the rest of that permission - that already worked before this
    // typed reference existed and would work identically via a raw Codeunit.Run(54779) call. The
    // real (and only) benefit of this typed reference is compile-time safety: a rename, ID change,
    // or removal of SD's dispatcher now breaks MCC's OWN build immediately, instead of silently
    // no-op'ing or erroring only at runtime the next time someone actually runs this concept.
    //
    // Deliberately references the DISPATCHER (54779), not the individual Phase1/Phase2 codeunits
    // (54780/54781) directly: 54779's own OnRun already orchestrates Phase3 -> Phase1 -> Phase2 in
    // the correct order (fixed 2026-08-23, see that extension's commit edfdc91 - Subtype=Upgrade
    // removed since OnUpgradePerCompany no longer does any real work) and each phase self-guards
    // by its own Upgrade Tag, so calling it once here is equivalent to and no more expensive than
    // MCC's previous plain Codeunit.Run(54779) by ID.
    trigger OnRun()
    var
        Dispatcher: Codeunit "DXR_SD_Migr_Phase_Dispatcher";
    begin
        Dispatcher.Run();
    end;
}
