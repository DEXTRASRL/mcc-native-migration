codeunit 60107 "DXR MCC RBPD Migr IBSetup"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateSetup(). Also ports the Dispatcher's own
    // Update_Setup() pre-cleanup (deduplicates a blank-Code row on the LEGACY
    // "DXR-IB IbankingSetup" table, a genuine data-quality prerequisite Phase1 depends on
    // - Recaudo BPD's own RunManually() always runs it immediately before Phase1).
    Permissions = tabledata "DXR-IB IbankingSetup" = RIMD,
                  tabledata "DXR_IbankingSetup" = RIM;

    trigger OnRun()
    begin
        DeduplicateLegacySetup();
        MigrateSetup();
    end;

    local procedure DeduplicateLegacySetup()
    var
        IbankingSetup: Record "DXR-IB IbankingSetup";
        IbankingSetup2: Record "DXR-IB IbankingSetup";
    begin
        if IbankingSetup.FindFirst() then begin
            IbankingSetup2.Code := ' ';
            IbankingSetup2.TransferFields(IbankingSetup);
            IbankingSetup2.Insert();
            IbankingSetup.Delete(true);
        end;
    end;

    local procedure MigrateSetup()
    var
        OldRec: Record "DXR-IB IbankingSetup";
        NewRec: Record "DXR_IbankingSetup";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec.Code) then begin
                    NewRec.Init();
                    NewRec.TransferFields(OldRec, true);
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}
