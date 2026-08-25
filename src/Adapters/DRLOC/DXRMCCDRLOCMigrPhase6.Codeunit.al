codeunit 60170 "DXR MCC DRLOC Migr Phase6"
{
    // Native local migration - ported (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization own "DXR_Migr. Phase 6 History" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Migr_Phase_6_History.Codeunit.al, codeunit 52257), start of the
    // DRLOC Phase 6 (History) native-porting campaign - the LAST DRLOC phase in this campaign.
    //
    // Real source OnRun() -> TryMigrateHistoricalTables() calls 3 typed, per-field procedures
    // (MigrateOmittedStandardTableFields, MigrateEFSendRegistry, MigrateNCFFiscalQueue - THIS batch
    // full scope, registry seq51/52/53) followed by a GENERIC RecordRef/FieldRef-based MigrateTable()
    // helper, called in a loop 24 times (registry seq50 + seq73-95) for every other Phase 6 concept.
    // Per this batch explicit instruction, that generic helper and its 24 call-sites are NOT ported
    // here - reserved for later Phase 6 sub-batches, where each of the 24 tables will be individually
    // expanded into its own explicit typed-Record procedure (same discipline as every prior
    // whole-table-clone batch in this campaign: Phase 2 Batch 3, Phase 3 Batch 2, Phase 4 Batch 2,
    // Phase 5 Batch 3).
    //
    // ===== UpgradeTag gating - shadow-finding, no individual tag exists for these 3 concepts =====
    // Confirmed via DXR_UpgradeTagMgt.Codeunit.al and DXR_Internal_Migr_Phase_Tags.Codeunit.al (both
    // read in full): unlike several earlier campaign batches (e.g. Phase 5 reuse of
    // UpgradeTagInternalClosureFields<X>() granular tags from the sibling "DXR_Internal Closure
    // Migration" codeunit), NO granular per-concept tag exists anywhere in real, current
    // DR-Localization source for MigrateOmittedStandardTableFields/MigrateEFSendRegistry/
    // MigrateNCFFiscalQueue. Real source itself does not individually gate these 3 procedures either -
    // they are called unconditionally, every time, from TryMigrateHistoricalTables(), which itself only
    // runs while the single OUTER "Phase6CompletedTag()" (DXR_Internal Migr. Phase Tags codeunit) is
    // not yet set. That outer tag cannot be reused/set by this codeunit: it is set only once ALL 27 of
    // Phase 6 real steps complete (these 3 plus the 24 out-of-scope MigrateTable() calls), so setting
    // it here would incorrectly cause a future batch still-unported 24 steps to be skipped. Per this
    // campaign own established discipline against inventing tags that do not exist in real source (see
    // Phase 2 own header: "none needed to be invented"), this port does NOT wrap the 3 procedures in an
    // invented UpgradeTag gate either - OnRun() calls all 3 directly/unconditionally, matching real
    // source actual behavior exactly. Safety on re-run relies on each procedure own natural idempotency:
    // MigrateEFSendRegistry/MigrateNCFFiscalQueue upsert by primary key (Get-then-Init-or-nothing,
    // Modify/Insert), and MigrateOmittedStandardTableFields is a dirty-check-then-Modify pattern on all
    // 3 of its loops - re-running any of the 3 is a safe no-op once already applied.
    //
    // ===== Shadow-field check (independently re-derived against real, current source) =====
    //   - seq51 (EF Send Registry): "DXR_EF Send Registry" (52247/36002908, live) primary key
    //     ("Document No.", "Source Type") confirmed against DXR_EFSendRegistry.Table.al; legacy source
    //     "DX EF Send Registry" (54174/36002837) confirmed ObsoleteState = Pending, same field set,
    //     same key. Both enum conversions ("DXR_EF Source Type"/"DX EF Source Type" on "Source Type",
    //     "DXR_EF Send Status"/"DX EF Send Status" on Status) ported via FromInteger()/AsInteger()
    //     exactly as real source does.
    //   - seq52 (NCF Fiscal Queue): "DXR_NCF Fiscal Queue" (52246/36002907, live) primary key
    //     ("Entry No.", AutoIncrement) confirmed against DXR_NCFFiscalQueue.Table.al; legacy source
    //     "DX NCF Fiscal Queue" (54173/36002836) confirmed ObsoleteState = Pending, same field set,
    //     same keys. "Document Type" (enum conversion, "DXR_NCF Queue Doc Type"/"DX NCF Queue Doc
    //     Type") AND Status (enum conversion, "DXR_NCF Queue Status"/"DX NCF Queue Status") both use
    //     FromInteger()/AsInteger() - confirmed real source uses it for BOTH fields on this table, not
    //     a same-type direct-assignment shortcut. "Document Subtype" is the SAME enum ("Purchase
    //     Document Type") on both old and new tables - direct assignment, no conversion, confirmed
    //     real source does not call FromInteger() on it either.
    //   - seq53 (Omitted standard table fields): "RegisterApplicationArea_DXR" (51814, Option,
    //     OptionMembers "BusinessCentral","LSCentral") vs legacy "DxRegisterApplicationArea" (51811,
    //     same Option/OptionMembers, ObsoleteState = Pending) on Application Area Setup - confirmed
    //     against DXR_ApplicationAreaSetupExt.TableExt.al, direct assignment safe (identical members
    //     and order). "NCF_DXR Afectado_DXR" (51903, Code[20], live - NOT the removed "_V1" sibling at
    //     51819) vs legacy "DXNCF Afectado" (54106, Code[20], ObsoleteState = Pending) on Purchase
    //     Header - confirmed against DXR_PurchaseHeaderExt.TableExt.AL. All 3 Sales Header field pairs
    //     ("NCF_DXR Modificado_DXR"/51829 vs "DXNCF Modificado"/54104, "NCF_DXR Afectado_DXR"/51815 vs
    //     "DXNCF Afectado"/54105, "NCF_DXR Factura_DXR"/51814 vs "DXNCF Factura"/54107, all Code[20])
    //     confirmed against DXR_SalesHeaderExt.TableExt.Al. Real source own #pragma warning
    //     disable/restore AL0432 wrapping (reads of ObsoleteState = Pending source fields) is
    //     deliberately OMITTED here, per this campaign established DRLOC-adapter convention (confirmed
    //     harmless via compile in Phase 5 Batch 1 review).
    //
    // ===== Commit() placement =====
    // Real source has no Commit() inside any of these 3 procedures (only a one-time
    // StatusMgt.MarkPhaseProgress + Commit() before each starts, via the outer TryMigrateHistoricalTables
    // orchestration - not replicated here, matching this campaign own established MCC-adapter
    // convention of not depending on DR-Localization own StatusMgt/PhaseTags scaffolding, see e.g.
    // Phase 2/Phase 4 own header comments).
    //   - MigrateEFSendRegistry / MigrateNCFFiscalQueue: both transaction-history-scale tables (per
    //     this batch own brief) - periodic Commit() every 100 rows added.
    //   - MigrateOmittedStandardTableFields: Application Area Setup is a tiny per-company setup table
    //     (no Commit() needed). Purchase Header and Sales Header hold only currently-open (not-yet-
    //     posted) documents - working/staging tables, not ever-growing history tables - same precedent
    //     already established for these exact 2 tables in Phase 4 own codeunit (60168) - no periodic
    //     Commit() added to any of this procedure 3 loops.
    //
    // ===== Batch 2: first 8 of 24 generic-loop whole-table clones (seq50, seq73-79) =====
    // Real source's generic MigrateTable(TableCaption, SourceTableId, DestinationTableId) helper
    // (lines 239-264 of real source) is RecordRef/FieldRef-based: it discovers, per table pair, the
    // set of fields that exist on BOTH tables with the SAME field number AND the SAME type
    // (GetCommonCompatibleFieldNos(), lines 266-280, Class = Normal only - this naturally excludes
    // FlowFields and fields removed via ObsoleteState = Removed on either side, since those never
    // appear as Class = Normal Field records for that TableNo), then upserts by primary key: tries
    // RecordRef.Insert(false) first (TryInsertRecRef), and on failure re-finds the target row via the
    // SOURCE record's own primary key VALUES applied by field position onto the target's primary key
    // (TryFindTargetByKeyOfSource, lines 301-314) and Modify(false)s it instead. This is NOT ported as
    // a generic helper (zero RecordRef/FieldRef/TransferFields is a hard constraint) - each of the 24
    // real call-sites is expanded into its own explicit typed-Record procedure. For all 8 tables in
    // this batch, the old and new tables' primary keys are identically named/shaped (same field names,
    // same order), so the typed port replicates the upsert-by-key semantic as a direct Target.Get()
    // using the source row's own key field values (equivalent outcome to TryFindTargetByKeyOfSource for
    // these particular pairs).
    //
    // Full field-by-field common-field derivation (independently re-read against real, current source
    // for BOTH the legacy DX-prefixed table AND its DXR-prefixed replacement, per table):
    //   - seq50 (API Dgi Setup, 54159 -> 52231): "DX API Dgi Setup"/"DXR_API Dgi Setup" - 4 fields
    //     total on both sides (Code[1] "Code", Text[250] "URL Endpoint", Boolean Active, Text[250]
    //     "Test URL"), identical numbers/types - all 4 common, nothing excluded. Tiny per-company setup
    //     table (single row keyed by "Code") - no periodic Commit() needed.
    //   - seq73 (Archived Bank Charges Lines, 54103 -> real 52109 "DXR_Arch Bank Charges Lines", NOT
    //     52128): registry row's own comment claims this shares destination table ID 52128 with
    //     seq76's "Bank Charges Lines" below. Re-verified directly against real source and both real
    //     table object declarations (DXR_ArchivedBankChargesLines.Table.al declares
    //     "table 52109 DXR_Arch Bank Charges Lines" under __SAAS__, confirmed again via
    //     TableIdMapping.csv row "54103","36002839","DXR_Arch Bank Charges Lines" - 36002839 being the
    //     on-prem ID whose __SAAS__ sibling is 52109, NOT 52128) - the registry's own New Table ID for
    //     seq73 (52128) is WRONG: 52128 is "DXR_Bank Charges Lines" (seq76's real, correct destination,
    //     confirmed via TableIdMapping.csv row "54110","36002846","DXR_Bank Charges Lines"), not
    //     "DXR_Arch Bank Charges Lines". Real source line 92 (Database::"DXR_Arch Bank Charges Lines")
    //     and line 95 (Database::"DXR_Bank Charges Lines") target two DIFFERENT real table IDs (52109
    //     vs 52128) - they do NOT share a destination; the registry seq73 metadata field is a
    //     pre-existing data error, not real, current DR-Localization behavior. Per this campaign's own
    //     discipline of porting real source behavior (not registry metadata that conflicts with it),
    //     MigrateArchivedBankChargesLines() below targets the CORRECT real destination, Record
    //     "DXR_Arch Bank Charges Lines" (52109) - see codeunit-level report for this batch on the
    //     registry metadata left as-is per this batch's own explicit instruction to not touch New Table
    //     ID. "DXArchived Bank Charges Lines"/"DXR_Arch Bank Charges Lines" - 10 fields on both sides
    //     (1 "No." Code[20], 2 "DX Transaction Date" Date, 23 NCF Code[19], 24 Amount Decimal, 25
    //     "Line No." Integer, 26 "Apply Trans." Boolean, 27 Description Text[30], 6 "Vendor No."
    //     Code[20], 28 "NCF Afectado" Code[19], 29 "Total Documento" Decimal), identical numbers/types -
    //     all 10 common, nothing excluded. Archive/history table (years of posted bank-charge lines) -
    //     periodic Commit() every 100 rows added.
    //   - seq74 (Archived Consumer Sales 607, 54104 -> 52111): "DXArchived Consumer Sales 607"/
    //     "DXR_Arch Consumer Sales 607" - 46 fields total on both sides; field 13 (Mensajes) is a
    //     FlowField on both (Class <> Normal, excluded by the real loop's own Class = Normal filter -
    //     never copied by real source either) and field 36002769 ("Additional Currency Code") carries
    //     ObsoleteState = Removed on BOTH sides (no longer a live field to reference/copy) - both
    //     excluded here too, matching real behavior exactly. All remaining 44 fields (1-12, 14-15,
    //     36002752-36002768, 36002770-36002782 including the legacy-typo'd field number 3600277
    //     "Cheque/Transf./Deposito ICY", which is identically present with the SAME typo'd number on
    //     both old and new tables) match by number+type - all 44 common. Archive/history table -
    //     periodic Commit() every 100 rows added.
    //   - seq75 (Archived Purchase 606 Buffer, 54152 -> 52217): "DXArchived Purchase 606 Buffer"/
    //     "DXR_Arch Purchase 606 Buffer" - both sides identical field-for-field except field 13
    //     (Mensajes), a FlowField on both, excluded (Class <> Normal). All other 70 fields (1-12, 14-47,
    //     36002769-36002792) match by number+type - all 70 common, nothing else excluded. Archive/
    //     history table - periodic Commit() every 100 rows added.
    //   - seq76 (Bank Charges Lines, 54110 -> 52128): "DX Bank Charges Lines"/"DXR_Bank Charges Lines" -
    //     9 fields total on both sides (1 "No." Code[20], 2 "DXTransaction Date" Date, 3 NCF Code[19],
    //     4 Amount Decimal, 5 "Line No." Integer, 6 "Apply Trans." Boolean, 7 Description Text[30], 8
    //     "Vendor No." Code[20], 9 "NCF Afectado" Code[19]), identical numbers/types - all 9 common,
    //     nothing excluded. This table holds only currently-unarchived (not-yet-posted) bank-charge
    //     document lines - a working/staging table, not an ever-growing history table (rows migrate out
    //     to the seq73 archive table above once posted) - same working-table precedent already
    //     established for Purchase Header/Sales Header in Phase 4 own codeunit (60168) - no periodic
    //     Commit() added.
    //   - seq77 (Bank Commission Setup, 54172 -> 52245): "DX Bank Commission Setup"/
    //     "DXR_Bank Commission Setup" - 4 fields total on both sides (1 "Bank Account No." Code[20], 2
    //     "Bank Account Name" Text[100], 3 "GL Account No." Code[20], 4 "GL Account Name" Text[100]),
    //     identical numbers/types - all 4 common, nothing excluded. Tiny per-bank-account setup table
    //     (one row per Bank Account) - no periodic Commit() needed.
    //   - seq78 (Cash Receipt Header, 54170 -> 52243): "DX Cash Receipt Header"/"DXR_Cash Receipt
    //     Header" - 40 fields total on both sides (1-26, 30-32, 40-47, 50-51, 480), identical
    //     numbers/types - all 40 common, nothing excluded (fields 40-47, the ITBIS/ISR withholding
    //     fields, carry ObsoleteState = Pending on the NEW/destination table only - still Class = Normal
    //     though, so still real-loop-copyable; this port does not add #pragma warning disable/restore
    //     AL0432 around the writes to those 8 fields, matching this codeunit's own already-established
    //     convention of omitting that pragma wrapping, see the UpgradeTag-gating header comment above).
    //     Unlike Purchase/Sales Header (Phase 4), this table's own Status field carries BOTH Open and
    //     Posted rows (no separate archive table for posted Cash Receipts) - genuinely ever-growing
    //     history-scale table - periodic Commit() every 100 rows added.
    //   - seq79 (Cash Receipt Line, 54171 -> 52244): "DX Cash Receipt Line"/"DXR_Cash Receipt Line" -
    //     40 fields total on both sides (1-17, 20-26, 30-32, 40-47, 50-51, 60-61, 480), identical
    //     numbers/types - all 40 common, nothing excluded (same ObsoleteState = Pending-on-destination-
    //     only note as seq78 applies to fields 40-47 here too). Same ever-growing rationale as seq78 -
    //     periodic Commit() every 100 rows added.
    //
    // ===== Batch 3: next 8 of 24 generic-loop whole-table clones (seq80-87) =====
    // Continuation of Batch 2's discipline for the same real generic MigrateTable() helper (lines
    // 239-264 of real source) - GetCommonCompatibleFieldNos() (lines 266-280) matches fields by SAME
    // NUMBER + SAME "Field" system-table Type value only (Class = Normal); for two Option/Enum fields,
    // "Type" reads as the same generic Option/Enum type regardless of which specific enum object each
    // side declares, so CopyCommonFields() (lines 282-293) still copies them as a raw FieldRef.Value
    // ordinal transfer - this is why seq85/86/87 below (ContributorType, a DIFFERENT Enum object on old
    // vs new side but with identical member values 1/2/3) are still real-loop-copyable, ported here via
    // FromInteger()/AsInteger() to replicate that exact ordinal-transfer semantic (same discipline as
    // seq51/52's Batch 1 enum conversions).
    //
    // Registry cross-check for all 8 rows in this batch (seq80-87): independently re-verified every
    // row's Old/New Table ID pair against real source's own MigrateTable() call arguments (lines 99-106)
    // AND both real table object declarations - all 8 registry rows are CORRECT, no data error found
    // this batch (unlike seq73 in Batch 2).
    //
    // Full field-by-field common-field derivation (independently re-read against real, current source
    // for BOTH the legacy DX-prefixed table AND its DXR-prefixed replacement, per table):
    //   - seq80 (Consumer Sales 607 Buffer, 54150 -> 52213): "DX Consumer Sales 607 Buffer"/
    //     "DXR_Consumer Sales 607 Buffer" - 45 common fields (field 13 Mensajes is a FlowField on both;
    //     fields 17-28, all "Total ... Amount" fields, are FlowFields on both too; field 36002769
    //     "Additional Currency Code" carries ObsoleteState = Removed on both - all excluded, matching
    //     real behavior exactly, same pattern as Batch 2's seq74 sibling table). History-scale table
    //     (DGII 607 consumer-sales tax reporting data, registry Category HIST) - periodic Commit() every
    //     100 rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento", "No. Linea") - safe
    //     to re-run.
    //   - seq81 (Customer Withholding Entries, 54115 -> 52143, active name shortened to "DXR_Cust
    //     Withhold Entries"): 23 fields total on both sides, identical numbers/types - all 23 common,
    //     nothing excluded. Note: this is a SEPARATE, legitimate whole-table clone of the same target
    //     table that Phase 5's updateWithholdingEntries() already field-restores (both real, both
    //     ObsoleteState = Pending module, confirmed real in an earlier batch this session) - not a
    //     duplication. Ledger-entry-style history table - periodic Commit() every 100 rows added.
    //     Upsert-by-primary-key ("Fecha Retencion", "No. Documento", "Tipo Retencion", "No. Linea") -
    //     safe to re-run.
    //   - seq82 (Customer Withholding Header, 54116 -> 52144, active name shortened to "DXR_Cust
    //     Withhold Header"): 17 fields total on both sides, identical numbers/types - all 17 common,
    //     nothing excluded. Document-header-style history table (pairs with seq81 above) - periodic
    //     Commit() every 100 rows added. Upsert-by-primary-key ("No.") - safe to re-run.
    //   - seq83 (Dependencies Metadata, 54157 -> 52225): "DX Dependencies Metadata"/"DXR_Dependencies
    //     Metadata" - 5 fields total on both sides, identical numbers/types - all 5 common, nothing
    //     excluded. DataPerCompany = false on both sides (global, not per-company, table) - tiny
    //     installed-extension-list setup table - no periodic Commit() needed. Upsert-by-primary-key
    //     (AppId) - safe to re-run.
    //   - seq84 (Detalle Servicio Adquirido, 54154 -> 52219): "DxDetalleServicioAdquirido"/
    //     "DXR_R_DetalleServicioAdquirido" - 3 fields total on both sides, identical numbers/types - all
    //     3 common, nothing excluded. Small reference/lookup table (service-type sub-code + description,
    //     not transactional despite registry Category HIST) - no periodic Commit() needed.
    //     Upsert-by-primary-key ("Tipo Servicio Adquirido", "Code") - safe to re-run.
    //   - seq85 (DGI API Services, 54160 -> 52233): "DX DGI ApiServices"/"DXR_DGI ApiServices" - 12
    //     fields total on both sides; field 11 (ContributorType) is Enum "DX ApiDGIServices Contr.
    //     Type" (54110, obsolete) vs Enum "DXR_ApiDGIServices Contr. Type" (52197, live) - a DIFFERENT
    //     enum object on each side but with identical member values 1=" ", 2=Customer, 3=Vendor
    //     (confirmed against both enum source files) - still real-loop-copyable per this batch's own
    //     header note above, ported via FromInteger()/AsInteger(). All 12 fields common, nothing
    //     excluded. Confirmed via DXR_DgiApiServices.Codeunit.al that current live code only ever
    //     returns "Record ... temporary" instances shaped by this table (never inserts into the real,
    //     persisted table) - its real row content is frozen legacy data from before that refactor,
    //     history-scale - periodic Commit() every 100 rows added. Upsert-by-primary-key ("RNC") - safe
    //     to re-run.
    //   - seq86 (DGI API Services FindByName, 54161 -> 52234): "DX DGI ApiServices FindByName"/"DXR_DGI
    //     ApiServices FindByName" - same 12-field shape/same field-11 enum-object difference as seq85
    //     above. Neither side declares a `keys` block in real source - per AL's own default-key rule (no
    //     keys property = the table's implicit primary key is ALL fields, in field-declaration order),
    //     the primary key is the full 12-field tuple; ported via Target.Get() with all 12 source-derived
    //     values (field 11 converted the same way as seq85). Same frozen-legacy-cache rationale as seq85
    //     - periodic Commit() every 100 rows added.
    //   - seq87 (DGII Temp Table, 54162 -> 52235): "DX DGII Temp Table"/"DXR_DGII Temp Table" - same
    //     12-field shape/same field-11 enum difference/same no-explicit-keys (all-fields primary key) as
    //     seq86 above. Confirmed via DXR_DgiApiServices.Codeunit.al (DGiServicesGetByName()) that this
    //     table is fully DeleteAll()'d/Delete()'d at the START of every real use despite being a real
    //     (non-AL-temporary) persisted table - genuinely transient/scratch, not accumulated history,
    //     unlike its seq85/86 siblings - no periodic Commit() needed. Upsert-by-all-12-fields-as-key -
    //     safe to re-run.
    Permissions =
        tabledata "DX EF Send Registry" = R,
        tabledata "DXR_EF Send Registry" = RIM,
        tabledata "DX NCF Fiscal Queue" = R,
        tabledata "DXR_NCF Fiscal Queue" = RIM,
        tabledata "Application Area Setup" = RM,
        tabledata "Purchase Header" = RM,
        tabledata "Sales Header" = RM,
        tabledata "DX API Dgi Setup" = R,
        tabledata "DXR_API Dgi Setup" = RIM,
        tabledata "DXArchived Bank Charges Lines" = R,
        tabledata "DXR_Arch Bank Charges Lines" = RIM,
        tabledata "DXArchived Consumer Sales 607" = R,
        tabledata "DXR_Arch Consumer Sales 607" = RIM,
        tabledata "DXArchived Purchase 606 Buffer" = R,
        tabledata "DXR_Arch Purchase 606 Buffer" = RIM,
        tabledata "DX Bank Charges Lines" = R,
        tabledata "DXR_Bank Charges Lines" = RIM,
        tabledata "DX Bank Commission Setup" = R,
        tabledata "DXR_Bank Commission Setup" = RIM,
        tabledata "DX Cash Receipt Header" = R,
        tabledata "DXR_Cash Receipt Header" = RIM,
        tabledata "DX Cash Receipt Line" = R,
        tabledata "DXR_Cash Receipt Line" = RIM,
        tabledata "DX Consumer Sales 607 Buffer" = R,
        tabledata "DXR_Consumer Sales 607 Buffer" = RIM,
        tabledata "DXCustomer Withholding Entries" = R,
        tabledata "DXR_Cust Withhold Entries" = RIM,
        tabledata "DXCustomer Withholding Header" = R,
        tabledata "DXR_Cust Withhold Header" = RIM,
        tabledata "DX Dependencies Metadata" = R,
        tabledata "DXR_Dependencies Metadata" = RIM,
        tabledata DxDetalleServicioAdquirido = R,
        tabledata DXR_R_DetalleServicioAdquirido = RIM,
        tabledata "DX DGI ApiServices" = R,
        tabledata "DXR_DGI ApiServices" = RIM,
        tabledata "DX DGI ApiServices FindByName" = R,
        tabledata "DXR_DGI ApiServices FindByName" = RIM,
        tabledata "DX DGII Temp Table" = R,
        tabledata "DXR_DGII Temp Table" = RIM;

    trigger OnRun()
    begin
        MigrateOmittedStandardTableFields();
        MigrateEFSendRegistry();
        MigrateNCFFiscalQueue();
        MigrateAPIDgiSetup();
        MigrateArchivedBankChargesLines();
        MigrateArchivedConsumerSales607();
        MigrateArchivedPurchase606Buffer();
        MigrateBankChargesLines();
        MigrateBankCommissionSetup();
        MigrateCashReceiptHeader();
        MigrateCashReceiptLine();
        MigrateConsumerSales607Buffer();
        MigrateCustomerWithholdingEntries();
        MigrateCustomerWithholdingHeader();
        MigrateDependenciesMetadata();
        MigrateDetalleServicioAdquirido();
        MigrateDGIApiServices();
        MigrateDGIApiServicesFindByName();
        MigrateDGIITempTable();
    end;

    // No periodic Commit() - Application Area Setup is a tiny per-company setup table; Purchase
    // Header/Sales Header hold only currently-open (not-yet-posted) documents, not ever-growing
    // history tables (see codeunit-level Commit() placement comment).
    local procedure MigrateOmittedStandardTableFields()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
    begin
        if ApplicationAreaSetup.FindSet(true) then
            repeat
                if ApplicationAreaSetup.RegisterApplicationArea_DXR <> ApplicationAreaSetup.DxRegisterApplicationArea then begin
                    ApplicationAreaSetup.RegisterApplicationArea_DXR := ApplicationAreaSetup.DxRegisterApplicationArea;
                    ApplicationAreaSetup.Modify(false);
                end;
            until ApplicationAreaSetup.Next() = 0;

        if PurchaseHeader.FindSet(true) then
            repeat
                if PurchaseHeader."NCF_DXR Afectado_DXR" <> PurchaseHeader."DXNCF Afectado" then begin
                    PurchaseHeader."NCF_DXR Afectado_DXR" := PurchaseHeader."DXNCF Afectado";
                    PurchaseHeader.Modify(false);
                end;
            until PurchaseHeader.Next() = 0;

        if SalesHeader.FindSet(true) then
            repeat
                if (SalesHeader."NCF_DXR Modificado_DXR" <> SalesHeader."DXNCF Modificado") or
                   (SalesHeader."NCF_DXR Afectado_DXR" <> SalesHeader."DXNCF Afectado") or
                   (SalesHeader."NCF_DXR Factura_DXR" <> SalesHeader."DXNCF Factura")
                then begin
                    SalesHeader."NCF_DXR Modificado_DXR" := SalesHeader."DXNCF Modificado";
                    SalesHeader."NCF_DXR Afectado_DXR" := SalesHeader."DXNCF Afectado";
                    SalesHeader."NCF_DXR Factura_DXR" := SalesHeader."DXNCF Factura";
                    SalesHeader.Modify(false);
                end;
            until SalesHeader.Next() = 0;
    end;

    // EF Send Registry is a transaction-history-scale table - periodic Commit() every 100 rows added
    // (real source has none, see codeunit-level Commit() placement comment). Upsert-by-primary-key
    // ("Document No.", "Source Type") - safe to re-run.
    local procedure MigrateEFSendRegistry()
    var
        Source: Record "DX EF Send Registry";
        Target: Record "DXR_EF Send Registry";
        TargetSourceType: Enum "DXR_EF Source Type";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetSourceType := Enum::"DXR_EF Source Type".FromInteger(Source."Source Type".AsInteger());
                TargetExists := Target.Get(Source."Document No.", TargetSourceType);
                if not TargetExists then
                    Target.Init();
                Target."Document No." := Source."Document No.";
                Target."Source Type" := TargetSourceType;
                Target.NCF := Source.NCF;
                Target."Posting Date" := Source."Posting Date";
                Target.Status := Enum::"DXR_EF Send Status".FromInteger(Source.Status.AsInteger());
                Target."Request DateTime" := Source."Request DateTime";
                Target."EF Track ID" := Source."EF Track ID";
                Target."EF Security Code" := Source."EF Security Code";
                Target."Error Message" := Source."Error Message";
                Target."Source Extension" := Source."Source Extension";
                Target."Retry Count" := Source."Retry Count";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // NCF Fiscal Queue is a transaction-history-scale table - periodic Commit() every 100 rows added
    // (real source has none, see codeunit-level Commit() placement comment). Upsert-by-primary-key
    // ("Entry No.") - safe to re-run.
    local procedure MigrateNCFFiscalQueue()
    var
        Source: Record "DX NCF Fiscal Queue";
        Target: Record "DXR_NCF Fiscal Queue";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Entry No.");
                if not TargetExists then
                    Target.Init();
                Target."Entry No." := Source."Entry No.";
                Target."Document Type" := Enum::"DXR_NCF Queue Doc Type".FromInteger(Source."Document Type".AsInteger());
                Target."Document Subtype" := Source."Document Subtype";
                Target."Document No." := Source."Document No.";
                Target."No. Series Code" := Source."No. Series Code";
                Target."NCF Type" := Source."NCF Type";
                Target."Requested By" := Source."Requested By";
                Target."Request DateTime" := Source."Request DateTime";
                Target.Status := Enum::"DXR_NCF Queue Status".FromInteger(Source.Status.AsInteger());
                Target."Assigned NCF" := Source."Assigned NCF";
                Target."Source Extension" := Source."Source Extension";
                Target."Vendor/Customer No." := Source."Vendor/Customer No.";
                Target."VAT Registration No." := Source."VAT Registration No.";
                Target."Posting Date" := Source."Posting Date";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // API Dgi Setup - tiny per-company setup table (all 4 fields common, see codeunit-level Batch 2
    // shadow-field comment) - no periodic Commit() needed. Upsert-by-primary-key ("Code") - safe to
    // re-run.
    local procedure MigrateAPIDgiSetup()
    var
        Source: Record "DX API Dgi Setup";
        Target: Record "DXR_API Dgi Setup";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Code");
                if not TargetExists then
                    Target.Init();
                Target."Code" := Source."Code";
                Target."URL Endpoint" := Source."URL Endpoint";
                Target.Active := Source.Active;
                Target."Test URL" := Source."Test URL";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Archived Bank Charges Lines - real destination is Record "DXR_Arch Bank Charges Lines" (real
    // table 52109), NOT table 52128 as the registry seq73 row's own New Table ID field claims - see
    // codeunit-level Batch 2 shadow-field comment for the full re-verification against real source. All
    // 10 fields common (see same comment) - archive/history table, periodic Commit() every 100 rows
    // added. Upsert-by-primary-key ("No.") - safe to re-run.
    local procedure MigrateArchivedBankChargesLines()
    var
        Source: Record "DXArchived Bank Charges Lines";
        Target: Record "DXR_Arch Bank Charges Lines";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."No.");
                if not TargetExists then
                    Target.Init();
                Target."No." := Source."No.";
                Target."DX Transaction Date" := Source."DX Transaction Date";
                Target.NCF := Source.NCF;
                Target.Amount := Source.Amount;
                Target."Line No." := Source."Line No.";
                Target."Apply Trans." := Source."Apply Trans.";
                Target.Description := Source.Description;
                Target."Vendor No." := Source."Vendor No.";
                Target."NCF Afectado" := Source."NCF Afectado";
                Target."Total Documento" := Source."Total Documento";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Archived Consumer Sales 607 - 44 common fields (field 13 Mensajes is a FlowField on both, field
    // 36002769 "Additional Currency Code" carries ObsoleteState = Removed on both - both excluded, see
    // codeunit-level Batch 2 shadow-field comment). Archive/history table, periodic Commit() every 100
    // rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento", "No. Linea", NCF) - safe to
    // re-run.
    local procedure MigrateArchivedConsumerSales607()
    var
        Source: Record "DXArchived Consumer Sales 607";
        Target: Record "DXR_Arch Consumer Sales 607";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea", Source.NCF);
                if not TargetExists then
                    Target.Init();
                Target."Tipo Documento" := Source."Tipo Documento";
                Target."No. Documento" := Source."No. Documento";
                Target."Tipo Identificacion" := Source."Tipo Identificacion";
                Target."Cod. Identificacion" := Source."Cod. Identificacion";
                Target."Cod. Cliente" := Source."Cod. Cliente";
                Target."Nombre Cliente" := Source."Nombre Cliente";
                Target.NCF := Source.NCF;
                Target."NCF Modificado" := Source."NCF Modificado";
                Target."Fecha Comprobante" := Source."Fecha Comprobante";
                Target."ITBIS Facturado" := Source."ITBIS Facturado";
                Target."Monto Facturado" := Source."Monto Facturado";
                Target."No. Linea" := Source."No. Linea";
                Target."Estado Reg." := Source."Estado Reg.";
                Target."Report 607" := Source."Report 607";
                Target."Type of Income" := Source."Type of Income";
                Target."Fecha Retencion" := Source."Fecha Retencion";
                Target."ITBIS Retenido por Terceros" := Source."ITBIS Retenido por Terceros";
                Target."ITBIS Percibido" := Source."ITBIS Percibido";
                Target."Retencion Renta por Terceros" := Source."Retencion Renta por Terceros";
                Target."ISR Percibido" := Source."ISR Percibido";
                Target."Imp. Selectivo al Consumo" := Source."Imp. Selectivo al Consumo";
                Target."Otros Impuestos o Tasas" := Source."Otros Impuestos o Tasas";
                Target."Monto Propina Legal" := Source."Monto Propina Legal";
                Target.Efectivo := Source.Efectivo;
                Target."Cheque/Transferencia/Deposito" := Source."Cheque/Transferencia/Deposito";
                Target."Tarjeta Debito/Credito" := Source."Tarjeta Debito/Credito";
                Target."Venta a Credito" := Source."Venta a Credito";
                Target."Bonos o Certificados de Regalo" := Source."Bonos o Certificados de Regalo";
                Target.Permuta := Source.Permuta;
                Target."Otras Formas de Ventas" := Source."Otras Formas de Ventas";
                Target."Fuente Datos" := Source."Fuente Datos";
                Target."Additional Currency Factor" := Source."Additional Currency Factor";
                Target."Addit. Currency Code" := Source."Addit. Currency Code";
                Target."Currency Code" := Source."Currency Code";
                Target."Currency Factor" := Source."Currency Factor";
                Target."DX Original Amount" := Source."DX Original Amount";
                Target."DX Original ITBIS Amount" := Source."DX Original ITBIS Amount";
                Target."Efectivo ICY" := Source."Efectivo ICY";
                Target."Cheque/Transf./Deposito ICY" := Source."Cheque/Transf./Deposito ICY";
                Target."Tarjeta Debito/Credito ICY" := Source."Tarjeta Debito/Credito ICY";
                Target."Venta a Credito ICY" := Source."Venta a Credito ICY";
                Target."Bonos o Certif. de Regalo ICY" := Source."Bonos o Certif. de Regalo ICY";
                Target."Permuta ICY" := Source."Permuta ICY";
                Target."Otras Formas de Ventas ICY" := Source."Otras Formas de Ventas ICY";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Archived Purchase 606 Buffer - 70 common fields (field 13 Mensajes is a FlowField on both -
    // excluded, see codeunit-level Batch 2 shadow-field comment). Archive/history table, periodic
    // Commit() every 100 rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento",
    // "No. Linea") - safe to re-run.
    local procedure MigrateArchivedPurchase606Buffer()
    var
        Source: Record "DXArchived Purchase 606 Buffer";
        Target: Record "DXR_Arch Purchase 606 Buffer";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea");
                if not TargetExists then
                    Target.Init();
                Target."Tipo Documento" := Source."Tipo Documento";
                Target."No. Documento" := Source."No. Documento";
                Target."Tipo Identificacion" := Source."Tipo Identificacion";
                Target."Cod. Identificacion" := Source."Cod. Identificacion";
                Target."Cod. Proveedor" := Source."Cod. Proveedor";
                Target."Nombre Proveedor" := Source."Nombre Proveedor";
                Target.NCF := Source.NCF;
                Target."NCF Modificado" := Source."NCF Modificado";
                Target."Fecha Comprobante" := Source."Fecha Comprobante";
                Target."ITBIS Facturado" := Source."ITBIS Facturado";
                Target."Monto Facturado" := Source."Monto Facturado";
                Target."No. Linea" := Source."No. Linea";
                Target."Estado Reg." := Source."Estado Reg.";
                Target."Categoria NCF" := Source."Categoria NCF";
                Target."Fecha Pago" := Source."Fecha Pago";
                Target."ITBIS Retenido" := Source."ITBIS Retenido";
                Target."Estatus Proveedor" := Source."Estatus Proveedor";
                Target."Importe Ret. Renta" := Source."Importe Ret. Renta";
                Target."No. Doc. Externo" := Source."No. Doc. Externo";
                Target."Desc. Categoria NCF" := Source."Desc. Categoria NCF";
                Target."Razon Social" := Source."Razon Social";
                Target.AnoMes_Fcomprobante := Source.AnoMes_Fcomprobante;
                Target.Dia_Fcomprobante := Source.Dia_Fcomprobante;
                Target.AnoMes_FPago := Source.AnoMes_FPago;
                Target.Dia_FPago := Source.Dia_FPago;
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target."Monto Facturado Servicios" := Source."Monto Facturado Servicios";
                Target."Monto Facturado Bienes" := Source."Monto Facturado Bienes";
                Target."ITBIS Proporcionalidad" := Source."ITBIS Proporcionalidad";
                Target."ITBIS llevado al costo" := Source."ITBIS llevado al costo";
                Target."ITBIS por adelantar" := Source."ITBIS por adelantar";
                Target."ITBIS Percibido" := Source."ITBIS Percibido";
                Target."ISR withholding Type" := Source."ISR withholding Type";
                Target."ISR Percibido" := Source."ISR Percibido";
                Target."Imp. Selectivo al Consumo" := Source."Imp. Selectivo al Consumo";
                Target."Otros Impuestos/Tasas" := Source."Otros Impuestos/Tasas";
                Target."Monto Propina Legal" := Source."Monto Propina Legal";
                Target."Payment Methods 606-607" := Source."Payment Methods 606-607";
                Target."Reporta 606" := Source."Reporta 606";
                Target."Monto USD" := Source."Monto USD";
                Target."Exchange Rate Factor" := Source."Exchange Rate Factor";
                Target."NCF Year/Month" := Source."NCF Year/Month";
                Target."NCF Day" := Source."NCF Day";
                Target."Posting Year/Month" := Source."Posting Year/Month";
                Target."Posting Day" := Source."Posting Day";
                Target."Additional Currency Code" := Source."Additional Currency Code";
                Target."Additional Currency Factor" := Source."Additional Currency Factor";
                Target."Document Date" := Source."Document Date";
                Target."Currency Code" := Source."Currency Code";
                Target."Currency Factor" := Source."Currency Factor";
                Target."DX Original Amount" := Source."DX Original Amount";
                Target."DX Original ITBIS Amount" := Source."DX Original ITBIS Amount";
                Target."Withholding Date" := Source."Withholding Date";
                Target."Vendor Ledger Entry No." := Source."Vendor Ledger Entry No.";
                Target."Importe Ret. Renta ICY" := Source."Importe Ret. Renta ICY";
                Target."Monto Facturado Servicios ICY" := Source."Monto Facturado Servicios ICY";
                Target."Monto Facturado Bienes ICY" := Source."Monto Facturado Bienes ICY";
                Target."ITBIS Proporcionalidad ICY" := Source."ITBIS Proporcionalidad ICY";
                Target."ITBIS llevado al costo ICY" := Source."ITBIS llevado al costo ICY";
                Target."ITBIS por adelantar ICY" := Source."ITBIS por adelantar ICY";
                Target."ITBIS Percibido ICY" := Source."ITBIS Percibido ICY";
                Target."ISR Percibido ICY" := Source."ISR Percibido ICY";
                Target."Imp. Selectivo al Consumo ICY" := Source."Imp. Selectivo al Consumo ICY";
                Target."Otros Impuestos/Tasas ICY" := Source."Otros Impuestos/Tasas ICY";
                Target."Monto Propina Legal ICY" := Source."Monto Propina Legal ICY";
                Target."ITBIS Retenido ICY" := Source."ITBIS Retenido ICY";
                Target."Posting Description" := Source."Posting Description";
                Target."VAT Bus. Posting Group" := Source."VAT Bus. Posting Group";
                Target."ITBIS Facturado ICY" := Source."ITBIS Facturado ICY";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Bank Charges Lines - all 9 fields common (see codeunit-level Batch 2 shadow-field comment).
    // Working/staging table holding only currently-unarchived (not-yet-posted) document lines - no
    // periodic Commit() needed (same precedent as Purchase Header/Sales Header in Phase 4). Upsert-by-
    // primary-key ("No.", "Line No.") - safe to re-run.
    local procedure MigrateBankChargesLines()
    var
        Source: Record "DX Bank Charges Lines";
        Target: Record "DXR_Bank Charges Lines";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."No.", Source."Line No.");
                if not TargetExists then
                    Target.Init();
                Target."No." := Source."No.";
                Target."DXTransaction Date" := Source."DXTransaction Date";
                Target.NCF := Source.NCF;
                Target.Amount := Source.Amount;
                Target."Line No." := Source."Line No.";
                Target."Apply Trans." := Source."Apply Trans.";
                Target.Description := Source.Description;
                Target."Vendor No." := Source."Vendor No.";
                Target."NCF Afectado" := Source."NCF Afectado";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Bank Commission Setup - all 4 fields common (see codeunit-level Batch 2 shadow-field comment).
    // Tiny per-bank-account setup table - no periodic Commit() needed. Upsert-by-primary-key
    // ("Bank Account No.") - safe to re-run.
    local procedure MigrateBankCommissionSetup()
    var
        Source: Record "DX Bank Commission Setup";
        Target: Record "DXR_Bank Commission Setup";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Bank Account No.");
                if not TargetExists then
                    Target.Init();
                Target."Bank Account No." := Source."Bank Account No.";
                Target."Bank Account Name" := Source."Bank Account Name";
                Target."GL Account No." := Source."GL Account No.";
                Target."GL Account Name" := Source."GL Account Name";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Cash Receipt Header - all 40 fields common (see codeunit-level Batch 2 shadow-field comment;
    // fields 40-47 carry ObsoleteState = Pending on the destination table only, still Class = Normal
    // and still copied). Status field holds both Open and Posted rows on this same table (no separate
    // archive) - genuinely ever-growing history-scale table - periodic Commit() every 100 rows added.
    // Upsert-by-primary-key ("No.") - safe to re-run.
    local procedure MigrateCashReceiptHeader()
    var
        Source: Record "DX Cash Receipt Header";
        Target: Record "DXR_Cash Receipt Header";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."No.");
                if not TargetExists then
                    Target.Init();
                Target."No." := Source."No.";
                Target.Fecha := Source.Fecha;
                Target."Cod. Customer" := Source."Cod. Customer";
                Target.Nombre := Source.Nombre;
                Target."Cod. Divisa" := Source."Cod. Divisa";
                Target."Factor Divisa" := Source."Factor Divisa";
                Target."No. Serie" := Source."No. Serie";
                Target."Document Type" := Source."Document Type";
                Target."Bal. Account Type" := Source."Bal. Account Type";
                Target."Bal. Account No." := Source."Bal. Account No.";
                Target."Applies-to Doc. Type" := Source."Applies-to Doc. Type";
                Target."Applies-to Doc. No." := Source."Applies-to Doc. No.";
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target.Description := Source.Description;
                Target."External Document No." := Source."External Document No.";
                Target.NCF := Source.NCF;
                Target.Beneficiario := Source.Beneficiario;
                Target.Status := Source.Status;
                Target."Importe Efectivo" := Source."Importe Efectivo";
                Target."Importe Tcr." := Source."Importe Tcr.";
                Target."Importe Cheque" := Source."Importe Cheque";
                Target."Importe Transf." := Source."Importe Transf.";
                Target."Tot. Monto Recibido" := Source."Tot. Monto Recibido";
                Target.Amount := Source.Amount;
                Target."Amount (LCY)" := Source."Amount (LCY)";
                Target."Imp. Fact. Sin ITBIS" := Source."Imp. Fact. Sin ITBIS";
                Target."Imp. ITBIS Facturado" := Source."Imp. ITBIS Facturado";
                Target."Total Fact. Incl. ITBIS" := Source."Total Fact. Incl. ITBIS";
                Target."ITBIS Withholding Code" := Source."ITBIS Withholding Code";
                Target."ITBIS Withholding %" := Source."ITBIS Withholding %";
                Target."ITBIS Withholding Base" := Source."ITBIS Withholding Base";
                Target."ITBIS Withholding Amount" := Source."ITBIS Withholding Amount";
                Target."ISR Withholding Code" := Source."ISR Withholding Code";
                Target."ISR Withholding %" := Source."ISR Withholding %";
                Target."ISR Withholding Base" := Source."ISR Withholding Base";
                Target."ISR Withholding Amount" := Source."ISR Withholding Amount";
                Target."Bank Commission Amount" := Source."Bank Commission Amount";
                Target."Bank Commission Account" := Source."Bank Commission Account";
                Target."Dimension Set ID" := Source."Dimension Set ID";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Cash Receipt Line - all 40 fields common (see codeunit-level Batch 2 shadow-field comment; same
    // ObsoleteState = Pending-on-destination-only note on fields 40-47 as Cash Receipt Header). Same
    // ever-growing rationale as Cash Receipt Header - periodic Commit() every 100 rows added. Upsert-
    // by-primary-key ("Document No.", "Line No.") - safe to re-run.
    local procedure MigrateCashReceiptLine()
    var
        Source: Record "DX Cash Receipt Line";
        Target: Record "DXR_Cash Receipt Line";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Document No.", Source."Line No.");
                if not TargetExists then
                    Target.Init();
                Target."Document No." := Source."Document No.";
                Target."Line No." := Source."Line No.";
                Target."Posting Date" := Source."Posting Date";
                Target."Account No." := Source."Account No.";
                Target."Customer Name" := Source."Customer Name";
                Target.NCF := Source.NCF;
                Target.Beneficiario := Source.Beneficiario;
                Target."Document Type" := Source."Document Type";
                Target."External Document No." := Source."External Document No.";
                Target.Description := Source.Description;
                Target."Bal. Account Type" := Source."Bal. Account Type";
                Target."Bal. Account No." := Source."Bal. Account No.";
                Target."Currency Code" := Source."Currency Code";
                Target."Currency Factor" := Source."Currency Factor";
                Target."Applies-to Doc. Type" := Source."Applies-to Doc. Type";
                Target."Applies-to Doc. No." := Source."Applies-to Doc. No.";
                Target."Applies-to ID" := Source."Applies-to ID";
                Target."Importe Efectivo" := Source."Importe Efectivo";
                Target."Importe Tcr." := Source."Importe Tcr.";
                Target."Importe Cheque" := Source."Importe Cheque";
                Target."Importe Transf." := Source."Importe Transf.";
                Target."Tot. Monto Recibido" := Source."Tot. Monto Recibido";
                Target.Amount := Source.Amount;
                Target."Amount (LCY)" := Source."Amount (LCY)";
                Target."Imp. Fact. Sin ITBIS" := Source."Imp. Fact. Sin ITBIS";
                Target."Imp. ITBIS Facturado" := Source."Imp. ITBIS Facturado";
                Target."Total Fact. Incl. ITBIS" := Source."Total Fact. Incl. ITBIS";
                Target."ITBIS Withholding Code" := Source."ITBIS Withholding Code";
                Target."ITBIS Withholding %" := Source."ITBIS Withholding %";
                Target."ITBIS Withholding Base" := Source."ITBIS Withholding Base";
                Target."ITBIS Withholding Amount" := Source."ITBIS Withholding Amount";
                Target."ISR Withholding Code" := Source."ISR Withholding Code";
                Target."ISR Withholding %" := Source."ISR Withholding %";
                Target."ISR Withholding Base" := Source."ISR Withholding Base";
                Target."ISR Withholding Amount" := Source."ISR Withholding Amount";
                Target."Bank Commission Amount" := Source."Bank Commission Amount";
                Target."Bank Commission Account" := Source."Bank Commission Account";
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target."Dimension Set ID" := Source."Dimension Set ID";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Consumer Sales 607 Buffer - 45 common fields (field 13 Mensajes and fields 17-28 "Total ..."
    // fields are FlowFields on both sides, field 36002769 "Additional Currency Code" carries
    // ObsoleteState = Removed on both sides - all excluded, see codeunit-level Batch 3 shadow-field
    // comment). History-scale table (DGII 607 consumer-sales tax reporting data), periodic Commit()
    // every 100 rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento", "No. Linea") -
    // safe to re-run.
    local procedure MigrateConsumerSales607Buffer()
    var
        Source: Record "DX Consumer Sales 607 Buffer";
        Target: Record "DXR_Consumer Sales 607 Buffer";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea");
                if not TargetExists then
                    Target.Init();
                Target."Tipo Documento" := Source."Tipo Documento";
                Target."No. Documento" := Source."No. Documento";
                Target."Tipo Identificacion" := Source."Tipo Identificacion";
                Target."Cod. Identificacion" := Source."Cod. Identificacion";
                Target."Cod. Cliente" := Source."Cod. Cliente";
                Target."Nombre Cliente" := Source."Nombre Cliente";
                Target.NCF := Source.NCF;
                Target."NCF Modificado" := Source."NCF Modificado";
                Target."Fecha Comprobante" := Source."Fecha Comprobante";
                Target."ITBIS Facturado" := Source."ITBIS Facturado";
                Target."Monto Facturado" := Source."Monto Facturado";
                Target."No. Linea" := Source."No. Linea";
                Target."Estado Reg." := Source."Estado Reg.";
                Target."Report 607" := Source."Report 607";
                Target."Date Filter" := Source."Date Filter";
                Target."Cheque/Transf./Deposito ICY" := Source."Cheque/Transf./Deposito ICY";
                Target."Type of Income" := Source."Type of Income";
                Target."Fecha Retencion" := Source."Fecha Retencion";
                Target."ITBIS Retenido por Terceros" := Source."ITBIS Retenido por Terceros";
                Target."ITBIS Percibido" := Source."ITBIS Percibido";
                Target."Retencion Renta por Terceros" := Source."Retencion Renta por Terceros";
                Target."ISR Percibido" := Source."ISR Percibido";
                Target."Imp. Selectivo al Consumo" := Source."Imp. Selectivo al Consumo";
                Target."Otros Impuestos o Tasas" := Source."Otros Impuestos o Tasas";
                Target."Monto Propina Legal" := Source."Monto Propina Legal";
                Target.Efectivo := Source.Efectivo;
                Target."Cheque/Transferencia/Deposito" := Source."Cheque/Transferencia/Deposito";
                Target."Tarjeta Debito/Credito" := Source."Tarjeta Debito/Credito";
                Target."Venta a Credito" := Source."Venta a Credito";
                Target."Bonos o Certificados de Regalo" := Source."Bonos o Certificados de Regalo";
                Target.Permuta := Source.Permuta;
                Target."Otras Formas de Ventas" := Source."Otras Formas de Ventas";
                Target."Fuente Datos" := Source."Fuente Datos";
                Target."Additional Currency Factor" := Source."Additional Currency Factor";
                Target."Addit. Currency Code" := Source."Addit. Currency Code";
                Target."Currency Code" := Source."Currency Code";
                Target."Currency Factor" := Source."Currency Factor";
                Target."DX Original Amount" := Source."DX Original Amount";
                Target."DX Original ITBIS Amount" := Source."DX Original ITBIS Amount";
                Target."Efectivo ICY" := Source."Efectivo ICY";
                Target."Tarjeta Debito/Credito ICY" := Source."Tarjeta Debito/Credito ICY";
                Target."Venta a Credito ICY" := Source."Venta a Credito ICY";
                Target."Bonos o Certif. de Regalo ICY" := Source."Bonos o Certif. de Regalo ICY";
                Target."Permuta ICY" := Source."Permuta ICY";
                Target."Otras Formas de Ventas ICY" := Source."Otras Formas de Ventas ICY";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Customer Withholding Entries - all 23 fields common (see codeunit-level Batch 3 shadow-field
    // comment). Ledger-entry-style history table - periodic Commit() every 100 rows added. Upsert-by-
    // primary-key ("Fecha Retencion", "No. Documento", "Tipo Retencion", "No. Linea") - safe to re-run.
    local procedure MigrateCustomerWithholdingEntries()
    var
        Source: Record "DXCustomer Withholding Entries";
        Target: Record "DXR_Cust Withhold Entries";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Fecha Retencion", Source."No. Documento", Source."Tipo Retencion", Source."No. Linea");
                if not TargetExists then
                    Target.Init();
                Target."Fecha Retencion" := Source."Fecha Retencion";
                Target."No. Documento" := Source."No. Documento";
                Target."Nombre Beneficiario" := Source."Nombre Beneficiario";
                Target."RNC/Cedula" := Source."RNC/Cedula";
                Target."Tipo Retencion" := Source."Tipo Retencion";
                Target."Importe Retenido" := Source."Importe Retenido";
                Target."No. Factura" := Source."No. Factura";
                Target."Monto Facturado" := Source."Monto Facturado";
                Target."No. Linea" := Source."No. Linea";
                Target."Fecha Factura" := Source."Fecha Factura";
                Target."Cod. Customer" := Source."Cod. Customer";
                Target."NCF Afectado" := Source."NCF Afectado";
                Target."Cod. Retencion ITBIS" := Source."Cod. Retencion ITBIS";
                Target."Cod. Retencion ISR" := Source."Cod. Retencion ISR";
                Target.Reverse := Source.Reverse;
                Target."Currency Code" := Source."Currency Code";
                Target."Amount Excl. VAT" := Source."Amount Excl. VAT";
                Target."Currency Factor" := Source."Currency Factor";
                Target."Exchange Rate" := Source."Exchange Rate";
                Target."Original Amount LCY" := Source."Original Amount LCY";
                Target."Withhold Amount LCY" := Source."Withhold Amount LCY";
                Target."Withholding Apply Type" := Source."Withholding Apply Type";
                Target."Payment Date" := Source."Payment Date";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Customer Withholding Header - all 17 fields common (see codeunit-level Batch 3 shadow-field
    // comment). Document-header-style history table (pairs with Customer Withholding Entries above) -
    // periodic Commit() every 100 rows added. Upsert-by-primary-key ("No.") - safe to re-run.
    local procedure MigrateCustomerWithholdingHeader()
    var
        Source: Record "DXCustomer Withholding Header";
        Target: Record "DXR_Cust Withhold Header";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."No.");
                if not TargetExists then
                    Target.Init();
                Target."No." := Source."No.";
                Target.Fecha := Source.Fecha;
                Target."Cod. Customer" := Source."Cod. Customer";
                Target.Nombre := Source.Nombre;
                Target."Cod. Divisa" := Source."Cod. Divisa";
                Target."Factor Divisa" := Source."Factor Divisa";
                Target."No. Serie" := Source."No. Serie";
                Target."No. Serie Registro" := Source."No. Serie Registro";
                Target."Aplicar a Factura No." := Source."Aplicar a Factura No.";
                Target."Imp. ITBIS Facturado" := Source."Imp. ITBIS Facturado";
                Target."Imp. Fact. Sin ITBIS" := Source."Imp. Fact. Sin ITBIS";
                Target."Total Fact. Incl. ITBIS" := Source."Total Fact. Incl. ITBIS";
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target."Dimension Set ID" := Source."Dimension Set ID";
                Target."Cod. Retencion ISR" := Source."Cod. Retencion ISR";
                Target."Cod. Retencion ITBIS" := Source."Cod. Retencion ITBIS";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // Dependencies Metadata - all 5 fields common (see codeunit-level Batch 3 shadow-field comment).
    // DataPerCompany = false on both sides - tiny global installed-extension-list setup table - no
    // periodic Commit() needed. Upsert-by-primary-key (AppId) - safe to re-run.
    local procedure MigrateDependenciesMetadata()
    var
        Source: Record "DX Dependencies Metadata";
        Target: Record "DXR_Dependencies Metadata";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source.AppId);
                if not TargetExists then
                    Target.Init();
                Target.AppId := Source.AppId;
                Target."App Name" := Source."App Name";
                Target."App Version" := Source."App Version";
                Target.Publisher := Source.Publisher;
                Target."Is Activated" := Source."Is Activated";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Detalle Servicio Adquirido - all 3 fields common (see codeunit-level Batch 3 shadow-field
    // comment). Small reference/lookup table (service-type sub-code + description) - no periodic
    // Commit() needed. Upsert-by-primary-key ("Tipo Servicio Adquirido", "Code") - safe to re-run.
    local procedure MigrateDetalleServicioAdquirido()
    var
        Source: Record DxDetalleServicioAdquirido;
        Target: Record DXR_R_DetalleServicioAdquirido;
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Tipo Servicio Adquirido", Source."Code");
                if not TargetExists then
                    Target.Init();
                Target."Tipo Servicio Adquirido" := Source."Tipo Servicio Adquirido";
                Target."Code" := Source."Code";
                Target.Description := Source.Description;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // DGI API Services - all 12 fields common, including ContributorType (Enum "DX ApiDGIServices
    // Contr. Type" vs Enum "DXR_ApiDGIServices Contr. Type" - different enum objects, identical member
    // values 1/2/3, ported via FromInteger()/AsInteger(), see codeunit-level Batch 3 shadow-field
    // comment). Frozen legacy history-scale table (current live code only ever returns temporary
    // records shaped by this table) - periodic Commit() every 100 rows added. Upsert-by-primary-key
    // ("RNC") - safe to re-run.
    local procedure MigrateDGIApiServices()
    var
        Source: Record "DX DGI ApiServices";
        Target: Record "DXR_DGI ApiServices";
        TargetContributorType: Enum "DXR_ApiDGIServices Contr. Type";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetContributorType := Enum::"DXR_ApiDGIServices Contr. Type".FromInteger(Source.ContributorType.AsInteger());
                TargetExists := Target.Get(Source.RNC);
                if not TargetExists then
                    Target.Init();
                Target."Code" := Source."Code";
                Target.RNC := Source.RNC;
                Target."Name" := Source."Name";
                Target.ComercialName := Source.ComercialName;
                Target.Category := Source.Category;
                Target.PaymentScheme := Source.PaymentScheme;
                Target.Status := Source.Status;
                Target.Valid := Source.Valid;
                Target.Date := Source.Date;
                Target.Count := Source.Count;
                Target.ContributorType := TargetContributorType;
                Target.ReferenceNo := Source.ReferenceNo;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // DGI API Services FindByName - same 12-field shape/same ContributorType enum-object difference as
    // MigrateDGIApiServices above (see codeunit-level Batch 3 shadow-field comment). Neither side
    // declares a keys block in real source - the implicit primary key is ALL 12 fields, in field-
    // declaration order (AL's own default-key rule for tables with no keys property) - Get() below
    // supplies all 12 source-derived values (ContributorType converted first). Same frozen-legacy-cache
    // rationale as MigrateDGIApiServices - periodic Commit() every 100 rows added.
    local procedure MigrateDGIApiServicesFindByName()
    var
        Source: Record "DX DGI ApiServices FindByName";
        Target: Record "DXR_DGI ApiServices FindByName";
        TargetContributorType: Enum "DXR_ApiDGIServices Contr. Type";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetContributorType := Enum::"DXR_ApiDGIServices Contr. Type".FromInteger(Source.ContributorType.AsInteger());
                TargetExists := Target.Get(
                    Source."Code", Source.RNC, Source."Name", Source.ComercialName, Source.Category,
                    Source.PaymentScheme, Source.Status, Source.Valid, Source.Date, Source.Count,
                    TargetContributorType, Source.ReferenceNo);
                if not TargetExists then
                    Target.Init();
                Target."Code" := Source."Code";
                Target.RNC := Source.RNC;
                Target."Name" := Source."Name";
                Target.ComercialName := Source.ComercialName;
                Target.Category := Source.Category;
                Target.PaymentScheme := Source.PaymentScheme;
                Target.Status := Source.Status;
                Target.Valid := Source.Valid;
                Target.Date := Source.Date;
                Target.Count := Source.Count;
                Target.ContributorType := TargetContributorType;
                Target.ReferenceNo := Source.ReferenceNo;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // DGII Temp Table - same 12-field shape/same ContributorType enum-object difference/same no-
    // explicit-keys (all-12-fields primary key) as MigrateDGIApiServicesFindByName above (see codeunit-
    // level Batch 3 shadow-field comment). Confirmed via DXR_DgiApiServices.Codeunit.al
    // (DGiServicesGetByName()) that this table is fully cleared at the start of every real use despite
    // being a real (non-AL-temporary) persisted table - genuinely transient/scratch, not accumulated
    // history - no periodic Commit() needed. Upsert-by-all-12-fields-as-key - safe to re-run.
    local procedure MigrateDGIITempTable()
    var
        Source: Record "DX DGII Temp Table";
        Target: Record "DXR_DGII Temp Table";
        TargetContributorType: Enum "DXR_ApiDGIServices Contr. Type";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetContributorType := Enum::"DXR_ApiDGIServices Contr. Type".FromInteger(Source.ContributorType.AsInteger());
                TargetExists := Target.Get(
                    Source."Code", Source.RNC, Source."Name", Source.ComercialName, Source.Category,
                    Source.PaymentScheme, Source.Status, Source.Valid, Source.Date, Source.Count,
                    TargetContributorType, Source.ReferenceNo);
                if not TargetExists then
                    Target.Init();
                Target."Code" := Source."Code";
                Target.RNC := Source.RNC;
                Target."Name" := Source."Name";
                Target.ComercialName := Source.ComercialName;
                Target.Category := Source.Category;
                Target.PaymentScheme := Source.PaymentScheme;
                Target.Status := Source.Status;
                Target.Valid := Source.Valid;
                Target.Date := Source.Date;
                Target.Count := Source.Count;
                Target.ContributorType := TargetContributorType;
                Target.ReferenceNo := Source.ReferenceNo;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;
}
