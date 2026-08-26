// #if not ESCUDEA and not BCDX
// codeunit 60080 "DXR MCC DXP Migr Phase1"
// {
//     // Native local migration (2026-08-23, per user directive to stop delegating via .Run() and
//     // instead have MCC perform the actual copy itself): ported verbatim from DX-Payments' own
//     // "DXR_DXP_Migr_Phase1_Tables".Run() - copies the 9 legacy tables ("DX Payment Setup" etc.)
//     // to their DXR_ clones (DXR-P1 concepts, seq 11/23-30). Explicit typed field mappings, one
//     // procedure per table, insert-only-if-existing-by-primary-key (idempotent, matches the
//     // original exactly). Dropped: DXP's own Upgrade Tag / "DXR_DXP_Internal_Migr_Status"
//     // bookkeeping - MCC tracks completion via its own Concept row counts, not upgrade tags.
//     //
//     // ORDERING NOTE (see "DXR MCC DXP Migr Phase5" for the full precedence rationale): the
//     // registry's own Sequence No. values already place DXP-P5 (seq 1-9) before DXP-P1 (seq
//     // 11/23-30) - a whole-extension run reaches Phase 5 first, exactly matching the business
//     // decision (Phase 5 = most recent generation = source of truth) this session already fixed
//     // once in DX-Payments' own repo. Not re-implementing DXP's own Runner's Phase2/3-depend-on-
//     // Phase1-tag guard here: that was an orchestration nicety (avoid marking a dependent phase
//     // "complete" if Phase 1 partially failed), not a data-correctness rule - each phase's own
//     // per-row insert-only-if-absent logic is independently safe regardless of Phase 1's outcome.
//     Permissions = tabledata "DX Payment Setup" = R,
//                   tabledata "DXR_Payment Setup" = RIM,
//                   tabledata "DX Promotion Bin Card" = R,
//                   tabledata "DXR_Promotion Bin Card" = RIM,
//                   tabledata "Store Payments DX" = R,
//                   tabledata "DXR_Store Payments" = RIM,
//                   tabledata "Payment Process Logs" = R,
//                   tabledata "DXR_Payment Process Logs" = RIM,
//                   tabledata "DX Promo Bin Header" = R,
//                   tabledata "DXR_Promo Bin Header" = RIM,
//                   tabledata "DX Promotion Bin Items Lines" = R,
//                   tabledata "DXR_Promotion Bin Items Lines" = RIM,
//                   tabledata "DX Promotion Bin Lines" = R,
//                   tabledata "DXR_Promotion Bin Lines" = RIM,
//                   tabledata "DX Promotion Bin Setup" = R,
//                   tabledata "DXR_Promotion Bin Setup" = RIM,
//                   tabledata "DX Error Audit Log" = R,
//                   tabledata "DXR_Error Audit Log" = RIM;

//     trigger OnRun()
//     begin
//         RunSetup();
//         RunMaster();
//         RunAccounting();
//         RunHistoric();
//     end;

//     procedure RunSetup()
//     begin
//         MigratePaymentSetup();
//         MigratePromotionBinSetup();
//     end;

//     procedure RunMaster()
//     begin
//         MigratePromotionBinCard();
//         MigratePromoBinHeader();
//         MigratePromotionBinItemsLines();
//         MigratePromotionBinLines();
//     end;

//     procedure RunAccounting()
//     begin
//         MigrateStorePayments();
//     end;

//     procedure RunHistoric()
//     begin
//         MigratePaymentProcessLogs();
//         MigrateErrorAuditLog();
//     end;

