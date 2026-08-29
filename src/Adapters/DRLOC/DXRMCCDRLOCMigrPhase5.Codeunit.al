codeunit 60169 "DXR MCC DRLOC Migr Phase5"
{
    // Native local migration - ported (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization's own "DXR_Migr. Phase 5 Ledger" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Migr_Phase_5_Ledger.Codeunit.al, codeunit 52216), start of the
    // DRLOC Phase 5 (Ledger) native-porting campaign. Real OnRun() calls 19 steps total; 9 of them
    // (Bank Account Ledger Entry, Check Ledger Entry, G/L Entry, G/L Register, Gen. Journal Line,
    // Item Ledger Entry, Price List Line, Reversal Entry, Vendor Ledger Entry Bulk+FlowFields) were
    // already ported earlier this session into codeunit 60165 (registry seq40-44, dispatcher already
    // repointed there) - NOT re-ported here. This codeunit (60169) is being built across 3 planned
    // batches to cover the remaining 10 real steps:
    //   - Batch 1 (registry seq45, DONE): RepairVendorWithholdingMigration (unconditional, no own
    //     registry row - see note below) + MigrateFields_DetailedCustLedgEntry.
    //   - Batch 2 (registry seq49, IN PROGRESS - real RunRecentV27DataUpgrades(), DXR_LocUpgradeProcess
    //     .Codeunit.al lines 264-317, a bundle of 11 independently Upgrade-Tag-gated sub-fixes/backfills
    //     - being landed across 3 dispatched sub-batches 2a/2b/2c, in the same relative order the real
    //     orchestrator calls them. Registry seq49's Dispatcher Codeunit ID stays at 60069 until the LAST
    //     sub-batch (2c) lands all 11 and repoints it - same "codeunit built across N batches" pattern
    //     60165 already used):
    //       - Sub-batch 2a (DONE): first 4 of 11 real sub-fixes - updateWithholdingEntries(),
    //         Fix606CategoriaNCFAndITBISAdelantar(), Fix606ISRWithholdingTypeBlank(),
    //         FixVLEWithholdingApplyType() (the last one called TWICE by real source, under two
    //         separate real tags - see its own section below for why).
    //       - Sub-batch 2b (DONE): next 4 of 11 real sub-fixes -
    //         BackfillWithholdingPaymentAndCodes(), Fix606WithholdingByVendor(),
    //         Fix606WithholdingByVendorV2(), Fix606WithholdingByVendorV3() - see their own section
    //         below for the V1/V2/V3 progression story.
    //       - Sub-batch 2c (THIS batch): Sync606ChargeHistoryNCF() + its self-contained helper chain
    //         ONLY (see that procedure's own section below) - narrower than originally planned.
    //         Investigation found the remaining 2 real sub-fixes (Repair606CardChargeVLEs(),
    //         Repair606BankChargeVLEs()) both call into a THIRD codeunit
    //         (Codeunit "DXR_Localization Fiscal Mgt.", Register606HistoryTable()) that is ~1500+ lines,
    //         carries live NCF fiscal-sequence-assignment logic, AND an unconditional interactive
    //         Dialog.OPEN() call - DGII/NCF-fiscal-numbering-adjacent territory, same risk class as the
    //         campaign's other explicitly-excluded DGII-RNC-Database-adjacent work, deliberately deferred
    //         to a dedicated follow-up decision (NOT part of this batch, NOT ported here). Because of
    //         this, registry seq49's Dispatcher Codeunit ID stays at 60069 for now, NOT repointed to this
    //         codeunit (60169) yet - repointing (and porting the 2 remaining procedures, pending a
    //         separate decision on Register606HistoryTable()) is left for a future, dedicated batch.
    //   - Batch 3 (THIS batch, registry seq46/47/48/65-72, LAST normal batch for this codeunit): the
    //     remaining 11 whole-table-clone steps - MigrateTable_ArchWithholdingGovHdr() (54108->52120,
    //     seq46), MigrateTable_ArchivedBankChargesHdr() (54102->52107, seq47),
    //     MigrateTable_WithholdingGovernHeader() (54147->52207, seq48),
    //     MigrateTable_ArchCCChargesHeader() (54100->52259, seq65),
    //     MigrateTable_ArchCCChargesLines() (54101->52260, seq66),
    //     MigrateTable_ArchWithholdGovLines() (54107->52117, seq67),
    //     MigrateTable_BankChargesHeader() (54109->52124, seq68),
    //     MigrateTable_CredCardChargesHeader() (54113->52140, seq69),
    //     MigrateTable_CredCardChargesLines() (54114->52142, seq70),
    //     MigrateTable_MessageLogTable() (54127->52173, seq71),
    //     MigrateTable_WithholdingGovernLines() (54148->52209, seq72) - each already a typed Record
    //     TransferFields(..., true) whole-table clone in real source (same shape as Phase 2 Batch 3/
    //     Phase 3 Batch 2/Phase 4 Batch 2's own precedent), expanded below to explicit per-field typed
    //     assignment. Upgrade Tags reused verbatim from DXR_UpgradeTagMgt.Codeunit.al's own
    //     UpgradeTagInternalClosureTable<Concept>() literals (the same tags that gate the sibling
    //     "DXR_Internal Closure Migration" codeunit's own RunMigrateTable_<Concept>() wrapper for each
    //     exact concept) - same reuse-the-granular-tag rationale already established by every prior
    //     whole-table-clone batch in this campaign. Registry seq49 (V27 data corrections) is
    //     deliberately NOT touched by this batch - see sub-batch 2c's own note above; it stays at
    //     Dispatcher Codeunit ID 60069 pending a separate, already-flagged decision.
    //
    // ===== Batch 3 shadow-field findings (independently re-derived against real, current source for
    // all 11 old/new table pairs - full coverage, not sampled) =====
    //   - seq46 (ArchWithholdingGovHdr): all 7 fields identical name/ID/type EXCEPT "No. Series" -
    //     Code[20] on the old table (DXArch Withholding Gov. Hdr) narrows to Code[10] on the new table
    //     (DXR_Arch Withholding Gov. Hdr) - a narrowing assignment (AL permits Code-to-Code assignment
    //     across different lengths; only a practical truncation risk if a legacy value happens to
    //     exceed 10 characters, same as real source's own TransferFields(..., true) would silently do).
    //   - seq47 (ArchivedBankChargesHdr): all fields identical name/ID/type; field 12 "Total Documento"
    //     is a FlowField on both sides (excluded, TransferFields never copies FlowFields either); field
    //     14 does not exist on either table (gap, not a rename).
    //   - seq48 (WithholdingGovernHeader): all 7 fields identical name/ID/type, no differences.
    //   - seq65 (ArchCCChargesHeader): all fields identical name/ID/type; field 33 "Prepayment" is
    //     ObsoleteState = Removed on BOTH tables (not merely Pending) - genuinely inaccessible in AL on
    //     either side, correctly excluded (not a rename, not a copyable field).
    //   - seq66 (ArchCCChargesLines): all fields identical name/ID/type, no differences.
    //   - seq67 (ArchWithholdGovLines): all fields identical name/ID/type, no differences - including
    //     the 2 high-numbered extension fields 36002769/36002770 (Additional Currency Code/Factor),
    //     present identically on both sides.
    //   - seq68 (BankChargesHeader): all fields identical name/ID/type; field 12 "Total Documento" is a
    //     FlowField on both sides (excluded); field 17 does not exist on either table (gap).
    //   - seq69 (CredCardChargesHeader): all fields identical name/ID/type; fields 20/21 do not exist on
    //     either table (gap); field 33 "Prepayment" is ObsoleteState = Removed on BOTH tables (same
    //     pattern as seq65, correctly excluded).
    //   - seq70 (CredCardChargesLines): all fields identical name/ID/type, including the "DX"-prefixed
    //     field names themselves ("DXDate Entry", "DXLote No.", "DXDaily NCF", "DXApply to Invoice No.",
    //     "DXAmount to-Apply", "DXApply to-Id") - preserved verbatim as a same-ID, same-name pair on
    //     both old and new tables (NOT a rename, the "DX" prefix is simply part of the field's real
    //     caption/name on both sides); fields 5/6 do not exist on either table (gap).
    //   - seq71 (MessageLogTable): all 6 fields identical name/ID/type, no differences.
    //   - seq72 (WithholdingGovernLines): all 12 fields identical name/ID/type, no differences.
    // Net finding for this batch: unlike several earlier whole-table-clone batches in this campaign
    // (ITBIS Purchase 606, ITBIS/Consumer02 Sales 607), NONE of these 11 tables carry a same-ID field
    // rename between old and new - the only non-trivial case is seq46's Code[20]->Code[10] "No. Series"
    // narrowing, flagged above for reviewer awareness.
    //
    // ===== Batch 3 Commit() placement reasoning =====
    // All 11 real MigrateTable_*() procedures have NO Commit() at all in real source. Every one of
    // these 11 old tables is a frozen, ObsoleteState = Pending legacy snapshot table being decommissioned
    // (not a live/growing transaction table) - matching this campaign's own established Phase 4 Batch 2
    // precedent for frozen legacy source tables (e.g. MigrateArchivedSales607Table() above) - NO periodic
    // Commit() added to any of the 11 procedures below. None of these 11 source tables is
    // transaction-volume-scale or unbounded the way Vendor Ledger Entry / Detailed Cust. Ledg. Entry /
    // DXR_Archived Purchase - (606) are elsewhere in this codeunit - they are one-time archived-document
    // history snapshots (bank/card charge headers+lines, government withholding headers+lines, a message
    // log), each bounded by how many documents were ever archived under the legacy module before it was
    // decommissioned.
    // OnRun() replicates Phase 5's real OnRun SHAPE (same pattern as 60165/60167/60168's own header
    // comments describe): every ported procedure is called unconditionally, each individually gated
    // by its own real UpgradeTag check inside. Batch 1's 2 procedures + sub-batch 2a's 4 procedures are
    // wired into OnRun() so far; sub-batches 2b/2c and Batch 3 will add their own calls later.
    //
    // ===== Sub-batch 2a stakes note: this is data-CORRECTION logic, not a field-copy =====
    // All 4 procedures below deal with Dominican Republic tax-withholding compliance data (ITBIS/ISR
    // withholding amounts and codes, NCF fiscal categories feeding "606" DGII reporting) - the EXACT
    // condition under which a value gets changed is the whole point of each procedure, same discipline
    // Batch 1's RepairVendorWithholdingMigration required. Every field reference and conditional branch
    // below was independently re-derived against the real, current source (DXR_LocUpgradeProcess
    // .Codeunit.al) and cross-checked against the current table/field definitions actually shipping in
    // DR-Localization - see each procedure's own comment for what was verified. Ported var names were
    // normalized to this codeunit's own established naming (e.g. real source's local "VLE" var renamed
    // to "VendorLedgerEntry", "VendorWithholdingEntries" renamed to singular "WithholdingEntry" style
    // matching Batch 1's own vars) - cosmetic only, zero logic/condition change.
    //
    // RepairVendorWithholdingMigration note: real source calls this directly and unconditionally
    // (TryRepairVendorWithholdingMigration() -> TryRepairVendorWithholdingMigrationOnce() ->
    // Codeunit "DXR_Vend. Withhold Migr Repair".Repair(), confirmed lines 73-74 of the real Phase 5
    // OnRun, right after the Vendor Ledger Entry field-restore steps already ported into 60165 - see
    // that codeunit's own "seq44 naming note"). There is no separate registry row for it; it rides
    // along with registry seq45 (this codeunit), matching this campaign's established pattern for
    // unconditional-but-unregistered sub-steps (e.g. Phase 2's ApplicationAreaSetup handling before it
    // got its own row). Repair() is NOT the same as the separately-gated
    // RunVendorWithholdingMigrationRepair() wrapper in DXR_LocUpgradeProcess.Codeunit.al (its own
    // UpgradeTagVendorWithholdingMigrationRepair tag, DXR-T20260720-RepairVendorWithholdingMigration)
    // - that different call path is NOT used by Phase 5's real OnRun and is out of scope here.
    //
    // ===== RepairVendorWithholdingMigration - what it actually does (new territory for this
    // campaign; every prior batch so far was either a simple field-restore or a whole-table clone) =====
    // Ported faithfully from Codeunit "DXR_Vend. Withhold Migr Repair".Repair() (140-line source,
    // read in full) - a REPAIR procedure fixing data left wrong by an earlier migration step, not a
    // first-time field copy. Its own real body (and this port) runs, in order:
    //   1) MigrateVendorWithholdingLedgerEntries() - whole-table clone, legacy
    //      DXVendorWithholdingLedgerEntry (ObsoleteState = Pending, frozen legacy snapshot) into
    //      DXR_VendWithholdLedgerEntry (Access = Internal), TransferFields(..., true) expanded to
    //      explicit typed field-by-field assignment (43 stored fields; field 32 "Reporta 609_DXR" /
    //      old "DXReporta 609" is a FlowField on both sides, excluded - TransferFields never copies
    //      FlowFields either). Confirmed same-ID field difference: 26 "DXTax Identificaction Type"
    //      renamed to "Tax Identificaction Type_DXR" (migrated). All other fields pair identically by
    //      name/ID/type, confirmed against the current DXR_VendorWithholdingLedgerEntry.Table.al /
    //      legacy DXVendorWithholdingLedgerEntry.Table.al.
    //   2) MigrateVendorLedgerEntryFields() - a dirty-check field restore over the LIVE, current
    //      "Vendor Ledger Entry" table (not the legacy table above) - repairs the same 5 field pairs
    //      ("Withholding Payment_DXR"/"Dx Withholding Payment", "Cod. Retencion ITBIS_DXR"/
    //      "DXCod. Retencion ITBIS", "Cod. Retencion ISR_DXR"/"DXCod. Retencion ISR",
    //      "Withholding Apply Type_DXR"/"DX Withholding Apply Type", "NCF_DXR Usado_DXR"/
    //      "DXNCF Usado") already touched by seq44's own Vendor Ledger Entry Bulk restore in codeunit
    //      60165 - but with asymmetric/one-directional repair logic instead of a straight copy (for
    //      example "Cod. Retencion ITBIS_DXR" is only overwritten when it is BLANK and the legacy
    //      source is not, never overwriting an already-populated value; "Withholding Apply Type_DXR"
    //      is only forced to "On Payment" when the legacy source says "On Payment", never reset back
    //      to "On Invoice") - this is what makes it a genuine repair rather than a re-run of seq44's
    //      own bulk copy. All 5 field pairs independently re-verified live/correct-type against the
    //      current DXR_VendorLedgerEntryExt.TableExt.AL (all 5 legacy-side fields confirmed
    //      ObsoleteState = Pending, same fields seq44 already reads without needing a pragma).
    //   3) RepairVendorLedgerEntryDocumentTypes() - for every row of the JUST-POPULATED
    //      DXR_VendWithholdLedgerEntry (from step 1), finds the matching "Vendor Ledger Entry" rows
    //      (by "NCF_DXR" when "NCF Afectado" is set, else by "Document No."; always filtered further
    //      by "Vendor No." and to Document Type Payment or the DR-Localization-added enum value
    //      "DX Withholding" on "Gen. Journal Document Type", confirmed via
    //      DXR_GenJournalDocumentType.EnumExt.al) and, for each match: reclassifies "Document Type"
    //      Payment into "DX Withholding", forces "Withholding Payment_DXR" := true, and back-fills
    //      whichever of "Cod. Retencion ITBIS_DXR" / "Cod. Retencion ISR_DXR" is still blank from the
    //      withholding-entry row's own "Tipo Retencion" (ITBIS/ISR) branch. This is the step that
    //      actually repairs ledger entries a prior migration mis-tagged as ordinary Payments instead
    //      of withholding transactions.
    // Repair() has its own internal completion guard, a local RepairUpgradeTag() literal
    // (defined inside "DXR_Vend. Withhold Migr Repair" itself, NOT one of DXR_UpgradeTagMgt.Codeunit.al's
    // tags, and NOT the same tag as the different DXR_LocUpgradeProcess wrapper's
    // UpgradeTagVendorWithholdingMigrationRepair noted above) - preserved verbatim as this port's own
    // gate, exactly where real source checks it (guard at entry, set after all 3 sub-steps complete),
    // per this task's instruction to preserve internal gating exactly as written. No additional
    // idempotency logic added or removed.
    //
    // Commit() placement: real Repair()/MigrateVendorWithholdingLedgerEntries()/
    // MigrateVendorLedgerEntryFields()/RepairVendorLedgerEntryDocumentTypes() have NO Commit() calls
    // anywhere. MigrateVendorWithholdingLedgerEntries() is a one-time backfill of a frozen legacy
    // snapshot (old table ObsoleteState = Pending) - no periodic Commit() added, matching this
    // campaign's established Phase 4 Batch 2 precedent for frozen legacy source tables.
    // MigrateVendorLedgerEntryFields() scans the full LIVE "Vendor Ledger Entry" table
    // (transaction-volume-scale, unbounded) with no Commit() at all in real source - an obviously
    // missing resilience gap per this campaign's own established judgment (same table/same "6 tables
    // explicitly called out" precedent already applied to seq44's Bulk/FlowFields scans in codeunit
    // 60165) - periodic Commit() every 100 rows added here. RepairVendorLedgerEntryDocumentTypes()'s
    // outer loop is bounded by the same frozen legacy snapshot as step 1 (so not itself unbounded),
    // but its own real body then re-scans a filtered subset of the same transaction-volume-scale
    // Vendor Ledger Entry table per outer row - periodic Commit() every 100 outer rows added here too,
    // by the same obviously-missing-on-a-live-ledger-entry-table reasoning, without altering any of
    // its own real matching/repair logic.
    //
    // ===== seq45: Detailed Cust. Ledg. Entry field restore =====
    // Ported from MigrateFields_DetailedCustLedgEntry() (~line 801 of the real Phase 5 source) - a
    // single dirty-checked field pair, "Status_DXR" (51811/36002753, Option, live) versus "Dx Status"
    // (54100/36002752, Option, ObsoleteState = Pending), both confirmed identical OptionMembers
    // (Paid, Not Paid, Partially Paid, Delayed, Applied, Unapplied) and order against the current
    // DXR_DtldCustLedgEntry.TableExt.al - direct assignment is safe (Option types, same members and
    // order, same rule already established earlier in this campaign). Upgrade Tag reused verbatim
    // from DXR_UpgradeTagMgt.Codeunit.al's own UpgradeTagInternalClosureFieldsDetailedCustLedgEntry()
    // (DX-INTERNAL-CLOSURE-FIELDS-DETAILEDCUSTLEDGENTRY-20260522), the tag that gates the sibling
    // "DXR_Internal Closure Migration" codeunit's own RunMigrateFields_DetailedCustLedgEntry()
    // wrapper for this exact concept - same reuse-the-granular-tag rationale already established by
    // every prior codeunit in this campaign.
    //
    // Commit() placement: Detailed Cust. Ledg. Entry is a transaction-volume-scale ledger-entry table
    // (real source has no Commit() at all in MigrateFields_DetailedCustLedgEntry(), same class of gap
    // as the ledger-entry tables above) - periodic Commit() every 100 rows added, matching this
    // campaign's precedent for other large ledger-entry tables (Cust./Vendor Ledger Entry, G/L Entry,
    // Item Ledger Entry, etc. in codeunit 60165).
    Permissions =
        tabledata "Detailed Cust. Ledg. Entry" = RM,
        tabledata "Vendor Ledger Entry" = RM,
        tabledata DXVendorWithholdingLedgerEntry = R,
        tabledata DXR_VendWithholdLedgerEntry = RIM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "DXR_Cust Withhold Entries" = R,
        tabledata "DXR_Archived Purchase - (606)" = RM,
        tabledata "Purch. Inv. Header" = R,
        tabledata "Purch. Cr. Memo Hdr." = R,
        tabledata NCFCategories_DXR = R,
        tabledata "DXR_Vendor Withholding Setup" = R,
        tabledata "DXR_Archived Bank Charges Hdr" = RIM,
        tabledata "DXR_Arch Bank Charges Lines" = R,
        tabledata "DXR_Arch. C. C. Charges Header" = RIM,
        tabledata "DXR_Arch. C. C. Charges Lines" = RIM,
        tabledata "DXR_NCF Setup" = R,
        tabledata "G/L Account" = R,
        // Batch 3 (whole-table clones) - old (legacy, frozen) tables read-only, new tables Insert+Modify.
        tabledata "DXArch Withholding Gov. Hdr" = R,
        tabledata "DXR_Arch Withholding Gov. Hdr" = RIM,
        tabledata "DXArchived Bank Charges Hdr" = R,
        tabledata "DXWithholding Govern. Header" = R,
        tabledata "DXR_Withholding Govern. Header" = RIM,
        tabledata "DXArch. C. C. Charges Header" = R,
        tabledata "DXArch. C. C. Charges Lines" = R,
        tabledata "DXArch. Withhold. Gov. Lines" = R,
        tabledata "DXR_Arch. Withhold. Gov. Lines" = RIM,
        tabledata "DXBank Charges Header" = R,
        tabledata "DXR_Bank Charges Header" = RIM,
        tabledata "DXCred. Card Charges Header" = R,
        tabledata "DXR_Cred. Card Charges Header" = RIM,
        tabledata "DXCred. Card Charges Lines" = R,
        tabledata "DXR_Cred. Card Charges Lines" = RIM,
        tabledata "DXMessage Log Table" = R,
        tabledata "DXR_Message Log Table" = RIM,
        tabledata "DXWithholding Govern. Lines" = R,
        tabledata "DXR_Withholding Govern. Lines" = RIM;

    trigger OnRun()
    var
        UpgradeTagMgt: Codeunit "Upgrade Tag";
        PhaseTags: Codeunit "DXR_Internal Migr. Phase Tags";
    begin
        // 2026-08-25 fix: added the outer completion gate real DR-Localization's own
        // "DXR_Migr. Phase 5 Ledger" OnRun() uses (Phase5CompletedTag(), reused verbatim) - same
        // root-cause/fix as codeunit 60165's OnRun() comment (full re-scan on every invocation,
        // forever, contributing to a real reported production hang). This tag correctly represents
        // "everything currently ported for Phase 5 is done" - it does not claim the deliberately
        // deferred Repair606CardChargeVLEs/Repair606BankChargeVLEs/Register606HistoryTable piece
        // (never ported here, tracked separately) is complete.
        if UpgradeTagMgt.HasUpgradeTag(PhaseTags.Phase5CompletedTag()) then
            exit;

        RepairVendorWithholdingMigration();
        BootstrapDetailedCustLedgEntryFields();
        BootstrapUpdateWithholdingEntries();
        BootstrapFix606CategoriaNCFAndITBISAdelantar();
        BootstrapFix606ISRWithholdingTypeBlank();
        BootstrapFixVLEWithholdingApplyType();
        BootstrapBackfillWithholdingPaymentAndCodes();
        BootstrapFix606WithholdingByVendor();
        BootstrapFix606WithholdingByVendorV2();
        BootstrapFix606WithholdingByVendorV3();
        BootstrapSync606ChargeHistoryNCF();
        BootstrapArchWithholdingGovHdrTable();
        BootstrapArchivedBankChargesHdrTable();
        BootstrapWithholdingGovernHeaderTable();
        BootstrapArchCCChargesHeaderTable();
        BootstrapArchCCChargesLinesTable();
        BootstrapArchWithholdGovLinesTable();
        BootstrapBankChargesHeaderTable();
        BootstrapCredCardChargesHeaderTable();
        BootstrapCredCardChargesLinesTable();
        BootstrapMessageLogTable();
        BootstrapWithholdingGovernLinesTable();

        UpgradeTagMgt.SetUpgradeTag(PhaseTags.Phase5CompletedTag());
    end;

    procedure RunMaster()
    begin
    end;

    procedure RunAccounting()
    begin
        RepairVendorWithholdingMigration();
        BootstrapDetailedCustLedgEntryFields();
        BootstrapUpdateWithholdingEntries();
        BootstrapFix606CategoriaNCFAndITBISAdelantar();
        BootstrapFix606ISRWithholdingTypeBlank();
        BootstrapFixVLEWithholdingApplyType();
        BootstrapBackfillWithholdingPaymentAndCodes();
        BootstrapFix606WithholdingByVendor();
        BootstrapFix606WithholdingByVendorV2();
        BootstrapFix606WithholdingByVendorV3();
        BootstrapSync606ChargeHistoryNCF();
        BootstrapArchivedBankChargesHdrTable();
        BootstrapWithholdingGovernHeaderTable();
        BootstrapBankChargesHeaderTable();
        BootstrapCredCardChargesHeaderTable();
        BootstrapCredCardChargesLinesTable();
        BootstrapWithholdingGovernLinesTable();
    end;

    procedure RunHistoric()
    begin
        BootstrapArchWithholdingGovHdrTable();
        BootstrapArchCCChargesHeaderTable();
        BootstrapArchCCChargesLinesTable();
        BootstrapArchWithholdGovLinesTable();
        BootstrapMessageLogTable();
    end;

    // ===== RepairVendorWithholdingMigration (unconditional, no registry row - see header note) =====
    local procedure RepairVendorWithholdingMigration()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // Own completion guard, ported verbatim from Repair()'s own real gate (see header note) - NOT
        // gated by the outer 60169 OnRun() itself, matching real source exactly.
        if UpgradeTag.HasUpgradeTag('DXR-VEND-WITHHOLD-PRESERVE-DXR-20260721-V2') then
            exit;

        MigrateVendorWithholdingLedgerEntries();
        MigrateVendorLedgerEntryFields();
        RepairVendorLedgerEntryDocumentTypes();
        UpgradeTag.SetUpgradeTag('DXR-VEND-WITHHOLD-PRESERVE-DXR-20260721-V2');
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see header Commit() placement note).
    local procedure MigrateVendorWithholdingLedgerEntries()
    var
        LegacyEntry: Record DXVendorWithholdingLedgerEntry;
        NewEntry: Record DXR_VendWithholdLedgerEntry;
    begin
        if LegacyEntry.IsEmpty() then
            exit;

        if LegacyEntry.FindSet() then
            repeat
                NewEntry.Init();
                NewEntry."Fecha Retencion" := LegacyEntry."Fecha Retencion";
                NewEntry."No. Documento" := LegacyEntry."No. Documento";
                NewEntry."Nombre Beneficiario" := LegacyEntry."Nombre Beneficiario";
                NewEntry."RNC/Cedula" := LegacyEntry."RNC/Cedula";
                NewEntry."Tipo Retencion" := LegacyEntry."Tipo Retencion";
                NewEntry."Importe Retenido" := LegacyEntry."Importe Retenido";
                NewEntry."No. Factura" := LegacyEntry."No. Factura";
                NewEntry."Monto Facturado" := LegacyEntry."Monto Facturado";
                NewEntry."No. Linea" := LegacyEntry."No. Linea";
                NewEntry."Fecha Factura" := LegacyEntry."Fecha Factura";
                NewEntry."Cod. Proveedor" := LegacyEntry."Cod. Proveedor";
                NewEntry."NCF Afectado" := LegacyEntry."NCF Afectado";
                NewEntry."Cod. Retencion ITBIS" := LegacyEntry."Cod. Retencion ITBIS";
                NewEntry."Cod. Retencion ISR" := LegacyEntry."Cod. Retencion ISR";
                NewEntry.Reverse := LegacyEntry.Reverse;
                NewEntry."Currency Code" := LegacyEntry."Currency Code";
                NewEntry."Amount Excl. VAT" := LegacyEntry."Amount Excl. VAT";
                NewEntry."Additional Currency Amount" := LegacyEntry."Additional Currency Amount";
                NewEntry."Currency Factor" := LegacyEntry."Currency Factor";
                NewEntry."Additl. Inv. Currency Amount" := LegacyEntry."Additl. Inv. Currency Amount";
                NewEntry."Additl. Curr. VAT Amount" := LegacyEntry."Additl. Curr. VAT Amount";
                NewEntry."Additl. ISR Currency Amount" := LegacyEntry."Additl. ISR Currency Amount";
                NewEntry."Additl. ITBIS Currency Amount" := LegacyEntry."Additl. ITBIS Currency Amount";
                NewEntry."Additl. Inv. Amount Incl. VAT" := LegacyEntry."Additl. Inv. Amount Incl. VAT";
                NewEntry."VAT Amount LCY" := LegacyEntry."VAT Amount LCY";
                NewEntry."Tax Identificaction Type_DXR" := LegacyEntry."DXTax Identificaction Type";
                NewEntry."Pais Destino" := LegacyEntry."Pais Destino";
                NewEntry."Tipo Servicio Adquirido" := LegacyEntry."Tipo Servicio Adquirido";
                NewEntry."Detalle Servicio Adquirido" := LegacyEntry."Detalle Servicio Adquirido";
                NewEntry."Parte Relacionada" := LegacyEntry."Parte Relacionada";
                NewEntry."Document Date" := LegacyEntry."Document Date";
                NewEntry."Has Associated Payment" := LegacyEntry."Has Associated Payment";
                NewEntry."Tax Base" := LegacyEntry."Tax Base";
                NewEntry."Exchange Rate" := LegacyEntry."Exchange Rate";
                NewEntry."Original Amount LCY" := LegacyEntry."Original Amount LCY";
                NewEntry."External Vendor Invoice No." := LegacyEntry."External Vendor Invoice No.";
                NewEntry."Payment Date" := LegacyEntry."Payment Date";
                NewEntry."Withhold Amount LCY" := LegacyEntry."Withhold Amount LCY";
                NewEntry."Inv. Vat Amount" := LegacyEntry."Inv. Vat Amount";
                NewEntry."Additl. Vat Amount" := LegacyEntry."Additl. Vat Amount";
                NewEntry."Inv. Amount LCY" := LegacyEntry."Inv. Amount LCY";
                NewEntry."Vendor Ledger Entry No." := LegacyEntry."Vendor Ledger Entry No.";
                NewEntry."Withholding Apply Type" := LegacyEntry."Withholding Apply Type";
                if not NewEntry.Insert(false) then
                    NewEntry.Modify(false);
            until LegacyEntry.Next() = 0;
    end;

    // Vendor Ledger Entry is a permanent, ever-growing posted-transaction history table
    // (transaction-volume-scale, unbounded) - periodic Commit() every 100 rows added (real source has
    // none at all here, see header Commit() placement note).
    local procedure MigrateVendorLedgerEntryFields()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntryToUpdate: Record "Vendor Ledger Entry";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - this is the only UNFILTERED Vendor Ledger Entry scan in this codeunit
        // (every other one is narrowed by Document Type/Vendor No./NCF first). FindSet(true) over the
        // whole table took a SQL UPDLOCK on every vendor ledger entry for the entire run (Learn,
        // "Record.FindSet") and, with no SetLoadFields, joined the companion table of every Vendor
        // Ledger Entry tableextension once per row. Partial unlocked scan, Get()/lock only on rows that
        // really change, and the Commit counter now advances per MODIFIED row instead of per scanned row.
        VendorLedgerEntry.SetLoadFields(
            "Entry No.",
            "Withholding Payment_DXR", "Dx Withholding Payment",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            "Withholding Apply Type_DXR", "DX Withholding Apply Type",
            "NCF_DXR Usado_DXR", "DXNCF Usado");
        if VendorLedgerEntry.FindSet(false) then
            repeat
                if (not VendorLedgerEntry."Withholding Payment_DXR" and VendorLedgerEntry."Dx Withholding Payment") or
                   ((VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ITBIS" <> '')) or
                   ((VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ISR" <> '')) or
                   ((VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice") and
                    (VendorLedgerEntry."DX Withholding Apply Type" = VendorLedgerEntry."DX Withholding Apply Type"::"On Payment")) or
                   (not VendorLedgerEntry."NCF_DXR Usado_DXR" and VendorLedgerEntry."DXNCF Usado")
                then
                    if VendorLedgerEntryToUpdate.Get(VendorLedgerEntry."Entry No.") then begin
                        if VendorLedgerEntryToUpdate."Dx Withholding Payment" then
                            VendorLedgerEntryToUpdate."Withholding Payment_DXR" := true;
                        if (VendorLedgerEntryToUpdate."Cod. Retencion ITBIS_DXR" = '') and (VendorLedgerEntryToUpdate."DXCod. Retencion ITBIS" <> '') then
                            VendorLedgerEntryToUpdate."Cod. Retencion ITBIS_DXR" := VendorLedgerEntryToUpdate."DXCod. Retencion ITBIS";
                        if (VendorLedgerEntryToUpdate."Cod. Retencion ISR_DXR" = '') and (VendorLedgerEntryToUpdate."DXCod. Retencion ISR" <> '') then
                            VendorLedgerEntryToUpdate."Cod. Retencion ISR_DXR" := VendorLedgerEntryToUpdate."DXCod. Retencion ISR";
                        if VendorLedgerEntryToUpdate."DX Withholding Apply Type" = VendorLedgerEntryToUpdate."DX Withholding Apply Type"::"On Payment" then
                            VendorLedgerEntryToUpdate."Withholding Apply Type_DXR" := VendorLedgerEntryToUpdate."Withholding Apply Type_DXR"::"On Payment";
                        if VendorLedgerEntryToUpdate."DXNCF Usado" then
                            VendorLedgerEntryToUpdate."NCF_DXR Usado_DXR" := true;
                        VendorLedgerEntryToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until VendorLedgerEntry.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // Outer loop is bounded by the frozen legacy DXR_VendWithholdLedgerEntry snapshot (step 1 above),
    // but its own real body re-scans a filtered subset of the transaction-volume-scale Vendor Ledger
    // Entry table per outer row - periodic Commit() every 100 outer rows added (real source has none
    // at all here, see header Commit() placement note); matching/repair logic itself unchanged.
    local procedure RepairVendorLedgerEntryDocumentTypes()
    var
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BatchCount: Integer;
    begin
        if WithholdingEntry.FindSet() then
            repeat
                VendorLedgerEntry.Reset();
                if WithholdingEntry."NCF Afectado" <> '' then
                    VendorLedgerEntry.SetRange("NCF_DXR", WithholdingEntry."NCF Afectado")
                else
                    VendorLedgerEntry.SetRange("Document No.", WithholdingEntry."No. Documento");
                VendorLedgerEntry.SetRange("Vendor No.", WithholdingEntry."Cod. Proveedor");
                VendorLedgerEntry.SetFilter("Document Type", '%1|%2', VendorLedgerEntry."Document Type"::Payment, VendorLedgerEntry."Document Type"::"DX Withholding");

                if VendorLedgerEntry.FindSet(true) then
                    repeat
                        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Payment then
                            VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::"DX Withholding";
                        VendorLedgerEntry."Withholding Payment_DXR" := true;
                        case WithholdingEntry."Tipo Retencion" of
                            WithholdingEntry."Tipo Retencion"::ITBIS:
                                if (VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (WithholdingEntry."Cod. Retencion ITBIS" <> '') then
                                    VendorLedgerEntry."Cod. Retencion ITBIS_DXR" := WithholdingEntry."Cod. Retencion ITBIS";
                            WithholdingEntry."Tipo Retencion"::ISR:
                                if (VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (WithholdingEntry."Cod. Retencion ISR" <> '') then
                                    VendorLedgerEntry."Cod. Retencion ISR_DXR" := WithholdingEntry."Cod. Retencion ISR";
                        end;
                        VendorLedgerEntry.Modify(false);
                    until VendorLedgerEntry.Next() = 0;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until WithholdingEntry.Next() = 0;
    end;

    // ===== seq45: Detailed Cust. Ledg. Entry field restore =====
    local procedure BootstrapDetailedCustLedgEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-DETAILEDCUSTLEDGENTRY-20260522') then begin
            MigrateDetailedCustLedgEntryFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-DETAILEDCUSTLEDGENTRY-20260522');
        end;
    end;

    // Detailed Cust. Ledg. Entry is a transaction-volume-scale ledger-entry table - periodic Commit()
    // every 100 rows added (real source has none, see header Commit() placement note).
    local procedure MigrateDetailedCustLedgEntryFields()
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedCustLedgEntryToUpdate: Record "Detailed Cust. Ledg. Entry";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole transaction-volume-
        // scale table for the entire run and, with no SetLoadFields, joined every tableextension
        // companion table per row. Partial unlocked scan + Get()/lock only on rows that really change +
        // Commit counter advancing per MODIFIED row.
        DetailedCustLedgEntry.SetLoadFields("Entry No.", "Status_DXR", "Dx Status");
        if DetailedCustLedgEntry.FindSet(false) then
            repeat
                if DetailedCustLedgEntry."Status_DXR" <> DetailedCustLedgEntry."Dx Status" then
                    if DetailedCustLedgEntryToUpdate.Get(DetailedCustLedgEntry."Entry No.") then begin
                        DetailedCustLedgEntryToUpdate."Status_DXR" := DetailedCustLedgEntryToUpdate."Dx Status";
                        DetailedCustLedgEntryToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until DetailedCustLedgEntry.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // ===== Sub-batch 2a, procedure 1/4: updateWithholdingEntries() =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 409-468, gated by real tag literal
    // 'DX-UpgradeTagT2026031_WithholdingEntries-03102026' (DXR_UpgradeTagMgt.Codeunit.al's own
    // UpgradeTagT2026031_WithholdingEntries(), reused verbatim - not a granular per-concept tag like
    // some earlier campaign batches, this one is the real tag DR-Localization itself uses for this
    // exact fix).
    //
    // What real gap it fixes: for every DXR_VendWithholdLedgerEntry row (vendor withholding), finds the
    // matching "Vendor Ledger Entry" rows (by "NCF_DXR" when "NCF Afectado" is set, else by
    // "Document No.", always also filtered by "Vendor No." per real source's own T20260401.0001 cross-
    // vendor-contamination guard) - NO Document Type filter is applied to the VLE find itself (unlike
    // Batch 1's RepairVendorLedgerEntryDocumentTypes, which DOES filter to Payment|"DX Withholding" -
    // this is a genuine, faithfully-preserved difference between the two procedures, not an omission).
    // For each matched VLE row: if its Document Type is Payment, reclassifies it to "DX Withholding";
    // then, ONLY if the (possibly just-reclassified) Document Type is "DX Withholding", stamps
    // "Withholding Payment_DXR" := true and back-fills whichever of "Cod. Retencion ITBIS_DXR" /
    // "Cod. Retencion ISR_DXR" is still BLANK (never overwrites an already-populated code) from the
    // withholding entry's own "Tipo Retencion" (ITBIS/ISR) branch. A parallel, simpler pass then does
    // the same Document Type reclassification (Payment -> "DX Withholding") for Customer withholding
    // entries (DXR_Cust Withhold Entries) against "Cust. Ledger Entry" - no field back-fill on the
    // customer side, matching real source exactly (real source's customer loop only reclassifies
    // Document Type, nothing else).
    //
    // Modify()-with-triggers note (deliberate, NOT normalized to Modify(false)): real source calls bare
    // "VendorLedgerEntry.Modify();" / "CustomerLedgerEntry.Modify();" (RunTrigger = true, the default) -
    // unlike every other repair procedure in this codeunit, which explicitly uses Modify(false). This
    // is preserved verbatim per this task's "do not simplify/improve/reorder" instruction - it means
    // this specific correction DOES run standard field-validation/OnModify triggers on live Vendor/Cust
    // Ledger Entry rows (e.g. Document Type reclassification), unlike Batch 1's raw Modify(false)
    // patches. Flagged as a concern for review, not silently normalized.
    //
    // Shadow-field check: DXR_Cust Withhold Entries (table 52143/36002851) is itself
    // ObsoleteState = Pending / ObsoleteReason = 'The customer withholding module is deprecated' (whole
    // table, not just a field) - confirmed against DXR_CustomerWithholdingEntries.Table.al. Real source
    // still reads it unconditionally in this exact procedure, so it is ported faithfully (matches "port
    // exactly what real source does" instruction) - flagged as a concern since a table-level Obsolete-
    // Pending source this deep in an active correction procedure is unusual and worth review attention.
    // "NCF_DXR" (Cust. Ledger Entry field 51812/36002900) confirmed live/non-obsolete against
    // DXR_CustLedgerEntryExtDx.TableExt.al.
    //
    // Commit() placement: DXR_VendWithholdLedgerEntry is the same live/growing table Batch 1's
    // RepairVendorLedgerEntryDocumentTypes already outer-loops with periodic Commit() every 100 rows
    // (per-outer-row inner re-scan of the transaction-volume Vendor Ledger Entry table) - same reasoning
    // applied here (real source has no Commit() at all). One shared BatchCount spans both the vendor and
    // customer loops below.
    local procedure BootstrapUpdateWithholdingEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-UpgradeTagT2026031_WithholdingEntries-03102026') then begin
            UpdateWithholdingEntries();
            UpgradeTag.SetUpgradeTag('DX-UpgradeTagT2026031_WithholdingEntries-03102026');
        end;
    end;

    local procedure UpdateWithholdingEntries()
    var
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustomerWithholdingEntry: Record "DXR_Cust Withhold Entries";
        CustomerLedgerEntry: Record "Cust. Ledger Entry";
        BatchCount: Integer;
    begin
        if WithholdingEntry.FindSet(false) then
            repeat
                VendorLedgerEntry.Reset();
                if WithholdingEntry."NCF Afectado" <> '' then
                    VendorLedgerEntry.SetRange("NCF_DXR", WithholdingEntry."NCF Afectado")
                else
                    VendorLedgerEntry.SetRange("Document No.", WithholdingEntry."No. Documento");

                // Always filter by vendor to prevent cross-vendor contamination (real source T20260401.0001).
                VendorLedgerEntry.SetRange("Vendor No.", WithholdingEntry."Cod. Proveedor");

                if VendorLedgerEntry.FindSet(false) then
                    repeat
                        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::Payment then
                            VendorLedgerEntry."Document Type" := VendorLedgerEntry."Document Type"::"DX Withholding";

                        if VendorLedgerEntry."Document Type" = VendorLedgerEntry."Document Type"::"DX Withholding" then begin
                            VendorLedgerEntry."Withholding Payment_DXR" := true;
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    if (VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (WithholdingEntry."Cod. Retencion ITBIS" <> '') then
                                        VendorLedgerEntry."Cod. Retencion ITBIS_DXR" := WithholdingEntry."Cod. Retencion ITBIS";
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    if (VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (WithholdingEntry."Cod. Retencion ISR" <> '') then
                                        VendorLedgerEntry."Cod. Retencion ISR_DXR" := WithholdingEntry."Cod. Retencion ISR";
                            end;
                        end;

                        VendorLedgerEntry.Modify();
                    until VendorLedgerEntry.Next() = 0;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until WithholdingEntry.Next() = 0;

        if CustomerWithholdingEntry.FindSet(false) then
            repeat
                CustomerLedgerEntry.Reset();
                if CustomerWithholdingEntry."NCF Afectado" <> '' then
                    CustomerLedgerEntry.SetRange("NCF_DXR", CustomerWithholdingEntry."NCF Afectado")
                else
                    CustomerLedgerEntry.SetRange("Document No.", CustomerWithholdingEntry."No. Documento");

                if CustomerLedgerEntry.FindSet(false) then
                    repeat
                        if CustomerLedgerEntry."Document Type" = CustomerLedgerEntry."Document Type"::Payment then begin
                            CustomerLedgerEntry."Document Type" := CustomerLedgerEntry."Document Type"::"DX Withholding";
                            CustomerLedgerEntry.Modify();
                        end;
                    until CustomerLedgerEntry.Next() = 0;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until CustomerWithholdingEntry.Next() = 0;
    end;

    // ===== Sub-batch 2a, procedure 2/4: Fix606CategoriaNCFAndITBISAdelantar() =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 1491-1540, gated by real tag literal
    // 'DX-T20260326.0001-Fix606CategoriaNCFAndITBISAdelantar' (DXR_UpgradeTagMgt.Codeunit.al's own
    // UpgradeTag606CategoriaBugFix(), reused verbatim).
    //
    // What real bugs it fixes, over DXR_Archived Purchase - (606) rows filtered to "Reporta 606" = true:
    //   Bug 1 - "Categoria NCF" left blank on the archived 606 row even though the source posted
    //   document (Purch. Inv. Header for "Tipo Documento" = Invoice, Purch. Cr. Memo Hdr. for
    //   "Tipo Documento" = "Credit Memo") DOES have a "Cod. Categoria NCF_DXR" populated - backfills
    //   both "Categoria NCF" and its "Desc. Categoria NCF" (looked up from NCFCategories_DXR.DXDescripcion
    //   when the category code resolves) from the header. Real source comment: "Fix 606 Categoria NCF
    //   blank on Credit Memo" - this is specifically about Credit Memo rows going through 606 reporting
    //   without their NCF fiscal category.
    //   Bug 2 - "ITBIS por adelantar" (and its ICY companion) left at 0 even though ITBIS was actually
    //   invoiced ("ITBIS Facturado ICY" <> 0) - condition is exactly "ITBIS Facturado ICY <> 0 AND
    //   ITBIS por adelantar = 0" (both must hold; a real, already-zero-by-design row is left untouched),
    //   recomputed as "ITBIS Facturado" minus "ITBIS llevado al costo" (and the ICY companions).
    // Both bugs are independently gated by their own Modified flag inside the same row iteration - a
    // row can trigger neither, either, or both fixes in the same pass, matching real source exactly.
    //
    // Shadow-field check: "Cod. Categoria NCF_DXR" confirmed live (non-obsolete) on both
    // Purch. Inv. Header (field 51965/36003169) and Purch. Cr. Memo Hdr. (field 51940/36003144); all
    // DXR_Archived Purchase - (606) fields referenced (table 52113/36002841) confirmed live/correct-type
    // against DXR_ArchivedPurchase606.Table.al - none obsolete.
    //
    // Commit() placement: real source has no Commit() at all. Archive606 here is filtered to
    // "Reporta 606" = true only (no date-range or NCF-category narrowing) - a reporting-scope filter,
    // not a small fixed set, and potentially spans the company's entire 606-reportable purchase history
    // - periodic Commit() every 100 rows added, same judgment this campaign applies to any
    // transaction-history-scale table scan lacking one in real source.
    local procedure BootstrapFix606CategoriaNCFAndITBISAdelantar()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260326.0001-Fix606CategoriaNCFAndITBISAdelantar') then begin
            Fix606CategoriaNCFAndITBISAdelantar();
            UpgradeTag.SetUpgradeTag('DX-T20260326.0001-Fix606CategoriaNCFAndITBISAdelantar');
        end;
    end;

    local procedure Fix606CategoriaNCFAndITBISAdelantar()
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        NcfCategories: Record NCFCategories_DXR;
        Modified: Boolean;
        BatchCount: Integer;
    begin
        Archive606.Reset();
        Archive606.SetRange("Reporta 606", true);
        if not Archive606.FindSet(true) then
            exit;
        repeat
            Modified := false;

            // Bug 1: "Categoria NCF" blank - backfill from the posted Purch. Invoice/Credit Memo header.
            if Archive606."Categoria NCF" = '' then
                case Archive606."Tipo Documento" of
                    "Gen. Journal Document Type"::Invoice:
                        if PurchInvHeader.Get(Archive606."No. Documento") then
                            if PurchInvHeader."Cod. Categoria NCF_DXR" <> '' then begin
                                Archive606."Categoria NCF" := PurchInvHeader."Cod. Categoria NCF_DXR";
                                if NcfCategories.Get(PurchInvHeader."Cod. Categoria NCF_DXR") then
                                    Archive606."Desc. Categoria NCF" := NcfCategories.DXDescripcion;
                                Modified := true;
                            end;
                    "Gen. Journal Document Type"::"Credit Memo":
                        if PurchCrMemoHdr.Get(Archive606."No. Documento") then
                            if PurchCrMemoHdr."Cod. Categoria NCF_DXR" <> '' then begin
                                Archive606."Categoria NCF" := PurchCrMemoHdr."Cod. Categoria NCF_DXR";
                                if NcfCategories.Get(PurchCrMemoHdr."Cod. Categoria NCF_DXR") then
                                    Archive606."Desc. Categoria NCF" := NcfCategories.DXDescripcion;
                                Modified := true;
                            end;
                end;

            // Bug 2: "ITBIS por adelantar" left at 0 even though ITBIS was actually invoiced.
            if (Archive606."ITBIS Facturado ICY" <> 0) and (Archive606."ITBIS por adelantar" = 0) then begin
                Archive606."ITBIS por adelantar" := Archive606."ITBIS Facturado" - Archive606."ITBIS llevado al costo";
                Archive606."ITBIS por adelantar ICY" := Archive606."ITBIS Facturado ICY" - Archive606."ITBIS llevado al costo ICY";
                Modified := true;
            end;

            if Modified then
                Archive606.Modify(false);

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until Archive606.Next() = 0;
    end;

    // ===== Sub-batch 2a, procedure 3/4: Fix606ISRWithholdingTypeBlank() =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 1544-1569, gated by real tag literal
    // 'DX-T20260326.0001-Fix606ISRWithholdingTypeBlank' (DXR_UpgradeTagMgt.Codeunit.al's own
    // UpgradeTag606ISRWithholdingTypeFix(), reused verbatim).
    //
    // What real gap it fixes: for DXR_Archived Purchase - (606) rows filtered to "Reporta 606" = true
    // AND "ISR withholding Type" = '' (narrow correction subset, not the whole 606 archive), where
    // "Importe Ret. Renta ICY" <> 0 (an ISR retention amount actually exists on the row) - looks up the
    // matching DXR_VendWithholdLedgerEntry row (by "No. Factura" = Archive606's "No. Documento", filtered
    // to "Tipo Retencion" = ISR, FindFirst - first match only, real source's own choice), and if that
    // entry's own "Cod. Retencion ISR" resolves through DXR_Vendor Withholding Setup to a non-blank
    // "DXR_ISR withholding Type", backfills that value onto Archive606's own "ISR withholding Type".
    // Net effect: a 606-reportable purchase row that clearly had ISR withheld (nonzero retained amount)
    // but was missing its "ISR withholding Type" classification gets it backfilled from the withholding
    // code's own setup record - a genuine reporting-completeness gap, not a value overwrite (target
    // field is only ever blank going in, per the outer SetRange filter itself).
    //
    // Shadow-field check: DXR_Vendor Withholding Setup (table 52205/36002882, Access = Internal) field
    // "DXR_ISR withholding Type" (54100, Code[10]) confirmed live against
    // DXR_VendorWithholdingSetup.Table.al; DXR_VendWithholdLedgerEntry fields used ("No. Factura",
    // "Tipo Retencion", "Cod. Retencion ISR") already confirmed live in Batch 1's own field mapping.
    //
    // Commit() placement: real source has no Commit(). Filter is narrower than procedure 2/4's
    // (additionally scoped to blank "ISR withholding Type"), likely a smaller correction set in
    // practice, but still unbounded by date/volume at the query level - periodic Commit() every 100
    // rows added for the same consistency reason applied to the other 3 procedures in this sub-batch.
    local procedure BootstrapFix606ISRWithholdingTypeBlank()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260326.0001-Fix606ISRWithholdingTypeBlank') then begin
            Fix606ISRWithholdingTypeBlank();
            UpgradeTag.SetUpgradeTag('DX-T20260326.0001-Fix606ISRWithholdingTypeBlank');
        end;
    end;

    local procedure Fix606ISRWithholdingTypeBlank()
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorWithholdingSetup: Record "DXR_Vendor Withholding Setup";
        BatchCount: Integer;
    begin
        Archive606.Reset();
        Archive606.SetRange("Reporta 606", true);
        Archive606.SetRange("ISR withholding Type", '');
        if not Archive606.FindSet(true) then
            exit;
        repeat
            if Archive606."Importe Ret. Renta ICY" <> 0 then begin
                WithholdingEntry.Reset();
                WithholdingEntry.SetRange("No. Factura", Archive606."No. Documento");
                WithholdingEntry.SetRange("Tipo Retencion", WithholdingEntry."Tipo Retencion"::ISR);
                if WithholdingEntry.FindFirst() then
                    if WithholdingEntry."Cod. Retencion ISR" <> '' then
                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                            if VendorWithholdingSetup."DXR_ISR withholding Type" <> '' then begin
                                Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                Archive606.Modify(false);
                            end;
            end;

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until Archive606.Next() = 0;
    end;

    // ===== Sub-batch 2a, procedure 4/4: FixVLEWithholdingApplyType() =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 1573-1665. Called TWICE by the real
    // orchestrator (RunRecentV27DataUpgrades(), lines 281-288), under TWO separate real tags:
    // 'DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank' (UpgradeTagVLEWithholdingApplyType()) and
    // 'DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank-V2' (UpgradeTagVLEWithholdingApplyTypeV2()).
    // DXR_UpgradeTagMgt.Codeunit.al's own comment on the V2 tag: "V2 rerun: strengthen matching for On
    // Invoice cases" - i.e. the V1 run didn't fully cover On-Invoice-history matching, so DR-Localization
    // shipped a second, identical-body re-run under a new tag rather than patching the V1 logic in
    // place. Preserved verbatim here as TWO separate gated calls to the SAME procedure body (see
    // BootstrapFixVLEWithholdingApplyType() below) - NOT deduplicated into one call, per this task's
    // explicit instruction; this does mean the full body runs twice on a fresh company where neither tag
    // is yet set, matching real, current DRLOC behavior exactly.
    //
    // What real gap it fixes: for every DXR_VendWithholdLedgerEntry row, derives an "AppliedDocNo"
    // ("No. Documento", falling back to "No. Factura" if blank) and "AffectedNCF" ("NCF Afectado"), then
    // stamps "Withholding Apply Type_DXR" on matching Vendor Ledger Entry rows whose Document Type is
    // "DX Withholding" (Invoice/CrMemo VLEs are never touched, per real source's own comment) - but ONLY
    // when the target field is still blank (option value " ", never overwrites an already-set On
    // Invoice/On Payment value). Value chosen: "On Payment" if the withholding entry's own "Withholding
    // Apply Type" is "On Payment", else "On Invoice". Matching cascades through 3 tiers per withholding
    // entry, each with its own separate VLE.FindSet/repeat (real source structure preserved exactly,
    // not merged into one filter):
    //   1) Strict match by NCF_DXR + Vendor No. (skipped if AffectedNCF is blank) - "most reliable for
    //      On Invoice history data" per real source comment.
    //   2) Strict match by Document No. + Vendor No. - always attempted (unconditional, regardless of
    //      whether tier 1 found anything).
    //   3) Fallback (only if NEITHER tier 1 nor tier 2 found any row - FoundAny stays false): re-tries
    //      both NCF_DXR and Document No. matches WITHOUT the Vendor No. filter, for old data with a
    //      blank/mismatched vendor no. on the withholding entry itself.
    // A row can be stamped by more than one tier if all three would otherwise match different subsets of
    // VLEs - each tier's own blank-check (" ") prevents re-stamping a row a prior tier already touched.
    //
    // Shadow-field check: "Withholding Apply Type_DXR" (Vendor Ledger Entry field 51821/36002911,
    // Option, OptionMembers " ",On Invoice","On Payment") and its legacy pair "DX Withholding Apply
    // Type" (54212/36002901, ObsoleteState = Pending) confirmed against DXR_VendorLedgerEntryExt
    // .TableExt.AL - same option members/order as Batch 1 already relied on for these two fields.
    // "NCF_DXR" on Vendor Ledger Entry already confirmed live in Batch 1.
    //
    // Commit() placement: real source has no Commit() at all, and this is the most row-intensive
    // procedure in this sub-batch - an unfiltered outer scan of ALL DXR_VendWithholdLedgerEntry rows
    // ("Iterates all withholding ledger entries" per real source's own comment, preserved above), each
    // with up to 3 separate inner re-scans of the transaction-volume Vendor Ledger Entry table - same
    // class of gap as Batch 1's RepairVendorLedgerEntryDocumentTypes (its own direct structural sibling)
    // - periodic Commit() every 100 outer rows added, matching that precedent exactly.
    local procedure BootstrapFixVLEWithholdingApplyType()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank') then begin
            FixVLEWithholdingApplyType();
            UpgradeTag.SetUpgradeTag('DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank');
        end;
        if not UpgradeTag.HasUpgradeTag('DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank-V2') then begin
            FixVLEWithholdingApplyType();
            UpgradeTag.SetUpgradeTag('DX-T20260326.0001-FixVLEDXWithholdingApplyTypeBlank-V2');
        end;
    end;

    local procedure FixVLEWithholdingApplyType()
    var
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        AppliedDocNo: Code[20];
        AffectedNCF: Code[20];
        FoundAny: Boolean;
        BatchCount: Integer;
    begin
        // Iterates all withholding ledger entries and stamps ALL matching DX Withholding VLEs (only
        // Document Type = "DX Withholding"; Invoice/CrMemo VLEs are not touched) - real source comment
        // preserved verbatim.
        WithholdingEntry.Reset();
        if not WithholdingEntry.FindSet() then
            exit;
        repeat
            AppliedDocNo := WithholdingEntry."No. Documento";
            if AppliedDocNo = '' then
                AppliedDocNo := WithholdingEntry."No. Factura";
            AffectedNCF := WithholdingEntry."NCF Afectado";

            if (AppliedDocNo <> '') or (AffectedNCF <> '') then begin
                FoundAny := false;

                // First try strict match by NCF + vendor (most reliable for On Invoice history data).
                if AffectedNCF <> '' then begin
                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"DX Withholding");
                    VendorLedgerEntry.SetRange("NCF_DXR", AffectedNCF);
                    VendorLedgerEntry.SetRange("Vendor No.", WithholdingEntry."Cod. Proveedor");
                    if VendorLedgerEntry.FindSet(true) then
                        repeat
                            FoundAny := true;
                            if VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::" " then begin
                                if WithholdingEntry."Withholding Apply Type" = WithholdingEntry."Withholding Apply Type"::"On Payment" then
                                    VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Payment"
                                else
                                    VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice";
                                VendorLedgerEntry.Modify(false);
                            end;
                        until VendorLedgerEntry.Next() = 0;
                end;

                // Second try strict match by Document No. + vendor.
                VendorLedgerEntry.Reset();
                VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"DX Withholding");
                VendorLedgerEntry.SetRange("Document No.", AppliedDocNo);
                VendorLedgerEntry.SetRange("Vendor No.", WithholdingEntry."Cod. Proveedor");
                if VendorLedgerEntry.FindSet(true) then
                    repeat
                        FoundAny := true;
                        if VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::" " then begin
                            if WithholdingEntry."Withholding Apply Type" = WithholdingEntry."Withholding Apply Type"::"On Payment" then
                                VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Payment"
                            else
                                VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice";
                            VendorLedgerEntry.Modify(false);
                        end;
                    until VendorLedgerEntry.Next() = 0;

                // Fallback for old data with blank/mismatched vendor no. in the withholding entry.
                if not FoundAny then begin
                    if AffectedNCF <> '' then begin
                        VendorLedgerEntry.Reset();
                        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"DX Withholding");
                        VendorLedgerEntry.SetRange("NCF_DXR", AffectedNCF);
                        if VendorLedgerEntry.FindSet(true) then
                            repeat
                                if VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::" " then begin
                                    if WithholdingEntry."Withholding Apply Type" = WithholdingEntry."Withholding Apply Type"::"On Payment" then
                                        VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Payment"
                                    else
                                        VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice";
                                    VendorLedgerEntry.Modify(false);
                                end;
                            until VendorLedgerEntry.Next() = 0;
                    end;

                    VendorLedgerEntry.Reset();
                    VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"DX Withholding");
                    VendorLedgerEntry.SetRange("Document No.", AppliedDocNo);
                    if VendorLedgerEntry.FindSet(true) then
                        repeat
                            if VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::" " then begin
                                if WithholdingEntry."Withholding Apply Type" = WithholdingEntry."Withholding Apply Type"::"On Payment" then
                                    VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Payment"
                                else
                                    VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice";
                                VendorLedgerEntry.Modify(false);
                            end;
                        until VendorLedgerEntry.Next() = 0;
                end;
            end;

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until WithholdingEntry.Next() = 0;
    end;

    // ===== Sub-batch 2b, procedure 1/4: BackfillWithholdingPaymentAndCodes() =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 1669-1706, gated by real tag literal
    // 'DX-T20260401.0001-BackfillWithholdingPaymentAndCodes-V2' (DXR_UpgradeTagMgt.Codeunit.al's own
    // UpgradeTagWithholdingPaymentAndCodesV2(), reused verbatim - note the tag literal itself carries a
    // "-V2" suffix even though the procedure name/body have no separate V1; real source has only ever
    // shipped this one body under this one (V2-named) tag, unlike the genuine V1/V2/V3 progression on
    // Fix606WithholdingByVendor below - preserved exactly as real source names it, not renamed).
    //
    // What real gap it fixes: for every DXR_VendWithholdLedgerEntry row, finds matching "Vendor Ledger
    // Entry" rows already of Document Type = "DX Withholding" (unlike updateWithholdingEntries()/
    // BackfillWithholdingPaymentAndCodes's sub-batch-2a sibling, this procedure does NOT reclassify
    // Payment -> "DX Withholding" itself - it only back-fills fields on rows that are ALREADY
    // "DX Withholding") - matched by "NCF_DXR" when "NCF Afectado" is set, else by "Document No.",
    // always also filtered by "Vendor No." (real source's own T20260401.0001 cross-vendor-contamination
    // guard, same guard reused verbatim in sub-batch 2a's updateWithholdingEntries()). For each matched
    // VLE row: unconditionally stamps "Withholding Payment_DXR" := true (no dirty-check, always set,
    // exactly as real source does it - not gated on the field's current value), then back-fills
    // whichever of "Cod. Retencion ITBIS_DXR" / "Cod. Retencion ISR_DXR" is still BLANK (never
    // overwrites an already-populated code) from the withholding entry's own "Tipo Retencion"
    // (ITBIS/ISR) branch - the same blank-only back-fill pattern as every other correction procedure in
    // this sub-campaign.
    //
    // Modify()-with-triggers note: real source calls bare "VLE.Modify(false);" here (NOT the bare
    // "VendorLedgerEntry.Modify();" with RunTrigger = true that sub-batch 2a's updateWithholdingEntries()
    // uses) - preserved verbatim, Modify(false) matches every other repair procedure in this codeunit.
    //
    // Shadow-field check: all fields referenced (DXR_VendWithholdLedgerEntry's "NCF Afectado",
    // "No. Documento", "Cod. Proveedor", "Tipo Retencion", "Cod. Retencion ITBIS"/"Cod. Retencion ISR";
    // Vendor Ledger Entry's "NCF_DXR", "Document No.", "Vendor No.", "Withholding Payment_DXR",
    // "Cod. Retencion ITBIS_DXR"/"Cod. Retencion ISR_DXR") already confirmed live in Batch 1 / sub-batch
    // 2a's own field mapping - no new fields introduced by this procedure. Ported var name "VLE"
    // normalized to "VendorLedgerEntry", matching this codeunit's own established naming (same
    // normalization rationale as sub-batch 2a's header note).
    //
    // Commit() placement: real source has no Commit() at all - unfiltered outer scan of ALL
    // DXR_VendWithholdLedgerEntry rows, each with its own inner Vendor Ledger Entry re-scan (same
    // structural shape as sub-batch 2a's FixVLEWithholdingApplyType / Batch 1's
    // RepairVendorLedgerEntryDocumentTypes) - periodic Commit() every 100 outer rows added, matching
    // that established precedent.
    local procedure BootstrapBackfillWithholdingPaymentAndCodes()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260401.0001-BackfillWithholdingPaymentAndCodes-V2') then begin
            BackfillWithholdingPaymentAndCodes();
            UpgradeTag.SetUpgradeTag('DX-T20260401.0001-BackfillWithholdingPaymentAndCodes-V2');
        end;
    end;

    local procedure BackfillWithholdingPaymentAndCodes()
    var
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BatchCount: Integer;
    begin
        WithholdingEntry.Reset();
        if not WithholdingEntry.FindSet() then
            exit;

        repeat
            VendorLedgerEntry.Reset();
            VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"DX Withholding");

            if WithholdingEntry."NCF Afectado" <> '' then
                VendorLedgerEntry.SetRange("NCF_DXR", WithholdingEntry."NCF Afectado")
            else
                VendorLedgerEntry.SetRange("Document No.", WithholdingEntry."No. Documento");

            // T20260401.0001 - Always filter by vendor to prevent cross-vendor contamination.
            VendorLedgerEntry.SetRange("Vendor No.", WithholdingEntry."Cod. Proveedor");

            if VendorLedgerEntry.FindSet(true) then
                repeat
                    VendorLedgerEntry."Withholding Payment_DXR" := true;

                    case WithholdingEntry."Tipo Retencion" of
                        WithholdingEntry."Tipo Retencion"::ITBIS:
                            if (VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (WithholdingEntry."Cod. Retencion ITBIS" <> '') then
                                VendorLedgerEntry."Cod. Retencion ITBIS_DXR" := WithholdingEntry."Cod. Retencion ITBIS";
                        WithholdingEntry."Tipo Retencion"::ISR:
                            if (VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (WithholdingEntry."Cod. Retencion ISR" <> '') then
                                VendorLedgerEntry."Cod. Retencion ISR_DXR" := WithholdingEntry."Cod. Retencion ISR";
                    end;

                    VendorLedgerEntry.Modify(false);
                until VendorLedgerEntry.Next() = 0;

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until WithholdingEntry.Next() = 0;
    end;

    // ===== Sub-batch 2b, procedures 2-4/4: Fix606WithholdingByVendor() / V2() / V3() - the genuine
    // V1/V2/V3 "fix the fix" progression =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 1710-1821 (V1), 1821-1925 (V2), 1925-2031
    // (V3) - THREE separate, sequentially-gated procedures, each its own distinct body (not one
    // procedure called 3 times like sub-batch 2a's FixVLEWithholdingApplyType). Real orchestrator
    // (RunRecentV27DataUpgrades()) calls all three, in order, each under its own real tag literal:
    //   V1: 'DX-T20260401.0001-Fix606WithholdingByVendor'  (UpgradeTag606WithholdingByVendorFix())
    //   V2: 'DX-T20260406.0001-Fix606WithholdingByVendor-V2' (UpgradeTag606WithholdingByVendorFixV2())
    //   V3: 'DX-T20260406.0001-Fix606WithholdingByVendor-V3' (UpgradeTag606WithholdingByVendorFixV3())
    // On a fresh/never-run tenant all three still run unconditionally in sequence, per this task's
    // instruction - NOT deduplicated or collapsed into a single "final" version.
    //
    // Common shape across all 3: for every DXR_Archived Purchase - (606) row with a non-blank "NCF"
    // (SetFilter NCF <> ''), FIRST unconditionally clears 13 withholding-related fields ("Fecha Pago",
    // "Withholding Date", AnoMes_FPago, Dia_FPago, "ITBIS Retenido"/ICY, "Importe Ret. Renta"/ICY,
    // "ITBIS Percibido"/ICY, "ISR Percibido"/ICY, "ISR withholding Type") to 0D/0/'' - a full
    // recompute-from-scratch pattern, not an incremental patch - THEN re-derives them from matching
    // DXR_VendWithholdLedgerEntry rows, accumulating amounts with += (a single Archive606 row can be
    // fed by multiple withholding entries) branched by "Withholding Apply Type" (On Payment -> "ITBIS
    // Retenido"/"Importe Ret. Renta" fields; On Invoice -> "ITBIS Percibido"/"ISR Percibido" fields;
    // blank/unknown Withholding Apply Type falls through to the On-Payment branch as a legacy default,
    // per real source's own inline comment preserved above each case), and stamps "ISR withholding
    // Type" from DXR_Vendor Withholding Setup only on ISR-type entries (never from ITBIS entries).
    // Dates: "Withholding Date"/"Fecha Pago"/AnoMes_FPago/Dia_FPago are (re)assigned from EACH matched
    // withholding entry in loop order (last-matched-wins, no explicit "latest date" comparison in any
    // of the 3 versions) - prefers "Fecha Retencion", falls back to "Payment Date" only when
    // "Fecha Retencion" is blank. Always unconditional Modify(false) at the end of each outer row (even
    // when no withholding entries matched - the clear-first fields simply stay at their cleared values,
    // per real source's own comment preserved above), matching V1's real comment exactly.
    //
    // ===== What actually changed V1 -> V2 -> V3 (the whole point of this sub-batch) =====
    //   V1 -> V2 matching change: V1 matches withholding entries by "NCF Afectado" = Archive606.NCF AND
    //     "Cod. Proveedor" = Archive606."Cod. Proveedor" (internal vendor code). V2 DROPS the vendor-code
    //     match and instead matches by "NCF Afectado" = Archive606.NCF AND "RNC/Cedula" =
    //     Archive606."Cod. Identificacion" (the vendor's fiscal ID / RNC-Cedula) - i.e. V2 switches the
    //     cross-vendor-contamination guard from an internal-code join to a fiscal-ID join. V1's real
    //     source also declares a local "FoundMatch" Boolean, set true when any withholding entry matches,
    //     but never actually branches on it afterward (the "if no entries found, fields stay cleared"
    //     comment describes what happens by fall-through, not by checking FoundMatch) - a vestigial/dead
    //     variable in real, current V1 source, preserved verbatim here (not dropped) per this task's
    //     no-simplification instruction; V2 removes this unused variable entirely (a genuine, faithfully
    //     ported difference between the two real bodies, not an omission on this port's part). The
    //     case/accumulation logic itself (Withholding Apply Type / Tipo Retencion branches) is IDENTICAL
    //     between V1 and V2 - V2's own header comment ("Corrects bug where ITBIS entries incorrectly set
    //     ISR withholding Type") describes a defect already absent from V1's own case structure as read
    //     in this batch (ISR withholding Type is only ever stamped from the ISR branches in both V1 and
    //     V2) - most likely describing a bug in a pre-V1 version not read as part of this campaign;
    //     flagged for reviewer awareness rather than silently resolved.
    //   V2 -> V3 change: matching filter is IDENTICAL to V2 (NCF Afectado + RNC/Cedula, no FoundMatch
    //     variable). The only functional difference is a NEW final step added AFTER the withholding-entry
    //     loop, before Modify(): if BOTH "Importe Ret. Renta ICY" = 0 AND "ISR Percibido ICY" = 0 (i.e.
    //     no ISR amount was actually accumulated on this row from either apply-type branch), "ISR
    //     withholding Type" is force-cleared to '' even if a withholding-entry iteration had stamped a
    //     non-blank type onto it during the loop. This fixes a residual-stale-value bug in V1/V2: since
    //     "ISR withholding Type" is stamped as a side effect of matching an ISR-type withholding entry
    //     (via DxVendorWithHoldingSetup.Get()), but the loop can still process ITBIS-type entries for the
    //     same NCF+vendor pair AFTER an ISR entry was processed, and neither ITBIS branch ever clears
    //     "ISR withholding Type" - a row could end up with a non-blank ISR type even though its final ISR
    //     retention amount actually is 0 (e.g. an ISR entry with a 0 "Importe Retenido"/zeroed
    //     "Withhold Amount LCY" still stamps the type via Get() before the += accumulation, or NCF+RNC
    //     grouping crosses ISR/ITBIS entries in a way that leaves a type/amount mismatch). V3's guard
    //     enforces "type set <=> some ISR amount actually present" as a post-loop invariant.
    //
    // Shadow-field check: all DXR_Archived Purchase - (606) fields cleared/assigned across all 3
    // versions (Fecha Pago, Withholding Date, AnoMes_FPago, Dia_FPago, ITBIS Retenido/ICY, Importe Ret.
    // Renta/ICY, ITBIS Percibido/ICY, ISR Percibido/ICY, ISR withholding Type, NCF, Cod. Proveedor,
    // Cod. Identificacion) independently re-confirmed live (non-obsolete, correct Decimal/Date/Text/Code
    // types) against the current DXR_ArchivedPurchase606.Table.al. WithholdingEntry fields used
    // ("NCF Afectado", "Cod. Proveedor", "RNC/Cedula", "Withholding Apply Type", "Tipo Retencion",
    // "Importe Retenido", "Withhold Amount LCY", "Cod. Retencion ISR", "Fecha Retencion",
    // "Payment Date") already confirmed live in Batch 1's own field mapping / sub-batch 2a. "Abs(...)"
    // on "Withhold Amount LCY" preserved verbatim (real source's own sign-normalization for the ICY
    // companion fields, same pattern already established). DXR_Vendor Withholding Setup's
    // "DXR_ISR withholding Type" already confirmed live in sub-batch 2a's Fix606ISRWithholdingTypeBlank.
    //
    // Commit() placement: NONE of the 3 real bodies has a Commit() at all - each is a full
    // recompute-from-scratch pass over every DXR_Archived Purchase - (606) row with a non-blank NCF, an
    // unbounded 606-reportable-history-scale scan (same class of gap as sub-batch 2a's procedures 2/4
    // and 3/4 over the same table) - periodic Commit() every 100 rows added independently to EACH of the
    // 3 procedures (they never run concurrently within the same OnRun(), so no shared BatchCount needed
    // across them), matching this sub-campaign's established judgment.
    local procedure BootstrapFix606WithholdingByVendor()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260401.0001-Fix606WithholdingByVendor') then begin
            Fix606WithholdingByVendor();
            UpgradeTag.SetUpgradeTag('DX-T20260401.0001-Fix606WithholdingByVendor');
        end;
    end;

    local procedure Fix606WithholdingByVendor()
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorWithholdingSetup: Record "DXR_Vendor Withholding Setup";
        FoundMatch: Boolean;
        BatchCount: Integer;
    begin
        Archive606.Reset();
        Archive606.SetFilter(NCF, '<>%1', '');
        if not Archive606.FindSet(true) then
            exit;

        repeat
            // Clear all withholding-related fields first, then repopulate only if matched.
            Archive606."Fecha Pago" := 0D;
            Archive606."Withholding Date" := 0D;
            Archive606.AnoMes_FPago := '';
            Archive606.Dia_FPago := '';
            Archive606."ITBIS Retenido" := 0;
            Archive606."ITBIS Retenido ICY" := 0;
            Archive606."Importe Ret. Renta" := 0;
            Archive606."Importe Ret. Renta ICY" := 0;
            Archive606."ITBIS Percibido" := 0;
            Archive606."ITBIS Percibido ICY" := 0;
            Archive606."ISR Percibido" := 0;
            Archive606."ISR Percibido ICY" := 0;
            Archive606."ISR withholding Type" := '';

            FoundMatch := false;

            // Search withholding entries filtered by Vendor + NCF.
            WithholdingEntry.Reset();
            WithholdingEntry.SetRange("NCF Afectado", Archive606.NCF);
            WithholdingEntry.SetRange("Cod. Proveedor", Archive606."Cod. Proveedor");
            if WithholdingEntry.FindSet() then begin
                FoundMatch := true;
                repeat
                    // T20260406.0001 - ISR type only from ISR entries; else branch for blank Withholding
                    // Apply Type; amounts accumulated with +=.
                    case WithholdingEntry."Withholding Apply Type" of
                        WithholdingEntry."Withholding Apply Type"::"On Payment":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        WithholdingEntry."Withholding Apply Type"::"On Invoice":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."ISR Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ISR Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        else
                            // Blank/unknown Withholding Apply Type -> treat as On Payment (legacy default).
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                    end;

                    // Assign dates from the matched withholding entry: prefer Fecha Retencion, fallback
                    // to Payment Date.
                    if WithholdingEntry."Fecha Retencion" <> 0D then begin
                        Archive606."Withholding Date" := WithholdingEntry."Fecha Retencion";
                        Archive606."Fecha Pago" := WithholdingEntry."Fecha Retencion";
                        Archive606.AnoMes_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Year4>') + Format(WithholdingEntry."Fecha Retencion", 0, '<Month,2>');
                        Archive606.Dia_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Day,2>');
                    end else
                        if WithholdingEntry."Payment Date" <> 0D then begin
                            Archive606."Withholding Date" := WithholdingEntry."Payment Date";
                            Archive606."Fecha Pago" := WithholdingEntry."Payment Date";
                            Archive606.AnoMes_FPago := Format(WithholdingEntry."Payment Date", 0, '<Year4>') + Format(WithholdingEntry."Payment Date", 0, '<Month,2>');
                            Archive606.Dia_FPago := Format(WithholdingEntry."Payment Date", 0, '<Day,2>');
                        end;
                until WithholdingEntry.Next() = 0;
            end;

            // If no withholding entries found for this vendor+NCF, fields stay cleared (0D / 0).
            Archive606.Modify(false);

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until Archive606.Next() = 0;
    end;

    local procedure BootstrapFix606WithholdingByVendorV2()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260406.0001-Fix606WithholdingByVendor-V2') then begin
            Fix606WithholdingByVendorV2();
            UpgradeTag.SetUpgradeTag('DX-T20260406.0001-Fix606WithholdingByVendor-V2');
        end;
    end;

    // V2 change vs V1 (see the combined header note above this procedure block): matches withholding
    // entries by "NCF Afectado" + "RNC/Cedula" (fiscal ID) instead of "NCF Afectado" + "Cod. Proveedor"
    // (internal vendor code); drops the unused "FoundMatch" variable V1's real source still carries.
    local procedure Fix606WithholdingByVendorV2()
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorWithholdingSetup: Record "DXR_Vendor Withholding Setup";
        BatchCount: Integer;
    begin
        Archive606.Reset();
        Archive606.SetFilter(NCF, '<>%1', '');
        if not Archive606.FindSet(true) then
            exit;

        repeat
            // Clear all withholding-related fields first, then repopulate only if matched.
            Archive606."Fecha Pago" := 0D;
            Archive606."Withholding Date" := 0D;
            Archive606.AnoMes_FPago := '';
            Archive606.Dia_FPago := '';
            Archive606."ITBIS Retenido" := 0;
            Archive606."ITBIS Retenido ICY" := 0;
            Archive606."Importe Ret. Renta" := 0;
            Archive606."Importe Ret. Renta ICY" := 0;
            Archive606."ITBIS Percibido" := 0;
            Archive606."ITBIS Percibido ICY" := 0;
            Archive606."ISR Percibido" := 0;
            Archive606."ISR Percibido ICY" := 0;
            Archive606."ISR withholding Type" := '';

            // Search withholding entries filtered by NCF + RNC/Cedula (fiscal ID, not internal vendor
            // code - see V1/V2 note above).
            WithholdingEntry.Reset();
            WithholdingEntry.SetRange("NCF Afectado", Archive606.NCF);
            WithholdingEntry.SetRange("RNC/Cedula", Archive606."Cod. Identificacion");
            if WithholdingEntry.FindSet() then
                repeat
                    // T20260406.0001 - ISR type only from ISR entries; else branch for blank Withholding
                    // Apply Type; amounts accumulated with +=.
                    case WithholdingEntry."Withholding Apply Type" of
                        WithholdingEntry."Withholding Apply Type"::"On Payment":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        WithholdingEntry."Withholding Apply Type"::"On Invoice":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."ISR Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ISR Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        else
                            // Blank/unknown Withholding Apply Type -> treat as On Payment (legacy default).
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                    end;

                    // Assign dates: prefer Fecha Retencion, fallback to Payment Date.
                    if WithholdingEntry."Fecha Retencion" <> 0D then begin
                        Archive606."Withholding Date" := WithholdingEntry."Fecha Retencion";
                        Archive606."Fecha Pago" := WithholdingEntry."Fecha Retencion";
                        Archive606.AnoMes_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Year4>') + Format(WithholdingEntry."Fecha Retencion", 0, '<Month,2>');
                        Archive606.Dia_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Day,2>');
                    end else
                        if WithholdingEntry."Payment Date" <> 0D then begin
                            Archive606."Withholding Date" := WithholdingEntry."Payment Date";
                            Archive606."Fecha Pago" := WithholdingEntry."Payment Date";
                            Archive606.AnoMes_FPago := Format(WithholdingEntry."Payment Date", 0, '<Year4>') + Format(WithholdingEntry."Payment Date", 0, '<Month,2>');
                            Archive606.Dia_FPago := Format(WithholdingEntry."Payment Date", 0, '<Day,2>');
                        end;
                until WithholdingEntry.Next() = 0;

            Archive606.Modify(false);

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until Archive606.Next() = 0;
    end;

    local procedure BootstrapFix606WithholdingByVendorV3()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260406.0001-Fix606WithholdingByVendor-V3') then begin
            Fix606WithholdingByVendorV3();
            UpgradeTag.SetUpgradeTag('DX-T20260406.0001-Fix606WithholdingByVendor-V3');
        end;
    end;

    // V3 change vs V2 (see the combined header note above the V1 procedure block): same NCF + RNC/Cedula
    // matching as V2, plus a NEW post-loop guard that force-clears "ISR withholding Type" back to '' when
    // neither "Importe Ret. Renta ICY" nor "ISR Percibido ICY" ended up non-zero on the row - fixes a
    // residual-stale-type bug where V1/V2 could leave a non-blank ISR type stamped from an earlier ISR
    // withholding-entry match even though the row's final accumulated ISR amount is 0.
    local procedure Fix606WithholdingByVendorV3()
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        WithholdingEntry: Record DXR_VendWithholdLedgerEntry;
        VendorWithholdingSetup: Record "DXR_Vendor Withholding Setup";
        BatchCount: Integer;
    begin
        Archive606.Reset();
        Archive606.SetFilter(NCF, '<>%1', '');
        if not Archive606.FindSet(true) then
            exit;

        repeat
            // Clear all withholding-related fields first.
            Archive606."Fecha Pago" := 0D;
            Archive606."Withholding Date" := 0D;
            Archive606.AnoMes_FPago := '';
            Archive606.Dia_FPago := '';
            Archive606."ITBIS Retenido" := 0;
            Archive606."ITBIS Retenido ICY" := 0;
            Archive606."Importe Ret. Renta" := 0;
            Archive606."Importe Ret. Renta ICY" := 0;
            Archive606."ITBIS Percibido" := 0;
            Archive606."ITBIS Percibido ICY" := 0;
            Archive606."ISR Percibido" := 0;
            Archive606."ISR Percibido ICY" := 0;
            Archive606."ISR withholding Type" := '';

            // Search withholding entries by NCF + RNC/Cedula (Cod. Identificacion) - centralized matching.
            WithholdingEntry.Reset();
            WithholdingEntry.SetRange("NCF Afectado", Archive606.NCF);
            WithholdingEntry.SetRange("RNC/Cedula", Archive606."Cod. Identificacion");
            if WithholdingEntry.FindSet() then
                repeat
                    case WithholdingEntry."Withholding Apply Type" of
                        WithholdingEntry."Withholding Apply Type"::"On Payment":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        WithholdingEntry."Withholding Apply Type"::"On Invoice":
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."ISR Percibido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ISR Percibido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                        else
                            // Blank/unknown Withholding Apply Type -> treat as On Payment (legacy default).
                            case WithholdingEntry."Tipo Retencion" of
                                WithholdingEntry."Tipo Retencion"::ITBIS:
                                    begin
                                        Archive606."ITBIS Retenido" += WithholdingEntry."Importe Retenido";
                                        Archive606."ITBIS Retenido ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                    end;
                                WithholdingEntry."Tipo Retencion"::ISR:
                                    begin
                                        Archive606."Importe Ret. Renta" += WithholdingEntry."Importe Retenido";
                                        Archive606."Importe Ret. Renta ICY" += Abs(WithholdingEntry."Withhold Amount LCY");
                                        if VendorWithholdingSetup.Get(WithholdingEntry."Cod. Retencion ISR") then
                                            Archive606."ISR withholding Type" := VendorWithholdingSetup."DXR_ISR withholding Type";
                                    end;
                            end;
                    end;

                    // Assign dates: prefer Fecha Retencion, fallback to Payment Date.
                    if WithholdingEntry."Fecha Retencion" <> 0D then begin
                        Archive606."Withholding Date" := WithholdingEntry."Fecha Retencion";
                        Archive606."Fecha Pago" := WithholdingEntry."Fecha Retencion";
                        Archive606.AnoMes_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Year4>') + Format(WithholdingEntry."Fecha Retencion", 0, '<Month,2>');
                        Archive606.Dia_FPago := Format(WithholdingEntry."Fecha Retencion", 0, '<Day,2>');
                    end else
                        if WithholdingEntry."Payment Date" <> 0D then begin
                            Archive606."Withholding Date" := WithholdingEntry."Payment Date";
                            Archive606."Fecha Pago" := WithholdingEntry."Payment Date";
                            Archive606.AnoMes_FPago := Format(WithholdingEntry."Payment Date", 0, '<Year4>') + Format(WithholdingEntry."Payment Date", 0, '<Month,2>');
                            Archive606.Dia_FPago := Format(WithholdingEntry."Payment Date", 0, '<Day,2>');
                        end;
                until WithholdingEntry.Next() = 0;

            // Clear ISR type only when NO ISR retention at all (neither On Payment nor On Invoice) -
            // T20260406.0001 V3's own new post-loop invariant guard.
            if (Archive606."Importe Ret. Renta ICY" = 0) and (Archive606."ISR Percibido ICY" = 0) then
                Archive606."ISR withholding Type" := '';

            Archive606.Modify(false);

            BatchCount += 1;
            if BatchCount >= 100 then begin
                Commit();
                BatchCount := 0;
            end;
        until Archive606.Next() = 0;
    end;

    // ===== Sub-batch 2c: Sync606ChargeHistoryNCF() and its self-contained helper chain =====
    // Real source: DXR_LocUpgradeProcess.Codeunit.al lines 2031-2219, gated by real tag literal
    // 'DX-T20260410.0001-Sync606ChargeHistoryNCF' (DXR_UpgradeTagMgt.Codeunit.al's own
    // UpgradeTag606ChargeHistoryNCFSync(), reused verbatim). This is the LAST of the 11 real sub-fixes
    // called by RunRecentV27DataUpgrades() ported into this codeunit so far - see the header note above
    // for why the remaining 2 (Repair606CardChargeVLEs/Repair606BankChargeVLEs) are deliberately NOT
    // part of this batch, and why registry seq49's Dispatcher Codeunit ID is NOT repointed here.
    //
    // What real gap it fixes: Sync606ChargeHistoryNCF() is a trivial dispatcher (calls the next 2
    // procedures below, in order, unconditionally - no logic of its own). Both
    // Sync606BankChargesFromHistory() and Sync606CardChargesFromHistory() scan their own processed-
    // history table (DXR_Archived Bank Charges Hdr / DXR_Arch. C. C. Charges Header, both filtered to
    // Procesado = true, Anulado = false) and, for each row, call the shared helper
    // SyncChargeHistoryTo606() to back-fill NCF/NCF-Modificado/Document-Date/Vendor-Ledger-Entry-No./
    // Categoria-NCF onto the matching DXR_Archived Purchase - (606) row(s) - i.e. these are DGII "606"
    // purchase-reporting rows generated from posted bank/card charge documents that are missing fields
    // their own source charge document actually has. SyncChargeHistoryTo606() itself is entirely
    // fill-gaps-only (every field write is individually conditional on the target Archive606 field
    // being blank/zero/mismatched from the source - see its own field-by-field comments below); it is
    // never an unconditional overwrite of an already-populated field, matching this whole sub-campaign's
    // established discipline.
    //
    // Matching shape: SyncChargeHistoryTo606() filters DXR_Archived Purchase - (606) by "Tipo Documento"
    // = the caller's own ChargeDocumentType parameter (Enum "Gen. Journal Document Type"::"DX Bank
    // Charge" from the bank-charge caller, ::"DX Card Charge" from the card-charge caller - used purely
    // as a filter value, never branched on inside the shared helper itself, matching the task's own
    // framing), "No. Documento" = the source document's own "No."/"No." (DocumentNo parameter), and
    // "Reporta 606" = true; additionally filtered by "Cod. Proveedor" = VendorNo when VendorNo is
    // non-blank (both callers always pass their own header's "Vendor No.", so this filter is always
    // applied in practice for both charge types) - can match more than one Archive606 row per source
    // document (loops with repeat/until), each independently fill-gapped.
    //
    // The 7 Get* helpers (GetArchivedBankChargeNCF/AffectedNCF, GetArchivedCardChargeNCF/AffectedNCF,
    // GetBankChargeExpenseAccountNo/GetCardChargeExpenseAccountNo, GetChargeCategoryFromExpenseAccount)
    // are short lookups/fallback chains ported verbatim: the bank-charge NCF/Affected-NCF getters prefer
    // the header's own NCF/"NCF Afectado" field, falling back to the first DXR_Arch Bank Charges Lines
    // row with a non-blank NCF/"NCF Afectado" (FindFirst, not a "latest" or "matching" search - real
    // source's own choice, preserved exactly); the card-charge NCF getter prefers the header's own "NCF
    // Mensual", falling back to the first DXR_Arch. C. C. Charges Lines row with a non-blank "Daily NCF";
    // the card-charge Affected-NCF getter has NO line-level fallback at all (reads only the header's own
    // "NCF Afectado", unlike its bank-charge sibling - a genuine, faithfully-preserved asymmetry between
    // the two charge types, not an omission); the 2 expense-account getters each read a single field off
    // the singleton DXR_NCF Setup row ("Cta. Gastos Cargos Banc." / "Cta. Gastos Cargos Tarjetas Cr");
    // GetChargeCategoryFromExpenseAccount() resolves a G/L Account's own "NCFCategories_DXR" field from
    // whichever expense-account no. its caller passed in, returning '' if the account no. is blank or
    // the G/L Account itself doesn't exist. CopyStr(..., 1, 20) truncation guards preserved verbatim on
    // every Code[19]-typed source value being assigned into a Code[20] target (a widening move, so this
    // never actually truncates in practice, but kept exactly as real source writes it).
    //
    // Enum parameter note (task-specified): SyncChargeHistoryTo606()'s ChargeDocumentType parameter
    // (Enum "Gen. Journal Document Type") is used purely as an outer SetRange filter value on Archive606's
    // "Tipo Documento" - it is never branched/cased on inside the shared helper itself, preserved exactly
    // as real source structures it (both callers pass their own already-resolved enum literal in).
    //
    // Shadow-field check: DXR_Archived Purchase - (606)'s NCF (7, Code[20]), "NCF Modificado" (8,
    // Code[20]), "Document Date" (36002771, Date, has its own OnValidate trigger deriving
    // AnoMes_FPago/Dia_FPago-style companions - Validate() used here, not a direct assignment, exactly
    // matching real source's own call), "Vendor Ledger Entry No." (36002777, Integer), "Categoria NCF"
    // (15, Code[20]), "Desc. Categoria NCF" (21, Text[60]), "Reporta 606" (41, Boolean), "Tipo Documento"
    // (1, Enum "Gen. Journal Document Type"), "No. Documento" (2, Code[20]), "Cod. Proveedor" (5,
    // Code[20]) all independently re-confirmed live/non-obsolete against the current
    // DXR_ArchivedPurchase606.Table.al. DXR_Archived Bank Charges Hdr (table 52107/36002838, Access =
    // Internal - No., Document Date, Vendor No., Procesado, Anulado, NCF, "NCF Afectado", "Document
    // Type") and DXR_Arch Bank Charges Lines (table 52109/36002839, Access = Internal - "No.", NCF,
    // "NCF Afectado") confirmed live against DXR_ArchivedBankChargesHdr.Table.al /
    // DXR_ArchivedBankChargesLines.Table.al; DXR_Arch. C. C. Charges Header (table 52259/36002909,
    // Access = Internal - No., Document Date, Vendor No., "NCF Mensual", Procesado, Anulado, "Document
    // Type", "NCF Afectado", "Entry No.") and DXR_Arch. C. C. Charges Lines ("Daily NCF") confirmed live
    // against DXR_ArchCCChargesHeader.Table.al / DXR_ArchCCChargesLines.Table.al; DXR_NCF Setup's "Cta.
    // Gastos Cargos Banc." (10) / "Cta. Gastos Cargos Tarjetas Cr" (11) confirmed live against
    // DXR_NCFSetup.Table.al; G/L Account's own "NCFCategories_DXR" (51812/36002754) confirmed live
    // against DXR_GLAccountExt.TableExt.al. Enum "Gen. Journal Document Type" values "DX Bank Charge"
    // (54100) / "DX Card Charge" (54101) confirmed live against DXR_GenJournalDocumentType.EnumExt.al.
    // None of the fields/tables/enum values referenced by this whole sub-batch carry ObsoleteState.
    //
    // Commit() placement: real source has NO Commit() anywhere in this chain. Unlike every other
    // procedure ported into this codeunit so far, the 2 outer-loop tables here (DXR_Archived Bank
    // Charges Hdr / DXR_Arch. C. C. Charges Header, both further filtered to Procesado = true, Anulado =
    // false) are bounded, processed-history-scale tables - one row per posted/processed bank-charge or
    // credit-card-charge batch document, not a per-transaction ledger-entry-scale table like every prior
    // sub-batch's own outer loop (Vendor Ledger Entry, DXR_VendWithholdLedgerEntry, DXR_Archived
    // Purchase - (606) itself) - no periodic Commit() added here, a deliberate departure from this
    // sub-campaign's own "add Commit() every 100 rows to any unbounded/transaction-volume scan lacking
    // one" default, justified by the genuinely different (bounded, processed-document-count) scale of
    // these 2 specific source tables. The inner SyncChargeHistoryTo606() helper's own Archive606 scan is
    // additionally narrowed by "No. Documento"/"Reporta 606"/"Cod. Proveedor" per outer row (a handful of
    // matches at most per source document), reinforcing that this whole chain is not transaction-volume
    // scale the way the rest of this codeunit's ledger-entry/archive-history scans are.
    local procedure BootstrapSync606ChargeHistoryNCF()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-T20260410.0001-Sync606ChargeHistoryNCF') then begin
            Sync606ChargeHistoryNCF();
            UpgradeTag.SetUpgradeTag('DX-T20260410.0001-Sync606ChargeHistoryNCF');
        end;
    end;

    local procedure Sync606ChargeHistoryNCF()
    begin
        Sync606BankChargesFromHistory();
        Sync606CardChargesFromHistory();
    end;

    local procedure Sync606BankChargesFromHistory()
    var
        ArchivedBankChargesHdr: Record "DXR_Archived Bank Charges Hdr";
    begin
        ArchivedBankChargesHdr.Reset();
        ArchivedBankChargesHdr.SetRange(Procesado, true);
        ArchivedBankChargesHdr.SetRange(Anulado, false);
        if not ArchivedBankChargesHdr.FindSet() then
            exit;

        repeat
            SyncChargeHistoryTo606(
                ArchivedBankChargesHdr."No.",
                ArchivedBankChargesHdr."Vendor No.",
                Enum::"Gen. Journal Document Type"::"DX Bank Charge",
                GetArchivedBankChargeNCF(ArchivedBankChargesHdr),
                GetArchivedBankChargeAffectedNCF(ArchivedBankChargesHdr),
                ArchivedBankChargesHdr."Document Type" = ArchivedBankChargesHdr."Document Type"::"Credit Memo",
                ArchivedBankChargesHdr."Document Date",
                0,
                GetChargeCategoryFromExpenseAccount(GetBankChargeExpenseAccountNo()));
        until ArchivedBankChargesHdr.Next() = 0;
    end;

    local procedure Sync606CardChargesFromHistory()
    var
        ArchCCChargesHeader: Record "DXR_Arch. C. C. Charges Header";
    begin
        ArchCCChargesHeader.Reset();
        ArchCCChargesHeader.SetRange(Procesado, true);
        ArchCCChargesHeader.SetRange(Anulado, false);
        if not ArchCCChargesHeader.FindSet() then
            exit;

        repeat
            SyncChargeHistoryTo606(
                ArchCCChargesHeader."No.",
                ArchCCChargesHeader."Vendor No.",
                Enum::"Gen. Journal Document Type"::"DX Card Charge",
                GetArchivedCardChargeNCF(ArchCCChargesHeader),
                GetArchivedCardChargeAffectedNCF(ArchCCChargesHeader),
                ArchCCChargesHeader."Document Type" = ArchCCChargesHeader."Document Type"::"Credit Memo",
                ArchCCChargesHeader."Document Date",
                ArchCCChargesHeader."Entry No.",
                GetChargeCategoryFromExpenseAccount(GetCardChargeExpenseAccountNo()));
        until ArchCCChargesHeader.Next() = 0;
    end;

    // Fill-gaps-only: every field write below is individually conditional on the target Archive606
    // field currently being blank/zero/mismatched from the source - never an unconditional overwrite.
    local procedure SyncChargeHistoryTo606(DocumentNo: Code[20]; VendorNo: Code[20]; ChargeDocumentType: Enum "Gen. Journal Document Type"; SourceNCF: Code[20]; SourceAffectedNCF: Code[20]; IsCreditMemo: Boolean; SourceDocumentDate: Date; SourceVendorLedgerEntryNo: Integer; SourceCategoryNCF: Code[20])
    var
        Archive606: Record "DXR_Archived Purchase - (606)";
        NcfCategories: Record NCFCategories_DXR;
        Modified: Boolean;
    begin
        if DocumentNo = '' then
            exit;

        Archive606.Reset();
        Archive606.SetRange("Tipo Documento", ChargeDocumentType);
        Archive606.SetRange("No. Documento", DocumentNo);
        Archive606.SetRange("Reporta 606", true);
        if VendorNo <> '' then
            Archive606.SetRange("Cod. Proveedor", VendorNo);
        if not Archive606.FindSet(true) then
            exit;

        repeat
            Modified := false;

            if (SourceNCF <> '') and (Archive606.NCF <> SourceNCF) then begin
                Archive606.NCF := SourceNCF;
                Modified := true;
            end;

            if IsCreditMemo and (SourceAffectedNCF <> '') and (Archive606."NCF Modificado" <> SourceAffectedNCF) then begin
                Archive606."NCF Modificado" := SourceAffectedNCF;
                Modified := true;
            end;

            if (SourceDocumentDate <> 0D) and (Archive606."Document Date" = 0D) then begin
                Archive606.Validate("Document Date", SourceDocumentDate);
                Modified := true;
            end;

            if (SourceVendorLedgerEntryNo <> 0) and (Archive606."Vendor Ledger Entry No." = 0) then begin
                Archive606."Vendor Ledger Entry No." := SourceVendorLedgerEntryNo;
                Modified := true;
            end;

            if (SourceCategoryNCF <> '') and (Archive606."Categoria NCF" = '') then begin
                Archive606."Categoria NCF" := SourceCategoryNCF;
                if NcfCategories.Get(SourceCategoryNCF) then
                    Archive606."Desc. Categoria NCF" := NcfCategories.DXDescripcion;
                Modified := true;
            end;

            if Modified then
                Archive606.Modify(false);
        until Archive606.Next() = 0;
    end;

    // Prefers the header's own NCF; falls back to the first DXR_Arch Bank Charges Lines row with a
    // non-blank NCF (FindFirst - first match only, real source's own choice).
    local procedure GetArchivedBankChargeNCF(ArchivedBankChargesHdr: Record "DXR_Archived Bank Charges Hdr"): Code[20]
    var
        ArchivedBankChargesLines: Record "DXR_Arch Bank Charges Lines";
    begin
        if ArchivedBankChargesHdr.NCF <> '' then
            exit(CopyStr(ArchivedBankChargesHdr.NCF, 1, 20));

        ArchivedBankChargesLines.Reset();
        ArchivedBankChargesLines.SetRange("No.", ArchivedBankChargesHdr."No.");
        ArchivedBankChargesLines.SetFilter(NCF, '<>%1', '');
        if ArchivedBankChargesLines.FindFirst() then
            exit(CopyStr(ArchivedBankChargesLines.NCF, 1, 20));

        exit('');
    end;

    // Prefers the header's own "NCF Afectado"; falls back to the first DXR_Arch Bank Charges Lines row
    // with a non-blank "NCF Afectado".
    local procedure GetArchivedBankChargeAffectedNCF(ArchivedBankChargesHdr: Record "DXR_Archived Bank Charges Hdr"): Code[20]
    var
        ArchivedBankChargesLines: Record "DXR_Arch Bank Charges Lines";
    begin
        if ArchivedBankChargesHdr."NCF Afectado" <> '' then
            exit(CopyStr(ArchivedBankChargesHdr."NCF Afectado", 1, 20));

        ArchivedBankChargesLines.Reset();
        ArchivedBankChargesLines.SetRange("No.", ArchivedBankChargesHdr."No.");
        ArchivedBankChargesLines.SetFilter("NCF Afectado", '<>%1', '');
        if ArchivedBankChargesLines.FindFirst() then
            exit(CopyStr(ArchivedBankChargesLines."NCF Afectado", 1, 20));

        exit('');
    end;

    // Prefers the header's own "NCF Mensual"; falls back to the first DXR_Arch. C. C. Charges Lines row
    // with a non-blank "Daily NCF".
    local procedure GetArchivedCardChargeNCF(ArchCCChargesHeader: Record "DXR_Arch. C. C. Charges Header"): Code[20]
    var
        ArchCCChargesLines: Record "DXR_Arch. C. C. Charges Lines";
    begin
        if ArchCCChargesHeader."NCF Mensual" <> '' then
            exit(CopyStr(ArchCCChargesHeader."NCF Mensual", 1, 20));

        ArchCCChargesLines.Reset();
        ArchCCChargesLines.SetRange("No.", ArchCCChargesHeader."No.");
        ArchCCChargesLines.SetFilter("Daily NCF", '<>%1', '');
        if ArchCCChargesLines.FindFirst() then
            exit(CopyStr(ArchCCChargesLines."Daily NCF", 1, 20));

        exit('');
    end;

    // Reads only the header's own "NCF Afectado" - NO line-level fallback (unlike its bank-charge
    // sibling above), a genuine, faithfully-preserved asymmetry between the two charge types.
    local procedure GetArchivedCardChargeAffectedNCF(ArchCCChargesHeader: Record "DXR_Arch. C. C. Charges Header"): Code[20]
    begin
        exit(CopyStr(ArchCCChargesHeader."NCF Afectado", 1, 20));
    end;

    local procedure GetBankChargeExpenseAccountNo(): Code[20]
    var
        NCFSetup: Record "DXR_NCF Setup";
    begin
        if NCFSetup.Get() then
            exit(CopyStr(NCFSetup."Cta. Gastos Cargos Banc.", 1, 20));

        exit('');
    end;

    local procedure GetCardChargeExpenseAccountNo(): Code[20]
    var
        NCFSetup: Record "DXR_NCF Setup";
    begin
        if NCFSetup.Get() then
            exit(CopyStr(NCFSetup."Cta. Gastos Cargos Tarjetas Cr", 1, 20));

        exit('');
    end;

    local procedure GetChargeCategoryFromExpenseAccount(ExpenseAccountNo: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        if (ExpenseAccountNo <> '') and GLAccount.Get(ExpenseAccountNo) then
            exit(CopyStr(GLAccount."NCFCategories_DXR", 1, 20));

        exit('');
    end;

    // ===== Batch 3, 1/11: seq46 - Arch. Withholding Gov. Hdr whole-table clone (54108 -> 52120) =====
    // Ported from real source's own MigrateTable_ArchWithholdingGovHdr(). All 7 fields identical
    // name/ID/type EXCEPT "No. Series" (Code[20] on the old table narrows to Code[10] on the new table)
    // - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableArchWithholdingGovHdr().
    local procedure BootstrapArchWithholdingGovHdrTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHWITHHOLDINGGOVHDR-20260522') then begin
            MigrateArchWithholdingGovHdrTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHWITHHOLDINGGOVHDR-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateArchWithholdingGovHdrTable()
    var
        OldRec: Record "DXArch Withholding Gov. Hdr";
        NewRec: Record "DXR_Arch Withholding Gov. Hdr";
        BatchCount: Integer;
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet(false) then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Cod. Cliente" := OldRec."Cod. Cliente";
                NewRec."Nombre Cliente" := OldRec."Nombre Cliente";
                NewRec.RNC := OldRec.RNC;
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Fecha := OldRec.Fecha;
                NewRec.Procesado := OldRec.Procesado;
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 2/11: seq47 - Archived Bank Charges Hdr whole-table clone (54102 -> 52107) =====
    // Ported from real source's own MigrateTable_ArchivedBankChargesHdr(). All fields identical
    // name/ID/type; field 12 "Total Documento" is a FlowField on both sides (excluded); field 14 does
    // not exist on either table (gap) - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag
    // reused verbatim from UpgradeTagInternalClosureTableArchivedBankChargesHdr().
    local procedure BootstrapArchivedBankChargesHdrTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDBANKCHARGESHDR-20260522') then begin
            MigrateArchivedBankChargesHdrTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDBANKCHARGESHDR-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateArchivedBankChargesHdrTable()
    var
        OldRec: Record "DXArchived Bank Charges Hdr";
        NewRec: Record "DXR_Archived Bank Charges Hdr";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Document Date" := OldRec."Document Date";
                NewRec."Tamplate Name" := OldRec."Tamplate Name";
                NewRec."Batch Name" := OldRec."Batch Name";
                NewRec."Document No." := OldRec."Document No.";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Vendor Name" := OldRec."Vendor Name";
                NewRec."Bank Acc. No." := OldRec."Bank Acc. No.";
                NewRec."Bank Name" := OldRec."Bank Name";
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Procesado := OldRec.Procesado;
                NewRec."No. Orig. Cargo Banc." := OldRec."No. Orig. Cargo Banc.";
                NewRec."Currency Code" := OldRec."Currency Code";
                NewRec."Currency Factor" := OldRec."Currency Factor";
                NewRec.Anulado := OldRec.Anulado;
                NewRec."Cuenta Gasto" := OldRec."Cuenta Gasto";
                NewRec."Document Type" := OldRec."Document Type";
                NewRec."Dimension Global 1" := OldRec."Dimension Global 1";
                NewRec."Dimension Global 2" := OldRec."Dimension Global 2";
                NewRec."Dimension Set ID" := OldRec."Dimension Set ID";
                NewRec.NCF := OldRec.NCF;
                NewRec.Amount := OldRec.Amount;
                NewRec."Line No." := OldRec."Line No.";
                NewRec."Apply Trans." := OldRec."Apply Trans.";
                NewRec.Description := OldRec.Description;
                NewRec."NCF Afectado" := OldRec."NCF Afectado";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 3/11: seq48 - Withholding Govern. Header whole-table clone (54147 -> 52207) =====
    // Ported from real source's own MigrateTable_WithholdingGovernHeader(). All 7 fields identical
    // name/ID/type, no differences - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused
    // verbatim from UpgradeTagInternalClosureTableWithholdingGovernHeader().
    local procedure BootstrapWithholdingGovernHeaderTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGGOVERNHEADER-20260522') then begin
            MigrateWithholdingGovernHeaderTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGGOVERNHEADER-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateWithholdingGovernHeaderTable()
    var
        OldRec: Record "DXWithholding Govern. Header";
        NewRec: Record "DXR_Withholding Govern. Header";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Cod. Cliente" := OldRec."Cod. Cliente";
                NewRec."Nombre Cliente" := OldRec."Nombre Cliente";
                NewRec.RNC := OldRec.RNC;
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Fecha := OldRec.Fecha;
                NewRec.Procesado := OldRec.Procesado;
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 4/11: seq65 - Arch. C.C. Charges Header whole-table clone (54100 -> 52259) =====
    // Ported from real source's own MigrateTable_ArchCCChargesHeader(). All fields identical
    // name/ID/type; field 33 "Prepayment" is ObsoleteState = Removed on BOTH tables (correctly excluded,
    // not a rename) - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableArchCCChargesHeader().
    local procedure BootstrapArchCCChargesHeaderTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHCCCHARGESHEADER-20260522') then begin
            MigrateArchCCChargesHeaderTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHCCCHARGESHEADER-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateArchCCChargesHeaderTable()
    var
        OldRec: Record "DXArch. C. C. Charges Header";
        NewRec: Record "DXR_Arch. C. C. Charges Header";
        BatchCount: Integer;
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet(false) then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Document Date" := OldRec."Document Date";
                NewRec."Customer No." := OldRec."Customer No.";
                NewRec."Customer Name" := OldRec."Customer Name";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Vendor Name" := OldRec."Vendor Name";
                NewRec."NCF Mensual" := OldRec."NCF Mensual";
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Procesado := OldRec.Procesado;
                NewRec."No. Serie Registro" := OldRec."No. Serie Registro";
                NewRec."Banco No." := OldRec."Banco No.";
                NewRec."Nombre Banco" := OldRec."Nombre Banco";
                NewRec."Utilizar NCF Mensual" := OldRec."Utilizar NCF Mensual";
                NewRec."Commission Discount" := OldRec."Commission Discount";
                NewRec."ITBIS Retention (2%)" := OldRec."ITBIS Retention (2%)";
                NewRec."Deposito Bruto" := OldRec."Deposito Bruto";
                NewRec."Deposito Neto" := OldRec."Deposito Neto";
                NewRec."No. Preasignado" := OldRec."No. Preasignado";
                NewRec."Shortcut Dimension 1 Code" := OldRec."Shortcut Dimension 1 Code";
                NewRec."Shortcut Dimension 2 Code" := OldRec."Shortcut Dimension 2 Code";
                NewRec.Anulado := OldRec.Anulado;
                NewRec."Document Type" := OldRec."Document Type";
                NewRec."NCF Afectado" := OldRec."NCF Afectado";
                NewRec."Currency Code" := OldRec."Currency Code";
                NewRec."Currency Factor" := OldRec."Currency Factor";
                NewRec.Loan := OldRec.Loan;
                NewRec."Has Charged Commission" := OldRec."Has Charged Commission";
                NewRec."Additional Charges" := OldRec."Additional Charges";
                NewRec."Entry No." := OldRec."Entry No.";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 5/11: seq66 - Arch. C.C. Charges Lines whole-table clone (54101 -> 52260) =====
    // Ported from real source's own MigrateTable_ArchCCChargesLines(). All fields identical name/ID/type,
    // no differences - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableArchCCChargesLines().
    local procedure BootstrapArchCCChargesLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHCCCHARGESLINES-20260522') then begin
            MigrateArchCCChargesLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHCCCHARGESLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateArchCCChargesLinesTable()
    var
        OldRec: Record "DXArch. C. C. Charges Lines";
        NewRec: Record "DXR_Arch. C. C. Charges Lines";
        BatchCount: Integer;
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet(false) then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Date Entry" := OldRec."Date Entry";
                NewRec."Lote No." := OldRec."Lote No.";
                NewRec."Daily NCF" := OldRec."Daily NCF";
                NewRec."Line No." := OldRec."Line No.";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Apply Trans." := OldRec."Apply Trans.";
                NewRec."Apply to Invoice No." := OldRec."Apply to Invoice No.";
                NewRec."Amount to-Apply" := OldRec."Amount to-Apply";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 6/11: seq67 - Arch. Withhold. Gov. Lines whole-table clone (54107 -> 52117) =====
    // Ported from real source's own MigrateTable_ArchWithholdGovLines(). All fields identical
    // name/ID/type, including the 2 high-numbered extension fields 36002769/36002770 (Additional
    // Currency Code/Factor) - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused
    // verbatim from UpgradeTagInternalClosureTableArchWithholdGovLines().
    local procedure BootstrapArchWithholdGovLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHWITHHOLDGOVLINES-20260522') then begin
            MigrateArchWithholdGovLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHWITHHOLDGOVLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateArchWithholdGovLinesTable()
    var
        OldRec: Record "DXArch. Withhold. Gov. Lines";
        NewRec: Record "DXR_Arch. Withhold. Gov. Lines";
        BatchCount: Integer;
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet(false) then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Fecha Retencion" := OldRec."Fecha Retencion";
                NewRec."No. Referencia" := OldRec."No. Referencia";
                NewRec."Tipo Referencia" := OldRec."Tipo Referencia";
                NewRec."Valor Retencion" := OldRec."Valor Retencion";
                NewRec.Banco := OldRec.Banco;
                NewRec."Nombre Banco" := OldRec."Nombre Banco";
                NewRec."No. Linea" := OldRec."No. Linea";
                NewRec.Registrar := OldRec.Registrar;
                NewRec."Liq. No. Factura" := OldRec."Liq. No. Factura";
                NewRec.Periodo := OldRec.Periodo;
                NewRec."Additional Currency Code" := OldRec."Additional Currency Code";
                NewRec."Additional Currency Factor" := OldRec."Additional Currency Factor";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 7/11: seq68 - Bank Charges Header whole-table clone (54109 -> 52124) =====
    // Ported from real source's own MigrateTable_BankChargesHeader(). All fields identical name/ID/type;
    // field 12 "Total Documento" is a FlowField on both sides (excluded); field 17 does not exist on
    // either table (gap) - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim
    // from UpgradeTagInternalClosureTableBankChargesHeader().
    local procedure BootstrapBankChargesHeaderTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-BANKCHARGESHEADER-20260522') then begin
            MigrateBankChargesHeaderTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-BANKCHARGESHEADER-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateBankChargesHeaderTable()
    var
        OldRec: Record "DXBank Charges Header";
        NewRec: Record "DXR_Bank Charges Header";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Document Date" := OldRec."Document Date";
                NewRec."Tamplate Name" := OldRec."Tamplate Name";
                NewRec."Batch Name" := OldRec."Batch Name";
                NewRec."Document No." := OldRec."Document No.";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Vendor Name" := OldRec."Vendor Name";
                NewRec."Bank Acc. No." := OldRec."Bank Acc. No.";
                NewRec."Bank Name" := OldRec."Bank Name";
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Procesado := OldRec.Procesado;
                NewRec."No. Serie Registro" := OldRec."No. Serie Registro";
                NewRec."No. Orig. Cargo Banc." := OldRec."No. Orig. Cargo Banc.";
                NewRec."Currency Code" := OldRec."Currency Code";
                NewRec."Currency Factor" := OldRec."Currency Factor";
                NewRec."Cuenta Gasto" := OldRec."Cuenta Gasto";
                NewRec."Document Type" := OldRec."Document Type";
                NewRec."Dimension Global 1" := OldRec."Dimension Global 1";
                NewRec."Dimension Global 2" := OldRec."Dimension Global 2";
                NewRec."Dimension Set ID" := OldRec."Dimension Set ID";
                NewRec.NCF := OldRec.NCF;
                NewRec.Amount := OldRec.Amount;
                NewRec."Line No." := OldRec."Line No.";
                NewRec."Apply Trans." := OldRec."Apply Trans.";
                NewRec.Description := OldRec.Description;
                NewRec."NCF Afectado" := OldRec."NCF Afectado";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 8/11: seq69 - Cred. Card Charges Header whole-table clone (54113 -> 52140) =====
    // Ported from real source's own MigrateTable_CredCardChargesHeader(). All fields identical
    // name/ID/type; fields 20/21 do not exist on either table (gap); field 33 "Prepayment" is
    // ObsoleteState = Removed on BOTH tables (correctly excluded, not a rename) - see codeunit-level
    // Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableCredCardChargesHeader().
    local procedure BootstrapCredCardChargesHeaderTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CREDCARDCHARGESHEADER-20260522') then begin
            MigrateCredCardChargesHeaderTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CREDCARDCHARGESHEADER-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateCredCardChargesHeaderTable()
    var
        OldRec: Record "DXCred. Card Charges Header";
        NewRec: Record "DXR_Cred. Card Charges Header";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Document Date" := OldRec."Document Date";
                NewRec."Customer No." := OldRec."Customer No.";
                NewRec."Customer Name" := OldRec."Customer Name";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Vendor Name" := OldRec."Vendor Name";
                NewRec."NCF Mensual" := OldRec."NCF Mensual";
                NewRec."No. Series" := OldRec."No. Series";
                NewRec.Procesado := OldRec.Procesado;
                NewRec."No. Serie Registro" := OldRec."No. Serie Registro";
                NewRec."Banco No." := OldRec."Banco No.";
                NewRec."Nombre Banco" := OldRec."Nombre Banco";
                NewRec."Utilizar NCF Mensual" := OldRec."Utilizar NCF Mensual";
                NewRec."Commission Discount" := OldRec."Commission Discount";
                NewRec."ITBIS Retention (2%)" := OldRec."ITBIS Retention (2%)";
                NewRec."Deposito Bruto" := OldRec."Deposito Bruto";
                NewRec."Deposito Neto" := OldRec."Deposito Neto";
                NewRec."Shortcut Dimension 1 Code" := OldRec."Shortcut Dimension 1 Code";
                NewRec."Shortcut Dimension 2 Code" := OldRec."Shortcut Dimension 2 Code";
                NewRec."Document Type" := OldRec."Document Type";
                NewRec."NCF Afectado" := OldRec."NCF Afectado";
                NewRec."Lote No." := OldRec."Lote No.";
                NewRec."Daily NCF" := OldRec."Daily NCF";
                NewRec."Line No." := OldRec."Line No.";
                NewRec."Apply Trans." := OldRec."Apply Trans.";
                NewRec."Apply to Invoice No." := OldRec."Apply to Invoice No.";
                NewRec."Amount to-Apply" := OldRec."Amount to-Apply";
                NewRec."Apply to-Id" := OldRec."Apply to-Id";
                NewRec."Currency Code" := OldRec."Currency Code";
                NewRec."Currency Factor" := OldRec."Currency Factor";
                NewRec.Loan := OldRec.Loan;
                NewRec."Has Charged Commission" := OldRec."Has Charged Commission";
                NewRec."Additional Charges" := OldRec."Additional Charges";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 9/11: seq70 - Cred. Card Charges Lines whole-table clone (54114 -> 52142) =====
    // Ported from real source's own MigrateTable_CredCardChargesLines(). All fields identical
    // name/ID/type, including the "DX"-prefixed field names themselves ("DXDate Entry", "DXLote No.",
    // "DXDaily NCF", "DXApply to Invoice No.", "DXAmount to-Apply", "DXApply to-Id") - preserved verbatim
    // as a same-ID, same-name pair on both old and new tables (NOT a rename, the "DX" prefix is simply
    // part of the field's real caption/name on both sides); fields 5/6 do not exist on either table
    // (gap) - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableCredCardChargesLines().
    local procedure BootstrapCredCardChargesLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CREDCARDCHARGESLINES-20260522') then begin
            MigrateCredCardChargesLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CREDCARDCHARGESLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateCredCardChargesLinesTable()
    var
        OldRec: Record "DXCred. Card Charges Lines";
        NewRec: Record "DXR_Cred. Card Charges Lines";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."DXDate Entry" := OldRec."DXDate Entry";
                NewRec."DXLote No." := OldRec."DXLote No.";
                NewRec."DXDaily NCF" := OldRec."DXDaily NCF";
                NewRec."Line No." := OldRec."Line No.";
                NewRec."Vendor No." := OldRec."Vendor No.";
                NewRec."Apply Trans." := OldRec."Apply Trans.";
                NewRec."DXApply to Invoice No." := OldRec."DXApply to Invoice No.";
                NewRec."DXAmount to-Apply" := OldRec."DXAmount to-Apply";
                NewRec."DXApply to-Id" := OldRec."DXApply to-Id";
                NewRec.Prepayment := OldRec.Prepayment;
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 10/11: seq71 - Message Log Table whole-table clone (54127 -> 52173) =====
    // Ported from real source's own MigrateTable_MessageLogTable(). All 6 fields identical name/ID/type,
    // no differences - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableMessageLogTable().
    local procedure BootstrapMessageLogTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-MESSAGELOGTABLE-20260522') then begin
            MigrateMessageLogTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-MESSAGELOGTABLE-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateMessageLogTable()
    var
        OldRec: Record "DXMessage Log Table";
        NewRec: Record "DXR_Message Log Table";
        BatchCount: Integer;
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet(false) then
            repeat
                NewRec.Init();
                NewRec."Origen Doc." := OldRec."Origen Doc.";
                NewRec."No. Linea Origen" := OldRec."No. Linea Origen";
                NewRec."Tipo Documento" := OldRec."Tipo Documento";
                NewRec."No. Documento" := OldRec."No. Documento";
                NewRec.Descripcion := OldRec.Descripcion;
                NewRec."No. Linea" := OldRec."No. Linea";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRec.Next() = 0;
    end;

    // ===== Batch 3, 11/11: seq72 - Withholding Govern. Lines whole-table clone (54148 -> 52209) =====
    // Ported from real source's own MigrateTable_WithholdingGovernLines(). All 12 fields identical
    // name/ID/type, no differences - see codeunit-level Batch 3 shadow-field comment. Upgrade Tag reused
    // verbatim from UpgradeTagInternalClosureTableWithholdingGovernLines().
    local procedure BootstrapWithholdingGovernLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGGOVERNLINES-20260522') then begin
            MigrateWithholdingGovernLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGGOVERNLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, see codeunit-level Batch 3 Commit() placement note).
    local procedure MigrateWithholdingGovernLinesTable()
    var
        OldRec: Record "DXWithholding Govern. Lines";
        NewRec: Record "DXR_Withholding Govern. Lines";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Fecha Retencion" := OldRec."Fecha Retencion";
                NewRec."No. Referencia" := OldRec."No. Referencia";
                NewRec."Tipo Referencia" := OldRec."Tipo Referencia";
                NewRec."Valor Retencion" := OldRec."Valor Retencion";
                NewRec.Banco := OldRec.Banco;
                NewRec."Nombre Banco" := OldRec."Nombre Banco";
                NewRec."No. Linea" := OldRec."No. Linea";
                NewRec.Registrar := OldRec.Registrar;
                NewRec."Liq. No. Factura" := OldRec."Liq. No. Factura";
                NewRec.Periodo := OldRec.Periodo;
                NewRec."Liq. por Id" := OldRec."Liq. por Id";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;
}
