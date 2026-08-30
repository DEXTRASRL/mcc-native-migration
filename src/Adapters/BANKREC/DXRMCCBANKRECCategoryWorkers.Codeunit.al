// Thin per-category workers for the BANKREC adapter - see
// DXRMCCBANKRECMigrDispatcher.Codeunit.al for the actual field-copy logic and the full analysis
// (table pairs found, TODOs, the resolved ObjectType/DXR_ObjectType enum conversion). Each worker below is gated by its
// own top-level Upgrade Tag (on top of the dispatcher's own per-step tags) exactly like the TU
// adapter's "DXR MCC TU Setup/Master/Accounting" pattern.


codeunit 60454 "DXR MCC BANKREC Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC BANKREC Migr Dispatch";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-SETUP-20260826.');
    end;
}

codeunit 60455 "DXR MCC BANKREC Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC BANKREC Migr Dispatch";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-MA-20260826.');
    end;
}

codeunit 60456 "DXR MCC BANKREC Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC BANKREC Migr Dispatch";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-ACCOUNTING-20260826.');
    end;
}

// ---------------------------------------------------------------------------------------------
// Registry rows added to src/DXRMCCRegistryLoader.Codeunit.al's LoadConcepts (near BANKREC's
// InsExt). CORRECTED 2026-08-29: this comment previously proposed 60451/60452/60453 as the
// Setup/Master/Accounting dispatcher IDs, but that never matched the codeunits actually declared
// in this file - the real IDs are 60454 (Setup)/60455 (Master)/60456 (Accounting) above; 60453 is
// the shared "DXR MCC BANKREC Migr Dispatch" worker codeunit, not a category worker. The registry
// had been seeded from this stale proposal, so these concepts pointed at the wrong (in one case
// unrelated, in another nonexistent) codeunit IDs and could never actually run from Business
// Central - fixed at the registry, not here; kept for reference only, do not re-copy blindly.
// ---------------------------------------------------------------------------------------------
//        InsConcept('BANKREC', 'BANKREC-P1', 1, 'Setup - Bank Statement legacy table restore', 60454, 50256, 50268, 'SETUP');
//        InsConcept('BANKREC', 'BANKREC-P1', 2, 'File Structure legacy table restore', 60454, 50258, 50270, 'SETUP');
//        InsConcept('BANKREC', 'BANKREC-P1', 3, 'Bank legacy table restore', 60455, 50250, 50262, 'MA');
//        InsConcept('BANKREC', 'BANKREC-P1', 4, 'Bank Relation legacy table restore', 60455, 50251, 50263, 'MA');
//        InsConcept('BANKREC', 'BANKREC-P1', 5, 'Banks - Bank Statement legacy table restore', 60455, 50252, 50264, 'MA');
//        InsConcept('BANKREC', 'BANKREC-P1', 6, 'BhdFile legacy table restore', 60456, 50253, 50265, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 7, 'BpdFile legacy table restore', 60456, 50254, 50266, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 8, 'BrsFile legacy table restore', 60456, 50255, 50267, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 9, 'BscFile legacy table restore', 60456, 50261, 50273, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 10, 'Detail - Bank Statement legacy table restore', 60456, 50257, 50269, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 11, 'History - Bank Statement legacy table restore', 60456, 50259, 50271, 'HIST');
//        InsConcept('BANKREC', 'BANKREC-P1', 12, 'Log - Bank Statement legacy table restore', 60456, 50260, 50272, 'HIST');
