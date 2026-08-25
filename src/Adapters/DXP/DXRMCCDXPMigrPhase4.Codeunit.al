codeunit 60083 "DXR MCC DXP Migr Phase4"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase4_Legacy"
    // - copies the 9 pre-DXR legacy tables ("DX Payment Setup 54211" etc., an ID-collision-driven
    // relocation of the original legacy family) to their clean-named clones (DXP-P4 concepts, seq
    // 14-22, which themselves feed DXP-P1). Independent of Phase1/3/5 (different source family).
    Permissions = tabledata "DX Payment Setup 54211" = R,
                  tabledata "DX Payment Setup" = RIM,
                  tabledata "DX Promotion Bin Card 54212" = R,
                  tabledata "DX Promotion Bin Card" = RIM,
                  tabledata "Store Payments DX 54213" = R,
                  tabledata "Store Payments DX" = RIM,
                  tabledata "Payment Process Logs 54214" = R,
                  tabledata "Payment Process Logs" = RIM,
                  tabledata "DX Promo Bin Header 54215" = R,
                  tabledata "DX Promo Bin Header" = RIM,
                  tabledata "DX Promo Bin ItemsLines 54216" = R,
                  tabledata "DX Promotion Bin Items Lines" = RIM,
                  tabledata "DX Promotion Bin Lines 54217" = R,
                  tabledata "DX Promotion Bin Lines" = RIM,
                  tabledata "DX Promotion Bin Setup 54218" = R,
                  tabledata "DX Promotion Bin Setup" = RIM,
                  tabledata "DX Error Audit Log 54219" = R,
                  tabledata "DX Error Audit Log" = RIM;

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
        Source: Record "DX Payment Setup 54211";
        Dest: Record "DX Payment Setup";
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
        Source: Record "DX Promotion Bin Card 54212";
        Dest: Record "DX Promotion Bin Card";
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
        Source: Record "Store Payments DX 54213";
        Dest: Record "Store Payments DX";
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
        Source: Record "Payment Process Logs 54214";
        Dest: Record "Payment Process Logs";
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
        Source: Record "DX Promo Bin Header 54215";
        Dest: Record "DX Promo Bin Header";
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
        Source: Record "DX Promo Bin ItemsLines 54216";
        Dest: Record "DX Promotion Bin Items Lines";
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
        Source: Record "DX Promotion Bin Lines 54217";
        Dest: Record "DX Promotion Bin Lines";
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
        Source: Record "DX Promotion Bin Setup 54218";
        Dest: Record "DX Promotion Bin Setup";
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
        Source: Record "DX Error Audit Log 54219";
        Dest: Record "DX Error Audit Log";
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
