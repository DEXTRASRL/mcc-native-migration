#if not ESCUDEA and not BCDX
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
        DeduplicateLegacySetupIfNeeded();
        MigrateSetup();
    end;

    /// <summary>
    /// Fixed 2026-08-27 (CONFIRMED reproducible failure): DeduplicateLegacySetup() was called with
    /// NO upgrade-tag guard, which is a regression introduced by this port. Recaudo BPD's own
    /// dispatcher runs the equivalent Update_Setup() exactly ONCE, behind the tag
    /// 'DXR-IB-Update_Setup-15-08-2025-10-1'. MCC, by design, is re-runnable from its control page
    /// and the Executor adds no guard of its own, so this ran on every single run.
    /// It inserts a row with Code = ' ' and then deletes the source row. On the SECOND run - and on
    /// the first run of any tenant where the Ibanking configuration page had ever been opened, since
    /// that page's OnOpenPage does Init/Insert on the LEGACY table and creates a blank-Code row -
    /// the Insert collides on the primary key, the error aborts OnRun, and MigrateSetup() below
    /// NEVER EXECUTES. Net effect: "DXR_IbankingSetup" stays empty and the whole phase fails, every
    /// time, with no partial progress.
    /// Guarded with its own tag so it runs once per company, matching upstream's own contract.
    /// </summary>
    local procedure DeduplicateLegacySetupIfNeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-RBPD-IBSETUP-DEDUP-20260827') then
            exit;

        DeduplicateLegacySetup();

        UpgradeTag.SetUpgradeTag('DXR-MCC-RBPD-IBSETUP-DEDUP-20260827');
    end;

    local procedure DeduplicateLegacySetup()
    var
        IbankingSetup: Record "DXR-IB IbankingSetup";
        IbankingSetup2: Record "DXR-IB IbankingSetup";
    begin
        // Fixed 2026-08-27: skip when a blank-Code row already exists, so the deduplication is
        // idempotent even if the tag above is ever cleared. Without this the Insert below collides.
        if IbankingSetup2.Get(' ') then
            exit;

        if IbankingSetup.FindFirst() then begin
            IbankingSetup2.Init();
            IbankingSetup2.Code := ' ';
            IbankingSetup2."User Active DXR-IB" := IbankingSetup."User Active DXR-IB";
            IbankingSetup2."User Name DXR-IB" := IbankingSetup."User Name DXR-IB";
            IbankingSetup2."Local Currency DXR-IB" := IbankingSetup."Local Currency DXR-IB";
            IbankingSetup2."Journal Template Name DXR-IB" := IbankingSetup."Journal Template Name DXR-IB";
            IbankingSetup2."Journal Batch Name DXR-IB" := IbankingSetup."Journal Batch Name DXR-IB";
            IbankingSetup2."Description DXR-IB" := IbankingSetup."Description DXR-IB";
            IbankingSetup2."Bal. Account Type DXR-IB" := IbankingSetup."Bal. Account Type DXR-IB";
            IbankingSetup2."Bal. Account No. DXR-IB" := IbankingSetup."Bal. Account No. DXR-IB";
            IbankingSetup2."No. Series DXR-IB" := IbankingSetup."No. Series DXR-IB";
            IbankingSetup2."Recibo Ingreso DXR-IB" := IbankingSetup."Recibo Ingreso DXR-IB";
            IbankingSetup2."Starting No. DXR-IB" := IbankingSetup."Starting No. DXR-IB";
            IbankingSetup2."Ending No. DXR-IB" := IbankingSetup."Ending No. DXR-IB";
            IbankingSetup2."Default Nos. DXR-IB" := IbankingSetup."Default Nos. DXR-IB";
            IbankingSetup2."Line No. DXR-IB" := IbankingSetup."Line No. DXR-IB";
            IbankingSetup2."Template Type DXR-IB" := IbankingSetup."Template Type DXR-IB";
            IbankingSetup2."Document Type DXR-IB" := IbankingSetup."Document Type DXR-IB";
            IbankingSetup2."Account Type DXR-IB" := IbankingSetup."Account Type DXR-IB";
            IbankingSetup2."User Password DXR-IB" := IbankingSetup."User Password DXR-IB";
            IbankingSetup2."AutoPosteo DXR-IB" := IbankingSetup."AutoPosteo DXR-IB";
            IbankingSetup2."PagoExcedente DXR-IB" := IbankingSetup."PagoExcedente DXR-IB";
            IbankingSetup2."Posting No. Series DXR-IB" := IbankingSetup."Posting No. Series DXR-IB";
            IbankingSetup2."JnlBatchNamePendientes DXR-IB" := IbankingSetup."JnlBatchNamePendientes DXR-IB";
            IbankingSetup2."open DXR-IB" := IbankingSetup."open DXR-IB";
            IbankingSetup2."Middleware URL DXR-IB" := IbankingSetup."Middleware URL DXR-IB";
            IbankingSetup2."Middleware User DXR-IB" := IbankingSetup."Middleware User DXR-IB";
            IbankingSetup2."Middleware Password DXR-IB" := IbankingSetup."Middleware Password DXR-IB";
            IbankingSetup2."Auto Process Pending DXR-IB" := IbankingSetup."Auto Process Pending DXR-IB";
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
                    NewRec."User Active DXR-IB" := OldRec."User Active DXR-IB";
                    NewRec."User Name DXR-IB" := OldRec."User Name DXR-IB";
                    NewRec."Local Currency DXR-IB" := OldRec."Local Currency DXR-IB";
                    NewRec."Journal Template Name DXR-IB" := OldRec."Journal Template Name DXR-IB";
                    NewRec."Journal Batch Name DXR-IB" := OldRec."Journal Batch Name DXR-IB";
                    NewRec."Description DXR-IB" := OldRec."Description DXR-IB";
                    NewRec."Bal. Account Type DXR-IB" := OldRec."Bal. Account Type DXR-IB";
                    NewRec."Bal. Account No. DXR-IB" := OldRec."Bal. Account No. DXR-IB";
                    NewRec."No. Series DXR-IB" := OldRec."No. Series DXR-IB";
                    NewRec."Recibo Ingreso DXR-IB" := OldRec."Recibo Ingreso DXR-IB";
                    NewRec."Starting No. DXR-IB" := OldRec."Starting No. DXR-IB";
                    NewRec."Ending No. DXR-IB" := OldRec."Ending No. DXR-IB";
                    NewRec."Default Nos. DXR-IB" := OldRec."Default Nos. DXR-IB";
                    NewRec."Line No. DXR-IB" := OldRec."Line No. DXR-IB";
                    NewRec."Template Type DXR-IB" := OldRec."Template Type DXR-IB";
                    NewRec."Document Type DXR-IB" := OldRec."Document Type DXR-IB";
                    NewRec."Account Type DXR-IB" := OldRec."Account Type DXR-IB";
                    NewRec."User Password DXR-IB" := OldRec."User Password DXR-IB";
                    NewRec."AutoPosteo DXR-IB" := OldRec."AutoPosteo DXR-IB";
                    NewRec."PagoExcedente DXR-IB" := OldRec."PagoExcedente DXR-IB";
                    NewRec."Posting No. Series DXR-IB" := OldRec."Posting No. Series DXR-IB";
                    NewRec."JnlBatchNamePendientes DXR-IB" := OldRec."JnlBatchNamePendientes DXR-IB";
                    NewRec."open DXR-IB" := OldRec."open DXR-IB";
                    NewRec."Middleware URL DXR-IB" := OldRec."Middleware URL DXR-IB";
                    NewRec."Middleware User DXR-IB" := OldRec."Middleware User DXR-IB";
                    NewRec."Middleware Password DXR-IB" := OldRec."Middleware Password DXR-IB";
                    NewRec."Auto Process Pending DXR-IB" := OldRec."Auto Process Pending DXR-IB";
                    NewRec.Code := OldRec.Code;
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}

#endif
