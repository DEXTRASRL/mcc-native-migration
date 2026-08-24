codeunit 60146 "DXR MCC Bellon Migr Phase2"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 2 Leg Norm" (56119), which itself only calls three procedures on "Bellon Upgrade
    // Process" (59221, Subtype = Upgrade - never .Run()/OnRun'd, only named procedures called on
    // a typed variable, same safe pattern used throughout this portfolio):
    //   1) MigrateAllNormalizedTables() - 137 legacy tables (50xxx) copied to their DXR_ clone.
    //   2) MigrateAllTableExtensionFields() - ~74 active field-copy procedures (427 fields across
    //      ~87 tableextensions were originally wired; 13 of those procedures - the whole Sales/
    //      Purchase Header family, since superseded by other phases - were retroactively removed
    //      from the active call list on 2026-08-20 and are dead code kept only as documentation
    //      in the real source; NOT ported here, matching the source's own current behavior).
    //      UNTRACKED BY MCC'S REGISTRY (no BELLON-Pn concept row references this specific group)
    //      but it DID run as a side effect every time the old delegation adapter (60056) executed
    //      - same situation as Despacho Base's Phase 1 in this same pivot - so it is preserved
    //      here rather than silently dropped.
    //   3) MigrateAllNormalizedTables_Batch2() - 4 more legacy tables, added after the main list.
    // Step-level idempotency reuses the sibling's own exact tag strings (hardcoded here since
    // "Upgrade Tag Mgt." exposes them via a typed Public codeunit already dependent-on elsewhere
    // in this portfolio, but the literals are copied directly to avoid any further cross-repo
    // coupling risk).
    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DXR-TablesNorm283') then begin
            MigrateAllNormalizedTables();
            UpgradeTag.SetUpgradeTag('DXR-TablesNorm283');
        end;

        if not UpgradeTag.HasUpgradeTag('DXR-TableExtFieldsNorm283') then begin
            MigrateAllTableExtensionFields();
            UpgradeTag.SetUpgradeTag('DXR-TableExtFieldsNorm283');
        end;

        if not UpgradeTag.HasUpgradeTag('DXR-TablesNorm283-Batch2') then begin
            MigrateAllNormalizedTables_Batch2();
            UpgradeTag.SetUpgradeTag('DXR-TablesNorm283-Batch2');
        end;
    end;

    // ===== Generic copy engines (ported verbatim from "Bellon Upgrade Process") =====

    // Copies every row of a legacy table (OldTableId) to its DXR_ clone (NewTableId) by field
    // NUMBER (both tables share identical field IDs/types), Class=Normal only on both sides.
    // Idempotent per table: if the destination already has rows, does nothing (protects against a
    // partial retry after a mid-run failure).
    local procedure MigrateLegacyTableData(OldTableId: Integer; NewTableId: Integer)
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
        FieldIdx: Integer;
    begin
        NewRecRef.Open(NewTableId);
        if not NewRecRef.IsEmpty() then begin
            NewRecRef.Close();
            exit;
        end;
        NewRecRef.Close();

        OldRecRef.Open(OldTableId);
        if OldRecRef.FindSet() then
            repeat
                NewRecRef.Open(NewTableId);
                NewRecRef.Init();
                for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                    OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                    if (OldFieldRef.Class() = FieldClass::Normal) and NewRecRef.FieldExist(OldFieldRef.Number()) then begin
                        NewFieldRef := NewRecRef.Field(OldFieldRef.Number());
                        if NewFieldRef.Class() = FieldClass::Normal then
                            NewFieldRef.Value := OldFieldRef.Value();
                    end;
                end;
                NewRecRef.Insert(false);
            until OldRecRef.Next() = 0;
        OldRecRef.Close();
    end;

    // Copies OldFieldNo -> NewFieldNo on the current row only if both fields exist in the
    // currently published schema (defense-in-depth: several IDs hardcoded in the real source
    // point at fields relocated/removed by a later renumbering round; RecRef.Field(N) on a
    // missing N throws and aborts the whole procedure otherwise).
    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;

    // ===== 1) 137 legacy table restores =====

    local procedure MigrateAllNormalizedTables()
    begin
        MigrateLegacyTableData(50001, 53301); // Agente -> DXR_Agente
        MigrateLegacyTableData(50004, 53302); // AGR Log -> DXR_AGR Log
        MigrateLegacyTableData(50005, 53303); // AGR Setup -> DXR_AGR Setup
        MigrateLegacyTableData(50006, 53304); // Ajuste Inventario Config -> DXR_Ajuste Inventario Config
        MigrateLegacyTableData(50007, 53305); // Archivo - Discrepancias -> DXR_Archivo - Discrepancias
        MigrateLegacyTableData(50008, 53306); // Area de Trabajo -> DXR_Area de Trabajo
        MigrateLegacyTableData(50009, 53307); // Bancos - Extracto Bancario -> DXR_Bancos - Extracto Bancario
        MigrateLegacyTableData(50010, 53308); // Bank -> DXR_Bank
        MigrateLegacyTableData(50011, 53309); // Bank Relation -> DXR_Bank Relation
        MigrateLegacyTableData(50012, 53310); // Black List Promotion -> DXR_Black List Promotion
        MigrateLegacyTableData(50013, 53311); // Cabecera Discrepancia -> DXR_Cabecera Discrepancia
        MigrateLegacyTableData(50016, 53312); // Carga Masiva Beneficiarios BPD -> DXR_Carga Masiva Benef BPD
        MigrateLegacyTableData(50020, 53313); // Categoria Servicios -> DXR_Categoria Servicios
        MigrateLegacyTableData(50021, 53314); // Cilindros -> DXR_Cilindros
        MigrateLegacyTableData(50022, 53315); // Cilindros - Setup -> DXR_Cilindros - Setup
        MigrateLegacyTableData(50024, 53316); // Codigos de Auditoria -> DXR_Codigos de Auditoria.
        MigrateLegacyTableData(50025, 53317); // Comentario - Discrepancias -> DXR_Comentario - Discrepancias
        MigrateLegacyTableData(50029, 53318); // Conf. Extracto Bancario -> DXR_Conf. Extracto Bancario
        MigrateLegacyTableData(50032, 53319); // Config. NCF Ventas -> DXR_Config. NCF Ventas
        MigrateLegacyTableData(50033, 53320); // Config. NCF Ventas STD -> DXR_Config. NCF Ventas STD
        MigrateLegacyTableData(50034, 53321); // Config. Polizas -> DXR_Config. Polizas
        MigrateLegacyTableData(50035, 53322); // Configuracion CB -> DXR_Configuracion CB
        MigrateLegacyTableData(50036, 53323); // Configuracion - Discrepancias -> DXR_Config - Discr
        MigrateLegacyTableData(50037, 53324); // Configuracion Encuestas - POS -> DXR_Config Encuestas - POS
        MigrateLegacyTableData(50038, 53325); // Configuraciones Requisicion -> DXR_Config Req
        MigrateLegacyTableData(50039, 53326); // Configuracion - MEDALLIA -> DXR_Configuracion - MEDALLIA
        MigrateLegacyTableData(50040, 53327); // Conf. Pagos Ecommerce Azul -> DXR_Conf. Pagos Ecommerce Azul
        MigrateLegacyTableData(50042, 53328); // Control Procesos por Almacen -> DXR_Control Proc por Almacen
        MigrateLegacyTableData(50043, 53329); // Conversion Costo -> DXR_Conversion Costo
        MigrateLegacyTableData(50048, 53330); // Departamento - Discrepancias -> DXR_Departamento - Discr
        MigrateLegacyTableData(50050, 53331); // Detalle - Extracto Bancario -> DXR_Detalle - Extr Bancario
        MigrateLegacyTableData(50052, 53332); // Draw Setup -> DXR_Draw Setup
        MigrateLegacyTableData(50055, 53333); // Email Source Template Relation -> DXR_Email Source Tmpl Rel
        MigrateLegacyTableData(50057, 53334); // Entrega Facturas CxC - Lines -> DXR_Entrega Fact CxC - Lines
        MigrateLegacyTableData(50058, 53335); // Envio Compras -> DXR_Envio Compras
        MigrateLegacyTableData(50061, 53336); // EPagos Setup -> DXR_EPagos Setup
        MigrateLegacyTableData(50063, 53337); // Exclude Filter Journal -> DXR_Exclude Filter Journal
        MigrateLegacyTableData(50064, 53338); // Excluir Terminos  - ItemSearch -> DXR_Excluir Term - ItemSearch
        MigrateLegacyTableData(50065, 53339); // File Structure -> DXR_File Structure
        MigrateLegacyTableData(50068, 53340); // Forma de Pago -> DXR_Forma de Pago
        MigrateLegacyTableData(50071, 53341); // HisCargaMasivaBeneficiariosBPD -> DXR_HisCargaMasivaBenefBPD
        MigrateLegacyTableData(50072, 53342); // Grupo Venta -> DXR_Grupo Venta
        MigrateLegacyTableData(50073, 53343); // HisLineasCargaMasivaBenefBPD -> DXR_HisLinCargaMasivaBenefBPD
        MigrateLegacyTableData(50074, 53344); // Hist. Beneficiarios BPD -> DXR_Hist. Beneficiarios BPD
        MigrateLegacyTableData(50075, 53345); // Hist. Cabecera Discrepancia -> DXR_Hist. Cabecera Discr
        MigrateLegacyTableData(50076, 53346); // Hist. de Ganadores -> DXR_Hist. de Ganadores
        MigrateLegacyTableData(50077, 53347); // Hist. Internal Consump. Header -> DXR_Hist. Int Consump. Header
        MigrateLegacyTableData(50078, 53348); // Hist. Internal Consump. Line -> DXR_Hist. Int Consump. Line
        MigrateLegacyTableData(50079, 53349); // Hist. Linea Discrepancia -> DXR_Hist. Linea Discrepancia
        MigrateLegacyTableData(50081, 53350); // Historico Enc Requisicion -> DXR_Historico Enc Requisicion
        MigrateLegacyTableData(50082, 53351); // Historico - Extracto Bancario -> DXR_Historico - Extr Bancario
        MigrateLegacyTableData(50084, 53352); // Historico Requisicion Line -> DXR_Historico Requisicion Line
        MigrateLegacyTableData(50085, 53353); // Hist Pre-Requisicion -> DXR_Hist Pre-Requisicion
        MigrateLegacyTableData(50086, 53354); // Hist Pre-Requisicion Line -> DXR_Hist Pre-Requisicion Line
        MigrateLegacyTableData(50093, 53355); // Internal Consumption Header -> DXR_Int Consump Header
        MigrateLegacyTableData(50094, 53356); // Internal Consumption Line -> DXR_Internal Consumption Line
        MigrateLegacyTableData(50095, 53357); // Internal Consumption Log -> DXR_Internal Consumption Log
        MigrateLegacyTableData(50096, 53358); // BE Inventory Masks -> DXR_Inventory Masks
        MigrateLegacyTableData(50098, 53359); // Item HTML -> DXR_Item HTML
        MigrateLegacyTableData(50099, 53360); // Item Image View -> DXR_Item Image View
        MigrateLegacyTableData(50100, 53361); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion
        MigrateLegacyTableData(50102, 53362); // Journal Promotion Tickets -> DXR_Journal Promotion Tickets
        MigrateLegacyTableData(50103, 53363); // Linea Discrepancia -> DXR_Linea Discrepancia
        MigrateLegacyTableData(50107, 53364); // Lineas Carga Masiva Ben. BPD -> DXR_Lin Carga Masiva Ben. BPD
        MigrateLegacyTableData(50109, 53365); // LineRQBuffer -> DXR_LineRQBuffer
        MigrateLegacyTableData(50111, 53366); // Log - Bank Statement -> DXR_Log - Bank Statement
        MigrateLegacyTableData(50112, 53367); // Log Email -> DXR_Log Email
        MigrateLegacyTableData(50115, 53368); // Log Transaccion Azul -> DXR_Log Transaccion Azul
        MigrateLegacyTableData(50116, 53369); // Log Transaccion Medallia -> DXR_Log Transaccion Medallia
        MigrateLegacyTableData(50117, 53370); // Log Transfer error -> DXR_Log Transfer error
        MigrateLegacyTableData(50118, 53371); // Marcas -> DXR_Marcas
        MigrateLegacyTableData(50119, 53372); // Member Management Setup -> DXR_Member Management Setup
        MigrateLegacyTableData(50121, 53373); // Motivo Cierre - Discrepancias -> DXR_Motivo Cierre - Discr
        MigrateLegacyTableData(50122, 53374); // Motivo Discrepancia -> DXR_Motivo Discrepancia
        MigrateLegacyTableData(50123, 53375); // Movimientos de Cilindro -> DXR_Movimientos de Cilindro
        MigrateLegacyTableData(50127, 53376); // Order Item Status -> DXR_Order Item Status
        MigrateLegacyTableData(50132, 53377); // Posted Jnl Promotion Tickets -> DXR_Posted Jnl Promo Tickets
        MigrateLegacyTableData(50135, 53378); // Pre Req LineNoStockValid -> DXR_Pre Req LineNoStockValid
        MigrateLegacyTableData(50136, 53379); // Pre Req no Stock Valid -> DXR_Pre Req no Stock Valid
        MigrateLegacyTableData(50137, 53380); // Pre-Requisicion -> DXR_Pre-Requisicion
        MigrateLegacyTableData(50138, 53381); // Pre-Requisicion Line -> DXR_Pre-Requisicion Line
        MigrateLegacyTableData(50139, 53382); // Pre-Requisicion Line No Stock -> DXR_Pre-Req Line No Stock
        MigrateLegacyTableData(50140, 53383); // Pre-Requisicion no Stock -> DXR_Pre-Requisicion no Stock
        MigrateLegacyTableData(50141, 53384); // Printing Invoice Log -> DXR_Printing Invoice Log
        MigrateLegacyTableData(50142, 53385); // Profesion -> DXR_Profesion
        MigrateLegacyTableData(50143, 53386); // Promotion Setup -> DXR_Promotion Setup
        MigrateLegacyTableData(50144, 53387); // Promotion Tickets Relation -> DXR_Promotion Tickets Relation
        MigrateLegacyTableData(50145, 53388); // Provincia -> DXR_Provincia
        MigrateLegacyTableData(50151, 53389); // Requisicion -> DXR_Requisicion
        MigrateLegacyTableData(50152, 53390); // Requisicion Comment Line -> DXR_Requisicion Comment Line
        MigrateLegacyTableData(50153, 53391); // Requisicion Line -> DXR_Requisicion Line
        MigrateLegacyTableData(50154, 53392); // Sales Dept -> DXR_Sales Dept
        MigrateLegacyTableData(50155, 53393); // Sales Groups -> DXR_Sales Groups
        MigrateLegacyTableData(50159, 53394); // Sales SubGroups -> DXR_Sales SubGroups
        MigrateLegacyTableData(50160, 53395); // Send Email Log -> DXR_Send Email Log
        MigrateLegacyTableData(50165, 53396); // Standard POS DASCOM Paymt Eqv -> DXR_Std POS DASCOM Paymt Eqv
        MigrateLegacyTableData(50168, 53397); // Standard POS Gen. Comments -> DXR_Standard POS Gen. Comments
        MigrateLegacyTableData(50172, 53398); // Standard POS Users -> DXR_Standard POS Users
        MigrateLegacyTableData(50173, 53399); // Store Statement Posting -> DXR_Store Statement Posting
        MigrateLegacyTableData(50174, 53400); // Summary Reconciliation Setup -> DXR_Summary Recon Setup
        MigrateLegacyTableData(50176, 53401); // Tasas BC -> DXR_Tasas BC
        MigrateLegacyTableData(50177, 53402); // Tickets By Offer -> DXR_Tickets By Offer
        MigrateLegacyTableData(50178, 53403); // Tickets Entry -> DXR_Tickets Entry
        MigrateLegacyTableData(50180, 53404); // Tipo de Contenedor -> DXR_Tipo de Contenedor
        MigrateLegacyTableData(50181, 53405); // Tipo Gas -> DXR_Tipo Gas
        MigrateLegacyTableData(50182, 53406); // Tipos o Agentes -> DXR_Tipos o Agentes
        MigrateLegacyTableData(50186, 53407); // Trans. Archive Line -> DXR_Trans. Archive Line
        MigrateLegacyTableData(50195, 53408); // Tratados Arancelarios -> DXR_Tratados Arancelarios
        MigrateLegacyTableData(50197, 53409); // UserApproverByBuyerGroup -> DXR_UserApproverByBuyerGroup
        MigrateLegacyTableData(50198, 53410); // UserByBuyerGroup -> DXR_UserByBuyerGroup
        MigrateLegacyTableData(50199, 53411); // UserLogs -> DXR_UserLogs
        MigrateLegacyTableData(50200, 53412); // UserPromo Apps -> DXR_UserPromo Apps
        MigrateLegacyTableData(50201, 53413); // Valoracion de Inventario -> DXR_Valoracion de Inventario
        MigrateLegacyTableData(50202, 53414); // VAT Bus. Settings -> DXR_VAT Bus. Settings
        MigrateLegacyTableData(50206, 53415); // Printing Invoice Log BO -> DXR_Printing Invoice Log BO
    end;

    // ===== 3) 4 more legacy table restores (added after the main list) =====

    local procedure MigrateAllNormalizedTables_Batch2()
    begin
        MigrateLegacyTableData(50002, 55006); // AGR Extended Item -> DXR_AGR Extended Item
        MigrateLegacyTableData(50027, 55005); // Comision_Grupo_Vendedor -> DXR_Comision_Grupo_Vendedor
        MigrateLegacyTableData(50097, 55004); // Inventory View -> DXR_Inventory View.
        MigrateLegacyTableData(50126, 55007); // Operaciones Tipo Comprobante2 -> DXR_Operaciones Tipo Comprob2
    end;

    // ===== 2) ~74 active tableextension field-copy procedures (untracked-gap logic) =====
    // 13 dead procedures (the whole Sales/Purchase Header family, superseded by later phases and
    // retroactively removed from the active call list 2026-08-20) are NOT ported here - matching
    // the real source's current behavior exactly.

    local procedure MigrateAllTableExtensionFields()
    begin
        MigrateTableExt_ApprovalEntryFields();
        MigrateTableExt_AssemblyHeaderFields();
        MigrateTableExt_AssemblySetupFields();
        MigrateTableExt_VendorLedgerEntryFields();
        MigrateTableExt_BankAccReconciliationFields();
        MigrateTableExt_BankAccReconciliationLineFields();
        MigrateTableExt_BankAccountFields();
        MigrateTableExt_BankAccountLedgerEntryFields();
        MigrateTableExt_LSCBarcodesFields();
        MigrateTableExt_CheckLedgerEntryFields();
        MigrateTableExt_CompanyInformationFields();
        MigrateTableExt_ContactFields();
        MigrateTableExt_CountryRegionFields();
        MigrateTableExt_CurrencyFields();
        MigrateTableExt_CurrencyExchangeRateFields();
        MigrateTableExt_CustLedgerEntryFields();
        MigrateTableExt_CustomerFields();
        MigrateTableExt_CustomerPriceGroupFields();
        MigrateTableExt_GenJournalBatchFields();
        MigrateTableExt_GenJournalLineFields();
        MigrateTableExt_GenProductPostingGroupFields();
        MigrateTableExt_GeneralLedgerSetupFields();
        MigrateTableExt_IssuedReminderHeaderFields();
        MigrateTableExt_IssuedReminderLineFields();
        MigrateTableExt_ItemFields();
        MigrateTableExt_ItemCategoryFields();
        MigrateTableExt_ItemChargeAssignmentPurchFields();
        MigrateTableExt_ItemJournalBatchFields();
        MigrateTableExt_ItemJournalLineFields();
        MigrateTableExt_ItemLedgerEntryFields();
        MigrateTableExt_LSCItemSpecialGroupsFields();
        MigrateTableExt_DXCashJournalReceiptListFields();
        MigrateTableExt_LocationFields();
        MigrateTableExt_LSCMemberContactFields();
        MigrateTableExt_LSCMemberPointOfferFields();
        MigrateTableExt_LSCMemberPointOfferLineFields();
        MigrateTableExt_DXVendorWithholdingLedgerEntryFields();
        MigrateTableExt_DXNCFSetupFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_PaymentMethodFields();
        MigrateTableExt_LSCPeriodicDiscountFields();
        MigrateTableExt_PostedAssemblyHeaderFields();
        MigrateTableExt_LSCPostedStatementFields();
        MigrateTableExt_LSCRetailProductGroupFields();
        MigrateTableExt_PurchCommentLineFields();
        MigrateTableExt_PurchCommentLineArchiveFields();
        MigrateTableExt_PurchInvLineFields();
        MigrateTableExt_ReasonCodeFields();
        MigrateTableExt_LSCReplenJournalLinesFields();
        MigrateTableExt_LSCReplenTemplateFields();
        MigrateTableExt_LSCRetailSetupFields();
        MigrateTableExt_LSCRetailUserFields();
        MigrateTableExt_SalesPriceFields();
        MigrateTableExt_SalesPriceWorksheetFields();
        MigrateTableExt_SalesReceivablesSetupFields();
        MigrateTableExt_LSCSalesTypeFields();
        MigrateTableExt_SalespersonPurchaserFields();
        MigrateTableExt_ShiptoAddressFields();
        MigrateTableExt_LSCStatementFields();
        MigrateTableExt_LSCSTOREFields();
        MigrateTableExt_TariffNumberFields();
        MigrateTableExt_LSCTenderTypeFields();
        MigrateTableExt_LSCTransSalesEntryFields();
        MigrateTableExt_LSCTransactionHeaderFields();
        MigrateTableExt_TransferHeaderFields();
        MigrateTableExt_TransferLineFields();
        MigrateTableExt_TransferReceiptHeaderFields();
        MigrateTableExt_TransferShipmentHeaderFields();
        MigrateTableExt_UserSetupFields();
        MigrateTableExt_ValueEntryFields();
        MigrateTableExt_VendorFields();
        MigrateTableExt_WarehouseReceiptLineFields();
    end;

    local procedure MigrateTableExt_ApprovalEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Approval Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 52001, 52002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_AssemblyHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Assembly Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_AssemblySetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Assembly Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 52000, 52001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_VendorLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Vendor Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccReconciliationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccReconciliationLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 52000, 52001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccountFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccountLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCBarcodesFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Barcodes");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CheckLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Check Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50005, 50009);
                CopyFieldIfExists(RecRef, 50006, 50010);
                CopyFieldIfExists(RecRef, 50007, 50011);
                CopyFieldIfExists(RecRef, 50008, 50012);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CompanyInformationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Company Information");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ContactFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Contact");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50060, 50079);
                CopyFieldIfExists(RecRef, 50061, 50080);
                CopyFieldIfExists(RecRef, 50062, 50081);
                CopyFieldIfExists(RecRef, 50063, 50082);
                CopyFieldIfExists(RecRef, 50064, 50083);
                CopyFieldIfExists(RecRef, 50065, 50084);
                CopyFieldIfExists(RecRef, 50066, 50085);
                CopyFieldIfExists(RecRef, 50067, 50086);
                CopyFieldIfExists(RecRef, 50068, 50087);
                CopyFieldIfExists(RecRef, 50069, 50088);
                CopyFieldIfExists(RecRef, 50070, 50089);
                CopyFieldIfExists(RecRef, 50071, 50090);
                CopyFieldIfExists(RecRef, 50072, 50091);
                CopyFieldIfExists(RecRef, 50073, 50092);
                CopyFieldIfExists(RecRef, 50074, 50093);
                CopyFieldIfExists(RecRef, 50075, 50094);
                CopyFieldIfExists(RecRef, 50076, 50095);
                CopyFieldIfExists(RecRef, 50077, 50096);
                CopyFieldIfExists(RecRef, 50078, 50097);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CountryRegionFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Country/Region");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CurrencyFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CurrencyExchangeRateFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency Exchange Rate");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Cust. Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50002, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustomerFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Customer");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50061);
                CopyFieldIfExists(RecRef, 50001, 50062);
                CopyFieldIfExists(RecRef, 50002, 50063);
                CopyFieldIfExists(RecRef, 50003, 50064);
                CopyFieldIfExists(RecRef, 50004, 50065);
                CopyFieldIfExists(RecRef, 50005, 50066);
                CopyFieldIfExists(RecRef, 50007, 50067);
                CopyFieldIfExists(RecRef, 50008, 50068);
                CopyFieldIfExists(RecRef, 50009, 50069);
                CopyFieldIfExists(RecRef, 50011, 50070);
                CopyFieldIfExists(RecRef, 50012, 50071);
                CopyFieldIfExists(RecRef, 50013, 50072);
                CopyFieldIfExists(RecRef, 50014, 50073);
                CopyFieldIfExists(RecRef, 50015, 50074);
                CopyFieldIfExists(RecRef, 50016, 50075);
                CopyFieldIfExists(RecRef, 50021, 50076);
                CopyFieldIfExists(RecRef, 50022, 50077);
                CopyFieldIfExists(RecRef, 50023, 50078);
                CopyFieldIfExists(RecRef, 50024, 50079);
                CopyFieldIfExists(RecRef, 50025, 50080);
                CopyFieldIfExists(RecRef, 50026, 50081);
                CopyFieldIfExists(RecRef, 50027, 50082);
                CopyFieldIfExists(RecRef, 50028, 50083);
                CopyFieldIfExists(RecRef, 50029, 50084);
                CopyFieldIfExists(RecRef, 50030, 50085);
                CopyFieldIfExists(RecRef, 50031, 50086);
                CopyFieldIfExists(RecRef, 50032, 50087);
                CopyFieldIfExists(RecRef, 50033, 50088);
                CopyFieldIfExists(RecRef, 50034, 50089);
                CopyFieldIfExists(RecRef, 50035, 50090);
                CopyFieldIfExists(RecRef, 50036, 50091);
                CopyFieldIfExists(RecRef, 50037, 50092);
                CopyFieldIfExists(RecRef, 50038, 50093);
                CopyFieldIfExists(RecRef, 50039, 50094);
                CopyFieldIfExists(RecRef, 50040, 50095);
                CopyFieldIfExists(RecRef, 50041, 50096);
                CopyFieldIfExists(RecRef, 50042, 50097);
                CopyFieldIfExists(RecRef, 50043, 50098);
                CopyFieldIfExists(RecRef, 50045, 50099);
                CopyFieldIfExists(RecRef, 50048, 50100);
                CopyFieldIfExists(RecRef, 50049, 50101);
                CopyFieldIfExists(RecRef, 50050, 50102);
                CopyFieldIfExists(RecRef, 50051, 50103);
                CopyFieldIfExists(RecRef, 50054, 50104);
                CopyFieldIfExists(RecRef, 50056, 50105);
                CopyFieldIfExists(RecRef, 50060, 50106);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustomerPriceGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Customer Price Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenJournalBatchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Batch");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50004);
                CopyFieldIfExists(RecRef, 50003, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenJournalLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50055);
                CopyFieldIfExists(RecRef, 50050, 50056);
                CopyFieldIfExists(RecRef, 50051, 50057);
                CopyFieldIfExists(RecRef, 50052, 50058);
                CopyFieldIfExists(RecRef, 50013, 50059);
                CopyFieldIfExists(RecRef, 50014, 50060);
                CopyFieldIfExists(RecRef, 50015, 50061);
                CopyFieldIfExists(RecRef, 50053, 50062);
                CopyFieldIfExists(RecRef, 50054, 50063);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenProductPostingGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Product Posting Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GeneralLedgerSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"General Ledger Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_IssuedReminderHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Issued Reminder Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_IssuedReminderLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Issued Reminder Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50036);
                CopyFieldIfExists(RecRef, 50001, 50037);
                CopyFieldIfExists(RecRef, 50002, 50038);
                CopyFieldIfExists(RecRef, 50003, 50039);
                CopyFieldIfExists(RecRef, 50004, 50040);
                CopyFieldIfExists(RecRef, 50005, 50041);
                CopyFieldIfExists(RecRef, 50006, 50042);
                CopyFieldIfExists(RecRef, 50007, 50043);
                CopyFieldIfExists(RecRef, 50008, 50044);
                CopyFieldIfExists(RecRef, 50009, 50045);
                CopyFieldIfExists(RecRef, 50010, 50046);
                CopyFieldIfExists(RecRef, 50011, 50047);
                CopyFieldIfExists(RecRef, 50012, 50048);
                CopyFieldIfExists(RecRef, 50013, 50049);
                CopyFieldIfExists(RecRef, 50014, 50050);
                CopyFieldIfExists(RecRef, 50015, 50051);
                CopyFieldIfExists(RecRef, 50016, 50052);
                CopyFieldIfExists(RecRef, 50017, 50053);
                CopyFieldIfExists(RecRef, 50018, 50054);
                CopyFieldIfExists(RecRef, 50019, 50055);
                CopyFieldIfExists(RecRef, 50020, 50056);
                CopyFieldIfExists(RecRef, 50021, 50057);
                CopyFieldIfExists(RecRef, 50022, 50058);
                CopyFieldIfExists(RecRef, 50023, 50059);
                CopyFieldIfExists(RecRef, 50024, 50060);
                CopyFieldIfExists(RecRef, 50025, 50061);
                CopyFieldIfExists(RecRef, 50026, 50062);
                CopyFieldIfExists(RecRef, 50027, 50063);
                CopyFieldIfExists(RecRef, 50029, 50064);
                CopyFieldIfExists(RecRef, 50030, 50065);
                CopyFieldIfExists(RecRef, 50031, 50066);
                CopyFieldIfExists(RecRef, 50032, 50067);
                CopyFieldIfExists(RecRef, 50033, 50068);
                CopyFieldIfExists(RecRef, 50034, 50069);
                CopyFieldIfExists(RecRef, 50035, 50070);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemCategoryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Category");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemChargeAssignmentPurchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemJournalBatchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Journal Batch");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemJournalLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Journal Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50003, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50003, 50005);
                CopyFieldIfExists(RecRef, 50004, 50006);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCItemSpecialGroupsFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Item Special Groups");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXCashJournalReceiptListFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52132); // DXR_Cash Journal Receipt List (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50002, 50009);
                CopyFieldIfExists(RecRef, 50003, 50010);
                CopyFieldIfExists(RecRef, 50004, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LocationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Location");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50002, 50008);
                CopyFieldIfExists(RecRef, 50003, 50009);
                CopyFieldIfExists(RecRef, 50004, 50010);
                CopyFieldIfExists(RecRef, 50005, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberContactFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Contact");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50002, 50008);
                CopyFieldIfExists(RecRef, 50003, 50009);
                CopyFieldIfExists(RecRef, 50004, 50010);
                CopyFieldIfExists(RecRef, 50005, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberPointOfferFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Point Offer");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50004);
                CopyFieldIfExists(RecRef, 50001, 50005);
                CopyFieldIfExists(RecRef, 50002, 50006);
                CopyFieldIfExists(RecRef, 50003, 50007);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberPointOfferLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Point Offer Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXVendorWithholdingLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52204); // DXR_VendWithholdLedgerEntry (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXNCFSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52179); // DXR_NCF Setup (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50003);
                CopyFieldIfExists(RecRef, 50002, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTransLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Trans. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50001, 50009);
                CopyFieldIfExists(RecRef, 50000, 50010);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTransactionFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Transaction");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50010);
                CopyFieldIfExists(RecRef, 50001, 50006);
                CopyFieldIfExists(RecRef, 50002, 50007);
                CopyFieldIfExists(RecRef, 50003, 50008);
                CopyFieldIfExists(RecRef, 50004, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PaymentMethodFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Payment Method");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50005, 50006);
                CopyFieldIfExists(RecRef, 50000, 50007);
                CopyFieldIfExists(RecRef, 50001, 50008);
                CopyFieldIfExists(RecRef, 50002, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPeriodicDiscountFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Periodic Discount");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50011);
                CopyFieldIfExists(RecRef, 50001, 50012);
                CopyFieldIfExists(RecRef, 50002, 50013);
                CopyFieldIfExists(RecRef, 50003, 50014);
                CopyFieldIfExists(RecRef, 50004, 50015);
                CopyFieldIfExists(RecRef, 50005, 50016);
                CopyFieldIfExists(RecRef, 50006, 50017);
                CopyFieldIfExists(RecRef, 50010, 50018);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PostedAssemblyHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Posted Assembly Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPostedStatementFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Posted Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailProductGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Product Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchCommentLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchCommentLineArchiveFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchInvLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Inv. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50017, 50018);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ReasonCodeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Reason Code");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCReplenJournalLinesFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Journal Lines");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50016, 50032);
                CopyFieldIfExists(RecRef, 50031, 50033);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCReplenTemplateFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Template");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50016, 50032);
                CopyFieldIfExists(RecRef, 50031, 50033);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50027);
                CopyFieldIfExists(RecRef, 50001, 50028);
                CopyFieldIfExists(RecRef, 50002, 50029);
                CopyFieldIfExists(RecRef, 50003, 50030);
                CopyFieldIfExists(RecRef, 50004, 50031);
                CopyFieldIfExists(RecRef, 50007, 50032);
                CopyFieldIfExists(RecRef, 50008, 50033);
                CopyFieldIfExists(RecRef, 50009, 50034);
                CopyFieldIfExists(RecRef, 50010, 50035);
                CopyFieldIfExists(RecRef, 50011, 50036);
                CopyFieldIfExists(RecRef, 50012, 50037);
                CopyFieldIfExists(RecRef, 50013, 50038);
                CopyFieldIfExists(RecRef, 50014, 50039);
                CopyFieldIfExists(RecRef, 50016, 50040);
                CopyFieldIfExists(RecRef, 50017, 50041);
                if RecRef.FieldExist(50018) then
                    RecRef.Field(50018).CalcField();
                CopyFieldIfExists(RecRef, 50018, 50042);
                CopyFieldIfExists(RecRef, 50019, 50043);
                CopyFieldIfExists(RecRef, 50020, 50044);
                CopyFieldIfExists(RecRef, 50021, 50045);
                CopyFieldIfExists(RecRef, 50022, 50046);
                CopyFieldIfExists(RecRef, 50023, 50047);
                CopyFieldIfExists(RecRef, 50024, 50048);
                CopyFieldIfExists(RecRef, 50025, 50049);
                CopyFieldIfExists(RecRef, 50026, 50050);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailUserFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail User");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesPriceFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Price");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50053);
                CopyFieldIfExists(RecRef, 50002, 50054);
                CopyFieldIfExists(RecRef, 50003, 50055);
                CopyFieldIfExists(RecRef, 50011, 50056);
                CopyFieldIfExists(RecRef, 50052, 50057);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesPriceWorksheetFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Price Worksheet");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesReceivablesSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales & Receivables Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCSalesTypeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Sales Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalespersonPurchaserFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Salesperson/Purchaser");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50004, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50006, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ShiptoAddressFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Ship-to Address");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCStatementFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCSTOREFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC STORE");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50010);
                CopyFieldIfExists(RecRef, 50001, 50011);
                CopyFieldIfExists(RecRef, 50007, 50012);
                CopyFieldIfExists(RecRef, 50008, 50013);
                CopyFieldIfExists(RecRef, 50009, 50014);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TariffNumberFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Tariff Number");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTenderTypeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Tender Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50007, 50008);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransSalesEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Sales Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransactionHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Transaction Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50020, 50037);
                CopyFieldIfExists(RecRef, 50025, 50038);
                CopyFieldIfExists(RecRef, 50026, 50039);
                CopyFieldIfExists(RecRef, 50027, 50040);
                CopyFieldIfExists(RecRef, 50028, 50041);
                CopyFieldIfExists(RecRef, 50029, 50042);
                CopyFieldIfExists(RecRef, 50030, 50043);
                CopyFieldIfExists(RecRef, 50031, 50044);
                CopyFieldIfExists(RecRef, 50032, 50045);
                CopyFieldIfExists(RecRef, 50033, 50046);
                CopyFieldIfExists(RecRef, 50034, 50047);
                CopyFieldIfExists(RecRef, 50035, 50048);
                CopyFieldIfExists(RecRef, 50036, 50049);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50009, 50011);
                CopyFieldIfExists(RecRef, 50010, 50012);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferReceiptHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Receipt Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50011);
                CopyFieldIfExists(RecRef, 50007, 50012);
                CopyFieldIfExists(RecRef, 50009, 50013);
                CopyFieldIfExists(RecRef, 50010, 50014);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferShipmentHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Shipment Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50009);
                CopyFieldIfExists(RecRef, 50007, 50010);
                CopyFieldIfExists(RecRef, 50008, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_UserSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"User Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50025);
                CopyFieldIfExists(RecRef, 50001, 50026);
                CopyFieldIfExists(RecRef, 50002, 50027);
                CopyFieldIfExists(RecRef, 50003, 50028);
                CopyFieldIfExists(RecRef, 50005, 50029);
                CopyFieldIfExists(RecRef, 50006, 50030);
                CopyFieldIfExists(RecRef, 50007, 50031);
                CopyFieldIfExists(RecRef, 50008, 50032);
                CopyFieldIfExists(RecRef, 50010, 50033);
                CopyFieldIfExists(RecRef, 50011, 50034);
                CopyFieldIfExists(RecRef, 50012, 50035);
                CopyFieldIfExists(RecRef, 50013, 50036);
                CopyFieldIfExists(RecRef, 50014, 50037);
                CopyFieldIfExists(RecRef, 50015, 50038);
                CopyFieldIfExists(RecRef, 50016, 50039);
                CopyFieldIfExists(RecRef, 50017, 50040);
                CopyFieldIfExists(RecRef, 50018, 50041);
                CopyFieldIfExists(RecRef, 50019, 50042);
                CopyFieldIfExists(RecRef, 50020, 50043);
                CopyFieldIfExists(RecRef, 50021, 50044);
                CopyFieldIfExists(RecRef, 50022, 50045);
                CopyFieldIfExists(RecRef, 50024, 50046);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ValueEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Value Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_VendorFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Vendor");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50014, 50034);
                CopyFieldIfExists(RecRef, 50015, 50035);
                CopyFieldIfExists(RecRef, 50016, 50036);
                CopyFieldIfExists(RecRef, 50017, 50037);
                CopyFieldIfExists(RecRef, 50018, 50038);
                CopyFieldIfExists(RecRef, 50019, 50039);
                CopyFieldIfExists(RecRef, 50020, 50040);
                CopyFieldIfExists(RecRef, 50021, 50041);
                CopyFieldIfExists(RecRef, 50022, 50042);
                CopyFieldIfExists(RecRef, 50023, 50043);
                CopyFieldIfExists(RecRef, 50024, 50044);
                CopyFieldIfExists(RecRef, 50025, 50045);
                CopyFieldIfExists(RecRef, 50026, 50046);
                CopyFieldIfExists(RecRef, 50027, 50047);
                CopyFieldIfExists(RecRef, 50028, 50048);
                CopyFieldIfExists(RecRef, 50029, 50049);
                CopyFieldIfExists(RecRef, 50030, 50050);
                CopyFieldIfExists(RecRef, 50031, 50051);
                CopyFieldIfExists(RecRef, 50032, 50052);
                CopyFieldIfExists(RecRef, 50033, 50053);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_WarehouseReceiptLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Warehouse Receipt Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
