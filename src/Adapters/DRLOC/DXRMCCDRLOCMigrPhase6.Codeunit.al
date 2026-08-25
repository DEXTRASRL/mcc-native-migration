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
    // the shared ConvertContributorType() helper (FromInteger()/AsInteger(), guarded against the
    // unmapped ordinal 0 that a never-explicitly-set legacy field defaults to - CopyCommonFields()'s raw
    // FieldRef transfer tolerates that unmapped value silently, but Enum.FromInteger() does not, so an
    // unguarded direct port would throw at runtime for such rows; same discipline as seq51/52's Batch 1
    // enum conversions, plus this additional guard).
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
    //     header note above, ported via the guarded ConvertContributorType() helper (see that
    //     procedure's own comment - neither enum declares a member at ordinal 0, so a legacy row whose
    //     ContributorType was never set is left at the target field's default instead of erroring, unlike
    //     an unguarded FromInteger() call). All 12 fields common, nothing excluded. Confirmed via
    //     DXR_DgiApiServices.Codeunit.al that current live code never calls
    //     Insert()/Modify()/Get() against the real, persisted table itself (only fills this table's
    //     shape in-memory, via "... temporary" return vars or a plain buffer var that's never persisted,
    //     before forwarding into the separate "DXR_DGII Temp Table") - its real row content is frozen
    //     legacy data from before that refactor, history-scale - periodic Commit() every 100 rows added.
    //     Upsert-by-primary-key ("RNC") - safe
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
    //
    // ===== Batch 4 (FINAL): last 8 of 24 generic-loop whole-table clones (seq88-95) - closes out Phase 6
    //   and DRLOC's entire native-porting campaign =====
    // Continuation of Batch 2/3's discipline for the same real generic MigrateTable() helper (real source
    // lines 91-114; this batch's 8 call-sites are lines 107-114, re-verified directly against real source
    // rather than trusted from the line-number hint alone).
    //
    // Registry cross-check for all 8 rows in this batch (seq88-95): independently re-verified every row's
    // Old/New Table ID pair against real source's own MigrateTable() call arguments AND both real table
    // object declarations - all 8 registry rows' Old/New Table IDs are CORRECT, no data error found this
    // batch (unlike seq73 in Batch 2).
    //   - seq91's own registry comment ("same destination as DRLOC-P2's Purchase Type Relation")
    //     independently re-verified and found to be CORRECT this time (unlike seq73's wrong claim,
    //     corrected in Batch 2) - real source confirms TWO separate, genuinely different legacy tables
    //     both converge on the same real destination table 52242 "DXR_Purchase Type Relation": DRLOC-P2's
    //     own seq55 (codeunit 60165, DXR_Migr_Phase_2_Fiscal.Codeunit.al real source) migrates legacy
    //     table 54140 "DXPurchase Type Relation" (no space after "DX") into 52242, while THIS batch's
    //     seq91 migrates a DIFFERENT, later-generation legacy table, 54167 "DX Purchase Type Relation"
    //     (space after "DX" - the "space-variant" the registry description refers to) into the SAME 52242.
    //     Confirmed via "DXPurchaseTypeRelation.Table.Obsolete.al" (54140)'s own ObsoleteReason
    //     ('Obsolete in 25.5.0.136 replaced by Table 54167 - 36002832 "DX Purchase Type Relation"') and
    //     "DXPurchaseTypeRelation.Table.al" (54167)'s own ObsoleteReason ('Replaced by the DXR-prefixed
    //     table for Business Central 28') that this is a genuine two-generation chain (54140 -> 54167 ->
    //     52242), not a registry data error - both DRLOC-P2 seq55 and this batch's seq91 are legitimate,
    //     independent whole-table clones of two different legacy sources into the same live destination.
    //     No registry correction needed for seq91.
    //
    // Registry seq5 ('DRLOC-P6', "History migration phase", Dispatcher Codeunit 60069, Old/New Table ID
    // both 0) is a pre-existing coarse phase-marker row, NOT one of the 27 concrete Phase 6 steps this
    // campaign covers (registry seq50-53/73-95) - correctly left untouched, same treatment as registry
    // seq49's deferred piece elsewhere in this campaign (see Phase 5's own codeunit header). Not a missed
    // row; do not repoint or retire it as part of this batch.
    //
    // Two NEW cross-enum fields found this batch (same permissive-raw-copy situation as seq85/86/87's
    // ContributorType in Batch 3 - a DIFFERENT enum object on old vs new side, but the real generic loop's
    // GetCommonCompatibleFieldNos() still treats them as "the same Type" since both are generically enum-
    // typed, so CopyCommonFields() raw-transfers the ordinal regardless of which specific enum each side
    // declares) - both ported via their own guarded conversion helper below, following the same
    // ConvertContributorType() discipline established in Batch 3:
    //   - "Order Process Status" (field 36002821, shared by seq88 History Purchase Header AND seq89
    //     History Purchase Line): Enum "DX PO Process Status" (54111, obsolete) on the old side vs Enum
    //     "DXR_PO Process Status" (52203, live) on the new side - ported via ConvertPOProcessStatus()
    //     below. Unlike ContributorType, both enums declare identical members at every ordinal in their
    //     range (0/1/2, "Original Order"/"Received Order"/"Invoiced Order") - the guard can never actually
    //     reject a legacy value here, but is still applied for consistency with this codeunit's own
    //     established discipline of never calling an unguarded FromInteger() against a genuinely
    //     different-enum-object field. Notably, on BOTH tables this field is part of the real, identically
    //     -shaped primary key (Header Key1: "Document Type", "No.", "Order Process Status"; Line Key1:
    //     "Document Type", "Document No.", "Line No.", "Order Process Status", both Clustered) - the
    //     converted value must be computed BEFORE calling Target.Get(), same pattern as seq51's Source
    //     Type conversion in this codeunit's MigrateEFSendRegistry() above. Asymmetric risk vs.
    //     ContributorType (Batch 3): because this field is part of the primary key here (unlike
    //     ContributorType on seq85), if the two enums' member sets were ever to diverge in the future, two
    //     source rows both falling into ConvertPOProcessStatus()'s unmapped-ordinal fallback with matching
    //     other key fields would silently MERGE via Get-then-Modify - losing one whole target row, not
    //     just one field's value like ContributorType's fallback would. Purely informational today: both
    //     enums are provably identical (0/1/2 on both sides), so the fallback branch is unreachable in
    //     practice - no functional change made here, just flagging the difference for future readers.
    //   - "Tipo Comprobante" (field 3, seq90 NCF Process Registration only, NOT part of that table's
    //     primary key "NCF, Document No."): Enum "DX Fiscal Doc. Type" (54100, obsolete) vs Enum
    //     "DXR_Fiscal Doc. Type" (52250, live) - ported via ConvertFiscalDocType() below. Both enums
    //     declare identical members at ordinals 0-10 (confirmed against both enum source files) - same
    //     "guard can never actually reject a value, kept for consistency" situation as
    //     ConvertPOProcessStatus() above.
    //
    // Full field-by-field common-field derivation (independently re-read against real, current source for
    // BOTH the legacy DX-prefixed table AND its DXR-prefixed replacement, per table - full derivation, not
    // sampled):
    //   - seq88 (History Purchase Header, 54163 -> 52237): "DX History Purchase Header"/"DXR_History
    //     Purchase Header" - 150 common fields out of 152 total field declarations: field 5754 "Location
    //     Filter" and field 5796 "Date Filter" are BOTH FieldClass = FlowFilter on both old and new sides
    //     (Class <> Normal, excluded by the real loop's own Class = Normal filter) - all other 150 fields
    //     match by number+type, including field 36002821 "Order Process Status" (cross-enum, see above;
    //     part of the primary key). History-scale table (purchase-document history/archive snapshot,
    //     registry Category HIST) - periodic Commit() every 100 rows added. Upsert-by-primary-key
    //     ("Document Type", "No.", "Order Process Status") - safe to re-run.
    //   - seq89 (History Purchase Line, 54164 -> 52239): "DX History Purchase Line"/"DXR_History Purchase
    //     Line" - 204 common fields out of 206 total field declarations: field 5705 "Cross-Reference No."
    //     carries ObsoleteState = Removed on BOTH sides under the CLEAN17 compile-time symbol (which this
    //     campaign's BC28-targeted symbols resolve as active, confirmed by the field not existing in
    //     either compiled table's Field metadata - referencing it in typed AL is a compile error, matching
    //     the real generic loop's own inability to see it via GetCommonCompatibleFieldNos()), and field
    //     5712 "Product Group Code" carries ObsoleteState = Removed unconditionally on both sides - both
    //     excluded. All remaining 204 fields match by number+type, including field 36002821 "Order Process
    //     Status" (cross-enum, see above; part of the primary key, same pairing table as seq88). Same
    //     history-scale rationale as seq88 - periodic Commit() every 100 rows added. Upsert-by-primary-key
    //     ("Document Type", "Document No.", "Line No.", "Order Process Status") - safe to re-run.
    //   - seq90 (NCF Process Registration, 54166 -> 52241): "DX NCF Process Registration"/"DXR_NCF Process
    //     Registration" - 6 fields total on both sides, identical numbers/types - all 6 common
    //     (field 3 "Tipo Comprobante" is the cross-enum field discussed above, not part of the primary
    //     key). Small fiscal-document-tracking table - no periodic Commit() needed (Registry Category HIST
    //     notwithstanding, real row volume here is one row per still-valid NCF, not a growing ledger).
    //     Upsert-by-primary-key (NCF, "Document No.") - safe to re-run.
    //   - seq91 (Purchase Type Relation V27, 54167 -> 52242): "DX Purchase Type Relation"/"DXR_Purchase
    //     Type Relation" - 2 fields total on both sides ("Grupo Contable Prod." Code[20], Tipo - a plain
    //     Option with identical OptionMembers " ",Bienes,Servicios on both sides, not a cross-enum
    //     situation), identical numbers/types - both common, nothing excluded. See the shared-destination
    //     investigation note above. Tiny per-posting-group setup table - no periodic Commit() needed.
    //     Upsert-by-primary-key ("Grupo Contable Prod.") - safe to re-run.
    //   - seq92 (Report Logs, 54158 -> 52228): "Dx Report Logs"/"DXR_Report Logs" - 8 common fields out of
    //     9 total field declarations: field 54106 "Modified By User." is a FlowField on both sides (Class
    //     <> Normal, excluded). All other 8 fields (54100, 54101, 54102, 54103, 54104, 54107, 54108,
    //     54109) match by number+type - field 54109 is named DXNCF on the old side vs NCF_DXR on the new
    //     side (name differs, number+type identical - matching real behavior which matches on number+type
    //     only). Real source's own OnInsert() trigger (a "Document Type." self-to-self reassignment,
    //     effectively a no-op) is not replicated, since Target.Insert(false) below suppresses table
    //     triggers exactly as real source's own TargetRecRef.Insert(false) does. Transaction-history-scale
    //     table - periodic Commit() every 100 rows added. Upsert-by-primary-key ("Entry No.",
    //     AutoIncrement) - safe to re-run (an explicitly-supplied non-zero AutoIncrement value is honored
    //     as-is by Insert(), same precedent as seq52's NCF Fiscal Queue in this codeunit).
    //   - seq93 (Report Sales 607 Buffer, 54151 -> 52215): "DX Report Sales 607 Buffer"/"DXR_Report Sales
    //     607 Buffer" - 43 common fields out of 62 total field declarations: field 13 (Mensajes) and
    //     fields 17-33 (17 fields, all FlowFields aggregating 607-report totals) are FlowFields on both
    //     sides; field 16 "Date Filter" is FieldClass = FlowFilter on both sides - all 19 excluded (Class
    //     <> Normal on both). All remaining 43 fields (1-12, 14, 36002752-36002768, 36002770-36002782
    //     including the legacy-typo'd field number 3600277 "Cheque/Transf./Deposito ICY", identically
    //     present with the same typo'd number on both old and new tables) match by number+type - all 43
    //     common, nothing else excluded (same typo-preservation precedent as Batch 2's seq74). History-
    //     scale table (DGII 607 sales tax reporting data, registry Category HIST) - periodic Commit()
    //     every 100 rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento", "No. Linea") -
    //     safe to re-run.
    //   - seq94 (Sending Pay Services Abroad 609, 54156 -> 52222): "DXSendingPayServicesAbroad609"/
    //     "DXR_SendPayServAbroad609" - 15 fields total on both sides, identical numbers/types - all 15
    //     common, nothing excluded (field 2, "DXTax Identificaction Type" on the old side vs "Tax
    //     Identificaction Type_DXR" on the new side, is a plain Option with identical OptionMembers on
    //     both sides - name differs, not a cross-enum situation). DGII 609-report tracking table -
    //     periodic Commit() every 100 rows added (registry Category HIST). Upsert-by-primary-key
    //     ("Numero de Documento", "No Linea") - safe to re-run.
    //   - seq95 (Tipo Servicio Adquirido, 54153 -> 52218): "DxTipoServicioAdquirido"/
    //     "DXR_R_TipoServicioAdquirido" - 2 fields total on both sides (Code[10] "Code", Text[100]
    //     Description), identical numbers/types - both common, nothing excluded. Tiny reference/lookup
    //     table (service-type code + description) - no periodic Commit() needed. Upsert-by-primary-key
    //     ("Code") - safe to re-run.
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
        tabledata "DXR_DGII Temp Table" = RIM,
        tabledata "DX History Purchase Header" = R,
        tabledata "DXR_History Purchase Header" = RIM,
        tabledata "DX History Purchase Line" = R,
        tabledata "DXR_History Purchase Line" = RIM,
        tabledata "DX NCF Process Registration" = R,
        tabledata "DXR_NCF Process Registration" = RIM,
        tabledata "DX Purchase Type Relation" = R,
        tabledata "DXR_Purchase Type Relation" = RIM,
        tabledata "Dx Report Logs" = R,
        tabledata "DXR_Report Logs" = RIM,
        tabledata "DX Report Sales 607 Buffer" = R,
        tabledata "DXR_Report Sales 607 Buffer" = RIM,
        tabledata DXSendingPayServicesAbroad609 = R,
        tabledata DXR_SendPayServAbroad609 = RIM,
        tabledata DxTipoServicioAdquirido = R,
        tabledata DXR_R_TipoServicioAdquirido = RIM;

    trigger OnRun()
    var
        UpgradeTagMgt: Codeunit "Upgrade Tag";
        PhaseTags: Codeunit "DXR_Internal Migr. Phase Tags";
    begin
        // 2026-08-25 fix: added the outer completion gate real DR-Localization's own
        // "DXR_Migr. Phase 6 History" OnRun() uses (Phase6CompletedTag(), reused verbatim) - same
        // root-cause/fix as codeunit 60165's OnRun() comment (full re-scan on every invocation,
        // forever, contributing to a real reported production hang).
        if UpgradeTagMgt.HasUpgradeTag(PhaseTags.Phase6CompletedTag()) then
            exit;

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
        MigrateHistoryPurchaseHeader();
        MigrateHistoryPurchaseLine();
        MigrateNCFProcessRegistration();
        MigratePurchaseTypeRelationV27();
        MigrateReportLogs();
        MigrateReportSales607Buffer();
        MigrateSendingPayServicesAbroad609();
        MigrateTipoServicioAdquirido();

        UpgradeTagMgt.SetUpgradeTag(PhaseTags.Phase6CompletedTag());
    end;

    procedure RunSetup()
    begin
        MigrateAPIDgiSetup();
        MigrateBankCommissionSetup();
        MigrateDependenciesMetadata();
        MigratePurchaseTypeRelationV27();
        MigrateTipoServicioAdquirido();
    end;

    procedure RunHistoric()
    begin
        MigrateEFSendRegistry();
        MigrateNCFFiscalQueue();
        MigrateArchivedBankChargesLines();
        MigrateArchivedConsumerSales607();
        MigrateArchivedPurchase606Buffer();
        MigrateBankChargesLines();
        MigrateCashReceiptHeader();
        MigrateCashReceiptLine();
        MigrateConsumerSales607Buffer();
        MigrateCustomerWithholdingEntries();
        MigrateCustomerWithholdingHeader();
        MigrateDetalleServicioAdquirido();
        MigrateDGIApiServices();
        MigrateDGIApiServicesFindByName();
        MigrateDGIITempTable();
        MigrateHistoryPurchaseHeader();
        MigrateHistoryPurchaseLine();
        MigrateNCFProcessRegistration();
        MigrateReportLogs();
        MigrateReportSales607Buffer();
        MigrateSendingPayServicesAbroad609();
    end;

    procedure RunOther()
    begin
        MigrateOmittedStandardTableFields();
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

    // ContributorType ordinal-transfer conversion shared by MigrateDGIApiServices/
    // MigrateDGIApiServicesFindByName/MigrateDGIITempTable below. Both the old enum ("DX ApiDGIServices
    // Contr. Type", 54110) and the new enum ("DXR_ApiDGIServices Contr. Type", 52197) only declare
    // members at ordinals 1/2/3 - a legacy row whose ContributorType was never explicitly set defaults
    // to raw storage value 0, which has no enum member on either side. The real generic MigrateTable()
    // loop never hits this because CopyCommonFields() does a raw FieldRef.Value := FieldRef.Value
    // transfer that bypasses enum-membership validation entirely (silently writing an orphaned 0 into
    // storage); Enum.FromInteger() has no such bypass and errors for unmapped ordinals. This guard
    // matches the real loop's permissive behavior: recognized ordinals (1/2/3) convert normally,
    // anything else (e.g. 0 on frozen legacy rows predating this field being populated) is left at the
    // target field's own default/unset value instead of throwing.
    local procedure ConvertContributorType(SourceOrdinal: Integer): Enum "DXR_ApiDGIServices Contr. Type"
    begin
        if SourceOrdinal in [1, 2, 3] then
            exit(Enum::"DXR_ApiDGIServices Contr. Type".FromInteger(SourceOrdinal));
        // Unrecognized/legacy-unset ordinal (e.g. 0) - leave at default, matching the real generic
        // loop's permissive raw-value copy instead of erroring.
    end;

    // DGI API Services - all 12 fields common, including ContributorType (Enum "DX ApiDGIServices
    // Contr. Type" vs Enum "DXR_ApiDGIServices Contr. Type" - different enum objects, identical member
    // values 1/2/3, ported via ConvertContributorType() above, see codeunit-level Batch 3 shadow-field
    // comment). Frozen legacy history-scale table: current live code (DXR_DgiApiServices.Codeunit.al)
    // only ever fills this table's shape in-memory (via "... temporary" return vars in FillRec()/
    // FillFirstRecArray(), and via a plain non-temporary-but-never-Get/Insert/Modify'd buffer var in
    // FillRecArray()) and forwards the data into the separate "DXR_DGII Temp Table" - it never calls
    // Insert()/Modify()/Get() against the real, persisted "DXR_DGI ApiServices" table itself - so this
    // table's real row content is frozen legacy data from before that refactor. Periodic Commit() every
    // 100 rows added. Upsert-by-primary-key ("RNC") - safe to re-run.
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
                TargetContributorType := ConvertContributorType(Source.ContributorType.AsInteger());
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
    // supplies all 12 source-derived values (ContributorType converted first via ConvertContributorType()
    // above, guarded against unmapped legacy-unset ordinals). Same frozen-legacy-cache rationale as
    // MigrateDGIApiServices - periodic Commit() every 100 rows added.
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
                TargetContributorType := ConvertContributorType(Source.ContributorType.AsInteger());
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
                TargetContributorType := ConvertContributorType(Source.ContributorType.AsInteger());
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

    // PO Process Status ordinal-transfer conversion shared by MigrateHistoryPurchaseHeader/
    // MigrateHistoryPurchaseLine below. Both the old enum ("DX PO Process Status", 54111) and the new
    // enum ("DXR_PO Process Status", 52203) declare identical members at ordinals 0/1/2 ("Original
    // Order"/"Received Order"/"Invoiced Order") - unlike ContributorType (Batch 3), every legacy ordinal
    // has a mapped member on both sides, so this guard can never actually reject a value in practice; it
    // is still applied here for consistency with this codeunit's own established discipline (see
    // ConvertContributorType() above) of never calling an unguarded FromInteger() for a genuinely
    // different-enum-object field.
    // Asymmetric risk vs. ContributorType: "Order Process Status" is part of the real primary key on both
    // callers (unlike ContributorType), so if the two enums' member sets ever diverge, two source rows
    // both hitting the fallback with matching other key fields would silently merge one target row into
    // another via Get-then-Modify, instead of just losing one field's value - unreachable today (see
    // codeunit-level Batch 4 comment), purely informational.
    local procedure ConvertPOProcessStatus(SourceOrdinal: Integer): Enum "DXR_PO Process Status"
    begin
        if SourceOrdinal in [0, 1, 2] then
            exit(Enum::"DXR_PO Process Status".FromInteger(SourceOrdinal));
        // Unrecognized ordinal (not expected given both enums cover the same 0/1/2 range) - leave at
        // default instead of erroring, matching the real generic loop's permissive raw-value copy.
    end;

    // Fiscal Doc. Type ordinal-transfer conversion for MigrateNCFProcessRegistration below. Both the old
    // enum ("DX Fiscal Doc. Type", 54100) and the new enum ("DXR_Fiscal Doc. Type", 52250) declare
    // identical members at ordinals 0-10 - same "guard can never actually reject a value, kept for
    // consistency" situation as ConvertPOProcessStatus() above.
    local procedure ConvertFiscalDocType(SourceOrdinal: Integer): Enum "DXR_Fiscal Doc. Type"
    begin
        if SourceOrdinal in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10] then
            exit(Enum::"DXR_Fiscal Doc. Type".FromInteger(SourceOrdinal));
        // Unrecognized ordinal (not expected given both enums cover the same 0-10 range) - leave at
        // default instead of erroring, matching the real generic loop's permissive raw-value copy.
    end;

    // History Purchase Header - 150 common fields (2 FlowFilter fields excluded, "Order Process Status"
    // cross-enum-converted and part of the primary key - see codeunit-level Batch 4 shadow-field comment).
    // History-scale table - periodic Commit() every 100 rows added. Upsert-by-primary-key
    // ("Document Type", "No.", "Order Process Status") - safe to re-run.
    local procedure MigrateHistoryPurchaseHeader()
    var
        Source: Record "DX History Purchase Header";
        Target: Record "DXR_History Purchase Header";
        TargetOrderProcessStatus: Enum "DXR_PO Process Status";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetOrderProcessStatus := ConvertPOProcessStatus(Source."Order Process Status".AsInteger());
                TargetExists := Target.Get(Source."Document Type", Source."No.", TargetOrderProcessStatus);
                if not TargetExists then
                    Target.Init();
                Target."Document Type" := Source."Document Type";
                Target."Buy-from Vendor No." := Source."Buy-from Vendor No.";
                Target."No." := Source."No.";
                Target."Pay-to Vendor No." := Source."Pay-to Vendor No.";
                Target."Pay-to Name" := Source."Pay-to Name";
                Target."Pay-to Name 2" := Source."Pay-to Name 2";
                Target."Pay-to Address" := Source."Pay-to Address";
                Target."Pay-to Address 2" := Source."Pay-to Address 2";
                Target."Pay-to City" := Source."Pay-to City";
                Target."Pay-to Contact" := Source."Pay-to Contact";
                Target."Your Reference" := Source."Your Reference";
                Target."Ship-to Code" := Source."Ship-to Code";
                Target."Ship-to Name" := Source."Ship-to Name";
                Target."Ship-to Name 2" := Source."Ship-to Name 2";
                Target."Ship-to Address" := Source."Ship-to Address";
                Target."Ship-to Address 2" := Source."Ship-to Address 2";
                Target."Ship-to City" := Source."Ship-to City";
                Target."Ship-to Contact" := Source."Ship-to Contact";
                Target."Order Date" := Source."Order Date";
                Target."Posting Date" := Source."Posting Date";
                Target."Expected Receipt Date" := Source."Expected Receipt Date";
                Target."Posting Description" := Source."Posting Description";
                Target."Payment Terms Code" := Source."Payment Terms Code";
                Target."Due Date" := Source."Due Date";
                Target."Payment Discount %" := Source."Payment Discount %";
                Target."Pmt. Discount Date" := Source."Pmt. Discount Date";
                Target."Shipment Method Code" := Source."Shipment Method Code";
                Target."Location Code" := Source."Location Code";
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target."Vendor Posting Group" := Source."Vendor Posting Group";
                Target."Currency Code" := Source."Currency Code";
                Target."Currency Factor" := Source."Currency Factor";
                Target."Prices Including VAT" := Source."Prices Including VAT";
                Target."Invoice Disc. Code" := Source."Invoice Disc. Code";
                Target."Language Code" := Source."Language Code";
                Target."Purchaser Code" := Source."Purchaser Code";
                Target."Order Class" := Source."Order Class";
                Target.Comment := Source.Comment;
                Target."No. Printed" := Source."No. Printed";
                Target."On Hold" := Source."On Hold";
                Target."Applies-to Doc. Type" := Source."Applies-to Doc. Type";
                Target."Applies-to Doc. No." := Source."Applies-to Doc. No.";
                Target."Bal. Account No." := Source."Bal. Account No.";
                Target."Recalculate Invoice Disc." := Source."Recalculate Invoice Disc.";
                Target.Receive := Source.Receive;
                Target.Invoice := Source.Invoice;
                Target."Print Posted Documents" := Source."Print Posted Documents";
                Target.Amount := Source.Amount;
                Target."Amount Including VAT" := Source."Amount Including VAT";
                Target."Receiving No." := Source."Receiving No.";
                Target."Posting No." := Source."Posting No.";
                Target."Last Receiving No." := Source."Last Receiving No.";
                Target."Last Posting No." := Source."Last Posting No.";
                Target."Vendor Order No." := Source."Vendor Order No.";
                Target."Vendor Shipment No." := Source."Vendor Shipment No.";
                Target."Vendor Invoice No." := Source."Vendor Invoice No.";
                Target."Vendor Cr. Memo No." := Source."Vendor Cr. Memo No.";
                Target."VAT Registration No." := Source."VAT Registration No.";
                Target."Sell-to Customer No." := Source."Sell-to Customer No.";
                Target."Reason Code" := Source."Reason Code";
                Target."Gen. Bus. Posting Group" := Source."Gen. Bus. Posting Group";
                Target."Transaction Type" := Source."Transaction Type";
                Target."Transport Method" := Source."Transport Method";
                Target."VAT Country/Region Code" := Source."VAT Country/Region Code";
                Target."Buy-from Vendor Name" := Source."Buy-from Vendor Name";
                Target."Buy-from Vendor Name 2" := Source."Buy-from Vendor Name 2";
                Target."Buy-from Address" := Source."Buy-from Address";
                Target."Buy-from Address 2" := Source."Buy-from Address 2";
                Target."Buy-from City" := Source."Buy-from City";
                Target."Buy-from Contact" := Source."Buy-from Contact";
                Target."Pay-to Post Code" := Source."Pay-to Post Code";
                Target."Pay-to County" := Source."Pay-to County";
                Target."Pay-to Country/Region Code" := Source."Pay-to Country/Region Code";
                Target."Buy-from Post Code" := Source."Buy-from Post Code";
                Target."Buy-from County" := Source."Buy-from County";
                Target."Buy-from Country/Region Code" := Source."Buy-from Country/Region Code";
                Target."Ship-to Post Code" := Source."Ship-to Post Code";
                Target."Ship-to County" := Source."Ship-to County";
                Target."Ship-to Country/Region Code" := Source."Ship-to Country/Region Code";
                Target."Bal. Account Type" := Source."Bal. Account Type";
                Target."Order Address Code" := Source."Order Address Code";
                Target."Entry Point" := Source."Entry Point";
                Target.Correction := Source.Correction;
                Target."Document Date" := Source."Document Date";
                Target."Area" := Source."Area";
                Target."Transaction Specification" := Source."Transaction Specification";
                Target."Payment Method Code" := Source."Payment Method Code";
                Target."No. Series" := Source."No. Series";
                Target."Posting No. Series" := Source."Posting No. Series";
                Target."Receiving No. Series" := Source."Receiving No. Series";
                Target."Tax Area Code" := Source."Tax Area Code";
                Target."Tax Liable" := Source."Tax Liable";
                Target."VAT Bus. Posting Group" := Source."VAT Bus. Posting Group";
                Target."Applies-to ID" := Source."Applies-to ID";
                Target."VAT Base Discount %" := Source."VAT Base Discount %";
                Target.Status := Source.Status;
                Target."Invoice Discount Calculation" := Source."Invoice Discount Calculation";
                Target."Invoice Discount Value" := Source."Invoice Discount Value";
                Target."Send IC Document" := Source."Send IC Document";
                Target."IC Status" := Source."IC Status";
                Target."Buy-from IC Partner Code" := Source."Buy-from IC Partner Code";
                Target."Pay-to IC Partner Code" := Source."Pay-to IC Partner Code";
                Target."IC Direction" := Source."IC Direction";
                Target."Prepayment No." := Source."Prepayment No.";
                Target."Last Prepayment No." := Source."Last Prepayment No.";
                Target."Prepmt. Cr. Memo No." := Source."Prepmt. Cr. Memo No.";
                Target."Last Prepmt. Cr. Memo No." := Source."Last Prepmt. Cr. Memo No.";
                Target."Prepayment %" := Source."Prepayment %";
                Target."Prepayment No. Series" := Source."Prepayment No. Series";
                Target."Compress Prepayment" := Source."Compress Prepayment";
                Target."Prepayment Due Date" := Source."Prepayment Due Date";
                Target."Prepmt. Cr. Memo No. Series" := Source."Prepmt. Cr. Memo No. Series";
                Target."Prepmt. Posting Description" := Source."Prepmt. Posting Description";
                Target."Prepmt. Pmt. Discount Date" := Source."Prepmt. Pmt. Discount Date";
                Target."Prepmt. Payment Terms Code" := Source."Prepmt. Payment Terms Code";
                Target."Prepmt. Payment Discount %" := Source."Prepmt. Payment Discount %";
                Target."Quote No." := Source."Quote No.";
                Target."Job Queue Status" := Source."Job Queue Status";
                Target."Job Queue Entry ID" := Source."Job Queue Entry ID";
                Target."Incoming Document Entry No." := Source."Incoming Document Entry No.";
                Target."Creditor No." := Source."Creditor No.";
                Target."Payment Reference" := Source."Payment Reference";
                Target."A. Rcd. Not Inv. Ex. VAT (LCY)" := Source."A. Rcd. Not Inv. Ex. VAT (LCY)";
                Target."Amt. Rcd. Not Invoiced (LCY)" := Source."Amt. Rcd. Not Invoiced (LCY)";
                Target."Dimension Set ID" := Source."Dimension Set ID";
                Target."Invoice Discount Amount" := Source."Invoice Discount Amount";
                Target."No. of Archived Versions" := Source."No. of Archived Versions";
                Target."Doc. No. Occurrence" := Source."Doc. No. Occurrence";
                Target."Campaign No." := Source."Campaign No.";
                Target."Buy-from Contact No." := Source."Buy-from Contact No.";
                Target."Pay-to Contact No." := Source."Pay-to Contact No.";
                Target."Responsibility Center" := Source."Responsibility Center";
                Target."Partially Invoiced" := Source."Partially Invoiced";
                Target."Completely Received" := Source."Completely Received";
                Target."Posting from Whse. Ref." := Source."Posting from Whse. Ref.";
                Target."Requested Receipt Date" := Source."Requested Receipt Date";
                Target."Promised Receipt Date" := Source."Promised Receipt Date";
                Target."Lead Time Calculation" := Source."Lead Time Calculation";
                Target."Inbound Whse. Handling Time" := Source."Inbound Whse. Handling Time";
                Target."Vendor Authorization No." := Source."Vendor Authorization No.";
                Target."Return Shipment No." := Source."Return Shipment No.";
                Target."Return Shipment No. Series" := Source."Return Shipment No. Series";
                Target.Ship := Source.Ship;
                Target."Last Return Shipment No." := Source."Last Return Shipment No.";
                Target."Price Calculation Method" := Source."Price Calculation Method";
                Target.Id := Source.Id;
                Target."Assigned User ID" := Source."Assigned User ID";
                Target."Pending Approvals" := Source."Pending Approvals";
                Target."Order Process Status" := TargetOrderProcessStatus;
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

    // History Purchase Line - 204 common fields (2 Removed fields excluded, "Order Process Status"
    // cross-enum-converted and part of the primary key - see codeunit-level Batch 4 shadow-field comment).
    // Same history-scale rationale as MigrateHistoryPurchaseHeader above - periodic Commit() every 100
    // rows added. Upsert-by-primary-key ("Document Type", "Document No.", "Line No.",
    // "Order Process Status") - safe to re-run.
    local procedure MigrateHistoryPurchaseLine()
    var
        Source: Record "DX History Purchase Line";
        Target: Record "DXR_History Purchase Line";
        TargetOrderProcessStatus: Enum "DXR_PO Process Status";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetOrderProcessStatus := ConvertPOProcessStatus(Source."Order Process Status".AsInteger());
                TargetExists := Target.Get(Source."Document Type", Source."Document No.", Source."Line No.", TargetOrderProcessStatus);
                if not TargetExists then
                    Target.Init();
                Target."Document Type" := Source."Document Type";
                Target."Buy-from Vendor No." := Source."Buy-from Vendor No.";
                Target."Document No." := Source."Document No.";
                Target."Line No." := Source."Line No.";
                Target.Type := Source.Type;
                Target."No." := Source."No.";
                Target."Location Code" := Source."Location Code";
                Target."Posting Group" := Source."Posting Group";
                Target."Expected Receipt Date" := Source."Expected Receipt Date";
                Target.Description := Source.Description;
                Target."Description 2" := Source."Description 2";
                Target."Unit of Measure" := Source."Unit of Measure";
                Target.Quantity := Source.Quantity;
                Target."Outstanding Quantity" := Source."Outstanding Quantity";
                Target."Qty. to Invoice" := Source."Qty. to Invoice";
                Target."Qty. to Receive" := Source."Qty. to Receive";
                Target."Direct Unit Cost" := Source."Direct Unit Cost";
                Target."Unit Cost (LCY)" := Source."Unit Cost (LCY)";
                Target."VAT %" := Source."VAT %";
                Target."Line Discount %" := Source."Line Discount %";
                Target."Line Discount Amount" := Source."Line Discount Amount";
                Target.Amount := Source.Amount;
                Target."Amount Including VAT" := Source."Amount Including VAT";
                Target."Unit Price (LCY)" := Source."Unit Price (LCY)";
                Target."Allow Invoice Disc." := Source."Allow Invoice Disc.";
                Target."Gross Weight" := Source."Gross Weight";
                Target."Net Weight" := Source."Net Weight";
                Target."Units per Parcel" := Source."Units per Parcel";
                Target."Unit Volume" := Source."Unit Volume";
                Target."Appl.-to Item Entry" := Source."Appl.-to Item Entry";
                Target."Shortcut Dimension 1 Code" := Source."Shortcut Dimension 1 Code";
                Target."Shortcut Dimension 2 Code" := Source."Shortcut Dimension 2 Code";
                Target."Job No." := Source."Job No.";
                Target."Indirect Cost %" := Source."Indirect Cost %";
                Target."Recalculate Invoice Disc." := Source."Recalculate Invoice Disc.";
                Target."Outstanding Amount" := Source."Outstanding Amount";
                Target."Qty. Rcd. Not Invoiced" := Source."Qty. Rcd. Not Invoiced";
                Target."Amt. Rcd. Not Invoiced" := Source."Amt. Rcd. Not Invoiced";
                Target."Quantity Received" := Source."Quantity Received";
                Target."Quantity Invoiced" := Source."Quantity Invoiced";
                Target."Receipt No." := Source."Receipt No.";
                Target."Receipt Line No." := Source."Receipt Line No.";
                Target."Order No." := Source."Order No.";
                Target."Order Line No." := Source."Order Line No.";
                Target."Profit %" := Source."Profit %";
                Target."Pay-to Vendor No." := Source."Pay-to Vendor No.";
                Target."Inv. Discount Amount" := Source."Inv. Discount Amount";
                Target."Vendor Item No." := Source."Vendor Item No.";
                Target."Sales Order No." := Source."Sales Order No.";
                Target."Sales Order Line No." := Source."Sales Order Line No.";
                Target."Drop Shipment" := Source."Drop Shipment";
                Target."Gen. Bus. Posting Group" := Source."Gen. Bus. Posting Group";
                Target."Gen. Prod. Posting Group" := Source."Gen. Prod. Posting Group";
                Target."VAT Calculation Type" := Source."VAT Calculation Type";
                Target."Transaction Type" := Source."Transaction Type";
                Target."Transport Method" := Source."Transport Method";
                Target."Attached to Line No." := Source."Attached to Line No.";
                Target."Entry Point" := Source."Entry Point";
                Target."Area" := Source."Area";
                Target."Transaction Specification" := Source."Transaction Specification";
                Target."Tax Area Code" := Source."Tax Area Code";
                Target."Tax Liable" := Source."Tax Liable";
                Target."Tax Group Code" := Source."Tax Group Code";
                Target."Use Tax" := Source."Use Tax";
                Target."VAT Bus. Posting Group" := Source."VAT Bus. Posting Group";
                Target."VAT Prod. Posting Group" := Source."VAT Prod. Posting Group";
                Target."Currency Code" := Source."Currency Code";
                Target."Outstanding Amount (LCY)" := Source."Outstanding Amount (LCY)";
                Target."Amt. Rcd. Not Invoiced (LCY)" := Source."Amt. Rcd. Not Invoiced (LCY)";
                Target."Reserved Quantity" := Source."Reserved Quantity";
                Target."Blanket Order No." := Source."Blanket Order No.";
                Target."Blanket Order Line No." := Source."Blanket Order Line No.";
                Target."VAT Base Amount" := Source."VAT Base Amount";
                Target."Unit Cost" := Source."Unit Cost";
                Target."System-Created Entry" := Source."System-Created Entry";
                Target."Line Amount" := Source."Line Amount";
                Target."VAT Difference" := Source."VAT Difference";
                Target."Inv. Disc. Amount to Invoice" := Source."Inv. Disc. Amount to Invoice";
                Target."VAT Identifier" := Source."VAT Identifier";
                Target."IC Partner Ref. Type" := Source."IC Partner Ref. Type";
                Target."IC Partner Reference" := Source."IC Partner Reference";
                Target."Prepayment %" := Source."Prepayment %";
                Target."Prepmt. Line Amount" := Source."Prepmt. Line Amount";
                Target."Prepmt. Amt. Inv." := Source."Prepmt. Amt. Inv.";
                Target."Prepmt. Amt. Incl. VAT" := Source."Prepmt. Amt. Incl. VAT";
                Target."Prepayment Amount" := Source."Prepayment Amount";
                Target."Prepmt. VAT Base Amt." := Source."Prepmt. VAT Base Amt.";
                Target."Prepayment VAT %" := Source."Prepayment VAT %";
                Target."Prepmt. VAT Calc. Type" := Source."Prepmt. VAT Calc. Type";
                Target."Prepayment VAT Identifier" := Source."Prepayment VAT Identifier";
                Target."Prepayment Tax Area Code" := Source."Prepayment Tax Area Code";
                Target."Prepayment Tax Liable" := Source."Prepayment Tax Liable";
                Target."Prepayment Tax Group Code" := Source."Prepayment Tax Group Code";
                Target."Prepmt Amt to Deduct" := Source."Prepmt Amt to Deduct";
                Target."Prepmt Amt Deducted" := Source."Prepmt Amt Deducted";
                Target."Prepayment Line" := Source."Prepayment Line";
                Target."Prepmt. Amount Inv. Incl. VAT" := Source."Prepmt. Amount Inv. Incl. VAT";
                Target."Prepmt. Amount Inv. (LCY)" := Source."Prepmt. Amount Inv. (LCY)";
                Target."IC Partner Code" := Source."IC Partner Code";
                Target."Prepmt. VAT Amount Inv. (LCY)" := Source."Prepmt. VAT Amount Inv. (LCY)";
                Target."Prepayment VAT Difference" := Source."Prepayment VAT Difference";
                Target."Prepmt VAT Diff. to Deduct" := Source."Prepmt VAT Diff. to Deduct";
                Target."Prepmt VAT Diff. Deducted" := Source."Prepmt VAT Diff. Deducted";
                Target."IC Item Reference No." := Source."IC Item Reference No.";
                Target."Outstanding Amt. Ex. VAT (LCY)" := Source."Outstanding Amt. Ex. VAT (LCY)";
                Target."A. Rcd. Not Inv. Ex. VAT (LCY)" := Source."A. Rcd. Not Inv. Ex. VAT (LCY)";
                Target."Pmt. Discount Amount" := Source."Pmt. Discount Amount";
                Target."Dimension Set ID" := Source."Dimension Set ID";
                Target."Job Task No." := Source."Job Task No.";
                Target."Job Line Type" := Source."Job Line Type";
                Target."Job Unit Price" := Source."Job Unit Price";
                Target."Job Total Price" := Source."Job Total Price";
                Target."Job Line Amount" := Source."Job Line Amount";
                Target."Job Line Discount Amount" := Source."Job Line Discount Amount";
                Target."Job Line Discount %" := Source."Job Line Discount %";
                Target."Job Unit Price (LCY)" := Source."Job Unit Price (LCY)";
                Target."Job Total Price (LCY)" := Source."Job Total Price (LCY)";
                Target."Job Line Amount (LCY)" := Source."Job Line Amount (LCY)";
                Target."Job Line Disc. Amount (LCY)" := Source."Job Line Disc. Amount (LCY)";
                Target."Job Currency Factor" := Source."Job Currency Factor";
                Target."Job Currency Code" := Source."Job Currency Code";
                Target."Job Planning Line No." := Source."Job Planning Line No.";
                Target."Job Remaining Qty." := Source."Job Remaining Qty.";
                Target."Job Remaining Qty. (Base)" := Source."Job Remaining Qty. (Base)";
                Target."Deferral Code" := Source."Deferral Code";
                Target."Returns Deferral Start Date" := Source."Returns Deferral Start Date";
                Target."Prod. Order No." := Source."Prod. Order No.";
                Target."Variant Code" := Source."Variant Code";
                Target."Bin Code" := Source."Bin Code";
                Target."Qty. per Unit of Measure" := Source."Qty. per Unit of Measure";
                Target."Unit of Measure Code" := Source."Unit of Measure Code";
                Target."Quantity (Base)" := Source."Quantity (Base)";
                Target."Outstanding Qty. (Base)" := Source."Outstanding Qty. (Base)";
                Target."Qty. to Invoice (Base)" := Source."Qty. to Invoice (Base)";
                Target."Qty. to Receive (Base)" := Source."Qty. to Receive (Base)";
                Target."Qty. Rcd. Not Invoiced (Base)" := Source."Qty. Rcd. Not Invoiced (Base)";
                Target."Qty. Received (Base)" := Source."Qty. Received (Base)";
                Target."Qty. Invoiced (Base)" := Source."Qty. Invoiced (Base)";
                Target."Reserved Qty. (Base)" := Source."Reserved Qty. (Base)";
                Target."FA Posting Date" := Source."FA Posting Date";
                Target."FA Posting Type" := Source."FA Posting Type";
                Target."Depreciation Book Code" := Source."Depreciation Book Code";
                Target."Salvage Value" := Source."Salvage Value";
                Target."Depr. until FA Posting Date" := Source."Depr. until FA Posting Date";
                Target."Depr. Acquisition Cost" := Source."Depr. Acquisition Cost";
                Target."Maintenance Code" := Source."Maintenance Code";
                Target."Insurance No." := Source."Insurance No.";
                Target."Budgeted FA No." := Source."Budgeted FA No.";
                Target."Duplicate in Depreciation Book" := Source."Duplicate in Depreciation Book";
                Target."Use Duplication List" := Source."Use Duplication List";
                Target."Responsibility Center" := Source."Responsibility Center";
                Target."Unit of Measure (Cross Ref.)" := Source."Unit of Measure (Cross Ref.)";
                Target."Cross-Reference Type" := Source."Cross-Reference Type";
                Target."Cross-Reference Type No." := Source."Cross-Reference Type No.";
                Target."Item Category Code" := Source."Item Category Code";
                Target.Nonstock := Source.Nonstock;
                Target."Purchasing Code" := Source."Purchasing Code";
                Target."Special Order" := Source."Special Order";
                Target."Special Order Sales No." := Source."Special Order Sales No.";
                Target."Special Order Sales Line No." := Source."Special Order Sales Line No.";
                Target."Item Reference No." := Source."Item Reference No.";
                Target."Item Reference Unit of Measure" := Source."Item Reference Unit of Measure";
                Target."Item Reference Type" := Source."Item Reference Type";
                Target."Item Reference Type No." := Source."Item Reference Type No.";
                Target."Whse. Outstanding Qty. (Base)" := Source."Whse. Outstanding Qty. (Base)";
                Target."Completely Received" := Source."Completely Received";
                Target."Requested Receipt Date" := Source."Requested Receipt Date";
                Target."Promised Receipt Date" := Source."Promised Receipt Date";
                Target."Lead Time Calculation" := Source."Lead Time Calculation";
                Target."Inbound Whse. Handling Time" := Source."Inbound Whse. Handling Time";
                Target."Planned Receipt Date" := Source."Planned Receipt Date";
                Target."Order Date" := Source."Order Date";
                Target."Allow Item Charge Assignment" := Source."Allow Item Charge Assignment";
                Target."Qty. to Assign" := Source."Qty. to Assign";
                Target."Qty. Assigned" := Source."Qty. Assigned";
                Target."Return Qty. to Ship" := Source."Return Qty. to Ship";
                Target."Return Qty. to Ship (Base)" := Source."Return Qty. to Ship (Base)";
                Target."Return Qty. Shipped Not Invd." := Source."Return Qty. Shipped Not Invd.";
                Target."Ret. Qty. Shpd Not Invd.(Base)" := Source."Ret. Qty. Shpd Not Invd.(Base)";
                Target."Return Shpd. Not Invd." := Source."Return Shpd. Not Invd.";
                Target."Return Shpd. Not Invd. (LCY)" := Source."Return Shpd. Not Invd. (LCY)";
                Target."Return Qty. Shipped" := Source."Return Qty. Shipped";
                Target."Return Qty. Shipped (Base)" := Source."Return Qty. Shipped (Base)";
                Target."Return Shipment No." := Source."Return Shipment No.";
                Target."Return Shipment Line No." := Source."Return Shipment Line No.";
                Target."Return Reason Code" := Source."Return Reason Code";
                Target.Subtype := Source.Subtype;
                Target."Copied From Posted Doc." := Source."Copied From Posted Doc.";
                Target."Price Calculation Method" := Source."Price Calculation Method";
                Target."Attached Doc Count" := Source."Attached Doc Count";
                Target."Over-Receipt Quantity" := Source."Over-Receipt Quantity";
                Target."Over-Receipt Code" := Source."Over-Receipt Code";
                Target."Over-Receipt Approval Status" := Source."Over-Receipt Approval Status";
                Target."Routing No." := Source."Routing No.";
                Target."Operation No." := Source."Operation No.";
                Target."Work Center No." := Source."Work Center No.";
                Target.Finished := Source.Finished;
                Target."Prod. Order Line No." := Source."Prod. Order Line No.";
                Target."Overhead Rate" := Source."Overhead Rate";
                Target."MPS Order" := Source."MPS Order";
                Target."Planning Flexibility" := Source."Planning Flexibility";
                Target."Safety Lead Time" := Source."Safety Lead Time";
                Target."Routing Reference No." := Source."Routing Reference No.";
                Target."Order Process Status" := TargetOrderProcessStatus;
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

    // NCF Process Registration - all 6 fields common (field 3 "Tipo Comprobante" is the cross-enum field,
    // NOT part of the primary key - see codeunit-level Batch 4 shadow-field comment). Small fiscal-
    // document-tracking table - no periodic Commit() needed. Upsert-by-primary-key (NCF, "Document No.")
    // - safe to re-run.
    local procedure MigrateNCFProcessRegistration()
    var
        Source: Record "DX NCF Process Registration";
        Target: Record "DXR_NCF Process Registration";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source.NCF, Source."Document No.");
                if not TargetExists then
                    Target.Init();
                Target.NCF := Source.NCF;
                Target."Fecha Comprobante" := Source."Fecha Comprobante";
                Target."Tipo Comprobante" := ConvertFiscalDocType(Source."Tipo Comprobante".AsInteger());
                Target."Document No." := Source."Document No.";
                Target."Expiration Date" := Source."Expiration Date";
                Target."No. Series" := Source."No. Series";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Purchase Type Relation V27 - both fields common, no cross-enum (Tipo is a plain Option with
    // identical OptionMembers on both sides). See codeunit-level Batch 4 comment for the independently
    // re-verified shared-destination-with-DRLOC-P2 investigation (confirmed correct, not a data error).
    // Tiny per-posting-group setup table - no periodic Commit() needed. Upsert-by-primary-key
    // ("Grupo Contable Prod.") - safe to re-run.
    local procedure MigratePurchaseTypeRelationV27()
    var
        Source: Record "DX Purchase Type Relation";
        Target: Record "DXR_Purchase Type Relation";
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Grupo Contable Prod.");
                if not TargetExists then
                    Target.Init();
                Target."Grupo Contable Prod." := Source."Grupo Contable Prod.";
                Target.Tipo := Source.Tipo;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    // Report Logs - 8 common fields (field 54106 "Modified By User." is a FlowField on both sides,
    // excluded - see codeunit-level Batch 4 shadow-field comment). Transaction-history-scale table -
    // periodic Commit() every 100 rows added. Upsert-by-primary-key ("Entry No.", AutoIncrement) - safe
    // to re-run.
    local procedure MigrateReportLogs()
    var
        Source: Record "Dx Report Logs";
        Target: Record "DXR_Report Logs";
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Entry No.");
                if not TargetExists then
                    Target.Init();
                Target."Document No." := Source."Document No.";
                Target."Document Type." := Source."Document Type.";
                Target."NCF." := Source."NCF.";
                Target."Doc Posting Date." := Source."Doc Posting Date.";
                Target."Description." := Source."Description.";
                Target."Modified Date." := Source."Modified Date.";
                Target."Entry No." := Source."Entry No.";
                Target.NCF_DXR := Source.DXNCF;
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

    // Report Sales 607 Buffer - 43 common fields (field 13 Mensajes and fields 17-33 are FlowFields on
    // both sides, field 16 "Date Filter" is FlowFilter on both sides - all excluded, see codeunit-level
    // Batch 4 shadow-field comment). History-scale table (DGII 607 sales tax reporting data) - periodic
    // Commit() every 100 rows added. Upsert-by-primary-key ("Tipo Documento", "No. Documento",
    // "No. Linea") - safe to re-run.
    local procedure MigrateReportSales607Buffer()
    var
        Source: Record "DX Report Sales 607 Buffer";
        Target: Record "DXR_Report Sales 607 Buffer";
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
                Target."Additional Currency Code" := Source."Additional Currency Code";
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

    // Sending Pay Services Abroad 609 - all 15 fields common, no cross-enum (field 2 is a plain Option
    // with identical OptionMembers on both sides). DGII 609-report tracking table - periodic Commit()
    // every 100 rows added. Upsert-by-primary-key ("Numero de Documento", "No Linea") - safe to re-run.
    local procedure MigrateSendingPayServicesAbroad609()
    var
        Source: Record DXSendingPayServicesAbroad609;
        Target: Record DXR_SendPayServAbroad609;
        TargetExists: Boolean;
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Numero de Documento", Source."No Linea");
                if not TargetExists then
                    Target.Init();
                Target."Nombre / Razón Social" := Source."Nombre / Razón Social";
                Target."Tax Identificaction Type_DXR" := Source."DXTax Identificaction Type";
                Target."ID Tributaria" := Source."ID Tributaria";
                Target."Pais de Destino" := Source."Pais de Destino";
                Target."Tipo de Servicio Adquirido" := Source."Tipo de Servicio Adquirido";
                Target."Detalle del Servicio Adquirido" := Source."Detalle del Servicio Adquirido";
                Target."Parte Relacionada" := Source."Parte Relacionada";
                Target."Numero de Documento" := Source."Numero de Documento";
                Target."Fecha de Documento" := Source."Fecha de Documento";
                Target."Monto Facturado" := Source."Monto Facturado";
                Target."Fecha de Retención ISR" := Source."Fecha de Retención ISR";
                Target."Renta Presunta" := Source."Renta Presunta";
                Target."ISR Retenido" := Source."ISR Retenido";
                Target."No Linea" := Source."No Linea";
                Target.NCF := Source.NCF;
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

    // Tipo Servicio Adquirido - both fields common. Tiny reference/lookup table - no periodic Commit()
    // needed. Upsert-by-primary-key ("Code") - safe to re-run.
    local procedure MigrateTipoServicioAdquirido()
    var
        Source: Record DxTipoServicioAdquirido;
        Target: Record DXR_R_TipoServicioAdquirido;
        TargetExists: Boolean;
    begin
        if Source.FindSet(false) then
            repeat
                TargetExists := Target.Get(Source."Code");
                if not TargetExists then
                    Target.Init();
                Target."Code" := Source."Code";
                Target.Description := Source.Description;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;
}
