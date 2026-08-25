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
    // guard on Promo Bin Header that errors on raw field-copy writes since Validate never
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
                    CopyPaymentSetupFields(Source, Dest, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    CopyPaymentSetupFields(Source, Dest, true);
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
                    CopyPromotionBinCardFields(Source, Dest, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    CopyPromotionBinCardFields(Source, Dest, true);
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
                    CopyStorePaymentsFields(Source, Dest, false);
                    // RunTrigger = false: OnModify() unconditionally bumps "DX Replication Counter" -
                    // a side effect a raw precedence-correction upsert should not trigger (see header
                    // comment, ported from DX-Payments' own reviewed fix).
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyStorePaymentsFields(Source, Dest, true);
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
                    CopyPaymentProcessLogFields(Source, Dest, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyPaymentProcessLogFields(Source, Dest, true);
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
                    CopyPromoBinHeaderFields(Source, Dest, false);
                    // RunTrigger = false: OnModify() has a "ModifiedAllowed" guard that errors on any
                    // modify of an already-Enabled promotion whose Status field wasn't changed via
                    // Validate (see header comment, ported from DX-Payments' own reviewed fix).
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyPromoBinHeaderFields(Source, Dest, true);
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
                    CopyPromotionBinItemFields(Source, Dest, false);
                    Dest.SetSkipModifyFlag(true); // no reevaluar reglas del header al reparar historico
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyPromotionBinItemFields(Source, Dest, true);
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
                    CopyPromotionBinLineFields(Source, Dest, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyPromotionBinLineFields(Source, Dest, true);
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
                    CopyPromotionBinSetupFields(Source, Dest, false);
                    Dest.Modify(true);
                end else begin
                    Dest.Init();
                    CopyPromotionBinSetupFields(Source, Dest, true);
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
                    CopyErrorAuditLogFields(Source, Dest, false);
                    Dest.Modify(false);
                end else begin
                    Dest.Init();
                    CopyErrorAuditLogFields(Source, Dest, true);
                    Dest.Insert(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure CopyPaymentSetupFields(Source: Record "DXR_Payment Setup 54700"; var Dest: Record "DXR_Payment Setup"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest.DXKey := Source.DXKey;
        Dest.DXURLEndPoint := Source.DXURLEndPoint;
        Dest.DXProvider := Source.DXProvider;
        Dest.DXInfocodeSetup := Source.DXInfocodeSetup;
        Dest."DX Use Promo Bin Card" := Source."DX Use Promo Bin Card";
        Dest."DX Visanet TokenECR" := Source."DX Visanet TokenECR";
        Dest.viewJson := Source.viewJson;
        Dest.FiscalPrinter := Source.FiscalPrinter;
        Dest."Role Center" := Source."Role Center";
        Dest."Active Logs" := Source."Active Logs";
    end;

    local procedure CopyPromotionBinCardFields(Source: Record "DXR_Promotion Bin Card 54701"; var Dest: Record "DXR_Promotion Bin Card"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest."Promo Bin Code" := Source."Promo Bin Code";
        Dest."Percentage %" := Source."Percentage %";
        Dest."From Date" := Source."From Date";
        Dest."To Date" := Source."To Date";
        Dest.Active := Source.Active;
    end;

    local procedure CopyStorePaymentsFields(Source: Record "DXR_Store Payments 54702"; var Dest: Record "DXR_Store Payments"; IncludePrimaryKey: Boolean)
    var
        SourceStream: InStream;
        DestStream: OutStream;
    begin
        if IncludePrimaryKey then begin
            Dest."DX Store No." := Source."DX Store No.";
            Dest."DX Pos Terminal No." := Source."DX Pos Terminal No.";
            Dest."DX Receipt No." := Source."DX Receipt No.";
            Dest."DX Approval" := Source."DX Approval";
        end;
        Dest."DX Host" := Source."DX Host";
        Dest."DX Card Type" := Source."DX Card Type";
        Dest."DX Transaction Mode" := Source."DX Transaction Mode";
        Dest."DX Card" := Source."DX Card";
        Dest."DX Open Lote" := Source."DX Open Lote";
        Dest."DX Amount" := Source."DX Amount";
        Dest."DX Date" := Source."DX Date";
        Dest."DX Time" := Source."DX Time";
        Dest."DX NameTH" := Source."DX NameTH";
        Dest."DX Terminal Number" := Source."DX Terminal Number";
        Dest."DX Reference Number" := Source."DX Reference Number";
        Dest."DX RRN" := Source."DX RRN";
        Dest."DX Trade ID" := Source."DX Trade ID";
        Dest."DX Transaction ID" := Source."DX Transaction ID";
        Dest."DX Application Identifier" := Source."DX Application Identifier";
        Dest."DX Cuotas" := Source."DX Cuotas";
        Dest."DX Service Code" := Source."DX Service Code";
        Dest."DX Status" := Source."DX Status";
        Dest."DX Line No." := Source."DX Line No.";
        Dest."DX Close Batch" := Source."DX Close Batch";
        Dest."Dx Total Sales" := Source."Dx Total Sales";
        Dest."DX Sales Amount" := Source."DX Sales Amount";
        Dest."DX Void" := Source."DX Void";
        Dest."DX Close Time" := Source."DX Close Time";
        Dest."DX Close Date" := Source."DX Close Date";
        Dest."DX ITBIS" := Source."DX ITBIS";
        Dest."DX SubTotal" := Source."DX SubTotal";
        Dest."DX CierreZ" := Source."DX CierreZ";
        Dest."DX Replication Counter" := Source."DX Replication Counter";
        Dest."DX Provider" := Source."DX Provider";
        Source.CalcFields("DX Picture");
        Source."DX Picture".CreateInStream(SourceStream);
        Dest."DX Picture".CreateOutStream(DestStream);
        CopyStream(DestStream, SourceStream);
        Dest."DX Transaction No." := Source."DX Transaction No.";
        Dest."DX DCC Indicador" := Source."DX DCC Indicador";
        Dest."DX DCC Aceptado" := Source."DX DCC Aceptado";
        Dest."DX DCC Percentage Margen" := Source."DX DCC Percentage Margen";
        Dest."DX DCC Transaction Amount" := Source."DX DCC Transaction Amount";
        Dest."DX DCC Display Rate" := Source."DX DCC Display Rate";
        Dest."DX DCC Simbolo Moneda" := Source."DX DCC Simbolo Moneda";
        Dest."DX DCC Reservado" := Source."DX DCC Reservado";
        Dest."DX DCC Firma" := Source."DX DCC Firma";
        Dest.Promocode := Source.Promocode;
        Dest.DxOrignalAmount := Source.DxOrignalAmount;
        Dest."DX Discount Percentage" := Source."DX Discount Percentage";
        Dest."DX Stan" := Source."DX Stan";
        Dest."DX TokenECR" := Source."DX TokenECR";
        Dest."Local Currency Symbol" := Source."Local Currency Symbol";
        Dest."DX Entry No." := Source."DX Entry No.";
    end;

    local procedure CopyPaymentProcessLogFields(Source: Record "DXR_Payment Process Logs 54703"; var Dest: Record "DXR_Payment Process Logs"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest."Entry No." := Source."Entry No.";
        Dest."Store No." := Source."Store No.";
        Dest."POS Terminal No." := Source."POS Terminal No.";
        Dest."Receipt No." := Source."Receipt No.";
        Dest."Line No." := Source."Line No.";
        Dest."Process Date" := Source."Process Date";
        Dest."Process Time" := Source."Process Time";
        Dest."Process Type" := Source."Process Type";
        Dest."Process Status" := Source."Process Status";
        Dest."Error Message" := Source."Error Message";
        Dest.Provider := Source.Provider;
        Dest."Transaction ID" := Source."Transaction ID";
        Dest."Authorization No." := Source."Authorization No.";
        Dest.Amount := Source.Amount;
        Dest."Card Type" := Source."Card Type";
        Dest."Card Number" := Source."Card Number";
        Dest."Batch No." := Source."Batch No.";
        Dest."Response Code" := Source."Response Code";
        Dest."Response Message" := Source."Response Message";
        Dest."User ID" := Source."User ID";
        Dest."Process Lap Time" := Source."Process Lap Time";
    end;

    local procedure CopyPromoBinHeaderFields(Source: Record "DXR_Promo Bin Header 54704"; var Dest: Record "DXR_Promo Bin Header"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest."No." := Source."No.";
        Dest.Description := Source.Description;
        Dest.Status := Source.Status;
        Dest.Priority := Source.Priority;
        Dest."Price Group" := Source."Price Group";
        Dest."Currency Code" := Source."Currency Code";
        Dest."No. Series" := Source."No. Series";
        Dest."Validation Period ID" := Source."Validation Period ID";
        Dest."Validation Description" := Source."Validation Description";
        Dest."Starting Date" := Source."Starting Date";
        Dest."Ending Date" := Source."Ending Date";
        Dest."Customer Disc. Group" := Source."Customer Disc. Group";
        Dest."Last Date Modified" := Source."Last Date Modified";
        Dest."Member Type" := Source."Member Type";
        Dest."Member Value" := Source."Member Value";
        Dest."Member Attribute" := Source."Member Attribute";
        Dest."Member Attribute Value" := Source."Member Attribute Value";
        Dest."Sales Type Filter" := Source."Sales Type Filter";
        Dest."Price Group Validation" := Source."Price Group Validation";
        Dest."Block Printing" := Source."Block Printing";
        Dest."Buyer ID" := Source."Buyer ID";
        Dest."Buyer Group Code" := Source."Buyer Group Code";
        Dest."Line Specific" := Source."Line Specific";
        Dest."Value Type" := Source."Value Type";
        Dest.Value := Source.Value;
        Dest."Percentage %" := Source."Percentage %";
    end;

    local procedure CopyPromotionBinItemFields(Source: Record "DXR_Promo Bin ItemsLines 54705"; var Dest: Record "DXR_Promotion Bin Items Lines"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then begin
            Dest."Offer No." := Source."Offer No.";
            Dest."Line No." := Source."Line No.";
        end;
        Dest.Type := Source.Type;
        Dest."No." := Source."No.";
        Dest.Description := Source.Description;
        Dest."Prod. Group Category" := Source."Prod. Group Category";
        Dest."Unit of Measure" := Source."Unit of Measure";
        Dest.Status := Source.Status;
        Dest.Exclude := Source.Exclude;
    end;

    local procedure CopyPromotionBinLineFields(Source: Record "DXR_Promotion Bin Lines 54706"; var Dest: Record "DXR_Promotion Bin Lines"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then begin
            Dest."Offer No." := Source."Offer No.";
            Dest."Bin Code" := Source."Bin Code";
        end;
        Dest."Percentage %" := Source."Percentage %";
        Dest."From Date" := Source."From Date";
        Dest."To Date" := Source."To Date";
        Dest.Active := Source.Active;
    end;

    local procedure CopyPromotionBinSetupFields(Source: Record "DXR_Promotion Bin Setup 54707"; var Dest: Record "DXR_Promotion Bin Setup"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest."Key" := Source."Key";
        Dest.Active := Source.Active;
        Dest."Use Promo Bin Card" := Source."Use Promo Bin Card";
        Dest."No. Series Promotion" := Source."No. Series Promotion";
        Dest.RoundDiscountBin := Source.RoundDiscountBin;
        Dest."Max Discount Allowed" := Source."Max Discount Allowed";
    end;

    local procedure CopyErrorAuditLogFields(Source: Record "DXR_Error Audit Log 54708"; var Dest: Record "DXR_Error Audit Log"; IncludePrimaryKey: Boolean)
    begin
        if IncludePrimaryKey then
            Dest."Entry No." := Source."Entry No.";
        Dest."Created At" := Source."Created At";
        Dest."Created Date" := Source."Created Date";
        Dest."Created Time" := Source."Created Time";
        Dest."Source Category" := Source."Source Category";
        Dest."Source Name" := Source."Source Name";
        Dest."Error Message" := Source."Error Message";
        Dest."Store No." := Source."Store No.";
        Dest."POS Terminal No." := Source."POS Terminal No.";
        Dest."Receipt No." := Source."Receipt No.";
        Dest."Line No." := Source."Line No.";
        Dest."User ID" := Source."User ID";
        Dest."Session ID" := Source."Session ID";
        Dest."Transaction ID" := Source."Transaction ID";
        Dest.Provider := Source.Provider;
        Dest.Handled := Source.Handled;
        Dest."Additional Context" := Source."Additional Context";
    end;
}
