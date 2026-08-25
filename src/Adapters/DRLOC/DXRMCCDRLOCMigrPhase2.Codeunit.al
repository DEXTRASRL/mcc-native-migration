codeunit 60165 "DXR MCC DRLOC Migr Phase2"
{
    // Native local migration - ported verbatim (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization own "DXR_Internal Closure Migration" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Internal_Closure_Migration_Upgrade_Clean.al), which currently
    // only runs from DR-Localization own background TaskScheduler dispatcher. This codeunit lets
    // MCC run the same 13 field-copy procedures itself, without depending on DR-Localization own
    // dispatcher. DR-Localization own internalsVisibleTo already grants MCC app ID, so every table
    // below (both the legacy "Dx"/"DX"-prefixed side and the "_DXR"-suffixed target side) is
    // declared as a typed Record directly, matching the pattern already proven by
    // "DXR MCC Adapt DRLOC PmtMethod" (60164).
    //
    // Registry rows (DXRMCCRegistryLoader.Codeunit.al, DRLOC-P2 seq9/10/11) are repointed from the
    // generic forwarding adapter (60069, "DXR MCC Adapt DRLOC Dispatch") to this codeunit as part
    // of the same change that adds this file.
    //
    // Batch 3 (2026-08-24) added seq54-64 - 11 more whole-table-clone registry rows (Withholding/
    // Payment/Other setup tables), also repointed from 60069 to this codeunit. See the
    // "seq54-64" section comment below for full detail.
    //
    // Shadow-field check (2026-08-24): every destination field in all 13 ported procedures was
    // independently verified against DR-Localization real tableextension sources
    // (DXR_CustomerExt.TableExt.al, DXR_VendorExt.TableExt.Al, DXR_BankAccountExt.TableExt.al,
    // DXR_CompanyInformationExt.TableExt.al, DXR_CustomerTempl.TableExt.al,
    // DXR_UserSetupExt.TableExt.al, DXR_NoSeriesLineExt.TableExt.al, DXR_GenJournalTemplate.TableExt.al,
    // DXR_GenJournalBatchExt.TableExt.Al, DXR_WorkflowStepArgument.TableExt.al,
    // DXR_VATProductPostingGroupTablExt.TableExt.al) - full field-by-field coverage on Customer and
    // Vendor per this task elevated master-data rigor requirement. All "_DXR" fields confirmed to
    // be the true, non-obsoleted final target (no ObsoleteState); all legacy "Dx"/"DX" source fields
    // confirmed ObsoleteState = Pending (still readable, safe migration source).
    //
    // One real bug found and fixed while porting (not a shadow-field issue - the target field is
    // correct, but the source own procedure never copies it): DR-Localization real
    // MigrateFields_Customer() checks "Apply Cust Withhold_DXR" against
    // "DX Apply Customer Withholding" in its dirty-check condition (added 2026-08-22 per that
    // procedure own comment) but never actually assigns the field in the following if-block - the
    // 20th condition has no matching 20th assignment. Both fields are confirmed real, non-FlowField
    // Enum fields on Customer (field 51831 for the target "_DXR" field): the target enum is
    // "DXR_ApplyCustomerWithholding" (52201, current, not obsolete) and the legacy source enum is
    // "DXApplyCustomerWithholding" (54203, ObsoleteState = Pending). This port adds the missing
    // assignment so the ported version actually does what the dirty-check condition promises;
    // DR-Localization own source is left unmodified (out of scope - this MCC repo only).
    //
    // "GLAccount" (part of seq11) is a deliberate no-op, matching DR-Localization own source: both
    // "DXNCF" and "NCF_DXR" on G/L Account are ObsoleteState = Removed (confirmed against
    // DXR_GLAccountExt.TableExt.al) - nothing left to migrate for that table via this procedure.
    // (G/L Account still-active "DXNCF Categories" -> "NCFCategories_DXR" field is a different,
    // already-tracked registry row, DRLOC-P2 seq105 - out of scope here.)
    //
    // Upgrade Tag reuse (2026-08-24, review fix): every one of the 13 procedures below is gated by
    // DR-Localization's OWN real per-procedure completion tag, copied verbatim (as literals, not a
    // runtime call into DRLOC's codeunit) from DXR_UpgradeTagMgt.Codeunit.al
    // (UpgradeTagInternalClosureFields<X>() for each table) - same rationale and pattern already
    // documented in DXRMCCBellonMigrPhase2.Codeunit.al's own header: reusing the sibling's own exact
    // tag strings means a tenant that already ran this migration via the old bridge path (registry
    // rows seq9/10/11 previously pointed at codeunit 60069, which called into DRLOC's own real
    // dispatcher, codeunit 52208) is correctly recognized as already done and this codeunit's first
    // run after cutover skips the redundant FindSet(true) scan on every table, instead of treating
    // every tenant as if none of this had ever run. Not a data-integrity risk either way (each
    // procedure's own dirty-check before Modify makes a redundant scan safe), but avoiding it matters
    // more for later DRLOC batches that touch Ledger Entry-scale tables. The Customer tag
    // (...-CUSTOMER-20260522-V2) is DRLOC's own already-bumped V2 tag, which happens to exist
    // specifically because DRLOC's own team found the same "Apply Cust Withhold_DXR" gap documented
    // above and bumped the tag to force a re-run - reusing it here is exactly correct, not a
    // coincidence. All 13 tags below were confirmed to exist as real procedures in
    // DXR_UpgradeTagMgt.Codeunit.al; none needed to be invented.
    //
    // ===== Batch 4 (2026-08-24) - final batch for this codeunit's Phase 2 OnRun-triggered scope =====
    // Registry rows DRLOC-P4 seq34 and DRLOC-P5 seq40/41/42/43/44 are repointed from 60069 to this
    // codeunit, same as Batches 1-3, even though their Concept Code labels say P4/P5 (business-domain
    // categorization only - Cust. Ledger Entry is Sales/P4, the rest are Ledger/P5). The REAL 12
    // source procedures all live in DR-Localization's "DXR_Internal Closure Migration" codeunit and
    // are called unconditionally from "DXR_Migr. Phase 2 Fiscal"'s own OnRun() trigger via
    // InternalClosureMigration.RunOrphanedFieldMigrationsRetroactive() - confirmed by reading that
    // orchestrator's real body (13 calls: ApplicationAreaSetup, BankAccountLedgerEntry,
    // CheckLedgerEntry, CustLedgerEntry_Bulk, CustLedgerEntry_FlowFields, GLEntry, GLRegister,
    // GenJournalLine, ItemLedgerEntry, PriceListLine, ReversalEntry, VendorLedgerEntry_Bulk,
    // VendorLedgerEntry_FlowFields). Since that call happens on every single Phase 2 invocation,
    // before Phase2CompletedTag()'s own gate check, and this codeunit already replicates Phase 2's
    // OnRun() shape (see Batch 1-3 comment above), all 12 of those procedures belong in this same
    // codeunit, not a separate Phase4/Phase5 codeunit (those don't exist yet - they'll be built later
    // for Phase 4/5's own main-line OnRun() logic, a different scope).
    //
    // seq44 naming note: the registry row's description ("... + withholding migration repair") does
    // NOT match RunOrphanedFieldMigrationsRetroactive()'s real call list. The withholding repair call
    // (Codeunit "DXR_Vend. Withhold Migr Repair".Repair(), via TryRepairVendorWithholdingMigration())
    // was found instead inside "DXR_Migr_Phase_5_Ledger.Codeunit.al"'s OWN main-line OnRun() - a
    // different, not-yet-ported codeunit, and NOT part of the orchestrator this batch's scope note
    // binds to. Porting it here would call it unconditionally from every Phase 2 invocation, which
    // does not match real source behavior. It is deliberately NOT ported in this batch; it belongs
    // with the future Phase 5 Ledger port instead.
    //
    // ApplicationAreaSetup gap (seq106, new registry row added this batch, DRLOC-P2/'SETUP'): real
    // MigrateFields_ApplicationAreaSetup() IS called unconditionally from
    // RunOrphanedFieldMigrationsRetroactive() (confirmed, line ~423 of the real source) but had ZERO
    // registry row anywhere in MCC before this batch (confirmed via grep, zero matches) - a genuine
    // untracked gap, not merely a mislabeled one like seq44. Added as its own new row rather than
    // silently dropped, matching this batch's real 13th call.
    //
    // Shadow-field check (2026-08-24, Batch 4): all destination fields for the 12 ledger-entry/
    // journal-line procedures independently verified against DXR_CustLedgerEntryExtDx.TableExt.al,
    // DXR_BankAccountLedgerEntryExt.TableExt.al, DXR_CheckLedgerEntryExt.TableExt.al,
    // DXR_GLEntryExt.TableExt.al, DXR_GLRegisterExt.TableExt.al, DXR_GenJournalLineExt.TableExt.al,
    // DXR_ItemLedgerEntry.TableExt.al, DXR_PriceListLineExt.TableExt.al,
    // DXR_ReversalEntryExt.TableExt.al, DXR_VendorLedgerEntryExt.TableExt.AL - all "_DXR" targets
    // confirmed real, non-obsolete, correct type (including two Option fields, "Withholding Type"/
    // "_DXR" and "DX Withholding Apply Type"/"_DXR", both confirmed identical OptionMembers/order on
    // old and new side, so direct assignment is safe per the Option-is-not-nominally-typed rule
    // already established in Batch 3). ApplicationAreaSetup verified against
    // DXR_ApplicationAreaSetupExt.TableExt.al: found THREE generations of fields on that table (the
    // oldest "Dx..." fields, a MIDDLE "..._DXR"-suffixed generation that is ALSO ObsoleteState =
    // Pending/superseded, and the true final active fields with no separator, e.g.
    // "DextraBusinessCentralDXR") - the real source's own target is correctly the no-separator active
    // field, NOT the "_DXR"-suffixed one (which would have been the natural guess given every other
    // table in this codeunit); ported verbatim to match, with the middle-generation field reset to
    // false exactly as DR-Localization's own DataTransfer.AddConstantValue(false, ...) calls do.
    //
    // No-op observation (matching real source behavior, not a bug - same pattern as the GLAccount
    // no-op above): MigrateFields_CustLedgerEntry_FlowFields()'s "Settled Amount_DXR" and
    // MigrateFields_VendorLedgerEntry_FlowFields()'s "Vendor Name_DXR"/"Settled Amount_DXR" are
    // themselves FlowFields (confirmed against the TableExt sources above) with formulas identical to
    // their source FlowFields - assigning one FlowField's calculated value to another FlowField's
    // in-memory value has no persisted effect (Modify() never writes FlowField columns), so these two
    // ported procedures reproduce DR-Localization's own real no-op exactly as written, without
    // "fixing" it (out of scope - DR-Localization's own source has the same characteristic).
    //
    // Commit() placement (per this task's resilience-gap instruction, same rationale as Batch 2's
    // Item table): periodic Commit() every 100 rows added to the 6 tables explicitly called out as
    // unbounded/transaction-volume-scale - Cust. Ledger Entry (both Bulk and FlowFields scans),
    // Vendor Ledger Entry (both Bulk and FlowFields scans), Bank Account Ledger Entry, Check Ledger
    // Entry, G/L Entry, and Item Ledger Entry. Deliberately NOT added to G/L Register (one row per
    // posting batch/register, not per transaction line - orders of magnitude smaller than G/L Entry),
    // Gen. Journal Line (a staging table for not-yet-posted lines, cleared down as batches post - not
    // an ever-growing history table like the ledger entry tables), Price List Line (bounded by
    // item/price-list catalog size, not transaction volume), Reversal Entry (one row per reversal
    // action, not per line), or Application Area Setup (one row per company) - same size-class
    // reasoning already applied to Batch 2/3's small tables.
    Permissions =
        tabledata "Company Information" = RM,
        tabledata "Bank Account" = RM,
        tabledata Customer = RM,
        tabledata "Customer Templ." = RM,
        tabledata Vendor = RM,
        tabledata "User Setup" = RM,
        tabledata "No. Series Line" = RM,
        tabledata "Gen. Journal Template" = RM,
        tabledata "Gen. Journal Batch" = RM,
        tabledata "Workflow Step Argument" = RM,
        tabledata "VAT Product Posting Group" = RM,
        tabledata "DXFiscal Receipt Types" = R,
        tabledata "DXR_Fiscal Receipt Types" = RIM,
        tabledata "DXNCF Categories" = R,
        tabledata "NCFCategories_DXR" = RIM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RIM,
        tabledata "DXNCF Purchase Setup" = R,
        tabledata "DXR_NCF Purchase Setup" = RIM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RIM,
        tabledata "DXNAV_POS_Customer" = R,
        tabledata "DXR_NAV_POS_Customer" = RIM,
        tabledata "DXExtract Cards" = R,
        tabledata "DXR_Extract Cards" = RIM,
        tabledata "DXGubernamentales(623)" = R,
        tabledata "DXR_Gubernamentales(623)" = RIM,
        tabledata Item = RM,
        tabledata "General Posting Setup" = R,
        tabledata "G/L Account" = RM,
        tabledata "DXPayment Methods 606-607" = R,
        tabledata "DXR_Payment Methods 606-607" = RIM,
        tabledata "DXPurchase Type Relation" = R,
        tabledata "DXR_Purchase Type Relation" = RIM,
        tabledata "DXTender Types Relation" = R,
        tabledata "DXR_Tender Types Relation" = RIM,
        tabledata "DXIncome Types Setup" = R,
        tabledata "DXR_Income Types Setup" = RIM,
        tabledata "DXISR withholding Type" = R,
        tabledata "DXR_ISR withholding Type" = RIM,
        tabledata "DXType of Income" = R,
        tabledata "Type of Income_DXR" = RIM,
        tabledata "DXCustomer Withholding Setup" = R,
        tabledata "DXR_Customer Withholding Setup" = RIM,
        tabledata "DXVendor Withholding Setup" = R,
        tabledata "DXR_Vendor Withholding Setup" = RIM,
        tabledata "DXProporcionality 606" = R,
        tabledata "DXR_Proporcionality 606" = RIM,
        tabledata "DXProporcionality Group 606" = R,
        tabledata "DXR_Proporcionality Group 606" = RIM,
        tabledata "DXPOS-Nav Setup" = R,
        tabledata "DXR_POS-Nav Setup" = RIM,
        tabledata "Application Area Setup" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Bank Account Ledger Entry" = RM,
        tabledata "Check Ledger Entry" = RM,
        tabledata "G/L Entry" = RM,
        tabledata "G/L Register" = RM,
        tabledata "Gen. Journal Line" = RM,
        tabledata "Item Ledger Entry" = RM,
        tabledata "Price List Line" = RM,
        tabledata "Reversal Entry" = RM,
        tabledata "Vendor Ledger Entry" = RM;

    trigger OnRun()
    var
        UpgradeTagMgt: Codeunit "Upgrade Tag";
        PhaseTags: Codeunit "DXR_Internal Migr. Phase Tags";
    begin
        // 2026-08-25 fix: this codeunit had NO top-level completion gate at all (the comment
        // previously here argued an outer tag would be "redundant" since each of the 9 steps below
        // already has its own real per-step tag) - but that meant EVERY invocation of Codeunit.Run()
        // for this dispatcher re-scanned and re-checked all 9 real Phase 2 steps (plus the 7
        // orphaned-field steps below) from scratch, on every single portfolio/category/extension run,
        // forever, since MCC's own executor also can't mark a "Not Row-Based" (0/0 table ID) concept
        // like these Bootstrap steps as Completed (see DXRMCCExecutor's IsDispatcherAlreadyDone). For
        // a company with real data volume, that full unconditional re-scan on every run - combined
        // with normal BC record-lock contention on universally-touched tables like Company
        // Information - is the confirmed root cause of a real, reported production hang ("se queda
        // congelado en Bootstrap Company Information / NCF Sales y no avanza"). Added the exact same
        // outer gate real DR-Localization's own "DXR_Migr. Phase 2 Fiscal" OnRun() uses
        // (Phase2CompletedTag(), reused verbatim, same convention already used for every inner tag in
        // this file) - once a company completes these 9 steps for real once, every subsequent
        // invocation becomes a single tag-check no-op instead of a full re-scan. If a future hotfix
        // ever needs to force ONE step to re-run in isolation after this outer tag is set, comment out
        // this gate temporarily (same technique already used for local debugging elsewhere) rather
        // than clearing the real tag in a live company.
        //
        // Scope of this gate: ONLY the 9 calls below (BootstrapCompanyInformationFields through
        // BootstrapWithholdingPaymentOtherSetupTables) - these are the exact 9 steps real Phase 2's
        // own OnRun() gates with Phase2CompletedTag(). The 7 "orphaned field migration" calls further
        // below stay UNCONDITIONAL/ungated, exactly matching real source's own structure (real
        // RunOrphanedFieldMigrationsRetroactive() is called BEFORE and independently of the
        // Phase2CompletedTag() check - see DXR_Migr_Phase_2_Fiscal.Codeunit.al lines 111-114 - each of
        // those 7 already has its own individual idempotency tag, which is correct/sufficient there).
        if not UpgradeTagMgt.HasUpgradeTag(PhaseTags.Phase2CompletedTag()) then begin
            BootstrapCompanyInformationFields();
            BootstrapBankAccountCustomerVendorFields();
            BootstrapGLUserSetupJournalFields();
            BootstrapNCFSetupTables();
            BootstrapItemNCFCategoryBackfill();
            BootstrapNAVPOSCustomerTable();
            BootstrapExtractCardsTable();
            BootstrapGubernamentales623Table();
            BootstrapWithholdingPaymentOtherSetupTables();
            UpgradeTagMgt.SetUpgradeTag(PhaseTags.Phase2CompletedTag());
        end;

        // Batch 4 (2026-08-24) additions - seq34/40/41/42/43/44 (registry rows labeled DRLOC-P4/
        // DRLOC-P5, but kept in THIS codeunit - see the "Batch 4" section comment below for why) plus
        // the ApplicationAreaSetup gap-fill (seq106, DRLOC-P2). All 7 procedures below are the same
        // ones DR-Localization's own RunOrphanedFieldMigrationsRetroactive() calls unconditionally
        // from "DXR_Migr. Phase 2 Fiscal"'s OnRun(), before that codeunit's own Phase2CompletedTag()
        // gate check - deliberately left OUTSIDE the gate above, matching that same real structure.
        BootstrapApplicationAreaSetupFields();
        BootstrapGLAccountNCFCategory();
        BootstrapCustLedgerEntryFields();
        BootstrapBankAccountCheckLedgerEntryFields();
        BootstrapGLEntryGLRegisterFields();
        BootstrapGenJournalLineItemLedgerEntryFields();
        BootstrapPriceListLineReversalEntryFields();
        BootstrapVendorLedgerEntryFields();
    end;

    procedure RunSetup()
    begin
        BootstrapCompanyInformationFields();
        BootstrapNCFSetupTables();
        BootstrapWithholdingPaymentOtherSetupTables();
        BootstrapApplicationAreaSetupFields();
    end;

    procedure RunMaster()
    begin
        BootstrapBankAccountCustomerVendorFields();
        BootstrapItemNCFCategoryBackfill();
        BootstrapNAVPOSCustomerTable();
        BootstrapExtractCardsTable();
        BootstrapGubernamentales623Table();
        BootstrapGLAccountNCFCategory();
    end;

    procedure RunAccounting()
    begin
        BootstrapGLUserSetupJournalFields();
        BootstrapCustLedgerEntryFields();
        BootstrapBankAccountCheckLedgerEntryFields();
        BootstrapGLEntryGLRegisterFields();
        BootstrapGenJournalLineItemLedgerEntryFields();
        BootstrapPriceListLineReversalEntryFields();
        BootstrapVendorLedgerEntryFields();
    end;

    local procedure BootstrapGLAccountNCFCategory()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        GLAccount: Record "G/L Account";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-DRLOC-GLACCOUNT-NCFCATEGORY-20260825.') then
            exit;

        if GLAccount.FindSet(true) then
            repeat
                if GLAccount."NCFCategories_DXR" <> GLAccount."DXNCF Categories" then begin
                    GLAccount."NCFCategories_DXR" := GLAccount."DXNCF Categories";
                    GLAccount.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until GLAccount.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-MCC-DRLOC-GLACCOUNT-NCFCATEGORY-20260825.');
    end;

    // ===== seq9: Bootstrap: CompanyInformation fields =====
    // Ported from MigrateFields_CompanyInformation_Bulk() (~line 1619) and
    // MigrateFields_CompanyInformation_SpecialConversions() (~line 1636).

    local procedure BootstrapCompanyInformationFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
     //   if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-BULK-20260522') then begin
            MigrateCompanyInformationBulk();
    //        UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-BULK-20260522');
      //  end;

        //if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-SPECIALCONVERSIONS-20260522') then begin
            MigrateCompanyInformationSpecialConversions();
          //  UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-SPECIALCONVERSIONS-20260522');
       // end;
    end;

    // "Company Information" is a single-record table (no key) - Get() with no arguments, exactly
    // as the real source does.
    local procedure MigrateCompanyInformationBulk()
    var
        CompanyInformationRec: Record "Company Information";
    begin
        if not CompanyInformationRec.Get() then
            exit;

        if (CompanyInformationRec."Tax Management_DXR" <> CompanyInformationRec."DxTax Management") or
           (CompanyInformationRec."Position_DXR" <> CompanyInformationRec."DxPosition") then begin
            CompanyInformationRec."Tax Management_DXR" := CompanyInformationRec."DxTax Management";
            CompanyInformationRec."Position_DXR" := CompanyInformationRec."DxPosition";
            CompanyInformationRec.Modify(false);
        end;
    end;

    // BLOB fields - CalcFields required first on the legacy side. Both "DxSignature Picture"/
    // "DxEntity Logo" and their "_DXR" counterparts live on the SAME table ("Company Information"),
    // so a direct typed assignment between BLOB fields of one Record variable is used, exactly as
    // DR-Localization own real source does.
    local procedure MigrateCompanyInformationSpecialConversions()
    var
        CompanyInformationRec: Record "Company Information";
    begin
        if CompanyInformationRec.FindSet(true) then
            repeat
                CompanyInformationRec.CalcFields("DxSignature Picture", "DxEntity Logo");
                CompanyInformationRec."Signature Picture_DXR" := CompanyInformationRec."DxSignature Picture";
                CompanyInformationRec."Entity Logo_DXR" := CompanyInformationRec."DxEntity Logo";
                CompanyInformationRec.Modify(false);
            until CompanyInformationRec.Next() = 0;
    end;

    // ===== seq10: Bootstrap: BankAccount/Customer/Vendor fields =====
    // Ported from MigrateFields_BankAccount() (~line 603), MigrateFields_Customer() (~line 1680),
    // MigrateFields_CustomerTempl() (~line 1736) and MigrateFields_Vendor() (~line 2399, real body
    // of the RunMigrateFields_Vendor() wrapper at ~line 927).

    local procedure BootstrapBankAccountCustomerVendorFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNT-20260522') then begin
            MigrateBankAccountFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNT-20260522');
        end;

        // "-V2" tag - DR-Localization's own real tag, already bumped by DRLOC's team when they added
        // "Apply Cust Withhold_DXR" to this procedure's dirty-check condition (see codeunit-level
        // comment). Reusing it here (not the superseded V1 tag) is required for tenants who ran the
        // migration under DRLOC's real dispatcher after that bump to be correctly recognized as done.
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMER-20260522-V2') then begin
            MigrateCustomerFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMER-20260522-V2');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMERTEMPL-20260522') then begin
            MigrateCustomerTemplFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMERTEMPL-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDOR-20260522') then begin
            MigrateVendorFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDOR-20260522');
        end;
    end;

    local procedure MigrateBankAccountFields()
    var
        BankAccountRec: Record "Bank Account";
    begin
        if BankAccountRec.FindSet(true) then
            repeat
                if (BankAccountRec."Cod. Proveedor Bco._DXR" <> BankAccountRec."DxCod. Proveedor Bco.") or
                   (BankAccountRec."Cargar Estados CSV_DXR" <> BankAccountRec."DxCargar Estados CSV") then begin
                    BankAccountRec."Cod. Proveedor Bco._DXR" := BankAccountRec."DxCod. Proveedor Bco.";
                    BankAccountRec."Cargar Estados CSV_DXR" := BankAccountRec."DxCargar Estados CSV";
                    BankAccountRec.Modify(false);
                end;
            until BankAccountRec.Next() = 0;
    end;

    // Master data - full field-by-field shadow-field verification performed against real
    // DXR_CustomerExt.TableExt.al (all 20 fields confirmed real, non-obsolete, non-FlowField).
    //
    // BUG FIX vs. real source (see codeunit-level comment): DR-Localization own
    // MigrateFields_Customer() checks "Apply Cust Withhold_DXR" in its dirty-check condition but
    // never assigns it. Added the missing assignment here so the ported version is actually
    // correct.
    local procedure MigrateCustomerFields()
    var
        CustomerRec: Record Customer;
    begin
        if CustomerRec.FindSet(true) then
            repeat
                if (CustomerRec."Tipo NCF_DXR" <> CustomerRec."DxTipo NCF") or
                   (CustomerRec."Utiliza NCF_DXR" <> CustomerRec."DxUtiliza NCF") or
                   (CustomerRec."Tipo Identificacion_DXR" <> CustomerRec."DXTipo Identificacion") or
                   (CustomerRec."Razon Social_DXR" <> CustomerRec."DxRazon Social") or
                   (CustomerRec."Nombre Comercial_DXR" <> CustomerRec."DxNombre Comercial") or
                   (CustomerRec."Tipo Negocio_DXR" <> CustomerRec."DxTipo Negocio") or
                   (CustomerRec."Fecha Constitucion_DXR" <> CustomerRec."DxFecha Constitucion") or
                   (CustomerRec."Estatus_DXR" <> CustomerRec."DxEstatus") or
                   (CustomerRec."Fecha Act. DGII_DXR" <> CustomerRec."DxFecha Act. DGII") or
                   (CustomerRec."Tax Identification Type_DXR" <> CustomerRec."DxTax Identification Type") or
                   (CustomerRec."Proveedor Tarjeta Cr._DXR" <> CustomerRec."DxProveedor Tarjeta Cr.") or
                   (CustomerRec."International Customer_DXR" <> CustomerRec."DX International Customer") or
                   (CustomerRec."Uses Withholding_DXR" <> CustomerRec."DX Uses Withholding") or
                   (CustomerRec."Bank Commission_DXR" <> CustomerRec."DX Bank Commission") or
                   (CustomerRec."Cod. Retencion ITBIS_DXR" <> CustomerRec."DXCod. Retencion ITBIS") or
                   (CustomerRec."Cod. Retencion ISR_DXR" <> CustomerRec."DXCod. Retencion ISR") or
                   (CustomerRec."Bank Commission Account_DXR" <> CustomerRec."DX Bank Commission Account") or
                   (CustomerRec."Def ITBIS Withhold_DXR" <> CustomerRec."DXDefault ITBIS Withholding") or
                   (CustomerRec."Default ISR Withholding_DXR" <> CustomerRec."DXDefault ISR Withholding") or
                   (CustomerRec."Apply Cust Withhold_DXR" <> CustomerRec."DX Apply Customer Withholding") then begin
                    CustomerRec."Tipo NCF_DXR" := CustomerRec."DxTipo NCF";
                    CustomerRec."Utiliza NCF_DXR" := CustomerRec."DxUtiliza NCF";
                    CustomerRec."Tipo Identificacion_DXR" := CustomerRec."DXTipo Identificacion";
                    CustomerRec."Razon Social_DXR" := CustomerRec."DxRazon Social";
                    CustomerRec."Nombre Comercial_DXR" := CustomerRec."DxNombre Comercial";
                    CustomerRec."Tipo Negocio_DXR" := CustomerRec."DxTipo Negocio";
                    CustomerRec."Fecha Constitucion_DXR" := CustomerRec."DxFecha Constitucion";
                    CustomerRec."Estatus_DXR" := CustomerRec."DxEstatus";
                    CustomerRec."Fecha Act. DGII_DXR" := CustomerRec."DxFecha Act. DGII";
                    CustomerRec."Tax Identification Type_DXR" := CustomerRec."DxTax Identification Type";
                    CustomerRec."Proveedor Tarjeta Cr._DXR" := CustomerRec."DxProveedor Tarjeta Cr.";
                    CustomerRec."International Customer_DXR" := CustomerRec."DX International Customer";
                    CustomerRec."Uses Withholding_DXR" := CustomerRec."DX Uses Withholding";
                    CustomerRec."Bank Commission_DXR" := CustomerRec."DX Bank Commission";
                    CustomerRec."Cod. Retencion ITBIS_DXR" := CustomerRec."DXCod. Retencion ITBIS";
                    CustomerRec."Cod. Retencion ISR_DXR" := CustomerRec."DXCod. Retencion ISR";
                    CustomerRec."Bank Commission Account_DXR" := CustomerRec."DX Bank Commission Account";
                    CustomerRec."Def ITBIS Withhold_DXR" := CustomerRec."DXDefault ITBIS Withholding";
                    CustomerRec."Default ISR Withholding_DXR" := CustomerRec."DXDefault ISR Withholding";
                    // Explicit conversion required - "Apply Cust Withhold_DXR" (52201) and
                    // "DX Apply Customer Withholding" (54203) are two distinct Enum objects (the
                    // latter Obsolete = Pending, replaced by the former), even though their value
                    // sets are numerically identical (0=" ", 1="On Payment", 2="On Invoice" on both -
                    // confirmed against DXR_ApplyCustomerWithholding.Enum.al and
                    // DXApplyCustomerWithholding.Enum.al). AL does not implicitly convert between
                    // different Enum types on assignment (AL0122), so FromInteger/AsInteger is used.
                    CustomerRec."Apply Cust Withhold_DXR" :=
                        "Apply Cust Withhold_DXR".FromInteger(CustomerRec."DX Apply Customer Withholding".AsInteger());
                    CustomerRec.Modify(false);
                end;
            until CustomerRec.Next() = 0;
    end;

    local procedure MigrateCustomerTemplFields()
    var
        CustomerTemplRec: Record "Customer Templ.";
    begin
        if CustomerTemplRec.FindSet(true) then
            repeat
                if (CustomerTemplRec."Tipo NCF_DXR" <> CustomerTemplRec."DxTipo NCF") or
                   (CustomerTemplRec."Utiliza NCF_DXR" <> CustomerTemplRec."DxUtiliza NCF") then begin
                    CustomerTemplRec."Tipo NCF_DXR" := CustomerTemplRec."DxTipo NCF";
                    CustomerTemplRec."Utiliza NCF_DXR" := CustomerTemplRec."DxUtiliza NCF";
                    CustomerTemplRec.Modify(false);
                end;
            until CustomerTemplRec.Next() = 0;
    end;

    // Master data - full field-by-field shadow-field verification performed against real
    // DXR_VendorExt.TableExt.Al (all 20 fields confirmed real, non-obsolete, non-FlowField).
    local procedure MigrateVendorFields()
    var
        VendorRec: Record Vendor;
    begin
        if VendorRec.FindSet(true) then
            repeat
                if (VendorRec."NCF Interno Proveedor_DXR" <> VendorRec."DXNCF Interno Proveedor") or
                   (VendorRec."Utiliza NCF Externo_DXR" <> VendorRec."DXUtiliza NCF Externo") or
                   (VendorRec."Tipo Identificacion_DXR" <> VendorRec."DXTipo Identificacion") or
                   (VendorRec."Razon Social_DXR" <> VendorRec."DXRazon Social") or
                   (VendorRec."Nombre Comercial_DXR" <> VendorRec."DXNombre Comercial") or
                   (VendorRec."Tipo Negocio_DXR" <> VendorRec."DXTipo Negocio") or
                   (VendorRec."Fecha Constitucion_DXR" <> VendorRec."DXFecha Constitucion") or
                   (VendorRec."Estatus_DXR" <> VendorRec."DXEstatus") or
                   (VendorRec."Fecha Act. DGII_DXR" <> VendorRec."DXFecha Act. DGII") or
                   (VendorRec."Tax Identificaction Type_DXR" <> VendorRec."DXTax Identificaction Type") or
                   (VendorRec."Cod. Retencion ITBIS_DXR" <> VendorRec."DXCod. Retencion ITBIS") or
                   (VendorRec."Cod. Retencion ISR_DXR" <> VendorRec."DXCod. Retencion ISR") or
                   (VendorRec."Proveedor Internacional_DXR" <> VendorRec."DXProveedor Internacional") or
                   (VendorRec."Utiliza Retencion_DXR" <> VendorRec."DXUtiliza Retencion") or
                   (VendorRec."Uses Sel Amount Tip_DXR" <> VendorRec."DXUses Selective Amount Tip") or
                   (VendorRec."Uses Legal Tip_DXR" <> VendorRec."DXUses Legal Tip") or
                   (VendorRec."Uses Other Fees Tip_DXR" <> VendorRec."DXUses Other Fees Tip") or
                   (VendorRec."Parte Relacionada_DXR" <> VendorRec."DxParte Relacionada") or
                   (VendorRec."Reporta 609_DXR" <> VendorRec."DXReporta 609") or
                   (VendorRec."Addtl Currency Code_DXR" <> VendorRec."DX Additional Currency Code") then begin
                    VendorRec."NCF Interno Proveedor_DXR" := VendorRec."DXNCF Interno Proveedor";
                    VendorRec."Utiliza NCF Externo_DXR" := VendorRec."DXUtiliza NCF Externo";
                    VendorRec."Tipo Identificacion_DXR" := VendorRec."DXTipo Identificacion";
                    VendorRec."Razon Social_DXR" := VendorRec."DXRazon Social";
                    VendorRec."Nombre Comercial_DXR" := VendorRec."DXNombre Comercial";
                    VendorRec."Tipo Negocio_DXR" := VendorRec."DXTipo Negocio";
                    VendorRec."Fecha Constitucion_DXR" := VendorRec."DXFecha Constitucion";
                    VendorRec."Estatus_DXR" := VendorRec."DXEstatus";
                    VendorRec."Fecha Act. DGII_DXR" := VendorRec."DXFecha Act. DGII";
                    VendorRec."Tax Identificaction Type_DXR" := VendorRec."DXTax Identificaction Type";
                    VendorRec."Cod. Retencion ITBIS_DXR" := VendorRec."DXCod. Retencion ITBIS";
                    VendorRec."Cod. Retencion ISR_DXR" := VendorRec."DXCod. Retencion ISR";
                    VendorRec."Proveedor Internacional_DXR" := VendorRec."DXProveedor Internacional";
                    VendorRec."Utiliza Retencion_DXR" := VendorRec."DXUtiliza Retencion";
                    VendorRec."Uses Sel Amount Tip_DXR" := VendorRec."DXUses Selective Amount Tip";
                    VendorRec."Uses Legal Tip_DXR" := VendorRec."DXUses Legal Tip";
                    VendorRec."Uses Other Fees Tip_DXR" := VendorRec."DXUses Other Fees Tip";
                    VendorRec."Parte Relacionada_DXR" := VendorRec."DxParte Relacionada";
                    VendorRec."Reporta 609_DXR" := VendorRec."DXReporta 609";
                    VendorRec."Addtl Currency Code_DXR" := VendorRec."DX Additional Currency Code";
                    VendorRec.Modify(false);
                end;
            until VendorRec.Next() = 0;
    end;

    // ===== seq11: Bootstrap: GL/UserSetup/Journal fields =====
    // Ported from MigrateFields_GLAccount() (~line 1753), MigrateFields_UserSetup() (~line 2384),
    // MigrateFields_NoSeriesLine() (~line 1920), MigrateFields_GenJournalTemplate() (~line 1878),
    // MigrateFields_GenJournalBatch() (~line 1798), MigrateFields_WorkflowStepArgument()
    // (~line 2495), MigrateFields_VATProductPostingGroup() (~line 3984).

    local procedure BootstrapGLUserSetupJournalFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // GLAccount is a no-op (see codeunit-level comment) but is still gated by its own real tag
        // for consistency with the other 12 procedures and with DR-Localization's own dispatcher.
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLACCOUNT-20260522') then begin
            MigrateGLAccountFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLACCOUNT-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-USERSETUP-20260522') then begin
            MigrateUserSetupFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-USERSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-NOSERIESLINE-20260522') then begin
            MigrateNoSeriesLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-NOSERIESLINE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALTEMPLATE-20260522') then begin
            MigrateGenJournalTemplateFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALTEMPLATE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALBATCH-20260522') then begin
            MigrateGenJournalBatchFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALBATCH-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-WORKFLOWSTEPARGUMENT-20260522') then begin
            MigrateWorkflowStepArgumentFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-WORKFLOWSTEPARGUMENT-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VATPRODUCTPOSTINGGROUP-20260522') then begin
            MigrateVATProductPostingGroupFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VATPRODUCTPOSTINGGROUP-20260522');
        end;
    end;

    // Deliberate no-op - see codeunit-level comment. Both "DXNCF" and "NCF_DXR" on G/L Account are
    // ObsoleteState = Removed (confirmed against DXR_GLAccountExt.TableExt.al); nothing to migrate.
    local procedure MigrateGLAccountFields()
    begin
    end;

    local procedure MigrateUserSetupFields()
    var
        UserSetupRec: Record "User Setup";
    begin
        if UserSetupRec.FindSet(true) then
            repeat
                if UserSetupRec."Entrega Cheques_DXR" <> UserSetupRec."DXEntrega Cheques" then begin
                    UserSetupRec."Entrega Cheques_DXR" := UserSetupRec."DXEntrega Cheques";
                    UserSetupRec.Modify(false);
                end;
            until UserSetupRec.Next() = 0;
    end;

    local procedure MigrateNoSeriesLineFields()
    var
        NoSeriesLineRec: Record "No. Series Line";
    begin
        if NoSeriesLineRec.FindSet(true) then
            repeat
                if NoSeriesLineRec."Fecha Expiracion NCF_DXR" <> NoSeriesLineRec."DXFecha Expiracion NCF" then begin
                    NoSeriesLineRec."Fecha Expiracion NCF_DXR" := NoSeriesLineRec."DXFecha Expiracion NCF";
                    NoSeriesLineRec.Modify(false);
                end;
            until NoSeriesLineRec.Next() = 0;
    end;

    local procedure MigrateGenJournalTemplateFields()
    var
        GenJournalTemplateRec: Record "Gen. Journal Template";
    begin
        if GenJournalTemplateRec.FindSet(true) then
            repeat
                if GenJournalTemplateRec."Cash Recpt. Report ID_DXR" <> GenJournalTemplateRec."Cash Recpt. Report ID" then begin
                    GenJournalTemplateRec."Cash Recpt. Report ID_DXR" := GenJournalTemplateRec."Cash Recpt. Report ID";
                    GenJournalTemplateRec.Modify(false);
                end;
            until GenJournalTemplateRec.Next() = 0;
    end;

    local procedure MigrateGenJournalBatchFields()
    var
        GenJournalBatchRec: Record "Gen. Journal Batch";
    begin
        if GenJournalBatchRec.FindSet(true) then
            repeat
                if (GenJournalBatchRec."Recibo Ingreso_DXR" <> GenJournalBatchRec."DXRecibo Ingreso") or
                   (GenJournalBatchRec."Diario de cheques_DXR" <> GenJournalBatchRec."DXDiario de cheques") then begin
                    GenJournalBatchRec."Recibo Ingreso_DXR" := GenJournalBatchRec."DXRecibo Ingreso";
                    GenJournalBatchRec."Diario de cheques_DXR" := GenJournalBatchRec."DXDiario de cheques";
                    GenJournalBatchRec.Modify(false);
                end;
            until GenJournalBatchRec.Next() = 0;
    end;

    local procedure MigrateWorkflowStepArgumentFields()
    var
        WorkflowStepArgumentRec: Record "Workflow Step Argument";
    begin
        if WorkflowStepArgumentRec.FindSet(true) then
            repeat
                if WorkflowStepArgumentRec."Due Invoice Option_DXR" <> WorkflowStepArgumentRec."DX Due Invoice Option" then begin
                    WorkflowStepArgumentRec."Due Invoice Option_DXR" := WorkflowStepArgumentRec."DX Due Invoice Option";
                    WorkflowStepArgumentRec.Modify(false);
                end;
            until WorkflowStepArgumentRec.Next() = 0;
    end;

    local procedure MigrateVATProductPostingGroupFields()
    var
        VATProductPostingGroupRec: Record "VAT Product Posting Group";
    begin
        if VATProductPostingGroupRec.FindSet(true) then
            repeat
                if (VATProductPostingGroupRec."Taken To Cost_DXR" <> VATProductPostingGroupRec."DX Taken To Cost") or
                   (VATProductPostingGroupRec."Proportionality_DXR" <> VATProductPostingGroupRec."DX Proportionality") then begin
                    VATProductPostingGroupRec."Taken To Cost_DXR" := VATProductPostingGroupRec."DX Taken To Cost";
                    VATProductPostingGroupRec."Proportionality_DXR" := VATProductPostingGroupRec."DX Proportionality";
                    VATProductPostingGroupRec.Modify(false);
                end;
            until VATProductPostingGroupRec.Next() = 0;
    end;

    // ===== seq12: Bootstrap: NCF Setup tables =====
    // Ported from MigrateTable_FiscalReceiptTypes() (~line 3258), MigrateTable_NCFCategories()
    // (~line 3532), MigrateTable_NCFSetup() (~line 3581), MigrateTable_NCFPurchaseSetup()
    // (~line 3550) and MigrateTable_NCFSalesSetup() (~line 3568), all in
    // DXR_Internal_Closure_Migration_Upgrade_Clean.al. All 5 are whole-table CLONES in DR-
    // Localization own source (unlike Batch 1's field-group procedures) and DR-Localization own
    // code uses NewRec.TransferFields(OldRec, true) for every one of them - each is expanded below
    // into explicit, per-field typed assignment (TransferFields is banned plan-wide in this MCC
    // project). Bundled under one registry concept (seq12, same bundling pattern as seq9/10/11),
    // but each of the 5 sub-procedures still gates on its OWN real DR-Localization completion tag
    // (UpgradeTagInternalClosureTable<X>() in DXR_UpgradeTagMgt.Codeunit.al), same convention as
    // Batch 1's per-procedure tag reuse.
    //
    // NCF Setup investigation (2026-08-24, this task - required before writing MigrateNCFSetupTable
    // below): "DXR_NCF Setup" (52179) already has THREE independent, pre-existing migration
    // mechanisms in this MCC repo (all confirmed via source):
    //   1) DXRMCCBellonMigrPhase2.Codeunit.al MigrateTableExt_DXNCFSetupFields() - same-table
    //      bridge, copies "Grupo Contable BS"/"Legal Tip %" into "Grupo Contable BS_DXR"/
    //      "Legal Tip %_DXR" (all four fields live on "DXR_NCF Setup" itself).
    //   2) DXRMCCBellonMigrPhase11.Codeunit.al MigrateNCFSetupOldCrossTable() - cross-table bridge,
    //      copies the SAME two target fields, but reads the source values off the LEGACY "DXNCF
    //      Setup" table instead ("Grupo Contable BS"/"Legal Tip %" on the old table).
    //   3) DXRMCCBellonMigrPhase13.Codeunit.al - intermediate "_Old" bridge, copies
    //      "Grupo Contable BS_Old"/"Legal Tip %_Old" (also on "DXR_NCF Setup" itself) into the same
    //      two "_DXR" targets.
    // All three existing mechanisms exclusively target "Grupo Contable BS_DXR"/"Legal Tip %_DXR" -
    // two fields that do NOT exist anywhere in DR-Localization's own repo (confirmed by grepping
    // DR-Localization's full source tree for both names: zero matches in either
    // Tables.old/DXNCFSetup.Table.al or Base/Tables/DXR_NCFSetup.Table.al). They are purely
    // BELLON-added tableextension fields layered on top of DR-Localization's "DXNCF Setup"/
    // "DXR_NCF Setup". MigrateNCFSetupTable() below instead ports DR-Localization's OWN 92
    // base-table fields (94 total minus the 2 Removed fields below; the real schema DR-Localization
    // itself declares on both tables) - a
    // completely disjoint field set from all three existing mechanisms; it never reads or writes
    // "Grupo Contable BS_DXR"/"Legal Tip %_DXR"/either "_Old" or legacy-tableextension counterpart.
    // This confirms MigrateNCFSetupTable() is a genuine 4th, independent/complementary mechanism
    // for this same physical table pair, matching this plan's established "multiple independent
    // fill-gap mechanisms for messy tenant history" precedent for this exact table - it is ported
    // here unmerged/unmodified, per this task's instructions (do NOT merge/simplify/skip it).
    //
    // Two fields on "DXNCF Setup"/"DXR_NCF Setup" are ObsoleteState = Removed on BOTH the old and
    // new side ("Prepayment Acct. Credit Card", "Use Additional Currency" - confirmed against both
    // real table sources) - referencing a Removed field is a compile error (AL0499), so both are
    // deliberately excluded entirely from MigrateNCFSetupTable() below; every other field (including
    // several marked ObsoleteState = Pending on one or both sides, which remain both readable and
    // writable - e.g. "Allow NCF 32 in Consumer 607", "CR Customer Withholding",
    // "EnableCustomerWithholdings", "EnableBankCommission", "Bank Commission Account") is copied,
    // matching DR-Localization's own TransferFields(OldRec, true) behavior (Pending is not a
    // migration blocker, only Removed is).
    local procedure BootstrapNCFSetupTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-FISCALRECEIPTTYPES-20260522') then begin
            MigrateFiscalReceiptTypesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-FISCALRECEIPTTYPES-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFCATEGORIES-20260522') then begin
            MigrateNCFCategoriesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFCATEGORIES-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSETUP-20260522') then begin
            MigrateNCFSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFPURCHASESETUP-20260522') then begin
            MigrateNCFPurchaseSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFPURCHASESETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSALESSETUP-20260522') then begin
            MigrateNCFSalesSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSALESSETUP-20260522');
        end;
    end;

    local procedure MigrateFiscalReceiptTypesTable()
    var
        FiscalReceiptTypesOld: Record "DXFiscal Receipt Types";
        FiscalReceiptTypesNew: Record "DXR_Fiscal Receipt Types";
    begin
        if FiscalReceiptTypesOld.IsEmpty() then
            exit;
        if FiscalReceiptTypesOld.FindSet() then
            repeat
                FiscalReceiptTypesNew."Code" := FiscalReceiptTypesOld."Code";
                FiscalReceiptTypesNew.Description := FiscalReceiptTypesOld.Description;
                FiscalReceiptTypesNew."Comprobante Electronico" := FiscalReceiptTypesOld."Comprobante Electronico";
                if not FiscalReceiptTypesNew.Insert(false) then
                    FiscalReceiptTypesNew.Modify(false);
            until FiscalReceiptTypesOld.Next() = 0;
    end;

    local procedure MigrateNCFCategoriesTable()
    var
        NCFCategoriesOld: Record "DXNCF Categories";
        NCFCategoriesNew: Record "NCFCategories_DXR";
    begin
        if NCFCategoriesOld.IsEmpty() then
            exit;
        if NCFCategoriesOld.FindSet() then
            repeat
                NCFCategoriesNew."DXCodigo" := NCFCategoriesOld."DXCodigo";
                NCFCategoriesNew."DXDescripcion" := NCFCategoriesOld."DXDescripcion";
                if not NCFCategoriesNew.Insert(false) then
                    NCFCategoriesNew.Modify(false);
            until NCFCategoriesOld.Next() = 0;
    end;

    // 92-field whole-table clone (see codeunit-level "NCF Setup investigation" comment above for
    // the field-count/Removed-field rationale). Field order below matches the real table
    // declaration order in Base/Tables/DXR_NCFSetup.Table.al / Tables.old/DXNCFSetup.Table.al.
    local procedure MigrateNCFSetupTable()
    var
        NCFSetupOld: Record "DXNCF Setup";
        NCFSetupNew: Record "DXR_NCF Setup";
    begin
        if NCFSetupOld.IsEmpty() then
            exit;
        if NCFSetupOld.FindSet() then
            repeat
                NCFSetupNew."Primary Key" := NCFSetupOld."Primary Key";
                NCFSetupNew."Control Dígitos NCF" := NCFSetupOld."Control Dígitos NCF";
                NCFSetupNew."Funcionalidad NCF" := NCFSetupOld."Funcionalidad NCF";
                NCFSetupNew."N/C Ventas ITBIS +30 dias" := NCFSetupOld."N/C Ventas ITBIS +30 dias";
                NCFSetupNew."Directorio Archivo ITBIS (607)" := NCFSetupOld."Directorio Archivo ITBIS (607)";
                NCFSetupNew."Libro Diario Cargos Banc." := NCFSetupOld."Libro Diario Cargos Banc.";
                NCFSetupNew."Seccion Diario Cargos Banc." := NCFSetupOld."Seccion Diario Cargos Banc.";
                NCFSetupNew."No. Series Cargo Banc." := NCFSetupOld."No. Series Cargo Banc.";
                NCFSetupNew."Codigo Audit. Cargos Banc." := NCFSetupOld."Codigo Audit. Cargos Banc.";
                NCFSetupNew."Cta. Gastos Cargos Banc." := NCFSetupOld."Cta. Gastos Cargos Banc.";
                NCFSetupNew."Cta. Gastos Cargos Tarjetas Cr" := NCFSetupOld."Cta. Gastos Cargos Tarjetas Cr";
                NCFSetupNew."Cta. ITBIS Cargos Tarjetas Cr" := NCFSetupOld."Cta. ITBIS Cargos Tarjetas Cr";
                NCFSetupNew."Libro Diario Cargos Tarj. Cr." := NCFSetupOld."Libro Diario Cargos Tarj. Cr.";
                NCFSetupNew."Seccion Diario Cargos Tarj. Cr" := NCFSetupOld."Seccion Diario Cargos Tarj. Cr";
                NCFSetupNew."No. Series Cargos Tarj. Cr." := NCFSetupOld."No. Series Cargos Tarj. Cr.";
                NCFSetupNew."Codigo Audit. Cargos Tarj. Cr." := NCFSetupOld."Codigo Audit. Cargos Tarj. Cr.";
                NCFSetupNew."No. Series Ret. Gubernamental" := NCFSetupOld."No. Series Ret. Gubernamental";
                NCFSetupNew."Cta. Ret. Gubernamental" := NCFSetupOld."Cta. Ret. Gubernamental";
                NCFSetupNew."Cod. Audit. Ret. Gubernamental" := NCFSetupOld."Cod. Audit. Ret. Gubernamental";
                NCFSetupNew."Libro Diario Ret. Gub." := NCFSetupOld."Libro Diario Ret. Gub.";
                NCFSetupNew."Seccion Diario Ret. Gub." := NCFSetupOld."Seccion Diario Ret. Gub.";
                NCFSetupNew."Directorio Archivo ITBIS (606)" := NCFSetupOld."Directorio Archivo ITBIS (606)";
                NCFSetupNew."Fecha Cierre" := NCFSetupOld."Fecha Cierre";
                NCFSetupNew."Directorio Ret. Guber623" := NCFSetupOld."Directorio Ret. Guber623";
                NCFSetupNew."Directorio Pagos Supl. Inter." := NCFSetupOld."Directorio Pagos Supl. Inter.";
                NCFSetupNew."Cod. Audit. Pagos Supl. inter." := NCFSetupOld."Cod. Audit. Pagos Supl. inter.";
                NCFSetupNew."RNC Oblig. en Proveedores" := NCFSetupOld."RNC Oblig. en Proveedores";
                NCFSetupNew."RNC Oblig. en Clientes" := NCFSetupOld."RNC Oblig. en Clientes";
                NCFSetupNew."Cat. NCF Oblig. en Cuentas" := NCFSetupOld."Cat. NCF Oblig. en Cuentas";
                NCFSetupNew."No. Serie Regist. Cargo Banc." := NCFSetupOld."No. Serie Regist. Cargo Banc.";
                NCFSetupNew."No. Serie Regist. C. Tarj. Cr." := NCFSetupOld."No. Serie Regist. C. Tarj. Cr.";
                NCFSetupNew."Libro Diario Ret. Proveedor" := NCFSetupOld."Libro Diario Ret. Proveedor";
                NCFSetupNew."Seccion Diario Ret. Proveedor" := NCFSetupOld."Seccion Diario Ret. Proveedor";
                NCFSetupNew."No. Serie Ret. Proveedor" := NCFSetupOld."No. Serie Ret. Proveedor";
                NCFSetupNew."No. Serie Regist. Ret. Gub." := NCFSetupOld."No. Serie Regist. Ret. Gub.";
                NCFSetupNew."Libro Diario Productos" := NCFSetupOld."Libro Diario Productos";
                NCFSetupNew."Seccion Diario Productos" := NCFSetupOld."Seccion Diario Productos";
                NCFSetupNew."Codigo Almacen Diario" := NCFSetupOld."Codigo Almacen Diario";
                NCFSetupNew."NCF Ventas" := NCFSetupOld."NCF Ventas";
                NCFSetupNew."Recibo de Ingreso" := NCFSetupOld."Recibo de Ingreso";
                NCFSetupNew."NCF Punto de Venta" := NCFSetupOld."NCF Punto de Venta";
                NCFSetupNew."Cargos Bancario" := NCFSetupOld."Cargos Bancario";
                NCFSetupNew.Cheques := NCFSetupOld.Cheques;
                NCFSetupNew."Cargos Tarjetas de Credito" := NCFSetupOld."Cargos Tarjetas de Credito";
                NCFSetupNew."Retenciones Gubernamentales" := NCFSetupOld."Retenciones Gubernamentales";
                NCFSetupNew."NCF Compras" := NCFSetupOld."NCF Compras";
                NCFSetupNew."Impresora Fiscal" := NCFSetupOld."Impresora Fiscal";
                NCFSetupNew."Block posting in zero prices" := NCFSetupOld."Block posting in zero prices";
                NCFSetupNew."Impedir Precio Cero POS" := NCFSetupOld."Impedir Precio Cero POS";
                NCFSetupNew."Exempt group" := NCFSetupOld."Exempt group";
                NCFSetupNew."Exempt Product group" := NCFSetupOld."Exempt Product group";
                NCFSetupNew."Keep Original VAT Reg. No." := NCFSetupOld."Keep Original VAT Reg. No.";
                // "Tax Rule" and "Grupo Contable Prop." are plain (non-Enum) Option fields on both
                // tables, with identical OptionMembers/order on each side - AL permits direct
                // cross-record Option field assignment (unlike Enum, Option is not nominally typed).
                NCFSetupNew."Tax Rule" := NCFSetupOld."Tax Rule";
                NCFSetupNew."Max Amount without RNC/Cedula" := NCFSetupOld."Max Amount without RNC/Cedula";
                // ObsoleteState = Pending on both sides (still readable/writable) - copied per
                // TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."Allow NCF 32 in Consumer 607" := NCFSetupOld."Allow NCF 32 in Consumer 607";
                NCFSetupNew."Fiscal Controls" := NCFSetupOld."Fiscal Controls";
                NCFSetupNew."POS Transactions in 607" := NCFSetupOld."POS Transactions in 607";
                NCFSetupNew."Grupo Contable Prop." := NCFSetupOld."Grupo Contable Prop.";
                NCFSetupNew."Funcionalidad e-CF" := NCFSetupOld."Funcionalidad e-CF";
                NCFSetupNew."Digitos e-CF" := NCFSetupOld."Digitos e-CF";
                NCFSetupNew."Use Localization DR" := NCFSetupOld."Use Localization DR";
                NCFSetupNew."NCF Debit Note" := NCFSetupOld."NCF Debit Note";
                NCFSetupNew."No. Serie NDB" := NCFSetupOld."No. Serie NDB";
                NCFSetupNew."Libro Diario Ret. Customer" := NCFSetupOld."Libro Diario Ret. Customer";
                NCFSetupNew."Seccion Diario Ret. Customer" := NCFSetupOld."Seccion Diario Ret. Customer";
                NCFSetupNew."No. Serie Ret. Customer" := NCFSetupOld."No. Serie Ret. Customer";
                NCFSetupNew."Other Feeds Percentage" := NCFSetupOld."Other Feeds Percentage";
                // "Prepayment Acct. Credit Card" (36002767/36002768) is skipped deliberately -
                // ObsoleteState = Removed on BOTH old and new tables (referencing it is AL0499).
                NCFSetupNew."Loan Acct. Credit Card" := NCFSetupOld."Loan Acct. Credit Card";
                // "Use Additional Currency" (36002769) is skipped deliberately - ObsoleteState =
                // Removed on BOTH old and new tables (referencing it is AL0499).
                NCFSetupNew."Directorio Archivo (609)" := NCFSetupOld."Directorio Archivo (609)";
                NCFSetupNew."Allow Diff. Margen Legal Tip" := NCFSetupOld."Allow Diff. Margen Legal Tip";
                NCFSetupNew."Check Cust.A.NCF Ledg. Entries" := NCFSetupOld."Check Cust.A.NCF Ledg. Entries";
                NCFSetupNew."VAT Bus. ITBIS For Advance" := NCFSetupOld."VAT Bus. ITBIS For Advance";
                NCFSetupNew.PrintNCFindCheck := NCFSetupOld.PrintNCFindCheck;
                NCFSetupNew."Fixed Asset NCF" := NCFSetupOld."Fixed Asset NCF";
                NCFSetupNew."VAT Bus. ITBIS Taken To Cost" := NCFSetupOld."VAT Bus. ITBIS Taken To Cost";
                NCFSetupNew."Uses Electronic Invoice" := NCFSetupOld."Uses Electronic Invoice";
                NCFSetupNew."Purchase NCF Debit Note" := NCFSetupOld."Purchase NCF Debit Note";
                NCFSetupNew."Purchase No. Series NDP" := NCFSetupOld."Purchase No. Series NDP";
                NCFSetupNew."Report 606 on vend header DXR" := NCFSetupOld."Report 606 on vend header DXR";
                NCFSetupNew."Show Withholdings Info" := NCFSetupOld."Show Withholdings Info";
                NCFSetupNew."Show Additional Amounts" := NCFSetupOld."Show Additional Amounts";
                NCFSetupNew."Show Cust. Withholding Fields" := NCFSetupOld."Show Cust. Withholding Fields";
                NCFSetupNew."Show Settled Amount" := NCFSetupOld."Show Settled Amount";
                // ObsoleteState = Pending on both sides (still readable/writable) - copied per
                // TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."EnableCustomerWithholdings" := NCFSetupOld."EnableCustomerWithholdings";
                NCFSetupNew."EnableBankCommission" := NCFSetupOld."EnableBankCommission";
                NCFSetupNew."Bank Commission Account" := NCFSetupOld."Bank Commission Account";
                NCFSetupNew."Allow Edit Taxes in Cr. Memo" := NCFSetupOld."Allow Edit Taxes in Cr. Memo";
                NCFSetupNew."Enable Customer Withholdings" := NCFSetupOld."Enable Customer Withholdings";
                // ObsoleteState = Pending on the NEW side only (still readable/writable) - copied
                // per TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."CR Customer Withholding" := NCFSetupOld."CR Customer Withholding";
                NCFSetupNew."Enable CR Bank Commission" := NCFSetupOld."Enable CR Bank Commission";
                NCFSetupNew."Bank Fee G/L Account" := NCFSetupOld."Bank Fee G/L Account";
                NCFSetupNew."No. Serie Cash Receipt Doc" := NCFSetupOld."No. Serie Cash Receipt Doc";
                if not NCFSetupNew.Insert(false) then
                    NCFSetupNew.Modify(false);
            until NCFSetupOld.Next() = 0;
    end;

    local procedure MigrateNCFPurchaseSetupTable()
    var
        NCFPurchaseSetupOld: Record "DXNCF Purchase Setup";
        NCFPurchaseSetupNew: Record "DXR_NCF Purchase Setup";
    begin
        if NCFPurchaseSetupOld.IsEmpty() then
            exit;
        if NCFPurchaseSetupOld.FindSet() then
            repeat
                NCFPurchaseSetupNew."DXCodigo" := NCFPurchaseSetupOld."DXCodigo";
                NCFPurchaseSetupNew."DXDescripcion" := NCFPurchaseSetupOld."DXDescripcion";
                NCFPurchaseSetupNew."No. Serie NCF Fact." := NCFPurchaseSetupOld."No. Serie NCF Fact.";
                NCFPurchaseSetupNew."No. Serie NCF Abono" := NCFPurchaseSetupOld."No. Serie NCF Abono";
                NCFPurchaseSetupNew."Tipo NCF" := NCFPurchaseSetupOld."Tipo NCF";
                NCFPurchaseSetupNew."DXAuto ECF34 Internal Cr. Memo" := NCFPurchaseSetupOld."DXAuto ECF34 Internal Cr. Memo";
                if not NCFPurchaseSetupNew.Insert(false) then
                    NCFPurchaseSetupNew.Modify(false);
            until NCFPurchaseSetupOld.Next() = 0;
    end;

    // Real source has no IsEmpty() guard for this one table (unlike its 4 siblings above/below) -
    // ported exactly as-is (FindSet() on an empty table simply returns false, so behavior is
    // identical either way; kept faithful to source rather than "improving" it).
    local procedure MigrateNCFSalesSetupTable()
    var
        NCFSalesSetupOld: Record "DXNCF Sales Setup";
        NCFSalesSetupNew: Record "DXR_NCF Sales Setup";
    begin
        if NCFSalesSetupOld.FindSet() then
            repeat
                NCFSalesSetupNew."Codigo" := NCFSalesSetupOld."Codigo";
                NCFSalesSetupNew."Descripcion" := NCFSalesSetupOld."Descripcion";
                NCFSalesSetupNew."No. Serie NCF Fact." := NCFSalesSetupOld."No. Serie NCF Fact.";
                NCFSalesSetupNew."No. Serie NCF NCR" := NCFSalesSetupOld."No. Serie NCF NCR";
                // Explicit conversion required - "Tipo Doc. Fiscal" is a different Enum object on
                // each table ("DXR_Fiscal Doc. Type" vs. legacy "DX Fiscal Doc. Type"), even though
                // both enums share the identical 11-value set (0..10, same names/order in the same
                // order - confirmed against Base/Enums/DXR_FiscalDocType.enum.al and
                // Base/Enums.old/DXFiscalDocType.enum.al). AL does not implicitly convert between
                // different Enum types on assignment (AL0122), so FromInteger/AsInteger is used
                // (same pattern as Batch 1's Customer "Apply Cust Withhold_DXR" conversion).
                NCFSalesSetupNew."Tipo Doc. Fiscal" :=
                    Enum::"DXR_Fiscal Doc. Type".FromInteger(NCFSalesSetupOld."Tipo Doc. Fiscal".AsInteger());
                NCFSalesSetupNew."Tipo NCF" := NCFSalesSetupOld."Tipo NCF";
                if not NCFSalesSetupNew.Insert(false) then
                    NCFSalesSetupNew.Modify(false);
            until NCFSalesSetupOld.Next() = 0;
    end;

    // ===== seq14: Item NCF Category backfill (V27 data) =====
    // Ported from TryRunItemNCFCategoryBackfill() / MigrateItemNCFCategoryInBatches()
    // (DXR_Migr_Phase_2_Fiscal.Codeunit.al, ~line 289 / ~line 403). The real source runs inside a
    // checkpoint/batch-commit loop (StatusMgt.GetCheckpoint/SaveCheckpoint/ClearCheckpoint,
    // Commit() every ProductBatchSize() rows) purely for TaskScheduler-background resilience on
    // very large Item tables; the full checkpoint/resume infrastructure (StatusMgt checkpoint
    // key/resume-from-last-item) is DR-Localization-internal plumbing, not migrated business
    // logic, so it is NOT ported here - that would be a bigger architectural change than this
    // task warrants. However, DR-Localization's own periodic Commit() (every ProductBatchSize(),
    // 100 rows) IS ported below (same 100-row batch size), because the entry points that reach
    // this procedure ("Run Concept" on this registry row, "Run Extension" on DRLOC - both via
    // DXRMCCExecutor.Codeunit.al ScheduleConcept/ScheduleExtension) run synchronously in the
    // caller's own web-client session, not through MCC's background TaskScheduler path (see
    // DXRMCCExecutor.Codeunit.al's own documented real-world failure of exactly this per-row-loop-
    // over-a-large-table shape, ~line 476-486/546-556). Without periodic commits, (a) a tenant
    // with a large Item table risks reproducing that same session-timeout failure, and (b) a
    // mid-run failure would lose 100% of progress (the UpgradeTag is only set once the whole loop
    // completes), forcing every retry to restart from the first Item - strictly worse resilience
    // than DR-Localization's own original design for this one table. Periodic Commit() alone (no
    // resume-from-checkpoint) fixes both: each transaction stays bounded in size, and a retry
    // after a mid-run failure re-scans from the first Item but is cheap and safe to repeat because
    // this procedure's own dirty-check ("NCF Category_DXR" <> NCFCategory) already skips any Item
    // whose value is already correct from a prior partial run.
    // TryGetItemNcfCategory() (DXR_LocalizationFiscalMgt.Codeunit.al, ~line 1559) is inlined below
    // as TryGetItemNcfCategoryLocal() rather than calling into DR-Localization's own codeunit, for
    // the same "typed, self-contained" reason as every other procedure in this file. The real
    // caller always passes a blank GenBusPostingGroup argument (see MigrateItemNCFCategoryInBatches
    // calling TryGetItemNcfCategory(Item, '', NCFCategory)), so the GenBusPostingGroup parameter and
    // its associated filter branch (never exercised for this specific call site) are omitted here.
    local procedure BootstrapItemNCFCategoryBackfill()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DXR-T20260716-BackfillItemNCFCategory') then begin
            MigrateItemNCFCategoryBackfill();
            UpgradeTag.SetUpgradeTag('DXR-T20260716-BackfillItemNCFCategory');
        end;
    end;

    local procedure MigrateItemNCFCategoryBackfill()
    var
        Item: Record Item;
        NCFCategory: Code[20];
        BatchCount: Integer;
    begin
        // Periodic Commit() every 100 rows (matching DR-Localization's own ProductBatchSize()) -
        // see the codeunit-level comment above BootstrapItemNCFCategoryBackfill() for why this is
        // required here even without the full checkpoint/resume machinery.
        if Item.FindSet(true) then
            repeat
                if TryGetItemNcfCategoryLocal(Item, NCFCategory) and (Item."NCF Category_DXR" <> NCFCategory) then begin
                    Item."NCF Category_DXR" := NCFCategory;
                    Item.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Item.Next() = 0;
    end;

    local procedure TryGetItemNcfCategoryLocal(Item: Record Item; var NCFCategory: Code[20]): Boolean
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        Clear(NCFCategory);
        if Item."Gen. Prod. Posting Group" = '' then
            exit(false);

        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                if GLAccount.Get(GeneralPostingSetup."Purch. Account") and (GLAccount."NCFCategories_DXR" <> '') then begin
                    NCFCategory := GLAccount."NCFCategories_DXR";
                    exit(true);
                end;
            until GeneralPostingSetup.Next() = 0;

        exit(false);
    end;

    // ===== seq16: NAV POS Customer legacy table restore (54128 -> 52175) =====
    // Ported from MigrateTable_NAVPOSCustomer() (~line 3490). Whole-table clone in DR-Localization
    // own source, using NewRec.TransferFields(OldRec, true) - expanded below into explicit,
    // per-field typed assignment (TransferFields is banned plan-wide in this MCC project). Real
    // source also has a fast-path branch using "DXR_Background Data Transfer"
    // (AddFieldValue/CopyRows) when the new table is still empty; that branch is intentionally NOT
    // ported (Global Constraint: zero-RecordRef/zero-FieldRef/zero-TransferFields plan-wide -
    // DataTransfer's AddFieldValue/CopyRows operate on the same field-number-matching mechanism
    // internally). The always-manual typed loop below (the real source's OWN fallback branch, used
    // when the new table already has data) is used unconditionally instead - functionally
    // equivalent, just without the bulk-copy performance optimization for a first-time run against
    // an empty target on a very large legacy table.
    local procedure BootstrapNAVPOSCustomerTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NAVPOSCUSTOMER-20260522') then begin
            MigrateNAVPOSCustomerTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NAVPOSCUSTOMER-20260522');
        end;
    end;

    local procedure MigrateNAVPOSCustomerTable()
    var
        NAVPOSCustomerOld: Record "DXNAV_POS_Customer";
        NAVPOSCustomerNew: Record "DXR_NAV_POS_Customer";
    begin
        if NAVPOSCustomerOld.IsEmpty() then
            exit;
        if NAVPOSCustomerOld.FindSet() then
            repeat
                NAVPOSCustomerNew.No := NAVPOSCustomerOld.No;
                NAVPOSCustomerNew.CodCliePOS := NAVPOSCustomerOld.CodCliePOS;
                NAVPOSCustomerNew.Name := NAVPOSCustomerOld.Name;
                NAVPOSCustomerNew.Address := NAVPOSCustomerOld.Address;
                NAVPOSCustomerNew.City := NAVPOSCustomerOld.City;
                NAVPOSCustomerNew.PhoneNo := NAVPOSCustomerOld.PhoneNo;
                NAVPOSCustomerNew.BalanceDue := NAVPOSCustomerOld.BalanceDue;
                NAVPOSCustomerNew.CreditLimit := NAVPOSCustomerOld.CreditLimit;
                NAVPOSCustomerNew.Document := NAVPOSCustomerOld.Document;
                NAVPOSCustomerNew.PaymentTermsCode := NAVPOSCustomerOld.PaymentTermsCode;
                NAVPOSCustomerNew.CustomerPostingGroup := NAVPOSCustomerOld.CustomerPostingGroup;
                NAVPOSCustomerNew.ForCheckBankCode := NAVPOSCustomerOld.ForCheckBankCode;
                NAVPOSCustomerNew.ForCheckBankAccountNo := NAVPOSCustomerOld.ForCheckBankAccountNo;
                NAVPOSCustomerNew.ForCheckLimit := NAVPOSCustomerOld.ForCheckLimit;
                NAVPOSCustomerNew.ForCheckStatus := NAVPOSCustomerOld.ForCheckStatus;
                NAVPOSCustomerNew.CorpClientCode := NAVPOSCustomerOld.CorpClientCode;
                NAVPOSCustomerNew.CorpBalance := NAVPOSCustomerOld.CorpBalance;
                NAVPOSCustomerNew.PayrollNo := NAVPOSCustomerOld.PayrollNo;
                NAVPOSCustomerNew.PayrollPostingDate := NAVPOSCustomerOld.PayrollPostingDate;
                if not NAVPOSCustomerNew.Insert(false) then
                    NAVPOSCustomerNew.Modify(false);
            until NAVPOSCustomerOld.Next() = 0;
    end;

    // ===== seq17: Extract Cards legacy table restore (54120 -> 52160) =====
    // Ported from MigrateTable_ExtractCards() (~line 3222). Same shape/reasoning as
    // MigrateNAVPOSCustomerTable() above (whole-table clone, TransferFields expanded per-field,
    // DataTransfer fast-path branch intentionally not ported).
    local procedure BootstrapExtractCardsTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-EXTRACTCARDS-20260522') then begin
            MigrateExtractCardsTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-EXTRACTCARDS-20260522');
        end;
    end;

    local procedure MigrateExtractCardsTable()
    var
        ExtractCardsOld: Record "DXExtract Cards";
        ExtractCardsNew: Record "DXR_Extract Cards";
    begin
        if ExtractCardsOld.IsEmpty() then
            exit;
        if ExtractCardsOld.FindSet() then
            repeat
                ExtractCardsNew."Cuenta Banco" := ExtractCardsOld."Cuenta Banco";
                ExtractCardsNew."Fecha Posteo" := ExtractCardsOld."Fecha Posteo";
                ExtractCardsNew."No Referencia" := ExtractCardsOld."No Referencia";
                ExtractCardsNew."Monto Transaccion" := ExtractCardsOld."Monto Transaccion";
                ExtractCardsNew.Credito := ExtractCardsOld.Credito;
                ExtractCardsNew.Debito := ExtractCardsOld.Debito;
                ExtractCardsNew.Peaje := ExtractCardsOld.Peaje;
                ExtractCardsNew.Descripcion := ExtractCardsOld.Descripcion;
                ExtractCardsNew."No. Afiliado" := ExtractCardsOld."No. Afiliado";
                ExtractCardsNew.NCF := ExtractCardsOld.NCF;
                ExtractCardsNew."Ind Peaje" := ExtractCardsOld."Ind Peaje";
                ExtractCardsNew."No. Lote" := ExtractCardsOld."No. Lote";
                ExtractCardsNew.Estacion := ExtractCardsOld.Estacion;
                if not ExtractCardsNew.Insert(false) then
                    ExtractCardsNew.Modify(false);
            until ExtractCardsOld.Next() = 0;
    end;

    // ===== seq18: Gubernamentales(623) legacy table restore (54155 -> 52220) =====
    // Ported from MigrateTable_Gubernamentales623() (~line 3294). Whole-table clone, TransferFields
    // expanded per-field. Real source has no IsEmpty() guard for this one table either (same as
    // MigrateNCFSalesSetupTable() above) - ported exactly as-is.
    local procedure BootstrapGubernamentales623Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-GUBERNAMENTALES623-20260522') then begin
            MigrateGubernamentales623Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-GUBERNAMENTALES623-20260522');
        end;
    end;

    local procedure MigrateGubernamentales623Table()
    var
        Gubernamentales623Old: Record "DXGubernamentales(623)";
        Gubernamentales623New: Record "DXR_Gubernamentales(623)";
    begin
        if Gubernamentales623Old.FindSet() then
            repeat
                Gubernamentales623New."No." := Gubernamentales623Old."No.";
                Gubernamentales623New."No. Linea" := Gubernamentales623Old."No. Linea";
                Gubernamentales623New."Cod. Cliente" := Gubernamentales623Old."Cod. Cliente";
                Gubernamentales623New."Nombre Cliente" := Gubernamentales623Old."Nombre Cliente";
                Gubernamentales623New.RNC := Gubernamentales623Old.RNC;
                Gubernamentales623New."Fecha Registro" := Gubernamentales623Old."Fecha Registro";
                Gubernamentales623New."Fecha Retencion" := Gubernamentales623Old."Fecha Retencion";
                Gubernamentales623New."No. Referencia" := Gubernamentales623Old."No. Referencia";
                // Explicit conversion required - different Enum objects (DXR_TipoReferencia623 vs.
                // legacy DXTipoReferencia623), identical 3-value set (0=" ", 1=Transferencia,
                // 2=Cheque - confirmed against Base/Enums/DXR_TipoReferencia623.Enum.al and
                // Base/Enums.old/DXTipoReferencia623.Enum.al).
                Gubernamentales623New."Tipo Referencia" :=
                    Enum::"DXR_TipoReferencia623".FromInteger(Gubernamentales623Old."Tipo Referencia".AsInteger());
                Gubernamentales623New."Valor Retencion" := Gubernamentales623Old."Valor Retencion";
                Gubernamentales623New."Nombre Banco" := Gubernamentales623Old."Nombre Banco";
                Gubernamentales623New.Periodo := Gubernamentales623Old.Periodo;
                if not Gubernamentales623New.Insert(false) then
                    Gubernamentales623New.Modify(false);
            until Gubernamentales623Old.Next() = 0;
    end;

    // ===== seq54-64: Withholding/Payment/Other setup tables legacy table restore (11 registry rows) =====
    // Ported from MigrateTable_PaymentMethods606607() (~line 3617), MigrateTable_PurchaseTypeRelation()
    // (~line 3744), MigrateTable_TenderTypesRelation() (~line 3795), MigrateTable_IncomeTypesSetup()
    // (~line 3307), MigrateTable_ISRwithholdingType() (~line 3325), MigrateTable_TypeofIncome()
    // (~line 3813), MigrateTable_CustomerWithholdingSetup() (~line 3143),
    // MigrateTable_VendorWithholdingSetup() (~line 3871), MigrateTable_Proporcionality606()
    // (~line 3666), MigrateTable_ProporcionalityGroup606() (~line 3684) and MigrateTable_POSNavSetup()
    // (~line 3648), all in DXR_Internal_Closure_Migration_Upgrade_Clean.al. All 11 are whole-table
    // CLONES in DR-Localization own source, each using NewRec.TransferFields(OldRec, true) - expanded
    // below into explicit, per-field typed assignment (TransferFields is banned plan-wide in this MCC
    // project). Bundled under one orchestrator (matching seq9/10/11/12's own bundling pattern), but
    // each of the 11 sub-procedures still gates on its OWN real DR-Localization completion tag
    // (UpgradeTagInternalClosureTable<X>() in DXR_UpgradeTagMgt.Codeunit.al).
    //
    // Shadow-field check (this task): every destination field in all 11 procedures below was
    // independently verified against the real table pair (src/Tables.old/DX<Name>.Table.al vs.
    // src/Base/Tables/DXR_<Name>.Table.al in DR-Localization's own repo) - field-by-field, including
    // types, so no FlowField/BLOB/AutoIncrement field is silently mis-copied. Two real findings from
    // that check:
    //   1) "DXIncome Types Setup"/"DXR_Income Types Setup" (seq57) - fields "Description" (2) and
    //      "Account Description" (4) are FlowFields (CalcFormula lookups) on BOTH old and new tables,
    //      not stored data. TransferFields never copies FlowFields either (only stored fields), so
    //      MigrateIncomeTypesSetupTable() below only copies the two real stored fields ("Code",
    //      "Income Account"); this matches DR-Localization's own TransferFields(OldRec, true)
    //      behavior exactly, not a gap introduced by this port.
    //   2) "DXCustomer Withholding Setup"/"DXVendor Withholding Setup" (seq60/seq61) - real source
    //      copies field 54100 explicitly (DXRCustomerWithholdingSetupNew."DXR_ISR withholding Type" :=
    //      DXCustomerWithholdingSetupOld."DXISR withholding Type") in ADDITION to TransferFields,
    //      because the field was renamed ("DXISR withholding Type" -> "DXR_ISR withholding Type").
    //      TransferFields actually matches by field NUMBER; the explicit semantic assignment from
    //      the real source is retained so this renamed pair is auditable and does not depend on that
    //      numeric behavior.
    // No AutoIncrement or BLOB fields exist on any of the 11 old/new table pairs (confirmed against
    // every real table source read for this task) - no special handling needed beyond ordinary typed
    // assignment.
    //
    // No field-level Enum/Option type mismatch requiring FromInteger/AsInteger conversion exists in
    // this batch (unlike Batch 1's Customer/seq10 and Batch 2's NCFSalesSetup/Gubernamentales623/
    // seq12/seq18) - the two Option fields present ("Tipo" on PurchaseTypeRelation/
    // CustomerWithholdingSetup/VendorWithholdingSetup) have identical OptionMembers/order on both old
    // and new tables, and Option (unlike Enum) is not a nominally-typed AL object, so direct
    // cross-record assignment compiles and behaves correctly.
    //
    // Commit() placement (per this task's resilience-gap instruction, see Batch 2's Item table fix):
    // none of these 11 tables get a periodic Commit(). All are small setup/master-data registries
    // (payment method codes, withholding-type codes, proportionality percentage-by-period rows,
    // single-record POS-Nav Setup, etc.) with realistically at most dozens to low hundreds of rows in
    // production - the same size class as Batch 2's FiscalReceiptTypes/NCFCategories/NCFPurchaseSetup/
    // NCFSalesSetup/NAVPOSCustomer/ExtractCards/Gubernamentales623 (none of which got a Commit()
    // either); only Item (a genuinely large master-data table) warranted one. A single uncommitted
    // transaction across a table this size does not reproduce the large-synchronous-loop timeout shape
    // documented in DXRMCCExecutor.Codeunit.al.
    //
    // IsEmpty() guard fidelity: ported exactly as DR-Localization's own source does per table -
    // PaymentMethods606607/TenderTypesRelation/IncomeTypesSetup/ISRwithholdingType/TypeofIncome/
    // CustomerWithholdingSetup/VendorWithholdingSetup/Proporcionality606/ProporcionalityGroup606/
    // POSNavSetup all have a real source IsEmpty() guard (kept below); PurchaseTypeRelation's real
    // source has NO IsEmpty() guard (same faithful-to-source choice already established for
    // MigrateNCFSalesSetupTable()/MigrateGubernamentales623Table() above) - kept exactly as-is.
    local procedure BootstrapWithholdingPaymentOtherSetupTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PAYMENTMETHODS606607-20260522') then begin
            MigratePaymentMethods606607Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PAYMENTMETHODS606607-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASETYPERELATION-20260522') then begin
            MigratePurchaseTypeRelationTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASETYPERELATION-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-TENDERTYPESRELATION-20260522') then begin
            MigrateTenderTypesRelationTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-TENDERTYPESRELATION-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-INCOMETYPESSETUP-20260522') then begin
            MigrateIncomeTypesSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-INCOMETYPESSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ISRWITHHOLDINGTYPE-20260522') then begin
            MigrateISRwithholdingTypeTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ISRWITHHOLDINGTYPE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-TYPEOFINCOME-20260522') then begin
            MigrateTypeofIncomeTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-TYPEOFINCOME-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CUSTOMERWITHHOLDINGSETUP-20260522') then begin
            MigrateCustomerWithholdingSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CUSTOMERWITHHOLDINGSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-VENDORWITHHOLDINGSETUP-20260522') then begin
            MigrateVendorWithholdingSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-VENDORWITHHOLDINGSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITY606-20260522') then begin
            MigrateProporcionality606Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITY606-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITYGROUP606-20260522') then begin
            MigrateProporcionalityGroup606Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PROPORCIONALITYGROUP606-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-POSNAVSETUP-20260522') then begin
            MigratePOSNavSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-POSNAVSETUP-20260522');
        end;
    end;

    // seq54: Payment Methods 606-607 legacy table restore (54134 -> 52181)
    local procedure MigratePaymentMethods606607Table()
    var
        PaymentMethods606607Old: Record "DXPayment Methods 606-607";
        PaymentMethods606607New: Record "DXR_Payment Methods 606-607";
    begin
        if PaymentMethods606607Old.IsEmpty() then
            exit;
        if PaymentMethods606607Old.FindSet() then
            repeat
                PaymentMethods606607New."Code" := PaymentMethods606607Old."Code";
                PaymentMethods606607New.Description := PaymentMethods606607Old.Description;
                if not PaymentMethods606607New.Insert(false) then
                    PaymentMethods606607New.Modify(false);
            until PaymentMethods606607Old.Next() = 0;
    end;

    // seq55: Purchase Type Relation legacy table restore (54140 -> 52242). Real source has no
    // IsEmpty() guard for this one table (same faithful-to-source choice as
    // MigrateNCFSalesSetupTable()/MigrateGubernamentales623Table() above) - ported exactly as-is.
    //
    // INSERT-ONLY, NOT upsert (2026-08-25 fix, found during Phase 6 Batch 4 review): table 52242 is
    // ALSO written by Phase 6's own seq91 (codeunit 60170, MigratePurchaseTypeRelationV27(), source
    // table 54167 "DX Purchase Type Relation" - the NEWER/successor generation of this same data,
    // confirmed via 54140's own real ObsoleteReason chain: "...replaced by Table 54167..."). MCC's
    // executor runs dispatchers by ascending Sequence No.; codeunit 60170 owns seq50 (< this
    // codeunit's seq54/55), so 60170's newer-generation write ALWAYS lands first on any fresh run.
    // The original upsert (Insert-or-Modify) would let this OLDER-generation write silently clobber
    // the newer-generation value on any "Grupo Contable Prod." key present in both legacy sources
    // with a different Tipo - backwards from the intended newer-generation-is-authoritative semantics,
    // fully deterministic, and invisible to MCC's own row-count-based gap detection. Changed to
    // insert-only (skip existing rows entirely) so this older generation only fills gaps the newer
    // generation's write didn't already cover, regardless of future execution-order changes.
    local procedure MigratePurchaseTypeRelationTable()
    var
        PurchaseTypeRelationOld: Record "DXPurchase Type Relation";
        PurchaseTypeRelationNew: Record "DXR_Purchase Type Relation";
    begin
        if PurchaseTypeRelationOld.FindSet() then
            repeat
                if not PurchaseTypeRelationNew.Get(PurchaseTypeRelationOld."Grupo Contable Prod.") then begin
                    PurchaseTypeRelationNew.Init();
                    PurchaseTypeRelationNew."Grupo Contable Prod." := PurchaseTypeRelationOld."Grupo Contable Prod.";
                    // "Tipo" is a plain (non-Enum) Option field on both tables, with identical
                    // OptionMembers/order (" ",Bienes,Servicios) - AL permits direct cross-record
                    // Option field assignment (unlike Enum, Option is not nominally typed).
                    PurchaseTypeRelationNew.Tipo := PurchaseTypeRelationOld.Tipo;
                    PurchaseTypeRelationNew.Insert(false);
                end;
            until PurchaseTypeRelationOld.Next() = 0;
    end;

    // seq56: Tender Types Relation legacy table restore (54142 -> 52198)
    local procedure MigrateTenderTypesRelationTable()
    var
        TenderTypesRelationOld: Record "DXTender Types Relation";
        TenderTypesRelationNew: Record "DXR_Tender Types Relation";
    begin
        if TenderTypesRelationOld.IsEmpty() then
            exit;
        if TenderTypesRelationOld.FindSet() then
            repeat
                TenderTypesRelationNew."Code" := TenderTypesRelationOld."Code";
                TenderTypesRelationNew.Description := TenderTypesRelationOld.Description;
                if not TenderTypesRelationNew.Insert(false) then
                    TenderTypesRelationNew.Modify(false);
            until TenderTypesRelationOld.Next() = 0;
    end;

    // seq57: Income Types Setup legacy table restore (54123 -> 52166). "Description" (2) and
    // "Account Description" (4) are FlowFields on both tables (see codeunit-level shadow-field
    // comment above) - not copied, matching TransferFields(OldRec, true) behavior (FlowFields are
    // never stored/copied).
    local procedure MigrateIncomeTypesSetupTable()
    var
        IncomeTypesSetupOld: Record "DXIncome Types Setup";
        IncomeTypesSetupNew: Record "DXR_Income Types Setup";
    begin
        if IncomeTypesSetupOld.IsEmpty() then
            exit;
        if IncomeTypesSetupOld.FindSet() then
            repeat
                IncomeTypesSetupNew."Code" := IncomeTypesSetupOld."Code";
                IncomeTypesSetupNew."Income Account" := IncomeTypesSetupOld."Income Account";
                if not IncomeTypesSetupNew.Insert(false) then
                    IncomeTypesSetupNew.Modify(false);
            until IncomeTypesSetupOld.Next() = 0;
    end;

    // seq58: ISR withholding Type legacy table restore (54124 -> 52167)
    local procedure MigrateISRwithholdingTypeTable()
    var
        ISRwithholdingTypeOld: Record "DXISR withholding Type";
        ISRwithholdingTypeNew: Record "DXR_ISR withholding Type";
    begin
        if ISRwithholdingTypeOld.IsEmpty() then
            exit;
        if ISRwithholdingTypeOld.FindSet() then
            repeat
                ISRwithholdingTypeNew."Code" := ISRwithholdingTypeOld."Code";
                ISRwithholdingTypeNew.Description := ISRwithholdingTypeOld.Description;
                if not ISRwithholdingTypeNew.Insert(false) then
                    ISRwithholdingTypeNew.Modify(false);
            until ISRwithholdingTypeOld.Next() = 0;
    end;

    // seq59: Type of Income legacy table restore (54143 -> 52200). Target table's real AL object
    // name is "Type of Income_DXR" (a "_DXR"-suffix name, not the usual "DXR_"-prefix convention used
    // by every other table in this batch) - confirmed against DR-Localization's own
    // Base/Tables/DXR_TypeOfIncome.Table.al; not a field rename, just this one table's own naming
    // convention.
    local procedure MigrateTypeofIncomeTable()
    var
        TypeofIncomeOld: Record "DXType of Income";
        TypeofIncomeNew: Record "Type of Income_DXR";
    begin
        if TypeofIncomeOld.IsEmpty() then
            exit;
        if TypeofIncomeOld.FindSet() then
            repeat
                TypeofIncomeNew."Code" := TypeofIncomeOld."Code";
                TypeofIncomeNew.Description := TypeofIncomeOld.Description;
                if not TypeofIncomeNew.Insert(false) then
                    TypeofIncomeNew.Modify(false);
            until TypeofIncomeOld.Next() = 0;
    end;

    // seq60: Customer Withholding Setup legacy table restore (54118 -> 52152). Field 54100 was
    // renamed ("DXISR withholding Type" -> "DXR_ISR withholding Type"), so it is copied via an
    // explicit assignment below (see codeunit-level shadow-field comment above) - matching DR-
    // Localization's own real source exactly.
    local procedure MigrateCustomerWithholdingSetupTable()
    var
        CustomerWithholdingSetupOld: Record "DXCustomer Withholding Setup";
        CustomerWithholdingSetupNew: Record "DXR_Customer Withholding Setup";
    begin
        if CustomerWithholdingSetupOld.IsEmpty() then
            exit;
        if CustomerWithholdingSetupOld.FindSet() then
            repeat
                CustomerWithholdingSetupNew.Codigo := CustomerWithholdingSetupOld.Codigo;
                CustomerWithholdingSetupNew.Descripcion := CustomerWithholdingSetupOld.Descripcion;
                CustomerWithholdingSetupNew.Norma := CustomerWithholdingSetupOld.Norma;
                CustomerWithholdingSetupNew."%Retencion" := CustomerWithholdingSetupOld."%Retencion";
                // "Tipo" is a plain (non-Enum) Option field on both tables, identical OptionMembers
                // (" ",ITBIS,ISR) - direct cross-record Option field assignment.
                CustomerWithholdingSetupNew.Tipo := CustomerWithholdingSetupOld.Tipo;
                CustomerWithholdingSetupNew."Cta. Retencion" := CustomerWithholdingSetupOld."Cta. Retencion";
                CustomerWithholdingSetupNew."Cod. Auditoria" := CustomerWithholdingSetupOld."Cod. Auditoria";
                CustomerWithholdingSetupNew."DXR_ISR withholding Type" := CustomerWithholdingSetupOld."DXISR withholding Type";
                if not CustomerWithholdingSetupNew.Insert(false) then
                    CustomerWithholdingSetupNew.Modify(false);
            until CustomerWithholdingSetupOld.Next() = 0;
    end;

    // seq61: Vendor Withholding Setup legacy table restore (54146 -> 52205). Same field-54100 rename
    // as MigrateCustomerWithholdingSetupTable() above - explicit copy kept for the same reason.
    local procedure MigrateVendorWithholdingSetupTable()
    var
        VendorWithholdingSetupOld: Record "DXVendor Withholding Setup";
        VendorWithholdingSetupNew: Record "DXR_Vendor Withholding Setup";
    begin
        if VendorWithholdingSetupOld.IsEmpty() then
            exit;
        if VendorWithholdingSetupOld.FindSet() then
            repeat
                VendorWithholdingSetupNew.Codigo := VendorWithholdingSetupOld.Codigo;
                VendorWithholdingSetupNew.Descripcion := VendorWithholdingSetupOld.Descripcion;
                VendorWithholdingSetupNew.Norma := VendorWithholdingSetupOld.Norma;
                VendorWithholdingSetupNew."%Retencion" := VendorWithholdingSetupOld."%Retencion";
                // "Tipo" is a plain (non-Enum) Option field on both tables, identical OptionMembers
                // (" ",ITBIS,ISR) - direct cross-record Option field assignment.
                VendorWithholdingSetupNew.Tipo := VendorWithholdingSetupOld.Tipo;
                VendorWithholdingSetupNew."Cta. Retencion" := VendorWithholdingSetupOld."Cta. Retencion";
                VendorWithholdingSetupNew."Cod. Auditoria" := VendorWithholdingSetupOld."Cod. Auditoria";
                VendorWithholdingSetupNew."DXR_ISR withholding Type" := VendorWithholdingSetupOld."DXISR withholding Type";
                if not VendorWithholdingSetupNew.Insert(false) then
                    VendorWithholdingSetupNew.Modify(false);
            until VendorWithholdingSetupOld.Next() = 0;
    end;

    // seq62: Proporcionality 606 legacy table restore (54137 -> 52188)
    local procedure MigrateProporcionality606Table()
    var
        Proporcionality606Old: Record "DXProporcionality 606";
        Proporcionality606New: Record "DXR_Proporcionality 606";
    begin
        if Proporcionality606Old.IsEmpty() then
            exit;
        if Proporcionality606Old.FindSet() then
            repeat
                Proporcionality606New.Periodo := Proporcionality606Old.Periodo;
                Proporcionality606New."% Proporcionalidad" := Proporcionality606Old."% Proporcionalidad";
                Proporcionality606New.Fecha := Proporcionality606Old.Fecha;
                Proporcionality606New."Taxed Amount" := Proporcionality606Old."Taxed Amount";
                Proporcionality606New."Exempt Amount" := Proporcionality606Old."Exempt Amount";
                Proporcionality606New."User Id" := Proporcionality606Old."User Id";
                if not Proporcionality606New.Insert(false) then
                    Proporcionality606New.Modify(false);
            until Proporcionality606Old.Next() = 0;
    end;

    // seq63: Proporcionality Group 606 legacy table restore (54138 -> 52191)
    local procedure MigrateProporcionalityGroup606Table()
    var
        ProporcionalityGroup606Old: Record "DXProporcionality Group 606";
        ProporcionalityGroup606New: Record "DXR_Proporcionality Group 606";
    begin
        if ProporcionalityGroup606Old.IsEmpty() then
            exit;
        if ProporcionalityGroup606Old.FindSet() then
            repeat
                ProporcionalityGroup606New."Codigo Grupo" := ProporcionalityGroup606Old."Codigo Grupo";
                ProporcionalityGroup606New.Excluir := ProporcionalityGroup606Old.Excluir;
                if not ProporcionalityGroup606New.Insert(false) then
                    ProporcionalityGroup606New.Modify(false);
            until ProporcionalityGroup606Old.Next() = 0;
    end;

    // seq64: POS-Nav Setup legacy table restore (54136 -> 52185)
    local procedure MigratePOSNavSetupTable()
    var
        POSNavSetupOld: Record "DXPOS-Nav Setup";
        POSNavSetupNew: Record "DXR_POS-Nav Setup";
    begin
        if POSNavSetupOld.IsEmpty() then
            exit;
        if POSNavSetupOld.FindSet() then
            repeat
                POSNavSetupNew."Primary Key" := POSNavSetupOld."Primary Key";
                POSNavSetupNew."Payroll Journal Template Name" := POSNavSetupOld."Payroll Journal Template Name";
                POSNavSetupNew."Payroll Journal Batch Name" := POSNavSetupOld."Payroll Journal Batch Name";
                POSNavSetupNew."Auto Register Payroll Entries" := POSNavSetupOld."Auto Register Payroll Entries";
                POSNavSetupNew."Payroll Global Dim. 1 Code" := POSNavSetupOld."Payroll Global Dim. 1 Code";
                POSNavSetupNew."Payroll Global Dim. 2 Code" := POSNavSetupOld."Payroll Global Dim. 2 Code";
                POSNavSetupNew."Payroll Cust. Posting Group" := POSNavSetupOld."Payroll Cust. Posting Group";
                if not POSNavSetupNew.Insert(false) then
                    POSNavSetupNew.Modify(false);
            until POSNavSetupOld.Next() = 0;
    end;

    // ===== Batch 4: ApplicationAreaSetup gap-fill (seq106) =====
    // Ported from MigrateFields_ApplicationAreaSetup() (~line 1541). Real source uses
    // "DXR_Background Data Transfer" (AddFieldValue/AddConstantValue/CopyFields) - expanded below
    // into explicit typed assignment (Global Constraint: zero-RecordRef/zero-FieldRef/
    // zero-TransferFields plan-wide), same pattern already used for BootstrapNAVPOSCustomerTable's
    // real DataTransfer fast path. See codeunit-level comment above for the three-generation shadow-
    // field finding on this table.
    local procedure BootstrapApplicationAreaSetupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-APPLICATIONAREASETUP-20260522') then begin
            MigrateApplicationAreaSetupFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-APPLICATIONAREASETUP-20260522');
        end;
    end;

    local procedure MigrateApplicationAreaSetupFields()
    var
        ApplicationAreaSetupRec: Record "Application Area Setup";
    begin
        if ApplicationAreaSetupRec.FindSet(true) then
            repeat
                if (ApplicationAreaSetupRec.DextraBusinessCentralDXR <> ApplicationAreaSetupRec."DxDextra Business Central") or
                   (ApplicationAreaSetupRec.DextraLSCentralDXR <> ApplicationAreaSetupRec."DxDextra LS Central") or
                   (ApplicationAreaSetupRec.DextraEmptyLabelsDXR <> ApplicationAreaSetupRec."DxDextra Empty Labels") or
                   ApplicationAreaSetupRec."Dextra Business Central_DXR" or
                   ApplicationAreaSetupRec."Dextra LS Central_DXR" or
                   ApplicationAreaSetupRec."Dextra Empty Labels_DXR" then begin
                    ApplicationAreaSetupRec.DextraBusinessCentralDXR := ApplicationAreaSetupRec."DxDextra Business Central";
                    ApplicationAreaSetupRec.DextraLSCentralDXR := ApplicationAreaSetupRec."DxDextra LS Central";
                    ApplicationAreaSetupRec.DextraEmptyLabelsDXR := ApplicationAreaSetupRec."DxDextra Empty Labels";
                    // Real source resets these obsolete middle-generation fields to constant false
                    // via DataTransfer.AddConstantValue(false, ...) - preserved verbatim.
                    ApplicationAreaSetupRec."Dextra Business Central_DXR" := false;
                    ApplicationAreaSetupRec."Dextra LS Central_DXR" := false;
                    ApplicationAreaSetupRec."Dextra Empty Labels_DXR" := false;
                    ApplicationAreaSetupRec.Modify(false);
                end;
            until ApplicationAreaSetupRec.Next() = 0;
    end;

    // ===== Batch 4, seq34: Cust. Ledger Entry field restore (bulk + FlowFields) =====
    // Ported from MigrateFields_CustLedgerEntry_Bulk() (~line 1649) and
    // MigrateFields_CustLedgerEntry_FlowFields() (~line 1666). "Settled Amount_DXR" is itself a
    // FlowField with a formula identical to the source "DX Settled Amount" FlowField - see
    // codeunit-level "No-op observation" comment (ported verbatim, not fixed).
    local procedure BootstrapCustLedgerEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTLEDGERENTRY-BULK-20260522') then begin
            MigrateCustLedgerEntryBulkFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTLEDGERENTRY-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTLEDGERENTRY-FLOWFIELDS-20260522') then begin
            MigrateCustLedgerEntryFlowFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTLEDGERENTRY-FLOWFIELDS-20260522');
        end;
    end;

    // Cust. Ledger Entry is transaction-volume-scale (unbounded) - periodic Commit() every 100 rows.
    local procedure MigrateCustLedgerEntryBulkFields()
    var
        CustLedgerEntryRec: Record "Cust. Ledger Entry";
        BatchCount: Integer;
    begin
        if CustLedgerEntryRec.FindSet(true) then
            repeat
                if (CustLedgerEntryRec."NCF_DXR" <> CustLedgerEntryRec."DXNCF") or
                   (CustLedgerEntryRec."Reporta en 607_DXR" <> CustLedgerEntryRec."DXReporta en 607") or
                   (CustLedgerEntryRec."Withholding Payment_DXR" <> CustLedgerEntryRec."Dx Withholding Payment") then begin
                    CustLedgerEntryRec."NCF_DXR" := CustLedgerEntryRec."DXNCF";
                    CustLedgerEntryRec."Reporta en 607_DXR" := CustLedgerEntryRec."DXReporta en 607";
                    CustLedgerEntryRec."Withholding Payment_DXR" := CustLedgerEntryRec."Dx Withholding Payment";
                    CustLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until CustLedgerEntryRec.Next() = 0;
    end;

    local procedure MigrateCustLedgerEntryFlowFields()
    var
        CustLedgerEntryRec: Record "Cust. Ledger Entry";
        BatchCount: Integer;
    begin
        CustLedgerEntryRec.SetAutoCalcFields("DX Settled Amount");
        if CustLedgerEntryRec.FindSet(true) then
            repeat
                if CustLedgerEntryRec."Settled Amount_DXR" <> CustLedgerEntryRec."DX Settled Amount" then begin
                    CustLedgerEntryRec."Settled Amount_DXR" := CustLedgerEntryRec."DX Settled Amount";
                    CustLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until CustLedgerEntryRec.Next() = 0;
    end;

    // ===== Batch 4, seq40: Bank Account/Check Ledger Entry field restore =====
    // Ported from MigrateFields_BankAccountLedgerEntry() (~line 1573) and
    // MigrateFields_CheckLedgerEntry() (~line 1598). Both tables are transaction-volume-scale
    // (unbounded) - periodic Commit() every 100 rows on each.
    local procedure BootstrapBankAccountCheckLedgerEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNTLEDGERENTRY-20260522') then begin
            MigrateBankAccountLedgerEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNTLEDGERENTRY-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CHECKLEDGERENTRY-20260522') then begin
            MigrateCheckLedgerEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CHECKLEDGERENTRY-20260522');
        end;
    end;

    local procedure MigrateBankAccountLedgerEntryFields()
    var
        BankAccountLedgerEntryRec: Record "Bank Account Ledger Entry";
        BatchCount: Integer;
    begin
        if BankAccountLedgerEntryRec.FindSet(true) then
            repeat
                if (BankAccountLedgerEntryRec."Beneficiario_DXR" <> BankAccountLedgerEntryRec."DxBeneficiario") or
                   (BankAccountLedgerEntryRec."Recibo Ingreso_DXR" <> BankAccountLedgerEntryRec."DxRecibo Ingreso") or
                   (BankAccountLedgerEntryRec."Importe Efectivo_DXR" <> BankAccountLedgerEntryRec."DxImporte Efectivo") or
                   (BankAccountLedgerEntryRec."Importe Tcr._DXR" <> BankAccountLedgerEntryRec."DxImporte Tcr.") or
                   (BankAccountLedgerEntryRec."Importe Cheque_DXR" <> BankAccountLedgerEntryRec."DxImporte Cheque") or
                   (BankAccountLedgerEntryRec."Importe Transf._DXR" <> BankAccountLedgerEntryRec."DxImporte Transf.") or
                   (BankAccountLedgerEntryRec."Provider_DXR" <> BankAccountLedgerEntryRec."DxProvider") then begin
                    BankAccountLedgerEntryRec."Beneficiario_DXR" := BankAccountLedgerEntryRec."DxBeneficiario";
                    BankAccountLedgerEntryRec."Recibo Ingreso_DXR" := BankAccountLedgerEntryRec."DxRecibo Ingreso";
                    BankAccountLedgerEntryRec."Importe Efectivo_DXR" := BankAccountLedgerEntryRec."DxImporte Efectivo";
                    BankAccountLedgerEntryRec."Importe Tcr._DXR" := BankAccountLedgerEntryRec."DxImporte Tcr.";
                    BankAccountLedgerEntryRec."Importe Cheque_DXR" := BankAccountLedgerEntryRec."DxImporte Cheque";
                    BankAccountLedgerEntryRec."Importe Transf._DXR" := BankAccountLedgerEntryRec."DxImporte Transf.";
                    BankAccountLedgerEntryRec."Provider_DXR" := BankAccountLedgerEntryRec."DxProvider";
                    BankAccountLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until BankAccountLedgerEntryRec.Next() = 0;
    end;

    local procedure MigrateCheckLedgerEntryFields()
    var
        CheckLedgerEntryRec: Record "Check Ledger Entry";
        BatchCount: Integer;
    begin
        if CheckLedgerEntryRec.FindSet(true) then
            repeat
                if (CheckLedgerEntryRec."Beneficiario_DXR" <> CheckLedgerEntryRec."DxBeneficiario") or
                   (CheckLedgerEntryRec."Entregado_DXR" <> CheckLedgerEntryRec."DxEntregado") or
                   (CheckLedgerEntryRec."Fecha Entrega_DXR" <> CheckLedgerEntryRec."DxFecha Entrega") or
                   (CheckLedgerEntryRec."Usuario entrega_DXR" <> CheckLedgerEntryRec."DxUsuario entrega") or
                   (CheckLedgerEntryRec."Check Concept_DXR" <> CheckLedgerEntryRec."DX Check Concept") then begin
                    CheckLedgerEntryRec."Beneficiario_DXR" := CheckLedgerEntryRec."DxBeneficiario";
                    CheckLedgerEntryRec."Entregado_DXR" := CheckLedgerEntryRec."DxEntregado";
                    CheckLedgerEntryRec."Fecha Entrega_DXR" := CheckLedgerEntryRec."DxFecha Entrega";
                    CheckLedgerEntryRec."Usuario entrega_DXR" := CheckLedgerEntryRec."DxUsuario entrega";
                    CheckLedgerEntryRec."Check Concept_DXR" := CheckLedgerEntryRec."DX Check Concept";
                    CheckLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until CheckLedgerEntryRec.Next() = 0;
    end;

    // ===== Batch 4, seq41: G/L Entry/G/L Register field restore =====
    // Ported from MigrateFields_GLEntry() (~line 1760) and MigrateFields_GLRegister() (~line 1785).
    // G/L Entry is transaction-volume-scale (unbounded) - periodic Commit() every 100 rows. G/L
    // Register is one row per posting batch/register (orders of magnitude smaller) - no Commit().
    local procedure BootstrapGLEntryGLRegisterFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // "-V2" tag - DR-Localization's own real tag, already bumped when they added
        // "NCFCategories_DXR" to this procedure's dirty-check condition. Reusing it here (not the
        // superseded V1 tag) is required for tenants who ran the migration under DRLOC's real
        // dispatcher after that bump to be correctly recognized as done.
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLENTRY-20260522-V2') then begin
            MigrateGLEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLENTRY-20260522-V2');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLREGISTER-20260522') then begin
            MigrateGLRegisterFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLREGISTER-20260522');
        end;
    end;

    local procedure MigrateGLEntryFields()
    var
        GLEntryRec: Record "G/L Entry";
        BatchCount: Integer;
    begin
        if GLEntryRec.FindSet(true) then
            repeat
                if (GLEntryRec."NCF_DXR" <> GLEntryRec."DXNCF") or
                   (GLEntryRec."Name_DXR" <> GLEntryRec."DX Name") or
                   (GLEntryRec."Withholding Type_DXR" <> GLEntryRec."Withholding Type") or
                   (GLEntryRec."Concepto Cheque_DXR" <> GLEntryRec."Concepto Cheque") or
                   (GLEntryRec."NCFCategories_DXR" <> GLEntryRec."DXNCF Categories") then begin
                    GLEntryRec."NCF_DXR" := GLEntryRec."DXNCF";
                    GLEntryRec."Name_DXR" := GLEntryRec."DX Name";
                    GLEntryRec."Withholding Type_DXR" := GLEntryRec."Withholding Type";
                    GLEntryRec."Concepto Cheque_DXR" := GLEntryRec."Concepto Cheque";
                    GLEntryRec."NCFCategories_DXR" := GLEntryRec."DXNCF Categories";
                    GLEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until GLEntryRec.Next() = 0;
    end;

    local procedure MigrateGLRegisterFields()
    var
        GLRegisterRec: Record "G/L Register";
    begin
        if GLRegisterRec.FindSet(true) then
            repeat
                if GLRegisterRec."Recibo Ingreso_DXR" <> GLRegisterRec."DXRecibo Ingreso" then begin
                    GLRegisterRec."Recibo Ingreso_DXR" := GLRegisterRec."DXRecibo Ingreso";
                    GLRegisterRec.Modify(false);
                end;
            until GLRegisterRec.Next() = 0;
    end;

    // ===== Batch 4, seq42: Gen. Journal Line/Item Ledger Entry field restore =====
    // Ported from MigrateFields_GenJournalLine() (~line 1815) and MigrateFields_ItemLedgerEntry()
    // (~line 1907). Gen. Journal Line is a staging table for not-yet-posted lines (cleared down as
    // batches post) - no Commit(). Item Ledger Entry is transaction-volume-scale (unbounded) -
    // periodic Commit() every 100 rows.
    local procedure BootstrapGenJournalLineItemLedgerEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALLINE-20260522') then begin
            MigrateGenJournalLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALLINE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-ITEMLEDGERENTRY-20260522') then begin
            MigrateItemLedgerEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-ITEMLEDGERENTRY-20260522');
        end;
    end;

    // Shadow-field check: all 24 destination fields independently verified against
    // DXR_GenJournalLineExt.TableExt.al, including "Withholding Type_DXR" (Option, identical
    // OptionMembers/order to the source "Withholding Type" - safe direct assignment).
    local procedure MigrateGenJournalLineFields()
    var
        GenJournalLineRec: Record "Gen. Journal Line";
    begin
        if GenJournalLineRec.FindSet(true) then
            repeat
                if (GenJournalLineRec."NCF_DXR" <> GenJournalLineRec."DXNCF") or
                   (GenJournalLineRec."Beneficiario_DXR" <> GenJournalLineRec."DXBeneficiario") or
                   (GenJournalLineRec."Recibo Ingreso_DXR" <> GenJournalLineRec."DXRecibo Ingreso") or
                   (GenJournalLineRec."Importe Efectivo_DXR" <> GenJournalLineRec."DXImporte Efectivo") or
                   (GenJournalLineRec."Importe Tcr._DXR" <> GenJournalLineRec."DXImporte Tcr.") or
                   (GenJournalLineRec."Importe Cheque_DXR" <> GenJournalLineRec."DXImporte Cheque") or
                   (GenJournalLineRec."Reporta en 606_DXR" <> GenJournalLineRec."DXReporta en 606") or
                   (GenJournalLineRec."Correccion Int._DXR" <> GenJournalLineRec."DXCorreccion Int.") or
                   (GenJournalLineRec."Tot. Monto Recibido_DXR" <> GenJournalLineRec."DXTot. Monto Recibido") or
                   (GenJournalLineRec."Concepto Cheque_DXR" <> GenJournalLineRec."DXConcepto Cheque") or
                   (GenJournalLineRec."Importe Transf._DXR" <> GenJournalLineRec."DXImporte Transf.") or
                   (GenJournalLineRec."Venta Bonos_DXR" <> GenJournalLineRec."DXVenta Bonos") or
                   (GenJournalLineRec."Withholding Payment_DXR" <> GenJournalLineRec."Dx Withholding Payment") or
                   (GenJournalLineRec."Withholding Type_DXR" <> GenJournalLineRec."Withholding Type") or
                   (GenJournalLineRec."Cust ITBIS Withhold_DXR" <> GenJournalLineRec."DXCustomer ITBIS Withholding") or
                   (GenJournalLineRec."Customer ISR Withholding_DXR" <> GenJournalLineRec."DXCustomer ISR Withholding") or
                   (GenJournalLineRec."Bank Commission Amount_DXR" <> GenJournalLineRec."DXBank Commission Amount") or
                   (GenJournalLineRec."ITBIS Withholding Code_DXR" <> GenJournalLineRec."DXITBIS Withholding Code") or
                   (GenJournalLineRec."ITBIS Withholding %_DXR" <> GenJournalLineRec."DXITBIS Withholding %") or
                   (GenJournalLineRec."ITBIS Withholding Base_DXR" <> GenJournalLineRec."DXITBIS Withholding Base") or
                   (GenJournalLineRec."ITBIS Withholding Amount_DXR" <> GenJournalLineRec."DXITBIS Withholding Amount") or
                   (GenJournalLineRec."ISR Withholding Code_DXR" <> GenJournalLineRec."DXISR Withholding Code") or
                   (GenJournalLineRec."ISR Withholding %_DXR" <> GenJournalLineRec."DXISR Withholding %") or
                   (GenJournalLineRec."ISR Withholding Base_DXR" <> GenJournalLineRec."DXISR Withholding Base") or
                   (GenJournalLineRec."ISR Withholding Amount_DXR" <> GenJournalLineRec."DXISR Withholding Amount") or
                   (GenJournalLineRec."Bank Fee Amount_DXR" <> GenJournalLineRec."DXBank Fee Amount") then begin
                    GenJournalLineRec."NCF_DXR" := GenJournalLineRec."DXNCF";
                    GenJournalLineRec."Beneficiario_DXR" := GenJournalLineRec."DXBeneficiario";
                    GenJournalLineRec."Recibo Ingreso_DXR" := GenJournalLineRec."DXRecibo Ingreso";
                    GenJournalLineRec."Importe Efectivo_DXR" := GenJournalLineRec."DXImporte Efectivo";
                    GenJournalLineRec."Importe Tcr._DXR" := GenJournalLineRec."DXImporte Tcr.";
                    GenJournalLineRec."Importe Cheque_DXR" := GenJournalLineRec."DXImporte Cheque";
                    GenJournalLineRec."Reporta en 606_DXR" := GenJournalLineRec."DXReporta en 606";
                    GenJournalLineRec."Correccion Int._DXR" := GenJournalLineRec."DXCorreccion Int.";
                    GenJournalLineRec."Tot. Monto Recibido_DXR" := GenJournalLineRec."DXTot. Monto Recibido";
                    GenJournalLineRec."Concepto Cheque_DXR" := GenJournalLineRec."DXConcepto Cheque";
                    GenJournalLineRec."Importe Transf._DXR" := GenJournalLineRec."DXImporte Transf.";
                    GenJournalLineRec."Venta Bonos_DXR" := GenJournalLineRec."DXVenta Bonos";
                    GenJournalLineRec."Withholding Payment_DXR" := GenJournalLineRec."Dx Withholding Payment";
                    GenJournalLineRec."Withholding Type_DXR" := GenJournalLineRec."Withholding Type";
                    GenJournalLineRec."Cust ITBIS Withhold_DXR" := GenJournalLineRec."DXCustomer ITBIS Withholding";
                    GenJournalLineRec."Customer ISR Withholding_DXR" := GenJournalLineRec."DXCustomer ISR Withholding";
                    GenJournalLineRec."Bank Commission Amount_DXR" := GenJournalLineRec."DXBank Commission Amount";
                    GenJournalLineRec."ITBIS Withholding Code_DXR" := GenJournalLineRec."DXITBIS Withholding Code";
                    GenJournalLineRec."ITBIS Withholding %_DXR" := GenJournalLineRec."DXITBIS Withholding %";
                    GenJournalLineRec."ITBIS Withholding Base_DXR" := GenJournalLineRec."DXITBIS Withholding Base";
                    GenJournalLineRec."ITBIS Withholding Amount_DXR" := GenJournalLineRec."DXITBIS Withholding Amount";
                    GenJournalLineRec."ISR Withholding Code_DXR" := GenJournalLineRec."DXISR Withholding Code";
                    GenJournalLineRec."ISR Withholding %_DXR" := GenJournalLineRec."DXISR Withholding %";
                    GenJournalLineRec."ISR Withholding Base_DXR" := GenJournalLineRec."DXISR Withholding Base";
                    GenJournalLineRec."ISR Withholding Amount_DXR" := GenJournalLineRec."DXISR Withholding Amount";
                    GenJournalLineRec."Bank Fee Amount_DXR" := GenJournalLineRec."DXBank Fee Amount";
                    GenJournalLineRec.Modify(false);
                end;
            until GenJournalLineRec.Next() = 0;
    end;

    local procedure MigrateItemLedgerEntryFields()
    var
        ItemLedgerEntryRec: Record "Item Ledger Entry";
        BatchCount: Integer;
    begin
        if ItemLedgerEntryRec.FindSet(true) then
            repeat
                if ItemLedgerEntryRec."User Id_DXR" <> ItemLedgerEntryRec."DX User Id" then begin
                    ItemLedgerEntryRec."User Id_DXR" := ItemLedgerEntryRec."DX User Id";
                    ItemLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until ItemLedgerEntryRec.Next() = 0;
    end;

    // ===== Batch 4, seq43: Price List Line/Reversal Entry field restore =====
    // Ported from MigrateFields_PriceListLine() (~line 1935) and MigrateFields_ReversalEntry()
    // (~line 2279). Both tables are bounded by catalog/reversal-action count, not transaction
    // volume - no Commit().
    local procedure BootstrapPriceListLineReversalEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PRICELISTLINE-20260522') then begin
            MigratePriceListLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PRICELISTLINE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-REVERSALENTRY-20260522') then begin
            MigrateReversalEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-REVERSALENTRY-20260522');
        end;
    end;

    local procedure MigratePriceListLineFields()
    var
        PriceListLineRec: Record "Price List Line";
    begin
        if PriceListLineRec.FindSet(true) then
            repeat
                if PriceListLineRec."Item Category Code_DXR" <> PriceListLineRec."Item Category Code" then begin
                    PriceListLineRec."Item Category Code_DXR" := PriceListLineRec."Item Category Code";
                    PriceListLineRec.Modify(false);
                end;
            until PriceListLineRec.Next() = 0;
    end;

    local procedure MigrateReversalEntryFields()
    var
        ReversalEntryRec: Record "Reversal Entry";
    begin
        if ReversalEntryRec.FindSet(true) then
            repeat
                if ReversalEntryRec."Reporta en 606_DXR" <> ReversalEntryRec."DXReporta en 606" then begin
                    ReversalEntryRec."Reporta en 606_DXR" := ReversalEntryRec."DXReporta en 606";
                    ReversalEntryRec.Modify(false);
                end;
            until ReversalEntryRec.Next() = 0;
    end;

    // ===== Batch 4, seq44: Vendor Ledger Entry field restore (bulk + FlowFields) =====
    // Ported from MigrateFields_VendorLedgerEntry_Bulk() (~line 2452) and
    // MigrateFields_VendorLedgerEntry_FlowFields() (~line 2478). "Withholding migration repair"
    // (registry row description) is deliberately NOT included - see codeunit-level "seq44 naming
    // note" comment. "Vendor Name_DXR"/"Settled Amount_DXR" are themselves FlowFields - see
    // codeunit-level "No-op observation" comment (ported verbatim, not fixed).
    local procedure BootstrapVendorLedgerEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDORLEDGERENTRY-BULK-20260522') then begin
            MigrateVendorLedgerEntryBulkFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDORLEDGERENTRY-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDORLEDGERENTRY-FLOWFIELDS-20260522') then begin
            MigrateVendorLedgerEntryFlowFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDORLEDGERENTRY-FLOWFIELDS-20260522');
        end;
    end;

    // Vendor Ledger Entry is transaction-volume-scale (unbounded) - periodic Commit() every 100 rows.
    local procedure MigrateVendorLedgerEntryBulkFields()
    var
        VendorLedgerEntryRec: Record "Vendor Ledger Entry";
        BatchCount: Integer;
    begin
        if VendorLedgerEntryRec.FindSet(true) then
            repeat
                if (VendorLedgerEntryRec."NCF_DXR" <> VendorLedgerEntryRec."DXNCF") or
                   (VendorLedgerEntryRec."Reporta en 606_DXR" <> VendorLedgerEntryRec."DXReporta en 606") or
                   (VendorLedgerEntryRec."Withholding Payment_DXR" <> VendorLedgerEntryRec."Dx Withholding Payment") or
                   (VendorLedgerEntryRec."Cod. Retencion ITBIS_DXR" <> VendorLedgerEntryRec."DXCod. Retencion ITBIS") or
                   (VendorLedgerEntryRec."Cod. Retencion ISR_DXR" <> VendorLedgerEntryRec."DXCod. Retencion ISR") or
                   (VendorLedgerEntryRec."Utiliza NCF Externo_DXR" <> VendorLedgerEntryRec."DXUtiliza NCF Externo") or
                   (VendorLedgerEntryRec."Withholding Apply Type_DXR" <> VendorLedgerEntryRec."DX Withholding Apply Type") then begin
                    VendorLedgerEntryRec."NCF_DXR" := VendorLedgerEntryRec."DXNCF";
                    VendorLedgerEntryRec."Reporta en 606_DXR" := VendorLedgerEntryRec."DXReporta en 606";
                    VendorLedgerEntryRec."Withholding Payment_DXR" := VendorLedgerEntryRec."Dx Withholding Payment";
                    VendorLedgerEntryRec."Cod. Retencion ITBIS_DXR" := VendorLedgerEntryRec."DXCod. Retencion ITBIS";
                    VendorLedgerEntryRec."Cod. Retencion ISR_DXR" := VendorLedgerEntryRec."DXCod. Retencion ISR";
                    VendorLedgerEntryRec."Utiliza NCF Externo_DXR" := VendorLedgerEntryRec."DXUtiliza NCF Externo";
                    VendorLedgerEntryRec."Withholding Apply Type_DXR" := VendorLedgerEntryRec."DX Withholding Apply Type";
                    VendorLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until VendorLedgerEntryRec.Next() = 0;
    end;

    local procedure MigrateVendorLedgerEntryFlowFields()
    var
        VendorLedgerEntryRec: Record "Vendor Ledger Entry";
        BatchCount: Integer;
    begin
        VendorLedgerEntryRec.SetAutoCalcFields("Dx Vendor Name", "DX Settled Amount");
        if VendorLedgerEntryRec.FindSet(true) then
            repeat
                if (VendorLedgerEntryRec."Vendor Name_DXR" <> VendorLedgerEntryRec."Dx Vendor Name") or
                   (VendorLedgerEntryRec."Settled Amount_DXR" <> VendorLedgerEntryRec."DX Settled Amount") then begin
                    VendorLedgerEntryRec."Vendor Name_DXR" := VendorLedgerEntryRec."Dx Vendor Name";
                    VendorLedgerEntryRec."Settled Amount_DXR" := VendorLedgerEntryRec."DX Settled Amount";
                    VendorLedgerEntryRec.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until VendorLedgerEntryRec.Next() = 0;
    end;
}
