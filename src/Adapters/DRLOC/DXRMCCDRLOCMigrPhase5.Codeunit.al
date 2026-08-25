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
    //   - Batch 1 (THIS batch, registry seq45): RepairVendorWithholdingMigration (unconditional, no
    //     own registry row - see note below) + MigrateFields_DetailedCustLedgEntry.
    //   - Batch 2 (later, registry seq49): "V27 data: Recent fiscal corrections" - large, own batch.
    //   - Batch 3 (later, registry seq46/47/48/65-72): the remaining 11 whole-table-clone steps.
    // OnRun() replicates Phase 5's real OnRun SHAPE (same pattern as 60165/60167/60168's own header
    // comments describe): every ported procedure is called unconditionally, each individually gated
    // by its own real UpgradeTag check inside. Only this batch's 2 procedures are wired into OnRun()
    // for now; Batches 2 and 3 will add their own calls to this same OnRun() later.
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
        tabledata DXR_VendWithholdLedgerEntry = RIM;

    trigger OnRun()
    begin
        RepairVendorWithholdingMigration();
        BootstrapDetailedCustLedgEntryFields();
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
}