//     local procedure MigratePaymentSetup()
//     var
//         Source: Record "DX Payment Setup";
//         Dest: Record "DXR_Payment Setup";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."DXKey") then begin
//                     Dest.Init();
//                     CopyPaymentSetupFields(Source, Dest, true);
//                     Dest.Insert(true);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePromotionBinCard()
//     var
//         Source: Record "DX Promotion Bin Card";
//         Dest: Record "DXR_Promotion Bin Card";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."Promo Bin Code") then begin
//                     Dest.Init();
//                     CopyPromotionBinCardFields(Source, Dest, true);
//                     Dest.Insert(true);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigrateStorePayments()
//     var
//         Source: Record "Store Payments DX";
//         Dest: Record "DXR_Store Payments";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."DX Store No.", Source."DX Pos Terminal No.", Source."DX Receipt No.", Source."DX Approval") then begin
//                     Dest.Init();
//                     CopyStorePaymentsFields(Source, Dest, true);
//                     Dest.Insert(true);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePaymentProcessLogs()
//     var
//         Source: Record "Payment Process Logs";
//         Dest: Record "DXR_Payment Process Logs";
//         BatchCount: Integer;
//     begin
//         if Source.FindSet(false) then
//             repeat
//                 if not Dest.Get(Source."Entry No.") then begin
//                     Dest.Init();
//                     CopyPaymentProcessLogFields(Source, Dest, true);
//                     Dest.Insert(false);
//                 end;
//                 CommitBatch(BatchCount);
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePromoBinHeader()
//     var
//         Source: Record "DX Promo Bin Header";
//         Dest: Record "DXR_Promo Bin Header";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."No.") then begin
//                     Dest.Init();
//                     CopyPromoBinHeaderFields(Source, Dest, true);
//                     Dest.Insert(true);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePromotionBinItemsLines()
//     var
//         Source: Record "DX Promotion Bin Items Lines";
//         Dest: Record "DXR_Promotion Bin Items Lines";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."Offer No.", Source."Line No.") then begin
//                     Dest.Init();
//                     CopyPromotionBinItemFields(Source, Dest, true);
//                     Dest.SetSkipModifyFlag(true); // no reevaluar reglas del header al migrar historico
//                     Dest.Insert(false);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePromotionBinLines()
//     var
//         Source: Record "DX Promotion Bin Lines";
//         Dest: Record "DXR_Promotion Bin Lines";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."Offer No.", Source."Bin Code") then begin
//                     Dest.Init();
//                     CopyPromotionBinLineFields(Source, Dest, true);
//                     Dest.Insert(false);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigratePromotionBinSetup()
//     var
//         Source: Record "DX Promotion Bin Setup";
//         Dest: Record "DXR_Promotion Bin Setup";
//     begin
//         if Source.FindSet() then
//             repeat
//                 if not Dest.Get(Source."Key") then begin
//                     Dest.Init();
//                     CopyPromotionBinSetupFields(Source, Dest, true);
//                     Dest.Insert(true);
//                 end;
//             until Source.Next() = 0;
//     end;

//     local procedure MigrateErrorAuditLog()
//     var
//         Source: Record "DX Error Audit Log";
//         Dest: Record "DXR_Error Audit Log";
//         BatchCount: Integer;
//     begin
//         if Source.FindSet(false) then
//             repeat
//                 if not Dest.Get(Source."Entry No.") then begin
//                     Dest.Init();
//                     CopyErrorAuditLogFields(Source, Dest, true);
//                     Dest.Insert(false);
//                 end;
//                 CommitBatch(BatchCount);
//             until Source.Next() = 0;
//     end;

//     local procedure CommitBatch(var BatchCount: Integer)
//     begin
//         BatchCount += 1;
//         if BatchCount < 500 then
//             exit;
//         Commit();
//         BatchCount := 0;
//     end;

//     local procedure CopyPaymentSetupFields(Source: Record "DX Payment Setup"; var Dest: Record "DXR_Payment Setup"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest.DXKey := Source.DXKey;
//         Dest.DXURLEndPoint := Source.DXURLEndPoint;
//         Dest.DXProvider := (Source.DXProvider.AsInteger());
//         Dest.DXInfocodeSetup := Source.DXInfocodeSetup;
//         Dest."DX Use Promo Bin Card" := Source."DX Use Promo Bin Card";
//         Dest."DX Visanet TokenECR" := Source."DX Visanet TokenECR";
//         Dest.viewJson := Source.viewJson;
//         Dest.FiscalPrinter := Source.FiscalPrinter;
//         Dest."Role Center" := Source."Role Center";
//         Dest."Active Logs" := Source."Active Logs";
//     end;

//     local procedure CopyPromotionBinCardFields(Source: Record "DX Promotion Bin Card"; var Dest: Record "DXR_Promotion Bin Card"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest."Promo Bin Code" := Source."Promo Bin Code";
//         Dest."Percentage %" := Source."Percentage %";
//         Dest."From Date" := Source."From Date";
//         Dest."To Date" := Source."To Date";
//         Dest.Active := Source.Active;
//     end;

