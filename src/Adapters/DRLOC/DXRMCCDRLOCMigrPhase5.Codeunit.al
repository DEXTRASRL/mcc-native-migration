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
    //       - Sub-batch 2b (THIS batch): next 4 of 11 real sub-fixes -
    //         BackfillWithholdingPaymentAndCodes(), Fix606WithholdingByVendor(),
    //         Fix606WithholdingByVendorV2(), Fix606WithholdingByVendorV3() - see their own section
    //         below for the V1/V2/V3 progression story.
    //       - Sub-batch 2c (later, dispatched after 2b review): remaining 3 real sub-fixes
    //         (Sync606ChargeHistoryNCF + its helpers, Repair606CardChargeVLEs,
    //         Repair606BankChargeVLEs) - the last sub-batch, which also repoints registry seq49's
    //         Dispatcher Codeunit ID to this codeunit (60169).
    //   - Batch 3 (later, registry seq46/47/48/65-72): the remaining 11 whole-table-clone steps.
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
        tabledata "DXR_Vendor Withholding Setup" = R;

    trigger OnRun()
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
        BatchCount: Integer;
    begin
        if VendorLedgerEntry.FindSet(true) then
            repeat
                if (not VendorLedgerEntry."Withholding Payment_DXR" and VendorLedgerEntry."Dx Withholding Payment") or
                   ((VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ITBIS" <> '')) or
                   ((VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ISR" <> '')) or
                   ((VendorLedgerEntry."Withholding Apply Type_DXR" = VendorLedgerEntry."Withholding Apply Type_DXR"::"On Invoice") and
                    (VendorLedgerEntry."DX Withholding Apply Type" = VendorLedgerEntry."DX Withholding Apply Type"::"On Payment")) or
                   (not VendorLedgerEntry."NCF_DXR Usado_DXR" and VendorLedgerEntry."DXNCF Usado")
                then begin
                    if VendorLedgerEntry."Dx Withholding Payment" then
                        VendorLedgerEntry."Withholding Payment_DXR" := true;
                    if (VendorLedgerEntry."Cod. Retencion ITBIS_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ITBIS" <> '') then
                        VendorLedgerEntry."Cod. Retencion ITBIS_DXR" := VendorLedgerEntry."DXCod. Retencion ITBIS";
                    if (VendorLedgerEntry."Cod. Retencion ISR_DXR" = '') and (VendorLedgerEntry."DXCod. Retencion ISR" <> '') then
                        VendorLedgerEntry."Cod. Retencion ISR_DXR" := VendorLedgerEntry."DXCod. Retencion ISR";
                    if VendorLedgerEntry."DX Withholding Apply Type" = VendorLedgerEntry."DX Withholding Apply Type"::"On Payment" then
                        VendorLedgerEntry."Withholding Apply Type_DXR" := VendorLedgerEntry."Withholding Apply Type_DXR"::"On Payment";
                    if VendorLedgerEntry."DXNCF Usado" then
                        VendorLedgerEntry."NCF_DXR Usado_DXR" := true;
                    VendorLedgerEntry.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until VendorLedgerEntry.Next() = 0;
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
        BatchCount: Integer;
    begin
        if DetailedCustLedgEntry.FindSet(true) then
            repeat
                if DetailedCustLedgEntry."Status_DXR" <> DetailedCustLedgEntry."Dx Status" then begin
                    DetailedCustLedgEntry."Status_DXR" := DetailedCustLedgEntry."Dx Status";
                    DetailedCustLedgEntry.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until DetailedCustLedgEntry.Next() = 0;
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
}
