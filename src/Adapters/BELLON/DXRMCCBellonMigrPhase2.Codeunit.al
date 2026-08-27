#if not ESCUDEA and not BCDX
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
    //
    // Fixed 2026-08-26 (batching + field-by-ID retrofit): MigrateTableExt_LSCPOSTransLineFields(),
    // MigrateTableExt_LSCPOSTransactionFields() and MigrateTableExt_PaymentMethodFields() were
    // still on the generic ID-based CopyFieldIfExists(RecRef, OldFieldNo, NewFieldNo) overload,
    // whose hardcoded destination IDs (50006-50010 range) do not exist anywhere in "LSC POS
    // Trans. Line"/"LSC POS Transaction"/"Payment Method"'s real schema (confirmed via
    // Dextra_Bellon Customization_28.3.4.20.app's SymbolReference.json - the exact dependency
    // symbol package this project compiles against), making every one of those calls a guaranteed
    // no-op; each source field's real active target, confirmed via that same schema's own
    // ObsoleteReason text (identical "the old field is Pending, replaced by X_DXR" shape as every
    // other procedure fixed 2026-08-24 above), is its "_DXR"-suffixed sibling. Converted to typed
    // Record with direct field access, matching this codeunit's established fix pattern - needs
    // the same RM grant as the other ~50 sibling tables above.
    //
    // Fixed 2026-08-27 (never-overwrite policy on the 10 typed MASTER-DATA field groups: Bank
    // Account, Currency, Customer, "Customer Price Group", Item, "Item Category", Location,
    // "Ship-to Address", "LSC STORE", Vendor - 118 field assignments in total). Those procedures
    // used to copy unconditionally:
    //     if (X_DXR <> X) then X_DXR := X;
    // which overwrites the destination EVEN WITH A BLANK SOURCE. That is a real data-loss path, not
    // a theoretical one: "DXR MCC Bellon Migr Phase5" (the port of "Bellon Migr. Phase 5 CustItem")
    // repopulates these SAME _DXR fields from the "_BE_DXR" intermediates using a never-overwrite
    // policy, and MigrateTableExt_ContactFields here already does the same through "DXR MCC Master
    // Field Resolver". On a tenant where the live value sits in _BE_DXR and the original 500xx field
    // is blank, running Phase 5 and then Phase 2 erased exactly what Phase 5 had just recovered -
    // and nothing in the code declared or enforced the safe ordering. Each assignment is now:
    //     if X_DXR = Blank.X_DXR then X_DXR := X;
    // where Blank is a Record variable of the same table that is never read from the database, so
    // every one of its fields sits at that field's declared default/InitValue. Comparing against it
    // is deliberately type-agnostic - it is correct for Text, Code, Decimal, Integer, Boolean, Date,
    // DateTime and Option alike, which hand-written "= ''"/"= 0"/"= false" tests are not (that exact
    // Boolean/Option blind spot exists in the resolver's own TestField-based HasValue). Net effect:
    // Phase 2 now only ever FILLS an empty destination, never replaces a value another phase or a
    // user already put there, which also makes the Phase 2 / Phase 5 execution order irrelevant.
    // NOT applied to the ~47 accounting/historic field groups in this same codeunit - they keep the
    // original unconditional copy; see the task notes for that pending follow-up.
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
        // Added 2026-08-27 (Critical, found auditing why the Master category never produced Contact
        // data): MigrateTableExt_ContactFields() does RecRef.Open(Database::"Contact") followed by
        // RecRef.Modify(false), but Contact had NO grant here at all - every other master table this
        // procedure family touches did (Customer, Item, Vendor, Location, "Ship-to Address", "Bank
        // Account", Currency, "Customer Price Group", "Item Category", "LSC STORE"). Since
        // permissionset 60000 "DXR MCC" grants only MCC's own tabledata plus codeunit Execute, a
        // per-object Permissions entry is the ONLY runtime write path in this codebase, so this
        // procedure could only ever fail with "Required permission ... Modify ... Contact" in the
        // background session - and, before the step isolation added below, that single failure
        // aborted the rest of RunMaster() with it.
        tabledata Contact = RM,
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
        tabledata "LSC POS Trans. Line" = RM,
        tabledata "LSC POS Transaction" = RM,
        tabledata "Payment Method" = RM,
        tabledata "LSC Posted Statement" = RM,
        tabledata "LSC Retail Product Group" = RM,
        // Added 2026-08-27, same gap as Contact above: MigrateTableExt_LSCRetailSetupFields()
        // declares Record "LSC Retail Setup" and calls CalcFields + Modify on it (including the
        // "Terminos Devoluciones" BLOB) from RunSetup(), with no grant.
        tabledata "LSC Retail Setup" = RM,
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

    // ===== Per-step isolation (added 2026-08-27) =====
    //
    // WHY: RunMaster()/RunAccounting() were a single flat sequence of ~30-50 calls running in ONE
    // transaction under ONE upgrade tag, set by the category dispatcher only after the very last
    // call returned (see "DXR MCC Bellon P2 Master"/"DXR MCC Bellon P2 Accounting" in
    // DXRMCCBellonCategoryDispatchers.Codeunit.al). That shape has three compounding failure modes,
    // all three confirmed against a real BELLON run that stopped on "Item HTML"/"Item Image View"
    // and consequently never migrated Contact, Customer, Item, Location, LSC STORE or Vendor at all:
    //   1) one failing table aborted every remaining table in the same category;
    //   2) the abort rolled back the tables that HAD already succeeded, because nothing committed
    //      between them;
    //   3) the dispatcher's tag was therefore never set, so the next run restarted from the first
    //      table and stopped in exactly the same place - the category could never move forward.
    // Removing the offending tables (done above) fixes today's symptom but not the shape, which is
    // why this exists: it makes any future bad table cost exactly one step instead of a category.
    //
    // HOW: each table is now its own step, run through Codeunit.Run and guarded by its own upgrade
    // tag. Per Learn ("Codeunit.Run(Integer [, var Record]) Method" - Transaction semantics): when
    // the Boolean return value is used, the callee's changes are committed at the end unless an
    // error occurs, and "If you're already in a transaction you must commit first before calling
    // Codeunit.Run" - hence the Commit() immediately before each step. A failing step is thus rolled
    // back ALONE, its tag stays unset, every other step still runs, and the next run retries only
    // what actually failed. Codeunit.Run rather than [TryFunction] is REQUIRED here: the steps
    // themselves commit internally (CheckpointCommit/FinishBatch) and Commit is illegal inside a
    // TryFunction.
    //
    // Failures are accumulated and re-raised once at the end of the category, so the run is still
    // reported as Failed in DXR MCC Run Log with the full list rather than silently swallowed.

    /// <summary>
    /// Executes exactly one named migration step. Public only so codeunit "DXR MCC Bellon P2 Step"
    /// can invoke it through Codeunit.Run; never call it directly - go through RunIsolatedStep so
    /// the step gets its commit boundary and its upgrade tag.
    /// </summary>
    internal procedure ExecuteStep(StepCode: Text)
    begin
        case StepCode of
            // --- Master: whole-table native restores ---
            'BANK':
                MigrateBankTable();
            'BANK-RELATION':
                MigrateBankRelationTable();
            'CILINDROS':
                MigrateCilindrosTable();
            'GRUPO-VENTA':
                MigrateGrupoVentaTable();
            'ITEMNO-DESLIQUIDACION':
                MigrateItemNoDesliquidacionTable();
            'ORDER-ITEM-STATUS':
                MigrateOrderItemStatusTable();
            'PROMOTION-TICKETS-REL':
                MigratePromotionTicketsRelationTable();
            'USERPROMO-APPS':
                MigrateUserPromoAppsTable();
            'AGR-EXTENDED-ITEM':
                MigrateAGRExtendedItemTable();
            'COMISION-GRUPO-VENDEDOR':
                MigrateComisionGrupoVendedorTable();
            // --- Master: tableextension field groups ---
            'TE-ASSEMBLY-SETUP':
                MigrateTableExt_AssemblySetupFields();
            'TE-BANK-ACCOUNT':
                MigrateTableExt_BankAccountFields();
            'TE-CONTACT':
                MigrateTableExt_ContactFields();
            'TE-CURRENCY':
                MigrateTableExt_CurrencyFields();
            'TE-CURRENCY-EXCH-RATE':
                MigrateTableExt_CurrencyExchangeRateFields();
            'TE-CUSTOMER':
                MigrateTableExt_CustomerFields();
            'TE-CUSTOMER-PRICE-GROUP':
                MigrateTableExt_CustomerPriceGroupFields();
            'TE-ITEM':
                MigrateTableExt_ItemFields();
            'TE-ITEM-CATEGORY':
                MigrateTableExt_ItemCategoryFields();
            'TE-ITEM-JNL-BATCH':
                MigrateTableExt_ItemJournalBatchFields();
            'TE-LSC-ITEM-SPECIAL-GROUPS':
                MigrateTableExt_LSCItemSpecialGroupsFields();
            'TE-LOCATION':
                MigrateTableExt_LocationFields();
            'TE-LSC-MEMBER-CONTACT':
                MigrateTableExt_LSCMemberContactFields();
            'TE-LSC-MEMBER-POINT-OFFER':
                MigrateTableExt_LSCMemberPointOfferFields();
            'TE-LSC-MEMBER-PT-OFFER-LINE':
                MigrateTableExt_LSCMemberPointOfferLineFields();
            'TE-LSC-PERIODIC-DISCOUNT':
                MigrateTableExt_LSCPeriodicDiscountFields();
            'TE-LSC-RETAIL-PRODUCT-GROUP':
                MigrateTableExt_LSCRetailProductGroupFields();
            'TE-SHIPTO-ADDRESS':
                MigrateTableExt_ShiptoAddressFields();
            'TE-LSC-STORE':
                MigrateTableExt_LSCSTOREFields();
            'TE-TARIFF-NUMBER':
                MigrateTableExt_TariffNumberFields();
            'TE-LSC-TENDER-TYPE':
                MigrateTableExt_LSCTenderTypeFields();
            // --- Accounting: whole-table native restores ---
            'ACC-BANCOS-EXTRACTO':
                MigrateBancosExtractoBancarioTable();
            'ACC-CARGA-MASIVA-BENEF-BPD':
                MigrateCargaMasivaBeneficiariosBPDTable();
            'ACC-CONVERSION-COSTO':
                MigrateConversionCostoTable();
            'ACC-DETALLE-EXTRACTO':
                MigrateDetalleExtractoBancarioTable();
            'ACC-ENTREGA-FACT-CXC-LINES':
                MigrateEntregaFacturasCxCLinesTable();
            'ACC-ENVIO-COMPRAS':
                MigrateEnvioComprasTable();
            'ACC-INT-CONSUMP-HEADER':
                MigrateInternalConsumptionHeaderTable();
            'ACC-INT-CONSUMP-LINE':
                MigrateInternalConsumptionLineTable();
            'ACC-JOURNAL-PROMO-TICKETS':
                MigrateJournalPromotionTicketsTable();
            'ACC-LIN-CARGA-MASIVA-BEN-BPD':
                MigrateLineasCargaMasivaBenBPDTable();
            'ACC-MOV-CILINDRO':
                MigrateMovimientosDeCilindroTable();
            'ACC-PRE-REQ-LINE-NO-STOCK-VAL':
                MigratePreReqLineNoStockValidTable();
            'ACC-PRE-REQ-NO-STOCK-VALID':
                MigratePreReqNoStockValidTable();
            'ACC-PRE-REQUISICION':
                MigratePreRequisicionTable();
            'ACC-PRE-REQUISICION-LINE':
                MigratePreRequisicionLineTable();
            'ACC-PRE-REQ-LINE-NO-STOCK':
                MigratePreRequisicionLineNoStockTable();
            'ACC-PRE-REQUISICION-NO-STOCK':
                MigratePreRequisicionNoStockTable();
            'ACC-REQUISICION':
                MigrateRequisicionTable();
            'ACC-REQUISICION-COMMENT-LINE':
                MigrateRequisicionCommentLineTable();
            'ACC-REQUISICION-LINE':
                MigrateRequisicionLineTable();
            'ACC-STORE-STATEMENT-POSTING':
                MigrateStoreStatementPostingTable();
            'ACC-TICKETS-BY-OFFER':
                MigrateTicketsByOfferTable();
            'ACC-TICKETS-ENTRY':
                MigrateTicketsEntryTable();
            'ACC-VALORACION-INVENTARIO':
                MigrateValoracionDeInventarioTable();
            // --- Accounting: tableextension field groups ---
            'TE-APPROVAL-ENTRY':
                MigrateTableExt_ApprovalEntryFields();
            'TE-ASSEMBLY-HEADER':
                MigrateTableExt_AssemblyHeaderFields();
            'TE-VENDOR-LEDGER-ENTRY':
                MigrateTableExt_VendorLedgerEntryFields();
            'TE-BANK-ACC-RECONCILIATION':
                MigrateTableExt_BankAccReconciliationFields();
            'TE-BANK-ACC-RECON-LINE':
                MigrateTableExt_BankAccReconciliationLineFields();
            'TE-BANK-ACCOUNT-LEDGER-ENTRY':
                MigrateTableExt_BankAccountLedgerEntryFields();
            'TE-CUST-LEDGER-ENTRY':
                MigrateTableExt_CustLedgerEntryFields();
            'TE-ISSUED-REMINDER-HEADER':
                MigrateTableExt_IssuedReminderHeaderFields();
            'TE-ISSUED-REMINDER-LINE':
                MigrateTableExt_IssuedReminderLineFields();
            'TE-ITEM-CHARGE-ASSGT-PURCH':
                MigrateTableExt_ItemChargeAssignmentPurchFields();
            'TE-ITEM-JOURNAL-LINE':
                MigrateTableExt_ItemJournalLineFields();
            'TE-ITEM-LEDGER-ENTRY':
                MigrateTableExt_ItemLedgerEntryFields();
            'TE-DX-CASH-JNL-RECEIPT-LIST':
                MigrateTableExt_DXCashJournalReceiptListFields();
            'TE-POSTED-ASSEMBLY-HEADER':
                MigrateTableExt_PostedAssemblyHeaderFields();
            'TE-LSC-POSTED-STATEMENT':
                MigrateTableExt_LSCPostedStatementFields();
            'TE-PURCH-COMMENT-LINE':
                MigrateTableExt_PurchCommentLineFields();
            'TE-PURCH-COMMENT-LINE-ARCH':
                MigrateTableExt_PurchCommentLineArchiveFields();
            'TE-PURCH-INV-LINE':
                MigrateTableExt_PurchInvLineFields();
            'TE-LSC-STATEMENT':
                MigrateTableExt_LSCStatementFields();
            'TE-LSC-TRANS-SALES-ENTRY':
                MigrateTableExt_LSCTransSalesEntryFields();
            'TE-LSC-TRANSACTION-HEADER':
                MigrateTableExt_LSCTransactionHeaderFields();
            'TE-TRANSFER-HEADER':
                MigrateTableExt_TransferHeaderFields();
            'TE-TRANSFER-LINE':
                MigrateTableExt_TransferLineFields();
            'TE-TRANSFER-RECEIPT-HEADER':
                MigrateTableExt_TransferReceiptHeaderFields();
            'TE-TRANSFER-SHIPMENT-HEADER':
                MigrateTableExt_TransferShipmentHeaderFields();
            'TE-USER-SETUP':
                MigrateTableExt_UserSetupFields();
            'TE-VALUE-ENTRY':
                MigrateTableExt_ValueEntryFields();
            'TE-VENDOR':
                MigrateTableExt_VendorFields();
            'TE-WAREHOUSE-RECEIPT-LINE':
                MigrateTableExt_WarehouseReceiptLineFields();
            // --- Setup / Historic / Other: named steps ---
            'SET-AGR-SETUP':
                MigrateAGRSetupTable();
            'SET-AJUSTE-INVENTARIO-CONFIG':
                MigrateAjusteInventarioConfigTable();
            'SET-AREA-DE-TRABAJO':
                MigrateAreaDeTrabajoTable();
            'SET-CATEGORIA-SERVICIOS':
                MigrateCategoriaServiciosTable();
            'SET-CILINDROS-SETUP':
                MigrateCilindrosSetupTable();
            'SET-CODIGOS-DE-AUDITORIA':
                MigrateCodigosDeAuditoriaTable();
            'SET-CONF-EXTRACTO-BANCARIO':
                MigrateConfExtractoBancarioTable();
            'SET-CONFIG-NCF-VENTAS':
                MigrateConfigNCFVentasTable();
            'SET-CONFIG-NCF-VENTAS-STD':
                MigrateConfigNCFVentasSTDTable();
            'SET-CONFIG-POLIZAS':
                MigrateConfigPolizasTable();
            'SET-CONFIGURACION-CB':
                MigrateConfiguracionCBTable();
            'SET-CONFIGURACION-DISCREPANCIAS':
                MigrateConfiguracionDiscrepanciasTable();
            'SET-CONFIGURACION-ENCUESTAS-POS':
                MigrateConfiguracionEncuestasPOSTable();
            'SET-CONFIGURACIONES-REQUISICION':
                MigrateConfiguracionesRequisicionTable();
            'SET-CONFIGURACION-MEDALLIA':
                MigrateConfiguracionMedalliaTable();
            'SET-CONF-PAGOS-ECOMMERCE-AZUL':
                MigrateConfPagosEcommerceAzulTable();
            'SET-CONTROL-PROCESOS-POR-ALMACEN':
                MigrateControlProcesosPorAlmacenTable();
            'SET-DRAW-SETUP':
                MigrateDrawSetupTable();
            'SET-EMAIL-SOURCE-TEMPLATE-RELATION':
                MigrateEmailSourceTemplateRelationTable();
            'SET-E-PAGOS-SETUP':
                MigrateEPagosSetupTable();
            'SET-EXCLUDE-FILTER-JOURNAL':
                MigrateExcludeFilterJournalTable();
            'SET-EXCLUIR-TERMINOS-ITEM-SEARCH':
                MigrateExcluirTerminosItemSearchTable();
            'SET-FILE-STRUCTURE':
                MigrateFileStructureTable();
            'SET-FORMA-DE-PAGO':
                MigrateFormaDePagoTable();
            'SET-BE-INVENTORY-MASKS':
                MigrateBEInventoryMasksTable();
            'SET-MARCAS':
                MigrateMarcasTable();
            'SET-MEMBER-MANAGEMENT-SETUP':
                MigrateMemberManagementSetupTable();
            'SET-MOTIVO-CIERRE-DISCREPANCIAS':
                MigrateMotivoCierreDiscrepanciasTable();
            'SET-MOTIVO-DISCREPANCIA':
                MigrateMotivoDiscrepanciaTable();
            'SET-PROFESION':
                MigrateProfesionTable();
            'SET-PROMOTION-SETUP':
                MigratePromotionSetupTable();
            'SET-PROVINCIA':
                MigrateProvinciaTable();
            'SET-SALES-DEPT':
                MigrateSalesDeptTable();
            'SET-SALES-GROUPS':
                MigrateSalesGroupsTable();
            'SET-SALES-SUB-GROUPS':
                MigrateSalesSubGroupsTable();
            'SET-STANDARD-POSDASCOM-PAYMT-EQV':
                MigrateStandardPOSDASCOMPaymtEqvTable();
            'SET-STANDARD-POS-GEN-COMMENTS':
                MigrateStandardPOSGenCommentsTable();
            'SET-STANDARD-POS-USERS':
                MigrateStandardPOSUsersTable();
            'SET-SUMMARY-RECONCILIATION-SETUP':
                MigrateSummaryReconciliationSetupTable();
            'SET-TASAS-BC':
                MigrateTasasBCTable();
            'SET-TIPO-DE-CONTENEDOR':
                MigrateTipoDeContenedorTable();
            'SET-TIPO-GAS':
                MigrateTipoGasTable();
            'SET-TIPOS-O-AGENTES':
                MigrateTiposOAgentesTable();
            'SET-TRATADOS-ARANCELARIOS':
                MigrateTratadosArancelariosTable();
            'SET-USER-APPROVER-BY-BUYER-GROUP':
                MigrateUserApproverByBuyerGroupTable();
            'SET-USER-BY-BUYER-GROUP':
                MigrateUserByBuyerGroupTable();
            'SET-VAT-BUS-SETTINGS':
                MigrateVATBusSettingsTable();
            'SET-OPERACIONES-TIPO-COMPROBANTE2':
                MigrateOperacionesTipoComprobante2Table();
            'TE-LSC-BARCODES':
                MigrateTableExt_LSCBarcodesFields();
            'TE-CHECK-LEDGER-ENTRY':
                MigrateTableExt_CheckLedgerEntryFields();
            'TE-COMPANY-INFORMATION':
                MigrateTableExt_CompanyInformationFields();
            'TE-COUNTRY-REGION':
                MigrateTableExt_CountryRegionFields();
            'TE-GEN-JOURNAL-BATCH':
                MigrateTableExt_GenJournalBatchFields();
            'TE-GEN-JOURNAL-LINE':
                MigrateTableExt_GenJournalLineFields();
            'TE-GEN-PRODUCT-POSTING-GROUP':
                MigrateTableExt_GenProductPostingGroupFields();
            'TE-GENERAL-LEDGER-SETUP':
                MigrateTableExt_GeneralLedgerSetupFields();
            'TE-DX-VENDOR-WITHHOLDING-LEDGER-ENTRY':
                MigrateTableExt_DXVendorWithholdingLedgerEntryFields();
            'TE-DXNCF-SETUP':
                MigrateTableExt_DXNCFSetupFields();
            'TE-REASON-CODE':
                MigrateTableExt_ReasonCodeFields();
            'TE-LSC-REPLEN-JOURNAL-LINES':
                MigrateTableExt_LSCReplenJournalLinesFields();
            'TE-LSC-REPLEN-TEMPLATE':
                MigrateTableExt_LSCReplenTemplateFields();
            'TE-LSC-RETAIL-SETUP':
                MigrateTableExt_LSCRetailSetupFields();
            'TE-LSC-RETAIL-USER':
                MigrateTableExt_LSCRetailUserFields();
            'TE-SALES-PRICE':
                MigrateTableExt_SalesPriceFields();
            'TE-SALES-PRICE-WORKSHEET':
                MigrateTableExt_SalesPriceWorksheetFields();
            'TE-SALES-RECEIVABLES-SETUP':
                MigrateTableExt_SalesReceivablesSetupFields();
            'TE-LSC-SALES-TYPE':
                MigrateTableExt_LSCSalesTypeFields();
            'TE-SALESPERSON-PURCHASER':
                MigrateTableExt_SalespersonPurchaserFields();
            'TE-LSCPOS-TRANS-LINE':
                MigrateTableExt_LSCPOSTransLineFields();
            'TE-LSCPOS-TRANSACTION':
                MigrateTableExt_LSCPOSTransactionFields();
            'TE-PAYMENT-METHOD':
                MigrateTableExt_PaymentMethodFields();
            else
                Error('Paso de migración desconocido en "DXR MCC Bellon Migr Phase2": %1.', StepCode);
        end;
    end;

    /// <summary>
    /// Runs one step in its own transaction. Never raises: a failed step is appended to FailedSteps
    /// and the caller keeps going, so no single table can take the rest of the category down with
    /// it. Already-tagged steps are skipped, which is what makes a re-run resume instead of restart.
    /// </summary>
    local procedure RunIsolatedStep(StepCode: Text; var FailedSteps: Text)
    var
        StepRunner: Codeunit "DXR MCC Bellon P2 Step";
        UpgradeTag: Codeunit "Upgrade Tag";
        StepTag: Code[250];
        FailureText: Text;
    begin
        StepTag := GetStepTag(StepCode);
        if UpgradeTag.HasUpgradeTag(StepTag) then
            exit;

        // Required by Codeunit.Run's documented transaction semantics, and it is also what turns the
        // previous step's work into a committed checkpoint that this step's failure cannot undo.
        Commit();

        StepRunner.SetStep(StepCode);
        if StepRunner.Run() then begin
            UpgradeTag.SetUpgradeTag(StepTag);
            Commit();
            exit;
        end;

        FailureText := GetLastErrorText();
        ClearLastError();
        if FailureText = '' then
            FailureText := 'error desconocido (sin texto)';
        if FailedSteps <> '' then
            FailedSteps += ' | ';
        FailedSteps += StrSubstNo('%1: %2', StepCode, FailureText);
    end;

    /// <summary>
    /// Table-pair counterpart of ExecuteStep, for the Historic/Other categories whose migrations are
    /// plain MigrateLegacyTableData(OldId, NewId) calls. Same "public only for the step runner"
    /// caveat - go through RunIsolatedTablePair.
    /// </summary>
    internal procedure ExecuteTablePair(OldTableId: Integer; NewTableId: Integer)
    begin
        MigrateLegacyTableData(OldTableId, NewTableId);
    end;

    /// <summary>
    /// Same isolation contract as RunIsolatedStep, keyed by the table pair instead of a step name so
    /// the ~34 generic legacy restores do not each need a branch in ExecuteStep.
    /// </summary>
    local procedure RunIsolatedTablePair(OldTableId: Integer; NewTableId: Integer; var FailedSteps: Text)
    var
        StepRunner: Codeunit "DXR MCC Bellon P2 Step";
        UpgradeTag: Codeunit "Upgrade Tag";
        StepTag: Code[250];
        FailureText: Text;
    begin
        StepTag := GetStepTag(StrSubstNo('TBL-%1-%2', OldTableId, NewTableId));
        if UpgradeTag.HasUpgradeTag(StepTag) then
            exit;

        Commit();

        StepRunner.SetTablePair(OldTableId, NewTableId);
        if StepRunner.Run() then begin
            UpgradeTag.SetUpgradeTag(StepTag);
            Commit();
            exit;
        end;

        FailureText := GetLastErrorText();
        ClearLastError();
        if FailureText = '' then
            FailureText := 'error desconocido (sin texto)';
        if FailedSteps <> '' then
            FailedSteps += ' | ';
        FailedSteps += StrSubstNo('tabla %1->%2: %3', OldTableId, NewTableId, FailureText);
    end;

    local procedure GetStepTag(StepCode: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('DXR-MCC-BELLON-P2-STEP-%1-20260827', StepCode), 1, 250));
    end;

    local procedure ThrowIfStepsFailed(CategoryName: Text; FailedSteps: Text)
    begin
        if FailedSteps = '' then
            exit;
        // Everything that succeeded is already committed and tagged; this only marks the run Failed
        // so the operator sees exactly which steps still owe work, and stops the category dispatcher
        // from setting its own "whole category done" tag.
        Error(
            'BELLON Phase 2 / %1: los pasos listados fallaron y NO quedaron migrados; todos los demás pasos sí se migraron y ya están confirmados. Vuelva a ejecutar esta categoría y sólo se reintentarán estos: %2',
            CategoryName, FailedSteps);
    end;

    procedure RunSetup()
    var
        FailedSteps: Text;
    begin
        RunIsolatedStep('SET-AGR-SETUP', FailedSteps); // AGR Setup -> DXR_AGR Setup (native - fixes NewRecRef.Open-inside-loop leak, see MigrateLegacyTableData)
        RunIsolatedStep('SET-AJUSTE-INVENTARIO-CONFIG', FailedSteps); // Ajuste Inventario Config -> DXR_Ajuste Inventario Config (native)
        RunIsolatedStep('SET-AREA-DE-TRABAJO', FailedSteps); // Area de Trabajo -> DXR_Area de Trabajo (native)
        RunIsolatedStep('SET-CATEGORIA-SERVICIOS', FailedSteps); // Categoria Servicios -> DXR_Categoria Servicios (native)
        RunIsolatedStep('SET-CILINDROS-SETUP', FailedSteps); // Cilindros - Setup -> DXR_Cilindros - Setup (native)
        RunIsolatedStep('SET-CODIGOS-DE-AUDITORIA', FailedSteps); // Codigos de Auditoria -> DXR_Codigos de Auditoria. (native)
        RunIsolatedStep('SET-CONF-EXTRACTO-BANCARIO', FailedSteps); // Conf. Extracto Bancario -> DXR_Conf. Extracto Bancario (native)
        RunIsolatedStep('SET-CONFIG-NCF-VENTAS', FailedSteps); // Config. NCF Ventas -> DXR_Config. NCF Ventas (native)
        RunIsolatedStep('SET-CONFIG-NCF-VENTAS-STD', FailedSteps); // Config. NCF Ventas STD -> DXR_Config. NCF Ventas STD (native)
        RunIsolatedStep('SET-CONFIG-POLIZAS', FailedSteps); // Config. Polizas -> DXR_Config. Polizas (native)
        RunIsolatedStep('SET-CONFIGURACION-CB', FailedSteps); // Configuracion CB -> DXR_Configuracion CB (native)
        RunIsolatedStep('SET-CONFIGURACION-DISCREPANCIAS', FailedSteps); // Configuracion - Discrepancias -> DXR_Config - Discr (native)
        RunIsolatedStep('SET-CONFIGURACION-ENCUESTAS-POS', FailedSteps); // Configuracion Encuestas - POS -> DXR_Config Encuestas - POS (native)
        RunIsolatedStep('SET-CONFIGURACIONES-REQUISICION', FailedSteps); // Configuraciones Requisicion -> DXR_Config Req (native)
        RunIsolatedStep('SET-CONFIGURACION-MEDALLIA', FailedSteps); // Configuracion - MEDALLIA -> DXR_Configuracion - MEDALLIA (native)
        RunIsolatedStep('SET-CONF-PAGOS-ECOMMERCE-AZUL', FailedSteps); // Conf. Pagos Ecommerce Azul -> DXR_Conf. Pagos Ecommerce Azul (native)
        RunIsolatedStep('SET-CONTROL-PROCESOS-POR-ALMACEN', FailedSteps); // Control Procesos por Almacen -> DXR_Control Proc por Almacen (native)
        RunIsolatedStep('SET-DRAW-SETUP', FailedSteps); // Draw Setup -> DXR_Draw Setup (native)
        RunIsolatedStep('SET-EMAIL-SOURCE-TEMPLATE-RELATION', FailedSteps); // Email Source Template Relation -> DXR_Email Source Tmpl Rel (native)
        RunIsolatedStep('SET-E-PAGOS-SETUP', FailedSteps); // EPagos Setup -> DXR_EPagos Setup (native)
        RunIsolatedStep('SET-EXCLUDE-FILTER-JOURNAL', FailedSteps); // Exclude Filter Journal -> DXR_Exclude Filter Journal (native)
        RunIsolatedStep('SET-EXCLUIR-TERMINOS-ITEM-SEARCH', FailedSteps); // Excluir Terminos  - ItemSearch -> DXR_Excluir Term - ItemSearch (native)
        RunIsolatedStep('SET-FILE-STRUCTURE', FailedSteps); // File Structure -> DXR_File Structure (native)
        RunIsolatedStep('SET-FORMA-DE-PAGO', FailedSteps); // Forma de Pago -> DXR_Forma de Pago (native)
        RunIsolatedStep('SET-BE-INVENTORY-MASKS', FailedSteps); // BE Inventory Masks -> DXR_Inventory Masks (native)
        RunIsolatedStep('SET-MARCAS', FailedSteps); // Marcas -> DXR_Marcas (native)
        RunIsolatedStep('SET-MEMBER-MANAGEMENT-SETUP', FailedSteps); // Member Management Setup -> DXR_Member Management Setup (native)
        RunIsolatedStep('SET-MOTIVO-CIERRE-DISCREPANCIAS', FailedSteps); // Motivo Cierre - Discrepancias -> DXR_Motivo Cierre - Discr (native)
        RunIsolatedStep('SET-MOTIVO-DISCREPANCIA', FailedSteps); // Motivo Discrepancia -> DXR_Motivo Discrepancia (native)
        RunIsolatedStep('SET-PROFESION', FailedSteps); // Profesion -> DXR_Profesion (native)
        RunIsolatedStep('SET-PROMOTION-SETUP', FailedSteps); // Promotion Setup -> DXR_Promotion Setup (native)
        RunIsolatedStep('SET-PROVINCIA', FailedSteps); // Provincia -> DXR_Provincia (native)
        RunIsolatedStep('SET-SALES-DEPT', FailedSteps); // Sales Dept -> DXR_Sales Dept (native)
        RunIsolatedStep('SET-SALES-GROUPS', FailedSteps); // Sales Groups -> DXR_Sales Groups (native)
        RunIsolatedStep('SET-SALES-SUB-GROUPS', FailedSteps); // Sales SubGroups -> DXR_Sales SubGroups (native)
        RunIsolatedStep('SET-STANDARD-POSDASCOM-PAYMT-EQV', FailedSteps); // Standard POS DASCOM Paymt Eqv -> DXR_Std POS DASCOM Paymt Eqv (native)
        RunIsolatedStep('SET-STANDARD-POS-GEN-COMMENTS', FailedSteps); // Standard POS Gen. Comments -> DXR_Standard POS Gen. Comments (native)
        RunIsolatedStep('SET-STANDARD-POS-USERS', FailedSteps); // Standard POS Users -> DXR_Standard POS Users (native)
        RunIsolatedStep('SET-SUMMARY-RECONCILIATION-SETUP', FailedSteps); // Summary Reconciliation Setup -> DXR_Summary Recon Setup (native)
        RunIsolatedStep('SET-TASAS-BC', FailedSteps); // Tasas BC -> DXR_Tasas BC (native)
        RunIsolatedStep('SET-TIPO-DE-CONTENEDOR', FailedSteps); // Tipo de Contenedor -> DXR_Tipo de Contenedor (native)
        RunIsolatedStep('SET-TIPO-GAS', FailedSteps); // Tipo Gas -> DXR_Tipo Gas (native)
        RunIsolatedStep('SET-TIPOS-O-AGENTES', FailedSteps); // Tipos o Agentes -> DXR_Tipos o Agentes (native)
        RunIsolatedStep('SET-TRATADOS-ARANCELARIOS', FailedSteps); // Tratados Arancelarios -> DXR_Tratados Arancelarios (native)
        RunIsolatedStep('SET-USER-APPROVER-BY-BUYER-GROUP', FailedSteps); // UserApproverByBuyerGroup -> DXR_UserApproverByBuyerGroup (native)
        RunIsolatedStep('SET-USER-BY-BUYER-GROUP', FailedSteps); // UserByBuyerGroup -> DXR_UserByBuyerGroup (native)
        RunIsolatedStep('SET-VAT-BUS-SETTINGS', FailedSteps); // VAT Bus. Settings -> DXR_VAT Bus. Settings (native)
        RunIsolatedStep('SET-OPERACIONES-TIPO-COMPROBANTE2', FailedSteps); // Operaciones Tipo Comprobante2 -> DXR_Operaciones Tipo Comprob2 (native)
        RunIsolatedStep('TE-LSC-BARCODES', FailedSteps);
        RunIsolatedStep('TE-CHECK-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-COMPANY-INFORMATION', FailedSteps);
        RunIsolatedStep('TE-COUNTRY-REGION', FailedSteps);
        RunIsolatedStep('TE-GEN-JOURNAL-BATCH', FailedSteps);
        RunIsolatedStep('TE-GEN-JOURNAL-LINE', FailedSteps);
        RunIsolatedStep('TE-GEN-PRODUCT-POSTING-GROUP', FailedSteps);
        RunIsolatedStep('TE-GENERAL-LEDGER-SETUP', FailedSteps);
        RunIsolatedStep('TE-DX-VENDOR-WITHHOLDING-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-DXNCF-SETUP', FailedSteps);
        RunIsolatedStep('TE-REASON-CODE', FailedSteps);
        RunIsolatedStep('TE-LSC-REPLEN-JOURNAL-LINES', FailedSteps);
        RunIsolatedStep('TE-LSC-REPLEN-TEMPLATE', FailedSteps);
        RunIsolatedStep('TE-LSC-RETAIL-SETUP', FailedSteps);
        RunIsolatedStep('TE-LSC-RETAIL-USER', FailedSteps);
        RunIsolatedStep('TE-SALES-PRICE', FailedSteps);
        RunIsolatedStep('TE-SALES-PRICE-WORKSHEET', FailedSteps);
        RunIsolatedStep('TE-SALES-RECEIVABLES-SETUP', FailedSteps);
        RunIsolatedStep('TE-LSC-SALES-TYPE', FailedSteps);
        RunIsolatedStep('TE-SALESPERSON-PURCHASER', FailedSteps);
        ThrowIfStepsFailed('Setup', FailedSteps);
    end;

    procedure RunMaster()
    var
        FailedSteps: Text;
    begin
        RunIsolatedStep('BANK', FailedSteps); // Bank -> DXR_Bank (native)
        RunIsolatedStep('BANK-RELATION', FailedSteps); // Bank Relation -> DXR_Bank Relation (native)
        RunIsolatedStep('CILINDROS', FailedSteps); // Cilindros -> DXR_Cilindros (native)
        RunIsolatedStep('GRUPO-VENTA', FailedSteps); // Grupo Venta -> DXR_Grupo Venta (native)
        // Removed 2026-08-27 (Master category stall, root cause): "Item HTML" and "Item Image View"
        // used to run here, between Grupo Venta and ItemNo Desliquidacion, and they are where a real
        // BELLON run stopped - so NOTHING below them in this procedure (Contact, Customer, Item,
        // Location, LSC STORE, Ship-to Address, Tariff Number, LSC Tender Type...) ever executed.
        //   * MigrateItemImageViewTable(): "Item Image View" (50099) AND "DXR_Item Image View"
        //     (53360) both declare LinkedObject = true in Bellon Customization's own source
        //     (Dextra_Bellon Customization_28.3.4.20.app, Base\Tables.old\ItemImageView.Table.al and
        //     Base\Tables\ItemImageView.Table.al). A LinkedObject table is a link to a SQL Server
        //     object, not BC-managed storage, and per Learn ("LinkedInTransaction Property") such
        //     access "is not under Business Central transaction control". Source and destination
        //     therefore resolve to the SAME external view: there is no tenant row to move, and the
        //     Insert is issued against a SQL view. Migrating it is not slow, it is meaningless.
        //   * MigrateItemHTMLTable(): "Item HTML" carries three BLOB fields (Html, "Descripcion
        //     Extendida", Caracteristicas) copied per row via CalcFields + CopyStream, and this
        //     whole procedure holds ONE uncommitted transaction, so the cost grew without bound.
        //     Omitted by explicit decision - this content is presentation data, not master data.
        // Both concepts are also Retired in DXR MCC Registry Loader (BELLON-P2 seq 74/75) so MCC's
        // generic fallback stops re-attempting them on every run - the exact remediation already
        // applied to DESB-P1 seq 29 for the same "looked like a frozen phase" symptom.
        // MigrateItemNoDesliquidacionTable() below is NOT one of these: plain scalar table, kept.
        RunIsolatedStep('ITEMNO-DESLIQUIDACION', FailedSteps); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion (native)
        RunIsolatedStep('ORDER-ITEM-STATUS', FailedSteps); // Order Item Status -> DXR_Order Item Status (native)
        RunIsolatedStep('PROMOTION-TICKETS-REL', FailedSteps); // Promotion Tickets Relation -> DXR_Promotion Tickets Relation (native)
        RunIsolatedStep('USERPROMO-APPS', FailedSteps); // UserPromo Apps -> DXR_UserPromo Apps (native)
        RunIsolatedStep('AGR-EXTENDED-ITEM', FailedSteps); // AGR Extended Item -> DXR_AGR Extended Item (native)
        RunIsolatedStep('COMISION-GRUPO-VENDEDOR', FailedSteps); // Comision_Grupo_Vendedor -> DXR_Comision_Grupo_Vendedor (native)
        // Removed 2026-08-27: same LinkedObject reason as "Item Image View" above. "Inventory View"
        // (50097) and "DXR_Inventory View." (55004) BOTH declare LinkedObject = true (verified in
        // Dextra_Bellon Customization_28.3.4.20.app: Base\Tables.old\InventoryView.Table.al,
        // Base\Tables\InventoryView.Table.al) - a SQL Server view computed from live inventory, not
        // BC storage. There is nothing to copy, and the old call sat directly in front of the whole
        // master-data tableextension block below. Concept BELLON-P2 seq 133 retired to match.
        // MigrateInventoryViewTable(); // Inventory View -> DXR_Inventory View. (native)
        RunIsolatedStep('TE-ASSEMBLY-SETUP', FailedSteps);
        RunIsolatedStep('TE-BANK-ACCOUNT', FailedSteps);
        RunIsolatedStep('TE-CONTACT', FailedSteps);
        RunIsolatedStep('TE-CURRENCY', FailedSteps);
        RunIsolatedStep('TE-CURRENCY-EXCH-RATE', FailedSteps);
        RunIsolatedStep('TE-CUSTOMER', FailedSteps);
        RunIsolatedStep('TE-CUSTOMER-PRICE-GROUP', FailedSteps);
        RunIsolatedStep('TE-ITEM', FailedSteps);
        RunIsolatedStep('TE-ITEM-CATEGORY', FailedSteps);
        RunIsolatedStep('TE-ITEM-JNL-BATCH', FailedSteps);
        RunIsolatedStep('TE-LSC-ITEM-SPECIAL-GROUPS', FailedSteps);
        RunIsolatedStep('TE-LOCATION', FailedSteps);
        RunIsolatedStep('TE-LSC-MEMBER-CONTACT', FailedSteps);
        RunIsolatedStep('TE-LSC-MEMBER-POINT-OFFER', FailedSteps);
        RunIsolatedStep('TE-LSC-MEMBER-PT-OFFER-LINE', FailedSteps);
        RunIsolatedStep('TE-LSC-PERIODIC-DISCOUNT', FailedSteps);
        RunIsolatedStep('TE-LSC-RETAIL-PRODUCT-GROUP', FailedSteps);
        RunIsolatedStep('TE-SHIPTO-ADDRESS', FailedSteps);
        RunIsolatedStep('TE-LSC-STORE', FailedSteps);
        RunIsolatedStep('TE-TARIFF-NUMBER', FailedSteps);
        RunIsolatedStep('TE-LSC-TENDER-TYPE', FailedSteps);
        ThrowIfStepsFailed('Master', FailedSteps);
    end;

    procedure RunAccounting()
    var
        FailedSteps: Text;
    begin
        RunIsolatedStep('ACC-BANCOS-EXTRACTO', FailedSteps);
        RunIsolatedStep('ACC-CARGA-MASIVA-BENEF-BPD', FailedSteps);
        RunIsolatedStep('ACC-CONVERSION-COSTO', FailedSteps);
        RunIsolatedStep('ACC-DETALLE-EXTRACTO', FailedSteps);
        RunIsolatedStep('ACC-ENTREGA-FACT-CXC-LINES', FailedSteps);
        RunIsolatedStep('ACC-ENVIO-COMPRAS', FailedSteps);
        RunIsolatedStep('ACC-INT-CONSUMP-HEADER', FailedSteps);
        RunIsolatedStep('ACC-INT-CONSUMP-LINE', FailedSteps);
        RunIsolatedStep('ACC-JOURNAL-PROMO-TICKETS', FailedSteps);
        RunIsolatedStep('ACC-LIN-CARGA-MASIVA-BEN-BPD', FailedSteps);
        RunIsolatedStep('ACC-MOV-CILINDRO', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQ-LINE-NO-STOCK-VAL', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQ-NO-STOCK-VALID', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQUISICION', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQUISICION-LINE', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQ-LINE-NO-STOCK', FailedSteps);
        RunIsolatedStep('ACC-PRE-REQUISICION-NO-STOCK', FailedSteps);
        RunIsolatedStep('ACC-REQUISICION', FailedSteps);
        RunIsolatedStep('ACC-REQUISICION-COMMENT-LINE', FailedSteps);
        RunIsolatedStep('ACC-REQUISICION-LINE', FailedSteps);
        RunIsolatedStep('ACC-STORE-STATEMENT-POSTING', FailedSteps);
        RunIsolatedStep('ACC-TICKETS-BY-OFFER', FailedSteps);
        RunIsolatedStep('ACC-TICKETS-ENTRY', FailedSteps);
        RunIsolatedStep('ACC-VALORACION-INVENTARIO', FailedSteps);
        RunIsolatedStep('TE-APPROVAL-ENTRY', FailedSteps);
        RunIsolatedStep('TE-ASSEMBLY-HEADER', FailedSteps);
        RunIsolatedStep('TE-VENDOR-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-BANK-ACC-RECONCILIATION', FailedSteps);
        RunIsolatedStep('TE-BANK-ACC-RECON-LINE', FailedSteps);
        RunIsolatedStep('TE-BANK-ACCOUNT-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-CUST-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-ISSUED-REMINDER-HEADER', FailedSteps);
        RunIsolatedStep('TE-ISSUED-REMINDER-LINE', FailedSteps);
        RunIsolatedStep('TE-ITEM-CHARGE-ASSGT-PURCH', FailedSteps);
        RunIsolatedStep('TE-ITEM-JOURNAL-LINE', FailedSteps);
        RunIsolatedStep('TE-ITEM-LEDGER-ENTRY', FailedSteps);
        RunIsolatedStep('TE-DX-CASH-JNL-RECEIPT-LIST', FailedSteps);
        RunIsolatedStep('TE-POSTED-ASSEMBLY-HEADER', FailedSteps);
        RunIsolatedStep('TE-LSC-POSTED-STATEMENT', FailedSteps);
        RunIsolatedStep('TE-PURCH-COMMENT-LINE', FailedSteps);
        RunIsolatedStep('TE-PURCH-COMMENT-LINE-ARCH', FailedSteps);
        RunIsolatedStep('TE-PURCH-INV-LINE', FailedSteps);
        RunIsolatedStep('TE-LSC-STATEMENT', FailedSteps);
        RunIsolatedStep('TE-LSC-TRANS-SALES-ENTRY', FailedSteps);
        RunIsolatedStep('TE-LSC-TRANSACTION-HEADER', FailedSteps);
        RunIsolatedStep('TE-TRANSFER-HEADER', FailedSteps);
        RunIsolatedStep('TE-TRANSFER-LINE', FailedSteps);
        RunIsolatedStep('TE-TRANSFER-RECEIPT-HEADER', FailedSteps);
        RunIsolatedStep('TE-TRANSFER-SHIPMENT-HEADER', FailedSteps);
        RunIsolatedStep('TE-USER-SETUP', FailedSteps);
        RunIsolatedStep('TE-VALUE-ENTRY', FailedSteps);
        RunIsolatedStep('TE-VENDOR', FailedSteps);
        RunIsolatedStep('TE-WAREHOUSE-RECEIPT-LINE', FailedSteps);
        ThrowIfStepsFailed('Accounting', FailedSteps);
    end;

    procedure RunHistoric()
    var
        FailedSteps: Text;
    begin
        RunIsolatedTablePair(50004, 53302, FailedSteps); // AGR Log -> DXR_AGR Log
        RunIsolatedTablePair(50071, 53341, FailedSteps); // HisCargaMasivaBeneficiariosBPD -> DXR_HisCargaMasivaBenefBPD
        RunIsolatedTablePair(50073, 53343, FailedSteps); // HisLineasCargaMasivaBenefBPD -> DXR_HisLinCargaMasivaBenefBPD
        RunIsolatedTablePair(50074, 53344, FailedSteps); // Hist. Beneficiarios BPD -> DXR_Hist. Beneficiarios BPD
        RunIsolatedTablePair(50075, 53345, FailedSteps); // Hist. Cabecera Discrepancia -> DXR_Hist. Cabecera Discr
        RunIsolatedTablePair(50076, 53346, FailedSteps); // Hist. de Ganadores -> DXR_Hist. de Ganadores
        RunIsolatedTablePair(50077, 53347, FailedSteps); // Hist. Internal Consump. Header -> DXR_Hist. Int Consump. Header
        RunIsolatedTablePair(50078, 53348, FailedSteps); // Hist. Internal Consump. Line -> DXR_Hist. Int Consump. Line
        RunIsolatedTablePair(50079, 53349, FailedSteps); // Hist. Linea Discrepancia -> DXR_Hist. Linea Discrepancia
        RunIsolatedTablePair(50081, 53350, FailedSteps); // Historico Enc Requisicion -> DXR_Historico Enc Requisicion
        RunIsolatedTablePair(50082, 53351, FailedSteps); // Historico - Extracto Bancario -> DXR_Historico - Extr Bancario
        RunIsolatedTablePair(50084, 53352, FailedSteps); // Historico Requisicion Line -> DXR_Historico Requisicion Line
        RunIsolatedTablePair(50085, 53353, FailedSteps); // Hist Pre-Requisicion -> DXR_Hist Pre-Requisicion
        RunIsolatedTablePair(50086, 53354, FailedSteps); // Hist Pre-Requisicion Line -> DXR_Hist Pre-Requisicion Line
        RunIsolatedTablePair(50095, 53357, FailedSteps); // Internal Consumption Log -> DXR_Internal Consumption Log
        RunIsolatedTablePair(50111, 53366, FailedSteps); // Log - Bank Statement -> DXR_Log - Bank Statement
        RunIsolatedTablePair(50112, 53367, FailedSteps); // Log Email -> DXR_Log Email
        RunIsolatedTablePair(50115, 53368, FailedSteps); // Log Transaccion Azul -> DXR_Log Transaccion Azul
        RunIsolatedTablePair(50116, 53369, FailedSteps); // Log Transaccion Medallia -> DXR_Log Transaccion Medallia
        RunIsolatedTablePair(50117, 53370, FailedSteps); // Log Transfer error -> DXR_Log Transfer error
        RunIsolatedTablePair(50132, 53377, FailedSteps); // Posted Jnl Promotion Tickets -> DXR_Posted Jnl Promo Tickets
        RunIsolatedTablePair(50141, 53384, FailedSteps); // Printing Invoice Log -> DXR_Printing Invoice Log
        RunIsolatedTablePair(50160, 53395, FailedSteps); // Send Email Log -> DXR_Send Email Log
        RunIsolatedTablePair(50186, 53407, FailedSteps); // Trans. Archive Line -> DXR_Trans. Archive Line
        RunIsolatedTablePair(50199, 53411, FailedSteps); // UserLogs -> DXR_UserLogs
        RunIsolatedTablePair(50206, 53415, FailedSteps); // Printing Invoice Log BO -> DXR_Printing Invoice Log BO
        ThrowIfStepsFailed('Historic', FailedSteps);
    end;

    procedure RunOther()
    var
        FailedSteps: Text;
    begin
        RunIsolatedTablePair(50001, 53301, FailedSteps); // Agente -> DXR_Agente
        RunIsolatedTablePair(50007, 53305, FailedSteps); // Archivo - Discrepancias -> DXR_Archivo - Discrepancias
        RunIsolatedTablePair(50012, 53310, FailedSteps); // Black List Promotion -> DXR_Black List Promotion
        RunIsolatedTablePair(50013, 53311, FailedSteps); // Cabecera Discrepancia -> DXR_Cabecera Discrepancia
        RunIsolatedTablePair(50025, 53317, FailedSteps); // Comentario - Discrepancias -> DXR_Comentario - Discrepancias
        RunIsolatedTablePair(50048, 53330, FailedSteps); // Departamento - Discrepancias -> DXR_Departamento - Discr
        RunIsolatedTablePair(50103, 53363, FailedSteps); // Linea Discrepancia -> DXR_Linea Discrepancia
        RunIsolatedTablePair(50109, 53365, FailedSteps); // LineRQBuffer -> DXR_LineRQBuffer
        RunIsolatedStep('TE-LSCPOS-TRANS-LINE', FailedSteps);
        RunIsolatedStep('TE-LSCPOS-TRANSACTION', FailedSteps);
        RunIsolatedStep('TE-PAYMENT-METHOD', FailedSteps);
        ThrowIfStepsFailed('Other', FailedSteps);
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
        BatchCount: Integer;
        TargetWasEmpty: Boolean;
    begin
        NewRecRef.Open(NewTableId);
        TargetWasEmpty := NewRecRef.IsEmpty();
        NewRecRef.Close();

        OldRecRef.Open(OldTableId);
        if OldRecRef.FindSet(false) then
            repeat
                NewRecRef.Open(NewTableId);
                NewRecRef.Init();
                for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                    OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                    if (OldFieldRef.Number() < 2000000000) and
                       (OldFieldRef.Class() = FieldClass::Normal) and
                       NewRecRef.FieldExist(OldFieldRef.Name())
                    then begin
                        NewFieldRef := NewRecRef.Field(OldFieldRef.Name());
                        if (NewFieldRef.Class() = FieldClass::Normal) and
                           (OldFieldRef.Type() = NewFieldRef.Type())
                        then
                            NewFieldRef.Value := OldFieldRef.Value();
                    end;
                end;
                if TargetWasEmpty then begin
                    NewRecRef.Insert(false);
                    BatchCount += 1;
                end else
                    if TryInsertRecordRef(NewRecRef) then
                        BatchCount += 1;
                // 2026-08-25 fix: NewRecRef.Close() was missing here, so the 2nd+ legacy row of
                // ANY multi-row table still served by this shared helper (~99 of BELLON-P2's 137
                // tables, the ones not yet converted to native per-table procedures) threw "The
                // record is already open." on the next loop iteration's Open() call, aborting the
                // whole OnRun() and rolling back the entire upgrade-tag-gated batch - the exact
                // "HIGH PRIORITY FIX" root-caused from a real production run but never actually
                // applied to this shared helper itself (only to the tables already carved out into
                // their own native procedures, which stopped sharing this bug by construction).
                NewRecRef.Close();
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRecRef.Next() = 0;
        OldRecRef.Close();
        if BatchCount > 0 then
            Commit();
    end;

    [TryFunction]
    local procedure TryInsertRecordRef(var TargetRecRef: RecordRef)
    begin
        TargetRecRef.Insert(false);
    end;

    // Removed 2026-08-26 (batching + field-by-ID retrofit): this ID-based CopyFieldIfExists(RecRef,
    // OldFieldNo, NewFieldNo) overload had exactly three callers - MigrateTableExt_
    // LSCPOSTransLineFields/LSCPOSTransactionFields/PaymentMethodFields - all of which targeted
    // destination IDs that do not exist in the real schema (confirmed via Dextra_Bellon
    // Customization_28.3.4.20.app's SymbolReference.json), making it a guaranteed no-op wherever
    // it was called. Those three procedures were converted to direct typed Record field access
    // (see each procedure's own "Fixed 2026-08-26" comment for the real "_DXR" targets), leaving
    // this generic helper with no remaining callers - removed rather than left dead.

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
        // Removed 2026-08-27, same two tables and same reasons as in RunMaster() above - "Item HTML"
        // (three BLOB fields) and "Item Image View" (LinkedObject = true on BOTH sides, i.e. a SQL
        // Server view rather than BC storage). Kept as comments rather than deleted so the omission
        // stays visible against the real source's original 137-table list.
        // MigrateItemHTMLTable(); // Item HTML -> DXR_Item HTML (native)
        // MigrateItemImageViewTable(); // Item Image View -> DXR_Item Image View (native)
        // RESTORED 2026-08-27: "ItemNo Desliquidacion" (50100 -> 53361) had been dropped from this
        // list together with the two tables above while triaging the stall, but it is neither a BLOB
        // nor a LinkedObject table - it is a plain scalar table (Item No./Procesado/Fecha Desde/
        // Fecha Hasta/Almacen) and concept BELLON-P2 seq 76 is NOT retired, so leaving it out
        // silently dropped real master data and left that concept permanently gapped.
        MigrateItemNoDesliquidacionTable(); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion (native)
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
        // Removed 2026-08-27: "Inventory View" (50097) and "DXR_Inventory View." (55004) BOTH
        // declare LinkedObject = true - a SQL Server view, not BC storage. See RunMaster().
        // MigrateInventoryViewTable(); // Inventory View -> DXR_Inventory View. (native)
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
    //
    // Fixed 2026-08-26 (batching retrofit, Critical finding on unbounded transaction size): none
    // of the ~57 loop-based MigrateTableExt_* procedures below ever committed, so a single
    // upgrade-tag-gated run touched every ledger/master/transaction table's rows (Cust. Ledger
    // Entry, Gen. Journal Line, Value Entry, Vendor, Customer, Item, LSC Transaction Header, Bank
    // Account Ledger Entry among them) inside one giant uncommitted transaction - same shape bug
    // already fixed in this same portfolio pass for "DXR MCC Bellon Migr Phase3"
    // (DXRMCCBellonMigrPhase3.Codeunit.al, PersistChangedRecord/FinishTable/BatchSize). Mirrors
    // that exact commit cadence here: CheckpointCommit() once per row processed (matching the
    // original data unconditionally, whether or not that specific row's Modify happened) and
    // FinishBatch() once per table after its loop, guaranteeing a commit boundary between tables
    // regardless of row count. Purely a checkpoint/commit safety net - no migration semantics,
    // table order, or field mapping changed.
    local procedure CheckpointCommit()
    begin
        RowsSinceCommit += 1;
        if RowsSinceCommit >= BatchSize() then begin
            Commit();
            RowsSinceCommit := 0;
        end;
    end;

    local procedure FinishBatch()
    begin
        if RowsSinceCommit > 0 then begin
            Commit();
            RowsSinceCommit := 0;
        end;
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

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
                CheckpointCommit();
            until ApprovalEntry.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until BankAccReconciliation.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until BankAccReconciliationLine.Next() = 0;
        FinishBatch();
    end;

    local procedure MigrateTableExt_BankAccountFields()
    var
        BankAccount: Record "Bank Account";
        Blank: Record "Bank Account";
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
                    if BankAccount."Cod. Proveedor Bco._BE_DXR" = Blank."Cod. Proveedor Bco._BE_DXR" then
                        BankAccount."Cod. Proveedor Bco._BE_DXR" := BankAccount."Cod. Proveedor Bco.";
                    if BankAccount."Account No._DXR" = Blank."Account No._DXR" then
                        BankAccount."Account No._DXR" := BankAccount."Account No.";
                    if BankAccount."Amount In Payload_DXR" = Blank."Amount In Payload_DXR" then
                        BankAccount."Amount In Payload_DXR" := BankAccount."Amount In Payload";
                    BankAccount.Modify(false);
                end;
                CheckpointCommit();
            until BankAccount.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until BankAccountLedgerEntry.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCBarcodes.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until CheckLedgerEntry.Next() = 0;
        FinishBatch();
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
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        RecRef: RecordRef;
        Modified: Boolean;
    begin
        RecRef.Open(Database::"Contact");
        if RecRef.FindSet(true) then
            repeat
                Modified := false;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Selection_DXR.', 'Next Order Selection|Next Order Selection_Old|Next Order Selection_Old_DXR|Next Order Selection_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Restaurant_DXR.', 'Next Order Restaurant|Next Order Restaurant_Old|Next Order Rest_Old_DXR|Next Order Restaurant_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Date_DXR.', 'Next Order Date|Next Order Date_Old|Next Order Date_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Time_DXR.', 'Next Order Time|Next Order Time_Old|Next Order Time_Old_DXR|Next Order Time_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Delivery Tender_DXR.', 'Next Delivery Tender|Next Delivery Tender_Old|Next Delivery Tender_Old_DXR|Next Delivery Tender_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Recall Order_DXR.', 'Recall Order|Recall Order_Old|Recall Order_Old_DXR|Recall Order_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Ord Rest Temp_DXR.', 'Next Order Rest. Temporary|Next Ord Rest Temp_Old|Next Ord Rest Temp_Old_DXR|Next Ord Rest Temp_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Date Created_DXR.', 'Date Created|Date Created_Old|Date Created_Old_DXR|Date Created_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Pre-Order Print DT_DXR', 'Pre-Order Print DateTime|Pre-Ord Print DateTime_Old|Pre-Ord Print DT_Old_DXR|Pre-Ord Print DateTime_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Est Prod Time_DXR.', 'Next Estimated Prod. Time|Next Est Prod Time_Old|Next Est Prod Time_Old_DXR|Next Est Prod Time_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'External No._DXR.', 'External No.|External No._Old|External No._Old_DXR|External No._DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Last Date/Time Modified_DXR.', 'Last Date/Time Modified|Last Date/Time Modified_Old|Last Date/Time Mod_Old_DXR|Last Date/Time Modified_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Cust Template Code_DXR', 'Customer Template Code|Customer Template Code_Old|Cust Template Code_Old_DXR|Customer Template Code_DXR') or Modified;
                if Modified then
                    RecRef.Modify(false);
                CheckpointCommit();
            until RecRef.Next() = 0;
        RecRef.Close();
        FinishBatch();
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
                CheckpointCommit();
            until CountryRegion.Next() = 0;
        FinishBatch();
    end;

    local procedure MigrateTableExt_CurrencyFields()
    var
        Currency: Record "Currency";
        Blank: Record "Currency";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "Accepted bpd" into "Accepted bpd_Old" (field 50001), a dead shadow field -
        // Currency.TableExt.al's real active target, confirmed via ObsoleteReason on field 50000
        // (52787 is not itself obsolete), is "Accepted bpd_DXR" (52787). Direct typed field closes
        // that gap.
        if Currency.FindSet(true) then
            repeat
                if Currency."Accepted bpd_DXR" <> Currency."Accepted bpd" then begin
                    if Currency."Accepted bpd_DXR" = Blank."Accepted bpd_DXR" then
                        Currency."Accepted bpd_DXR" := Currency."Accepted bpd";
                    Currency.Modify(false);
                end;
                CheckpointCommit();
            until Currency.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until CurrencyExchangeRate.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until CustLedgerEntry.Next() = 0;
        FinishBatch();
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
        Blank: Record Customer;
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
                    if Customer."Dirección Representante_DXR" = Blank."Dirección Representante_DXR" then
                        Customer."Dirección Representante_DXR" := Customer."Dirección Representante";
                    if Customer."Sector Representante_DXR" = Blank."Sector Representante_DXR" then
                        Customer."Sector Representante_DXR" := Customer."Sector Representante";
                    if Customer."Cédula Representante_DXR" = Blank."Cédula Representante_DXR" then
                        Customer."Cédula Representante_DXR" := Customer."Cédula Representante";
                    if Customer."Cumpl Representante_DXR" = Blank."Cumpl Representante_DXR" then
                        Customer."Cumpl Representante_DXR" := Customer."Cumpleaños Representante";
                    if Customer."Celular Representante_DXR" = Blank."Celular Representante_DXR" then
                        Customer."Celular Representante_DXR" := Customer."Celular Representante";
                    if Customer."E-Mail Representante_DXR." = Blank."E-Mail Representante_DXR." then
                        Customer."E-Mail Representante_DXR." := Customer."E-Mail Representante";
                    if Customer."Código Cobrador_DXR" = Blank."Código Cobrador_DXR" then
                        Customer."Código Cobrador_DXR" := Customer."Código Cobrador";
                    if Customer."Requiere OC_DXR" = Blank."Requiere OC_DXR" then
                        Customer."Requiere OC_DXR" := Customer."Requiere OC";
                    if Customer."Tipo de Cliente_DXR" = Blank."Tipo de Cliente_DXR" then
                        Customer."Tipo de Cliente_DXR" := Customer."Tipo de Cliente";
                    if Customer."Frecuencia Visita_DXR" = Blank."Frecuencia Visita_DXR" then
                        Customer."Frecuencia Visita_DXR" := Customer."Frecuencia Visita";
                    if Customer."Secuencia Visita_DXR" = Blank."Secuencia Visita_DXR" then
                        Customer."Secuencia Visita_DXR" := Customer."Secuencia Visita";
                    if Customer."Días Visita_DXR" = Blank."Días Visita_DXR" then
                        Customer."Días Visita_DXR" := Customer."Días Visita";
                    if Customer."Carnet DGII_DXR" = Blank."Carnet DGII_DXR" then
                        Customer."Carnet DGII_DXR" := Customer."Carnet DGII";
                    if Customer."Cobrar Interés_DXR" = Blank."Cobrar Interés_DXR" then
                        Customer."Cobrar Interés_DXR" := Customer."Cobrar Interés";
                    if Customer."% Interés_DXR" = Blank."% Interés_DXR" then
                        Customer."% Interés_DXR" := Customer."% Interés";
                    if Customer."Carnet Exención ITBIS_DXR" = Blank."Carnet Exención ITBIS_DXR" then
                        Customer."Carnet Exención ITBIS_DXR" := Customer."Carnet Exención ITBIS";
                    if Customer."Vencimiento Carnet_DXR" = Blank."Vencimiento Carnet_DXR" then
                        Customer."Vencimiento Carnet_DXR" := Customer."Vencimiento Carnet";
                    if Customer."Enc. Compras Nombre_DXR" = Blank."Enc. Compras Nombre_DXR" then
                        Customer."Enc. Compras Nombre_DXR" := Customer."Enc. Compras Nombre";
                    if Customer."Enc. Compras Email_DXR." = Blank."Enc. Compras Email_DXR." then
                        Customer."Enc. Compras Email_DXR." := Customer."Enc. Compras email";
                    if Customer."Enc. Compras celular_DXR" = Blank."Enc. Compras celular_DXR" then
                        Customer."Enc. Compras celular_DXR" := Customer."Enc. Compras celular";
                    if Customer."Enc. Compras Cumpleaños_DXR" = Blank."Enc. Compras Cumpleaños_DXR" then
                        Customer."Enc. Compras Cumpleaños_DXR" := Customer."Enc. Compras Cumpleaños";
                    if Customer."Enc. Pagos Nombre_DXR" = Blank."Enc. Pagos Nombre_DXR" then
                        Customer."Enc. Pagos Nombre_DXR" := Customer."Enc. Pagos Nombre";
                    if Customer."Enc. Pagos Email_DXR." = Blank."Enc. Pagos Email_DXR." then
                        Customer."Enc. Pagos Email_DXR." := Customer."Enc. Pagos email";
                    if Customer."Enc. Pagos celular_DXR" = Blank."Enc. Pagos celular_DXR" then
                        Customer."Enc. Pagos celular_DXR" := Customer."Enc. Pagos celular";
                    if Customer."Enc. Pagos Cumpleaños_DXR" = Blank."Enc. Pagos Cumpleaños_DXR" then
                        Customer."Enc. Pagos Cumpleaños_DXR" := Customer."Enc. Pagos Cumpleaños";
                    if Customer."Frecuencia de Pago_DXR" = Blank."Frecuencia de Pago_DXR" then
                        Customer."Frecuencia de Pago_DXR" := Customer."Frecuencia de Pago";
                    if Customer."Apartado Postal_DXR" = Blank."Apartado Postal_DXR" then
                        Customer."Apartado Postal_DXR" := Customer."Apartado Postal";
                    if Customer."Sector_DXR" = Blank."Sector_DXR" then
                        Customer."Sector_DXR" := Customer.Sector;
                    if Customer."Municipio_DXR" = Blank."Municipio_DXR" then
                        Customer."Municipio_DXR" := Customer.Municipio;
                    if Customer."Provincia_DXR" = Blank."Provincia_DXR" then
                        Customer."Provincia_DXR" := Customer.Provincia;
                    if Customer."Comision_Tipo_ID_DXR." = Blank."Comision_Tipo_ID_DXR." then
                        Customer."Comision_Tipo_ID_DXR." := Customer.Comision_Tipo_ID;
                    if Customer."Deuda Pico_DXR" = Blank."Deuda Pico_DXR" then
                        Customer."Deuda Pico_DXR" := Customer."Deuda Pico";
                    if Customer."Fecha Deuda Pico_DXR" = Blank."Fecha Deuda Pico_DXR" then
                        Customer."Fecha Deuda Pico_DXR" := Customer."Fecha Deuda Pico";
                    if Customer."Gestor_ID_DXR." = Blank."Gestor_ID_DXR." then
                        Customer."Gestor_ID_DXR." := Customer.Gestor_ID;
                    if Customer."Fecha envio edo cuenta_DXR" = Blank."Fecha envio edo cuenta_DXR" then
                        Customer."Fecha envio edo cuenta_DXR" := Customer."Fecha envio estado cuenta";
                    if Customer."Invoice Expiration Days_DXR" = Blank."Invoice Expiration Days_DXR" then
                        Customer."Invoice Expiration Days_DXR" := Customer."Invoice Expiration Days";
                    if Customer."Enc. Recepcion Email_DXR." = Blank."Enc. Recepcion Email_DXR." then
                        Customer."Enc. Recepcion Email_DXR." := Customer."Enc. Recepcion Email";
                    if Customer."StoreID_DXR." = Blank."StoreID_DXR." then
                        Customer."StoreID_DXR." := Customer.StoreId;
                    if Customer."Tipo Segmento_DXR" = Blank."Tipo Segmento_DXR" then
                        Customer."Tipo Segmento_DXR" := Customer."Tipo Segmento";
                    if Customer."Monto Deposito Cilindr_DXR" = Blank."Monto Deposito Cilindr_DXR" then
                        Customer."Monto Deposito Cilindr_DXR" := Customer."Monto Deposito - Cilindros";
                    if Customer."Cant asig - Cilindros_DXR" = Blank."Cant asig - Cilindros_DXR" then
                        Customer."Cant asig - Cilindros_DXR" := Customer."Cantidad asignar - Cilindros";
                    if Customer."Cliente Cilindros_DXR" = Blank."Cliente Cilindros_DXR" then
                        Customer."Cliente Cilindros_DXR" := Customer."Cliente Cilindros";
                    if Customer."Fecha Exp Reg Merc_DXR" = Blank."Fecha Exp Reg Merc_DXR" then
                        Customer."Fecha Exp Reg Merc_DXR" := Customer."Fecha Expiracion Reg Mercantil";
                    if Customer."B2C Customer_DXR" = Blank."B2C Customer_DXR" then
                        Customer."B2C Customer_DXR" := Customer."B2C Customer";
                    if Customer."Last Date/Time Modified_DXR" = Blank."Last Date/Time Modified_DXR" then
                        Customer."Last Date/Time Modified_DXR" := Customer."Last Date/Time Modified";
                    if Customer."Req Fecha Reg Merc_DXR" = Blank."Req Fecha Reg Merc_DXR" then
                        Customer."Req Fecha Reg Merc_DXR" := Customer."Requiere Fecha Reg. Mercantil";
                    Customer.Modify(false);
                end;
                CheckpointCommit();
            until Customer.Next() = 0;
        FinishBatch();
    end;

    local procedure MigrateTableExt_CustomerPriceGroupFields()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        Blank: Record "Customer Price Group";
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
                    if CustomerPriceGroup."Global Sales Code_DXR" = Blank."Global Sales Code_DXR" then
                        CustomerPriceGroup."Global Sales Code_DXR" := CustomerPriceGroup."Global Sales Code";
                    CustomerPriceGroup.Modify(false);
                end;
                CheckpointCommit();
            until CustomerPriceGroup.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until GenJournalBatch.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until GenJournalLine.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until GenProductPostingGroup.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until IssuedReminderHeader.Next() = 0;
        FinishBatch();
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
        Blank: Record Item;
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
                    if Item."Modelo_DXR" = Blank."Modelo_DXR" then
                        Item."Modelo_DXR" := Item.Modelo;
                    if Item."Marca_DXR" = Blank."Marca_DXR" then
                        Item."Marca_DXR" := Item.Marca;
                    if Item."Se Detalla_DXR" = Blank."Se Detalla_DXR" then
                        Item."Se Detalla_DXR" := Item."Se Detalla";
                    if Item."Producido_DXR" = Blank."Producido_DXR" then
                        Item."Producido_DXR" := Item.Producido;
                    if Item."Carga % Tarjeta_DXR" = Blank."Carga % Tarjeta_DXR" then
                        Item."Carga % Tarjeta_DXR" := Item."Carga % Tarjeta";
                    if Item."Consignación_DXR" = Blank."Consignación_DXR" then
                        Item."Consignación_DXR" := Item."Consignación";
                    if Item."Internal Use_DXR" = Blank."Internal Use_DXR" then
                        Item."Internal Use_DXR" := Item."Internal Use";
                    if Item."Acepta Decimales_DXR" = Blank."Acepta Decimales_DXR" then
                        Item."Acepta Decimales_DXR" := Item."Acepta Decimales";
                    if Item."Exhibición_DXR" = Blank."Exhibición_DXR" then
                        Item."Exhibición_DXR" := Item."Exhibición";
                    if Item."Precio Sugerido_DXR" = Blank."Precio Sugerido_DXR" then
                        Item."Precio Sugerido_DXR" := Item."Precio Sugerido";
                    if Item."Kit_DXR" = Blank."Kit_DXR" then
                        Item."Kit_DXR" := Item.Kit;
                    if Item."Empaque_DXR" = Blank."Empaque_DXR" then
                        Item."Empaque_DXR" := Item.Empaque;
                    if Item."Empaque Maestro_DXR" = Blank."Empaque Maestro_DXR" then
                        Item."Empaque Maestro_DXR" := Item."Empaque Maestro";
                    if Item."Venta por Mayor_DXR" = Blank."Venta por Mayor_DXR" then
                        Item."Venta por Mayor_DXR" := Item."Venta por Mayor";
                    if Item."% Comisión Venta_DXR" = Blank."% Comisión Venta_DXR" then
                        Item."% Comisión Venta_DXR" := Item."% Comisión Venta";
                    if Item."% Comisión Cobro_DXR" = Blank."% Comisión Cobro_DXR" then
                        Item."% Comisión Cobro_DXR" := Item."% Comisión Cobro";
                    if Item."Márgen Plaza_DXR" = Blank."Márgen Plaza_DXR" then
                        Item."Márgen Plaza_DXR" := Item."Márgen Plaza";
                    if Item."Márgen Importación_DXR" = Blank."Márgen Importación_DXR" then
                        Item."Márgen Importación_DXR" := Item."Márgen Importación";
                    if Item."Descripcion_Bellon_DXR" = Blank."Descripcion_Bellon_DXR" then
                        Item."Descripcion_Bellon_DXR" := Item."Descripcion Bellon";
                    if Item."Costo Liquidacion_DXR" = Blank."Costo Liquidacion_DXR" then
                        Item."Costo Liquidacion_DXR" := Item."Costo Liquidacion";
                    if Item."Comision_Tipo_ID_DXR." = Blank."Comision_Tipo_ID_DXR." then
                        Item."Comision_Tipo_ID_DXR." := Item.Comision_Tipo_ID;
                    if Item."Ultimo Costo Bellon_DXR" = Blank."Ultimo Costo Bellon_DXR" then
                        Item."Ultimo Costo Bellon_DXR" := Item."Ultimo Costo Bellon";
                    if Item."Costo Unitario Bellon_DXR" = Blank."Costo Unitario Bellon_DXR" then
                        Item."Costo Unitario Bellon_DXR" := Item."Costo Unitario Bellon";
                    if Item."SANA Info Adicionales_DXR" = Blank."SANA Info Adicionales_DXR" then
                        Item."SANA Info Adicionales_DXR" := Item."SANA - Info. Adicionales";
                    if Item."Sales Group_DXR" = Blank."Sales Group_DXR" then
                        Item."Sales Group_DXR" := Item."Sales Group";
                    if Item."Sales SubGroup_DXR" = Blank."Sales SubGroup_DXR" then
                        Item."Sales SubGroup_DXR" := Item."Sales SubGroup";
                    if Item."Sales Dept Code_DXR" = Blank."Sales Dept Code_DXR" then
                        Item."Sales Dept Code_DXR" := Item."Sales Dept Code";
                    if Item."Codigo Producto Aduana_DXR" = Blank."Codigo Producto Aduana_DXR" then
                        Item."Codigo Producto Aduana_DXR" := Item."Codigo Producto Aduana";
                    if Item."ExclFromDiscountCoupons_DXR" = Blank."ExclFromDiscountCoupons_DXR" then
                        Item."ExclFromDiscountCoupons_DXR" := Item.ExcludedFromDiscountCoupons;
                    if Item."ExclFromFreeShipCoupons_DXR" = Blank."ExclFromFreeShipCoupons_DXR" then
                        Item."ExclFromFreeShipCoupons_DXR" := Item.ExcludedFromFreeShipCoupons;
                    if Item."Disponible para Ventas_DXR" = Blank."Disponible para Ventas_DXR" then
                        Item."Disponible para Ventas_DXR" := Item."Disponible para Ventas";
                    if Item."Item Status_DXR" = Blank."Item Status_DXR" then
                        Item."Item Status_DXR" := Item."Item Status";
                    if Item."Control Existencia_DXR" = Blank."Control Existencia_DXR" then
                        Item."Control Existencia_DXR" := Item."Control Existencia";
                    Item.Modify(false);
                end;
                CheckpointCommit();
            until Item.Next() = 0;
        FinishBatch();
    end;

    local procedure MigrateTableExt_ItemCategoryFields()
    var
        ItemCategory: Record "Item Category";
        Blank: Record "Item Category";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 50000, 50001))
        // copied "% Comision" into "% Comision_Old" (field 50001), a dead shadow field -
        // ItemCategory.TableExt.al's real active target, confirmed via ObsoleteReason on field 50000
        // (52787 is not itself obsolete), is "% Comision_DXR" (52787). Direct typed field closes
        // that gap.
        if ItemCategory.FindSet(true) then
            repeat
                if ItemCategory."% Comision_DXR" <> ItemCategory."% Comision" then begin
                    if ItemCategory."% Comision_DXR" = Blank."% Comision_DXR" then
                        ItemCategory."% Comision_DXR" := ItemCategory."% Comision";
                    ItemCategory.Modify(false);
                end;
                CheckpointCommit();
            until ItemCategory.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until ItemChargeAssignmentPurch.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until ItemJournalLine.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCItemSpecialGroups.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until CashJournalReceiptList.Next() = 0;
        FinishBatch();
    end;

    local procedure MigrateTableExt_LocationFields()
    var
        Location: Record Location;
        Blank: Record Location;
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
                    if Location."Req._Transport_DXR" = Blank."Req._Transport_DXR" then
                        Location."Req._Transport_DXR" := Location."Req. Transport";
                    if Location."Existencia Ventas_DXR" = Blank."Existencia Ventas_DXR" then
                        Location."Existencia Ventas_DXR" := Location."Existencia Ventas";
                    if Location."Transito Internacional_DXR" = Blank."Transito Internacional_DXR" then
                        Location."Transito Internacional_DXR" := Location."Transito Internacional";
                    if Location."Req. Cod. Audit Transf_DXR" = Blank."Req. Cod. Audit Transf_DXR" then
                        Location."Req. Cod. Audit Transf_DXR" := Location."Req. Cod. Auditoria Transf.";
                    if Location."Visible in Trafico_DXR" = Blank."Visible in Trafico_DXR" then
                        Location."Visible in Trafico_DXR" := Location."Visible in Trafico";
                    if Location."Req. Cod. Pos. & Neg._DXR" = Blank."Req. Cod. Pos. & Neg._DXR" then
                        Location."Req. Cod. Pos. & Neg._DXR" := Location."Req. Cod. Pos. & Neg.";
                    Location.Modify(false);
                end;
                CheckpointCommit();
            until Location.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCMemberContact.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCMemberPointOffer.Next() = 0;
        FinishBatch();
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

    // Fixed 2026-08-26: the old RecordRef version's four ID-based CopyFieldIfExists(RecRef,
    // OldFieldNo, NewFieldNo) calls all targeted destination IDs (50007-50010) that do not exist
    // anywhere in "LSC POS Trans. Line"'s real schema - guaranteed no-ops on every row - confirmed
    // via Dextra_Bellon Customization_28.3.4.20.app's SymbolReference.json (the exact dependency
    // symbol package this project compiles against). Each source field's real active target,
    // confirmed via that same schema's ObsoleteReason on each source field (none of the _DXR
    // destinations below are themselves obsolete), is its "_DXR"-suffixed sibling: "Offer No." ->
    // "Offer No._DXR" (52787), "Orig. Trans. Date" -> "Orig. Trans. Date_DXR" (52788),
    // PedidoBackOffice -> "PedidoBackOffice_DXR" (52789), Autorizador -> "Autorizador_DXR"
    // (52790). Direct typed fields close all four gaps.
    local procedure MigrateTableExt_LSCPOSTransLineFields()
    var
        LSCPOSTransLine: Record "LSC POS Trans. Line";
    begin
        if LSCPOSTransLine.FindSet(true) then
            repeat
                if (LSCPOSTransLine."Offer No._DXR" <> LSCPOSTransLine."Offer No.") or
                   (LSCPOSTransLine."Orig. Trans. Date_DXR" <> LSCPOSTransLine."Orig. Trans. Date") or
                   (LSCPOSTransLine."PedidoBackOffice_DXR" <> LSCPOSTransLine.PedidoBackOffice) or
                   (LSCPOSTransLine."Autorizador_DXR" <> LSCPOSTransLine.Autorizador)
                then begin
                    LSCPOSTransLine."Offer No._DXR" := LSCPOSTransLine."Offer No.";
                    LSCPOSTransLine."Orig. Trans. Date_DXR" := LSCPOSTransLine."Orig. Trans. Date";
                    LSCPOSTransLine."PedidoBackOffice_DXR" := LSCPOSTransLine.PedidoBackOffice;
                    LSCPOSTransLine."Autorizador_DXR" := LSCPOSTransLine.Autorizador;
                    LSCPOSTransLine.Modify(false);
                end;
                CheckpointCommit();
            until LSCPOSTransLine.Next() = 0;
        FinishBatch();
    end;

    // Fixed 2026-08-26: same situation as MigrateTableExt_LSCPOSTransLineFields() above - the old
    // RecordRef version's five ID-based CopyFieldIfExists calls all targeted destination IDs
    // (50006-50010) that do not exist anywhere in "LSC POS Transaction"'s real schema (confirmed
    // via Dextra_Bellon Customization_28.3.4.20.app's SymbolReference.json) - guaranteed no-ops on
    // every row, so this procedure has never actually migrated any data. Each source field's real
    // active target, confirmed via that same schema's ObsoleteReason on each source field (none of
    // the _DXR destinations below are themselves obsolete), is its "_DXR"-suffixed sibling:
    // Autorizador -> "Autorizador_DXR" (52791), PedidoBackOffice -> "PedidoBackOffice_DXR"
    // (52787), "Sell-to Contact" -> "Sell-to Contact_DXR" (52788), PanelCRF -> "PanelCRF_DXR"
    // (52789), "Qty Tickets" -> "Qty Tickets_DXR" (52790). Direct typed fields close all five gaps.
    local procedure MigrateTableExt_LSCPOSTransactionFields()
    var
        LSCPOSTransaction: Record "LSC POS Transaction";
    begin
        if LSCPOSTransaction.FindSet(true) then
            repeat
                if (LSCPOSTransaction."Autorizador_DXR" <> LSCPOSTransaction.Autorizador) or
                   (LSCPOSTransaction."PedidoBackOffice_DXR" <> LSCPOSTransaction.PedidoBackOffice) or
                   (LSCPOSTransaction."Sell-to Contact_DXR" <> LSCPOSTransaction."Sell-to Contact") or
                   (LSCPOSTransaction."PanelCRF_DXR" <> LSCPOSTransaction.PanelCRF) or
                   (LSCPOSTransaction."Qty Tickets_DXR" <> LSCPOSTransaction."Qty Tickets")
                then begin
                    LSCPOSTransaction."Autorizador_DXR" := LSCPOSTransaction.Autorizador;
                    LSCPOSTransaction."PedidoBackOffice_DXR" := LSCPOSTransaction.PedidoBackOffice;
                    LSCPOSTransaction."Sell-to Contact_DXR" := LSCPOSTransaction."Sell-to Contact";
                    LSCPOSTransaction."PanelCRF_DXR" := LSCPOSTransaction.PanelCRF;
                    LSCPOSTransaction."Qty Tickets_DXR" := LSCPOSTransaction."Qty Tickets";
                    LSCPOSTransaction.Modify(false);
                end;
                CheckpointCommit();
            until LSCPOSTransaction.Next() = 0;
        FinishBatch();
    end;

    // Fixed 2026-08-26: same situation as MigrateTableExt_LSCPOSTransLineFields() above - the old
    // RecordRef version's four ID-based CopyFieldIfExists calls all targeted destination IDs
    // (50006-50009) that do not exist anywhere in "Payment Method"'s real schema (confirmed via
    // Dextra_Bellon Customization_28.3.4.20.app's SymbolReference.json) - guaranteed no-ops on
    // every row. Not to be confused with Phase7's MigrateTableExt_PaymentMethodIdRestore() (a
    // different bug, bridging "_DXR"/"_Old" name pairs at different, already-renumbered field
    // IDs). Each source field's real active target, confirmed via that same schema's
    // ObsoleteReason on each source field (none of the _DXR destinations below are themselves
    // obsolete), is its "_DXR"-suffixed sibling: "Payment Processor" -> "Payment Processor_DXR"
    // (52787), Prioridad -> "Prioridad_DXR." (52788, trailing period as declared in source),
    // Contado -> "Contado_DXR" (52789), "Tipo Venta" -> "Tipo Venta_DXR" (52790). Direct typed
    // fields close all four gaps.
    local procedure MigrateTableExt_PaymentMethodFields()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.FindSet(true) then
            repeat
                if (PaymentMethod."Payment Processor_DXR" <> PaymentMethod."Payment Processor") or
                   (PaymentMethod."Prioridad_DXR." <> PaymentMethod.Prioridad) or
                   (PaymentMethod."Contado_DXR" <> PaymentMethod.Contado) or
                   (PaymentMethod."Tipo Venta_DXR" <> PaymentMethod."Tipo Venta")
                then begin
                    PaymentMethod."Payment Processor_DXR" := PaymentMethod."Payment Processor";
                    PaymentMethod."Prioridad_DXR." := PaymentMethod.Prioridad;
                    PaymentMethod."Contado_DXR" := PaymentMethod.Contado;
                    PaymentMethod."Tipo Venta_DXR" := PaymentMethod."Tipo Venta";
                    PaymentMethod.Modify(false);
                end;
                CheckpointCommit();
            until PaymentMethod.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCPeriodicDiscount.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCPostedStatement.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCRetailProductGroup.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until PurchCommentLine.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until PurchCommentLineArchive.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until PurchInvLine.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until ReasonCode.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCReplenJournalLines.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCReplenTemplate.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCRetailUser.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until SalesPrice.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCSalesType.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until SalespersonPurchaser.Next() = 0;
        FinishBatch();
    end;

    // Fixed 2026-08-24: the old RecordRef version had two pairs, both copying into dead "_Old"
    // shadow fields - ShiptoAddress.TableExt.al's real active targets, confirmed via ObsoleteReason
    // on fields 50000/50001 (52787/52788 are not themselves obsolete), are "Latitud_DXR." (52787,
    // trailing period as declared in source) and "Longitud_DXR." (52788, trailing period as declared
    // in source). Direct typed fields close both gaps.
    local procedure MigrateTableExt_ShiptoAddressFields()
    var
        ShiptoAddress: Record "Ship-to Address";
        Blank: Record "Ship-to Address";
    begin
        if ShiptoAddress.FindSet(true) then
            repeat
                if (ShiptoAddress."Latitud_DXR." <> ShiptoAddress.Latitud) or
                   (ShiptoAddress."Longitud_DXR." <> ShiptoAddress.Longitud)
                then begin
                    if ShiptoAddress."Latitud_DXR." = Blank."Latitud_DXR." then
                        ShiptoAddress."Latitud_DXR." := ShiptoAddress.Latitud;
                    if ShiptoAddress."Longitud_DXR." = Blank."Longitud_DXR." then
                        ShiptoAddress."Longitud_DXR." := ShiptoAddress.Longitud;
                    ShiptoAddress.Modify(false);
                end;
                CheckpointCommit();
            until ShiptoAddress.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCStatement.Next() = 0;
        FinishBatch();
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
        Blank: Record "LSC STORE";
    begin
        if LSCStore.FindSet(true) then
            repeat
                if (LSCStore."Cod. Cliente Contado_BE_DXR" <> LSCStore."Cod. Cliente Contado") or
                   (LSCStore."No Serie 3er Party Item_DXR" <> LSCStore."No. Serie 3er. Party Item") or
                   (LSCStore."Address 3_BE_DXR" <> LSCStore."Address 3") or
                   (LSCStore."Utiliza NCF Unico_BE_DXR" <> LSCStore."Utiliza NCF Unico") or
                   (LSCStore."Print Header Doc._DXR." <> LSCStore."Print Header Doc.")
                then begin
                    if LSCStore."Cod. Cliente Contado_BE_DXR" = Blank."Cod. Cliente Contado_BE_DXR" then
                        LSCStore."Cod. Cliente Contado_BE_DXR" := LSCStore."Cod. Cliente Contado";
                    if LSCStore."No Serie 3er Party Item_DXR" = Blank."No Serie 3er Party Item_DXR" then
                        LSCStore."No Serie 3er Party Item_DXR" := LSCStore."No. Serie 3er. Party Item";
                    if LSCStore."Address 3_BE_DXR" = Blank."Address 3_BE_DXR" then
                        LSCStore."Address 3_BE_DXR" := LSCStore."Address 3";
                    if LSCStore."Utiliza NCF Unico_BE_DXR" = Blank."Utiliza NCF Unico_BE_DXR" then
                        LSCStore."Utiliza NCF Unico_BE_DXR" := LSCStore."Utiliza NCF Unico";
                    if LSCStore."Print Header Doc._DXR." = Blank."Print Header Doc._DXR." then
                        LSCStore."Print Header Doc._DXR." := LSCStore."Print Header Doc.";
                    LSCStore.Modify(false);
                end;
                CheckpointCommit();
            until LSCStore.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until TariffNumber.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCTenderType.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCTransSalesEntry.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until LSCTransactionHeader.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until TransferLine.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until TransferReceiptHeader.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until TransferShipmentHeader.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until UserSetup.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until ValueEntry.Next() = 0;
        FinishBatch();
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
        Blank: Record Vendor;
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
                    if Vendor."Teléfono 2_DXR" = Blank."Teléfono 2_DXR" then
                        Vendor."Teléfono 2_DXR" := Vendor."BE Teléfono 2";
                    if Vendor."Vendedor_DXR" = Blank."Vendedor_DXR" then
                        Vendor."Vendedor_DXR" := Vendor."BE Vendedor";
                    if Vendor."Vendedor Email_DXR." = Blank."Vendedor Email_DXR." then
                        Vendor."Vendedor Email_DXR." := Vendor."BE Vendedor email";
                    if Vendor."Vendedor Celular_DXR" = Blank."Vendedor Celular_DXR" then
                        Vendor."Vendedor Celular_DXR" := Vendor."BE Vendedor Celular";
                    if Vendor."Tipo Servicio_DXR" = Blank."Tipo Servicio_DXR" then
                        Vendor."Tipo Servicio_DXR" := Vendor."BE Tipo Servicio";
                    if Vendor."Clasificación ABC_DXR" = Blank."Clasificación ABC_DXR" then
                        Vendor."Clasificación ABC_DXR" := Vendor."BE Clasificación ABC";
                    if Vendor."Enc. Cobros Nombre_DXR" = Blank."Enc. Cobros Nombre_DXR" then
                        Vendor."Enc. Cobros Nombre_DXR" := Vendor."BE Enc. Cobros Nombre";
                    if Vendor."Enc. Cobros Email_DXR." = Blank."Enc. Cobros Email_DXR." then
                        Vendor."Enc. Cobros Email_DXR." := Vendor."BE Enc. Cobros email";
                    if Vendor."Enc. Cobros celular_DXR" = Blank."Enc. Cobros celular_DXR" then
                        Vendor."Enc. Cobros celular_DXR" := Vendor."BE Enc. Cobros celular";
                    if Vendor."Enc. Cobros Cumpleaños_DXR" = Blank."Enc. Cobros Cumpleaños_DXR" then
                        Vendor."Enc. Cobros Cumpleaños_DXR" := Vendor."BE Enc. Cobros Cumpleaños";
                    if Vendor."Frecuencia de Pago_DXR" = Blank."Frecuencia de Pago_DXR" then
                        Vendor."Frecuencia de Pago_DXR" := Vendor."BE Frecuencia de Pago";
                    if Vendor."Límite de Crédito_DXR" = Blank."Límite de Crédito_DXR" then
                        Vendor."Límite de Crédito_DXR" := Vendor."BE Límite de Crédito";
                    if Vendor."Apartado Postal_DXR" = Blank."Apartado Postal_DXR" then
                        Vendor."Apartado Postal_DXR" := Vendor."BE Apartado Postal";
                    if Vendor."Sector_DXR" = Blank."Sector_DXR" then
                        Vendor."Sector_DXR" := Vendor."BE Sector";
                    if Vendor."Municipio_DXR" = Blank."Municipio_DXR" then
                        Vendor."Municipio_DXR" := Vendor."BE Municipio";
                    if Vendor."Provincia_DXR" = Blank."Provincia_DXR" then
                        Vendor."Provincia_DXR" := Vendor."BE Provincia";
                    if Vendor."Despachador Email_DX.R" = Blank."Despachador Email_DX.R" then
                        Vendor."Despachador Email_DX.R" := Vendor."BE Despachador Email";
                    if Vendor."Proveedor Cilindros_DXR" = Blank."Proveedor Cilindros_DXR" then
                        Vendor."Proveedor Cilindros_DXR" := Vendor."BE Proveedor Cilindros";
                    if Vendor."Gestor_CXP_ID_DXR." = Blank."Gestor_CXP_ID_DXR." then
                        Vendor."Gestor_CXP_ID_DXR." := Vendor."BE Gestor_CXP_ID";
                    if Vendor."FechaCreacion_DXR" = Blank."FechaCreacion_DXR" then
                        Vendor."FechaCreacion_DXR" := Vendor."BE FechaCreacion";
                    Vendor.Modify(false);
                end;
                CheckpointCommit();
            until Vendor.Next() = 0;
        FinishBatch();
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
                CheckpointCommit();
            until WarehouseReceiptLine.Next() = 0;
        FinishBatch();
    end;

    var
        RowsSinceCommit: Integer;
}

#endif