//     local procedure CopyStorePaymentsFields(Source: Record "Store Payments DX"; var Dest: Record "DXR_Store Payments"; IncludePrimaryKey: Boolean)
//     var
//         SourceStream: InStream;
//         DestStream: OutStream;
//     begin
//         if IncludePrimaryKey then begin
//             Dest."DX Store No." := Source."DX Store No.";
//             Dest."DX Pos Terminal No." := Source."DX Pos Terminal No.";
//             Dest."DX Receipt No." := Source."DX Receipt No.";
//             Dest."DX Approval" := Source."DX Approval";
//         end;
//         Dest."DX Host" := Source."DX Host";
//         Dest."DX Card Type" := Source."DX Card Type";
//         Dest."DX Transaction Mode" := Source."DX Transaction Mode";
//         Dest."DX Card" := Source."DX Card";
//         Dest."DX Open Lote" := Source."DX Open Lote";
//         Dest."DX Amount" := Source."DX Amount";
//         Dest."DX Date" := Source."DX Date";
//         Dest."DX Time" := Source."DX Time";
//         Dest."DX NameTH" := Source."DX NameTH";
//         Dest."DX Terminal Number" := Source."DX Terminal Number";
//         Dest."DX Reference Number" := Source."DX Reference Number";
//         Dest."DX RRN" := Source."DX RRN";
//         Dest."DX Trade ID" := Source."DX Trade ID";
//         Dest."DX Transaction ID" := Source."DX Transaction ID";
//         Dest."DX Application Identifier" := Source."DX Application Identifier";
//         Dest."DX Cuotas" := Source."DX Cuotas";
//         Dest."DX Service Code" := Source."DX Service Code";
//         Dest."DX Status" := (Source."DX Status".AsInteger());
//         Dest."DX Line No." := Source."DX Line No.";
//         Dest."DX Close Batch" := Source."DX Close Batch";
//         Dest."Dx Total Sales" := Source."Dx Total Sales";
//         Dest."DX Sales Amount" := Source."DX Sales Amount";
//         Dest."DX Void" := Source."DX Void";
//         Dest."DX Close Time" := Source."DX Close Time";
//         Dest."DX Close Date" := Source."DX Close Date";
//         Dest."DX ITBIS" := Source."DX ITBIS";
//         Dest."DX SubTotal" := Source."DX SubTotal";
//         Dest."DX CierreZ" := Source."DX CierreZ";
//         Dest."DX Replication Counter" := Source."DX Replication Counter";
//         Dest."DX Provider" := (Source."DX Provider".AsInteger());
//         Source.CalcFields("DX Picture");
//         Source."DX Picture".CreateInStream(SourceStream);
//         Dest."DX Picture".CreateOutStream(DestStream);
//         CopyStream(DestStream, SourceStream);
//         Dest."DX Transaction No." := Source."DX Transaction No.";
//         Dest."DX DCC Indicador" := Source."DX DCC Indicador";
//         Dest."DX DCC Aceptado" := Source."DX DCC Aceptado";
//         Dest."DX DCC Percentage Margen" := Source."DX DCC Percentage Margen";
//         Dest."DX DCC Transaction Amount" := Source."DX DCC Transaction Amount";
//         Dest."DX DCC Display Rate" := Source."DX DCC Display Rate";
//         Dest."DX DCC Simbolo Moneda" := Source."DX DCC Simbolo Moneda";
//         Dest."DX DCC Reservado" := Source."DX DCC Reservado";
//         Dest."DX DCC Firma" := Source."DX DCC Firma";
//         Dest.Promocode := Source.Promocode;
//         Dest.DxOrignalAmount := Source.DxOrignalAmount;
//         Dest."DX Discount Percentage" := Source."DX Discount Percentage";
//         Dest."DX Stan" := Source."DX Stan";
//         Dest."DX TokenECR" := Source."DX TokenECR";
//         Dest."Local Currency Symbol" := Source."Local Currency Symbol";
//         Dest."DX Entry No." := Source."DX Entry No.";
//     end;

//     local procedure CopyPaymentProcessLogFields(Source: Record "Payment Process Logs"; var Dest: Record "DXR_Payment Process Logs"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest."Entry No." := Source."Entry No.";
//         Dest."Store No." := Source."Store No.";
//         Dest."POS Terminal No." := Source."POS Terminal No.";
//         Dest."Receipt No." := Source."Receipt No.";
//         Dest."Line No." := Source."Line No.";
//         Dest."Process Date" := Source."Process Date";
//         Dest."Process Time" := Source."Process Time";
//         Dest."Process Type" := Source."Process Type";
//         Dest."Process Status" := Source."Process Status";
//         Dest."Error Message" := Source."Error Message";
//         Dest.Provider := (Source.Provider.AsInteger());
//         Dest."Transaction ID" := Source."Transaction ID";
//         Dest."Authorization No." := Source."Authorization No.";
//         Dest.Amount := Source.Amount;
//         Dest."Card Type" := Source."Card Type";
//         Dest."Card Number" := Source."Card Number";
//         Dest."Batch No." := Source."Batch No.";
//         Dest."Response Code" := Source."Response Code";
//         Dest."Response Message" := Source."Response Message";
//         Dest."User ID" := Source."User ID";
//         Dest."Process Lap Time" := Source."Process Lap Time";
//     end;

