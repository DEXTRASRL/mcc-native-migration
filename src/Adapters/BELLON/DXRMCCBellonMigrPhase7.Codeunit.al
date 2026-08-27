#if not ESCUDEA and not BCDX
codeunit 60151 "DXR MCC Bellon Migr Phase7"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 7 TabExt" (56124) -> "Bellon Upgrade Process".MigrateAllTableExtIdRestore283(). ~46
    // tableextensions had their "_BE_DXR" field renumbered AND renamed in place (suffix "_BE_DXR"
    // -> "_DXR", same field declaration edited directly, no data migration) by the same global
    // renumbering commit, orphaning any value stored under the original ID on a tenant not yet
    // republished. The original field was restored at its true original ID with an "_Old" suffix;
    // this phase bridges old -> new, same row, same table. Excludes Customer/Item (Phase 5),
    // the Sales/Purchase Header family (Phase 3), Contact (Phase 8, verified NOT colliding - see
    // that codeunit's header comment) and Transfer Header (Phase 9).
    //
    // Added 2026-08-27: this codeunit runs in background via TaskScheduler and had NO Permissions
    // property at all, despite RecRef.Open()'ing 55 tables (53 via Database::"..." literal, plus
    // "DXR_Cash Journal Receipt List" and "DXR_NCF Setup" via numeric ID - both Access = Internal
    // in DR-Localization, confirmed via that dependency's own SymbolReference.json). DXR MCC
    // PermissionSet (60000) only grants codeunit Execute and MCC's own tabledata, never
    // third-party tabledata, so a per-object Permissions block is the sole runtime access
    // mechanism in this codebase (see Phase2's own header comment). Every table here is read via
    // FindSet(true) and, when a field is copied, written back via RecRef.Modify(false) on the SAME
    // row (CopyFieldIfExists/PersistChangedRecord) - never Insert - so RM is correct for all 55.
    Permissions =
        tabledata "Approval Entry" = RM,
        tabledata "Assembly Setup" = RM,
        tabledata "Bank Acc. Reconciliation" = RM,
        tabledata "Bank Acc. Reconciliation Line" = RM,
        tabledata "Bank Account" = RM,
        tabledata "Bank Account Ledger Entry" = RM,
        tabledata "Check Ledger Entry" = RM,
        tabledata "Company Information" = RM,
        tabledata "Country/Region" = RM,
        tabledata "Currency" = RM,
        tabledata "Currency Exchange Rate" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Customer Price Group" = RM,
        tabledata "Gen. Journal Batch" = RM,
        tabledata "Gen. Journal Line" = RM,
        tabledata "Gen. Product Posting Group" = RM,
        tabledata "General Ledger Setup" = RM,
        tabledata "Issued Reminder Header" = RM,
        tabledata "Item Category" = RM,
        tabledata "Item Charge Assignment (Purch)" = RM,
        tabledata "LSC Item Special Groups" = RM,
        tabledata "DXR_Cash Journal Receipt List" = RM,
        tabledata "Location" = RM,
        tabledata "LSC Member Contact" = RM,
        tabledata "LSC Member Point Offer" = RM,
        tabledata "DXR_NCF Setup" = RM,
        tabledata "Payment Method" = RM,
        tabledata "LSC Periodic Discount" = RM,
        tabledata "LSC Posted Statement" = RM,
        tabledata "LSC Retail Product Group" = RM,
        tabledata "Purch. Comment Line" = RM,
        tabledata "Purch. Comment Line Archive" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Reason Code" = RM,
        tabledata "LSC Replen. Journal Lines" = RM,
        tabledata "LSC Replen. Template" = RM,
        tabledata "LSC Retail Setup" = RM,
        tabledata "LSC Retail User" = RM,
        tabledata "Sales Price" = RM,
        tabledata "Sales & Receivables Setup" = RM,
        tabledata "LSC Sales Type" = RM,
        tabledata "Salesperson/Purchaser" = RM,
        tabledata "Ship-to Address" = RM,
        tabledata "LSC Statement" = RM,
        tabledata "LSC STORE" = RM,
        tabledata "Tariff Number" = RM,
        tabledata "LSC Tender Type" = RM,
        tabledata "LSC Trans. Sales Entry" = RM,
        tabledata "LSC Transaction Header" = RM,
        tabledata "Transfer Receipt Header" = RM,
        tabledata "Transfer Shipment Header" = RM,
        tabledata "User Setup" = RM,
        tabledata "Value Entry" = RM,
        tabledata "Vendor" = RM,
        tabledata "Warehouse Receipt Line" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-TableExtIdRestore283-NAME-FALLBACK-20260826') then
            exit;

        MigrateAllTableExtIdRestore283();

        UpgradeTag.SetUpgradeTag('DXR-TableExtIdRestore283-NAME-FALLBACK-20260826');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        // Field numbers remain in the published schema to keep BC's RecordRef mechanisms (Field(),
        // FieldExist()) compatible, but migration lookup itself is entirely name based - same
        // resolver as Phase3 (DXR MCC Master Field Resolver), skip-if-target-already-populated.
        // Unlike Phase3 (which derives legacy-alias candidates automatically from the "_DXR"
        // suffix), every call site here passes the exact "_Old" source field name recovered from
        // this table's own tableextension source (src/Extentions/tables/*.TableExt.al in the
        // Bellon Customization app): several targets here use a "_BE_DXR" suffix instead of
        // "_DXR", or carry a trailing "." in their declared Name, so Phase3's generic
        // suffix-stripping derivation would not reliably reconstruct the matching source name for
        // every field in this codeunit's much larger and more irregular table set.
        if MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldName) then
            RecordChanged := true;
    end;

    local procedure PersistChangedRecord(var RecRef: RecordRef)
    begin
        if RecordChanged then
            RecRef.Modify(false);
        Clear(RecordChanged);

        RowsSinceCommit += 1;
        if RowsSinceCommit >= BatchSize() then begin
            Commit();
            RowsSinceCommit := 0;
        end;
    end;

    local procedure FinishTable(var RecRef: RecordRef)
    begin
        RecRef.Close();
        Commit();
        RowsSinceCommit := 0;
        Clear(RecordChanged);
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure MigrateAllTableExtIdRestore283()
    begin
        MigrateTableExt_ApprovalEntryIdRestore();
        MigrateTableExt_AssemblySetupIdRestore();
        MigrateTableExt_BankAccReconciliationIdRestore();
        MigrateTableExt_BankAccReconciliationLineIdRestore();
        MigrateTableExt_BankAccountIdRestore();
        MigrateTableExt_BankAccountLedgerEntryIdRestore();
        MigrateTableExt_CheckLedgerEntryIdRestore();
        MigrateTableExt_CompanyInformationIdRestore();
        MigrateTableExt_CountryRegionIdRestore();
        MigrateTableExt_CurrencyIdRestore();
        MigrateTableExt_CurrencyExchangeRateIdRestore();
        MigrateTableExt_CustLedgerEntryIdRestore();
        MigrateTableExt_CustomerPriceGroupIdRestore();
        MigrateTableExt_GenJournalBatchIdRestore();
        MigrateTableExt_GenJournalLineIdRestore();
        MigrateTableExt_GenProductPostingGroupIdRestore();
        MigrateTableExt_GeneralLedgerSetupIdRestore();
        MigrateTableExt_IssuedReminderHeaderIdRestore();
        MigrateTableExt_ItemCategoryIdRestore();
        MigrateTableExt_ItemChargeAssignmentPurchIdRestore();
        MigrateTableExt_ItemSpecialGroupsIdRestore();
        MigrateTableExt_ListadoRecibodeIngresoIdRestore();
        MigrateTableExt_LocationIdRestore();
        MigrateTableExt_MemberContactIdRestore();
        MigrateTableExt_MemberPointOfferIdRestore();
        MigrateTableExt_NCFSetupIdRestore();
        MigrateTableExt_PaymentMethodIdRestore();
        MigrateTableExt_PeriodicDiscountIdRestore();
        MigrateTableExt_PostedStatementIdRestore();
        MigrateTableExt_ProductGroupIdRestore();
        MigrateTableExt_PurchCommentLineIdRestore();
        MigrateTableExt_PurchCommentLineArchiveIdRestore();
        MigrateTableExt_PurchInvLineIdRestore();
        MigrateTableExt_ReasonCodeTableExtIdRestore();
        MigrateTableExt_ReplenJournalLinesIdRestore();
        MigrateTableExt_ReplenTemplateIdRestore();
        MigrateTableExt_RetailSetupIdRestore();
        MigrateTableExt_RetailUserIdRestore();
        MigrateTableExt_SalesPriceIdRestore();
        MigrateTableExt_SalesReceivablesSetupIdRestore();
        MigrateTableExt_SalesTypeIdRestore();
        MigrateTableExt_SalespersonPurchaserIdRestore();
        MigrateTableExt_ShiptoAddressIdRestore();
        MigrateTableExt_StatementIdRestore();
        MigrateTableExt_StoreIdRestore();
        MigrateTableExt_TariffNumberIdRestore();
        MigrateTableExt_TenderTypeIdRestore();
        MigrateTableExt_TransSalesEntryIdRestore();
        MigrateTableExt_TransactionHeaderIdRestore();
        MigrateTableExt_TransferReceiptHeaderIdRestore();
        MigrateTableExt_TransferShipmentHeaderIdRestore();
        MigrateTableExt_UserSetupIdRestore();
        MigrateTableExt_ValueEntryIdRestore();
        MigrateTableExt_VendorIdRestore();
        MigrateTableExt_WarehouseReceiptLineIdRestore();
    end;

    local procedure MigrateTableExt_ApprovalEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Approval Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'ID_DXR.', 'ID_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_AssemblySetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Assembly Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Tolerance%_DXR', 'Tolerance%_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_BankAccReconciliationIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Extracto Bancario_DXR', 'Extracto Bancario_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_BankAccReconciliationLineIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Extracto Bancario_DXR', 'Extracto Bancario_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_BankAccountIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Cod. Proveedor Bco._BE_DXR', 'Cod. Proveedor Bco._Old');
                CopyFieldIfExists(RecRef, 'Account No._DXR', 'Account No._Old');
                CopyFieldIfExists(RecRef, 'Amount In Payload_DXR', 'Amount In Payload_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_BankAccountLedgerEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Fecha Registro 2_DXR', 'Fecha Registro 2_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CheckLedgerEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Check Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Recibido Por_DXR', 'Recibido Por_Old');
                CopyFieldIfExists(RecRef, 'Recibido Por Cedula_DXR', 'Recibido Por Cedula_Old');
                CopyFieldIfExists(RecRef, 'Hora Entrega_DXR', 'Hora Entrega_Old');
                CopyFieldIfExists(RecRef, 'No. Recibo_DXR', 'No. Recibo_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CompanyInformationIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Company Information");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Encargado Retenciones_DXR', 'Encargado Retenciones_Old');
                CopyFieldIfExists(RecRef, 'Posicion Encargado Ret._DXR', 'Posicion Encargado Ret._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CountryRegionIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Country/Region");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Obsolete 11123302_DXR', 'Obsolete 11123302_Old');
                CopyFieldIfExists(RecRef, 'Obsolete 11123303_DXR', 'Obsolete 11123303_Old');
                CopyFieldIfExists(RecRef, '2-Digit ISO Code_DXR', '2-Digit ISO Code_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CurrencyIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Accepted bpd_DXR', 'Accepted bpd_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CurrencyExchangeRateIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency Exchange Rate");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Tasa Banco Central_DXR', 'Tasa Banco Central_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CustLedgerEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Cust. Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'No. Authorizacion_DXR', 'No. Authorizacion_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_CustomerPriceGroupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Customer Price Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Global Sales Code_DXR', 'Global Sales Code_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_GenJournalBatchIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Batch");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Pago Electronico_DXR', 'Pago Electronico_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_GenJournalLineIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Pago Electronico_DXR', 'Pago Electronico_Old');
                CopyFieldIfExists(RecRef, 'IsRecaudo_DXR', 'IsRecaudo_Old');
                CopyFieldIfExists(RecRef, 'ePAGOS_DXR', 'ePAGOS_Old');
                CopyFieldIfExists(RecRef, 'VendorPay No._DXR', 'VendorPay No._Old');
                CopyFieldIfExists(RecRef, 'Only Two Dimensions_DXR', 'Only Two Dimensions_Old');
                CopyFieldIfExists(RecRef, 'No. Authorizacion_DXR', 'No. Authorizacion_Old');
                CopyFieldIfExists(RecRef, 'Fecha Registro2_DXR', 'Fecha Registro2_Old');
                CopyFieldIfExists(RecRef, 'Posting Exch. Entry No._DXR', 'Posting Exch. Entry No._Old');
                CopyFieldIfExists(RecRef, 'Posting Exch. Line No._DXR', 'Posting Exch. Line No._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_GenProductPostingGroupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Product Posting Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Internal Consumption_DXR', 'Internal Consumption_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_GeneralLedgerSetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"General Ledger Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Fecha Inicio AJCOSTO_DXR', 'Fecha Inicio AJCOSTO_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_IssuedReminderHeaderIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Issued Reminder Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Remaining Amount 2_DXR', 'Remaining Amount 2_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ItemCategoryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Category");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, '% Comision_DXR', '% Comision_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ItemChargeAssignmentPurchIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Monto Cargo Liq._DXR', 'Monto Cargo Liq._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ItemSpecialGroupsIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Item Special Groups");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, '% Comision_DXR', '% Comision_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ListadoRecibodeIngresoIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52132); // DXR_Cash Journal Receipt List (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Documento Registrado_DXR', 'Documento Registrado_Old');
                CopyFieldIfExists(RecRef, 'Fecha Vencimiento_DXR', 'Fecha Vencimiento_Old');
                CopyFieldIfExists(RecRef, 'IsRecaudo_DXR', 'IsRecaudo_Old');
                CopyFieldIfExists(RecRef, 'No. Authorizacion_DXR', 'No. Authorizacion_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_LocationIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Location");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Req._Transport_DXR', 'Req. Transport_Old');
                CopyFieldIfExists(RecRef, 'Existencia Ventas_DXR', 'Existencia Ventas_Old');
                CopyFieldIfExists(RecRef, 'Transito Internacional_DXR', 'Transito Internacional_Old');
                CopyFieldIfExists(RecRef, 'Req. Cod. Audit Transf_DXR', 'Req. Cod. Audit Transf_Old');
                CopyFieldIfExists(RecRef, 'Visible in Trafico_DXR', 'Visible in Trafico_Old');
                CopyFieldIfExists(RecRef, 'Req. Cod. Pos. & Neg._DXR', 'Req. Cod. Pos. & Neg._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_MemberContactIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Contact");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Cedula_DXR', 'Cedula_Old');
                CopyFieldIfExists(RecRef, 'Newsletter_DXR', 'Newsletter_Old');
                CopyFieldIfExists(RecRef, 'Profesion_DXR', 'Profesion_Old');
                CopyFieldIfExists(RecRef, 'Area de Trabajo_DXR', 'Area de Trabajo_Old');
                CopyFieldIfExists(RecRef, 'Cantidad De Hijos_DXR', 'Cantidad De Hijos_Old');
                CopyFieldIfExists(RecRef, 'Sucursal Preferida_DXR', 'Sucursal Preferida_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_MemberPointOfferIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Point Offer");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'isTickets_DXR', 'isTickets_Old');
                CopyFieldIfExists(RecRef, 'Promotion Status_DXR', 'Promotion Status_Old');
                CopyFieldIfExists(RecRef, 'Multiplier for members_DXR', 'Multiplier for members_Old');
                CopyFieldIfExists(RecRef, 'Calc. Type_DXR', 'Calc. Type_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_NCFSetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52179); // DXR_NCF Setup (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Grupo Contable BS_DXR', 'Grupo Contable BS_Old');
                CopyFieldIfExists(RecRef, 'Legal Tip %_DXR', 'Legal Tip %_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PaymentMethodIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Payment Method");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Payment Processor_DXR', 'Payment Processor_Old');
                CopyFieldIfExists(RecRef, 'Prioridad_DXR.', 'Prioridad_Old');
                CopyFieldIfExists(RecRef, 'Contado_DXR', 'Contado_Old');
                CopyFieldIfExists(RecRef, 'Tipo Venta_DXR', 'Tipo Venta_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PeriodicDiscountIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Periodic Discount");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Global_DXR', 'Global_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PostedStatementIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Posted Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Listo para Registrar_DXR', 'Listo para Registrar_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ProductGroupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Product Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Block, Sand And Cement_DXR', 'Block, Sand And Cement_Old');
                CopyFieldIfExists(RecRef, 'Comision_Cobro_DXR.', 'Comision_Cobro_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchCommentLineIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Comentario Extendido_DXR', 'Comentario Extendido_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchCommentLineArchiveIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Comentario Extendido_DXR', 'Comentario Extendido_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchInvLineIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Inv. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Liquidacion_DXR', 'Liquidacion_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ReasonCodeTableExtIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Reason Code");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'GroupTransport_DXR.', 'GroupTransport_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ReplenJournalLinesIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Journal Lines");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Almacen Destino_DXR', 'Almacen Destino_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ReplenTemplateIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Template");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Almacen Destino_DXR', 'Almacen Destino_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_RetailSetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Withhold VAT Refund_DXR', 'Withhold VAT Refund_Old');
                CopyFieldIfExists(RecRef, 'VAT Bus. Posting Group_DXR', 'VAT Bus. Posting Group_Old');
                CopyFieldIfExists(RecRef, 'VAT Prod. Posting Group_DXR', 'VAT Prod. Posting Group_Old');
                CopyFieldIfExists(RecRef, 'Days Limit_DXR', 'Days Limit_Old');
                CopyFieldIfExists(RecRef, 'Sales Type_DXR', 'Sales Type_Old');
                CopyFieldIfExists(RecRef, 'Validar Salida POS_DXR', 'Validar Salida POS_Old');
                CopyFieldIfExists(RecRef, 'Bloq camb de lin MKP_DXR', 'Bloq camb de lin MKP_Old');
                CopyFieldIfExists(RecRef, 'Impr por Descripcion_DXR', 'Impr por Descripcion_Old');
                CopyFieldIfExists(RecRef, 'Cod Barras en Copias_DXR', 'Cod Barras en Copias_Old');
                CopyFieldIfExists(RecRef, 'No Valid Prec Cliente_DXR', 'No Valid Prec Cliente_Old');
                CopyFieldIfExists(RecRef, 'Permitir Descuentos N/C_DXR', 'Permitir Descuentos N/C_Old');
                CopyFieldIfExists(RecRef, 'Send Trans. Sales Entry_DXR', 'Send Trans. Sales Entry_Old');
                CopyFieldIfExists(RecRef, 'Control SPO Cte Exon_DXR', 'Control SPO Cte Exon_Old');
                CopyFieldIfExists(RecRef, 'Cantidades Barcodes_DXR', 'Cantidades Barcodes_Old');
                CopyFieldIfExists(RecRef, 'Env correo Ventas/Devol_DXR', 'Env correo Ventas/Devol_Old');
                CopyFieldIfExists(RecRef, 'Terminos Devoluciones_DXR', 'Terminos Devoluciones_Old');
                CopyFieldIfExists(RecRef, 'Prefijo Pedidos POS TMP_DXR', 'Prefijo Pedidos POS TMP_Old');
                CopyFieldIfExists(RecRef, 'Proveedor_DXR', 'Proveedor_Old');
                CopyFieldIfExists(RecRef, 'USD Currency Code_DXR', 'USD Currency Code_Old');
                CopyFieldIfExists(RecRef, 'Days to Reprint_DXR', 'Days to Reprint_Old');
                CopyFieldIfExists(RecRef, 'Allow Days to Reprint_DXR', 'Allow Days to Reprint_Old');
                CopyFieldIfExists(RecRef, 'Ruta Api Email_DXR', 'Ruta Api Email_Old');
                CopyFieldIfExists(RecRef, 'FileServerName_DXR', 'FileServerName_Old');
                CopyFieldIfExists(RecRef, 'NotAllowReprintReturn_DXR', 'NotAllowReprintReturn_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_RetailUserIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail User");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Almacen Despacho_DXR.', 'Almacen Despacho_Old');
                CopyFieldIfExists(RecRef, 'Filtrar Exist Ventas_DXR', 'Filtrar Exist Ventas_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesPriceIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Price");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Markup % Without TAX_DXR', 'Markup % Without TAX_Old');
                CopyFieldIfExists(RecRef, 'Markup % CP_DXR', 'Markup % CP_Old');
                CopyFieldIfExists(RecRef, 'Visible in Webshop_DXR', 'Visible in Webshop_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesReceivablesSetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales & Receivables Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'STD POS VAT Bus Pst Grp_DXR', 'STD POS VAT Bus Pst Grp_Old');
                CopyFieldIfExists(RecRef, 'STD POS Dflt Doc Copies_DXR', 'STD POS Dflt Doc Copies_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesTypeIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Sales Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Venta Ex. ITBIS_DXR', 'Venta Ex. ITBIS_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalespersonPurchaserIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Salesperson/Purchaser");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Gestor_CXP_DXR', 'Gestor_CXP_Old');
                CopyFieldIfExists(RecRef, 'Comisiona_DXR', 'Comisiona_Old');
                CopyFieldIfExists(RecRef, 'Tipo Comision_DXR', 'Tipo Comision_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ShiptoAddressIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Ship-to Address");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Latitud_DXR.', 'Latitud_Old');
                CopyFieldIfExists(RecRef, 'Longitud_DXR.', 'Longitud_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_StatementIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Listo para Registrar_DXR', 'Listo para Registrar_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_StoreIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC STORE");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Cod. Cliente Contado_BE_DXR', 'Cod. Cliente Contado_Old');
                CopyFieldIfExists(RecRef, 'No Serie 3er Party Item_DXR', 'No Serie 3er Party Item_Old');
                CopyFieldIfExists(RecRef, 'Address 3_BE_DXR', 'Address 3_Old');
                CopyFieldIfExists(RecRef, 'Utiliza NCF Unico_BE_DXR', 'Utiliza NCF Unico_Old');
                CopyFieldIfExists(RecRef, 'Print Header Doc._DXR.', 'Print Header Doc._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TariffNumberIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Tariff Number");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, '% Arancel_DXR', '% Arancel_Old');
                CopyFieldIfExists(RecRef, 'ISC_DXR', 'ISC_Old');
                CopyFieldIfExists(RecRef, '% Selectivo_DXR', '% Selectivo_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TenderTypeIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Tender Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'IsCreditMemo_DXR', 'IsCreditMemo_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TransSalesEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Sales Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Autorizador_DXR', 'Autorizador_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TransactionHeaderIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Transaction Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'No. Ticket_BE_DXR', 'No. Ticket_Old');
                CopyFieldIfExists(RecRef, 'Email Transaction_DXR', 'Email Transaction_Old');
                CopyFieldIfExists(RecRef, 'Fecha Expiracion NCF_BE_DXR', 'Fecha Expiracion NCF_Old');
                CopyFieldIfExists(RecRef, 'Tipo Identificacion_BE_DXR', 'Tipo Identificacion_Old');
                CopyFieldIfExists(RecRef, 'Sell-to Contact_DXR', 'Sell-to Contact_Old');
                CopyFieldIfExists(RecRef, 'Aplica Transportacion_DXR', 'Aplica Transportacion_Old');
                CopyFieldIfExists(RecRef, 'Addl Currency Code_DXR', 'Addl Currency Code_Old');
                CopyFieldIfExists(RecRef, 'Addl Currency Factor_DXR', 'Addl Currency Factor_Old');
                CopyFieldIfExists(RecRef, 'Print Header Doc_DXR', 'Print Header Doc_Old');
                CopyFieldIfExists(RecRef, 'Banco Central Cur Fctr_DXR', 'Banco Central Cur Fctr_Old');
                CopyFieldIfExists(RecRef, 'Qty Tickets_DXR', 'Qty Tickets_Old');
                CopyFieldIfExists(RecRef, 'Promotion Tickets_DXR', 'Promotion Tickets_Old');
                CopyFieldIfExists(RecRef, 'Order No._DXR', 'Order No._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TransferReceiptHeaderIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Receipt Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Order User ID_DXR.', 'Order User Id_Old');
                CopyFieldIfExists(RecRef, 'Order Date Created_DXR.', 'Order Date Created_Old');
                CopyFieldIfExists(RecRef, 'Receipt User ID_DXR.', 'Receipt User ID_Old');
                CopyFieldIfExists(RecRef, 'Pre Receive Ref No_DXR', 'Pre Receive Ref No_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_TransferShipmentHeaderIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Shipment Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Order User ID_DXR.', 'Order User Id_Old');
                CopyFieldIfExists(RecRef, 'Order Date Created_DXR.', 'Order Date Created_Old');
                CopyFieldIfExists(RecRef, 'Shipment User ID_DXR.', 'Shipment User ID_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_UserSetupIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"User Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Entrega Cheques_BE_DXR', 'Entrega Cheques_Old');
                CopyFieldIfExists(RecRef, 'Grupo Precios Tope_DXR.', 'Grupo Precios Tope_Old');
                CopyFieldIfExists(RecRef, 'Ilimitado_DXR', 'Ilimitado_Old');
                CopyFieldIfExists(RecRef, 'Filtrar Por Vendedor_DXR', 'Filtrar Por Vendedor_Old');
                CopyFieldIfExists(RecRef, 'Create_Shipments_DXR', 'Create Shipments_Old');
                CopyFieldIfExists(RecRef, 'Invoice Shipments_DXR', 'Invoice Shipments_Old');
                CopyFieldIfExists(RecRef, 'User Hierarchy_DXR', 'User Hierarchy_Old');
                CopyFieldIfExists(RecRef, 'Filtrar Cartera Cte_DXR.', 'Filtrar Cartera Cte_Old');
                CopyFieldIfExists(RecRef, 'Permit Tienda Dif a IF_DXR', 'Permit Tienda Dif a IF_Old');
                CopyFieldIfExists(RecRef, 'Tipo Segmento_DXR', 'Tipo Segmento_Old');
                CopyFieldIfExists(RecRef, 'Aprrove Int Consump_DXR', 'Aprrove Int Consump_Old');
                CopyFieldIfExists(RecRef, 'Create Int Consump_DXR', 'Create Int Consump_Old');
                CopyFieldIfExists(RecRef, 'Almacen Consumo Interno_DXR', 'Almacen Consumo Interno_Old');
                CopyFieldIfExists(RecRef, 'Departamento - Discr_DXR', 'Departamento - Discr_Old');
                CopyFieldIfExists(RecRef, 'Crear Ajustes - Discr_DXR', 'Crear Ajustes - Discr_Old');
                CopyFieldIfExists(RecRef, 'Post Int Consumption_DXR', 'Post Int Consumption_Old');
                CopyFieldIfExists(RecRef, 'Excl Filtro DptoDiscr_DXR', 'Excl Filtro DptoDiscr_Old');
                CopyFieldIfExists(RecRef, 'Filtrar Usu Reimpresion_DXR', 'Filtrar Usu Reimpresion_Old');
                CopyFieldIfExists(RecRef, 'Modify Int Consump_DXR', 'Modify Int Consump_Old');
                CopyFieldIfExists(RecRef, 'SendAppr  Int Consump_DXR', 'SendAppr  Int Consump_Old');
                CopyFieldIfExists(RecRef, 'Order to Retail Order_DXR', 'Order to Retail Order_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_ValueEntryIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Value Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Correccion Int._DXR', 'Correccion Int._Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_VendorIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Vendor");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Teléfono 2_DXR', 'Teléfono 2_Old');
                CopyFieldIfExists(RecRef, 'Vendedor_DXR', 'Vendedor_Old');
                CopyFieldIfExists(RecRef, 'Vendedor Email_DXR.', 'Vendedor email_Old');
                CopyFieldIfExists(RecRef, 'Vendedor Celular_DXR', 'Vendedor Celular_Old');
                CopyFieldIfExists(RecRef, 'Apartado Postal_DXR', 'Apartado Postal_Old');
                CopyFieldIfExists(RecRef, 'Sector_DXR', 'Sector_Old');
                CopyFieldIfExists(RecRef, 'FechaCreacion_DXR', 'FechaCreacion_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_WarehouseReceiptLineIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Warehouse Receipt Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Almacen Destino_DXR', 'Almacen Destino_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
