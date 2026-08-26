// #if not ESCUDEA and not BCDX
// codeunit 60151 "DXR MCC Bellon Migr Phase7"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 7 TabExt" (56124) -> "Bellon Upgrade Process".MigrateAllTableExtIdRestore283(). ~46
//     // tableextensions had their "_BE_DXR" field renumbered AND renamed in place (suffix "_BE_DXR"
//     // -> "_DXR", same field declaration edited directly, no data migration) by the same global
//     // renumbering commit, orphaning any value stored under the original ID on a tenant not yet
//     // republished. The original field was restored at its true original ID with an "_Old" suffix;
//     // this phase bridges old -> new, same row, same table. Excludes Customer/Item (Phase 5),
//     // the Sales/Purchase Header family (Phase 3), Contact (Phase 8, verified NOT colliding - see
//     // that codeunit's header comment) and Transfer Header (Phase 9).
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-TableExtIdRestore283') then
//             exit;

//         MigrateAllTableExtIdRestore283();

//         UpgradeTag.SetUpgradeTag('DXR-TableExtIdRestore283');
//     end;

//     local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
//     var
//         CandidateField: FieldRef;
//         SourceField: FieldRef;
//         TargetField: FieldRef;
//         FieldIndex: Integer;
//         SourceFound: Boolean;
//         TargetFound: Boolean;
//     begin
//         // Resolve the published identities once through metadata, then copy by the resolved field
//         // names. This avoids direct Field(ID) dereferencing and validates the physical types.
//         for FieldIndex := 1 to RecRef.FieldCount() do begin
//             CandidateField := RecRef.FieldIndex(FieldIndex);
//             if CandidateField.Number() = OldFieldNo then begin
//                 SourceField := CandidateField;
//                 SourceFound := true;
//             end;
//             if CandidateField.Number() = NewFieldNo then begin
//                 TargetField := CandidateField;
//                 TargetFound := true;
//             end;
//         end;
//         if not SourceFound or not TargetFound then
//             exit;
//         if (SourceField.Class() <> FieldClass::Normal) or
//            (TargetField.Class() <> FieldClass::Normal) or
//            (SourceField.Type() <> TargetField.Type())
//         then
//             exit;

//         SourceField := RecRef.Field(SourceField.Name());
//         TargetField := RecRef.Field(TargetField.Name());
//         TargetField.Value := SourceField.Value();
//     end;

//     local procedure MigrateAllTableExtIdRestore283()
//     begin
//         MigrateTableExt_ApprovalEntryIdRestore();
//         MigrateTableExt_AssemblySetupIdRestore();
//         MigrateTableExt_BankAccReconciliationIdRestore();
//         MigrateTableExt_BankAccReconciliationLineIdRestore();
//         MigrateTableExt_BankAccountIdRestore();
//         MigrateTableExt_BankAccountLedgerEntryIdRestore();
//         MigrateTableExt_CheckLedgerEntryIdRestore();
//         MigrateTableExt_CompanyInformationIdRestore();
//         MigrateTableExt_CountryRegionIdRestore();
//         MigrateTableExt_CurrencyIdRestore();
//         MigrateTableExt_CurrencyExchangeRateIdRestore();
//         MigrateTableExt_CustLedgerEntryIdRestore();
//         MigrateTableExt_CustomerPriceGroupIdRestore();
//         MigrateTableExt_GenJournalBatchIdRestore();
//         MigrateTableExt_GenJournalLineIdRestore();
//         MigrateTableExt_GenProductPostingGroupIdRestore();
//         MigrateTableExt_GeneralLedgerSetupIdRestore();
//         MigrateTableExt_IssuedReminderHeaderIdRestore();
//         MigrateTableExt_ItemCategoryIdRestore();
//         MigrateTableExt_ItemChargeAssignmentPurchIdRestore();
//         MigrateTableExt_ItemSpecialGroupsIdRestore();
//         MigrateTableExt_ListadoRecibodeIngresoIdRestore();
//         MigrateTableExt_LocationIdRestore();
//         MigrateTableExt_MemberContactIdRestore();
//         MigrateTableExt_MemberPointOfferIdRestore();
//         MigrateTableExt_NCFSetupIdRestore();
//         MigrateTableExt_PaymentMethodIdRestore();
//         MigrateTableExt_PeriodicDiscountIdRestore();
//         MigrateTableExt_PostedStatementIdRestore();
//         MigrateTableExt_ProductGroupIdRestore();
//         MigrateTableExt_PurchCommentLineIdRestore();
//         MigrateTableExt_PurchCommentLineArchiveIdRestore();
//         MigrateTableExt_PurchInvLineIdRestore();
//         MigrateTableExt_ReasonCodeTableExtIdRestore();
//         MigrateTableExt_ReplenJournalLinesIdRestore();
//         MigrateTableExt_ReplenTemplateIdRestore();
//         MigrateTableExt_RetailSetupIdRestore();
//         MigrateTableExt_RetailUserIdRestore();
//         MigrateTableExt_SalesPriceIdRestore();
//         MigrateTableExt_SalesReceivablesSetupIdRestore();
//         MigrateTableExt_SalesTypeIdRestore();
//         MigrateTableExt_SalespersonPurchaserIdRestore();
//         MigrateTableExt_ShiptoAddressIdRestore();
//         MigrateTableExt_StatementIdRestore();
//         MigrateTableExt_StoreIdRestore();
//         MigrateTableExt_TariffNumberIdRestore();
//         MigrateTableExt_TenderTypeIdRestore();
//         MigrateTableExt_TransSalesEntryIdRestore();
//         MigrateTableExt_TransactionHeaderIdRestore();
//         MigrateTableExt_TransferReceiptHeaderIdRestore();
//         MigrateTableExt_TransferShipmentHeaderIdRestore();
//         MigrateTableExt_UserSetupIdRestore();
//         MigrateTableExt_ValueEntryIdRestore();
//         MigrateTableExt_VendorIdRestore();
//         MigrateTableExt_WarehouseReceiptLineIdRestore();
//     end;

