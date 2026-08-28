// Thin per-category worker for the INBC adapter - see DXRMCCINBCMigrDispatcher.Codeunit.al for
// the actual delegation and full analysis. Only one category (Master): the source extension's
// own migration is a single payroll-data phase, not split into Setup/Master/Accounting/Historic.

codeunit 60641 "DXR MCC INBC Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC INBC Migr Dispatcher";
    begin
        Worker.RunMaster();
    end;
}
