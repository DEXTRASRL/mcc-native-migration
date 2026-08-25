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
    //
    // Fixed 2026-08-24 (code review, Critical finding on the FE/BELLON bridge retrofit): this
    // codeunit had NO Permissions property at all despite MigrateTableExt_DXNCFSetupFields()
    // declaring a typed Record on "DXR_NCF Setup" (Access = Internal in DR-Localization) and
    // calling Get()/Modify() on it - MCC's top-level permission set only grants codeunit Execute,
    // never tabledata, so per-object Permissions blocks are the sole runtime access mechanism in
    // this codebase. Adds the one entry actually required by that procedure's real Get/Modify
    // calls (no Insert anywhere in this procedure). NOTE: this codeunit's ~130+ other typed Record
    // calls (MigrateAllNormalizedTables/MigrateAllTableExtensionFields and their many helper
    // procedures, e.g. "AGR Setup"/"DXR_AGR Setup" et al.) also have no corresponding Permissions
    // entries and are a separate, much larger pre-existing gap predating this task - flagged here
    // for visibility, not fixed as part of this specific retrofit (out of scope for this task).
    //
    // Extended 2026-08-24 (Task B.1, BELLON-P2 MA-category whole-table-clone sweep): the 37 new
    // native procedures added below each declare a typed Legacy/New Record pair, so their 74
    // touched tables (37 source + 37 destination) need the same explicit per-object grant for the
    // same reason as "DXR_NCF Setup" above. Source tables only need R (FindSet/Next/CalcFields,
    // never modified); destination tables only need RI (Get + Insert - none of these procedures
    // ever call Modify, so RIM would be over-broad).
    //
    // Extended 2026-08-24 (Task B.1, BELLON-P2 MA-category tableextension field-group batch B1,
    // seq136/137/139/141): unlike the whole-table-clone batch above, this batch's field-group
    // procedures each read AND write the SAME table (a single "_DXR" field alongside its legacy
    // counterpart on one row), so the grant needed is RM (FindSet/Get + Modify), never RI. Covers
    // every table with a typed Record declared by this batch's 12 non-no-op procedures, plus
    // "Assembly Setup" (already typed/Direct from an earlier, out-of-band commit within this same
    // seq136 concept, bc6cae7, which never added its own Permissions entry - closing that gap here
    // rather than leaving a third undocumented instance of the same recurring mistake).
    //
    // Extended 2026-08-24 (Task B.1, BELLON-P2 MA-category tableextension field-group batch B2,
    // seq142/143/144/147/148): same RM rationale as batch B1 above. Covers every table with a typed
    // Record declared by this batch's 11 non-no-op procedures (6 of the batch's 17 procedures are
    // pure no-ops - FlowField-only pairs with no stored value to migrate - and declare no Record, so
    // need no grant).
    //
    // Extended 2026-08-24 (Task B.1, BELLON-P2 MA-category tableextension field-group batch B3,
    // FINAL batch, seq152/153/154/155/156): same RM rationale as batches B1/B2 above. Covers every
    // table with a typed Record declared by this batch's 14 non-no-op procedures (the 15th,
    // MigrateTableExt_TransferHeaderFields, is a no-op - its old field pairs are now fully
    // ObsoleteState = Removed, see that procedure's own comment - and declares no Record, so needs no
    // grant). Includes Vendor (master-data, elevated shadow-field scrutiny per this batch's brief).
    Permissions =
        tabledata "DXR_NCF Setup" = RM,
        tabledata "Bancos - Extracto Bancario" = R,
        tabledata "DXR_Bancos - Extracto Bancario" = RI,
        tabledata Bank = R,
        tabledata "DXR_Bank" = RI,
        tabledata "Bank Relation" = R,
        tabledata "DXR_Bank Relation" = RI,
        tabledata "Carga Masiva Beneficiarios BPD" = R,
        tabledata "DXR_Carga Masiva Benef BPD" = RI,
        tabledata Cilindros = R,
        tabledata "DXR_Cilindros" = RI,
        tabledata "Conversion Costo" = R,
        tabledata "DXR_Conversion Costo" = RI,
        tabledata "Detalle - Extracto Bancario" = R,
        tabledata "DXR_Detalle - Extr Bancario" = RI,
        tabledata "Entrega Facturas CxC - Lines" = R,
        tabledata "DXR_Entrega Fact CxC - Lines" = RI,
        tabledata "Envio Compras" = R,
        tabledata "DXR_Envio Compras" = RI,
        tabledata "Grupo Venta" = R,
        tabledata "DXR_Grupo Venta" = RI,
        tabledata "Internal Consumption Header" = R,
        tabledata "DXR_Int Consump Header" = RI,
        tabledata "Internal Consumption Line" = R,
        tabledata "DXR_Internal Consumption Line" = RI,
        tabledata "Item HTML" = R,
        tabledata "DXR_Item HTML" = RI,
        tabledata "Item Image View" = R,
        tabledata "DXR_Item Image View" = RI,
        tabledata "ItemNo Desliquidacion" = R,
        tabledata "DXR_ItemNo Desliquidacion" = RI,
        tabledata "Journal Promotion Tickets" = R,
        tabledata "DXR_Journal Promotion Tickets" = RI,
        tabledata "Lineas Carga Masiva Ben. BPD" = R,
        tabledata "DXR_Lin Carga Masiva Ben. BPD" = RI,
        tabledata "Movimientos de Cilindro" = R,
        tabledata "DXR_Movimientos de Cilindro" = RI,
        tabledata "Order Item Status" = R,
        tabledata "DXR_Order Item Status" = RI,
        tabledata "Pre Req LineNoStockValid" = R,
        tabledata "DXR_Pre Req LineNoStockValid" = RI,
        tabledata "Pre Req no Stock Valid" = R,
        tabledata "DXR_Pre Req no Stock Valid" = RI,
        tabledata "Pre-Requisicion" = R,
        tabledata "DXR_Pre-Requisicion" = RI,
        tabledata "Pre-Requisicion Line" = R,
        tabledata "DXR_Pre-Requisicion Line" = RI,
        tabledata "Pre-Requisicion Line No Stock" = R,
        tabledata "DXR_Pre-Req Line No Stock" = RI,
        tabledata "Pre-Requisicion no Stock" = R,
        tabledata "DXR_Pre-Requisicion no Stock" = RI,
        tabledata "Promotion Tickets Relation" = R,
        tabledata "DXR_Promotion Tickets Relation" = RI,
        tabledata Requisicion = R,
        tabledata "DXR_Requisicion" = RI,
        tabledata "Requisicion Comment Line" = R,
        tabledata "DXR_Requisicion Comment Line" = RI,
        tabledata "Requisicion Line" = R,
        tabledata "DXR_Requisicion Line" = RI,
        tabledata "Store Statement Posting" = R,
        tabledata "DXR_Store Statement Posting" = RI,
        tabledata "Tickets By Offer" = R,
        tabledata "DXR_Tickets By Offer" = RI,
        tabledata "Tickets Entry" = R,
        tabledata "DXR_Tickets Entry" = RI,
        tabledata "UserPromo Apps" = R,
        tabledata "DXR_UserPromo Apps" = RI,
        tabledata "Valoracion de Inventario" = R,
        tabledata "DXR_Valoracion de Inventario" = RI,
        tabledata "AGR Extended Item" = R,
        tabledata "DXR_AGR Extended Item" = RI,
        tabledata Comision_Grupo_Vendedor = R,
        tabledata "DXR_Comision_Grupo_Vendedor" = RI,
        tabledata "Inventory View" = R,
        tabledata "DXR_Inventory View." = RI,
        tabledata "Approval Entry" = RM,
        tabledata "Assembly Setup" = RM,
        tabledata "Bank Acc. Reconciliation" = RM,
        tabledata "Bank Acc. Reconciliation Line" = RM,
        tabledata "Bank Account" = RM,
        tabledata "Bank Account Ledger Entry" = RM,
        tabledata Currency = RM,
        tabledata "Currency Exchange Rate" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata Customer = RM,
        tabledata "Customer Price Group" = RM,
        tabledata "Issued Reminder Header" = RM,
        tabledata Item = RM,
        tabledata "Item Category" = RM,
        tabledata "Item Charge Assignment (Purch)" = RM,
        tabledata "Item Journal Line" = RM,
        tabledata "LSC Item Special Groups" = RM,
        tabledata "DXR_Cash Journal Receipt List" = RM,
        tabledata Location = RM,
        tabledata "LSC Member Contact" = RM,
        tabledata "LSC Member Point Offer" = RM,
        tabledata "LSC Periodic Discount" = RM,
        tabledata "LSC Posted Statement" = RM,
        tabledata "LSC Retail Product Group" = RM,
        tabledata "Purch. Comment Line" = RM,
        tabledata "Purch. Comment Line Archive" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Ship-to Address" = RM,
        tabledata "LSC Statement" = RM,
        tabledata "LSC STORE" = RM,
        tabledata "Tariff Number" = RM,
        tabledata "LSC Tender Type" = RM,
        tabledata "LSC Trans. Sales Entry" = RM,
        tabledata "LSC Transaction Header" = RM,
        tabledata "Transfer Line" = RM,
        tabledata "Transfer Receipt Header" = RM,
        tabledata "Transfer Shipment Header" = RM,
        tabledata "User Setup" = RM,
        tabledata "Value Entry" = RM,
        tabledata Vendor = RM,
        tabledata "Warehouse Receipt Line" = RM;

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

    procedure RunSetup()
    begin
        MigrateAGRSetupTable(); // AGR Setup -> DXR_AGR Setup (native - fixes NewRecRef.Open-inside-loop leak, see MigrateLegacyTableData)
        MigrateAjusteInventarioConfigTable(); // Ajuste Inventario Config -> DXR_Ajuste Inventario Config (native)
        MigrateAreaDeTrabajoTable(); // Area de Trabajo -> DXR_Area de Trabajo (native)
        MigrateCategoriaServiciosTable(); // Categoria Servicios -> DXR_Categoria Servicios (native)
        MigrateCilindrosSetupTable(); // Cilindros - Setup -> DXR_Cilindros - Setup (native)
        MigrateCodigosDeAuditoriaTable(); // Codigos de Auditoria -> DXR_Codigos de Auditoria. (native)
        MigrateConfExtractoBancarioTable(); // Conf. Extracto Bancario -> DXR_Conf. Extracto Bancario (native)
        MigrateConfigNCFVentasTable(); // Config. NCF Ventas -> DXR_Config. NCF Ventas (native)
        MigrateConfigNCFVentasSTDTable(); // Config. NCF Ventas STD -> DXR_Config. NCF Ventas STD (native)
        MigrateConfigPolizasTable(); // Config. Polizas -> DXR_Config. Polizas (native)
        MigrateConfiguracionCBTable(); // Configuracion CB -> DXR_Configuracion CB (native)
        MigrateConfiguracionDiscrepanciasTable(); // Configuracion - Discrepancias -> DXR_Config - Discr (native)
        MigrateConfiguracionEncuestasPOSTable(); // Configuracion Encuestas - POS -> DXR_Config Encuestas - POS (native)
        MigrateConfiguracionesRequisicionTable(); // Configuraciones Requisicion -> DXR_Config Req (native)
        MigrateConfiguracionMedalliaTable(); // Configuracion - MEDALLIA -> DXR_Configuracion - MEDALLIA (native)
        MigrateConfPagosEcommerceAzulTable(); // Conf. Pagos Ecommerce Azul -> DXR_Conf. Pagos Ecommerce Azul (native)
        MigrateControlProcesosPorAlmacenTable(); // Control Procesos por Almacen -> DXR_Control Proc por Almacen (native)
        MigrateDrawSetupTable(); // Draw Setup -> DXR_Draw Setup (native)
        MigrateEmailSourceTemplateRelationTable(); // Email Source Template Relation -> DXR_Email Source Tmpl Rel (native)
        MigrateEPagosSetupTable(); // EPagos Setup -> DXR_EPagos Setup (native)
        MigrateExcludeFilterJournalTable(); // Exclude Filter Journal -> DXR_Exclude Filter Journal (native)
        MigrateExcluirTerminosItemSearchTable(); // Excluir Terminos  - ItemSearch -> DXR_Excluir Term - ItemSearch (native)
        MigrateFileStructureTable(); // File Structure -> DXR_File Structure (native)
        MigrateFormaDePagoTable(); // Forma de Pago -> DXR_Forma de Pago (native)
        MigrateBEInventoryMasksTable(); // BE Inventory Masks -> DXR_Inventory Masks (native)
        MigrateMarcasTable(); // Marcas -> DXR_Marcas (native)
        MigrateMemberManagementSetupTable(); // Member Management Setup -> DXR_Member Management Setup (native)
        MigrateMotivoCierreDiscrepanciasTable(); // Motivo Cierre - Discrepancias -> DXR_Motivo Cierre - Discr (native)
        MigrateMotivoDiscrepanciaTable(); // Motivo Discrepancia -> DXR_Motivo Discrepancia (native)
        MigrateProfesionTable(); // Profesion -> DXR_Profesion (native)
        MigratePromotionSetupTable(); // Promotion Setup -> DXR_Promotion Setup (native)
        MigrateProvinciaTable(); // Provincia -> DXR_Provincia (native)
        MigrateSalesDeptTable(); // Sales Dept -> DXR_Sales Dept (native)
        MigrateSalesGroupsTable(); // Sales Groups -> DXR_Sales Groups (native)
        MigrateSalesSubGroupsTable(); // Sales SubGroups -> DXR_Sales SubGroups (native)
        MigrateStandardPOSDASCOMPaymtEqvTable(); // Standard POS DASCOM Paymt Eqv -> DXR_Std POS DASCOM Paymt Eqv (native)
        MigrateStandardPOSGenCommentsTable(); // Standard POS Gen. Comments -> DXR_Standard POS Gen. Comments (native)
        MigrateStandardPOSUsersTable(); // Standard POS Users -> DXR_Standard POS Users (native)
        MigrateSummaryReconciliationSetupTable(); // Summary Reconciliation Setup -> DXR_Summary Recon Setup (native)
        MigrateTasasBCTable(); // Tasas BC -> DXR_Tasas BC (native)
        MigrateTipoDeContenedorTable(); // Tipo de Contenedor -> DXR_Tipo de Contenedor (native)
        MigrateTipoGasTable(); // Tipo Gas -> DXR_Tipo Gas (native)
        MigrateTiposOAgentesTable(); // Tipos o Agentes -> DXR_Tipos o Agentes (native)
        MigrateTratadosArancelariosTable(); // Tratados Arancelarios -> DXR_Tratados Arancelarios (native)
        MigrateUserApproverByBuyerGroupTable(); // UserApproverByBuyerGroup -> DXR_UserApproverByBuyerGroup (native)
        MigrateUserByBuyerGroupTable(); // UserByBuyerGroup -> DXR_UserByBuyerGroup (native)
        MigrateVATBusSettingsTable(); // VAT Bus. Settings -> DXR_VAT Bus. Settings (native)
        MigrateOperacionesTipoComprobante2Table(); // Operaciones Tipo Comprobante2 -> DXR_Operaciones Tipo Comprob2 (native)
        MigrateTableExt_LSCBarcodesFields();
        MigrateTableExt_CheckLedgerEntryFields();
        MigrateTableExt_CompanyInformationFields();
        MigrateTableExt_CountryRegionFields();
        MigrateTableExt_GenJournalBatchFields();
        MigrateTableExt_GenJournalLineFields();
        MigrateTableExt_GenProductPostingGroupFields();
        MigrateTableExt_GeneralLedgerSetupFields();
        MigrateTableExt_DXVendorWithholdingLedgerEntryFields();
        MigrateTableExt_DXNCFSetupFields();
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
    end;

    procedure RunMaster()
    begin
        MigrateBancosExtractoBancarioTable(); // Bancos - Extracto Bancario -> DXR_Bancos - Extracto Bancario (native)
        MigrateBankTable(); // Bank -> DXR_Bank (native)
        MigrateBankRelationTable(); // Bank Relation -> DXR_Bank Relation (native)
        MigrateCargaMasivaBeneficiariosBPDTable(); // Carga Masiva Beneficiarios BPD -> DXR_Carga Masiva Benef BPD (native)
        MigrateCilindrosTable(); // Cilindros -> DXR_Cilindros (native)
        MigrateConversionCostoTable(); // Conversion Costo -> DXR_Conversion Costo (native)
        MigrateDetalleExtractoBancarioTable(); // Detalle - Extracto Bancario -> DXR_Detalle - Extr Bancario (native)
        MigrateEntregaFacturasCxCLinesTable(); // Entrega Facturas CxC - Lines -> DXR_Entrega Fact CxC - Lines (native)
        MigrateEnvioComprasTable(); // Envio Compras -> DXR_Envio Compras (native)
        MigrateGrupoVentaTable(); // Grupo Venta -> DXR_Grupo Venta (native)
        MigrateInternalConsumptionHeaderTable(); // Internal Consumption Header -> DXR_Int Consump Header (native)
        MigrateInternalConsumptionLineTable(); // Internal Consumption Line -> DXR_Internal Consumption Line (native)
        MigrateItemHTMLTable(); // Item HTML -> DXR_Item HTML (native)
        MigrateItemImageViewTable(); // Item Image View -> DXR_Item Image View (native)
        MigrateItemNoDesliquidacionTable(); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion (native)
        MigrateJournalPromotionTicketsTable(); // Journal Promotion Tickets -> DXR_Journal Promotion Tickets (native)
        MigrateLineasCargaMasivaBenBPDTable(); // Lineas Carga Masiva Ben. BPD -> DXR_Lin Carga Masiva Ben. BPD (native)
        MigrateMovimientosDeCilindroTable(); // Movimientos de Cilindro -> DXR_Movimientos de Cilindro (native)
        MigrateOrderItemStatusTable(); // Order Item Status -> DXR_Order Item Status (native)
        MigratePreReqLineNoStockValidTable(); // Pre Req LineNoStockValid -> DXR_Pre Req LineNoStockValid (native)
        MigratePreReqNoStockValidTable(); // Pre Req no Stock Valid -> DXR_Pre Req no Stock Valid (native)
        MigratePreRequisicionTable(); // Pre-Requisicion -> DXR_Pre-Requisicion (native)
        MigratePreRequisicionLineTable(); // Pre-Requisicion Line -> DXR_Pre-Requisicion Line (native)
        MigratePreRequisicionLineNoStockTable(); // Pre-Requisicion Line No Stock -> DXR_Pre-Req Line No Stock (native)
        MigratePreRequisicionNoStockTable(); // Pre-Requisicion no Stock -> DXR_Pre-Requisicion no Stock (native)
        MigratePromotionTicketsRelationTable(); // Promotion Tickets Relation -> DXR_Promotion Tickets Relation (native)
        MigrateRequisicionTable(); // Requisicion -> DXR_Requisicion (native)
        MigrateRequisicionCommentLineTable(); // Requisicion Comment Line -> DXR_Requisicion Comment Line (native)
        MigrateRequisicionLineTable(); // Requisicion Line -> DXR_Requisicion Line (native)
        MigrateStoreStatementPostingTable(); // Store Statement Posting -> DXR_Store Statement Posting (native)
        MigrateTicketsByOfferTable(); // Tickets By Offer -> DXR_Tickets By Offer (native)
        MigrateTicketsEntryTable(); // Tickets Entry -> DXR_Tickets Entry (native)
        MigrateUserPromoAppsTable(); // UserPromo Apps -> DXR_UserPromo Apps (native)
        MigrateValoracionDeInventarioTable(); // Valoracion de Inventario -> DXR_Valoracion de Inventario (native)
        MigrateAGRExtendedItemTable(); // AGR Extended Item -> DXR_AGR Extended Item (native)
        MigrateComisionGrupoVendedorTable(); // Comision_Grupo_Vendedor -> DXR_Comision_Grupo_Vendedor (native)
        MigrateInventoryViewTable(); // Inventory View -> DXR_Inventory View. (native)
        MigrateTableExt_ApprovalEntryFields();
        MigrateTableExt_AssemblyHeaderFields();
        MigrateTableExt_AssemblySetupFields();
        MigrateTableExt_VendorLedgerEntryFields();
        MigrateTableExt_BankAccReconciliationFields();
        MigrateTableExt_BankAccReconciliationLineFields();
        MigrateTableExt_BankAccountFields();
        MigrateTableExt_BankAccountLedgerEntryFields();
        MigrateTableExt_ContactFields();
        MigrateTableExt_CurrencyFields();
        MigrateTableExt_CurrencyExchangeRateFields();
        MigrateTableExt_CustLedgerEntryFields();
        MigrateTableExt_CustomerFields();
        MigrateTableExt_CustomerPriceGroupFields();
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
        MigrateTableExt_LSCPeriodicDiscountFields();
        MigrateTableExt_PostedAssemblyHeaderFields();
        MigrateTableExt_LSCPostedStatementFields();
        MigrateTableExt_LSCRetailProductGroupFields();
        MigrateTableExt_PurchCommentLineFields();
        MigrateTableExt_PurchCommentLineArchiveFields();
        MigrateTableExt_PurchInvLineFields();
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

    procedure RunHistoric()
    begin
        MigrateLegacyTableData(50004, 53302); // AGR Log -> DXR_AGR Log
        MigrateLegacyTableData(50071, 53341); // HisCargaMasivaBeneficiariosBPD -> DXR_HisCargaMasivaBenefBPD
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
        MigrateLegacyTableData(50095, 53357); // Internal Consumption Log -> DXR_Internal Consumption Log
        MigrateLegacyTableData(50111, 53366); // Log - Bank Statement -> DXR_Log - Bank Statement
        MigrateLegacyTableData(50112, 53367); // Log Email -> DXR_Log Email
        MigrateLegacyTableData(50115, 53368); // Log Transaccion Azul -> DXR_Log Transaccion Azul
        MigrateLegacyTableData(50116, 53369); // Log Transaccion Medallia -> DXR_Log Transaccion Medallia
        MigrateLegacyTableData(50117, 53370); // Log Transfer error -> DXR_Log Transfer error
        MigrateLegacyTableData(50132, 53377); // Posted Jnl Promotion Tickets -> DXR_Posted Jnl Promo Tickets
        MigrateLegacyTableData(50141, 53384); // Printing Invoice Log -> DXR_Printing Invoice Log
        MigrateLegacyTableData(50160, 53395); // Send Email Log -> DXR_Send Email Log
        MigrateLegacyTableData(50186, 53407); // Trans. Archive Line -> DXR_Trans. Archive Line
        MigrateLegacyTableData(50199, 53411); // UserLogs -> DXR_UserLogs
        MigrateLegacyTableData(50206, 53415); // Printing Invoice Log BO -> DXR_Printing Invoice Log BO
    end;

    procedure RunOther()
    begin
        MigrateLegacyTableData(50001, 53301); // Agente -> DXR_Agente
        MigrateLegacyTableData(50007, 53305); // Archivo - Discrepancias -> DXR_Archivo - Discrepancias
        MigrateLegacyTableData(50012, 53310); // Black List Promotion -> DXR_Black List Promotion
        MigrateLegacyTableData(50013, 53311); // Cabecera Discrepancia -> DXR_Cabecera Discrepancia
        MigrateLegacyTableData(50025, 53317); // Comentario - Discrepancias -> DXR_Comentario - Discrepancias
        MigrateLegacyTableData(50048, 53330); // Departamento - Discrepancias -> DXR_Departamento - Discr
        MigrateLegacyTableData(50103, 53363); // Linea Discrepancia -> DXR_Linea Discrepancia
        MigrateLegacyTableData(50109, 53365); // LineRQBuffer -> DXR_LineRQBuffer
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_PaymentMethodFields();
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
                // 2026-08-25 fix: NewRecRef.Close() was missing here, so the 2nd+ legacy row of
                // ANY multi-row table still served by this shared helper (~99 of BELLON-P2's 137
                // tables, the ones not yet converted to native per-table procedures) threw "The
                // record is already open." on the next loop iteration's Open() call, aborting the
                // whole OnRun() and rolling back the entire upgrade-tag-gated batch - the exact
                // "HIGH PRIORITY FIX" root-caused from a real production run but never actually
                // applied to this shared helper itself (only to the tables already carved out into
                // their own native procedures, which stopped sharing this bug by construction).
                NewRecRef.Close();
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
        MigrateAGRSetupTable(); // AGR Setup -> DXR_AGR Setup (native - fixes NewRecRef.Open-inside-loop leak, see MigrateLegacyTableData)
        MigrateAjusteInventarioConfigTable(); // Ajuste Inventario Config -> DXR_Ajuste Inventario Config (native)
        MigrateLegacyTableData(50007, 53305); // Archivo - Discrepancias -> DXR_Archivo - Discrepancias
        MigrateAreaDeTrabajoTable(); // Area de Trabajo -> DXR_Area de Trabajo (native)
        MigrateBancosExtractoBancarioTable(); // Bancos - Extracto Bancario -> DXR_Bancos - Extracto Bancario (native)
        MigrateBankTable(); // Bank -> DXR_Bank (native)
        MigrateBankRelationTable(); // Bank Relation -> DXR_Bank Relation (native)
        MigrateLegacyTableData(50012, 53310); // Black List Promotion -> DXR_Black List Promotion
        MigrateLegacyTableData(50013, 53311); // Cabecera Discrepancia -> DXR_Cabecera Discrepancia
        MigrateCargaMasivaBeneficiariosBPDTable(); // Carga Masiva Beneficiarios BPD -> DXR_Carga Masiva Benef BPD (native)
        MigrateCategoriaServiciosTable(); // Categoria Servicios -> DXR_Categoria Servicios (native)
        MigrateCilindrosTable(); // Cilindros -> DXR_Cilindros (native)
        MigrateCilindrosSetupTable(); // Cilindros - Setup -> DXR_Cilindros - Setup (native)
        MigrateCodigosDeAuditoriaTable(); // Codigos de Auditoria -> DXR_Codigos de Auditoria. (native)
        MigrateLegacyTableData(50025, 53317); // Comentario - Discrepancias -> DXR_Comentario - Discrepancias
        MigrateConfExtractoBancarioTable(); // Conf. Extracto Bancario -> DXR_Conf. Extracto Bancario (native)
        MigrateConfigNCFVentasTable(); // Config. NCF Ventas -> DXR_Config. NCF Ventas (native)
        MigrateConfigNCFVentasSTDTable(); // Config. NCF Ventas STD -> DXR_Config. NCF Ventas STD (native)
        MigrateConfigPolizasTable(); // Config. Polizas -> DXR_Config. Polizas (native)
        MigrateConfiguracionCBTable(); // Configuracion CB -> DXR_Configuracion CB (native)
        MigrateConfiguracionDiscrepanciasTable(); // Configuracion - Discrepancias -> DXR_Config - Discr (native)
        MigrateConfiguracionEncuestasPOSTable(); // Configuracion Encuestas - POS -> DXR_Config Encuestas - POS (native)
        MigrateConfiguracionesRequisicionTable(); // Configuraciones Requisicion -> DXR_Config Req (native)
        MigrateConfiguracionMedalliaTable(); // Configuracion - MEDALLIA -> DXR_Configuracion - MEDALLIA (native)
        MigrateConfPagosEcommerceAzulTable(); // Conf. Pagos Ecommerce Azul -> DXR_Conf. Pagos Ecommerce Azul (native)
        MigrateControlProcesosPorAlmacenTable(); // Control Procesos por Almacen -> DXR_Control Proc por Almacen (native)
        MigrateConversionCostoTable(); // Conversion Costo -> DXR_Conversion Costo (native)
        MigrateLegacyTableData(50048, 53330); // Departamento - Discrepancias -> DXR_Departamento - Discr
        MigrateDetalleExtractoBancarioTable(); // Detalle - Extracto Bancario -> DXR_Detalle - Extr Bancario (native)
        MigrateDrawSetupTable(); // Draw Setup -> DXR_Draw Setup (native)
        MigrateEmailSourceTemplateRelationTable(); // Email Source Template Relation -> DXR_Email Source Tmpl Rel (native)
        MigrateEntregaFacturasCxCLinesTable(); // Entrega Facturas CxC - Lines -> DXR_Entrega Fact CxC - Lines (native)
        MigrateEnvioComprasTable(); // Envio Compras -> DXR_Envio Compras (native)
        MigrateEPagosSetupTable(); // EPagos Setup -> DXR_EPagos Setup (native)
        MigrateExcludeFilterJournalTable(); // Exclude Filter Journal -> DXR_Exclude Filter Journal (native)
        MigrateExcluirTerminosItemSearchTable(); // Excluir Terminos  - ItemSearch -> DXR_Excluir Term - ItemSearch (native)
        MigrateFileStructureTable(); // File Structure -> DXR_File Structure (native)
        MigrateFormaDePagoTable(); // Forma de Pago -> DXR_Forma de Pago (native)
        MigrateLegacyTableData(50071, 53341); // HisCargaMasivaBeneficiariosBPD -> DXR_HisCargaMasivaBenefBPD
        MigrateGrupoVentaTable(); // Grupo Venta -> DXR_Grupo Venta (native)
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
        MigrateInternalConsumptionHeaderTable(); // Internal Consumption Header -> DXR_Int Consump Header (native)
        MigrateInternalConsumptionLineTable(); // Internal Consumption Line -> DXR_Internal Consumption Line (native)
        MigrateLegacyTableData(50095, 53357); // Internal Consumption Log -> DXR_Internal Consumption Log
        MigrateBEInventoryMasksTable(); // BE Inventory Masks -> DXR_Inventory Masks (native)
        MigrateItemHTMLTable(); // Item HTML -> DXR_Item HTML (native)
        MigrateItemImageViewTable(); // Item Image View -> DXR_Item Image View (native)
        MigrateItemNoDesliquidacionTable(); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion (native)
        MigrateJournalPromotionTicketsTable(); // Journal Promotion Tickets -> DXR_Journal Promotion Tickets (native)
        MigrateLegacyTableData(50103, 53363); // Linea Discrepancia -> DXR_Linea Discrepancia
        MigrateLineasCargaMasivaBenBPDTable(); // Lineas Carga Masiva Ben. BPD -> DXR_Lin Carga Masiva Ben. BPD (native)
        MigrateLegacyTableData(50109, 53365); // LineRQBuffer -> DXR_LineRQBuffer
        MigrateLegacyTableData(50111, 53366); // Log - Bank Statement -> DXR_Log - Bank Statement
        MigrateLegacyTableData(50112, 53367); // Log Email -> DXR_Log Email
        MigrateLegacyTableData(50115, 53368); // Log Transaccion Azul -> DXR_Log Transaccion Azul
        MigrateLegacyTableData(50116, 53369); // Log Transaccion Medallia -> DXR_Log Transaccion Medallia
        MigrateLegacyTableData(50117, 53370); // Log Transfer error -> DXR_Log Transfer error
        MigrateMarcasTable(); // Marcas -> DXR_Marcas (native)
        MigrateMemberManagementSetupTable(); // Member Management Setup -> DXR_Member Management Setup (native)
        MigrateMotivoCierreDiscrepanciasTable(); // Motivo Cierre - Discrepancias -> DXR_Motivo Cierre - Discr (native)
        MigrateMotivoDiscrepanciaTable(); // Motivo Discrepancia -> DXR_Motivo Discrepancia (native)
        MigrateMovimientosDeCilindroTable(); // Movimientos de Cilindro -> DXR_Movimientos de Cilindro (native)
        MigrateOrderItemStatusTable(); // Order Item Status -> DXR_Order Item Status (native)
        MigrateLegacyTableData(50132, 53377); // Posted Jnl Promotion Tickets -> DXR_Posted Jnl Promo Tickets
        MigratePreReqLineNoStockValidTable(); // Pre Req LineNoStockValid -> DXR_Pre Req LineNoStockValid (native)
        MigratePreReqNoStockValidTable(); // Pre Req no Stock Valid -> DXR_Pre Req no Stock Valid (native)
        MigratePreRequisicionTable(); // Pre-Requisicion -> DXR_Pre-Requisicion (native)
        MigratePreRequisicionLineTable(); // Pre-Requisicion Line -> DXR_Pre-Requisicion Line (native)
        MigratePreRequisicionLineNoStockTable(); // Pre-Requisicion Line No Stock -> DXR_Pre-Req Line No Stock (native)
        MigratePreRequisicionNoStockTable(); // Pre-Requisicion no Stock -> DXR_Pre-Requisicion no Stock (native)
        MigrateLegacyTableData(50141, 53384); // Printing Invoice Log -> DXR_Printing Invoice Log
        MigrateProfesionTable(); // Profesion -> DXR_Profesion (native)
        MigratePromotionSetupTable(); // Promotion Setup -> DXR_Promotion Setup (native)
        MigratePromotionTicketsRelationTable(); // Promotion Tickets Relation -> DXR_Promotion Tickets Relation (native)
        MigrateProvinciaTable(); // Provincia -> DXR_Provincia (native)
        MigrateRequisicionTable(); // Requisicion -> DXR_Requisicion (native)
        MigrateRequisicionCommentLineTable(); // Requisicion Comment Line -> DXR_Requisicion Comment Line (native)
        MigrateRequisicionLineTable(); // Requisicion Line -> DXR_Requisicion Line (native)
        MigrateSalesDeptTable(); // Sales Dept -> DXR_Sales Dept (native)
        MigrateSalesGroupsTable(); // Sales Groups -> DXR_Sales Groups (native)
        MigrateSalesSubGroupsTable(); // Sales SubGroups -> DXR_Sales SubGroups (native)
        MigrateLegacyTableData(50160, 53395); // Send Email Log -> DXR_Send Email Log
        MigrateStandardPOSDASCOMPaymtEqvTable(); // Standard POS DASCOM Paymt Eqv -> DXR_Std POS DASCOM Paymt Eqv (native)
        MigrateStandardPOSGenCommentsTable(); // Standard POS Gen. Comments -> DXR_Standard POS Gen. Comments (native)
        MigrateStandardPOSUsersTable(); // Standard POS Users -> DXR_Standard POS Users (native)
        MigrateStoreStatementPostingTable(); // Store Statement Posting -> DXR_Store Statement Posting (native)
        MigrateSummaryReconciliationSetupTable(); // Summary Reconciliation Setup -> DXR_Summary Recon Setup (native)
        MigrateTasasBCTable(); // Tasas BC -> DXR_Tasas BC (native)
        MigrateTicketsByOfferTable(); // Tickets By Offer -> DXR_Tickets By Offer (native)
        MigrateTicketsEntryTable(); // Tickets Entry -> DXR_Tickets Entry (native)
        MigrateTipoDeContenedorTable(); // Tipo de Contenedor -> DXR_Tipo de Contenedor (native)
        MigrateTipoGasTable(); // Tipo Gas -> DXR_Tipo Gas (native)
        MigrateTiposOAgentesTable(); // Tipos o Agentes -> DXR_Tipos o Agentes (native)
        MigrateLegacyTableData(50186, 53407); // Trans. Archive Line -> DXR_Trans. Archive Line
        MigrateTratadosArancelariosTable(); // Tratados Arancelarios -> DXR_Tratados Arancelarios (native)
        MigrateUserApproverByBuyerGroupTable(); // UserApproverByBuyerGroup -> DXR_UserApproverByBuyerGroup (native)
        MigrateUserByBuyerGroupTable(); // UserByBuyerGroup -> DXR_UserByBuyerGroup (native)
        MigrateLegacyTableData(50199, 53411); // UserLogs -> DXR_UserLogs
        MigrateUserPromoAppsTable(); // UserPromo Apps -> DXR_UserPromo Apps (native)
        MigrateValoracionDeInventarioTable(); // Valoracion de Inventario -> DXR_Valoracion de Inventario (native)
        MigrateVATBusSettingsTable(); // VAT Bus. Settings -> DXR_VAT Bus. Settings (native)
        MigrateLegacyTableData(50206, 53415); // Printing Invoice Log BO -> DXR_Printing Invoice Log BO
    end;

    // ===== 3) 4 more legacy table restores (added after the main list) =====

    local procedure MigrateAllNormalizedTables_Batch2()
    begin
        MigrateAGRExtendedItemTable(); // AGR Extended Item -> DXR_AGR Extended Item (native)
        MigrateComisionGrupoVendedorTable(); // Comision_Grupo_Vendedor -> DXR_Comision_Grupo_Vendedor (native)
        MigrateInventoryViewTable(); // Inventory View -> DXR_Inventory View. (native)
        MigrateOperacionesTipoComprobante2Table(); // Operaciones Tipo Comprobante2 -> DXR_Operaciones Tipo Comprob2 (native)
    end;

    // ===== 1b) 19 SETUP-category whole-table restores converted to native typed logic =====
    // Task A.4 Batch 1: zero RecordRef/FieldRef, zero TransferFields - every field assigned
    // explicitly. Replaces 19 of the MigrateLegacyTableData(...) calls above (still used by ~118
    // other, out-of-scope tables in MigrateAllNormalizedTables()) and eliminates, for these 19
    // tables specifically, the real production bug in MigrateLegacyTableData: it calls
    // NewRecRef.Open(NewTableId) INSIDE the repeat/until loop without ever closing it between
    // iterations, so the 2nd+ legacy row of any multi-row table throws "The record is already
    // open." Field lists and primary keys verified against Bellon_Customization's real
    // Tables.old\*.Table.al (legacy) and Tables\*.Table.al (DXR_) sources.

    // seq18: AGR Setup (50005) -> DXR_AGR Setup (53303). PK = "Primary Key".
    local procedure MigrateAGRSetupTable()
    var
        Legacy: Record "AGR Setup";
        New: Record "DXR_AGR Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Primary Key") then begin
                    New.Init();
                    New."Primary Key" := Legacy."Primary Key";
                    New."SQL Server" := Legacy."SQL Server";
                    New."SQL User ID" := Legacy."SQL User ID";
                    New."SQL Password" := Legacy."SQL Password";
                    New."SQL Database" := Legacy."SQL Database";
                    New."SQL Connection Timeout" := Legacy."SQL Connection Timeout";
                    New."Enable Log Cleanup" := Legacy."Enable Log Cleanup";
                    New."Keep History for" := Legacy."Keep History for";
                    New."Last Cleanup" := Legacy."Last Cleanup";
                    New."Req. Worksh. Template Name" := Legacy."Req. Worksh. Template Name";
                    New."Req. Worksh. Jrnl. Batch Name" := Legacy."Req. Worksh. Jrnl. Batch Name";
                    New."Plan. Worksh. Template Name" := Legacy."Plan. Worksh. Template Name";
                    New."Plan. Worksh. Jrnl. Batch Name" := Legacy."Plan. Worksh. Jrnl. Batch Name";
                    New.ProdOrderChoice := Legacy.ProdOrderChoice;
                    New.PurchOrderChoice := Legacy.PurchOrderChoice;
                    New.TransOrderChoice := Legacy.TransOrderChoice;
                    New.AsmOrderChoice := Legacy.AsmOrderChoice;
                    New."Auto Refresh Production Order" := Legacy."Auto Refresh Production Order";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq19: Ajuste Inventario Config (50006) -> DXR_Ajuste Inventario Config (53304).
    // PK = ("Item Padre", "Item Padre UM").
    local procedure MigrateAjusteInventarioConfigTable()
    var
        Legacy: Record "Ajuste Inventario Config";
        New: Record "DXR_Ajuste Inventario Config";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item Padre", Legacy."Item Padre UM") then begin
                    New.Init();
                    New."Item Padre" := Legacy."Item Padre";
                    New."Item Padre UM" := Legacy."Item Padre UM";
                    New."Item Hijo" := Legacy."Item Hijo";
                    New."Item Hijo UM" := Legacy."Item Hijo UM";
                    New."Cant. x UM Padre" := Legacy."Cant. x UM Padre";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq21: Area de Trabajo (50008) -> DXR_Area de Trabajo (53306). PK = "Code".
    local procedure MigrateAreaDeTrabajoTable()
    var
        Legacy: Record "Area de Trabajo";
        New: Record "DXR_Area de Trabajo";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq28: Categoria Servicios (50020) -> DXR_Categoria Servicios (53313). PK = "ID Services".
    local procedure MigrateCategoriaServiciosTable()
    var
        Legacy: Record "Categoria Servicios";
        New: Record "DXR_Categoria Servicios";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."ID Services") then begin
                    New.Init();
                    New."ID Services" := Legacy."ID Services";
                    New."Type Services" := Legacy."Type Services";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq30: Cilindros - Setup (50022) -> DXR_Cilindros - Setup (53315). PK = "Key".
    local procedure MigrateCilindrosSetupTable()
    var
        Legacy: Record "Cilindros - Setup";
        New: Record "DXR_Cilindros - Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."Cilindros No. Series" := Legacy."Cilindros No. Series";
                    New."Mov. Cilindros No. Series" := Legacy."Mov. Cilindros No. Series";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq31: Codigos de Auditoria (50024) -> DXR_Codigos de Auditoria. (53316, trailing period is
    // part of the real object name). PK = Code.
    local procedure MigrateCodigosDeAuditoriaTable()
    var
        Legacy: Record "Codigos de Auditoria";
        New: Record "DXR_Codigos de Auditoria.";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Code) then begin
                    New.Init();
                    New.Code := Legacy.Code;
                    New.Description := Legacy.Description;
                    New."Default Location Code" := Legacy."Default Location Code";
                    New."Inventory Value Zero" := Legacy."Inventory Value Zero";
                    New."Tipo Proceso" := Legacy."Tipo Proceso";
                    New."Key" := Legacy."Key";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq33: Conf. Extracto Bancario (50029) -> DXR_Conf. Extracto Bancario (53318). PK = "Key".
    local procedure MigrateConfExtractoBancarioTable()
    var
        Legacy: Record "Conf. Extracto Bancario";
        New: Record "DXR_Conf. Extracto Bancario";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New.Active := Legacy.Active;
                    New."Folder Patch" := Legacy."Folder Patch";
                    New."Days Run" := Legacy."Days Run";
                    New."Date Tolerance" := Legacy."Date Tolerance";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq34: Config. NCF Ventas (50032) -> DXR_Config. NCF Ventas (53319). PK = "Código".
    // Field 52120031 renamed on the target: "EF Alternal No. Series" (legacy) ->
    // "Alternal No. Series_DXR" (new), same field number/type - confirmed via
    // Tables.old\ConfigNCFVentas.Table.al vs Tables\ConfigNCFVentas.Table.al.
    local procedure MigrateConfigNCFVentasTable()
    var
        Legacy: Record "Config. NCF Ventas";
        New: Record "DXR_Config. NCF Ventas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Código") then begin
                    New.Init();
                    New."Código" := Legacy."Código";
                    New."Descripción" := Legacy."Descripción";
                    New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
                    New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
                    New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
                    New."Tipo NCF" := Legacy."Tipo NCF";
                    New."Alternal No. Series_DXR" := Legacy."EF Alternal No. Series";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq35: Config. NCF Ventas STD (50033) -> DXR_Config. NCF Ventas STD (53320).
    // PK = ("Código", "Terminal No."). Same field 52120031 rename as Config. NCF Ventas above.
    local procedure MigrateConfigNCFVentasSTDTable()
    var
        Legacy: Record "Config. NCF Ventas STD";
        New: Record "DXR_Config. NCF Ventas STD";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Código", Legacy."Terminal No.") then begin
                    New.Init();
                    New."Código" := Legacy."Código";
                    New."Descripción" := Legacy."Descripción";
                    New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
                    New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
                    New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
                    New."Store No." := Legacy."Store No.";
                    New."Terminal No." := Legacy."Terminal No.";
                    New."Tipo NCF" := Legacy."Tipo NCF";
                    New."Alternal No. Series_DXR" := Legacy."EF Alternal No. Series";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq36: Config. Polizas (50034) -> DXR_Config. Polizas (53321).
    // PK = ("Fecha Desde", "Fecha Hasta", "Monto Minimo", "Monto Maximo").
    local procedure MigrateConfigPolizasTable()
    var
        Legacy: Record "Config. Polizas";
        New: Record "DXR_Config. Polizas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Fecha Desde", Legacy."Fecha Hasta", Legacy."Monto Minimo", Legacy."Monto Maximo") then begin
                    New.Init();
                    New."Fecha Desde" := Legacy."Fecha Desde";
                    New."Fecha Hasta" := Legacy."Fecha Hasta";
                    New."Monto Minimo" := Legacy."Monto Minimo";
                    New."Monto Maximo" := Legacy."Monto Maximo";
                    New."Cantidad Cilindros" := Legacy."Cantidad Cilindros";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq37: Configuracion CB (50035) -> DXR_Configuracion CB (53322).
    // PK = (Bloque, "Reason Codes Filter", Orden).
    local procedure MigrateConfiguracionCBTable()
    var
        Legacy: Record "Configuracion CB";
        New: Record "DXR_Configuracion CB";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Bloque, Legacy."Reason Codes Filter", Legacy.Orden) then begin
                    New.Init();
                    New.Bloque := Legacy.Bloque;
                    New.Orden := Legacy.Orden;
                    New."Descripcion Renglon" := Legacy."Descripcion Renglon";
                    New."Reason Codes Filter" := Legacy."Reason Codes Filter";
                    New.Orientacion := Legacy.Orientacion;
                    New.Transito := Legacy.Transito;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq38: Configuracion - Discrepancias (50036) -> DXR_Config - Discr (53323). PK = "key".
    local procedure MigrateConfiguracionDiscrepanciasTable()
    var
        Legacy: Record "Configuracion - Discrepancias";
        New: Record "DXR_Config - Discr";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."key") then begin
                    New.Init();
                    New."key" := Legacy."key";
                    New."URL - Archivos Temporal" := Legacy."URL - Archivos Temporal";
                    New."URL  - Archivos Registrados" := Legacy."URL  - Archivos Registrados";
                    New."URL - Archivos Eliminados" := Legacy."URL - Archivos Eliminados";
                    New."No. Serie Discrepancia" := Legacy."No. Serie Discrepancia";
                    New."No. Serie Discrep. Registrada" := Legacy."No. Serie Discrep. Registrada";
                    New.AutoPost := Legacy.AutoPost;
                    New."Max Cantidad Dias retrocede" := Legacy."Max Cantidad Dias retrocede";
                    New."URL Lectura - Archivos Temp." := Legacy."URL Lectura - Archivos Temp.";
                    New."URL Lectura - Archivos Regis." := Legacy."URL Lectura - Archivos Regis.";
                    New."URL Lectura - Archivos Elimin." := Legacy."URL Lectura - Archivos Elimin.";
                    New."Reg Prod. in Discre." := Legacy."Reg Prod. in Discre.";
                    New."Control Disc. sin Attch" := Legacy."Control Disc. sin Attch";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq39: Configuracion Encuestas - POS (50037) -> DXR_Config Encuestas - POS (53324).
    // PK = ("Store No.", "Pos Terminal No.", "Transacction No.").
    local procedure MigrateConfiguracionEncuestasPOSTable()
    var
        Legacy: Record "Configuracion Encuestas - POS";
        New: Record "DXR_Config Encuestas - POS";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Store No.", Legacy."Pos Terminal No.", Legacy."Transacction No.") then begin
                    New.Init();
                    New."Store No." := Legacy."Store No.";
                    New."Pos Terminal No." := Legacy."Pos Terminal No.";
                    New."Transacction No." := Legacy."Transacction No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq40: Configuraciones Requisicion (50038) -> DXR_Config Req (53325). PK = "Key".
    local procedure MigrateConfiguracionesRequisicionTable()
    var
        Legacy: Record "Configuraciones Requisicion";
        New: Record "DXR_Config Req";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."No. Serie Pre-Req" := Legacy."No. Serie Pre-Req";
                    New."No Serie Req" := Legacy."No Serie Req";
                    New."No Serie Pre-Req No Stock" := Legacy."No Serie Pre-Req No Stock";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq41: Configuracion - MEDALLIA (50039) -> DXR_Configuracion - MEDALLIA (53326). PK = "Key".
    local procedure MigrateConfiguracionMedalliaTable()
    var
        Legacy: Record "Configuracion - MEDALLIA";
        New: Record "DXR_Configuracion - MEDALLIA";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."Log Request" := Legacy."Log Request";
                    New."Log Response" := Legacy."Log Response";
                    New.MedalliaURL := Legacy.MedalliaURL;
                    New.UserCredentials := Legacy.UserCredentials;
                    New.PasswordCredentials := Legacy.PasswordCredentials;
                    New."Pedido Ventas" := Legacy."Pedido Ventas";
                    New.Transportacion := Legacy.Transportacion;
                    New."Facturas POS" := Legacy."Facturas POS";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq42: Conf. Pagos Ecommerce Azul (50040) -> DXR_Conf. Pagos Ecommerce Azul (53327).
    // PK = "Key".
    local procedure MigrateConfPagosEcommerceAzulTable()
    var
        Legacy: Record "Conf. Pagos Ecommerce Azul";
        New: Record "DXR_Conf. Pagos Ecommerce Azul";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New.MerchantID := Legacy.MerchantID;
                    New.MerchantName := Legacy.MerchantName;
                    New.MerchantType := Legacy.MerchantType;
                    New.CurrencyCode := Legacy.CurrencyCode;
                    New.ApprovedURL := Legacy.ApprovedURL;
                    New.DeclinedURL := Legacy.DeclinedURL;
                    New.CancelURL := Legacy.CancelURL;
                    New.LogoURL := Legacy.LogoURL;
                    New.ProductImageURL := Legacy.ProductImageURL;
                    New.DesignV2 := Legacy.DesignV2;
                    New.Locale := Legacy.Locale;
                    New.AuthKey := Legacy.AuthKey;
                    New.PaymentPageUrl := Legacy.PaymentPageUrl;
                    New."Key" := Legacy."Key";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq43: Control Procesos por Almacen (50042) -> DXR_Control Proc por Almacen (53328).
    // PK = "Location Code".
    local procedure MigrateControlProcesosPorAlmacenTable()
    var
        Legacy: Record "Control Procesos por Almacen";
        New: Record "DXR_Control Proc por Almacen";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Location Code") then begin
                    New.Init();
                    New."Location Code" := Legacy."Location Code";
                    New.Ventas := Legacy.Ventas;
                    New.Compras := Legacy.Compras;
                    New.Ajustes := Legacy.Ajustes;
                    New.Ensamblados := Legacy.Ensamblados;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq47: Draw Setup (50052) -> DXR_Draw Setup (53332). PK = "Entry No.".
    // Field "Ready" (6) is a FlowField (CalcFormula) on both sides - not copied, calculated on
    // read.
    local procedure MigrateDrawSetupTable()
    var
        Legacy: Record "Draw Setup";
        New: Record "DXR_Draw Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Entry No.") then begin
                    New.Init();
                    New.Promotions := Legacy.Promotions;
                    New."Draw Date" := Legacy."Draw Date";
                    New.Description := Legacy.Description;
                    New."Winning customer" := Legacy."Winning customer";
                    New."Winning Ticket" := Legacy."Winning Ticket";
                    New."Entry No." := Legacy."Entry No.";
                    New.Done := Legacy.Done;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq48: Email Source Template Relation (50055) -> DXR_Email Source Tmpl Rel (53333).
    // PK = ("Email Template ID", "Email Source Table ID", "Field Email No."). Field
    // "Field Email Name" (5) is a FlowField (CalcFormula) on both sides - not copied.
    local procedure MigrateEmailSourceTemplateRelationTable()
    var
        Legacy: Record "Email Source Template Relation";
        New: Record "DXR_Email Source Tmpl Rel";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Email Template ID", Legacy."Email Source Table ID", Legacy."Field Email No.") then begin
                    New.Init();
                    New."Email Template ID" := Legacy."Email Template ID";
                    New."Email Source Table ID" := Legacy."Email Source Table ID";
                    New."Email Source Table Name" := Legacy."Email Source Table Name";
                    New."Field Email No." := Legacy."Field Email No.";
                    New.CC := Legacy.CC;
                    New."Requerir Correo" := Legacy."Requerir Correo";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // ===== 1c) 19 more SETUP-category whole-table restores converted to native typed logic =====
    // Task A.4 Batch 2: zero RecordRef/FieldRef, zero TransferFields - every field assigned
    // explicitly. Replaces 19 more of the MigrateLegacyTableData(...) calls above (still used by
    // ~99 other, out-of-scope tables in MigrateAllNormalizedTables()) and eliminates, for these 19
    // tables specifically, the same real production bug in MigrateLegacyTableData documented above
    // Batch 1 (NewRecRef.Open inside the repeat/until loop without closing between iterations).
    // Field lists and primary keys verified against Bellon_Customization's real Tables.old\*.Table.al
    // (legacy) and Tables\*.Table.al (DXR_) sources - field-for-field identical on both sides for
    // all 19 tables in this batch, no renamed/shadow fields found.

    // seq51: EPagos Setup (50061) -> DXR_EPagos Setup (53336). PK = "Primary Key".
    local procedure MigrateEPagosSetupTable()
    var
        Legacy: Record "EPagos Setup";
        New: Record "DXR_EPagos Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Primary Key") then begin
                    New.Init();
                    New."Primary Key" := Legacy."Primary Key";
                    New."Journal Template Name" := Legacy."Journal Template Name";
                    New."Journal Batch Name" := Legacy."Journal Batch Name";
                    New."Epago WS url" := Legacy."Epago WS url";
                    New.User := Legacy.User;
                    New.Password := Legacy.Password;
                    New."No Series" := Legacy."No Series";
                    New."Use Upproval" := Legacy."Use Upproval";
                    New.UserBPD := Legacy.UserBPD;
                    New.PassBPD := Legacy.PassBPD;
                    New.PathCert := Legacy.PathCert;
                    New.passCert := Legacy.passCert;
                    New.NoLote := Legacy.NoLote;
                    New."Url Login" := Legacy."Url Login";
                    New."Url Send Data" := Legacy."Url Send Data";
                    New."Url Status Global" := Legacy."Url Status Global";
                    New.Url := Legacy.Url;
                    New."Payment Method Code" := Legacy."Payment Method Code";
                    New."No Series Journal" := Legacy."No Series Journal";
                    New."VendorPay No. Series" := Legacy."VendorPay No. Series";
                    New."CreditTo No. Series" := Legacy."CreditTo No. Series";
                    New.ShowJson := Legacy.ShowJson;
                    New."Deny Multi Currency" := Legacy."Deny Multi Currency";
                    New."Use StartSession" := Legacy."Use StartSession";
                    New."Registrar Movs. Consolidados" := Legacy."Registrar Movs. Consolidados";
                    New."Registro Automatico" := Legacy."Registro Automatico";
                    New."Use Limit ACH" := Legacy."Use Limit ACH";
                    New."Amount Limit ACH" := Legacy."Amount Limit ACH";
                    New.DaysTo := Legacy.DaysTo;
                    New.DaysFrom := Legacy.DaysFrom;
                    New.NextDay := Legacy.NextDay;
                    New."Use Status LOG" := Legacy."Use Status LOG";
                    New."Max Days  Allow Payment" := Legacy."Max Days  Allow Payment";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq52: Exclude Filter Journal (50063) -> DXR_Exclude Filter Journal (53337).
    // PK = ("Journal Template", "Journal Batch").
    local procedure MigrateExcludeFilterJournalTable()
    var
        Legacy: Record "Exclude Filter Journal";
        New: Record "DXR_Exclude Filter Journal";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Journal Template", Legacy."Journal Batch") then begin
                    New.Init();
                    New."Journal Template" := Legacy."Journal Template";
                    New."Journal Batch" := Legacy."Journal Batch";
                    New.Excluir := Legacy.Excluir;
                    New.Type := Legacy.Type;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq53: Excluir Terminos  - ItemSearch (50064) -> DXR_Excluir Term - ItemSearch (53338).
    // PK = Termino. (Legacy object name has two spaces between "Terminos" and the dash - confirmed
    // via Tables.old\ExcluirTerminosItemSearch.Table.al line 1.)
    local procedure MigrateExcluirTerminosItemSearchTable()
    var
        Legacy: Record "Excluir Terminos  - ItemSearch";
        New: Record "DXR_Excluir Term - ItemSearch";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Termino) then begin
                    New.Init();
                    New.Termino := Legacy.Termino;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq54: File Structure (50065) -> DXR_File Structure (53339). PK = (Bank, "Field No").
    local procedure MigrateFileStructureTable()
    var
        Legacy: Record "File Structure";
        New: Record "DXR_File Structure";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Bank, Legacy."Field No") then begin
                    New.Init();
                    New."Field No" := Legacy."Field No";
                    New."Field Name" := Legacy."Field Name";
                    New."Length Field" := Legacy."Length Field";
                    New."From Field" := Legacy."From Field";
                    New.Bank := Legacy.Bank;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq55: Forma de Pago (50068) -> DXR_Forma de Pago (53340). PK = "Code".
    local procedure MigrateFormaDePagoTable()
    var
        Legacy: Record "Forma de Pago";
        New: Record "DXR_Forma de Pago";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq73: BE Inventory Masks (50096) -> DXR_Inventory Masks (53358). PK = "Seq. No.".
    local procedure MigrateBEInventoryMasksTable()
    var
        Legacy: Record "BE Inventory Masks";
        New: Record "DXR_Inventory Masks";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Seq. No.") then begin
                    New.Init();
                    New.Templates := Legacy.Templates;
                    New."Handheld User" := Legacy."Handheld User";
                    New."Store No." := Legacy."Store No.";
                    New."Entry Type" := Legacy."Entry Type";
                    New."Reason Code" := Legacy."Reason Code";
                    New.Unit := Legacy.Unit;
                    New."Vendor No." := Legacy."Vendor No.";
                    New.Description := Legacy.Description;
                    New."Journal Type" := Legacy."Journal Type";
                    New.Printing := Legacy.Printing;
                    New.Posting := Legacy.Posting;
                    New."Type of Entering" := Legacy."Type of Entering";
                    New."Shortcut Dimension 2 Code" := Legacy."Shortcut Dimension 2 Code";
                    New."New Store Code" := Legacy."New Store Code";
                    New."Source Code" := Legacy."Source Code";
                    New."Seq. No." := Legacy."Seq. No.";
                    New."Product Strict" := Legacy."Product Strict";
                    New.Accepted := Legacy.Accepted;
                    New.Location := Legacy.Location;
                    New."New Location" := Legacy."New Location";
                    New.Batch := Legacy.Batch;
                    New."Use Variants" := Legacy."Use Variants";
                    New."Shortcut Dimension 1 Code" := Legacy."Shortcut Dimension 1 Code";
                    New."Pre-Process" := Legacy."Pre-Process";
                    New."Pre-Process Object ID" := Legacy."Pre-Process Object ID";
                    New."Close Process" := Legacy."Close Process";
                    New."Close Process Object ID" := Legacy."Close Process Object ID";
                    New."Confirm Codeunit" := Legacy."Confirm Codeunit";
                    New."Report Object ID" := Legacy."Report Object ID";
                    New."Product Group Filter" := Legacy."Product Group Filter";
                    New."Inv. Posting Gr. Filter" := Legacy."Inv. Posting Gr. Filter";
                    New."Use Area" := Legacy."Use Area";
                    New."Handheld Type" := Legacy."Handheld Type";
                    New."Blocked for RF" := Legacy."Blocked for RF";
                    New."Leading Behavior" := Legacy."Leading Behavior";
                    New."Needs to Be in Distribution" := Legacy."Needs to Be in Distribution";
                    New."Needs to Be in Worksheet" := Legacy."Needs to Be in Worksheet";
                    New."Needs to Be Ordered by Hand" := Legacy."Needs to Be Ordered by Hand";
                    New."Needs to Be Ordered at Store" := Legacy."Needs to Be Ordered at Store";
                    New."Search for Item by" := Legacy."Search for Item by";
                    New."Quantity Method" := Legacy."Quantity Method";
                    New."Order Date Type" := Legacy."Order Date Type";
                    New."Order Date Calculation" := Legacy."Order Date Calculation";
                    New."End Date Type" := Legacy."End Date Type";
                    New."End Date Calculation" := Legacy."End Date Calculation";
                    New."Change Vendor in Line" := Legacy."Change Vendor in Line";
                    New."Change UOM in Line" := Legacy."Change UOM in Line";
                    New."Item Check" := Legacy."Item Check";
                    New."Quick-default Quantity" := Legacy."Quick-default Quantity";
                    New."Inv. Adjust. Group" := Legacy."Inv. Adjust. Group";
                    New."Vendor to Use in Returns" := Legacy."Vendor to Use in Returns";
                    New."Return Reason Code" := Legacy."Return Reason Code";
                    New."Item Journal Doc No." := Legacy."Item Journal Doc No.";
                    New.Status := Legacy.Status;
                    New."Use Batch Posting" := Legacy."Use Batch Posting";
                    New."Order Status" := Legacy."Order Status";
                    New."Standalone Store Action" := Legacy."Standalone Store Action";
                    New."Document Group" := Legacy."Document Group";
                    New.ID := Legacy.ID;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq86: Marcas (50118) -> DXR_Marcas (53371). PK = ID.
    local procedure MigrateMarcasTable()
    var
        Legacy: Record Marcas;
        New: Record "DXR_Marcas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.ID) then begin
                    New.Init();
                    New.ID := Legacy.ID;
                    New.Descripcion := Legacy.Descripcion;
                    New.Comision_Venta := Legacy.Comision_Venta;
                    New.Comision_Cobro := Legacy.Comision_Cobro;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq87: Member Management Setup (50119) -> DXR_Member Management Setup (53372). PK = "Code".
    local procedure MigrateMemberManagementSetupTable()
    var
        Legacy: Record "Member Management Setup";
        New: Record "DXR_Member Management Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New."Campaign No. Series" := Legacy."Campaign No. Series";
                    New."Discount Tracking No. Series" := Legacy."Discount Tracking No. Series";
                    New."Member Point Offer No. Series" := Legacy."Member Point Offer No. Series";
                    New."Missing  Attribute Handling" := Legacy."Missing  Attribute Handling";
                    New."Reason Blocking By Attribute" := Legacy."Reason Blocking By Attribute";
                    New."Reason Codes Devices" := Legacy."Reason Codes Devices";
                    New."Amount Type for Point Calc." := Legacy."Amount Type for Point Calc.";
                    New."Mobile Default Club Code" := Legacy."Mobile Default Club Code";
                    New."Mobile Card No. Series" := Legacy."Mobile Card No. Series";
                    New."Min. Point Balance" := Legacy."Min. Point Balance";
                    New."Min. Point Qty. in Redemption" := Legacy."Min. Point Qty. in Redemption";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq88: Motivo Cierre - Discrepancias (50121) -> DXR_Motivo Cierre - Discr (53373). PK = "Code".
    local procedure MigrateMotivoCierreDiscrepanciasTable()
    var
        Legacy: Record "Motivo Cierre - Discrepancias";
        New: Record "DXR_Motivo Cierre - Discr";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Anular := Legacy.Anular;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq89: Motivo Discrepancia (50122) -> DXR_Motivo Discrepancia (53374). PK = "Code".
    local procedure MigrateMotivoDiscrepanciaTable()
    var
        Legacy: Record "Motivo Discrepancia";
        New: Record "DXR_Motivo Discrepancia";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Description := Legacy.Description;
                    New.Habilitado := Legacy.Habilitado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq100: Profesion (50142) -> DXR_Profesion (53385). PK = "Code".
    local procedure MigrateProfesionTable()
    var
        Legacy: Record Profesion;
        New: Record "DXR_Profesion";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq101: Promotion Setup (50143) -> DXR_Promotion Setup (53386). PK = "Key".
    local procedure MigratePromotionSetupTable()
    var
        Legacy: Record "Promotion Setup";
        New: Record "DXR_Promotion Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."Promotion Active" := Legacy."Promotion Active";
                    New."No Series Tickets" := Legacy."No Series Tickets";
                    New."No Series Promotions" := Legacy."No Series Promotions";
                    New."Journal Template Name" := Legacy."Journal Template Name";
                    New."Journal Batch Name" := Legacy."Journal Batch Name";
                    New."Registro Automatico" := Legacy."Registro Automatico";
                    New.InfocedePOS := Legacy.InfocedePOS;
                    New.InfocedePOSRnc := Legacy.InfocedePOSRnc;
                    New.InfocedePOStlf := Legacy.InfocedePOStlf;
                    New."Max Point Change" := Legacy."Max Point Change";
                    New."Min Point Change" := Legacy."Min Point Change";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq103: Provincia (50145) -> DXR_Provincia (53388). PK = "Code".
    local procedure MigrateProvinciaTable()
    var
        Legacy: Record Provincia;
        New: Record "DXR_Provincia";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Name := Legacy.Name;
                    New."Cod. BPD" := Legacy."Cod. BPD";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq107: Sales Dept (50154) -> DXR_Sales Dept (53392). PK = "Code".
    local procedure MigrateSalesDeptTable()
    var
        Legacy: Record "Sales Dept";
        New: Record "DXR_Sales Dept";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Description := Legacy.Description;
                    New."Visible in Webshop" := Legacy."Visible in Webshop";
                    New."Sort No." := Legacy."Sort No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq108: Sales Groups (50155) -> DXR_Sales Groups (53393). PK = "Code".
    local procedure MigrateSalesGroupsTable()
    var
        Legacy: Record "Sales Groups";
        New: Record "DXR_Sales Groups";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Description := Legacy.Description;
                    New."Visible in Webshop" := Legacy."Visible in Webshop";
                    New."Sales Dept Code" := Legacy."Sales Dept Code";
                    New."Sort No." := Legacy."Sort No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq109: Sales SubGroups (50159) -> DXR_Sales SubGroups (53394). PK = "Code".
    local procedure MigrateSalesSubGroupsTable()
    var
        Legacy: Record "Sales SubGroups";
        New: Record "DXR_Sales SubGroups";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Description := Legacy.Description;
                    New."Visible in Webshop" := Legacy."Visible in Webshop";
                    New."Sort No." := Legacy."Sort No.";
                    New."Sales Group" := Legacy."Sales Group";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq111: Standard POS DASCOM Paymt Eqv (50165) -> DXR_Std POS DASCOM Paymt Eqv (53396).
    // PK = "Payment Code".
    local procedure MigrateStandardPOSDASCOMPaymtEqvTable()
    var
        Legacy: Record "Standard POS DASCOM Paymt Eqv";
        New: Record "DXR_Std POS DASCOM Paymt Eqv";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Payment Code") then begin
                    New.Init();
                    New."Payment Code" := Legacy."Payment Code";
                    New.Description := Legacy.Description;
                    New."DASCOM Eqv" := Legacy."DASCOM Eqv";
                    New."User Created" := Legacy."User Created";
                    New."Date Created" := Legacy."Date Created";
                    New."User Last Modified" := Legacy."User Last Modified";
                    New."Last Date Modified" := Legacy."Last Date Modified";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq112: Standard POS Gen. Comments (50168) -> DXR_Standard POS Gen. Comments (53397).
    // PK = ("Fiscal Doc. Type", "Line No.").
    local procedure MigrateStandardPOSGenCommentsTable()
    var
        Legacy: Record "Standard POS Gen. Comments";
        New: Record "DXR_Standard POS Gen. Comments";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Fiscal Doc. Type", Legacy."Line No.") then begin
                    New.Init();
                    New."Fiscal Doc. Type" := Legacy."Fiscal Doc. Type";
                    New."Line No." := Legacy."Line No.";
                    New."Text Message" := Legacy."Text Message";
                    New."User Created" := Legacy."User Created";
                    New."Date Created" := Legacy."Date Created";
                    New."User Last Modified" := Legacy."User Last Modified";
                    New."Last Date Modified" := Legacy."Last Date Modified";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq113: Standard POS Users (50172) -> DXR_Standard POS Users (53398). PK = "User Code".
    local procedure MigrateStandardPOSUsersTable()
    var
        Legacy: Record "Standard POS Users";
        New: Record "DXR_Standard POS Users";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."User Code") then begin
                    New.Init();
                    New."User Code" := Legacy."User Code";
                    New."Standard POS Store" := Legacy."Standard POS Store";
                    New."Standard POS Terminal" := Legacy."Standard POS Terminal";
                    New."User Name" := Legacy."User Name";
                    New.Inactive := Legacy.Inactive;
                    New."User Created" := Legacy."User Created";
                    New."Date Created" := Legacy."Date Created";
                    New."User Last Modified" := Legacy."User Last Modified";
                    New."Last Date Modified" := Legacy."Last Date Modified";
                    New."Filter Reg" := Legacy."Filter Reg";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // ===== 1d) 10 more SETUP-category whole-table restores converted to native typed logic =====
    // Task A.4 Batch 3a: zero RecordRef/FieldRef, zero TransferFields - every field assigned
    // explicitly. Replaces 10 more of the MigrateLegacyTableData(...) calls above (9 inside
    // MigrateAllNormalizedTables(), 1 inside MigrateAllNormalizedTables_Batch2()) and eliminates,
    // for these 10 tables specifically, the same real production bug in MigrateLegacyTableData
    // documented above Batch 1 (NewRecRef.Open inside the repeat/until loop without closing
    // between iterations). Field lists and primary keys verified against Bellon_Customization's
    // real Tables.old\*.Table.al (legacy) and Tables\*.Table.al (DXR_) sources - field-for-field
    // identical on both sides for all 10 tables in this batch, no renamed/shadow fields found.

    // seq115: Summary Reconciliation Setup (50174) -> DXR_Summary Recon Setup (53400). PK = Serial.
    local procedure MigrateSummaryReconciliationSetupTable()
    var
        Legacy: Record "Summary Reconciliation Setup";
        New: Record "DXR_Summary Recon Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Serial) then begin
                    New.Init();
                    New.Serial := Legacy.Serial;
                    New.Type := Legacy.Type;
                    New."Order" := Legacy."Order";
                    New."Type Text" := Legacy."Type Text";
                    New.Grupo := Legacy.Grupo;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq116: Tasas BC (50176) -> DXR_Tasas BC (53401). PK = "Fecha Tasa".
    local procedure MigrateTasasBCTable()
    var
        Legacy: Record "Tasas BC";
        New: Record "DXR_Tasas BC";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Fecha Tasa") then begin
                    New.Init();
                    New."Fecha Tasa" := Legacy."Fecha Tasa";
                    New.Tasa := Legacy.Tasa;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq119: Tipo de Contenedor (50180) -> DXR_Tipo de Contenedor (53404). PK = "Code".
    local procedure MigrateTipoDeContenedorTable()
    var
        Legacy: Record "Tipo de Contenedor";
        New: Record "DXR_Tipo de Contenedor";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq120: Tipo Gas (50181) -> DXR_Tipo Gas (53405). PK = Id.
    local procedure MigrateTipoGasTable()
    var
        Legacy: Record "Tipo Gas";
        New: Record "DXR_Tipo Gas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Id) then begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq121: Tipos o Agentes (50182) -> DXR_Tipos o Agentes (53406). PK = "Code".
    local procedure MigrateTiposOAgentesTable()
    var
        Legacy: Record "Tipos o Agentes";
        New: Record "DXR_Tipos o Agentes";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq123: Tratados Arancelarios (50195) -> DXR_Tratados Arancelarios (53408).
    // PK = (Arancel, Pais).
    local procedure MigrateTratadosArancelariosTable()
    var
        Legacy: Record "Tratados Arancelarios";
        New: Record "DXR_Tratados Arancelarios";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Arancel, Legacy.Pais) then begin
                    New.Init();
                    New.Arancel := Legacy.Arancel;
                    New.Pais := Legacy.Pais;
                    New."Tasa Arancel" := Legacy."Tasa Arancel";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq124: UserApproverByBuyerGroup (50197) -> DXR_UserApproverByBuyerGroup (53409).
    // PK = (UserID, "Buyer Group").
    local procedure MigrateUserApproverByBuyerGroupTable()
    var
        Legacy: Record UserApproverByBuyerGroup;
        New: Record "DXR_UserApproverByBuyerGroup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.UserID, Legacy."Buyer Group") then begin
                    New.Init();
                    New.UserID := Legacy.UserID;
                    New."Buyer Group" := Legacy."Buyer Group";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq125: UserByBuyerGroup (50198) -> DXR_UserByBuyerGroup (53410).
    // PK = (UserID, "Buyer Group Code").
    local procedure MigrateUserByBuyerGroupTable()
    var
        Legacy: Record UserByBuyerGroup;
        New: Record "DXR_UserByBuyerGroup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.UserID, Legacy."Buyer Group Code") then begin
                    New.Init();
                    New.UserID := Legacy.UserID;
                    New."Buyer Group Code" := Legacy."Buyer Group Code";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq129: VAT Bus. Settings (50202) -> DXR_VAT Bus. Settings (53414). PK = "code".
    local procedure MigrateVATBusSettingsTable()
    var
        Legacy: Record "VAT Bus. Settings";
        New: Record "DXR_VAT Bus. Settings";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."code") then begin
                    New.Init();
                    New."code" := Legacy."code";
                    New."VAT Bus. Posting GRoup" := Legacy."VAT Bus. Posting GRoup";
                    New.Usar := Legacy.Usar;
                    New."Tipo NCF Cliente" := Legacy."Tipo NCF Cliente";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq134: Operaciones Tipo Comprobante2 (50126) -> DXR_Operaciones Tipo Comprob2 (55007).
    // PK = Documento. Note target ID 55007 (not the usual 53xxx range) is real - called from
    // MigrateAllNormalizedTables_Batch2(), not MigrateAllNormalizedTables().
    local procedure MigrateOperacionesTipoComprobante2Table()
    var
        Legacy: Record "Operaciones Tipo Comprobante2";
        New: Record "DXR_Operaciones Tipo Comprob2";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Documento) then begin
                    New.Init();
                    New.Documento := Legacy.Documento;
                    New.NCF := Legacy.NCF;
                    New.Fecha := Legacy.Fecha;
                    New."Tipo Comprobante" := Legacy."Tipo Comprobante";
                    New."Monto sin ITBIS" := Legacy."Monto sin ITBIS";
                    New."Monto con ITBIS" := Legacy."Monto con ITBIS";
                    New.Origen := Legacy.Origen;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // ===== 1e) 37 MA-category whole-table restores converted to native typed logic =====
    // Task B.1 (BELLON-P2) Batch 1: zero RecordRef/FieldRef, zero TransferFields - every field
    // assigned explicitly. Replaces 34 of the MigrateLegacyTableData(...) calls inside
    // MigrateAllNormalizedTables() and 3 more inside MigrateAllNormalizedTables_Batch2(), and
    // eliminates, for these 37 tables specifically, the same real production bug in
    // MigrateLegacyTableData documented above Batch 1 (NewRecRef.Open inside the repeat/until loop
    // without closing between iterations). Field lists and primary keys verified against
    // Bellon_Customization's real Tables.old\*.Table.al (legacy) and Tables\*.Table.al (DXR_)
    // sources - no field-level ObsoleteState/ObsoleteReason found on any of the 37 destination
    // tables (shadow-field check clean). "Detalle - Extracto Bancario"/"DXR_Detalle - Extr
    // Bancario" (EntryNo) and "Pre Req LineNoStockValid"/"DXR_Pre Req LineNoStockValid" ("Line
    // Num") have an AutoIncrement primary-key field - the legacy value is copied directly, same
    // established precedent as MigrateDrawSetupTable() above. "Tickets Entry"/"DXR_Tickets Entry"
    // has a non-key AutoIncrement field ("Entry No.") that is also copied directly to preserve the
    // legacy value (its Get()/PK is "Tickets No."). "Item HTML"/"DXR_Item HTML" has three BLOB
    // fields (Html, "Descripcion Extendida", Caracteristicas) - copied via CalcFields() +
    // CreateInStream()/CreateOutStream()/CopyStream() directly on the typed BLOB fields, never by
    // direct field assignment and never via RecordRef/FieldRef (see MigrateItemHTMLTable() for
    // why Codeunit "Temp Blob" itself could not be used unchanged). "Item Image
    // View"/"DXR_Item Image View" and "Inventory View"/"DXR_Inventory View." are both
    // LinkedObject = true on both sides (pre-existing in the real source, not introduced here).

    // seq22: Bancos - Extracto Bancario (50009) -> DXR_Bancos - Extracto Bancario (53307).
    // PK = "Bank Code". Field "Nombre" (2) is a FlowField (CalcFormula) on both sides - not
    // copied, calculated on read.
    local procedure MigrateBancosExtractoBancarioTable()
    var
        Legacy: Record "Bancos - Extracto Bancario";
        New: Record "DXR_Bancos - Extracto Bancario";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Bank Code") then begin
                    New.Init();
                    New."Bank Code" := Legacy."Bank Code";
                    New.Url := Legacy.Url;
                    New.User := Legacy.User;
                    New.Password := Legacy.Password;
                    New."Formato Banco" := Legacy."Formato Banco";
                    New."Format Mt940" := Legacy."Format Mt940";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq23: Bank (50010) -> DXR_Bank (53308). PK = Bank.
    local procedure MigrateBankTable()
    var
        Legacy: Record Bank;
        New: Record "DXR_Bank";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Bank) then begin
                    New.Init();
                    New.Bank := Legacy.Bank;
                    New."Bank name" := Legacy."Bank name";
                    New."Cod. BPD" := Legacy."Cod. BPD";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq24: Bank Relation (50011) -> DXR_Bank Relation (53309). PK = ("Cod. Banco", Bank). Field
    // "Bank Account No" (3) is a FlowField (CalcFormula) on both sides - not copied.
    local procedure MigrateBankRelationTable()
    var
        Legacy: Record "Bank Relation";
        New: Record "DXR_Bank Relation";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Cod. Banco", Legacy.Bank) then begin
                    New.Init();
                    New."Cod. Banco" := Legacy."Cod. Banco";
                    New.Bank := Legacy.Bank;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq27: Carga Masiva Beneficiarios BPD (50016) -> DXR_Carga Masiva Benef BPD (53312).
    // PK = "Numero de ID". Field "Provincia" (18) is a FlowField (CalcFormula) on both sides -
    // not copied.
    local procedure MigrateCargaMasivaBeneficiariosBPDTable()
    var
        Legacy: Record "Carga Masiva Beneficiarios BPD";
        New: Record "DXR_Carga Masiva Benef BPD";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Numero de ID") then begin
                    New.Init();
                    New."Tipo de Registro" := Legacy."Tipo de Registro";
                    New."Tipo de ID" := Legacy."Tipo de ID";
                    New."Numero de ID" := Legacy."Numero de ID";
                    New."RNC del pagador" := Legacy."RNC del pagador";
                    New."Tipo de Beneficiario" := Legacy."Tipo de Beneficiario";
                    New."Nombre de la Empresa" := Legacy."Nombre de la Empresa";
                    New.Calle := Legacy.Calle;
                    New.Numero := Legacy.Numero;
                    New."Sector / Poblacion" := Legacy."Sector / Poblacion";
                    New."Cod. Provincia" := Legacy."Cod. Provincia";
                    New.Telefono := Legacy.Telefono;
                    New.Extension := Legacy.Extension;
                    New.Movil := Legacy.Movil;
                    New."Correo Electronico" := Legacy."Correo Electronico";
                    New."Codigo interno  beneficiario" := Legacy."Codigo interno  beneficiario";
                    New."Tipo Documento BPD" := Legacy."Tipo Documento BPD";
                    New."Tipo de cuenta contrato" := Legacy."Tipo de cuenta contrato";
                    New."Vendor No." := Legacy."Vendor No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq29: Cilindros (50021) -> DXR_Cilindros (53314). PK = Id. Fields "Nombre Gas" (8) and
    // "Nombre Propietario" (10) are FlowFields (CalcFormula) on both sides - not copied.
    // Insert(false) intentionally skips the table's own OnInsert trigger (No. Series auto-gen /
    // "Fecha Entrada" := Today), preserving the legacy row's raw values, same as every other
    // procedure in this file.
    local procedure MigrateCilindrosTable()
    var
        Legacy: Record Cilindros;
        New: Record "DXR_Cilindros";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Id) then begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Propietario := Legacy.Propietario;
                    New."Fecha Entrada" := Legacy."Fecha Entrada";
                    New."Fecha Salida" := Legacy."Fecha Salida";
                    New."Motivo Salida" := Legacy."Motivo Salida";
                    New.Serial := Legacy.Serial;
                    New."Id Gas" := Legacy."Id Gas";
                    New.Disponible := Legacy.Disponible;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq44: Conversion Costo (50043) -> DXR_Conversion Costo (53329). PK = Valor.
    local procedure MigrateConversionCostoTable()
    var
        Legacy: Record "Conversion Costo";
        New: Record "DXR_Conversion Costo";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Valor) then begin
                    New.Init();
                    New.Valor := Legacy.Valor;
                    New.Equivalencia := Legacy.Equivalencia;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq46: Detalle - Extracto Bancario (50050) -> DXR_Detalle - Extr Bancario (53331).
    // PK = EntryNo, AutoIncrement - legacy value copied directly, same established precedent as
    // MigrateDrawSetupTable() above.
    local procedure MigrateDetalleExtractoBancarioTable()
    var
        Legacy: Record "Detalle - Extracto Bancario";
        New: Record "DXR_Detalle - Extr Bancario";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.EntryNo) then begin
                    New.Init();
                    New.EntryNo := Legacy.EntryNo;
                    New."Account No" := Legacy."Account No";
                    New."Fecha Posteo" := Legacy."Fecha Posteo";
                    New."No. Cheque" := Legacy."No. Cheque";
                    New.Monto := Legacy.Monto;
                    New.Origen := Legacy.Origen;
                    New.Descripcion := Legacy.Descripcion;
                    New."Codigo Transaccion" := Legacy."Codigo Transaccion";
                    New."No. ReFerencia" := Legacy."No. ReFerencia";
                    New."Cta Banco" := Legacy."Cta Banco";
                    New.Bank := Legacy.Bank;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq49: Entrega Facturas CxC - Lines (50057) -> DXR_Entrega Fact CxC - Lines (53334).
    // PK = ("Document No.", "Invoices No.").
    local procedure MigrateEntregaFacturasCxCLinesTable()
    var
        Legacy: Record "Entrega Facturas CxC - Lines";
        New: Record "DXR_Entrega Fact CxC - Lines";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Document No.", Legacy."Invoices No.") then begin
                    New.Init();
                    New."Document No." := Legacy."Document No.";
                    New."Invoices No." := Legacy."Invoices No.";
                    New."Entregada Despacho" := Legacy."Entregada Despacho";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq50: Envio Compras (50058) -> DXR_Envio Compras (53335). PK = "Code".
    local procedure MigrateEnvioComprasTable()
    var
        Legacy: Record "Envio Compras";
        New: Record "DXR_Envio Compras";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New."Ship-to Address" := Legacy."Ship-to Address";
                    New."Ship-to Address 2" := Legacy."Ship-to Address 2";
                    New."Ship-to City" := Legacy."Ship-to City";
                    New."Ship-to Post Code" := Legacy."Ship-to Post Code";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq57: Grupo Venta (50072) -> DXR_Grupo Venta (53342). PK = "Code".
    local procedure MigrateGrupoVentaTable()
    var
        Legacy: Record "Grupo Venta";
        New: Record "DXR_Grupo Venta";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq70: Internal Consumption Header (50093) -> DXR_Int Consump Header (53355). PK = "No.".
    local procedure MigrateInternalConsumptionHeaderTable()
    var
        Legacy: Record "Internal Consumption Header";
        New: Record "DXR_Int Consump Header";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."No.") then begin
                    New.Init();
                    New."No." := Legacy."No.";
                    New."Posting Date" := Legacy."Posting Date";
                    New."Request By" := Legacy."Request By";
                    New.Manager := Legacy.Manager;
                    New."Global Dimension 2 Code" := Legacy."Global Dimension 2 Code";
                    New.Clasification := Legacy.Clasification;
                    New.Comment := Legacy.Comment;
                    New.Status := Legacy.Status;
                    New."User Created" := Legacy."User Created";
                    New."Date Created" := Legacy."Date Created";
                    New."Location Code" := Legacy."Location Code";
                    New."Usuario Aprobador" := Legacy."Usuario Aprobador";
                    New."Shortcut Dimension 1 Code" := Legacy."Shortcut Dimension 1 Code";
                    New."Responsibility Center" := Legacy."Responsibility Center";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq71: Internal Consumption Line (50094) -> DXR_Internal Consumption Line (53356).
    // PK = ("Document No.", "Item No."). Fields Description (3), Reference (4), UOM (5), Cost (7),
    // "Unit Price" (8) are FlowFields (CalcFormula) on both sides - not copied.
    local procedure MigrateInternalConsumptionLineTable()
    var
        Legacy: Record "Internal Consumption Line";
        New: Record "DXR_Internal Consumption Line";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Document No.", Legacy."Item No.") then begin
                    New.Init();
                    New."Document No." := Legacy."Document No.";
                    New."Item No." := Legacy."Item No.";
                    New.Quantity := Legacy.Quantity;
                    New."Location Code" := Legacy."Location Code";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq74: Item HTML (50098) -> DXR_Item HTML (53359). PK = "Item No.". Fields Html (20),
    // "Descripcion Extendida" (50000), Caracteristicas (50001) are BLOB - copied via CalcFields()
    // + CreateInStream()/CreateOutStream()/CopyStream() directly on the typed BLOB fields (never
    // by direct field assignment, never via RecordRef/FieldRef - Codeunit "Temp Blob" was tried
    // first but its only write-back method, ToRecordRef(), requires a RecordRef parameter, which
    // would violate the zero-RecordRef/FieldRef constraint; it has no ToRecord(Variant) overload).
    local procedure MigrateItemHTMLTable()
    var
        Legacy: Record "Item HTML";
        New: Record "DXR_Item HTML";
        InStr: InStream;
        OutStr: OutStream;
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item No.") then begin
                    New.Init();
                    New."Item No." := Legacy."Item No.";
                    New.URL := Legacy.URL;

                    Legacy.CalcFields(Html);
                    Legacy.Html.CreateInStream(InStr);
                    New.Html.CreateOutStream(OutStr);
                    CopyStream(OutStr, InStr);

                    Legacy.CalcFields("Descripcion Extendida");
                    Legacy."Descripcion Extendida".CreateInStream(InStr);
                    New."Descripcion Extendida".CreateOutStream(OutStr);
                    CopyStream(OutStr, InStr);

                    Legacy.CalcFields(Caracteristicas);
                    Legacy.Caracteristicas.CreateInStream(InStr);
                    New.Caracteristicas.CreateOutStream(OutStr);
                    CopyStream(OutStr, InStr);

                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq75: Item Image View (50099) -> DXR_Item Image View (53360). PK = "Entry No." (Integer,
    // not AutoIncrement). LinkedObject = true on both sides (pre-existing in the real source).
    local procedure MigrateItemImageViewTable()
    var
        Legacy: Record "Item Image View";
        New: Record "DXR_Item Image View";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Entry No.") then begin
                    New.Init();
                    New."Entry No." := Legacy."Entry No.";
                    New."Item No." := Legacy."Item No.";
                    New."Image Location" := Legacy."Image Location";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq76: ItemNo Desliquidacion (50100) -> DXR_ItemNo Desliquidacion (53361).
    // PK = ("Item No.", "Fecha Desde", "Fecha Hasta", Almacen).
    local procedure MigrateItemNoDesliquidacionTable()
    var
        Legacy: Record "ItemNo Desliquidacion";
        New: Record "DXR_ItemNo Desliquidacion";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item No.", Legacy."Fecha Desde", Legacy."Fecha Hasta", Legacy.Almacen) then begin
                    New.Init();
                    New."Item No." := Legacy."Item No.";
                    New.Procesado := Legacy.Procesado;
                    New."Fecha Desde" := Legacy."Fecha Desde";
                    New."Fecha Hasta" := Legacy."Fecha Hasta";
                    New.Almacen := Legacy.Almacen;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq77: Journal Promotion Tickets (50102) -> DXR_Journal Promotion Tickets (53362).
    // PK = (Promotions, "Member Account"). Field "Member Name" (3) is a FlowField (CalcFormula) on
    // both sides - not copied.
    local procedure MigrateJournalPromotionTicketsTable()
    var
        Legacy: Record "Journal Promotion Tickets";
        New: Record "DXR_Journal Promotion Tickets";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Promotions, Legacy."Member Account") then begin
                    New.Init();
                    New.Promotions := Legacy.Promotions;
                    New."Member Account" := Legacy."Member Account";
                    New."Member Points" := Legacy."Member Points";
                    New.PointsChange := Legacy.PointsChange;
                    New."Qty Tickets" := Legacy."Qty Tickets";
                    New.UserCreated := Legacy.UserCreated;
                    New.DateCreated := Legacy.DateCreated;
                    New.TimeCreated := Legacy.TimeCreated;
                    New."Member Card No." := Legacy."Member Card No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq79: Lineas Carga Masiva Ben. BPD (50107) -> DXR_Lin Carga Masiva Ben. BPD (53364).
    // PK = "Numero de Cuenta". Field Banco (12) is a FlowField (CalcFormula) on both sides - not
    // copied.
    local procedure MigrateLineasCargaMasivaBenBPDTable()
    var
        Legacy: Record "Lineas Carga Masiva Ben. BPD";
        New: Record "DXR_Lin Carga Masiva Ben. BPD";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Numero de Cuenta") then begin
                    New.Init();
                    New."Tipo de Registro" := Legacy."Tipo de Registro";
                    New."Tipo de ID" := Legacy."Tipo de ID";
                    New."Numero de ID" := Legacy."Numero de ID";
                    New."RNC del pagador" := Legacy."RNC del pagador";
                    New."Codigo de banco beneficiario" := Legacy."Codigo de banco beneficiario";
                    New."Via Pago" := Legacy."Via Pago";
                    New."Moneda de la cuenta" := Legacy."Moneda de la cuenta";
                    New."Tipo de Cuenta Bancaria" := Legacy."Tipo de Cuenta Bancaria";
                    New."Numero de Cuenta" := Legacy."Numero de Cuenta";
                    New."Referencia de Banco/cuenta" := Legacy."Referencia de Banco/cuenta";
                    New."Nombre de solicitante" := Legacy."Nombre de solicitante";
                    New."Vendor No." := Legacy."Vendor No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq90: Movimientos de Cilindro (50123) -> DXR_Movimientos de Cilindro (53375).
    // PK = "Document No.". Fields "Nombre cliente" (3), "Descripcion Gas" (8), "Serial Cilindro"
    // (10), "Id Gas" (11) are FlowFields (CalcFormula) on both sides - not copied. Insert(false)
    // intentionally skips the table's own OnInsert trigger, same as MigrateCilindrosTable() above.
    local procedure MigrateMovimientosDeCilindroTable()
    var
        Legacy: Record "Movimientos de Cilindro";
        New: Record "DXR_Movimientos de Cilindro";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Document No.") then begin
                    New.Init();
                    New."Document No." := Legacy."Document No.";
                    New."Cod. Cliente" := Legacy."Cod. Cliente";
                    New."Nro. Conduce" := Legacy."Nro. Conduce";
                    New."Fecha Despacho" := Legacy."Fecha Despacho";
                    New."Fecha Recepcion" := Legacy."Fecha Recepcion";
                    New."Id Cilindro" := Legacy."Id Cilindro";
                    New.Estatus := Legacy.Estatus;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq91: Order Item Status (50127) -> DXR_Order Item Status (53376). PK = ID.
    local procedure MigrateOrderItemStatusTable()
    var
        Legacy: Record "Order Item Status";
        New: Record "DXR_Order Item Status";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.ID) then begin
                    New.Init();
                    New.ID := Legacy.ID;
                    New.STATUS := Legacy.STATUS;
                    New.PROCESS := Legacy.PROCESS;
                    New.REJECTED := Legacy.REJECTED;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq93: Pre Req LineNoStockValid (50135) -> DXR_Pre Req LineNoStockValid (53378).
    // PK = ("Doc Num", "Line Num"); "Line Num" is AutoIncrement - legacy value copied directly,
    // same established precedent as MigrateDrawSetupTable() above.
    local procedure MigratePreReqLineNoStockValidTable()
    var
        Legacy: Record "Pre Req LineNoStockValid";
        New: Record "DXR_Pre Req LineNoStockValid";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Doc Num", Legacy."Line Num") then begin
                    New.Init();
                    New."Doc Num" := Legacy."Doc Num";
                    New."Line Num" := Legacy."Line Num";
                    New.Description := Legacy.Description;
                    New."Unit of Measure" := Legacy."Unit of Measure";
                    New.Quantity := Legacy.Quantity;
                    New."Precio Sugerido" := Legacy."Precio Sugerido";
                    New."Location Code" := Legacy."Location Code";
                    New.Insertar := Legacy.Insertar;
                    New."No." := Legacy."No.";
                    New.Insertado := Legacy.Insertado;
                    New."Buyer Group" := Legacy."Buyer Group";
                    New."Unit Cost" := Legacy."Unit Cost";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq94: Pre Req no Stock Valid (50136) -> DXR_Pre Req no Stock Valid (53379). PK = No.
    local procedure MigratePreReqNoStockValidTable()
    var
        Legacy: Record "Pre Req no Stock Valid";
        New: Record "DXR_Pre Req no Stock Valid";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.No) then begin
                    New.Init();
                    New.No := Legacy.No;
                    New.Descripcion := Legacy.Descripcion;
                    New."User Id" := Legacy."User Id";
                    New.Estado := Legacy.Estado;
                    New.Fecha := Legacy.Fecha;
                    New.Hora := Legacy.Hora;
                    New.Location := Legacy.Location;
                    New.Cliente := Legacy.Cliente;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq95: Pre-Requisicion (50137) -> DXR_Pre-Requisicion (53380). PK = No.
    local procedure MigratePreRequisicionTable()
    var
        Legacy: Record "Pre-Requisicion";
        New: Record "DXR_Pre-Requisicion";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.No) then begin
                    New.Init();
                    New.No := Legacy.No;
                    New.Descripcion := Legacy.Descripcion;
                    New."User Id" := Legacy."User Id";
                    New.Estado := Legacy.Estado;
                    New.Fecha := Legacy.Fecha;
                    New.Hora := Legacy.Hora;
                    New.Location := Legacy.Location;
                    New.Cliente := Legacy.Cliente;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq96: Pre-Requisicion Line (50138) -> DXR_Pre-Requisicion Line (53381).
    // PK = ("Doc Num", "Line Num", "No.").
    local procedure MigratePreRequisicionLineTable()
    var
        Legacy: Record "Pre-Requisicion Line";
        New: Record "DXR_Pre-Requisicion Line";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Doc Num", Legacy."Line Num", Legacy."No.") then begin
                    New.Init();
                    New."Doc Num" := Legacy."Doc Num";
                    New."Line Num" := Legacy."Line Num";
                    New."No." := Legacy."No.";
                    New."Location Code" := Legacy."Location Code";
                    New.Description := Legacy.Description;
                    New."Unit of Measure" := Legacy."Unit of Measure";
                    New.Quantity := Legacy.Quantity;
                    New."Buyer Group" := Legacy."Buyer Group";
                    New."Precio Sugerido" := Legacy."Precio Sugerido";
                    New."Unit Cost" := Legacy."Unit Cost";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq97: Pre-Requisicion Line No Stock (50139) -> DXR_Pre-Req Line No Stock (53382).
    // PK = ("Doc Num", "Line Num").
    local procedure MigratePreRequisicionLineNoStockTable()
    var
        Legacy: Record "Pre-Requisicion Line No Stock";
        New: Record "DXR_Pre-Req Line No Stock";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Doc Num", Legacy."Line Num") then begin
                    New.Init();
                    New."Doc Num" := Legacy."Doc Num";
                    New."Line Num" := Legacy."Line Num";
                    New.Description := Legacy.Description;
                    New."Unit of Measure" := Legacy."Unit of Measure";
                    New.Quantity := Legacy.Quantity;
                    New."Precio Sugerido" := Legacy."Precio Sugerido";
                    New."Location Code" := Legacy."Location Code";
                    New."Unit Cost" := Legacy."Unit Cost";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq98: Pre-Requisicion no Stock (50140) -> DXR_Pre-Requisicion no Stock (53383). PK = No.
    local procedure MigratePreRequisicionNoStockTable()
    var
        Legacy: Record "Pre-Requisicion no Stock";
        New: Record "DXR_Pre-Requisicion no Stock";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.No) then begin
                    New.Init();
                    New.No := Legacy.No;
                    New.Descripcion := Legacy.Descripcion;
                    New."User Id" := Legacy."User Id";
                    New.Estado := Legacy.Estado;
                    New.Fecha := Legacy.Fecha;
                    New.Hora := Legacy.Hora;
                    New.Location := Legacy.Location;
                    New.Cliente := Legacy.Cliente;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq102: Promotion Tickets Relation (50144) -> DXR_Promotion Tickets Relation (53387).
    // PK = (Promotion, "Filter Type", "Filter Code", "Scheme Filter Type", "Club/Scheme"). Field
    // "Promotion Description" (7) is a FlowField (CalcFormula) on both sides - not copied.
    local procedure MigratePromotionTicketsRelationTable()
    var
        Legacy: Record "Promotion Tickets Relation";
        New: Record "DXR_Promotion Tickets Relation";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Promotion, Legacy."Filter Type", Legacy."Filter Code", Legacy."Scheme Filter Type", Legacy."Club/Scheme") then begin
                    New.Init();
                    New.Promotion := Legacy.Promotion;
                    New."Filter Type" := Legacy."Filter Type";
                    New."Filter Code" := Legacy."Filter Code";
                    New."Base Calculation on" := Legacy."Base Calculation on";
                    New."Unit Rate" := Legacy."Unit Rate";
                    New.Tickets := Legacy.Tickets;
                    New."Scheme Filter Type" := Legacy."Scheme Filter Type";
                    New."Club/Scheme" := Legacy."Club/Scheme";
                    New."Club Code" := Legacy."Club Code";
                    New.Category := Legacy.Category;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq104: Requisicion (50151) -> DXR_Requisicion (53389). PK = "No. Req".
    local procedure MigrateRequisicionTable()
    var
        Legacy: Record Requisicion;
        New: Record "DXR_Requisicion";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."No. Req") then begin
                    New.Init();
                    New."No. Req" := Legacy."No. Req";
                    New."No. Pre-Req" := Legacy."No. Pre-Req";
                    New.Descripcion := Legacy.Descripcion;
                    New."User Id" := Legacy."User Id";
                    New."Buy-from Vendor No." := Legacy."Buy-from Vendor No.";
                    New."Document Date" := Legacy."Document Date";
                    New."Buyer Group" := Legacy."Buyer Group";
                    New.Estado := Legacy.Estado;
                    New.Location := Legacy.Location;
                    New.hora := Legacy.hora;
                    New."Id Aprobacion" := Legacy."Id Aprobacion";
                    New."Fecha Aprobacion" := Legacy."Fecha Aprobacion";
                    New."Hora Aprobacion" := Legacy."Hora Aprobacion";
                    New.Cliente := Legacy.Cliente;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq105: Requisicion Comment Line (50152) -> DXR_Requisicion Comment Line (53390).
    // PK = (Date, "Document Line No.", "Pre-Req", "User Id").
    local procedure MigrateRequisicionCommentLineTable()
    var
        Legacy: Record "Requisicion Comment Line";
        New: Record "DXR_Requisicion Comment Line";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Date, Legacy."Document Line No.", Legacy."Pre-Req", Legacy."User Id") then begin
                    New.Init();
                    New.Date := Legacy.Date;
                    New.Comment := Legacy.Comment;
                    New."Document Line No." := Legacy."Document Line No.";
                    New."Pre-Req" := Legacy."Pre-Req";
                    New."User Id" := Legacy."User Id";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq106: Requisicion Line (50153) -> DXR_Requisicion Line (53391).
    // PK = ("No. Req", "Line No.", "No.").
    local procedure MigrateRequisicionLineTable()
    var
        Legacy: Record "Requisicion Line";
        New: Record "DXR_Requisicion Line";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."No. Req", Legacy."Line No.", Legacy."No.") then begin
                    New.Init();
                    New."No. Req" := Legacy."No. Req";
                    New."Line No." := Legacy."Line No.";
                    New."No." := Legacy."No.";
                    New."Location Code" := Legacy."Location Code";
                    New.Description := Legacy.Description;
                    New.Quantity := Legacy.Quantity;
                    New."Unit of Measure" := Legacy."Unit of Measure";
                    New."Precio Sugerido" := Legacy."Precio Sugerido";
                    New."Unit Cost" := Legacy."Unit Cost";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq114: Store Statement Posting (50173) -> DXR_Store Statement Posting (53399).
    // PK = "Store No.".
    local procedure MigrateStoreStatementPostingTable()
    var
        Legacy: Record "Store Statement Posting";
        New: Record "DXR_Store Statement Posting";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Store No.") then begin
                    New.Init();
                    New."Store No." := Legacy."Store No.";
                    New.Exclude := Legacy.Exclude;
                    New.Priority := Legacy.Priority;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq117: Tickets By Offer (50177) -> DXR_Tickets By Offer (53402). PK = ("OfferNo.",
    // "Receipt No.").
    local procedure MigrateTicketsByOfferTable()
    var
        Legacy: Record "Tickets By Offer";
        New: Record "DXR_Tickets By Offer";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."OfferNo.", Legacy."Receipt No.") then begin
                    New.Init();
                    New."OfferNo." := Legacy."OfferNo.";
                    New."Receipt No." := Legacy."Receipt No.";
                    New.Qty := Legacy.Qty;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq118: Tickets Entry (50178) -> DXR_Tickets Entry (53403). PK = "Tickets No." (clustered
    // Key1). "Entry No." (16) is AutoIncrement but is NOT the primary key here (it forms its own
    // Key5) - the legacy value is still copied directly to preserve it, consistent with copying
    // every other normal field on this table.
    local procedure MigrateTicketsEntryTable()
    var
        Legacy: Record "Tickets Entry";
        New: Record "DXR_Tickets Entry";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Tickets No.") then begin
                    New.Init();
                    New.Promotions := Legacy.Promotions;
                    New."Store No." := Legacy."Store No.";
                    New."POS Terminal No." := Legacy."POS Terminal No.";
                    New."Receipt No." := Legacy."Receipt No.";
                    New."Tickets No." := Legacy."Tickets No.";
                    New."Customer No." := Legacy."Customer No.";
                    New."MemberAcc No." := Legacy."MemberAcc No.";
                    New."Identification No." := Legacy."Identification No.";
                    New.Priority := Legacy.Priority;
                    New."Replication Counter" := Legacy."Replication Counter";
                    New."Date Created" := Legacy."Date Created";
                    New."Time Created" := Legacy."Time Created";
                    New.BO := Legacy.BO;
                    New."Customer Name" := Legacy."Customer Name";
                    New."No. Tlf" := Legacy."No. Tlf";
                    New."Entry No." := Legacy."Entry No.";
                    New.Void := Legacy.Void;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq127: UserPromo Apps (50200) -> DXR_UserPromo Apps (53412). PK = UserApp.
    local procedure MigrateUserPromoAppsTable()
    var
        Legacy: Record "UserPromo Apps";
        New: Record "DXR_UserPromo Apps";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.UserApp) then begin
                    New.Init();
                    New.UserApp := Legacy.UserApp;
                    New.PasswordApp := Legacy.PasswordApp;
                    New.Consulta := Legacy.Consulta;
                    New.User_Role := Legacy.User_Role;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq128: Valoracion de Inventario (50201) -> DXR_Valoracion de Inventario (53413).
    // PK = "Location Code".
    local procedure MigrateValoracionDeInventarioTable()
    var
        Legacy: Record "Valoracion de Inventario";
        New: Record "DXR_Valoracion de Inventario";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Location Code") then begin
                    New.Init();
                    New."Location Code" := Legacy."Location Code";
                    New."Inv. Inicial" := Legacy."Inv. Inicial";
                    New.Compra := Legacy.Compra;
                    New.Venta := Legacy.Venta;
                    New."Ajuste Positivo" := Legacy."Ajuste Positivo";
                    New."Ajuste Negativo" := Legacy."Ajuste Negativo";
                    New.Transferencia := Legacy.Transferencia;
                    New.Consumo := Legacy.Consumo;
                    New."Salida desde Fabrica" := Legacy."Salida desde Fabrica";
                    New."NO USAR" := Legacy."NO USAR";
                    New."Consumo Ensamblado" := Legacy."Consumo Ensamblado";
                    New."Salida Ensamblado" := Legacy."Salida Ensamblado";
                    New."Inv. Final" := Legacy."Inv. Final";
                    New."Filtro Fecha Usado" := Legacy."Filtro Fecha Usado";
                    New."Fecha de Actualizacion" := Legacy."Fecha de Actualizacion";
                    New."Nombre de Localidad" := Legacy."Nombre de Localidad";
                    New."Inv. Final - Inv. Inicial" := Legacy."Inv. Final - Inv. Inicial";
                    New."Ajuste de Compra" := Legacy."Ajuste de Compra";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq131: AGR Extended Item (50002) -> DXR_AGR Extended Item (55006). PK = ("Item No.",
    // "Connected Item"). Called from MigrateAllNormalizedTables_Batch2().
    local procedure MigrateAGRExtendedItemTable()
    var
        Legacy: Record "AGR Extended Item";
        New: Record "DXR_AGR Extended Item";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item No.", Legacy."Connected Item") then begin
                    New.Init();
                    New."Item No." := Legacy."Item No.";
                    New."Connected From" := Legacy."Connected From";
                    New."Connected To" := Legacy."Connected To";
                    New.Scale := Legacy.Scale;
                    New."Connection Duration" := Legacy."Connection Duration";
                    New."Connect Sale History" := Legacy."Connect Sale History";
                    New."Connect Stock History" := Legacy."Connect Stock History";
                    New."Sale Overlap" := Legacy."Sale Overlap";
                    New."Connected Item" := Legacy."Connected Item";
                    New."Order Frequency" := Legacy."Order Frequency";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq132: Comision_Grupo_Vendedor (50027) -> DXR_Comision_Grupo_Vendedor (55005).
    // PK = (Comision_Grupo_ID, Vendedor_ID). Called from MigrateAllNormalizedTables_Batch2().
    local procedure MigrateComisionGrupoVendedorTable()
    var
        Legacy: Record Comision_Grupo_Vendedor;
        New: Record "DXR_Comision_Grupo_Vendedor";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Comision_Grupo_ID, Legacy.Vendedor_ID) then begin
                    New.Init();
                    New.Comision_Grupo_ID := Legacy.Comision_Grupo_ID;
                    New.Vendedor_ID := Legacy.Vendedor_ID;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq133: Inventory View (50097) -> DXR_Inventory View. (55004; the trailing period is part
    // of the real object name). PK = "Item No.". LinkedObject = true on both sides (pre-existing
    // in the real source). Called from MigrateAllNormalizedTables_Batch2().
    local procedure MigrateInventoryViewTable()
    var
        Legacy: Record "Inventory View";
        New: Record "DXR_Inventory View.";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item No.") then begin
                    New.Init();
                    New."Item No." := Legacy."Item No.";
                    New."Location Code" := Legacy."Location Code";
                    New.Quantity := Legacy.Quantity;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
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
        ApprovalEntry: Record "Approval Entry";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 52001, 52002))
        // copied "ID" into "ID_Old" (field 52002), a dead shadow field - ApprovalEntry.TableExt.al's
        // real active target, confirmed via ObsoleteReason on field 52001 (52787 is not itself
        // obsolete), is "ID_DXR." (field 52787, trailing period as declared in source). Direct
        // typed field closes that gap.
        if ApprovalEntry.FindSet(true) then
            repeat
                if ApprovalEntry."ID_DXR." <> ApprovalEntry."ID" then begin
                    ApprovalEntry."ID_DXR." := ApprovalEntry."ID";
                    ApprovalEntry.Modify(false);
                end;
            until ApprovalEntry.Next() = 0;
    end;

    // No-op by design (2026-08-24): AssemblyHeader.TableExt.al defines only field 50000 "Importe
    // Total Costo" (Pending, obsolete) and its replacement 52787 "Importe Total Costo_DXR" - both
    // are FlowFields (identical CalcFormula = Sum("Assembly Line"."Cost Amount" ...)), so there is
    // no stored value to migrate. The old RecordRef version's destination (50001) never existed in
    // the schema either (CopyFieldIfExists was already a guaranteed no-op on every row). Nothing to
    // open, nothing to copy.
    local procedure MigrateTableExt_AssemblyHeaderFields()
    begin
    end;

    local procedure MigrateTableExt_AssemblySetupFields()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 52000, 52001))
        // copied "Tolerance%" into "Tolerance%_Old" (field 52001), a dead shadow field - the real
        // active target "Tolerance%_DXR" (field 52787, confirmed via AssemblySetup.TableExt.al's
        // ObsoleteReason on field 52000) was NEVER populated by this codeunit despite it running
        // and reporting success. Direct typed fields close that gap.
        if AssemblySetup.Get() then
            if AssemblySetup."Tolerance%_DXR" <> AssemblySetup."Tolerance%" then begin
                AssemblySetup."Tolerance%_DXR" := AssemblySetup."Tolerance%";
                AssemblySetup.Modify();
            end;
    end;

    // No-op by design (2026-08-24): BEVendorLedgerEntryExt.TableExt.al defines only field 50000
    // "Buy-from Vendor Name" (Pending, obsolete) and its replacement 52787 "Buy-from Vendor
    // Name_DXR" - both are FlowFields (identical CalcFormula = lookup(Vendor.Name ...)), so there is
    // no stored value to migrate. The old RecordRef version's destination (50001) never existed in
    // the schema either (CopyFieldIfExists was already a guaranteed no-op on every row). Nothing to
    // open, nothing to copy.
    local procedure MigrateTableExt_VendorLedgerEntryFields()
    begin
    end;

    local procedure MigrateTableExt_BankAccReconciliationFields()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "BE Extracto Bancario" into "Extracto Bancario_Old" (field 50001), a dead shadow
        // field - BankAccReconciliation.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Extracto Bancario_DXR"
        // (52787). Direct typed field closes that gap.
        if BankAccReconciliation.FindSet(true) then
            repeat
                if BankAccReconciliation."Extracto Bancario_DXR" <> BankAccReconciliation."BE Extracto Bancario" then begin
                    BankAccReconciliation."Extracto Bancario_DXR" := BankAccReconciliation."BE Extracto Bancario";
                    BankAccReconciliation.Modify(false);
                end;
            until BankAccReconciliation.Next() = 0;
    end;

    local procedure MigrateTableExt_BankAccReconciliationLineFields()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 52000, 52001))
        // copied "BE Extracto Bancario" into "Extracto Bancario_Old" (field 52001), a dead shadow
        // field - BankAccReconciliationLine.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 52000 (52787 is not itself obsolete), is "Extracto Bancario_DXR"
        // (52787). Direct typed field closes that gap.
        if BankAccReconciliationLine.FindSet(true) then
            repeat
                if BankAccReconciliationLine."Extracto Bancario_DXR" <> BankAccReconciliationLine."BE Extracto Bancario" then begin
                    BankAccReconciliationLine."Extracto Bancario_DXR" := BankAccReconciliationLine."BE Extracto Bancario";
                    BankAccReconciliationLine.Modify(false);
                end;
            until BankAccReconciliationLine.Next() = 0;
    end;

    local procedure MigrateTableExt_BankAccountFields()
    var
        BankAccount: Record "Bank Account";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied all three fields into dead "_Old"
        // shadow fields (50003-50005) - BankAccount.TableExt.al's real active targets, confirmed
        // via ObsoleteReason on fields 50000-50002 (none of the destinations below are themselves
        // obsolete), are "Cod. Proveedor Bco._BE_DXR" (52787 - name kept as originally declared,
        // it is not itself obsolete), "Account No._DXR" (52788) and "Amount In Payload_DXR"
        // (52789). Direct typed fields close that gap.
        if BankAccount.FindSet(true) then
            repeat
                if (BankAccount."Cod. Proveedor Bco._BE_DXR" <> BankAccount."Cod. Proveedor Bco.") or
                   (BankAccount."Account No._DXR" <> BankAccount."Account No.") or
                   (BankAccount."Amount In Payload_DXR" <> BankAccount."Amount In Payload")
                then begin
                    BankAccount."Cod. Proveedor Bco._BE_DXR" := BankAccount."Cod. Proveedor Bco.";
                    BankAccount."Account No._DXR" := BankAccount."Account No.";
                    BankAccount."Amount In Payload_DXR" := BankAccount."Amount In Payload";
                    BankAccount.Modify(false);
                end;
            until BankAccount.Next() = 0;
    end;

    local procedure MigrateTableExt_BankAccountLedgerEntryFields()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "Fecha Registro 2" into "Fecha Registro 2_Old" (field 50001), a dead shadow field -
        // BankAccountLedgerEntry.TableExt.al's real active target, confirmed via ObsoleteReason on
        // field 50000 (52787 is not itself obsolete), is "Fecha Registro 2_DXR" (52787). Direct
        // typed field closes that gap.
        if BankAccountLedgerEntry.FindSet(true) then
            repeat
                if BankAccountLedgerEntry."Fecha Registro 2_DXR" <> BankAccountLedgerEntry."Fecha Registro 2" then begin
                    BankAccountLedgerEntry."Fecha Registro 2_DXR" := BankAccountLedgerEntry."Fecha Registro 2";
                    BankAccountLedgerEntry.Modify(false);
                end;
            until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCBarcodesFields()
    var
        LSCBarcodes: Record "LSC Barcodes";
    begin
        // Fixed 2026-08-24: the old RecordRef version targeted fields 50002/50003, which are not
        // defined anywhere in Barcodes.TableExt.al - CopyFieldIfExists silently no-op'd every row.
        // The real active targets, confirmed via that file's ObsoleteReason on fields 50000/50001
        // (neither the destination is itself obsolete), are "Description 2_DXR" (52787) and
        // "Cantidad Bellon_DXR" (52788). Direct typed fields close that gap.
        if LSCBarcodes.FindSet(true) then
            repeat
                if (LSCBarcodes."Description 2_DXR" <> LSCBarcodes."Description 2") or
                   (LSCBarcodes."Cantidad Bellon_DXR" <> LSCBarcodes."Cantidad Bellon")
                then begin
                    LSCBarcodes."Description 2_DXR" := LSCBarcodes."Description 2";
                    LSCBarcodes."Cantidad Bellon_DXR" := LSCBarcodes."Cantidad Bellon";
                    LSCBarcodes.Modify(false);
                end;
            until LSCBarcodes.Next() = 0;
    end;

    local procedure MigrateTableExt_CheckLedgerEntryFields()
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied all four fields into dead "_Old"
        // shadow fields (50009-50012) - CheckLedgerEntry.TableExt.al defines those alongside the
        // real active "_DXR" targets (52787-52790, confirmed via ObsoleteReason on fields
        // 50005-50008; none of the _DXR destinations are themselves obsolete), which were never
        // populated. Direct typed fields close that gap.
        if CheckLedgerEntry.FindSet(true) then
            repeat
                if (CheckLedgerEntry."Recibido Por_DXR" <> CheckLedgerEntry."Recibido Por") or
                   (CheckLedgerEntry."Recibido Por Cedula_DXR" <> CheckLedgerEntry."Recibido Por Cedula") or
                   (CheckLedgerEntry."Hora Entrega_DXR" <> CheckLedgerEntry."Hora Entrega") or
                   (CheckLedgerEntry."No. Recibo_DXR" <> CheckLedgerEntry."No. Recibo")
                then begin
                    CheckLedgerEntry."Recibido Por_DXR" := CheckLedgerEntry."Recibido Por";
                    CheckLedgerEntry."Recibido Por Cedula_DXR" := CheckLedgerEntry."Recibido Por Cedula";
                    CheckLedgerEntry."Hora Entrega_DXR" := CheckLedgerEntry."Hora Entrega";
                    CheckLedgerEntry."No. Recibo_DXR" := CheckLedgerEntry."No. Recibo";
                    CheckLedgerEntry.Modify(false);
                end;
            until CheckLedgerEntry.Next() = 0;
    end;

    local procedure MigrateTableExt_CompanyInformationFields()
    var
        CompanyInformation: Record "Company Information";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied both fields into dead "_Old" shadow
        // fields (50002/50003) - CompanyInformation.TableExt.al's real active targets, confirmed
        // via ObsoleteReason on fields 50000/50001 (neither destination is itself obsolete), are
        // "Encargado Retenciones_DXR" (52787) and "Posicion Encargado Ret._DXR" (52788). Company
        // Information is a single-row table (blank primary key). Direct typed fields close that gap.
        if CompanyInformation.Get() then
            if (CompanyInformation."Encargado Retenciones_DXR" <> CompanyInformation."Encargado Retenciones") or
               (CompanyInformation."Posicion Encargado Ret._DXR" <> CompanyInformation."Posicion Encargado Ret.")
            then begin
                CompanyInformation."Encargado Retenciones_DXR" := CompanyInformation."Encargado Retenciones";
                CompanyInformation."Posicion Encargado Ret._DXR" := CompanyInformation."Posicion Encargado Ret.";
                CompanyInformation.Modify(false);
            end;
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
        CountryRegion: Record "Country/Region";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied all three fields into dead "_Old"
        // shadow fields (50003-50005) - CountryRegion.TableExt.al's real active targets, confirmed
        // via ObsoleteReason on fields 50000-50002 (none of the _DXR destinations are themselves
        // obsolete), are "Obsolete 11123302_DXR" (52787), "Obsolete 11123303_DXR" (52788) and
        // "2-Digit ISO Code_DXR" (52789). Direct typed fields close that gap.
        if CountryRegion.FindSet(true) then
            repeat
                if (CountryRegion."Obsolete 11123302_DXR" <> CountryRegion."Obsolete 11123302") or
                   (CountryRegion."Obsolete 11123303_DXR" <> CountryRegion."Obsolete 11123303") or
                   (CountryRegion."2-Digit ISO Code_DXR" <> CountryRegion."2-Digit ISO Code")
                then begin
                    CountryRegion."Obsolete 11123302_DXR" := CountryRegion."Obsolete 11123302";
                    CountryRegion."Obsolete 11123303_DXR" := CountryRegion."Obsolete 11123303";
                    CountryRegion."2-Digit ISO Code_DXR" := CountryRegion."2-Digit ISO Code";
                    CountryRegion.Modify(false);
                end;
            until CountryRegion.Next() = 0;
    end;

    local procedure MigrateTableExt_CurrencyFields()
    var
        Currency: Record "Currency";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "Accepted bpd" into "Accepted bpd_Old" (field 50001), a dead shadow field -
        // Currency.TableExt.al's real active target, confirmed via ObsoleteReason on field 50000
        // (52787 is not itself obsolete), is "Accepted bpd_DXR" (52787). Direct typed field closes
        // that gap.
        if Currency.FindSet(true) then
            repeat
                if Currency."Accepted bpd_DXR" <> Currency."Accepted bpd" then begin
                    Currency."Accepted bpd_DXR" := Currency."Accepted bpd";
                    Currency.Modify(false);
                end;
            until Currency.Next() = 0;
    end;

    local procedure MigrateTableExt_CurrencyExchangeRateFields()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "Tasa Banco Central" into "Tasa Banco Central_Old" (field 50001), a dead shadow
        // field - CurrencyExchangeRate.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Tasa Banco Central_DXR"
        // (52787), which is also live-read by this same tableextension's own
        // ExchangeRateBancoCentral() procedure. Direct typed field closes that gap.
        if CurrencyExchangeRate.FindSet(true) then
            repeat
                if CurrencyExchangeRate."Tasa Banco Central_DXR" <> CurrencyExchangeRate."Tasa Banco Central" then begin
                    CurrencyExchangeRate."Tasa Banco Central_DXR" := CurrencyExchangeRate."Tasa Banco Central";
                    CurrencyExchangeRate.Modify(false);
                end;
            until CurrencyExchangeRate.Next() = 0;
    end;

    local procedure MigrateTableExt_CustLedgerEntryFields()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Fixed 2026-08-24: the old RecordRef version had two pairs. (1) CopyFieldIfExists(RecRef,
        // 50000, 50003): field 50003 never existed in CustLedgerEntry.TableExt.al's schema (already
        // a guaranteed no-op) - and source field 50000 "Recordatorios" is a FlowField (Count(...)),
        // replaced by FlowField 52787 "Recordatorios_DXR", so there is no stored value to migrate
        // either way; that pair is correctly dropped. (2) CopyFieldIfExists(RecRef, 50002, 50004)
        // copied "No. Authorizacion" into "No. Authorizacion_Old" (field 50004), a dead shadow field
        // - the real active target, confirmed via ObsoleteReason on field 50002 (52788 is not
        // itself obsolete), is "No. Authorizacion_DXR" (52788). Direct typed field closes that gap.
        if CustLedgerEntry.FindSet(true) then
            repeat
                if CustLedgerEntry."No. Authorizacion_DXR" <> CustLedgerEntry."No. Authorizacion" then begin
                    CustLedgerEntry."No. Authorizacion_DXR" := CustLedgerEntry."No. Authorizacion";
                    CustLedgerEntry.Modify(false);
                end;
            until CustLedgerEntry.Next() = 0;
    end;

    // Fixed 2026-08-24 (master-data table, elevated shadow-field scrutiny): the old RecordRef
    // version copied every one of these 46 fields into a "_BE_DXR" intermediate (50061-50106) that
    // is ITSELF further obsolete - confirmed via ObsoleteReason on each "_BE_DXR" field in
    // Customer.TableExt.al: "Field was renumbered and renamed to <ID> (...) by commit c9e8f48d
    // without a data migration ... Restored at its true original ID so 'Bellon Migr. Phase 5
    // CustItem' (cod. 56122) can bridge the value forward." That sibling codeunit
    // (BellonMigrPhase5CustItemDXR.Codeunit.al) independently bridges the same 46 "_BE_DXR" fields
    // to their true final "_DXR" targets (52787-52833 block) with a never-overwrite merge policy -
    // its own field-number comments are the authoritative source for the mapping used below, cross-
    // checked field-by-field against Customer.TableExt.al's ObsoleteReason text. Writing directly to
    // the final "_DXR" targets here (skipping the dead "_BE_DXR" hop entirely) makes this
    // procedure's result correct standalone, without depending on phase 5 having also run. None of
    // the final "_DXR" targets below are themselves obsolete.
    local procedure MigrateTableExt_CustomerFields()
    var
        Customer: Record Customer;
    begin
        if Customer.FindSet(true) then
            repeat
                if (Customer."Dirección Representante_DXR" <> Customer."Dirección Representante") or
                   (Customer."Sector Representante_DXR" <> Customer."Sector Representante") or
                   (Customer."Cédula Representante_DXR" <> Customer."Cédula Representante") or
                   (Customer."Cumpl Representante_DXR" <> Customer."Cumpleaños Representante") or
                   (Customer."Celular Representante_DXR" <> Customer."Celular Representante") or
                   (Customer."E-Mail Representante_DXR." <> Customer."E-Mail Representante") or
                   (Customer."Código Cobrador_DXR" <> Customer."Código Cobrador") or
                   (Customer."Requiere OC_DXR" <> Customer."Requiere OC") or
                   (Customer."Tipo de Cliente_DXR" <> Customer."Tipo de Cliente") or
                   (Customer."Frecuencia Visita_DXR" <> Customer."Frecuencia Visita") or
                   (Customer."Secuencia Visita_DXR" <> Customer."Secuencia Visita") or
                   (Customer."Días Visita_DXR" <> Customer."Días Visita") or
                   (Customer."Carnet DGII_DXR" <> Customer."Carnet DGII") or
                   (Customer."Cobrar Interés_DXR" <> Customer."Cobrar Interés") or
                   (Customer."% Interés_DXR" <> Customer."% Interés") or
                   (Customer."Carnet Exención ITBIS_DXR" <> Customer."Carnet Exención ITBIS") or
                   (Customer."Vencimiento Carnet_DXR" <> Customer."Vencimiento Carnet") or
                   (Customer."Enc. Compras Nombre_DXR" <> Customer."Enc. Compras Nombre") or
                   (Customer."Enc. Compras Email_DXR." <> Customer."Enc. Compras email") or
                   (Customer."Enc. Compras celular_DXR" <> Customer."Enc. Compras celular") or
                   (Customer."Enc. Compras Cumpleaños_DXR" <> Customer."Enc. Compras Cumpleaños") or
                   (Customer."Enc. Pagos Nombre_DXR" <> Customer."Enc. Pagos Nombre") or
                   (Customer."Enc. Pagos Email_DXR." <> Customer."Enc. Pagos email") or
                   (Customer."Enc. Pagos celular_DXR" <> Customer."Enc. Pagos celular") or
                   (Customer."Enc. Pagos Cumpleaños_DXR" <> Customer."Enc. Pagos Cumpleaños") or
                   (Customer."Frecuencia de Pago_DXR" <> Customer."Frecuencia de Pago") or
                   (Customer."Apartado Postal_DXR" <> Customer."Apartado Postal") or
                   (Customer."Sector_DXR" <> Customer.Sector) or
                   (Customer."Municipio_DXR" <> Customer.Municipio) or
                   (Customer."Provincia_DXR" <> Customer.Provincia) or
                   (Customer."Comision_Tipo_ID_DXR." <> Customer.Comision_Tipo_ID) or
                   (Customer."Deuda Pico_DXR" <> Customer."Deuda Pico") or
                   (Customer."Fecha Deuda Pico_DXR" <> Customer."Fecha Deuda Pico") or
                   (Customer."Gestor_ID_DXR." <> Customer.Gestor_ID) or
                   (Customer."Fecha envio edo cuenta_DXR" <> Customer."Fecha envio estado cuenta") or
                   (Customer."Invoice Expiration Days_DXR" <> Customer."Invoice Expiration Days") or
                   (Customer."Enc. Recepcion Email_DXR." <> Customer."Enc. Recepcion Email") or
                   (Customer."StoreID_DXR." <> Customer.StoreId) or
                   (Customer."Tipo Segmento_DXR" <> Customer."Tipo Segmento") or
                   (Customer."Monto Deposito Cilindr_DXR" <> Customer."Monto Deposito - Cilindros") or
                   (Customer."Cant asig - Cilindros_DXR" <> Customer."Cantidad asignar - Cilindros") or
                   (Customer."Cliente Cilindros_DXR" <> Customer."Cliente Cilindros") or
                   (Customer."Fecha Exp Reg Merc_DXR" <> Customer."Fecha Expiracion Reg Mercantil") or
                   (Customer."B2C Customer_DXR" <> Customer."B2C Customer") or
                   (Customer."Last Date/Time Modified_DXR" <> Customer."Last Date/Time Modified") or
                   (Customer."Req Fecha Reg Merc_DXR" <> Customer."Requiere Fecha Reg. Mercantil")
                then begin
                    Customer."Dirección Representante_DXR" := Customer."Dirección Representante";
                    Customer."Sector Representante_DXR" := Customer."Sector Representante";
                    Customer."Cédula Representante_DXR" := Customer."Cédula Representante";
                    Customer."Cumpl Representante_DXR" := Customer."Cumpleaños Representante";
                    Customer."Celular Representante_DXR" := Customer."Celular Representante";
                    Customer."E-Mail Representante_DXR." := Customer."E-Mail Representante";
                    Customer."Código Cobrador_DXR" := Customer."Código Cobrador";
                    Customer."Requiere OC_DXR" := Customer."Requiere OC";
                    Customer."Tipo de Cliente_DXR" := Customer."Tipo de Cliente";
                    Customer."Frecuencia Visita_DXR" := Customer."Frecuencia Visita";
                    Customer."Secuencia Visita_DXR" := Customer."Secuencia Visita";
                    Customer."Días Visita_DXR" := Customer."Días Visita";
                    Customer."Carnet DGII_DXR" := Customer."Carnet DGII";
                    Customer."Cobrar Interés_DXR" := Customer."Cobrar Interés";
                    Customer."% Interés_DXR" := Customer."% Interés";
                    Customer."Carnet Exención ITBIS_DXR" := Customer."Carnet Exención ITBIS";
                    Customer."Vencimiento Carnet_DXR" := Customer."Vencimiento Carnet";
                    Customer."Enc. Compras Nombre_DXR" := Customer."Enc. Compras Nombre";
                    Customer."Enc. Compras Email_DXR." := Customer."Enc. Compras email";
                    Customer."Enc. Compras celular_DXR" := Customer."Enc. Compras celular";
                    Customer."Enc. Compras Cumpleaños_DXR" := Customer."Enc. Compras Cumpleaños";
                    Customer."Enc. Pagos Nombre_DXR" := Customer."Enc. Pagos Nombre";
                    Customer."Enc. Pagos Email_DXR." := Customer."Enc. Pagos email";
                    Customer."Enc. Pagos celular_DXR" := Customer."Enc. Pagos celular";
                    Customer."Enc. Pagos Cumpleaños_DXR" := Customer."Enc. Pagos Cumpleaños";
                    Customer."Frecuencia de Pago_DXR" := Customer."Frecuencia de Pago";
                    Customer."Apartado Postal_DXR" := Customer."Apartado Postal";
                    Customer."Sector_DXR" := Customer.Sector;
                    Customer."Municipio_DXR" := Customer.Municipio;
                    Customer."Provincia_DXR" := Customer.Provincia;
                    Customer."Comision_Tipo_ID_DXR." := Customer.Comision_Tipo_ID;
                    Customer."Deuda Pico_DXR" := Customer."Deuda Pico";
                    Customer."Fecha Deuda Pico_DXR" := Customer."Fecha Deuda Pico";
                    Customer."Gestor_ID_DXR." := Customer.Gestor_ID;
                    Customer."Fecha envio edo cuenta_DXR" := Customer."Fecha envio estado cuenta";
                    Customer."Invoice Expiration Days_DXR" := Customer."Invoice Expiration Days";
                    Customer."Enc. Recepcion Email_DXR." := Customer."Enc. Recepcion Email";
                    Customer."StoreID_DXR." := Customer.StoreId;
                    Customer."Tipo Segmento_DXR" := Customer."Tipo Segmento";
                    Customer."Monto Deposito Cilindr_DXR" := Customer."Monto Deposito - Cilindros";
                    Customer."Cant asig - Cilindros_DXR" := Customer."Cantidad asignar - Cilindros";
                    Customer."Cliente Cilindros_DXR" := Customer."Cliente Cilindros";
                    Customer."Fecha Exp Reg Merc_DXR" := Customer."Fecha Expiracion Reg Mercantil";
                    Customer."B2C Customer_DXR" := Customer."B2C Customer";
                    Customer."Last Date/Time Modified_DXR" := Customer."Last Date/Time Modified";
                    Customer."Req Fecha Reg Merc_DXR" := Customer."Requiere Fecha Reg. Mercantil";
                    Customer.Modify(false);
                end;
            until Customer.Next() = 0;
    end;

    local procedure MigrateTableExt_CustomerPriceGroupFields()
    var
        CustomerPriceGroup: Record "Customer Price Group";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // targeted field 50001, which in CustomerPriceGroup.TableExt.al is a completely unrelated,
        // Removed Boolean field ("Relacionado a Precio GLOBAL") - not even the intended shadow
        // field. The actual dead shadow field is 50002 "Global Sales Code_Old"; the real active
        // target, confirmed via ObsoleteReason on field 50000 (52787 is not itself obsolete), is
        // "Global Sales Code_DXR" (52787). Direct typed field closes both gaps.
        if CustomerPriceGroup.FindSet(true) then
            repeat
                if CustomerPriceGroup."Global Sales Code_DXR" <> CustomerPriceGroup."Global Sales Code" then begin
                    CustomerPriceGroup."Global Sales Code_DXR" := CustomerPriceGroup."Global Sales Code";
                    CustomerPriceGroup.Modify(false);
                end;
            until CustomerPriceGroup.Next() = 0;
    end;

    local procedure MigrateTableExt_GenJournalBatchFields()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "Pago Electronico" into the dead
        // "_Old" shadow field (50004) - GenJournalBatch.TableExt.al's real active target,
        // confirmed via ObsoleteReason on field 50002 (52787 is not itself obsolete), is
        // "Pago Electronico_DXR" (52787). The other legacy pair, field 50003 "Exclude Rec" ->
        // 50005, is a FlowField on both the old and new side (identical CalcFormula against
        // "DXR_Exclude Filter Journal", already DXR_-normalized) - there is no stored value to
        // migrate for a FlowField, so that pair is intentionally omitted, matching the fact that
        // the old code's destination (50005) never existed in the schema either.
        if GenJournalBatch.FindSet(true) then
            repeat
                if GenJournalBatch."Pago Electronico_DXR" <> GenJournalBatch."Pago Electronico" then begin
                    GenJournalBatch."Pago Electronico_DXR" := GenJournalBatch."Pago Electronico";
                    GenJournalBatch.Modify(false);
                end;
            until GenJournalBatch.Next() = 0;
    end;

    local procedure MigrateTableExt_GenJournalLineFields()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied all nine fields into dead "_Old"
        // shadow fields (50055-50063) - GenJournalLine.TableExt.al's real active targets,
        // confirmed via ObsoleteReason on each source field (none of the _DXR destinations below
        // are themselves obsolete; "Posting Exch. Entry No._DXR"/"Posting Exch. Line No._DXR" are
        // also live-read by this same tableextension's own ClearPostExchangeEntries()), are
        // 52787-52795. Direct typed fields close that gap.
        if GenJournalLine.FindSet(true) then
            repeat
                if (GenJournalLine."Pago Electronico_DXR" <> GenJournalLine."Pago Electronico") or
                   (GenJournalLine."IsRecaudo_DXR" <> GenJournalLine.IsRecaudo) or
                   (GenJournalLine."ePAGOS_DXR" <> GenJournalLine.ePAGOS) or
                   (GenJournalLine."VendorPay No._DXR" <> GenJournalLine."VendorPay No.") or
                   (GenJournalLine."Only Two Dimensions_DXR" <> GenJournalLine."Only Two Dimensions") or
                   (GenJournalLine."No. Authorizacion_DXR" <> GenJournalLine."No. Authorizacion") or
                   (GenJournalLine."Fecha Registro2_DXR" <> GenJournalLine."Fecha Registro2") or
                   (GenJournalLine."Posting Exch. Entry No._DXR" <> GenJournalLine."Posting Exch. Entry No.") or
                   (GenJournalLine."Posting Exch. Line No._DXR" <> GenJournalLine."Posting Exch. Line No.")
                then begin
                    GenJournalLine."Pago Electronico_DXR" := GenJournalLine."Pago Electronico";
                    GenJournalLine."IsRecaudo_DXR" := GenJournalLine.IsRecaudo;
                    GenJournalLine."ePAGOS_DXR" := GenJournalLine.ePAGOS;
                    GenJournalLine."VendorPay No._DXR" := GenJournalLine."VendorPay No.";
                    GenJournalLine."Only Two Dimensions_DXR" := GenJournalLine."Only Two Dimensions";
                    GenJournalLine."No. Authorizacion_DXR" := GenJournalLine."No. Authorizacion";
                    GenJournalLine."Fecha Registro2_DXR" := GenJournalLine."Fecha Registro2";
                    GenJournalLine."Posting Exch. Entry No._DXR" := GenJournalLine."Posting Exch. Entry No.";
                    GenJournalLine."Posting Exch. Line No._DXR" := GenJournalLine."Posting Exch. Line No.";
                    GenJournalLine.Modify(false);
                end;
            until GenJournalLine.Next() = 0;
    end;

    local procedure MigrateTableExt_GenProductPostingGroupFields()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "Internal Consumption" into the dead
        // "_Old" shadow field (50001) - GenProductPostingGroup.TableExt.al's real active target,
        // confirmed via ObsoleteReason on field 50000 (52787 is not itself obsolete), is
        // "Internal Consumption_DXR" (52787). Direct typed field closes that gap.
        if GenProductPostingGroup.FindSet(true) then
            repeat
                if GenProductPostingGroup."Internal Consumption_DXR" <> GenProductPostingGroup."Internal Consumption" then begin
                    GenProductPostingGroup."Internal Consumption_DXR" := GenProductPostingGroup."Internal Consumption";
                    GenProductPostingGroup.Modify(false);
                end;
            until GenProductPostingGroup.Next() = 0;
    end;

    local procedure MigrateTableExt_GeneralLedgerSetupFields()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "Fecha Inicio AJCOSTO" into the dead
        // "_Old" shadow field (50001) - GeneralLedgerSetup.TableExt.al's real active target,
        // confirmed via ObsoleteReason on field 50000 (52787 is not itself obsolete), is
        // "Fecha Inicio AJCOSTO_DXR" (52787). General Ledger Setup is a single-row table (blank
        // primary key). Direct typed field closes that gap.
        if GeneralLedgerSetup.Get() then
            if GeneralLedgerSetup."Fecha Inicio AJCOSTO_DXR" <> GeneralLedgerSetup."Fecha Inicio AJCOSTO" then begin
                GeneralLedgerSetup."Fecha Inicio AJCOSTO_DXR" := GeneralLedgerSetup."Fecha Inicio AJCOSTO";
                GeneralLedgerSetup.Modify(false);
            end;
    end;

    local procedure MigrateTableExt_IssuedReminderHeaderFields()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // Fixed 2026-08-24: the old RecordRef version had three pairs. (1) CopyFieldIfExists(RecRef,
        // 50000, 50003): destination 50003 never existed in IssuedReminderHeader.TableExt.al's
        // schema (already a guaranteed no-op) - source field 50000 "Codigo Cobrador" is a FlowField,
        // replaced by FlowField 52787, so no stored value either way; correctly dropped. (2)
        // CopyFieldIfExists(RecRef, 50001, 50004) copied "Remaining Amount 2" into "Remaining
        // Amount 2_Old" (field 50004), a dead shadow field - the real active target, confirmed via
        // ObsoleteReason on field 50001 (52788 is not itself obsolete), is "Remaining Amount 2_DXR"
        // (52788). (3) CopyFieldIfExists(RecRef, 50002, 50005): destination 50005 never existed
        // either (guaranteed no-op) - source field 50002 "Cust Post Group Ficha Cliente" is also a
        // FlowField, replaced by FlowField 52789, no stored value; correctly dropped. Direct typed
        // field for pair (2) closes that one real gap.
        if IssuedReminderHeader.FindSet(true) then
            repeat
                if IssuedReminderHeader."Remaining Amount 2_DXR" <> IssuedReminderHeader."Remaining Amount 2" then begin
                    IssuedReminderHeader."Remaining Amount 2_DXR" := IssuedReminderHeader."Remaining Amount 2";
                    IssuedReminderHeader.Modify(false);
                end;
            until IssuedReminderHeader.Next() = 0;
    end;

    // No-op by design (2026-08-24): IssuedReminderLine.TableExt.al defines only field 50000
    // "Remaining Amount 2" (Pending, obsolete) and its replacement 52787 "Remaining Amount 2_DXR" -
    // both are FlowFields (identical CalcFormula = Sum("Detailed Cust. Ledg. Entry".Amount ...)), so
    // there is no stored value to migrate. The old RecordRef version's destination (50001) never
    // existed in the schema either (CopyFieldIfExists was already a guaranteed no-op on every row).
    // Nothing to open, nothing to copy.
    local procedure MigrateTableExt_IssuedReminderLineFields()
    begin
    end;

    // Fixed 2026-08-24 (master-data table, elevated shadow-field scrutiny): same two-hop shadow-
    // field pattern as MigrateTableExt_CustomerFields() above - the old RecordRef version copied
    // every field into a "_BE_DXR" intermediate (50036-50070) that is ITSELF further obsolete per
    // Item.TableExt.al's own ObsoleteReason text ("Field was renumbered and renamed to <ID> ... by
    // commit c9e8f48d without a data migration ... Restored ... so 'Bellon Migr. Phase 5 CustItem'
    // (cod. 56122) can bridge the value forward"), cross-checked against that sibling codeunit's own
    // BridgeItemOldGenFields() field-number comments. Two legacy pairs from the old code - 50032
    // "Buyer Group Code" -> 50067 and 50033 Inventory2 -> 50068 - are correctly dropped: both are
    // FlowFields on the legacy side AND their true final targets (52818/52819) are also FlowFields
    // (no "_BE_DXR" intermediate was ever declared for either), so there is no stored value to
    // migrate, matching BellonMigrPhase5CustItemDXR.Codeunit.al's own explicit exclusion of the same
    // two fields. Writing directly to the final "_DXR" targets here (skipping the dead "_BE_DXR"
    // hop) makes this procedure correct standalone. None of the final "_DXR" targets below are
    // themselves obsolete.
    local procedure MigrateTableExt_ItemFields()
    var
        Item: Record Item;
    begin
        if Item.FindSet(true) then
            repeat
                if (Item."Modelo_DXR" <> Item.Modelo) or
                   (Item."Marca_DXR" <> Item.Marca) or
                   (Item."Se Detalla_DXR" <> Item."Se Detalla") or
                   (Item."Producido_DXR" <> Item.Producido) or
                   (Item."Carga % Tarjeta_DXR" <> Item."Carga % Tarjeta") or
                   (Item."Consignación_DXR" <> Item."Consignación") or
                   (Item."Internal Use_DXR" <> Item."Internal Use") or
                   (Item."Acepta Decimales_DXR" <> Item."Acepta Decimales") or
                   (Item."Exhibición_DXR" <> Item."Exhibición") or
                   (Item."Precio Sugerido_DXR" <> Item."Precio Sugerido") or
                   (Item."Kit_DXR" <> Item.Kit) or
                   (Item."Empaque_DXR" <> Item.Empaque) or
                   (Item."Empaque Maestro_DXR" <> Item."Empaque Maestro") or
                   (Item."Venta por Mayor_DXR" <> Item."Venta por Mayor") or
                   (Item."% Comisión Venta_DXR" <> Item."% Comisión Venta") or
                   (Item."% Comisión Cobro_DXR" <> Item."% Comisión Cobro") or
                   (Item."Márgen Plaza_DXR" <> Item."Márgen Plaza") or
                   (Item."Márgen Importación_DXR" <> Item."Márgen Importación") or
                   (Item."Descripcion_Bellon_DXR" <> Item."Descripcion Bellon") or
                   (Item."Costo Liquidacion_DXR" <> Item."Costo Liquidacion") or
                   (Item."Comision_Tipo_ID_DXR." <> Item.Comision_Tipo_ID) or
                   (Item."Ultimo Costo Bellon_DXR" <> Item."Ultimo Costo Bellon") or
                   (Item."Costo Unitario Bellon_DXR" <> Item."Costo Unitario Bellon") or
                   (Item."SANA Info Adicionales_DXR" <> Item."SANA - Info. Adicionales") or
                   (Item."Sales Group_DXR" <> Item."Sales Group") or
                   (Item."Sales SubGroup_DXR" <> Item."Sales SubGroup") or
                   (Item."Sales Dept Code_DXR" <> Item."Sales Dept Code") or
                   (Item."Codigo Producto Aduana_DXR" <> Item."Codigo Producto Aduana") or
                   (Item."ExclFromDiscountCoupons_DXR" <> Item.ExcludedFromDiscountCoupons) or
                   (Item."ExclFromFreeShipCoupons_DXR" <> Item.ExcludedFromFreeShipCoupons) or
                   (Item."Disponible para Ventas_DXR" <> Item."Disponible para Ventas") or
                   (Item."Item Status_DXR" <> Item."Item Status") or
                   (Item."Control Existencia_DXR" <> Item."Control Existencia")
                then begin
                    Item."Modelo_DXR" := Item.Modelo;
                    Item."Marca_DXR" := Item.Marca;
                    Item."Se Detalla_DXR" := Item."Se Detalla";
                    Item."Producido_DXR" := Item.Producido;
                    Item."Carga % Tarjeta_DXR" := Item."Carga % Tarjeta";
                    Item."Consignación_DXR" := Item."Consignación";
                    Item."Internal Use_DXR" := Item."Internal Use";
                    Item."Acepta Decimales_DXR" := Item."Acepta Decimales";
                    Item."Exhibición_DXR" := Item."Exhibición";
                    Item."Precio Sugerido_DXR" := Item."Precio Sugerido";
                    Item."Kit_DXR" := Item.Kit;
                    Item."Empaque_DXR" := Item.Empaque;
                    Item."Empaque Maestro_DXR" := Item."Empaque Maestro";
                    Item."Venta por Mayor_DXR" := Item."Venta por Mayor";
                    Item."% Comisión Venta_DXR" := Item."% Comisión Venta";
                    Item."% Comisión Cobro_DXR" := Item."% Comisión Cobro";
                    Item."Márgen Plaza_DXR" := Item."Márgen Plaza";
                    Item."Márgen Importación_DXR" := Item."Márgen Importación";
                    Item."Descripcion_Bellon_DXR" := Item."Descripcion Bellon";
                    Item."Costo Liquidacion_DXR" := Item."Costo Liquidacion";
                    Item."Comision_Tipo_ID_DXR." := Item.Comision_Tipo_ID;
                    Item."Ultimo Costo Bellon_DXR" := Item."Ultimo Costo Bellon";
                    Item."Costo Unitario Bellon_DXR" := Item."Costo Unitario Bellon";
                    Item."SANA Info Adicionales_DXR" := Item."SANA - Info. Adicionales";
                    Item."Sales Group_DXR" := Item."Sales Group";
                    Item."Sales SubGroup_DXR" := Item."Sales SubGroup";
                    Item."Sales Dept Code_DXR" := Item."Sales Dept Code";
                    Item."Codigo Producto Aduana_DXR" := Item."Codigo Producto Aduana";
                    Item."ExclFromDiscountCoupons_DXR" := Item.ExcludedFromDiscountCoupons;
                    Item."ExclFromFreeShipCoupons_DXR" := Item.ExcludedFromFreeShipCoupons;
                    Item."Disponible para Ventas_DXR" := Item."Disponible para Ventas";
                    Item."Item Status_DXR" := Item."Item Status";
                    Item."Control Existencia_DXR" := Item."Control Existencia";
                    Item.Modify(false);
                end;
            until Item.Next() = 0;
    end;

    local procedure MigrateTableExt_ItemCategoryFields()
    var
        ItemCategory: Record "Item Category";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "% Comision" into "% Comision_Old" (field 50001), a dead shadow field -
        // ItemCategory.TableExt.al's real active target, confirmed via ObsoleteReason on field 50000
        // (52787 is not itself obsolete), is "% Comision_DXR" (52787). Direct typed field closes
        // that gap.
        if ItemCategory.FindSet(true) then
            repeat
                if ItemCategory."% Comision_DXR" <> ItemCategory."% Comision" then begin
                    ItemCategory."% Comision_DXR" := ItemCategory."% Comision";
                    ItemCategory.Modify(false);
                end;
            until ItemCategory.Next() = 0;
    end;

    local procedure MigrateTableExt_ItemChargeAssignmentPurchFields()
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
    begin
        // Fixed 2026-08-24: ItemChargeAssignmentPurch.TableExt.al's real active target, confirmed
        // via ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Monto Cargo
        // Liq._DXR" (52787) - not the dead "Monto Cargo Liq._Old" shadow field (50001) the old
        // RecordRef code wrote into.
        if ItemChargeAssignmentPurch.FindSet(true) then
            repeat
                if ItemChargeAssignmentPurch."Monto Cargo Liq._DXR" <> ItemChargeAssignmentPurch."Monto Cargo Liq." then begin
                    ItemChargeAssignmentPurch."Monto Cargo Liq._DXR" := ItemChargeAssignmentPurch."Monto Cargo Liq.";
                    ItemChargeAssignmentPurch.Modify(false);
                end;
            until ItemChargeAssignmentPurch.Next() = 0;
    end;

    // No-op by design (2026-08-24): ItemJournalBatch.TableExt.al defines exactly one Bellon field
    // pair here - source field 50000 "Exclude Rec" and its replacement 52787 "Exclude Rec_DXR" -
    // and BOTH are FlowFields (identical CalcFormula); there is no stored value to migrate for a
    // FlowField, matching the fact that the old code's RecordRef destination (50001) never existed
    // in the schema either (CopyFieldIfExists was already a guaranteed no-op on every row). Nothing
    // to open, nothing to copy.
    local procedure MigrateTableExt_ItemJournalBatchFields()
    begin
    end;

    local procedure MigrateTableExt_ItemJournalLineFields()
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Fixed 2026-08-24: ItemJournalLine.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50003 (52787 is not itself obsolete), is "No. Discrepancia_DXR"
        // (52787) - the old RecordRef code's destination (50004) never existed in the schema at
        // all (CopyFieldIfExists was already a guaranteed no-op on every row).
        if ItemJournalLine.FindSet(true) then
            repeat
                if ItemJournalLine."No. Discrepancia_DXR" <> ItemJournalLine."No. Discrepancia" then begin
                    ItemJournalLine."No. Discrepancia_DXR" := ItemJournalLine."No. Discrepancia";
                    ItemJournalLine.Modify(false);
                end;
            until ItemJournalLine.Next() = 0;
    end;

    // No-op by design (2026-08-24): ItemLedgerEntry.TableExt.al defines two Bellon field pairs
    // here - source fields 50003 "Existencia Ventas"/50004 "Transito Internacional" and their
    // replacements 52787/52788 - and every field in both pairs is a FlowField (CalcFormula lookups
    // onto Location); there is no stored value to migrate for a FlowField, matching the fact that
    // the old code's RecordRef destinations (50005/50006) never existed in the schema either.
    // Nothing to open, nothing to copy.
    local procedure MigrateTableExt_ItemLedgerEntryFields()
    begin
    end;

    local procedure MigrateTableExt_LSCItemSpecialGroupsFields()
    var
        LSCItemSpecialGroups: Record "LSC Item Special Groups";
    begin
        // Fixed 2026-08-24: ItemSpecialGroups.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "% Comision_DXR"
        // (52787) - not the dead "% Comision_Old" shadow field (50001) the old RecordRef code
        // wrote into.
        if LSCItemSpecialGroups.FindSet(true) then
            repeat
                if LSCItemSpecialGroups."% Comision_DXR" <> LSCItemSpecialGroups."% Comision" then begin
                    LSCItemSpecialGroups."% Comision_DXR" := LSCItemSpecialGroups."% Comision";
                    LSCItemSpecialGroups.Modify(false);
                end;
            until LSCItemSpecialGroups.Next() = 0;
    end;

    local procedure MigrateTableExt_DXCashJournalReceiptListFields()
    var
        CashJournalReceiptList: Record "DXR_Cash Journal Receipt List";
    begin
        // Retrofitted 2026-08-24 (bridge retirement): "DXR_Cash Journal Receipt List" (table
        // 52132, DR-Localization) is declared Access = Internal there, but DR-Localization now
        // grants MCC's own app ID internalsVisibleTo directly (confirmed via DR-Localization\
        // Localization\app.json), so a typed Record can be declared directly in MCC - no bridge
        // codeunit needed. Zero RecordRef/FieldRef/TransferFields.
        //
        // Field mapping: ListadoRecibodeIngreso.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on the source fields (none of the _DXR replacements are themselves
        // obsolete):
        //   50000 "Documento Registrado" -> 52787 "Documento Registrado_DXR" (old code wrote into
        //     the dead "..._Old" shadow field 50006 instead).
        //   50005 "Fecha Vencimiento" -> 52789 "Fecha Vencimiento_DXR" (old code wrote into dead
        //     shadow 50008).
        //   50003 IsRecaudo -> 52791 "IsRecaudo_DXR" (old code wrote into dead shadow 50010).
        //   50004 "No. Authorizacion" -> 52792 "No. Authorizacion_DXR" (old code wrote into dead
        //     shadow 50011).
        //   50001 Cobrador / 50002 Gestor and their _DXR replacements (52788/52790) are all
        //     FlowFields (CalcFormula lookups onto Customer) - no stored value to migrate, so those
        //     two field pairs are dropped entirely (the old code's destinations 50007/50009 never
        //     existed in the schema either, so they were already guaranteed no-ops).
        if CashJournalReceiptList.FindSet(true) then
            repeat
                if (CashJournalReceiptList."Documento Registrado_DXR" <> CashJournalReceiptList."Documento Registrado") or
                   (CashJournalReceiptList."Fecha Vencimiento_DXR" <> CashJournalReceiptList."Fecha Vencimiento") or
                   (CashJournalReceiptList."IsRecaudo_DXR" <> CashJournalReceiptList.IsRecaudo) or
                   (CashJournalReceiptList."No. Authorizacion_DXR" <> CashJournalReceiptList."No. Authorizacion")
                then begin
                    CashJournalReceiptList."Documento Registrado_DXR" := CashJournalReceiptList."Documento Registrado";
                    CashJournalReceiptList."Fecha Vencimiento_DXR" := CashJournalReceiptList."Fecha Vencimiento";
                    CashJournalReceiptList."IsRecaudo_DXR" := CashJournalReceiptList.IsRecaudo;
                    CashJournalReceiptList."No. Authorizacion_DXR" := CashJournalReceiptList."No. Authorizacion";
                    CashJournalReceiptList.Modify(false);
                end;
            until CashJournalReceiptList.Next() = 0;
    end;

    local procedure MigrateTableExt_LocationFields()
    var
        Location: Record Location;
    begin
        // Fixed 2026-08-24: Location.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on each source field (none of the _DXR replacements are themselves
        // obsolete), are the 52787-52792 fields - not the dead "..._Old" shadow fields
        // (50006-50011) the old RecordRef code wrote into.
        if Location.FindSet(true) then
            repeat
                if (Location."Req._Transport_DXR" <> Location."Req. Transport") or
                   (Location."Existencia Ventas_DXR" <> Location."Existencia Ventas") or
                   (Location."Transito Internacional_DXR" <> Location."Transito Internacional") or
                   (Location."Req. Cod. Audit Transf_DXR" <> Location."Req. Cod. Auditoria Transf.") or
                   (Location."Visible in Trafico_DXR" <> Location."Visible in Trafico") or
                   (Location."Req. Cod. Pos. & Neg._DXR" <> Location."Req. Cod. Pos. & Neg.")
                then begin
                    Location."Req._Transport_DXR" := Location."Req. Transport";
                    Location."Existencia Ventas_DXR" := Location."Existencia Ventas";
                    Location."Transito Internacional_DXR" := Location."Transito Internacional";
                    Location."Req. Cod. Audit Transf_DXR" := Location."Req. Cod. Auditoria Transf.";
                    Location."Visible in Trafico_DXR" := Location."Visible in Trafico";
                    Location."Req. Cod. Pos. & Neg._DXR" := Location."Req. Cod. Pos. & Neg.";
                    Location.Modify(false);
                end;
            until Location.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCMemberContactFields()
    var
        LSCMemberContact: Record "LSC Member Contact";
    begin
        // Fixed 2026-08-24: MemberContact.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on each source field (none of the _DXR replacements are themselves
        // obsolete), are the 52787-52792 fields - not the dead "..._Old" shadow fields
        // (50006-50011) the old RecordRef code wrote into.
        if LSCMemberContact.FindSet(true) then
            repeat
                if (LSCMemberContact."Cedula_DXR" <> LSCMemberContact.Cedula) or
                   (LSCMemberContact."Newsletter_DXR" <> LSCMemberContact.Newsletter) or
                   (LSCMemberContact."Profesion_DXR" <> LSCMemberContact.Profesion) or
                   (LSCMemberContact."Area de Trabajo_DXR" <> LSCMemberContact."Area de Trabajo") or
                   (LSCMemberContact."Cantidad De Hijos_DXR" <> LSCMemberContact."Cantidad De Hijos") or
                   (LSCMemberContact."Sucursal Preferida_DXR" <> LSCMemberContact."Sucursal Preferida")
                then begin
                    LSCMemberContact."Cedula_DXR" := LSCMemberContact.Cedula;
                    LSCMemberContact."Newsletter_DXR" := LSCMemberContact.Newsletter;
                    LSCMemberContact."Profesion_DXR" := LSCMemberContact.Profesion;
                    LSCMemberContact."Area de Trabajo_DXR" := LSCMemberContact."Area de Trabajo";
                    LSCMemberContact."Cantidad De Hijos_DXR" := LSCMemberContact."Cantidad De Hijos";
                    LSCMemberContact."Sucursal Preferida_DXR" := LSCMemberContact."Sucursal Preferida";
                    LSCMemberContact.Modify(false);
                end;
            until LSCMemberContact.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCMemberPointOfferFields()
    var
        LSCMemberPointOffer: Record "LSC Member Point Offer";
    begin
        // Fixed 2026-08-24: MemberPointOffer.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on each source field (none of the _DXR replacements are themselves
        // obsolete), are the 52787-52790 fields - not the dead "..._Old" shadow fields
        // (50004-50007) the old RecordRef code wrote into.
        if LSCMemberPointOffer.FindSet(true) then
            repeat
                if (LSCMemberPointOffer."isTickets_DXR" <> LSCMemberPointOffer.isTickets) or
                   (LSCMemberPointOffer."Promotion Status_DXR" <> LSCMemberPointOffer."Promotion Status") or
                   (LSCMemberPointOffer."Multiplier for members_DXR" <> LSCMemberPointOffer."Multiplier for members") or
                   (LSCMemberPointOffer."Calc. Type_DXR" <> LSCMemberPointOffer."Calc. Type")
                then begin
                    LSCMemberPointOffer."isTickets_DXR" := LSCMemberPointOffer.isTickets;
                    LSCMemberPointOffer."Promotion Status_DXR" := LSCMemberPointOffer."Promotion Status";
                    LSCMemberPointOffer."Multiplier for members_DXR" := LSCMemberPointOffer."Multiplier for members";
                    LSCMemberPointOffer."Calc. Type_DXR" := LSCMemberPointOffer."Calc. Type";
                    LSCMemberPointOffer.Modify(false);
                end;
            until LSCMemberPointOffer.Next() = 0;
    end;

    // No-op by design (2026-08-24): MemberPointOfferLine.TableExt.al defines exactly one Bellon
    // field pair here - source field 50001 Status and its replacement 52787 "Status_DXR" - and
    // BOTH are FlowFields (identical CalcFormula = Lookup("LSC Member Point Offer".Status ...));
    // there is no stored value to migrate for a FlowField, matching the fact that the old code's
    // RecordRef destination (50002) never existed in the schema either. Nothing to open, nothing to
    // copy.
    local procedure MigrateTableExt_LSCMemberPointOfferLineFields()
    begin
    end;

    // No-op by design (2026-08-24): MovsRetencionProveedor.TableExt.al (extends DR-Localization's
    // Access=Internal table 52204) defines exactly one Bellon field pair here - source field 50000
    // "Invoice Posting Date" and its replacement 52787 "Invoice Posting Date_DXR" - and BOTH are
    // FlowFields (identical CalcFormula = Lookup("Purch. Inv. Header"."Posting Date" WHERE(...)));
    // there is no stored value to migrate for a FlowField, matching the fact that the old code's
    // RecordRef destination (50001) never existed in the schema either (CopyFieldIfExists was
    // already a guaranteed no-op on every row). Nothing to open, nothing to copy.
    local procedure MigrateTableExt_DXVendorWithholdingLedgerEntryFields()
    begin
    end;

    // Retrofitted 2026-08-24 (bridge retirement): DXR_NCF Setup (table 52179, DR-Localization) is
    // declared Access = Internal there, but DR-Localization now grants MCC's own app ID
    // internalsVisibleTo directly (confirmed via DR-Localization\Localization\app.json), so a
    // typed Record on "DXR_NCF Setup" can now be declared directly in MCC - no bridge codeunit
    // needed. BELLON's own "DXR_BE MCC Migr Bridge" (56132) is left in place, unused, per this
    // task's scope. Zero RecordRef/FieldRef/TransferFields in this procedure.
    //
    // Field mapping: NCFSetup.TableExt.al's real active targets, confirmed via ObsoleteReason on
    // fields 50001/50002 (neither destination is itself obsolete), are "Grupo Contable BS_DXR"
    // (52787) and "Legal Tip %_DXR" (52788). "DXR_NCF Setup" is a single-row table (blank primary
    // key).
    local procedure MigrateTableExt_DXNCFSetupFields()
    var
        NCFSetup: Record "DXR_NCF Setup";
    begin
        if NCFSetup.Get() then
            if (NCFSetup."Grupo Contable BS_DXR" <> NCFSetup."Grupo Contable BS") or
               (NCFSetup."Legal Tip %_DXR" <> NCFSetup."Legal Tip %")
            then begin
                NCFSetup."Grupo Contable BS_DXR" := NCFSetup."Grupo Contable BS";
                NCFSetup."Legal Tip %_DXR" := NCFSetup."Legal Tip %";
                NCFSetup.Modify(false);
            end;
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
        LSCPeriodicDiscount: Record "LSC Periodic Discount";
    begin
        // Fixed 2026-08-24: PeriodicDiscount.TableExt.al defines 8 Bellon field pairs; 7 of them
        // (source fields 50000-50006, "Item Offers"/"BackOffice ..." metrics) are FlowField pairs
        // with their _DXR replacements (52787-52793) - no stored value to migrate, and the old
        // RecordRef code's destinations (50011-50017) never existed in the schema either, so those
        // 7 were already guaranteed no-ops - dropped entirely here. The 8th pair, source field
        // 50010 Global (a real stored Boolean, not a FlowField), IS a genuine bug: its real active
        // target, confirmed via ObsoleteReason on field 50010 (52794 is not itself obsolete), is
        // "Global_DXR" (52794) - the old code instead wrote into the dead-but-real "Global_Old"
        // field (50018), which DOES exist in the schema (unlike the other 7 dead destinations), so
        // that copy was silently succeeding into the wrong field on every run.
        if LSCPeriodicDiscount.FindSet(true) then
            repeat
                if LSCPeriodicDiscount."Global_DXR" <> LSCPeriodicDiscount.Global then begin
                    LSCPeriodicDiscount."Global_DXR" := LSCPeriodicDiscount.Global;
                    LSCPeriodicDiscount.Modify(false);
                end;
            until LSCPeriodicDiscount.Next() = 0;
    end;

    // No-op by design (2026-08-24): PostedAssemblyHeader.TableExt.al defines exactly one Bellon
    // field pair here - source field 50000 "Importe Total Costo" and its replacement 52787 "Importe
    // Total Costo_DXR" - and BOTH are FlowFields (identical CalcFormula); there is no stored value
    // to migrate for a FlowField, matching the fact that the old code's RecordRef destination
    // (50001) never existed in the schema either. Nothing to open, nothing to copy.
    local procedure MigrateTableExt_PostedAssemblyHeaderFields()
    begin
    end;

    local procedure MigrateTableExt_LSCPostedStatementFields()
    var
        LSCPostedStatement: Record "LSC Posted Statement";
    begin
        // Fixed 2026-08-24: PostedStatement.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Listo para
        // Registrar_DXR" (52787) - not the dead "Listo para Registrar_Old" shadow field (50001) the
        // old RecordRef code wrote into.
        if LSCPostedStatement.FindSet(true) then
            repeat
                if LSCPostedStatement."Listo para Registrar_DXR" <> LSCPostedStatement."Listo para Registrar" then begin
                    LSCPostedStatement."Listo para Registrar_DXR" := LSCPostedStatement."Listo para Registrar";
                    LSCPostedStatement.Modify(false);
                end;
            until LSCPostedStatement.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCRetailProductGroupFields()
    var
        LSCRetailProductGroup: Record "LSC Retail Product Group";
    begin
        // Fixed 2026-08-24: ProductGroup.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on each source field (neither _DXR replacement is itself obsolete), are
        // "Block, Sand And Cement_DXR" (52787) and "Comision_Cobro_DXR." (52788, field name
        // includes a trailing period as declared in source) - not the dead "..._Old" shadow fields
        // (50002/50003) the old RecordRef code wrote into.
        if LSCRetailProductGroup.FindSet(true) then
            repeat
                if (LSCRetailProductGroup."Block, Sand And Cement_DXR" <> LSCRetailProductGroup."Block, Sand And Cement") or
                   (LSCRetailProductGroup."Comision_Cobro_DXR." <> LSCRetailProductGroup."Comision_Cobro")
                then begin
                    LSCRetailProductGroup."Block, Sand And Cement_DXR" := LSCRetailProductGroup."Block, Sand And Cement";
                    LSCRetailProductGroup."Comision_Cobro_DXR." := LSCRetailProductGroup."Comision_Cobro";
                    LSCRetailProductGroup.Modify(false);
                end;
            until LSCRetailProductGroup.Next() = 0;
    end;

    local procedure MigrateTableExt_PurchCommentLineFields()
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        // Fixed 2026-08-24: PurchCommentLine.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Comentario
        // Extendido_DXR" (52787) - not the dead "Comentario Extendido_Old" shadow field (50001) the
        // old RecordRef code wrote into.
        if PurchCommentLine.FindSet(true) then
            repeat
                if PurchCommentLine."Comentario Extendido_DXR" <> PurchCommentLine."Comentario Extendido" then begin
                    PurchCommentLine."Comentario Extendido_DXR" := PurchCommentLine."Comentario Extendido";
                    PurchCommentLine.Modify(false);
                end;
            until PurchCommentLine.Next() = 0;
    end;

    local procedure MigrateTableExt_PurchCommentLineArchiveFields()
    var
        PurchCommentLineArchive: Record "Purch. Comment Line Archive";
    begin
        // Fixed 2026-08-24: PurchCommentLineArchive.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Comentario
        // Extendido_DXR" (52787) - not the dead "Comentario Extendido_Old" shadow field (50001) the
        // old RecordRef code wrote into.
        if PurchCommentLineArchive.FindSet(true) then
            repeat
                if PurchCommentLineArchive."Comentario Extendido_DXR" <> PurchCommentLineArchive."Comentario Extendido" then begin
                    PurchCommentLineArchive."Comentario Extendido_DXR" := PurchCommentLineArchive."Comentario Extendido";
                    PurchCommentLineArchive.Modify(false);
                end;
            until PurchCommentLineArchive.Next() = 0;
    end;

    local procedure MigrateTableExt_PurchInvLineFields()
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        // Fixed 2026-08-24: PurchInvLine.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50017 (52787 is not itself obsolete), is "Liquidacion_DXR"
        // (52787) - not the dead "Liquidacion_Old" shadow field (50018) the old RecordRef code
        // wrote into.
        if PurchInvLine.FindSet(true) then
            repeat
                if PurchInvLine."Liquidacion_DXR" <> PurchInvLine.Liquidacion then begin
                    PurchInvLine."Liquidacion_DXR" := PurchInvLine.Liquidacion;
                    PurchInvLine.Modify(false);
                end;
            until PurchInvLine.Next() = 0;
    end;

    local procedure MigrateTableExt_ReasonCodeFields()
    var
        ReasonCode: Record "Reason Code";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "GroupTransport" into the dead "_Old"
        // shadow field (50001) - ReasonCodeTableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is the literal field
        // "GroupTransport_DXR." (field name includes a trailing period as declared in source).
        // Direct typed field closes that gap.
        if ReasonCode.FindSet(true) then
            repeat
                if ReasonCode."GroupTransport_DXR." <> ReasonCode.GroupTransport then begin
                    ReasonCode."GroupTransport_DXR." := ReasonCode.GroupTransport;
                    ReasonCode.Modify(false);
                end;
            until ReasonCode.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCReplenJournalLinesFields()
    var
        LSCReplenJournalLines: Record "LSC Replen. Journal Lines";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "Almacen Destino" into the dead
        // "_Old" shadow field (50032) - ReplenJournalLines.TableExt.al's real active target,
        // confirmed via ObsoleteReason on field 50016 (52787 is not itself obsolete), is
        // "Almacen Destino_DXR" (52787). The other legacy pair, field 50031 "AlmacenDestino Name"
        // -> 50033, is a FlowField on both the old and new side (CalcFormula = Lookup(Location.Name
        // WHERE(...)) against the respective "Almacen Destino"/"Almacen Destino_DXR" source field)
        // - there is no stored value to migrate for a FlowField, matching the fact that the old
        // code's destination (50033) never existed in the schema either.
        if LSCReplenJournalLines.FindSet(true) then
            repeat
                if LSCReplenJournalLines."Almacen Destino_DXR" <> LSCReplenJournalLines."Almacen Destino" then begin
                    LSCReplenJournalLines."Almacen Destino_DXR" := LSCReplenJournalLines."Almacen Destino";
                    LSCReplenJournalLines.Modify(false);
                end;
            until LSCReplenJournalLines.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCReplenTemplateFields()
    var
        LSCReplenTemplate: Record "LSC Replen. Template";
    begin
        // Fixed 2026-08-24: same shadow-field bug and same FlowField exemption as
        // MigrateTableExt_LSCReplenJournalLinesFields() above (ReplenTemplate.TableExt.al declares
        // the identical field pair shape). The old RecordRef version copied "Almacen Destino" into
        // the dead "_Old" shadow field (50032); the real active target, confirmed via
        // ObsoleteReason on field 50016 (52787 is not itself obsolete), is "Almacen Destino_DXR"
        // (52787). Field 50031 "AlmacenDestino Name" -> 50033 is a FlowField pair on both sides -
        // nothing stored to migrate.
        if LSCReplenTemplate.FindSet(true) then
            repeat
                if LSCReplenTemplate."Almacen Destino_DXR" <> LSCReplenTemplate."Almacen Destino" then begin
                    LSCReplenTemplate."Almacen Destino_DXR" := LSCReplenTemplate."Almacen Destino";
                    LSCReplenTemplate.Modify(false);
                end;
            until LSCReplenTemplate.Next() = 0;
    end;

    local procedure MigrateTableExt_LSCRetailSetupFields()
    var
        LSCRetailSetup: Record "LSC Retail Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied every one of these 24 fields into
        // dead "_Old" shadow fields (50027-50050) - RetailSetup.TableExt.al's real active targets,
        // confirmed via ObsoleteReason on each source field below (none of the _DXR destinations
        // are themselves obsolete), are 52787-52810 (fields 50005/50006 don't exist, and 50015
        // "Prices Global Offer" is itself ObsoleteState = Removed, so both are correctly absent
        // from this mapping, matching the original source's own field list). LSC Retail Setup is
        // a single-row table (blank primary key). "Terminos Devoluciones" (50018/52802) is a BLOB
        // field, so it needs CalcFields() before it can be read/copied, same as the old RecordRef
        // version's explicit CalcField() call. Direct typed fields close the shadow-field gap.
        //
        // Note (code review, Finding 2): the redundant-write guard below intentionally excludes
        // "Terminos Devoluciones_DXR"/"Terminos Devoluciones" - AL does not support a "<>"
        // comparison on BLOB fields. The BLOB is still copied unconditionally whenever any other
        // field in the guard differs, so it never goes stale in practice for this one-shot
        // upgrade-time migration; it just isn't itself part of the trigger condition.
        if LSCRetailSetup.Get() then begin
            LSCRetailSetup.CalcFields("Terminos Devoluciones");
            if (LSCRetailSetup."Withhold VAT Refund_DXR" <> LSCRetailSetup."Withhold VAT Refund") or
               (LSCRetailSetup."VAT Bus. Posting Group_DXR" <> LSCRetailSetup."VAT Bus. Posting Group") or
               (LSCRetailSetup."VAT Prod. Posting Group_DXR" <> LSCRetailSetup."VAT Prod. Posting Group") or
               (LSCRetailSetup."Days Limit_DXR" <> LSCRetailSetup."Days Limit") or
               (LSCRetailSetup."Sales Type_DXR" <> LSCRetailSetup."Sales Type") or
               (LSCRetailSetup."Validar Salida POS_DXR" <> LSCRetailSetup."Validar Salida POS") or
               (LSCRetailSetup."Bloq camb de lin MKP_DXR" <> LSCRetailSetup."Bloquear cambio de lineas MKP") or
               (LSCRetailSetup."Impr por Descripcion_DXR" <> LSCRetailSetup."Impresión por Descripción") or
               (LSCRetailSetup."Cod Barras en Copias_DXR" <> LSCRetailSetup."Codigo de Barras en Copias") or
               (LSCRetailSetup."No Valid Prec Cliente_DXR" <> LSCRetailSetup."No Validar Precios Cliente") or
               (LSCRetailSetup."Permitir Descuentos N/C_DXR" <> LSCRetailSetup."Permitir Descuentos N/C") or
               (LSCRetailSetup."Send Trans. Sales Entry_DXR" <> LSCRetailSetup."Send Trans. Sales Entry") or
               (LSCRetailSetup."Control SPO Cte Exon_DXR" <> LSCRetailSetup."Control SPO Cte. Exonerado") or
               (LSCRetailSetup."Cantidades Barcodes_DXR" <> LSCRetailSetup."Cantidades Barcodes") or
               (LSCRetailSetup."Env correo Ventas/Devol_DXR" <> LSCRetailSetup."Envio correo Ventas/Devolucion") or
               (LSCRetailSetup."Prefijo Pedidos POS TMP_DXR" <> LSCRetailSetup."Prefijo Pedidos POS TMP") or
               (LSCRetailSetup."Proveedor_DXR" <> LSCRetailSetup.Proveedor) or
               (LSCRetailSetup."USD Currency Code_DXR" <> LSCRetailSetup."USD Currency Code") or
               (LSCRetailSetup."Days to Reprint_DXR" <> LSCRetailSetup."Days to Reprint") or
               (LSCRetailSetup."Allow Days to Reprint_DXR" <> LSCRetailSetup."Allow Days to Reprint") or
               (LSCRetailSetup."Ruta Api Email_DXR" <> LSCRetailSetup."Ruta Api Email") or
               (LSCRetailSetup."FileServerName_DXR" <> LSCRetailSetup.FileServerName) or
               (LSCRetailSetup."NotAllowReprintReturn_DXR" <> LSCRetailSetup.NotAllowReprintReturn)
            then begin
                LSCRetailSetup."Withhold VAT Refund_DXR" := LSCRetailSetup."Withhold VAT Refund";
                LSCRetailSetup."VAT Bus. Posting Group_DXR" := LSCRetailSetup."VAT Bus. Posting Group";
                LSCRetailSetup."VAT Prod. Posting Group_DXR" := LSCRetailSetup."VAT Prod. Posting Group";
                LSCRetailSetup."Days Limit_DXR" := LSCRetailSetup."Days Limit";
                LSCRetailSetup."Sales Type_DXR" := LSCRetailSetup."Sales Type";
                LSCRetailSetup."Validar Salida POS_DXR" := LSCRetailSetup."Validar Salida POS";
                LSCRetailSetup."Bloq camb de lin MKP_DXR" := LSCRetailSetup."Bloquear cambio de lineas MKP";
                LSCRetailSetup."Impr por Descripcion_DXR" := LSCRetailSetup."Impresión por Descripción";
                LSCRetailSetup."Cod Barras en Copias_DXR" := LSCRetailSetup."Codigo de Barras en Copias";
                LSCRetailSetup."No Valid Prec Cliente_DXR" := LSCRetailSetup."No Validar Precios Cliente";
                LSCRetailSetup."Permitir Descuentos N/C_DXR" := LSCRetailSetup."Permitir Descuentos N/C";
                LSCRetailSetup."Send Trans. Sales Entry_DXR" := LSCRetailSetup."Send Trans. Sales Entry";
                LSCRetailSetup."Control SPO Cte Exon_DXR" := LSCRetailSetup."Control SPO Cte. Exonerado";
                LSCRetailSetup."Cantidades Barcodes_DXR" := LSCRetailSetup."Cantidades Barcodes";
                LSCRetailSetup."Env correo Ventas/Devol_DXR" := LSCRetailSetup."Envio correo Ventas/Devolucion";
                LSCRetailSetup."Prefijo Pedidos POS TMP_DXR" := LSCRetailSetup."Prefijo Pedidos POS TMP";
                LSCRetailSetup."Proveedor_DXR" := LSCRetailSetup.Proveedor;
                LSCRetailSetup."USD Currency Code_DXR" := LSCRetailSetup."USD Currency Code";
                LSCRetailSetup."Days to Reprint_DXR" := LSCRetailSetup."Days to Reprint";
                LSCRetailSetup."Allow Days to Reprint_DXR" := LSCRetailSetup."Allow Days to Reprint";
                LSCRetailSetup."Ruta Api Email_DXR" := LSCRetailSetup."Ruta Api Email";
                LSCRetailSetup."FileServerName_DXR" := LSCRetailSetup.FileServerName;
                LSCRetailSetup."NotAllowReprintReturn_DXR" := LSCRetailSetup.NotAllowReprintReturn;
                LSCRetailSetup."Terminos Devoluciones_DXR" := LSCRetailSetup."Terminos Devoluciones";
                LSCRetailSetup.Modify(false);
            end;
        end;
    end;

    local procedure MigrateTableExt_LSCRetailUserFields()
    var
        LSCRetailUser: Record "LSC Retail User";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied both fields into dead "_Old" shadow
        // fields (50002/50003) - RetailUser.TableExt.al's real active targets, confirmed via
        // ObsoleteReason on fields 50000/50001 (neither destination is itself obsolete), are the
        // literal fields "Almacen Despacho_DXR." (52787, trailing period as declared in source)
        // and "Filtrar Exist Ventas_DXR" (52788). Direct typed fields close that gap.
        if LSCRetailUser.FindSet(true) then
            repeat
                if (LSCRetailUser."Almacen Despacho_DXR." <> LSCRetailUser."Almacen Despacho") or
                   (LSCRetailUser."Filtrar Exist Ventas_DXR" <> LSCRetailUser."Filtrar Existencia Ventas")
                then begin
                    LSCRetailUser."Almacen Despacho_DXR." := LSCRetailUser."Almacen Despacho";
                    LSCRetailUser."Filtrar Exist Ventas_DXR" := LSCRetailUser."Filtrar Existencia Ventas";
                    LSCRetailUser.Modify(false);
                end;
            until LSCRetailUser.Next() = 0;
    end;

    local procedure MigrateTableExt_SalesPriceFields()
    var
        SalesPrice: Record "Sales Price";
    begin
        // Fixed 2026-08-24: the old RecordRef version targeted destination fields 50053-50057,
        // none of which are defined anywhere in SalesPrice.TableExt.al - CopyFieldIfExists
        // silently no-op'd on every row for all five pairs. Of the five source fields:
        //  - 50001 "Default Priority" and 50052 "Price Group Description" are FlowFields on both
        //    the old and new side (identical CalcFormula against "Customer Price Group") - there
        //    is no stored value to migrate for a FlowField, so those two pairs are intentionally
        //    omitted.
        //  - 50002 "Markup % Without TAX", 50003 "Markup % CP" and 50011 "Visible in Webshop" are
        //    stored fields. Their real active targets, confirmed via ObsoleteReason on each source
        //    field (none of the _DXR destinations are themselves obsolete), are
        //    "Markup % Without TAX_DXR" (52788), "Markup % CP_DXR" (52789) and
        //    "Visible in Webshop_DXR" (52790). Direct typed fields close that gap.
        if SalesPrice.FindSet(true) then
            repeat
                if (SalesPrice."Markup % Without TAX_DXR" <> SalesPrice."Markup % Without TAX") or
                   (SalesPrice."Markup % CP_DXR" <> SalesPrice."Markup % CP") or
                   (SalesPrice."Visible in Webshop_DXR" <> SalesPrice."Visible in Webshop")
                then begin
                    SalesPrice."Markup % Without TAX_DXR" := SalesPrice."Markup % Without TAX";
                    SalesPrice."Markup % CP_DXR" := SalesPrice."Markup % CP";
                    SalesPrice."Visible in Webshop_DXR" := SalesPrice."Visible in Webshop";
                    SalesPrice.Modify(false);
                end;
            until SalesPrice.Next() = 0;
    end;

    // No-op by design (2026-08-24): SalesPriceWorksheet.TableExt.al defines exactly one Bellon
    // field pair here - source field 50001 "Price Group Description" and its replacement 52787
    // "Price Group Description_DXR" - and BOTH are FlowFields (identical CalcFormula against
    // "Customer Price Group"); there is no stored value to migrate for a FlowField, matching the
    // fact that the old code's RecordRef destination (50002) never existed in the schema either
    // (CopyFieldIfExists was already a guaranteed no-op on every row). Nothing to open, nothing
    // to copy.
    local procedure MigrateTableExt_SalesPriceWorksheetFields()
    begin
    end;

    local procedure MigrateTableExt_SalesReceivablesSetupFields()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied both fields into dead "_Old" shadow
        // fields (50002/50003) - SalesReceivablesSetup.TableExt.al's real active targets,
        // confirmed via ObsoleteReason on fields 50000/50001 (neither destination is itself
        // obsolete), are "STD POS VAT Bus Pst Grp_DXR" (52787) and "STD POS Dflt Doc Copies_DXR"
        // (52788). Sales & Receivables Setup is a single-row table (blank primary key). Direct
        // typed fields close that gap.
        if SalesReceivablesSetup.Get() then
            if (SalesReceivablesSetup."STD POS VAT Bus Pst Grp_DXR" <> SalesReceivablesSetup."STD POS VAT Bus. Posting Group") or
               (SalesReceivablesSetup."STD POS Dflt Doc Copies_DXR" <> SalesReceivablesSetup."STD POS Default Doc. Copies")
            then begin
                SalesReceivablesSetup."STD POS VAT Bus Pst Grp_DXR" := SalesReceivablesSetup."STD POS VAT Bus. Posting Group";
                SalesReceivablesSetup."STD POS Dflt Doc Copies_DXR" := SalesReceivablesSetup."STD POS Default Doc. Copies";
                SalesReceivablesSetup.Modify(false);
            end;
    end;

    local procedure MigrateTableExt_LSCSalesTypeFields()
    var
        LSCSalesType: Record "LSC Sales Type";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied "Venta Ex. ITBIS" into the dead
        // "_Old" shadow field (50001) - SalesType.TableExt.al's real active target, confirmed via
        // ObsoleteReason on field 50000 (52787 is not itself obsolete), is "Venta Ex. ITBIS_DXR"
        // (52787). Direct typed field closes that gap.
        if LSCSalesType.FindSet(true) then
            repeat
                if LSCSalesType."Venta Ex. ITBIS_DXR" <> LSCSalesType."Venta Ex. ITBIS" then begin
                    LSCSalesType."Venta Ex. ITBIS_DXR" := LSCSalesType."Venta Ex. ITBIS";
                    LSCSalesType.Modify(false);
                end;
            until LSCSalesType.Next() = 0;
    end;

    local procedure MigrateTableExt_SalespersonPurchaserFields()
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // Fixed 2026-08-24: the old RecordRef version copied all three fields into dead "_Old"
        // shadow fields (50007-50009) - SalespersonPurchaser.TableExt.al's real active targets,
        // confirmed via ObsoleteReason on fields 50004-50006 (none of the _DXR destinations are
        // themselves obsolete), are "Gestor_CXP_DXR" (52787), "Comisiona_DXR" (52788) and
        // "Tipo Comision_DXR" (52789). Direct typed fields close that gap.
        if SalespersonPurchaser.FindSet(true) then
            repeat
                if (SalespersonPurchaser."Gestor_CXP_DXR" <> SalespersonPurchaser.Gestor_CXP) or
                   (SalespersonPurchaser."Comisiona_DXR" <> SalespersonPurchaser.Comisiona) or
                   (SalespersonPurchaser."Tipo Comision_DXR" <> SalespersonPurchaser."Tipo Comision")
                then begin
                    SalespersonPurchaser."Gestor_CXP_DXR" := SalespersonPurchaser.Gestor_CXP;
                    SalespersonPurchaser."Comisiona_DXR" := SalespersonPurchaser.Comisiona;
                    SalespersonPurchaser."Tipo Comision_DXR" := SalespersonPurchaser."Tipo Comision";
                    SalespersonPurchaser.Modify(false);
                end;
            until SalespersonPurchaser.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had two pairs, both copying into dead "_Old"
    // shadow fields - ShiptoAddress.TableExt.al's real active targets, confirmed via ObsoleteReason
    // on fields 50000/50001 (52787/52788 are not themselves obsolete), are "Latitud_DXR." (52787,
    // trailing period as declared in source) and "Longitud_DXR." (52788, trailing period as declared
    // in source). Direct typed fields close both gaps.
    local procedure MigrateTableExt_ShiptoAddressFields()
    var
        ShiptoAddress: Record "Ship-to Address";
    begin
        if ShiptoAddress.FindSet(true) then
            repeat
                if (ShiptoAddress."Latitud_DXR." <> ShiptoAddress.Latitud) or
                   (ShiptoAddress."Longitud_DXR." <> ShiptoAddress.Longitud)
                then begin
                    ShiptoAddress."Latitud_DXR." := ShiptoAddress.Latitud;
                    ShiptoAddress."Longitud_DXR." := ShiptoAddress.Longitud;
                    ShiptoAddress.Modify(false);
                end;
            until ShiptoAddress.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "Listo para Registrar" into the dead "_Old"
    // shadow field (50001) - Statement.TableExt.al's real active target, confirmed via ObsoleteReason
    // on field 50000 (52787 is not itself obsolete), is "Listo para Registrar_DXR" (52787). Direct
    // typed field closes that gap.
    local procedure MigrateTableExt_LSCStatementFields()
    var
        LSCStatement: Record "LSC Statement";
    begin
        if LSCStatement.FindSet(true) then
            repeat
                if LSCStatement."Listo para Registrar_DXR" <> LSCStatement."Listo para Registrar" then begin
                    LSCStatement."Listo para Registrar_DXR" := LSCStatement."Listo para Registrar";
                    LSCStatement.Modify(false);
                end;
            until LSCStatement.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had five pairs, all copying into dead "_Old"
    // shadow fields - Store.TableExt.al's real active targets, confirmed via ObsoleteReason on each
    // source field (none of the destinations below are themselves obsolete), are 52787-52791. Note
    // three of those targets are themselves named with a "_BE_DXR" suffix - a naming-convention
    // artifact specific to this table, not a further-obsolete intermediate like Customer/Item's
    // systemic two-hop chain (confirmed no ObsoleteState is set on any of 52787-52791). Direct typed
    // fields close all five gaps.
    local procedure MigrateTableExt_LSCSTOREFields()
    var
        LSCStore: Record "LSC STORE";
    begin
        if LSCStore.FindSet(true) then
            repeat
                if (LSCStore."Cod. Cliente Contado_BE_DXR" <> LSCStore."Cod. Cliente Contado") or
                   (LSCStore."No Serie 3er Party Item_DXR" <> LSCStore."No. Serie 3er. Party Item") or
                   (LSCStore."Address 3_BE_DXR" <> LSCStore."Address 3") or
                   (LSCStore."Utiliza NCF Unico_BE_DXR" <> LSCStore."Utiliza NCF Unico") or
                   (LSCStore."Print Header Doc._DXR." <> LSCStore."Print Header Doc.")
                then begin
                    LSCStore."Cod. Cliente Contado_BE_DXR" := LSCStore."Cod. Cliente Contado";
                    LSCStore."No Serie 3er Party Item_DXR" := LSCStore."No. Serie 3er. Party Item";
                    LSCStore."Address 3_BE_DXR" := LSCStore."Address 3";
                    LSCStore."Utiliza NCF Unico_BE_DXR" := LSCStore."Utiliza NCF Unico";
                    LSCStore."Print Header Doc._DXR." := LSCStore."Print Header Doc.";
                    LSCStore.Modify(false);
                end;
            until LSCStore.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had three pairs, all copying into dead "_Old"
    // shadow fields - TariffNumber.TableExt.al's real active targets, confirmed via ObsoleteReason on
    // each source field (52787-52789 are not themselves obsolete), are "% Arancel_DXR" (52787),
    // "ISC_DXR" (52788) and "% Selectivo_DXR" (52789). Direct typed fields close all three gaps.
    local procedure MigrateTableExt_TariffNumberFields()
    var
        TariffNumber: Record "Tariff Number";
    begin
        if TariffNumber.FindSet(true) then
            repeat
                if (TariffNumber."% Arancel_DXR" <> TariffNumber."% Arancel") or
                   (TariffNumber."ISC_DXR" <> TariffNumber.ISC) or
                   (TariffNumber."% Selectivo_DXR" <> TariffNumber."% Selectivo")
                then begin
                    TariffNumber."% Arancel_DXR" := TariffNumber."% Arancel";
                    TariffNumber."ISC_DXR" := TariffNumber.ISC;
                    TariffNumber."% Selectivo_DXR" := TariffNumber."% Selectivo";
                    TariffNumber.Modify(false);
                end;
            until TariffNumber.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "IsCreditMemo" into the dead "_Old" shadow
    // field (50008) - TenderType.TableExt.al's real active target, confirmed via ObsoleteReason on
    // field 50007 (52787 is not itself obsolete), is "IsCreditMemo_DXR" (52787). Direct typed field
    // closes that gap.
    local procedure MigrateTableExt_LSCTenderTypeFields()
    var
        LSCTenderType: Record "LSC Tender Type";
    begin
        if LSCTenderType.FindSet(true) then
            repeat
                if LSCTenderType."IsCreditMemo_DXR" <> LSCTenderType.IsCreditMemo then begin
                    LSCTenderType."IsCreditMemo_DXR" := LSCTenderType.IsCreditMemo;
                    LSCTenderType.Modify(false);
                end;
            until LSCTenderType.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "Autorizador" into the dead "_Old" shadow
    // field (50002) - TransSalesEntry.TableExt.al's real active target, confirmed via ObsoleteReason
    // on field 50000 (52787 is not itself obsolete), is "Autorizador_DXR" (52787). Direct typed field
    // closes that gap.
    local procedure MigrateTableExt_LSCTransSalesEntryFields()
    var
        LSCTransSalesEntry: Record "LSC Trans. Sales Entry";
    begin
        if LSCTransSalesEntry.FindSet(true) then
            repeat
                if LSCTransSalesEntry."Autorizador_DXR" <> LSCTransSalesEntry."Autorizador" then begin
                    LSCTransSalesEntry."Autorizador_DXR" := LSCTransSalesEntry."Autorizador";
                    LSCTransSalesEntry.Modify(false);
                end;
            until LSCTransSalesEntry.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had thirteen pairs, all copying into dead "_Old"
    // shadow fields - TransactionHeader.TableExt.al's real active targets, confirmed via
    // ObsoleteReason on each source field (none of 52787-52799 below are themselves obsolete), are
    // that same 52787-52799 block (in source-field declaration order, not a literal ID offset - some
    // targets keep a "_BE_DXR" suffix, a naming-convention artifact specific to this table, not a
    // further-obsolete intermediate). Direct typed fields close all thirteen gaps.
    local procedure MigrateTableExt_LSCTransactionHeaderFields()
    var
        LSCTransactionHeader: Record "LSC Transaction Header";
    begin
        if LSCTransactionHeader.FindSet(true) then
            repeat
                if (LSCTransactionHeader."No. Ticket_BE_DXR" <> LSCTransactionHeader."No. Ticket") or
                   (LSCTransactionHeader."Email Transaction_DXR" <> LSCTransactionHeader."Email Transaction") or
                   (LSCTransactionHeader."Fecha Expiracion NCF_BE_DXR" <> LSCTransactionHeader."Fecha Expiracion NCF") or
                   (LSCTransactionHeader."Tipo Identificacion_BE_DXR" <> LSCTransactionHeader."Tipo Identificacion") or
                   (LSCTransactionHeader."Sell-to Contact_DXR" <> LSCTransactionHeader."Sell-to Contact") or
                   (LSCTransactionHeader."Aplica Transportacion_DXR" <> LSCTransactionHeader."Aplica Transportacion") or
                   (LSCTransactionHeader."Addl Currency Code_DXR" <> LSCTransactionHeader."Additional Currency Code") or
                   (LSCTransactionHeader."Addl Currency Factor_DXR" <> LSCTransactionHeader."Additional Currency Factor") or
                   (LSCTransactionHeader."Print Header Doc_DXR" <> LSCTransactionHeader."Print Header Doc") or
                   (LSCTransactionHeader."Banco Central Cur Fctr_DXR" <> LSCTransactionHeader."Banco Central Currency Factor") or
                   (LSCTransactionHeader."Qty Tickets_DXR" <> LSCTransactionHeader."Qty Tickets") or
                   (LSCTransactionHeader."Promotion Tickets_DXR" <> LSCTransactionHeader."Promotion Tickets") or
                   (LSCTransactionHeader."Order No._DXR" <> LSCTransactionHeader."Order No.")
                then begin
                    LSCTransactionHeader."No. Ticket_BE_DXR" := LSCTransactionHeader."No. Ticket";
                    LSCTransactionHeader."Email Transaction_DXR" := LSCTransactionHeader."Email Transaction";
                    LSCTransactionHeader."Fecha Expiracion NCF_BE_DXR" := LSCTransactionHeader."Fecha Expiracion NCF";
                    LSCTransactionHeader."Tipo Identificacion_BE_DXR" := LSCTransactionHeader."Tipo Identificacion";
                    LSCTransactionHeader."Sell-to Contact_DXR" := LSCTransactionHeader."Sell-to Contact";
                    LSCTransactionHeader."Aplica Transportacion_DXR" := LSCTransactionHeader."Aplica Transportacion";
                    LSCTransactionHeader."Addl Currency Code_DXR" := LSCTransactionHeader."Additional Currency Code";
                    LSCTransactionHeader."Addl Currency Factor_DXR" := LSCTransactionHeader."Additional Currency Factor";
                    LSCTransactionHeader."Print Header Doc_DXR" := LSCTransactionHeader."Print Header Doc";
                    LSCTransactionHeader."Banco Central Cur Fctr_DXR" := LSCTransactionHeader."Banco Central Currency Factor";
                    LSCTransactionHeader."Qty Tickets_DXR" := LSCTransactionHeader."Qty Tickets";
                    LSCTransactionHeader."Promotion Tickets_DXR" := LSCTransactionHeader."Promotion Tickets";
                    LSCTransactionHeader."Order No._DXR" := LSCTransactionHeader."Order No.";
                    LSCTransactionHeader.Modify(false);
                end;
            until LSCTransactionHeader.Next() = 0;
    end;

    // No-op by design (2026-08-24): the old RecordRef version targeted field pairs 50009->50011
    // ("Tipo Request" -> "Tipo Request_Old") and 50010->50012 ("Transfer Status" -> "Transfer
    // Status_Old"). Per TransferHeader.TableExt.al, ALL FOUR of those fields (50009, 50010, 50011,
    // 50012), plus their once-planned final targets 52787 ("Tipo Request_DXR") and 52788 ("Transfer
    // Status_DXR"), are now ObsoleteState = Removed - a collision fix ("Bellon Migr. Phase 14
    // XCollFix", cod. 56131) relocated this exact field family to a fresh 58100-58108 band before
    // this removal took effect on publish, because the physical field IDs collided with Transfer
    // Shipment Header/Transfer Receipt Header's own tableextension fields via the shared
    // TRANSFERFIELDS-based Transfer Order-Post Shipment/Receipt copy. Both the old code's source and
    // destination field numbers are already fully gone from the compiled schema (RecordRef.FieldExist
    // would return false on all four), making this a guaranteed no-op today - and the real live data
    // (50008-50010) was already bridged to 58100-58102 by Phase 14 XCollFix ahead of the removal, so
    // there is nothing left for this Phase 2 procedure to safely migrate without duplicating/
    // conflicting with that already-executed bridge. Nothing to open, nothing to copy.
    local procedure MigrateTableExt_TransferHeaderFields()
    begin
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "Almacen Destino" into destination field
    // 50002, which never existed in TransferLine.TableExt.al's schema (already a guaranteed no-op) -
    // the actual real active target, confirmed via ObsoleteReason on field 50001 (52787 is not itself
    // obsolete), is "Almacen Destino_DXR" (52787). Direct typed field closes that gap.
    local procedure MigrateTableExt_TransferLineFields()
    var
        TransferLine: Record "Transfer Line";
    begin
        if TransferLine.FindSet(true) then
            repeat
                if TransferLine."Almacen Destino_DXR" <> TransferLine."Almacen Destino" then begin
                    TransferLine."Almacen Destino_DXR" := TransferLine."Almacen Destino";
                    TransferLine.Modify(false);
                end;
            until TransferLine.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had four pairs, all copying into dead "_Old"
    // shadow fields - TransferReceiptHeader.TableExt.al's real active targets, confirmed via
    // ObsoleteReason on each source field (52787-52790 are not themselves obsolete), are "Order User
    // ID_DXR." (52787, trailing period as declared in source), "Order Date Created_DXR." (52788,
    // trailing period as declared in source), "Receipt User ID_DXR." (52789, trailing period as
    // declared in source) and "Pre Receive Ref No_DXR" (52790). Direct typed fields close all four
    // gaps.
    local procedure MigrateTableExt_TransferReceiptHeaderFields()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
    begin
        if TransferReceiptHeader.FindSet(true) then
            repeat
                if (TransferReceiptHeader."Order User ID_DXR." <> TransferReceiptHeader."Order User Id") or
                   (TransferReceiptHeader."Order Date Created_DXR." <> TransferReceiptHeader."Order Date Created") or
                   (TransferReceiptHeader."Receipt User ID_DXR." <> TransferReceiptHeader."Receipt User ID") or
                   (TransferReceiptHeader."Pre Receive Ref No_DXR" <> TransferReceiptHeader."Pre Receive Reference No.")
                then begin
                    TransferReceiptHeader."Order User ID_DXR." := TransferReceiptHeader."Order User Id";
                    TransferReceiptHeader."Order Date Created_DXR." := TransferReceiptHeader."Order Date Created";
                    TransferReceiptHeader."Receipt User ID_DXR." := TransferReceiptHeader."Receipt User ID";
                    TransferReceiptHeader."Pre Receive Ref No_DXR" := TransferReceiptHeader."Pre Receive Reference No.";
                    TransferReceiptHeader.Modify(false);
                end;
            until TransferReceiptHeader.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had three pairs, all copying into dead "_Old"
    // shadow fields - TransferShipmentHeader.TableExt.al's real active targets, confirmed via
    // ObsoleteReason on each source field (52787-52789 are not themselves obsolete), are "Order User
    // ID_DXR." (52787, trailing period as declared in source), "Order Date Created_DXR." (52788,
    // trailing period as declared in source) and "Shipment User ID_DXR." (52789, trailing period as
    // declared in source). Direct typed fields close all three gaps.
    local procedure MigrateTableExt_TransferShipmentHeaderFields()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        if TransferShipmentHeader.FindSet(true) then
            repeat
                if (TransferShipmentHeader."Order User ID_DXR." <> TransferShipmentHeader."Order User Id") or
                   (TransferShipmentHeader."Order Date Created_DXR." <> TransferShipmentHeader."Order Date Created") or
                   (TransferShipmentHeader."Shipment User ID_DXR." <> TransferShipmentHeader."Shipment User ID")
                then begin
                    TransferShipmentHeader."Order User ID_DXR." := TransferShipmentHeader."Order User Id";
                    TransferShipmentHeader."Order Date Created_DXR." := TransferShipmentHeader."Order Date Created";
                    TransferShipmentHeader."Shipment User ID_DXR." := TransferShipmentHeader."Shipment User ID";
                    TransferShipmentHeader.Modify(false);
                end;
            until TransferShipmentHeader.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version had 22 pairs. 21 of them copied into dead "_Old"
    // shadow fields - UserSetup.TableExt.al's real active targets, confirmed via ObsoleteReason on
    // each source field (none of the destinations below are themselves obsolete), are the
    // 52787-52808 block (some keep a "_BE_DXR" suffix, a naming-convention artifact specific to this
    // table, not a further-obsolete intermediate). The 22nd pair, 50008 "Default Priority" -> 50032,
    // is correctly dropped: destination 50032 never existed in the schema either way (guaranteed
    // no-op already) - source field 50008 is a FlowField (Max(...)), and so is its real replacement
    // 52794 "Default Priority_DXR" (identical CalcFormula shape against the "_DXR." price group), so
    // there is no stored value to migrate for that pair. Direct typed fields close the other 21 gaps.
    local procedure MigrateTableExt_UserSetupFields()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.FindSet(true) then
            repeat
                if (UserSetup."Entrega Cheques_BE_DXR" <> UserSetup."Entrega Cheques") or
                   (UserSetup."Grupo Precios Tope_DXR." <> UserSetup."Grupo Precios Tope") or
                   (UserSetup."Ilimitado_DXR" <> UserSetup.Ilimitado) or
                   (UserSetup."Filtrar Por Vendedor_DXR" <> UserSetup."Filtrar Por Vendedor") or
                   (UserSetup."Create_Shipments_DXR" <> UserSetup."Create Shipments") or
                   (UserSetup."Invoice Shipments_DXR" <> UserSetup."Invoice Shipments") or
                   (UserSetup."User Hierarchy_DXR" <> UserSetup."User Hierarchy") or
                   (UserSetup."Filtrar Cartera Cte_DXR." <> UserSetup."Filtrar Cartera Cte") or
                   (UserSetup."Permit Tienda Dif a IF_DXR" <> UserSetup."Permitir Tienda Diferente a IF") or
                   (UserSetup."Tipo Segmento_DXR" <> UserSetup."Tipo Segmento") or
                   (UserSetup."Aprrove Int Consump_DXR" <> UserSetup."Aprrove Internal Consumption") or
                   (UserSetup."Create Int Consump_DXR" <> UserSetup."Create Internal Consumption") or
                   (UserSetup."Almacen Consumo Interno_DXR" <> UserSetup."Almacen Consumo Interno") or
                   (UserSetup."Departamento - Discr_DXR" <> UserSetup."Departamento - Discrepancia") or
                   (UserSetup."Crear Ajustes - Discr_DXR" <> UserSetup."Crear Ajustes - Discrepancia") or
                   (UserSetup."Post Int Consumption_DXR" <> UserSetup."Post Internal Consumption") or
                   (UserSetup."Excl Filtro DptoDiscr_DXR" <> UserSetup."Excluir Filtro Dpto. - Discrep") or
                   (UserSetup."Filtrar Usu Reimpresion_DXR" <> UserSetup."Filtrar Usuario Reimpresion") or
                   (UserSetup."Modify Int Consump_DXR" <> UserSetup."Modify Internal Consumption") or
                   (UserSetup."SendAppr  Int Consump_DXR" <> UserSetup."SendAppr  Internal Consumption") or
                   (UserSetup."Order to Retail Order_DXR" <> UserSetup."Order to Retail Order")
                then begin
                    UserSetup."Entrega Cheques_BE_DXR" := UserSetup."Entrega Cheques";
                    UserSetup."Grupo Precios Tope_DXR." := UserSetup."Grupo Precios Tope";
                    UserSetup."Ilimitado_DXR" := UserSetup.Ilimitado;
                    UserSetup."Filtrar Por Vendedor_DXR" := UserSetup."Filtrar Por Vendedor";
                    UserSetup."Create_Shipments_DXR" := UserSetup."Create Shipments";
                    UserSetup."Invoice Shipments_DXR" := UserSetup."Invoice Shipments";
                    UserSetup."User Hierarchy_DXR" := UserSetup."User Hierarchy";
                    UserSetup."Filtrar Cartera Cte_DXR." := UserSetup."Filtrar Cartera Cte";
                    UserSetup."Permit Tienda Dif a IF_DXR" := UserSetup."Permitir Tienda Diferente a IF";
                    UserSetup."Tipo Segmento_DXR" := UserSetup."Tipo Segmento";
                    UserSetup."Aprrove Int Consump_DXR" := UserSetup."Aprrove Internal Consumption";
                    UserSetup."Create Int Consump_DXR" := UserSetup."Create Internal Consumption";
                    UserSetup."Almacen Consumo Interno_DXR" := UserSetup."Almacen Consumo Interno";
                    UserSetup."Departamento - Discr_DXR" := UserSetup."Departamento - Discrepancia";
                    UserSetup."Crear Ajustes - Discr_DXR" := UserSetup."Crear Ajustes - Discrepancia";
                    UserSetup."Post Int Consumption_DXR" := UserSetup."Post Internal Consumption";
                    UserSetup."Excl Filtro DptoDiscr_DXR" := UserSetup."Excluir Filtro Dpto. - Discrep";
                    UserSetup."Filtrar Usu Reimpresion_DXR" := UserSetup."Filtrar Usuario Reimpresion";
                    UserSetup."Modify Int Consump_DXR" := UserSetup."Modify Internal Consumption";
                    UserSetup."SendAppr  Int Consump_DXR" := UserSetup."SendAppr  Internal Consumption";
                    UserSetup."Order to Retail Order_DXR" := UserSetup."Order to Retail Order";
                    UserSetup.Modify(false);
                end;
            until UserSetup.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "Correccion Int." into the dead "_Old"
    // shadow field (50003) - ValueEntry.TableExt.al's real active target, confirmed via
    // ObsoleteReason on field 50002 (52787 is not itself obsolete), is "Correccion Int._DXR" (52787).
    // Direct typed field closes that gap.
    local procedure MigrateTableExt_ValueEntryFields()
    var
        ValueEntry: Record "Value Entry";
    begin
        if ValueEntry.FindSet(true) then
            repeat
                if ValueEntry."Correccion Int._DXR" <> ValueEntry."Correccion Int." then begin
                    ValueEntry."Correccion Int._DXR" := ValueEntry."Correccion Int.";
                    ValueEntry.Modify(false);
                end;
            until ValueEntry.Next() = 0;
    end;

    // Fixed 2026-08-24 (master-data table, elevated shadow-field scrutiny): unlike Customer/Item
    // (Batch B1), Vendor does NOT have a systemic two-hop "_BE_DXR" bridge chain - confirmed by
    // reading BellonMigrPhase5CustItemDXR.Codeunit.al (cod. 56122) in full: it only bridges Customer
    // and Item, with no BridgeVendorOldGenFields counterpart. Verified instead directly against
    // Vendor.TableExt.al, field by field. The old RecordRef version blindly applied a flat "source ID
    // + 20" destination offset to all 20 pairs (50014-50033 -> 50034-50053); the real schema doesn't
    // follow that pattern: (a) 7 pairs (Teléfono 2/Vendedor/Vendedor email/Vendedor Celular/Apartado
    // Postal/Sector/FechaCreacion) land on a real but dead "_Old" shadow field at that offset - real
    // active targets, confirmed via ObsoleteReason on each source field (none of the destinations
    // below are themselves obsolete), are in the 52787-52806 block; (b) the other 13 pairs' offset
    // destination (50038-50052) never existed in the schema at all (guaranteed no-op already) - their
    // real active targets are in a separate 57113-57125 block. None of the 20 real targets below are
    // themselves obsolete. Direct typed fields close all 20 gaps.
    local procedure MigrateTableExt_VendorFields()
    var
        Vendor: Record Vendor;
    begin
        if Vendor.FindSet(true) then
            repeat
                if (Vendor."Teléfono 2_DXR" <> Vendor."BE Teléfono 2") or
                   (Vendor."Vendedor_DXR" <> Vendor."BE Vendedor") or
                   (Vendor."Vendedor Email_DXR." <> Vendor."BE Vendedor email") or
                   (Vendor."Vendedor Celular_DXR" <> Vendor."BE Vendedor Celular") or
                   (Vendor."Tipo Servicio_DXR" <> Vendor."BE Tipo Servicio") or
                   (Vendor."Clasificación ABC_DXR" <> Vendor."BE Clasificación ABC") or
                   (Vendor."Enc. Cobros Nombre_DXR" <> Vendor."BE Enc. Cobros Nombre") or
                   (Vendor."Enc. Cobros Email_DXR." <> Vendor."BE Enc. Cobros email") or
                   (Vendor."Enc. Cobros celular_DXR" <> Vendor."BE Enc. Cobros celular") or
                   (Vendor."Enc. Cobros Cumpleaños_DXR" <> Vendor."BE Enc. Cobros Cumpleaños") or
                   (Vendor."Frecuencia de Pago_DXR" <> Vendor."BE Frecuencia de Pago") or
                   (Vendor."Límite de Crédito_DXR" <> Vendor."BE Límite de Crédito") or
                   (Vendor."Apartado Postal_DXR" <> Vendor."BE Apartado Postal") or
                   (Vendor."Sector_DXR" <> Vendor."BE Sector") or
                   (Vendor."Municipio_DXR" <> Vendor."BE Municipio") or
                   (Vendor."Provincia_DXR" <> Vendor."BE Provincia") or
                   (Vendor."Despachador Email_DX.R" <> Vendor."BE Despachador Email") or
                   (Vendor."Proveedor Cilindros_DXR" <> Vendor."BE Proveedor Cilindros") or
                   (Vendor."Gestor_CXP_ID_DXR." <> Vendor."BE Gestor_CXP_ID") or
                   (Vendor."FechaCreacion_DXR" <> Vendor."BE FechaCreacion")
                then begin
                    Vendor."Teléfono 2_DXR" := Vendor."BE Teléfono 2";
                    Vendor."Vendedor_DXR" := Vendor."BE Vendedor";
                    Vendor."Vendedor Email_DXR." := Vendor."BE Vendedor email";
                    Vendor."Vendedor Celular_DXR" := Vendor."BE Vendedor Celular";
                    Vendor."Tipo Servicio_DXR" := Vendor."BE Tipo Servicio";
                    Vendor."Clasificación ABC_DXR" := Vendor."BE Clasificación ABC";
                    Vendor."Enc. Cobros Nombre_DXR" := Vendor."BE Enc. Cobros Nombre";
                    Vendor."Enc. Cobros Email_DXR." := Vendor."BE Enc. Cobros email";
                    Vendor."Enc. Cobros celular_DXR" := Vendor."BE Enc. Cobros celular";
                    Vendor."Enc. Cobros Cumpleaños_DXR" := Vendor."BE Enc. Cobros Cumpleaños";
                    Vendor."Frecuencia de Pago_DXR" := Vendor."BE Frecuencia de Pago";
                    Vendor."Límite de Crédito_DXR" := Vendor."BE Límite de Crédito";
                    Vendor."Apartado Postal_DXR" := Vendor."BE Apartado Postal";
                    Vendor."Sector_DXR" := Vendor."BE Sector";
                    Vendor."Municipio_DXR" := Vendor."BE Municipio";
                    Vendor."Provincia_DXR" := Vendor."BE Provincia";
                    Vendor."Despachador Email_DX.R" := Vendor."BE Despachador Email";
                    Vendor."Proveedor Cilindros_DXR" := Vendor."BE Proveedor Cilindros";
                    Vendor."Gestor_CXP_ID_DXR." := Vendor."BE Gestor_CXP_ID";
                    Vendor."FechaCreacion_DXR" := Vendor."BE FechaCreacion";
                    Vendor.Modify(false);
                end;
            until Vendor.Next() = 0;
    end;

    // Fixed 2026-08-24: the old RecordRef version copied "Almacen Destino" into the dead "_Old"
    // shadow field (50002) - WarehouseReceiptLine.TableExt.al's real active target, confirmed via
    // ObsoleteReason on field 50001 (52787 is not itself obsolete), is "Almacen Destino_DXR" (52787).
    // Direct typed field closes that gap.
    local procedure MigrateTableExt_WarehouseReceiptLineFields()
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        if WarehouseReceiptLine.FindSet(true) then
            repeat
                if WarehouseReceiptLine."Almacen Destino_DXR" <> WarehouseReceiptLine."Almacen Destino" then begin
                    WarehouseReceiptLine."Almacen Destino_DXR" := WarehouseReceiptLine."Almacen Destino";
                    WarehouseReceiptLine.Modify(false);
                end;
            until WarehouseReceiptLine.Next() = 0;
    end;
}
