codeunit 60082 "DXR MCC DXP Migr Phase3"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase3_Tables"
    // - copies the 9 "...54220" (2nd-generation, exhausted SaaS range) tables to the same DXR_
    // clones Phase1 targets (DXP-P3 concepts, seq 13/31-38). See "DXR MCC DXP Migr Phase1" for the
    // dropped-bookkeeping note and the SeqNo-ordering rationale (registry places this after
    // DXP-P5, matching the confirmed Phase-5-wins precedence decision).
    Permissions = tabledata "DXR_Payment Setup 54220" = R,
                  tabledata "DXR_Payment Setup" = RIM,
                  tabledata "DXR_Promotion Bin Card 54221" = R,
                  tabledata "DXR_Promotion Bin Card" = RIM,
                  tabledata "DXR_Store Payments 54222" = R,
                  tabledata "DXR_Store Payments" = RIM,
                  tabledata "DXR_Payment Process Logs 54223" = R,
                  tabledata "DXR_Payment Process Logs" = RIM,
                  tabledata "DXR_Promo Bin Header 54224" = R,
                  tabledata "DXR_Promo Bin Header" = RIM,
                  tabledata "DXR_Promo Bin ItemsLines 54225" = R,
                  tabledata "DXR_Promotion Bin Items Lines" = RIM,
                  tabledata "DXR_Promotion Bin Lines 54226" = R,
                  tabledata "DXR_Promotion Bin Lines" = RIM,
                  tabledata "DXR_Promotion Bin Setup 54227" = R,
                  tabledata "DXR_Promotion Bin Setup" = RIM,
                  tabledata "DXR_Error Audit Log 54228" = R,
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
        Source: Record "DXR_Payment Setup 54220";
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
        Source: Record "DXR_Promotion Bin Card 54221";
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
        Source: Record "DXR_Store Payments 54222";
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
        Source: Record "DXR_Payment Process Logs 54223";
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
        Source: Record "DXR_Promo Bin Header 54224";
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
        Source: Record "DXR_Promo Bin ItemsLines 54225";
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
        Source: Record "DXR_Promotion Bin Lines 54226";
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
        Source: Record "DXR_Promotion Bin Setup 54227";
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
        Source: Record "DXR_Error Audit Log 54228";
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