//     local procedure MigrateTableExt_ApprovalEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Approval Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52002, 52787); // ID_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_AssemblySetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Assembly Setup");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52001, 52787); // Tolerance%_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_BankAccReconciliationIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Bank Acc. Reconciliation");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Extracto Bancario_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_BankAccReconciliationLineIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Bank Acc. Reconciliation Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52001, 52787); // Extracto Bancario_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_BankAccountIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Bank Account");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50003, 52787); // Cod. Proveedor Bco._Old
//                 CopyFieldIfExists(RecRef, 50004, 52788); // Account No._Old
//                 CopyFieldIfExists(RecRef, 50005, 52789); // Amount In Payload_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_BankAccountLedgerEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Bank Account Ledger Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Fecha Registro 2_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CheckLedgerEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Check Ledger Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50009, 52787); // Recibido Por_Old
//                 CopyFieldIfExists(RecRef, 50010, 52788); // Recibido Por Cedula_Old
//                 CopyFieldIfExists(RecRef, 50011, 52789); // Hora Entrega_Old
//                 CopyFieldIfExists(RecRef, 50012, 52790); // No. Recibo_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CompanyInformationIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Company Information");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Encargado Retenciones_Old
//                 CopyFieldIfExists(RecRef, 50003, 52788); // Posicion Encargado Ret._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CountryRegionIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Country/Region");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50003, 52787); // Obsolete 11123302_Old
//                 CopyFieldIfExists(RecRef, 50004, 52788); // Obsolete 11123303_Old
//                 CopyFieldIfExists(RecRef, 50005, 52789); // 2-Digit ISO Code_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CurrencyIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Currency");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Accepted bpd_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CurrencyExchangeRateIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Currency Exchange Rate");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Tasa Banco Central_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CustLedgerEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Cust. Ledger Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50004, 52788); // No. Authorizacion_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_CustomerPriceGroupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Customer Price Group");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Global Sales Code_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_GenJournalBatchIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Gen. Journal Batch");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50004, 52787); // Pago Electronico_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_GenJournalLineIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Gen. Journal Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50055, 52787); // Pago Electronico_Old
//                 CopyFieldIfExists(RecRef, 50056, 52788); // IsRecaudo_Old
//                 CopyFieldIfExists(RecRef, 50057, 52789); // ePAGOS_Old
//                 CopyFieldIfExists(RecRef, 50058, 52790); // VendorPay No._Old
//                 CopyFieldIfExists(RecRef, 50059, 52791); // Only Two Dimensions_Old
//                 CopyFieldIfExists(RecRef, 50060, 52792); // No. Authorizacion_Old
//                 CopyFieldIfExists(RecRef, 50061, 52793); // Fecha Registro2_Old
//                 CopyFieldIfExists(RecRef, 50062, 52794); // Posting Exch. Entry No._Old
//                 CopyFieldIfExists(RecRef, 50063, 52795); // Posting Exch. Line No._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_GenProductPostingGroupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Gen. Product Posting Group");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Internal Consumption_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_GeneralLedgerSetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"General Ledger Setup");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Fecha Inicio AJCOSTO_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_IssuedReminderHeaderIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Issued Reminder Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50004, 52788); // Remaining Amount 2_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ItemCategoryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Item Category");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // % Comision_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ItemChargeAssignmentPurchIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Item Charge Assignment (Purch)");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Monto Cargo Liq._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ItemSpecialGroupsIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Item Special Groups");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // % Comision_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ListadoRecibodeIngresoIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(52132); // DXR_Cash Journal Receipt List (Access = Internal in DR-Localization)
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50006, 52787); // Documento Registrado_Old
//                 CopyFieldIfExists(RecRef, 50008, 52789); // Fecha Vencimiento_Old
//                 CopyFieldIfExists(RecRef, 50010, 52791); // IsRecaudo_Old
//                 CopyFieldIfExists(RecRef, 50011, 52792); // No. Authorizacion_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_LocationIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Location");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50006, 52787); // Req. Transport_Old
//                 CopyFieldIfExists(RecRef, 50007, 52788); // Existencia Ventas_Old
//                 CopyFieldIfExists(RecRef, 50008, 52789); // Transito Internacional_Old
//                 CopyFieldIfExists(RecRef, 50009, 52790); // Req. Cod. Audit Transf_Old
//                 CopyFieldIfExists(RecRef, 50010, 52791); // Visible in Trafico_Old
//                 CopyFieldIfExists(RecRef, 50011, 52792); // Req. Cod. Pos. & Neg._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_MemberContactIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Member Contact");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50006, 52787); // Cedula_Old
//                 CopyFieldIfExists(RecRef, 50007, 52788); // Newsletter_Old
//                 CopyFieldIfExists(RecRef, 50008, 52789); // Profesion_Old
//                 CopyFieldIfExists(RecRef, 50009, 52790); // Area de Trabajo_Old
//                 CopyFieldIfExists(RecRef, 50010, 52791); // Cantidad De Hijos_Old
//                 CopyFieldIfExists(RecRef, 50011, 52792); // Sucursal Preferida_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_MemberPointOfferIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Member Point Offer");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50004, 52787); // isTickets_Old
//                 CopyFieldIfExists(RecRef, 50005, 52788); // Promotion Status_Old
//                 CopyFieldIfExists(RecRef, 50006, 52789); // Multiplier for members_Old
//                 CopyFieldIfExists(RecRef, 50007, 52790); // Calc. Type_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_NCFSetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(52179); // DXR_NCF Setup (Access = Internal in DR-Localization)
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50003, 52787); // Grupo Contable BS_Old
//                 CopyFieldIfExists(RecRef, 50004, 52788); // Legal Tip %_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PaymentMethodIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Payment Method");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50006, 52787); // Payment Processor_Old
//                 CopyFieldIfExists(RecRef, 50007, 52788); // Prioridad_Old
//                 CopyFieldIfExists(RecRef, 50008, 52789); // Contado_Old
//                 CopyFieldIfExists(RecRef, 50009, 52790); // Tipo Venta_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PeriodicDiscountIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Periodic Discount");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50018, 52794); // Global_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PostedStatementIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Posted Statement");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Listo para Registrar_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ProductGroupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Retail Product Group");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Block, Sand And Cement_Old
//                 CopyFieldIfExists(RecRef, 50003, 52788); // Comision_Cobro_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PurchCommentLineIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Comment Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Comentario Extendido_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PurchCommentLineArchiveIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Comment Line Archive");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Comentario Extendido_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_PurchInvLineIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Inv. Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50018, 52787); // Liquidacion_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ReasonCodeTableExtIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Reason Code");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // GroupTransport_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ReplenJournalLinesIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Replen. Journal Lines");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50032, 52787); // Almacen Destino_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ReplenTemplateIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Replen. Template");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50032, 52787); // Almacen Destino_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_RetailSetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Retail Setup");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50027, 52787); // Withhold VAT Refund_Old
//                 CopyFieldIfExists(RecRef, 50028, 52788); // VAT Bus. Posting Group_Old
//                 CopyFieldIfExists(RecRef, 50029, 52789); // VAT Prod. Posting Group_Old
//                 CopyFieldIfExists(RecRef, 50030, 52790); // Days Limit_Old
//                 CopyFieldIfExists(RecRef, 50031, 52791); // Sales Type_Old
//                 CopyFieldIfExists(RecRef, 50032, 52792); // Validar Salida POS_Old
//                 CopyFieldIfExists(RecRef, 50033, 52793); // Bloq camb de lin MKP_Old
//                 CopyFieldIfExists(RecRef, 50034, 52794); // Impr por Descripcion_Old
//                 CopyFieldIfExists(RecRef, 50035, 52795); // Cod Barras en Copias_Old
//                 CopyFieldIfExists(RecRef, 50036, 52796); // No Valid Prec Cliente_Old
//                 CopyFieldIfExists(RecRef, 50037, 52797); // Permitir Descuentos N/C_Old
//                 CopyFieldIfExists(RecRef, 50038, 52798); // Send Trans. Sales Entry_Old
//                 CopyFieldIfExists(RecRef, 50039, 52799); // Control SPO Cte Exon_Old
//                 CopyFieldIfExists(RecRef, 50040, 52800); // Cantidades Barcodes_Old
//                 CopyFieldIfExists(RecRef, 50041, 52801); // Env correo Ventas/Devol_Old
//                 CopyFieldIfExists(RecRef, 50042, 52802); // Terminos Devoluciones_Old
//                 CopyFieldIfExists(RecRef, 50043, 52803); // Prefijo Pedidos POS TMP_Old
//                 CopyFieldIfExists(RecRef, 50044, 52804); // Proveedor_Old
//                 CopyFieldIfExists(RecRef, 50045, 52805); // USD Currency Code_Old
//                 CopyFieldIfExists(RecRef, 50046, 52806); // Days to Reprint_Old
//                 CopyFieldIfExists(RecRef, 50047, 52807); // Allow Days to Reprint_Old
//                 CopyFieldIfExists(RecRef, 50048, 52808); // Ruta Api Email_Old
//                 CopyFieldIfExists(RecRef, 50049, 52809); // FileServerName_Old
//                 CopyFieldIfExists(RecRef, 50050, 52810); // NotAllowReprintReturn_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_RetailUserIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Retail User");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Almacen Despacho_Old
//                 CopyFieldIfExists(RecRef, 50003, 52788); // Filtrar Exist Ventas_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_SalesPriceIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Price");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50054, 52788); // Markup % Without TAX_Old
//                 CopyFieldIfExists(RecRef, 50055, 52789); // Markup % CP_Old
//                 CopyFieldIfExists(RecRef, 50056, 52790); // Visible in Webshop_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_SalesReceivablesSetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales & Receivables Setup");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // STD POS VAT Bus Pst Grp_Old
//                 CopyFieldIfExists(RecRef, 50003, 52788); // STD POS Dflt Doc Copies_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_SalesTypeIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Sales Type");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Venta Ex. ITBIS_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_SalespersonPurchaserIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Salesperson/Purchaser");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50007, 52787); // Gestor_CXP_Old
//                 CopyFieldIfExists(RecRef, 50008, 52788); // Comisiona_Old
//                 CopyFieldIfExists(RecRef, 50009, 52789); // Tipo Comision_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ShiptoAddressIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Ship-to Address");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Latitud_Old
//                 CopyFieldIfExists(RecRef, 50003, 52788); // Longitud_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_StatementIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Statement");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50001, 52787); // Listo para Registrar_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_StoreIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC STORE");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50010, 52787); // Cod. Cliente Contado_Old
//                 CopyFieldIfExists(RecRef, 50011, 52788); // No Serie 3er Party Item_Old
//                 CopyFieldIfExists(RecRef, 50012, 52789); // Address 3_Old
//                 CopyFieldIfExists(RecRef, 50013, 52790); // Utiliza NCF Unico_Old
//                 CopyFieldIfExists(RecRef, 50014, 52791); // Print Header Doc._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TariffNumberIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Tariff Number");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50003, 52787); // % Arancel_Old
//                 CopyFieldIfExists(RecRef, 50004, 52788); // ISC_Old
//                 CopyFieldIfExists(RecRef, 50005, 52789); // % Selectivo_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TenderTypeIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Tender Type");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50008, 52787); // IsCreditMemo_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TransSalesEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Trans. Sales Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Autorizador_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TransactionHeaderIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"LSC Transaction Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50037, 52787); // No. Ticket_Old
//                 CopyFieldIfExists(RecRef, 50038, 52788); // Email Transaction_Old
//                 CopyFieldIfExists(RecRef, 50039, 52789); // Fecha Expiracion NCF_Old
//                 CopyFieldIfExists(RecRef, 50040, 52790); // Tipo Identificacion_Old
//                 CopyFieldIfExists(RecRef, 50041, 52791); // Sell-to Contact_Old
//                 CopyFieldIfExists(RecRef, 50042, 52792); // Aplica Transportacion_Old
//                 CopyFieldIfExists(RecRef, 50043, 52793); // Addl Currency Code_Old
//                 CopyFieldIfExists(RecRef, 50044, 52794); // Addl Currency Factor_Old
//                 CopyFieldIfExists(RecRef, 50045, 52795); // Print Header Doc_Old
//                 CopyFieldIfExists(RecRef, 50046, 52796); // Banco Central Cur Fctr_Old
//                 CopyFieldIfExists(RecRef, 50047, 52797); // Qty Tickets_Old
//                 CopyFieldIfExists(RecRef, 50048, 52798); // Promotion Tickets_Old
//                 CopyFieldIfExists(RecRef, 50049, 52799); // Order No._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TransferReceiptHeaderIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Transfer Receipt Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50011, 52787); // Order User Id_Old
//                 CopyFieldIfExists(RecRef, 50012, 52788); // Order Date Created_Old
//                 CopyFieldIfExists(RecRef, 50013, 52789); // Receipt User ID_Old
//                 CopyFieldIfExists(RecRef, 50014, 52790); // Pre Receive Ref No_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_TransferShipmentHeaderIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Transfer Shipment Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50009, 52787); // Order User Id_Old
//                 CopyFieldIfExists(RecRef, 50010, 52788); // Order Date Created_Old
//                 CopyFieldIfExists(RecRef, 50011, 52789); // Shipment User ID_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_UserSetupIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"User Setup");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50025, 52787); // Entrega Cheques_Old
//                 CopyFieldIfExists(RecRef, 50026, 52788); // Grupo Precios Tope_Old
//                 CopyFieldIfExists(RecRef, 50027, 52789); // Ilimitado_Old
//                 CopyFieldIfExists(RecRef, 50028, 52790); // Filtrar Por Vendedor_Old
//                 CopyFieldIfExists(RecRef, 50029, 52791); // Create Shipments_Old
//                 CopyFieldIfExists(RecRef, 50030, 52792); // Invoice Shipments_Old
//                 CopyFieldIfExists(RecRef, 50031, 52793); // User Hierarchy_Old
//                 CopyFieldIfExists(RecRef, 50033, 52795); // Filtrar Cartera Cte_Old
//                 CopyFieldIfExists(RecRef, 50034, 52796); // Permit Tienda Dif a IF_Old
//                 CopyFieldIfExists(RecRef, 50035, 52797); // Tipo Segmento_Old
//                 CopyFieldIfExists(RecRef, 50036, 52798); // Aprrove Int Consump_Old
//                 CopyFieldIfExists(RecRef, 50037, 52799); // Create Int Consump_Old
//                 CopyFieldIfExists(RecRef, 50038, 52800); // Almacen Consumo Interno_Old
//                 CopyFieldIfExists(RecRef, 50039, 52801); // Departamento - Discr_Old
//                 CopyFieldIfExists(RecRef, 50040, 52802); // Crear Ajustes - Discr_Old
//                 CopyFieldIfExists(RecRef, 50041, 52803); // Post Int Consumption_Old
//                 CopyFieldIfExists(RecRef, 50042, 52804); // Excl Filtro DptoDiscr_Old
//                 CopyFieldIfExists(RecRef, 50043, 52805); // Filtrar Usu Reimpresion_Old
//                 CopyFieldIfExists(RecRef, 50044, 52806); // Modify Int Consump_Old
//                 CopyFieldIfExists(RecRef, 50045, 52807); // SendAppr  Int Consump_Old
//                 CopyFieldIfExists(RecRef, 50046, 52808); // Order to Retail Order_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_ValueEntryIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Value Entry");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50003, 52787); // Correccion Int._Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_VendorIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Vendor");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50034, 52787); // Teléfono 2_Old
//                 CopyFieldIfExists(RecRef, 50035, 52788); // Vendedor_Old
//                 CopyFieldIfExists(RecRef, 50036, 52789); // Vendedor email_Old
//                 CopyFieldIfExists(RecRef, 50037, 52790); // Vendedor Celular_Old
//                 CopyFieldIfExists(RecRef, 50046, 52799); // Apartado Postal_Old
//                 CopyFieldIfExists(RecRef, 50047, 52800); // Sector_Old
//                 CopyFieldIfExists(RecRef, 50053, 52806); // FechaCreacion_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateTableExt_WarehouseReceiptLineIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Warehouse Receipt Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50002, 52787); // Almacen Destino_Old
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;
// }

// #endif
