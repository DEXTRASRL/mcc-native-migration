// DRAFT - NOT ENABLED. Thin per-category workers for the BANKREC adapter - see
// DXRMCCBANKRECMigrDispatcher.Codeunit.al for the actual field-copy logic and the full analysis
// (table pairs found, TODOs, the resolved ObjectType/DXR_ObjectType enum conversion). Each worker below is gated by its
// own top-level Upgrade Tag (on top of the dispatcher's own per-step tags) exactly like the TU
// adapter's "DXR MCC TU Setup/Master/Accounting" pattern.


codeunit 60451 "DXR MCC BANKREC Setup"
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

codeunit 60452 "DXR MCC BANKREC Master"
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

codeunit 60453 "DXR MCC BANKREC Accounting"
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
// Proposed Registry rows (for a human to add to src/DXRMCCRegistryLoader.Codeunit.al -
// LoadConcepts, near the other extensions' InsConcept blocks). Extension code 'BANKREC' already
// exists (InsExt at line ~99) - no InsExt call is proposed here. Dispatcher/category codeunit IDs
// are the 60451/60452/60453 workers above; legacy/new IDs are the table pairs documented in
// DXRMCCBANKRECMigrDispatcher.Codeunit.al.
// ---------------------------------------------------------------------------------------------
/*
        InsConcept('BANKREC', 'BANKREC-P1', 1, 'Setup - Bank Statement legacy table restore', 60451, 50256, 50268, 'SETUP');
        InsConcept('BANKREC', 'BANKREC-P1', 2, 'File Structure legacy table restore', 60451, 50258, 50270, 'SETUP');
        InsConcept('BANKREC', 'BANKREC-P1', 3, 'Bank legacy table restore', 60452, 50250, 50262, 'MA');
        InsConcept('BANKREC', 'BANKREC-P1', 4, 'Bank Relation legacy table restore', 60452, 50251, 50263, 'MA');
        InsConcept('BANKREC', 'BANKREC-P1', 5, 'Banks - Bank Statement legacy table restore', 60452, 50252, 50264, 'MA');
        InsConcept('BANKREC', 'BANKREC-P1', 6, 'BhdFile legacy table restore', 60453, 50253, 50265, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 7, 'BpdFile legacy table restore', 60453, 50254, 50266, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 8, 'BrsFile legacy table restore', 60453, 50255, 50267, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 9, 'BscFile legacy table restore', 60453, 50261, 50273, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 10, 'Detail - Bank Statement legacy table restore', 60453, 50257, 50269, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 11, 'History - Bank Statement legacy table restore', 60453, 50259, 50271, 'HIST');
        InsConcept('BANKREC', 'BANKREC-P1', 12, 'Log - Bank Statement legacy table restore', 60453, 50260, 50272, 'HIST');
*/