//     local procedure CopyPromoBinHeaderFields(Source: Record "DX Promo Bin Header"; var Dest: Record "DXR_Promo Bin Header"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest."No." := Source."No.";
//         Dest.Description := Source.Description;
//         Dest.Status := Source.Status;
//         Dest.Priority := Source.Priority;
//         Dest."Price Group" := Source."Price Group";
//         Dest."Currency Code" := Source."Currency Code";
//         Dest."No. Series" := Source."No. Series";
//         Dest."Validation Period ID" := Source."Validation Period ID";
//         Dest."Validation Description" := Source."Validation Description";
//         Dest."Starting Date" := Source."Starting Date";
//         Dest."Ending Date" := Source."Ending Date";
//         Dest."Customer Disc. Group" := Source."Customer Disc. Group";
//         Dest."Last Date Modified" := Source."Last Date Modified";
//         Dest."Member Type" := Source."Member Type";
//         Dest."Member Value" := Source."Member Value";
//         Dest."Member Attribute" := Source."Member Attribute";
//         Dest."Member Attribute Value" := Source."Member Attribute Value";
//         Dest."Sales Type Filter" := Source."Sales Type Filter";
//         Dest."Price Group Validation" := Source."Price Group Validation";
//         Dest."Block Printing" := Source."Block Printing";
//         Dest."Buyer ID" := Source."Buyer ID";
//         Dest."Buyer Group Code" := Source."Buyer Group Code";
//         Dest."Line Specific" := Source."Line Specific";
//         Dest."Value Type" := Source."Value Type";
//         Dest.Value := Source.Value;
//         Dest."Percentage %" := Source."Percentage %";
//     end;

//     local procedure CopyPromotionBinItemFields(Source: Record "DX Promotion Bin Items Lines"; var Dest: Record "DXR_Promotion Bin Items Lines"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then begin
//             Dest."Offer No." := Source."Offer No.";
//             Dest."Line No." := Source."Line No.";
//         end;
//         Dest.Type := Source.Type;
//         Dest."No." := Source."No.";
//         Dest.Description := Source.Description;
//         Dest."Prod. Group Category" := Source."Prod. Group Category";
//         Dest."Unit of Measure" := Source."Unit of Measure";
//         Dest.Status := Source.Status;
//         Dest.Exclude := Source.Exclude;
//     end;

//     local procedure CopyPromotionBinLineFields(Source: Record "DX Promotion Bin Lines"; var Dest: Record "DXR_Promotion Bin Lines"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then begin
//             Dest."Offer No." := Source."Offer No.";
//             Dest."Bin Code" := Source."Bin Code";
//         end;
//         Dest."Percentage %" := Source."Percentage %";
//         Dest."From Date" := Source."From Date";
//         Dest."To Date" := Source."To Date";
//         Dest.Active := Source.Active;
//     end;

//     local procedure CopyPromotionBinSetupFields(Source: Record "DX Promotion Bin Setup"; var Dest: Record "DXR_Promotion Bin Setup"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest."Key" := Source."Key";
//         Dest.Active := Source.Active;
//         Dest."Use Promo Bin Card" := Source."Use Promo Bin Card";
//         Dest."No. Series Promotion" := Source."No. Series Promotion";
//         Dest.RoundDiscountBin := Source.RoundDiscountBin;
//         Dest."Max Discount Allowed" := Source."Max Discount Allowed";
//     end;

//     local procedure CopyErrorAuditLogFields(Source: Record "DX Error Audit Log"; var Dest: Record "DXR_Error Audit Log"; IncludePrimaryKey: Boolean)
//     begin
//         if IncludePrimaryKey then
//             Dest."Entry No." := Source."Entry No.";
//         Dest."Created At" := Source."Created At";
//         Dest."Created Date" := Source."Created Date";
//         Dest."Created Time" := Source."Created Time";
//         Dest."Source Category" := Source."Source Category";
//         Dest."Source Name" := Source."Source Name";
//         Dest."Error Message" := Source."Error Message";
//         Dest."Store No." := Source."Store No.";
//         Dest."POS Terminal No." := Source."POS Terminal No.";
//         Dest."Receipt No." := Source."Receipt No.";
//         Dest."Line No." := Source."Line No.";
//         Dest."User ID" := Source."User ID";
//         Dest."Session ID" := Source."Session ID";
//         Dest."Transaction ID" := Source."Transaction ID";
//         Dest.Provider := (Source.Provider.AsInteger());
//         Dest.Handled := Source.Handled;
//         Dest."Additional Context" := Source."Additional Context";
//     end;
// }

// #endif
