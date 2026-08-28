// #if not ESCUDEA and not BCDX
// codeunit 60162 "DXR MCC LSLOC Migr ToDXRLS"
// {
//     // Native local migration - ported verbatim from LS Central DR Localization's own
//     // "DXR_LS TableExt Fields Upgrade" (54510) + "DXR_LS Legacy Tables Upgrade" (54511), both
//     // Access = Internal, bundled together here under one Upgrade Tag exactly as the sibling's own
//     // Dispatcher does ('LS_TO_DXR_LS' phase: TableExtFieldsUpgrade.Execute() then
//     // LegacyTablesUpgrade.Execute(), same tag for both).
//     // Fixed 2026-08-27: these eleven were declared "= M" (Modify only) even though every procedure
//     // that touches them starts with FindSet(true), i.e. it READS first. Modify does not imply Read,
//     // and permissionset 60000 "DXR MCC" grants no foreign tabledata at all, so the only reason this
//     // has not been failing outright is an operator running as SUPER. Corrected to RM - strictly the
//     // permissions these procedures actually exercise (none of them Insert or Delete).
//     Permissions =
//         tabledata "Gen. Journal Line" = RM,
//         tabledata Item = RM,
//         tabledata "LSC Hospitality Type" = RM,
//         tabledata "LSC Label Functions" = RM,
//         tabledata "LSC POS Print Setup Header" = RM,
//         tabledata "LSC POS Terminal" = RM,
//         tabledata "LSC POS Transaction" = RM,
//         tabledata "LSC Sales Type" = RM,
//         tabledata "LSC Store" = RM,
//         tabledata "LSC Store Inventory Line" = RM,
//         tabledata "LSC Transaction Header" = RM,
//         tabledata Field = R,
//         tabledata "LSDX POS Setup" = R,
//         tabledata "DXR_LS POS Setup" = RIMD,
//         tabledata "LSDXTender Types Relation" = R,
//         tabledata "DXR_LS Tender Types Relation" = RIMD,
//         tabledata "LSDX OPOS Print Setup" = R,
//         tabledata "DXR_LS OPOS Print Setup" = RIMD,
//         tabledata "LSDX POS 607 Diagnostic" = R,
//         tabledata "DXR_LS POS 607 Diagnostic" = RIMD,
//         tabledata "LSDX LS NCF Process Reg." = R,
//         tabledata "DXR_LS NCF Process Reg." = RIMD;
// 
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-LS-MIGRATION-20260623') then
//             exit;
// 
//         TableExtFieldsExecute();
//         LegacyTablesExecute();
// 
//         UpgradeTag.SetUpgradeTag('DXR-LS-MIGRATION-20260623');
//     end;
// 
//     /// <summary>
//     /// Retroactive repair, added 2026-08-27. The ported "DXR_LS TableExt Fields Upgrade" reproduces
//     /// the real one verbatim, including two gaps in it: its field-range loops cover 54300->54500,
//     /// 54309->54509 and 54315->54515 on "LSC Transaction Header" and 54300->54500 / 54370->54510 on
//     /// "LSC POS Terminal", so twelve NCF-related pairs were never in any range and are migrated by
//     /// nothing at all - verified against Dextra_LS Central DR Localization_28.3.3.7.app, the exact
//     /// dependency symbol package this project compiles against.
//     /// Three of them ("Provider Reference_DXR", "Electronic Send Outcome_DXR",
//     /// "Reconciliation DateTime_DXR") are read in production by LSLOC's own
//     /// LSDXPOSElectronicSendOrch, so leaving them stranded loses the electronic-reconciliation
//     /// history. Another three are also written by the LSFE adapter but from LSFE's OWN fields, never
//     /// from these LSDX ones, so they do not cover this gap either.
//     /// Tag 'DXR-LS-MIGRATION-20260623' is already set in production and cannot carry this fix - a
//     /// company that already ran it would skip the repair forever - so this is a sibling step with
//     /// its own tag, called from OnRun and from every category entry point that reaches these two
//     /// tables. Every copy is "only if the destination is still blank", so it is idempotent, order
//     /// independent, and can never overwrite what the LSFE adapter or a user already wrote.
//     /// </summary>
//     procedure RepairMissingNCFFieldsIfNeeded()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-NCF-FIELDS-REPAIR-20260827') then
//             exit;
// 
//         RepairTransactionHeaderNCFFields();
//         RepairPOSTerminalAltNCFFields();
// 
//         UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-NCF-FIELDS-REPAIR-20260827');
//     end;
// 
//     local procedure RepairTransactionHeaderNCFFields()
//     var
//         TransactionHeader: Record "LSC Transaction Header";
//         Changed: Boolean;
//         RowsSinceCommit: Integer;
//     begin
//         if not TransactionHeader.FindSet(true) then
//             exit;
//         repeat
//             Changed := false;
//             if (TransactionHeader."Alternate NCF_DXR" = '') and (TransactionHeader."LSDX Alternate NCF" <> '') then begin
//                 TransactionHeader."Alternate NCF_DXR" := TransactionHeader."LSDX Alternate NCF";
//                 Changed := true;
//             end;
//             if (TransactionHeader."Alternate No. Series_DXR" = '') and (TransactionHeader."LSDX Alternate No. Series" <> '') then begin
//                 TransactionHeader."Alternate No. Series_DXR" := TransactionHeader."LSDX Alternate No. Series";
//                 Changed := true;
//             end;
//             if (not TransactionHeader."Has NCF Contingency_DXR") and TransactionHeader."LSDX Has NCF Contingency" then begin
//                 TransactionHeader."Has NCF Contingency_DXR" := true;
//                 Changed := true;
//             end;
//             if (TransactionHeader."Provider Reference_DXR" = '') and (TransactionHeader."LSDX Provider Reference" <> '') then begin
//                 TransactionHeader."Provider Reference_DXR" := TransactionHeader."LSDX Provider Reference";
//                 Changed := true;
//             end;
//             // Same enum type on both sides ("DXR_Electronic Send Outcome"), so no ordinal crossing.
//             if (TransactionHeader."Electronic Send Outcome_DXR".AsInteger() = 0) and
//                (TransactionHeader."LSDX Electronic Send Outcome".AsInteger() <> 0)
//             then begin
//                 TransactionHeader."Electronic Send Outcome_DXR" := TransactionHeader."LSDX Electronic Send Outcome";
//                 Changed := true;
//             end;
//             if (TransactionHeader."Reconciliation DateTime_DXR" = 0DT) and
//                (TransactionHeader."LSDX Reconciliation DateTime" <> 0DT)
//             then begin
//                 TransactionHeader."Reconciliation DateTime_DXR" := TransactionHeader."LSDX Reconciliation DateTime";
//                 Changed := true;
//             end;
// 
//             if Changed then
//                 TransactionHeader.Modify(false);
//             RowsSinceCommit += 1;
//             if RowsSinceCommit >= 500 then begin
//                 Commit();
//                 RowsSinceCommit := 0;
//             end;
//         until TransactionHeader.Next() = 0;
//         Commit();
//     end;
// 
//     local procedure RepairPOSTerminalAltNCFFields()
//     var
//         POSTerminal: Record "LSC POS Terminal";
//         Changed: Boolean;
//     begin
//         if not POSTerminal.FindSet(true) then
//             exit;
//         repeat
//             Changed := false;
//             if (POSTerminal."Alt. NCF Fiscal Credit_DXR" = '') and (POSTerminal."LSDX Alt. NCF Fiscal Credit" <> '') then begin
//                 POSTerminal."Alt. NCF Fiscal Credit_DXR" := POSTerminal."LSDX Alt. NCF Fiscal Credit";
//                 Changed := true;
//             end;
//             if (POSTerminal."Alt. NCF Final Consumer_DXR" = '') and (POSTerminal."LSDX Alt. NCF Final Consumer" <> '') then begin
//                 POSTerminal."Alt. NCF Final Consumer_DXR" := POSTerminal."LSDX Alt. NCF Final Consumer";
//                 Changed := true;
//             end;
//             if (POSTerminal."Alt. NCF Credit Note_DXR" = '') and (POSTerminal."LSDX Alt. NCF Credit Note" <> '') then begin
//                 POSTerminal."Alt. NCF Credit Note_DXR" := POSTerminal."LSDX Alt. NCF Credit Note";
//                 Changed := true;
//             end;
//             if (POSTerminal."Alt. NCF Governmental_DXR" = '') and (POSTerminal."LSDX Alt. NCF Governmental" <> '') then begin
//                 POSTerminal."Alt. NCF Governmental_DXR" := POSTerminal."LSDX Alt. NCF Governmental";
//                 Changed := true;
//             end;
//             if (POSTerminal."Alt. NCF Reg. Special_DXR" = '') and (POSTerminal."LSDX Alt. NCF Reg. Special" <> '') then begin
//                 POSTerminal."Alt. NCF Reg. Special_DXR" := POSTerminal."LSDX Alt. NCF Reg. Special";
//                 Changed := true;
//             end;
//             if (POSTerminal."Alt. NCF Export_DXR" = '') and (POSTerminal."LSDX Alt. NCF Export" <> '') then begin
//                 POSTerminal."Alt. NCF Export_DXR" := POSTerminal."LSDX Alt. NCF Export";
//                 Changed := true;
//             end;
// 
//             if Changed then
//                 POSTerminal.Modify(false);
//         until POSTerminal.Next() = 0;
//         Commit();
//     end;
// 
//     procedure RunPOSSetup()
//     begin
//         CopyLSDXPOSSetupToDXR();
//     end;
// 
//     procedure RunSetupFields()
//     begin
//         RepairMissingNCFFieldsIfNeeded();
//         CopyLSCHospitalityTypeFields();
//         CopyLSCLabelFunctionsFields();
//         CopyLSCPOSPrintSetupHeaderFields();
//         CopyLSCPOSTerminalFields();
//         CopyLSCSalesTypeFields();
//         CopyLSCStoreFields();
//         MigrateSameTableEnumFields();
//     end;
// 
//     procedure RunHospitalityTypeFields()
//     begin
//         CopyLSCHospitalityTypeFields();
//     end;
// 
//     procedure RunLabelFunctionsFields()
//     begin
//         CopyLSCLabelFunctionsFields();
//     end;
// 
//     procedure RunPOSPrintSetupHeaderFields()
//     begin
//         CopyLSCPOSPrintSetupHeaderFields();
//     end;
// 
//     procedure RunPOSTerminalFields()
//     begin
//         RepairMissingNCFFieldsIfNeeded();
//         CopyLSCPOSTerminalFields();
//         MigratePOSTerminalEnumFields();
//     end;
// 
//     procedure RunSalesTypeFields()
//     begin
//         CopyLSCSalesTypeFields();
//     end;
// 
//     procedure RunStoreFields()
//     begin
//         CopyLSCStoreFields();
//     end;
// 
//     procedure RunSetupRelations()
//     begin
//         CopyLSDXTenderTypesRelationToDXR();
//         CopyLSDXOPOSPrintSetupToDXR();
//     end;
// 
//     procedure RunMasterFields()
//     begin
//         CopyItemFields();
//     end;
// 
//     procedure RunAccountingFields()
//     begin
//         CopyGenJournalLineFields();
//         CopyLSCStoreInventoryLineFields();
//     end;
// 
//     procedure RunOtherFields()
//     begin
//         RepairMissingNCFFieldsIfNeeded();
//         CopyPOSTransactionOtherFields();
//         CopyTransactionHeaderOtherFields();
//     end;
// 
//     procedure RunHistoricTables()
//     begin
//         CopyStandaloneTable(Database::"LSDX POS 607 Diagnostic", Database::"DXR_LS POS 607 Diagnostic");
//         CopyStandaloneTable(Database::"LSDX LS NCF Process Reg.", Database::"DXR_LS NCF Process Reg.");
//     end;
// 
//     // ===== "DXR_LS TableExt Fields Upgrade" (54510) =====
// 
//     local procedure TableExtFieldsExecute()
//     begin
//         CopyGenJournalLineFields(); // seq2, MA
//         CopyItemFields(); // seq5, MA
//         CopyLSCHospitalityTypeFields(); // seq6, SETUP
//         CopyLSCLabelFunctionsFields(); // seq7, SETUP
//         CopyLSCPOSPrintSetupHeaderFields(); // seq8, SETUP
//         CopyLSCPOSTerminalFields(); // seq9, SETUP (2 ranges)
//         CopyPOSTransactionOtherFields(); // seq10, OTHER (2 ranges)
//         CopyLSCSalesTypeFields(); // seq11, SETUP
//         CopyLSCStoreFields(); // seq12, SETUP
//         CopyLSCStoreInventoryLineFields(); // seq13, MA
//         CopyTransactionHeaderOtherFields(); // seq14, OTHER (3 ranges)
// 
//         MigrateSameTableEnumFields(); // already typed (no RecordRef/FieldRef) - untouched
//     end;
// 
//     // ===== In-scope SETUP same-table field-range restores (LSLOC-TOLOC seq6/7/8/9/11/12) =====
//     // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
//     // Field pairs confirmed against the real compiled symbols (LSLOC's own old/new TableExts) -
//     // every source field below is ObsoleteState = Pending (not Removed), so it is still readable.
// 
//     local procedure CopyLSCHospitalityTypeFields()
//     var
//         Rec: Record "LSC Hospitality Type";
//     begin
//         if Rec.FindSet() then
//             repeat
//                 if (Rec."Void line after Bill Prin_DXR" <> Rec."LSDX Void line after Bill Prin") or
//                    (Rec."Void Tran. after Bill Prnt_DXR" <> Rec."LSDXVoid Tran. after Bill Prnt")
//                 then begin
//                     Rec."Void line after Bill Prin_DXR" := Rec."LSDX Void line after Bill Prin";
//                     Rec."Void Tran. after Bill Prnt_DXR" := Rec."LSDXVoid Tran. after Bill Prnt";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyLSCLabelFunctionsFields()
//     var
//         Rec: Record "LSC Label Functions";
//     begin
//         if Rec.FindSet() then
//             repeat
//                 if Rec."Function Description_DXR" <> Rec."LSDX Function Description" then begin
//                     Rec."Function Description_DXR" := Rec."LSDX Function Description";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyLSCPOSPrintSetupHeaderFields()
//     var
//         Rec: Record "LSC POS Print Setup Header";
//     begin
//         if Rec.FindSet() then
//             repeat
//                 if Rec."Print Voucher Loc._DXR" <> Rec."LSDX Print Voucher Loc." then begin
//                     Rec."Print Voucher Loc._DXR" := Rec."LSDX Print Voucher Loc.";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyLSCPOSTerminalFields()
//     var
//         Rec: Record "LSC POS Terminal";
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 if (Rec."No. Serie NCF Gubern._DXR" <> Rec."LSDXNo. Serie NCF Gubern.") or
//                    (Rec."No. Serie NCF Reg. Esp._DXR" <> Rec."LSDXNo. Serie NCF Reg. Esp.") or
//                    (Rec."No. Serie NCF Cred. Fiscal_DXR" <> Rec."LSDXNo. Serie NCF Cred. Fiscal") or
//                    (Rec."Ext. Cmd. NCF Cr. Fiscal_DXR" <> Rec."LSDXExt. Cmd. NCF Cr. Fiscal") or
//                    (Rec."External Cmd. NCF Guvern_DXR" <> Rec."LSDXExternal Cmd. NCF Guvern") or
//                    (Rec."Ext. Cmd. NCF Reg. Esp._DXR" <> Rec."LSDXExt. Cmd. NCF Reg. Esp.") or
//                    (Rec."No. Serie NCF Cons. Final_DXR" <> Rec."LSDXNo. Serie NCF Cons. Final") or
//                    (Rec."Ext. Cmd. NCF Cons. Final_DXR" <> Rec."LSDXExt. Cmd. NCF Cons. Final") or
//                    (Rec."NCF Nota de Credito_DXR" <> Rec."LSDXNCF Nota de Credito") or
//                    (Rec."NCF Credito U. Final_DXR" <> Rec."LSDXNCF Credito U. Final") or
//                    (Rec."NCF Credito Gubernamental_DXR" <> Rec."LSDXNCF Credito Gubernamental") or
//                    (Rec."NCF Credito Reg Especiales_DXR" <> Rec."LSDXNCF Credito Reg Especiales") or
//                    (Rec."Ext. Cmd. Nota de Credito_DXR" <> Rec."LSDXExt. Cmd. Nota de Credito")
//                 then begin
//                     Rec."No. Serie NCF Gubern._DXR" := Rec."LSDXNo. Serie NCF Gubern.";
//                     Rec."No. Serie NCF Reg. Esp._DXR" := Rec."LSDXNo. Serie NCF Reg. Esp.";
//                     Rec."No. Serie NCF Cred. Fiscal_DXR" := Rec."LSDXNo. Serie NCF Cred. Fiscal";
//                     Rec."Ext. Cmd. NCF Cr. Fiscal_DXR" := Rec."LSDXExt. Cmd. NCF Cr. Fiscal";
//                     Rec."External Cmd. NCF Guvern_DXR" := Rec."LSDXExternal Cmd. NCF Guvern";
//                     Rec."Ext. Cmd. NCF Reg. Esp._DXR" := Rec."LSDXExt. Cmd. NCF Reg. Esp.";
//                     Rec."No. Serie NCF Cons. Final_DXR" := Rec."LSDXNo. Serie NCF Cons. Final";
//                     Rec."Ext. Cmd. NCF Cons. Final_DXR" := Rec."LSDXExt. Cmd. NCF Cons. Final";
//                     Rec."NCF Nota de Credito_DXR" := Rec."LSDXNCF Nota de Credito";
//                     Rec."NCF Credito U. Final_DXR" := Rec."LSDXNCF Credito U. Final";
//                     Rec."NCF Credito Gubernamental_DXR" := Rec."LSDXNCF Credito Gubernamental";
//                     Rec."NCF Credito Reg Especiales_DXR" := Rec."LSDXNCF Credito Reg Especiales";
//                     Rec."Ext. Cmd. Nota de Credito_DXR" := Rec."LSDXExt. Cmd. Nota de Credito";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyLSCSalesTypeFields()
//     var
//         Rec: Record "LSC Sales Type";
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 if (Rec."Exento ITBIS_DXR" <> Rec."LSDX Exento ITBIS") or
//                    (Rec."POS VAT Exento_DXR" <> Rec."LSDX POS VAT Exento")
//                 then begin
//                     Rec."Exento ITBIS_DXR" := Rec."LSDX Exento ITBIS";
//                     Rec."POS VAT Exento_DXR" := Rec."LSDX POS VAT Exento";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyLSCStoreFields()
//     var
//         Rec: Record "LSC Store";
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 if (Rec."Cod. Cliente Contado_DXR" <> Rec."LSDX Cod. Cliente Contado") or
//                    (Rec."No. Serie 3er. Party Item_DXR" <> Rec."LSDX No. Serie 3er. Party Item") or
//                    (Rec."No. Serie NCF Unico_DXR" <> Rec."LSDX No. Serie NCF Unico") or
//                    (Rec."No. Serie NCF Gubern._DXR" <> Rec."LSDX No. Serie NCF Gubern.") or
//                    (Rec."No. Serie NCF Reg. Esp._DXR" <> Rec."LSDX No. Serie NCF Reg. Esp.") or
//                    (Rec."No. Serie NCF Cr. Fiscal_DXR" <> Rec."LSDX No. Serie NCF Cr. Fiscal") or
//                    (Rec."No. Serie NCF Cons. Final_DXR" <> Rec."LSDX No. Serie NCF Cons. Final") or
//                    (Rec."Address 3_DXR" <> Rec."LSDX Address 3") or
//                    (Rec."Utiliza NCF Unico_DXR" <> Rec."LSDX Utiliza NCF Unico")
//                 then begin
//                     Rec."Cod. Cliente Contado_DXR" := Rec."LSDX Cod. Cliente Contado";
//                     Rec."No. Serie 3er. Party Item_DXR" := Rec."LSDX No. Serie 3er. Party Item";
//                     Rec."No. Serie NCF Unico_DXR" := Rec."LSDX No. Serie NCF Unico";
//                     Rec."No. Serie NCF Gubern._DXR" := Rec."LSDX No. Serie NCF Gubern.";
//                     Rec."No. Serie NCF Reg. Esp._DXR" := Rec."LSDX No. Serie NCF Reg. Esp.";
//                     Rec."No. Serie NCF Cr. Fiscal_DXR" := Rec."LSDX No. Serie NCF Cr. Fiscal";
//                     Rec."No. Serie NCF Cons. Final_DXR" := Rec."LSDX No. Serie NCF Cons. Final";
//                     Rec."Address 3_DXR" := Rec."LSDX Address 3";
//                     Rec."Utiliza NCF Unico_DXR" := Rec."LSDX Utiliza NCF Unico";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     // ===== In-scope MA same-table field-range restores (LSLOC-TOLOC seq2/5/13) =====
//     // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
//     // Field pairs confirmed against the real compiled symbols (LSLOC's own old/new TableExts) -
//     // every source field below is ObsoleteState = Pending (not Removed), so it is still readable.
// 
//     local procedure CopyGenJournalLineFields()
//     var
//         Rec: Record "Gen. Journal Line";
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 if Rec."No. Ticket_DXR" <> Rec."LSDX No. Ticket" then begin
//                     Rec."No. Ticket_DXR" := Rec."LSDX No. Ticket";
//                     Rec.Modify(false);
//                     Commit();
//                 end;
//             until Rec.Next() = 0;
//     end;
// 
//     local procedure CopyItemFields()
//     var
//         MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
//         Rec: Record Item;
//         RecRef: RecordRef;
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 RecRef.GetTable(Rec);
//                 if MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Factor_DXR', 'Factor') then
//                     RecordChanged := true;
//                 PersistChangedRecord(RecRef);
//             until Rec.Next() = 0;
//         Commit();
//         RowsSinceCommit := 0;
//     end;
// 
//     local procedure CopyLSCStoreInventoryLineFields()
//     var
//         Rec: Record "LSC Store Inventory Line";
//         RowsSinceLineCommit: Integer;
//     begin
//         if Rec.FindSet(true) then
//             repeat
//                 if Rec."Recalculate Time_DXR" <> Rec."DX Recalculate Time" then begin
//                     Rec."Recalculate Time_DXR" := Rec."DX Recalculate Time";
//                     Rec.Modify(false);
//                 end;
// 
//                 RowsSinceLineCommit += 1;
//                 if RowsSinceLineCommit >= BatchSize() then begin
//                     Commit();
//                     RowsSinceLineCommit := 0;
//                 end;
//             until Rec.Next() = 0;
//         Commit();
//     end;
// 
//     // ===== In-scope OTHER same-table field-range restores (LSLOC-TOLOC seq10/14) =====
//     // Was previously RecordRef.Field(<literal field number>) over a numeric range - converted to
//     // explicit name-based pairs (via the shared MCC Master Field Resolver) so it no longer depends
//     // on the source/target fields staying at consecutive field numbers. Pairs confirmed against the
//     // real compiled symbols (LS Central DR Localization's own "LSDX POS Transaction"/"LSDXTransaction
//     // Header" (old) and "DXR_LS POS Transaction"/"DXR_LS Transaction Header" (new) tableextensions);
//     // the two Enum fields on each table (Tipo Doc. Fiscal/Tipo Identificacion) are intentionally
//     // excluded here - they are handled by MigratePOSTransactionEnumFields/
//     // MigrateTransactionHeaderEnumFields, which convert between the distinct LSDX/DXR_LS enum types.
//     local procedure CopyPOSTransactionOtherFields()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC POS Transaction");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 'RNC/Cedula_DXR', 'LSDX RNC/Cedula');
//                 CopyFieldIfExists(RecRef, 'No. Serie NCF_DXR', 'LSDX No. Serie NCF');
//                 CopyFieldIfExists(RecRef, 'Razon Social_DXR', 'LSDX Razon Social');
//                 CopyFieldIfExists(RecRef, 'VAT Amount_DXR', 'LSDX VAT Amount');
//                 CopyFieldIfExists(RecRef, 'Nombre Cliente_DXR', 'LSDX Nombre Cliente');
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;
// 
//     local procedure CopyTransactionHeaderOtherFields()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Transaction Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 'Tipo NCF_DXR', 'LSDXTipo NCF');
//                 CopyFieldIfExists(RecRef, 'NCF_DXR', 'LSDX NCF');
//                 CopyFieldIfExists(RecRef, 'NCF Afectado_DXR', 'LSDX NCF Afectado');
//                 CopyFieldIfExists(RecRef, 'Nombre_DXR', 'LSDX Nombre');
//                 CopyFieldIfExists(RecRef, 'RNC/Cedula_DXR', 'LSDX RNC/Cedula');
//                 CopyFieldIfExists(RecRef, 'NCF Unico_DXR', 'LSDX NCF Unico');
//                 CopyFieldIfExists(RecRef, 'NCF No Serie_DXR', 'LSDX NCF No Serie');
//                 CopyFieldIfExists(RecRef, 'NCF Unico Devolucion_DXR', 'LSDX NCF Unico Devolucion');
//                 CopyFieldIfExists(RecRef, 'No. Serie NCF_DXR', 'LSDX No. Serie NCF');
//                 CopyFieldIfExists(RecRef, 'Razon Social_DXR', 'LSDX Razon Social');
//                 CopyFieldIfExists(RecRef, 'Monto Propina_DXR', 'LSDX Monto Propina');
//                 CopyFieldIfExists(RecRef, 'No. Ticket_DXR', 'LSDX No. Ticket');
//                 CopyFieldIfExists(RecRef, 'Fecha Expiracion NCF_DXR', 'LSDX Fecha Expiracion NCF');
//                 CopyFieldIfExists(RecRef, 'Fiscal Printed_DXR', 'LSDX Fiscal Printed');
//                 CopyFieldIfExists(RecRef, 'Location Code_DXR', 'LSDX Location Code');
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;
// 
//     local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
//     var
//         MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
//     begin
//         if MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldName) then
//             RecordChanged := true;
//     end;
// 
//     local procedure PersistChangedRecord(var RecRef: RecordRef)
//     begin
//         if RecordChanged then
//             RecRef.Modify(false);
//         Clear(RecordChanged);
// 
//         RowsSinceCommit += 1;
//         if RowsSinceCommit >= BatchSize() then begin
//             Commit();
//             RowsSinceCommit := 0;
//         end;
//     end;
// 
//     local procedure FinishTable(var RecRef: RecordRef)
//     begin
//         RecRef.Close();
//         Commit();
//         RowsSinceCommit := 0;
//         Clear(RecordChanged);
//     end;
// 
//     local procedure BatchSize(): Integer
//     begin
//         exit(500);
//     end;
// 
//     local procedure MigrateSameTableEnumFields()
//     begin
//         MigratePOSTerminalEnumFields();
//         MigratePOSTransactionEnumFields();
//         MigrateTransactionHeaderEnumFields();
//     end;
// 
//     local procedure MigratePOSTerminalEnumFields()
//     var
//         POSTerminal: Record "LSC POS Terminal";
//     begin
//         if POSTerminal.FindSet(true) then
//             repeat
//                 POSTerminal."Ext. POS Type_DXR" := Enum::"DXR_LS POS Type".FromInteger(POSTerminal."LSDXExt. POS Type".AsInteger());
//                 POSTerminal.Modify(false);
//             until POSTerminal.Next() = 0;
//     end;
// 
//     local procedure MigratePOSTransactionEnumFields()
//     var
//         POSTransaction: Record "LSC POS Transaction";
//     begin
//         if POSTransaction.FindSet(true) then
//             repeat
//                 POSTransaction."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(POSTransaction."LSDX Tipo Doc. Fiscal".AsInteger());
//                 POSTransaction."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(POSTransaction."LSDX Tipo Identificacion".AsInteger());
//                 POSTransaction.Modify(false);
//             until POSTransaction.Next() = 0;
//     end;
// 
//     local procedure MigrateTransactionHeaderEnumFields()
//     var
//         TransactionHeader: Record "LSC Transaction Header";
//     begin
//         if TransactionHeader.FindSet(true) then
//             repeat
//                 TransactionHeader."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(TransactionHeader."LSDX Tipo Doc. Fiscal".AsInteger());
//                 TransactionHeader."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(TransactionHeader."LSDX Tipo Identificacion".AsInteger());
//                 TransactionHeader.Modify(false);
//             until TransactionHeader.Next() = 0;
//     end;
// 
//     // ===== "DXR_LS Legacy Tables Upgrade" (54511) =====
// 
//     local procedure LegacyTablesExecute()
//     begin
//         CopyLSDXPOSSetupToDXR(); // seq4, SETUP
//         CopyLSDXTenderTypesRelationToDXR(); // seq21, SETUP
//         CopyLSDXOPOSPrintSetupToDXR(); // seq22, SETUP
//         CopyStandaloneTable(Database::"LSDX POS 607 Diagnostic", Database::"DXR_LS POS 607 Diagnostic"); // seq23, HIST - out of scope
//         CopyStandaloneTable(Database::"LSDX LS NCF Process Reg.", Database::"DXR_LS NCF Process Reg."); // seq24, HIST - out of scope
//     end;
// 
//     // ===== In-scope SETUP standalone legacy-table restores (LSLOC-TOLOC seq4/21/22) =====
//     // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
//     // Both source and target tables are LSLOC's own (or standard LSC-relation) tables, confirmed
//     // NOT Access = Internal (no Access property on any of the six table objects). Field-by-field
//     // mapping confirmed 1:1 by field number against the real compiled symbols (source field N ->
//     // target field N, target name suffixed _DXR).
// 
//     local procedure CopyLSDXPOSSetupToDXR()
//     var
//         Source: Record "LSDX POS Setup";
//         Target: Record "DXR_LS POS Setup";
//         TargetExists: Boolean;
//     begin
//         if Source.FindSet() then
//             repeat
//                 TargetExists := Target.Get(Source."Key");
//                 if not TargetExists then begin
//                     Target.Init();
//                     Target."Key_DXR" := Source."Key";
//                 end;
//                 Target."Withhold VAT Refund_DXR" := Source."Withhold VAT Refund";
//                 Target."VAT Bus. Posting Group_DXR" := Source."VAT Bus. Posting Group";
//                 Target."VAT Prod. Posting Group_DXR" := Source."VAT Prod. Posting Group";
//                 Target."Days Limit_DXR" := Source."Days Limit";
//                 Target."Sales Type_DXR" := Source."Sales Type";
//                 Target."Ventas Monto 0_DXR" := Source."Ventas Monto 0";
//                 Target."Infocode NC Manual_DXR" := Source."Infocode NC Manual";
//                 Target."NCManual_DXR" := Source.NCManual;
//                 Target."Validate Suspended Trans. POS_DXR" := Source."Validate Suspended Trans. POS";
//                 Target."Use POS Localization_DXR" := Source."Use POS Localization";
//                 Target."POS in USD_DXR" := Source."POS in USD";
//                 Target."Not Allow Print Z with Trans._DXR" := Source."Not Allow Print Z with Trans.";
//                 Target."Enable Automatic Replication_DXR" := Source."Enable Automatic Replication";
//                 Target."Show Qty. Tags on POS_DXR" := Source."Show Qty. Tags on POS";
//                 Target."Show Currency Conv. in ticket_DXR" := Source."Show Currency Conv. in ticket";
//                 Target."Show DX Copy Header_DXR" := Source."Show DX Copy Header";
//                 Target."Increase Company Name Header_DXR" := Source."Increase Company Name Header";
//                 Target."Customer NCF PRIO_DXR" := Source."Customer NCF PRIO";
//                 Target."Require RNC Fiscal Credit_DXR" := Source."Require RNC Fiscal Credit";
//                 Target."Block Blank Lines in Trans._DXR" := Source."Block Blank Lines in Trans.";
//                 Target."Validate Empty Customer Name_DXR" := Source."Validate Empty Customer Name";
//                 Target."Validate 607 Fields_DXR" := Source."Validate 607 Fields";
//                 Target."Encode QR Ampersand_DXR" := Source."Encode QR Ampersand";
//                 if TargetExists then
//                     Target.Modify(false)
//                 else
//                     Target.Insert(false);
//             until Source.Next() = 0;
//     end;
// 
//     local procedure CopyLSDXTenderTypesRelationToDXR()
//     var
//         Source: Record "LSDXTender Types Relation";
//         Target: Record "DXR_LS Tender Types Relation";
//         TargetExists: Boolean;
//     begin
//         if Source.FindSet() then
//             repeat
//                 TargetExists := Target.Get(Source.Code, Source."Tender Type Code");
//                 if not TargetExists then begin
//                     Target.Init();
//                     Target."Code_DXR" := Source.Code;
//                     Target."Tender Type Code_DXR" := Source."Tender Type Code";
//                 end;
//                 Target.Description_DXR := Source.Description;
//                 if TargetExists then
//                     Target.Modify(false)
//                 else
//                     Target.Insert(false);
//             until Source.Next() = 0;
//     end;
// 
//     local procedure CopyLSDXOPOSPrintSetupToDXR()
//     var
//         Source: Record "LSDX OPOS Print Setup";
//         Target: Record "DXR_LS OPOS Print Setup";
//         TargetExists: Boolean;
//     begin
//         if Source.FindSet() then
//             repeat
//                 TargetExists := Target.Get(Source."Key");
//                 if not TargetExists then begin
//                     Target.Init();
//                     Target."Key_DXR" := Source."Key";
//                 end;
//                 Target."Print NCF_DXR" := Source."Print NCF";
//                 Target."Print Company Name_DXR" := Source."Print Company Name";
//                 Target."Print Employee and Trans_DXR" := Source."Print Employee and Trans";
//                 Target."Print Cashier_DXR" := Source."Print Cashier";
//                 Target."Print Site Name_DXR" := Source."Print Site Name";
//                 Target."LineBreakInRNC_DXR" := Source."LineBreakInRNC";
//                 Target."Print Transaction Time_DXR" := Source."Print Transaction Time";
//                 Target."LineBreakCustomerName_DXR" := Source."LineBreakCustomerName";
//                 Target."Print Qty Footer_DXR" := Source."Print Qty Footer";
//                 Target."Print Staff Sales Person_DXR" := Source."Print Staff Sales Person";
//                 Target."Staff Sales Person Label_DXR" := Source."Staff Sales Person Label";
//                 if TargetExists then
//                     Target.Modify(false)
//                 else
//                     Target.Insert(false);
//             until Source.Next() = 0;
//     end;
// 
//     /// <summary>
//     /// Fixed 2026-08-27 (CONFIRMED silent zero-row migration). This procedure resolved every target
//     /// field by NAME (TargetRef.FieldExist(SourceFieldRef.Name)). Both tables it is called with -
//     /// "LSDX POS 607 Diagnostic" -> "DXR_LS POS 607 Diagnostic" and "LSDX LS NCF Process Reg." ->
//     /// "DXR_LS NCF Process Reg." - had every destination field RENAMED with a "_DXR" suffix by the
//     /// DXR normalization, primary key included ("Entry No." -> "Entry No._DXR", "Store No." ->
//     /// "Store No._DXR"). So FieldExist returned false for the very first primary-key field, which
//     /// set AllKeyFieldsMapped := false, which hit the `exit` below on the FIRST source row: the
//     /// whole table returned having migrated ZERO rows and WITHOUT raising an error - it just looked
//     /// like an empty source. That also permanently stranded both NCF history tables, because MCC's
//     /// generic fallback (DXR MCC Fallback Migrator) resolves by name too and fails identically.
//     /// This is a regression against LSLOC's own original "DXR_LS Legacy Tables Upgrade", which
//     /// matched by field NUMBER and therefore worked.
//     /// Resolution order is now: exact name -> name + "_DXR" (the actual rename pattern) -> same
//     /// field number, and every candidate must still match on Class = Normal AND type. The mapping is
//     /// also built ONCE per table instead of being re-resolved for every field of every row.
//     /// An unmappable primary key now raises a real error instead of silently returning, so the
//     /// concept fails visibly in DXR MCC Run Log rather than reporting success over an empty copy.
//     /// </summary>
//     local procedure CopyStandaloneTable(SourceTableId: Integer; TargetTableId: Integer)
//     var
//         SourceRef: RecordRef;
//         TargetRef: RecordRef;
//         SourceKeyRef: KeyRef;
//         SourceFieldRef: FieldRef;
//         SourcePkFieldRef: FieldRef;
//         TargetFieldRef: FieldRef;
//         FieldMap: Dictionary of [Integer, Integer];
//         FieldIndex: Integer;
//         KeyFieldIndex: Integer;
//         TargetExists: Boolean;
//         BatchCount: Integer;
//     begin
//         SourceRef.Open(SourceTableId);
//         TargetRef.Open(TargetTableId);
//         BuildFieldMap(SourceRef, TargetRef, FieldMap);
// 
//         SourceKeyRef := SourceRef.KeyIndex(1);
//         for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
//             SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
//             if not FieldMap.ContainsKey(SourcePkFieldRef.Number) then begin
//                 TargetRef.Close();
//                 SourceRef.Close();
//                 Error(
//                     'No se pudo mapear el campo de clave primaria "%1" (No. %2) de la tabla %3 hacia la tabla %4: no existe ahí con ese nombre, ni con sufijo _DXR, ni con ese mismo número y tipo. La copia se detiene en vez de reportar éxito habiendo migrado 0 filas.',
//                     SourcePkFieldRef.Name, SourcePkFieldRef.Number, SourceTableId, TargetTableId);
//             end;
//         end;
// 
//         if SourceRef.FindSet(false) then
//             repeat
//                 TargetRef.Reset();
//                 for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
//                     SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
//                     TargetFieldRef := TargetRef.Field(FieldMap.Get(SourcePkFieldRef.Number));
//                     TargetFieldRef.SetRange(SourcePkFieldRef.Value);
//                 end;
// 
//                 TargetExists := TargetRef.FindFirst();
//                 if not TargetExists then
//                     TargetRef.Init();
// 
//                 for FieldIndex := 1 to SourceRef.FieldCount() do begin
//                     SourceFieldRef := SourceRef.FieldIndex(FieldIndex);
//                     if FieldMap.ContainsKey(SourceFieldRef.Number) then begin
//                         TargetFieldRef := TargetRef.Field(FieldMap.Get(SourceFieldRef.Number));
//                         TargetFieldRef.Value := SourceFieldRef.Value;
//                     end;
//                 end;
// 
//                 if TargetExists then
//                     TargetRef.Modify(false)
//                 else
//                     TargetRef.Insert(false);
// 
//                 BatchCount += 1;
//                 if BatchCount >= 100 then begin
//                     Commit();
//                     BatchCount := 0;
//                 end;
//             until SourceRef.Next() = 0;
// 
//         TargetRef.Close();
//         SourceRef.Close();
//     end;
// 
//     /// <summary>
//     /// Resolves source field number -> target field number once per table pair. Tries the exact
//     /// name first (unrenamed fields), then the "_DXR"-suffixed name (the DXR normalization's actual
//     /// rename pattern), and only then the same field number as a last resort. Every candidate must
//     /// agree on Class = Normal and on type, so a coincidentally reused field number can never write
//     /// a value into an unrelated destination field.
//     /// </summary>
//     local procedure BuildFieldMap(var SourceRef: RecordRef; var TargetRef: RecordRef; var FieldMap: Dictionary of [Integer, Integer])
//     var
//         SourceFieldRef: FieldRef;
//         TargetFieldRef: FieldRef;
//         TargetNoByName: Dictionary of [Text, Integer];
//         TargetTypeByNo: Dictionary of [Integer, Text];
//         FieldIndex: Integer;
//         TargetNo: Integer;
//         SourceName: Text;
//     begin
//         Clear(FieldMap);
// 
//         for FieldIndex := 1 to TargetRef.FieldCount() do begin
//             TargetFieldRef := TargetRef.FieldIndex(FieldIndex);
//             if (TargetFieldRef.Number < 2000000000) and (TargetFieldRef.Class = FieldClass::Normal) then begin
//                 TargetNoByName.Set(UpperCase(TargetFieldRef.Name), TargetFieldRef.Number);
//                 TargetTypeByNo.Set(TargetFieldRef.Number, Format(TargetFieldRef.Type));
//             end;
//         end;
// 
//         for FieldIndex := 1 to SourceRef.FieldCount() do begin
//             SourceFieldRef := SourceRef.FieldIndex(FieldIndex);
//             if (SourceFieldRef.Number < 2000000000) and (SourceFieldRef.Class = FieldClass::Normal) then begin
//                 SourceName := UpperCase(SourceFieldRef.Name);
//                 TargetNo := 0;
//                 if TargetNoByName.ContainsKey(SourceName) then
//                     TargetNo := TargetNoByName.Get(SourceName)
//                 else
//                     if TargetNoByName.ContainsKey(SourceName + '_DXR') then
//                         TargetNo := TargetNoByName.Get(SourceName + '_DXR')
//                     else
//                         if TargetTypeByNo.ContainsKey(SourceFieldRef.Number) then
//                             TargetNo := SourceFieldRef.Number;
// 
//                 if TargetNo <> 0 then
//                     if TargetTypeByNo.Get(TargetNo) = Format(SourceFieldRef.Type) then
//                         FieldMap.Set(SourceFieldRef.Number, TargetNo);
//             end;
//         end;
//     end;
// 
//     var
//         RecordChanged: Boolean;
//         RowsSinceCommit: Integer;
// }
// 
// #endif
// 
