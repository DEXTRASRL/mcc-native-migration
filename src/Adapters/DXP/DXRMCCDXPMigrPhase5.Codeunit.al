codeunit 60084 "DXR MCC DXP Migr Phase5"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase5_Tables"
    // - copies the 9 "...54700" tables (the most recent renumbering generation, business-confirmed
    // source of truth) to the same DXR_ clones Phase1/Phase3 also target (DXP-P5 concepts, seq
    // 1-9).
    //
    // CRITICAL ORDERING/PRECEDENCE NOTE (2026-08-23): this is the exact financial-data-precedence
    // bug already found and fixed once this session in DX-Payments' own repo (commits 3d1b88c,
    // 608dd6e, 0c499f0) - Phase 1/3/5 all insert-only-if-absent into the SAME 9 tables from 3
    // different legacy generations, and whichever runs first silently "wins" any shared key.
    // Business decision: Phase 5 must win. Two things preserve that here:
    // (1) SeqNo ordering: the registry places DXP-P5 (seq 1-9) before DXP-P1 (seq 11/23-30) and
    //     DXP-P3 (seq 13/31-38) - a whole-extension run always reaches this codeunit first.
    // (2) RepairPrecedence, ALWAYS run first in this OnRun (not gated), then the normal
    //     insert-only pass - ported from DXP's own RepairPrecedence procedure. This matters for
    //     data that was already migrated by DX-Payments' own background Runner (or a prior MCC
    //     run before this native-migration pass existed) with the wrong precedence: an
    //     insert-only pass alone would never touch an existing row, so re-ordering by itself is a
    //     silent no-op for anyone already migrated. RepairPrecedence force-overwrites the existing
    //     row from this (correct) source instead. Idempotent and safe to run on every invocation
    //     (upsert by primary key, same as the rest of this portfolio).
    //
    // RunTrigger=false choices below are preserved from DXP's own reviewed fix, not simplified
    // away: RepairStorePayments/RepairPaymentProcessLogs/RepairPromoBinHeader all skip OnModify()
    // deliberately (unconditional replication-counter bump on Store Payments; a ModifiedAllowed
    // guard on Promo Bin Header that errors on TransferFields-only writes since Validate never
    // ran) - see DX-Payments' own commit 0c499f0 for the original review finding.
    Permissions = tabledata "DXR_Payment Setup 54700" = R,
                  tabledata "DXR_Payment Setup" = RIM,
                  tabledata "DXR_Promotion Bin Card 54701" = R,
                  tabledata "DXR_Promotion Bin Card" = RIM,
                  tabledata "DXR_Store Payments 54702" = R,
                  tabledata "DXR_Store Payments" = RIM,
                  tabledata "DXR_Payment Process Logs 54703" = R,
                  tabledata "DXR_Payment Process Logs" = RIM,
                  tabledata "DXR_Promo Bin Header 54704" = R,
                  tabledata "DXR_Promo Bin Header" = RIM,
                  tabledata "DXR_Promo Bin ItemsLines 54705" = R,
                  tabledata "DXR_Promotion Bin Items Lines" = RIM,
                  tabledata "DXR_Promotion Bin Lines 54706" = R,
                  tabledata "DXR_Promotion Bin Lines" = RIM,
                  tabledata "DXR_Promotion Bin Setup 54707" = R,
                  tabledata "DXR_Promotion Bin Setup" = RIM,
                  tabledata "DXR_Error Audit Log 54708" = R,
                  tabledata "DXR_Error Audit Log" = RIM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunHistoric();
    end;

    procedure RunSetup()
    begin
        RepairPaymentSetup();
        RepairPromotionBinSetup();
    end;

    procedure RunMaster()
    begin
        RepairPromotionBinCard();
        RepairStorePayments();
        RepairPromoBinHeader();
        RepairPromotionBinItemsLines();
        RepairPromotionBinLines();
    end;

    procedure RunHistoric()
    begin
        RepairPaymentProcessLogs();
        RepairErrorAuditLog();
    end;

    local procedure RepairPaymentSetup()
    var
        Source: Record "DXR_Payment Setup 54700";
        Dest: Record "DXR_Payment Setup";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."DXKey") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPromotionBinCard()
    var
        Source: Record "DXR_Promotion Bin Card 54701";
        Dest: Record "DXR_Promotion Bin Card";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Promo Bin Code") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairStorePayments()
    var
        Source: Record "DXR_Store Payments 54702";
        Dest: Record "DXR_Store Payments";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."DX Store No.", Source."DX Pos Terminal No.", Source."DX Receipt No.", Source."DX Approval") then begin
                    Dest.TransferFields(Source, false);
                    // RunTrigger = false: OnModify() unconditionally bumps "DX Replication Counter" -
                    // a side effect a raw precedence-correction upsert should not trigger (see header
                    // comment, ported from DX-Payments' own reviewed fix).
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPaymentProcessLogs()
    var
        Source: Record "DXR_Payment Process Logs 54703";
        Dest: Record "DXR_Payment Process Logs";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Entry No.") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPromoBinHeader()
    var
        Source: Record "DXR_Promo Bin Header 54704";
        Dest: Record "DXR_Promo Bin Header";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."No.") then begin
                    Dest.TransferFields(Source, false);
                    // RunTrigger = false: OnModify() has a "ModifiedAllowed" guard that errors on any
                    // modify of an already-Enabled promotion whose Status field wasn't changed via
                    // Validate (see header comment, ported from DX-Payments' own reviewed fix).
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPromotionBinItemsLines()
    var
        Source: Record "DXR_Promo Bin ItemsLines 54705";
        Dest: Record "DXR_Promotion Bin Items Lines";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Offer No.", Source."Line No.") then begin
                    Dest.TransferFields(Source, false);
                    Dest.SetSkipModifyFlag(true); // no reevaluar reglas del header al reparar historico
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.SetSkipModifyFlag(true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPromotionBinLines()
    var
        Source: Record "DXR_Promotion Bin Lines 54706";
        Dest: Record "DXR_Promotion Bin Lines";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Offer No.", Source."Bin Code") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairPromotionBinSetup()
    var
        Source: Record "DXR_Promotion Bin Setup 54707";
        Dest: Record "DXR_Promotion Bin Setup";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Key") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure RepairErrorAuditLog()
    var
        Source: Record "DXR_Error Audit Log 54708";
        Dest: Record "DXR_Error Audit Log";
    begin
        if Source.FindSet() then
            repeat
                if Dest.Get(Source."Entry No.") then begin
                    Dest.TransferFields(Source, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;
}
