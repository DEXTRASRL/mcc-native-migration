codeunit 60080 "DXR MCC DXP Migr Phase1"
{
    // Native local migration (2026-08-23, per user directive to stop delegating via .Run() and
    // instead have MCC perform the actual copy itself): ported verbatim from DX-Payments' own
    // "DXR_DXP_Migr_Phase1_Tables".Run() - copies the 9 legacy tables ("DX Payment Setup" etc.)
    // to their DXR_ clones (DXR-P1 concepts, seq 11/23-30). Typed Record TransferFields, one
    // procedure per table, insert-only-if-existing-by-primary-key (idempotent, matches the
    // original exactly). Dropped: DXP's own Upgrade Tag / "DXR_DXP_Internal_Migr_Status"
    // bookkeeping - MCC tracks completion via its own Concept row counts, not upgrade tags.
    //
    // ORDERING NOTE (see "DXR MCC DXP Migr Phase5" for the full precedence rationale): the
    // registry's own Sequence No. values already place DXP-P5 (seq 1-9) before DXP-P1 (seq
    // 11/23-30) - a whole-extension run reaches Phase 5 first, exactly matching the business
    // decision (Phase 5 = most recent generation = source of truth) this session already fixed
    // once in DX-Payments' own repo. Not re-implementing DXP's own Runner's Phase2/3-depend-on-
    // Phase1-tag guard here: that was an orchestration nicety (avoid marking a dependent phase
    // "complete" if Phase 1 partially failed), not a data-correctness rule - each phase's own
    // per-row insert-only-if-absent logic is independently safe regardless of Phase 1's outcome.
    Permissions = tabledata "DX Payment Setup" = R,
                  tabledata "DXR_Payment Setup" = RIM,
                  tabledata "DX Promotion Bin Card" = R,
                  tabledata "DXR_Promotion Bin Card" = RIM,
                  tabledata "Store Payments DX" = R,
                  tabledata "DXR_Store Payments" = RIM,
                  tabledata "Payment Process Logs" = R,
                  tabledata "DXR_Payment Process Logs" = RIM,
                  tabledata "DX Promo Bin Header" = R,
                  tabledata "DXR_Promo Bin Header" = RIM,
                  tabledata "DX Promotion Bin Items Lines" = R,
                  tabledata "DXR_Promotion Bin Items Lines" = RIM,
                  tabledata "DX Promotion Bin Lines" = R,
                  tabledata "DXR_Promotion Bin Lines" = RIM,
                  tabledata "DX Promotion Bin Setup" = R,
                  tabledata "DXR_Promotion Bin Setup" = RIM,
                  tabledata "DX Error Audit Log" = R,
                  tabledata "DXR_Error Audit Log" = RIM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunHistoric();
    end;

    procedure RunSetup()
    begin
        MigratePaymentSetup();
        MigratePromotionBinSetup();
    end;

    procedure RunMaster()
    begin
        MigratePromotionBinCard();
        MigrateStorePayments();
        MigratePromoBinHeader();
        MigratePromotionBinItemsLines();
        MigratePromotionBinLines();
    end;

    procedure RunHistoric()
    begin
        MigratePaymentProcessLogs();
        MigrateErrorAuditLog();
    end;

    local procedure MigratePaymentSetup()
    var
        Source: Record "DX Payment Setup";
        Dest: Record "DXR_Payment Setup";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."DXKey") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePromotionBinCard()
    var
        Source: Record "DX Promotion Bin Card";
        Dest: Record "DXR_Promotion Bin Card";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Promo Bin Code") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateStorePayments()
    var
        Source: Record "Store Payments DX";
        Dest: Record "DXR_Store Payments";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."DX Store No.", Source."DX Pos Terminal No.", Source."DX Receipt No.", Source."DX Approval") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePaymentProcessLogs()
    var
        Source: Record "Payment Process Logs";
        Dest: Record "DXR_Payment Process Logs";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Entry No.") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePromoBinHeader()
    var
        Source: Record "DX Promo Bin Header";
        Dest: Record "DXR_Promo Bin Header";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."No.") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePromotionBinItemsLines()
    var
        Source: Record "DX Promotion Bin Items Lines";
        Dest: Record "DXR_Promotion Bin Items Lines";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Offer No.", Source."Line No.") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.SetSkipModifyFlag(true); // no reevaluar reglas del header al migrar historico
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePromotionBinLines()
    var
        Source: Record "DX Promotion Bin Lines";
        Dest: Record "DXR_Promotion Bin Lines";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Offer No.", Source."Bin Code") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigratePromotionBinSetup()
    var
        Source: Record "DX Promotion Bin Setup";
        Dest: Record "DXR_Promotion Bin Setup";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Key") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(true);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateErrorAuditLog()
    var
        Source: Record "DX Error Audit Log";
        Dest: Record "DXR_Error Audit Log";
    begin
        if Source.FindSet() then
            repeat
                if not Dest.Get(Source."Entry No.") then begin
                    Dest.Init();
                    Dest.TransferFields(Source, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;
}
