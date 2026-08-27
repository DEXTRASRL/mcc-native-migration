codeunit 60167 "DXR MCC DRLOC Migr Phase3"
{
    // Native local migration - ported (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization's own "DXR_Migr. Phase 3 Purchase" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Migr_Phase_3_Purchase.Codeunit.al), start of the DRLOC Phase 3
    // (Purchase) native-porting campaign. Batch 1 (registry seq19/21/23) covered the 3 document
    // HEADER concepts: Purchase Header, Purch. Inv. Header, Purch. Cr. Memo Hdr. field restores.
    // Registry rows are repointed from the generic forwarding adapter (60069, "DXR MCC Adapt DRLOC
    // Dispatch") to this codeunit, matching the Phase 2 (60165) precedent.
    //
    // ===== Batch 2 (FINAL for DRLOC Phase 3, 2026-08-24): document LINES + 6 whole-table clones =====
    // Covers registry seq20/22/24 (Purchase Line/Purch. Inv. Line/Purch. Cr. Memo Line field
    // restores) and seq25/26/27/28/29/30 (6 whole-table legacy clones: Archived Purchase - (606),
    // ITBIS Purchase (606), Purchase Line Settlement, Purchase WS Settlement, Vendor Withholding
    // Header, Withholding Vendor Lines). Ported from MigrateFields_PurchaseLine_Bulk()/
    // MigrateFields_PurchaseLine_FlowFields()/MigrateFields_PurchInvLine()/
    // MigrateFields_PurchCrMemoLine()/MigrateTable_ArchivedPurchase606()/
    // MigrateTable_ITBISPurchase606()/MigrateTable_PurchaseLineSettlement()/
    // MigrateTable_PurchaseWSSettlement()/MigrateTable_VendorWithholdingHeader()/
    // MigrateTable_WithholdingVendorLines() in the same real source codeunit.
    //
    // ===== Batch 2 shadow-field investigation - read before touching this file =====
    // 1) Purchase Line/Purch. Inv. Line/Purch. Cr. Memo Line raw-numeric #if __SAAS__
    //    CopyFieldIfExists(RecRef, ...) blocks: independently re-derived against the CURRENT real
    //    tableextension sources (DXR_PurchaseLineExt.TableExt.AL, DXR_PurchInvLine.TableExt.al,
    //    DXR_PurchCrMemoLineExt.tableext.al) instead of trusting the raw numbers. For Purch. Inv.
    //    Line/Purch. Cr. Memo Line, EVERY target field number (51811-51814) is a "_DXR_V1" bridge
    //    field that is ObsoleteState = Removed (real successors relocated to 51983-51986 /
    //    51951-51954 respectively - same collision-fix bug class documented in Batch 1's header raw
    //    blocks), and every source field number (54105-54108) does not exist at all on either table
    //    - confirmed via direct read of both tableextension files, both blocks are dead/redundant.
    //    For Purchase Line, the raw block's targets (51814-51817) are live (not Removed) but its
    //    source numbers (54108-54111) do not exist at all on DXR_PurchaseLineExt.TableExt.AL (that
    //    file only declares 54100-54106) - also dead/redundant. All three raw blocks are excluded;
    //    every legitimate target in all three is already covered by the adjacent named-field
    //    reconciliation block (already SourceRecord.FieldNo()-typed in real source), ported below
    //    verbatim/typed. Cross-confirmed against DR-Localization's own parallel, always-clean
    //    "DXR_Internal Closure Migration".MigrateFields_PurchaseLine_Bulk/PurchInvLine/
    //    PurchCrMemoLine (DataTransfer.AddFieldValue with compile-time-checked named fields) - each
    //    lists exactly the same field set ported below, confirming no hidden 3rd-generation fix was
    //    missed.
    // 2) MigrateFields_PurchaseLine_FlowFields()'s documented no-op claim ("both fields FlowFields")
    //    verified directly: "DXTipo Compra" (54100) and "Tipo Compra_DXR" (51811) are both
    //    FieldClass = FlowField on DXR_PurchaseLineExt.TableExt.AL with an identical CalcFormula
    //    shape against Purchase Type Relation - confirmed genuine, not a place where data is silently
    //    dropped (the parallel "DXR_Internal Closure Migration" implementation technically assigns
    //    the value in memory and calls Modify(), but since both fields are FlowFields with no
    //    physical column, Modify() persists nothing for that field either - functionally an
    //    equivalent no-op, just written less transparently there).
    // 3) The 6 whole-table clones (seq25-30): field lists independently re-derived from the real
    //    old (src\Tables.old\*.Table.al) and new (src\Base\Tables\*.Table.al) table definitions, then
    //    cross-confirmed against DR-Localization's own parallel "DXR_Internal Closure
    //    Migration".MigrateTable_*() DataTransfer.AddFieldValue field lists - exact match on field
    //    count and pairing for all 6 tables. CRITICAL FINDING for "ITBIS Purchase (606)": despite
    //    both tables sharing the SAME field IDs (TransferFields matches by ID, so the real
    //    TransferFields(OldRec, true) call in source works correctly), 4 of the 40 fields are
    //    RENAMED between old and new at the same ID - "DXNCF"(7)->"NCF_DXR", "DXEstatus
    //    Proveedor"(18)->"Estatus_DXR Proveedor", "DXRazon Social"(22)->"Razon Social_DXR",
    //    "DXISR withholding Type"(35)->"DXR_ISR withholding Type", "DXPayment Methods
    //    606-607"(40)->"DXR_Payment Methods 606-607". A naive "assume the same field name exists on
    //    both sides" expansion would have silently mismatched these 5 fields; ported below using
    //    each side's own correct field name per pair. Field 13 ("DXMensajes"/"DXMensajes") is a
    //    FlowField on BOTH sides (confirmed via direct read) and is correctly excluded from the
    //    expansion, matching TransferFields' own behavior (FlowFields have no physical column to
    //    transfer) and matching the real DataTransfer.AddFieldValue list, which also omits it. The
    //    other 5 whole-table clones (Archived Purchase - (606), Purchase Line Settlement, Purchase
    //    WS Settlement, Vendor Withholding Header, Withholding Vendor Lines) have IDENTICAL field
    //    names on both old and new sides for every field - no renames, no FlowFields - confirmed via
    //    direct read of all field blocks in both old and new table files.
    //
    // Commit() placement (Batch 2): Purch. Inv. Line and Purch. Cr. Memo Line are permanent,
    // ever-growing posted-document-history tables (live BC platform tables that keep accumulating
    // new posted documents indefinitely into the future) - periodic Commit() every 100 rows, same
    // treatment as their sibling headers in Batch 1. Purchase Line is a working/staging table (only
    // currently-open, not-yet-posted documents) - no periodic Commit(), matching Purchase Header's
    // Batch 1 precedent. The 6 whole-table clones (seq25-30) are one-time backfills of a FROZEN
    // legacy dataset: their old-table source is ObsoleteState = Pending and being fully decommissioned
    // in favor of the DXR_-prefixed table, so unlike the live platform Purchase document tables, the
    // old table's row count does not keep growing after this migration's cutover - it is a bounded
    // snapshot, not an ever-growing history table - no periodic Commit() for any of the 6.
    //
    // ===== MANDATORY shadow-field investigation (2026-08-24) - read before touching this file =====
    // The real source has a DOCUMENTED, CONFIRMED history of the exact silent-data-loss bug class
    // this task guards against: the raw-numeric #if __SAAS__ CopyFieldIfExists(RecRef, ...) blocks in
    // MigrateFields_PurchInvHeader_Bulk()/MigrateFields_PurchCrMemoHdr_Bulk() previously pointed every
    // TARGET number at a "_V1" bridge field now ObsoleteState = Removed (silently copying zero data
    // every run until a 2026-08-22 fix retargeted them), and MigrateFields_PurchaseHeader() had a
    // smaller 2-field version of the same bug. Independently re-verifying every field pair against the
    // CURRENT real tableextension sources (DXR_PurchaseHeaderExt.TableExt.AL,
    // DXR_PurchInvHeaderExt.TableExt.AL, DXR_PurchCrMemoHdrExt.TableExt.al) instead of trusting the
    // "2026-08-22 fix" comments at face value surfaced a THIRD generation of the same bug class, on
    // the SOURCE side this time:
    //
    //   1) MigrateFields_PurchaseHeader()'s raw-numeric block: its first 5 pairs (54131->51924
    //      "Details_DXR", 54133->51925 "NCF Expiration Date_DXR", 54134->51927 "Is Debit Note_DXR",
    //      54135->51928 "Excl Ctrl Legal Tip_DXR", 54136->51929 "Apply Withholding_DXR") reference
    //      SOURCE fields ("DX Details"/"DX NCF Expiration Date"/"DX Is Debit Note"/"DXExclude
    //      Control Legal Tip"/"DX Apply Withholding") that are THEMSELVES ObsoleteState = Removed on
    //      the current DXR_PurchaseHeaderExt.TableExt.AL (confirmed by direct read of each field's
    //      own attribute block). DISAMBIGUATION (2026-08-24, review correction confirmed and
    //      re-verified): it is the SOURCE "DX ..." field name that is Removed on each pair - the
    //      TARGET "_DXR" field ("Details_DXR"/"NCF Expiration Date_DXR"/"Is Debit Note_DXR"/
    //      "Excl Ctrl Legal Tip_DXR"/"Apply Withholding_DXR", no "DX" prefix) is perfectly live with
    //      no ObsoleteState at all - only a DIFFERENTLY-NAMED "_V1" intermediate one block above each
    //      target (e.g. "Apply Withholding_DXR_V1") is Removed on that side. Do not confuse the two:
    //      this port fails on the READ side (SourceRecord."DX Details" etc.), not the write side.
    //      Empirically re-verified by actually compiling a typed reference to all 5 source fields with
    //      alc.exe: every one throws "error AL0433: Field 'DX ...' is removed", quoting the exact same
    //      ObsoleteReason text cited above - a real compiler-enforced block, not a misreading of the
    //      property text. AL refuses a typed reference to a Removed field, whether read or write -
    //      there is no typed way to read these 5 values. DR-Localization's own two independent
    //      implementations of this migration (this codeunit AND the parallel "DXR_Internal Closure
    //      Migration"."MigratePurchaseHeaderHistoricalFieldsIfExists") both explicitly document
    //      switching to RecordRef/FieldRef specifically because typed access refuses a Removed field.
    //      Given this MCC project's zero-RecordRef/FieldRef/TransferFields constraint is a hard,
    //      plan-wide requirement, these 5 fields are NOT portable here and are deliberately EXCLUDED -
    //      a genuine, confirmed functional gap versus real DR-Localization behavior for these 5
    //      fields only (flagged, not silently dropped).
    //
    //   2) The rest of that block (54137-54169, ~31 pairs) references SOURCE field numbers that do
    //      not exist AT ALL on the current table (never declared, confirmed via exhaustive grep of
    //      every field(541xx; ...) in DXR_PurchaseHeaderExt.TableExt.AL). Every TARGET these pairs
    //      claim to reach is already populated by the adjacent named-field block (~26
    //      SourceRecord.FieldNo() calls, ported below verbatim/typed) - dead/redundant code in real
    //      source, not a hidden gap. One target, "NCF_DXR Afectado_DXR" (51903), looked at first like
    //      it needed re-deriving from "DXNCF Afectado" (54106, still Pending/readable) instead of the
    //      dead 54143 reference - but cross-checking DR-Localization's own "DXR_Migr_Phase_6_History"
    //      codeunit confirmed that field is migrated there instead (line ~210) - out of scope for
    //      Phase 3, correctly excluded here.
    //   3) The identical pattern repeats for MigrateFields_PurchInvHeader_Bulk() (23 pairs) and
    //      MigrateFields_PurchCrMemoHdr_Bulk() (18 pairs): every referenced source number either does
    //      not exist, or (54137-54143, which DO exist) belongs to an unrelated field family (NCF
    //      Reconciliation Status/Blocked/DateTime, Alternate NCF/No. Series, Has NCF Contingency -
    //      confirmed via direct read; using these as sources for the Retencion/Categoria/Monto-
    //      Selectivo targets the raw block claims would be a type mismatch or semantic corruption).
    //      Every legitimate target is already covered by the adjacent named-field reconciliation
    //      block (ported below). Independently CROSS-CONFIRMED against DR-Localization's own
    //      parallel, always-clean, all-named "DXR_Internal Closure
    //      Migration"."MigrateFields_PurchInvHeader_Bulk"/"MigrateFields_PurchCrMemoHdr_Bulk"
    //      (DataTransfer.AddFieldValue with compile-time-checked named fields, incapable of this bug
    //      class) - it lists EXACTLY the same field set as the named blocks below, no "NCF_DXR
    //      Afectado_DXR", no extra fields. This rules out a hidden-but-real 3rd-generation fix for
    //      these two raw blocks - they are confirmed dead/redundant, not ported (RecordRef banned
    //      plan-wide, and nothing legitimate remains once excluded field-by-field).
    //
    // Net effect: seq19/21/23 below port exactly the named-field reconciliation logic (26/24/18
    // fields) already typed and dirty-checked in real source - the only gap (Purchase Header's 5
    // Removed-source fields) is a hard AL compile constraint, not an oversight.
    //
    // MapPostedInvStatus() enum conversion (seq21 SpecialConversions): source Enum "Posted Inv.
    // Status" (standard BC platform enum) and target Enum "DXR_Posted Inv. Status" (52187, defined in
    // DXR_PostedInvStatus.enum.al: 0=" ",1=Invoiced,2="Internal Correction",3="Credit Memo") verified
    // directly against the real enum definition - ported verbatim.
    //
    // Upgrade Tag reuse: every procedure below is gated by DR-Localization's OWN real per-procedure
    // completion tag, copied as literals from DXR_UpgradeTagMgt.Codeunit.al - the "DXR_Internal
    // Closure Migration"-family tags (UpgradeTagInternalClosureFieldsPurchaseHeader/
    // PurchInvHeaderBulk/PurchInvHeaderFlowFields/PurchInvHeaderSpecialConversions/
    // PurchCrMemoHdrBulk/PurchCrMemoHdrFlowFields), confirmed via source read to be consumed by that
    // sibling codeunit's own RunMigrateFields_*() wrappers - same "reuse the granular tag from the
    // mechanism that already ran these exact fields" rationale already established by the Phase 2
    // codeunit (60165).
    //
    // Commit() placement: Purch. Inv. Header and Purch. Cr. Memo Hdr. are permanent, ever-growing
    // posted-document history tables (transaction-volume-scale, unbounded) - periodic Commit() every
    // 100 rows added to both Bulk procedures and to SpecialConversions. Purchase Header is
    // deliberately NOT given a periodic Commit(): it holds only currently-open (not-yet-posted)
    // documents, removed from this table once posted - a working/staging table, not an ever-growing
    // history table, the same reasoning already applied to Gen. Journal Line in the Phase 2 codeunit
    // (60165, Batch 4).
    Permissions =
        tabledata "Purchase Header" = RM,
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Cr. Memo Hdr." = RM,
        tabledata "Purchase Line" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "DXArchived Purchase - (606)" = R,
        tabledata "DXR_Archived Purchase - (606)" = RIM,
        tabledata "DXITBIS Purchase (606)" = R,
        tabledata "DXR_ITBIS Purchase (606)" = RIM,
        tabledata "DXPurchase Line Settlement" = R,
        tabledata "DXR_Purchase Line Settlement" = RIM,
        tabledata "DXPurchase WS Settlement" = R,
        tabledata "DXR_Purchase WS Settlement" = RIM,
        tabledata "DXVendor Withholding Header" = R,
        tabledata "DXR_Vendor Withholding Header" = RIM,
        tabledata "DXWithholding Vendor Lines" = R,
        tabledata "DXR_Withholding Vendor Lines" = RIM;

    trigger OnRun()
    var
        UpgradeTagMgt: Codeunit "Upgrade Tag";
        PhaseTags: Codeunit "DXR_Internal Migr. Phase Tags";
    begin
        // 2026-08-25 fix: added the outer completion gate real DR-Localization's own
        // "DXR_Migr. Phase 3 Purchase" OnRun() uses (Phase3CompletedTag(), reused verbatim) - this
        // codeunit previously had none, meaning it fully re-scanned all 12 steps on every single
        // invocation forever (MCC's own executor can't mark these 0/0 "Not Row-Based" concepts
        // Completed either). Same root-cause/fix as codeunit 60165 - see that codeunit's OnRun()
        // comment for the full explanation of the reported production hang this addresses.
        if UpgradeTagMgt.HasUpgradeTag(PhaseTags.Phase3CompletedTag()) then
            exit;

        BootstrapPurchaseHeaderFields();
        BootstrapPurchInvHeaderFields();
        BootstrapPurchCrMemoHdrFields();
        BootstrapPurchaseLineFields();
        BootstrapPurchInvLineFields();
        BootstrapPurchCrMemoLineFields();
        BootstrapArchivedPurchase606Table();
        BootstrapITBISPurchase606Table();
        BootstrapPurchaseLineSettlementTable();
        BootstrapPurchaseWSSettlementTable();
        BootstrapVendorWithholdingHeaderTable();
        BootstrapWithholdingVendorLinesTable();

        UpgradeTagMgt.SetUpgradeTag(PhaseTags.Phase3CompletedTag());
    end;

    procedure RunMaster()
    begin
    end;

    procedure RunAccounting()
    begin
        BootstrapPurchaseHeaderFields();
        BootstrapPurchInvHeaderFields();
        BootstrapPurchCrMemoHdrFields();
        BootstrapPurchaseLineFields();
        BootstrapPurchInvLineFields();
        BootstrapPurchCrMemoLineFields();
        BootstrapITBISPurchase606Table();
        BootstrapPurchaseLineSettlementTable();
        BootstrapPurchaseWSSettlementTable();
        BootstrapVendorWithholdingHeaderTable();
        BootstrapWithholdingVendorLinesTable();
    end;

    procedure RunHistoric()
    begin
        BootstrapArchivedPurchase606Table();
    end;

    // ===== seq19: Purchase Header field restore (bulk) =====
    // Ported from MigrateFields_PurchaseHeader() (~line 412). Only the 26 named-field pairs (already
    // SourceRecord.FieldNo()-typed in real source) are portable - see the codeunit-level shadow-field
    // investigation comment above for why the raw-numeric block's 5 legitimately-new pairs are
    // excluded (their real source fields are ObsoleteState = Removed) and why the rest of that block
    // is dead/redundant.
    local procedure BootstrapPurchaseHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASEHEADER-20260522') then begin
            MigratePurchaseHeaderFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASEHEADER-20260522');
        end;
    end;

    // No periodic Commit() - Purchase Header holds only currently-open documents, not an ever-
    // growing history table (see codeunit-level Commit() placement comment).
    local procedure MigratePurchaseHeaderFields()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderToUpdate: Record "Purchase Header";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 + A4 - the unfiltered FindSet(true) took a SQL UPDLOCK on every open
        // purchase document for the whole run (Learn, "Record.FindSet") and, with no SetLoadFields,
        // joined every Purchase Header tableextension companion table per row. Now: partial unlocked
        // scan, Get()/lock only on rows that really change, and a Commit every 500 MODIFIED rows so the
        // scan is no longer one unbounded transaction (it previously never committed at all).
        PurchaseHeader.SetLoadFields(
            "Document Type", "No.",
            "NCF Interno Proveedor_DXR", "DXNCF Interno Proveedor",
            "No. Series NCF Fact._DXR", "DXNo. Series NCF Fact.",
            "No. Series NCF Ab._DXR", "DXNo. Series NCF Ab.",
            "Utiliza Retencion_DXR", "DXUtiliza Retencion", NCF_DXR, DXNCF,
            "Utiliza NCF Externo_DXR", "DXUtiliza NCF Externo",
            "Descripcion NCF_DXR", "DXDescripcion NCF",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            "Cod. Categoria NCF_DXR", "DXCod. Categoria NCF",
            "Multiples Cat. NCF_DXR", "DXMultiples Cat. NCF",
            "Correccion Int._DXR", "DXCorreccion Int.",
            "Note Description_DXR", "DX Note Description",
            "Num. Importacion_DXR", "DXNum. Importacion",
            "Monto Selectivo_DXR", "DXMonto Selectivo",
            "Propina Legal_DXR", "DXPropina Legal",
            "Tipo NCF_DXR", "DXTipo NCF", "Tipo Retencion_DXR", "DXTipo Retencion",
            "Otros Impuestos y Tasas_DXR", "DXOtros Impuestos y Tasas",
            "Razon Social_DXR", "DXRazon Social",
            ImporteRetenidoITBIS_DXR, DXImporteRetenidoITBIS,
            ImporteRetenidoISR_DXR, DXImporteRetenidoISR,
            "Vendor Name_DXR", "DXVendor Name",
            "Tipo Servicio Adquirido_DXR", "DXTipo Servicio Adquirido",
            "Det Servicio Adquir_DXR", "DXDetalle Servicio Adquirido",
            "Parte Relacionada_DXR", "DXParte Relacionada");
        if PurchaseHeader.FindSet(false) then
            repeat
                if (PurchaseHeader."NCF Interno Proveedor_DXR" <> PurchaseHeader."DXNCF Interno Proveedor") or
                   (PurchaseHeader."No. Series NCF Fact._DXR" <> PurchaseHeader."DXNo. Series NCF Fact.") or
                   (PurchaseHeader."No. Series NCF Ab._DXR" <> PurchaseHeader."DXNo. Series NCF Ab.") or
                   (PurchaseHeader."Utiliza Retencion_DXR" <> PurchaseHeader."DXUtiliza Retencion") or
                   (PurchaseHeader.NCF_DXR <> PurchaseHeader.DXNCF) or
                   (PurchaseHeader."Utiliza NCF Externo_DXR" <> PurchaseHeader."DXUtiliza NCF Externo") or
                   (PurchaseHeader."Descripcion NCF_DXR" <> PurchaseHeader."DXDescripcion NCF") or
                   (PurchaseHeader."Cod. Retencion ITBIS_DXR" <> PurchaseHeader."DXCod. Retencion ITBIS") or
                   (PurchaseHeader."Cod. Retencion ISR_DXR" <> PurchaseHeader."DXCod. Retencion ISR") or
                   (PurchaseHeader."Cod. Categoria NCF_DXR" <> PurchaseHeader."DXCod. Categoria NCF") or
                   (PurchaseHeader."Multiples Cat. NCF_DXR" <> PurchaseHeader."DXMultiples Cat. NCF") or
                   (PurchaseHeader."Correccion Int._DXR" <> PurchaseHeader."DXCorreccion Int.") or
                   (PurchaseHeader."Note Description_DXR" <> PurchaseHeader."DX Note Description") or
                   (PurchaseHeader."Num. Importacion_DXR" <> PurchaseHeader."DXNum. Importacion") or
                   (PurchaseHeader."Monto Selectivo_DXR" <> PurchaseHeader."DXMonto Selectivo") or
                   (PurchaseHeader."Propina Legal_DXR" <> PurchaseHeader."DXPropina Legal") or
                   (PurchaseHeader."Tipo NCF_DXR" <> PurchaseHeader."DXTipo NCF") or
                   (PurchaseHeader."Tipo Retencion_DXR" <> PurchaseHeader."DXTipo Retencion") or
                   (PurchaseHeader."Otros Impuestos y Tasas_DXR" <> PurchaseHeader."DXOtros Impuestos y Tasas") or
                   (PurchaseHeader."Razon Social_DXR" <> PurchaseHeader."DXRazon Social") or
                   (PurchaseHeader.ImporteRetenidoITBIS_DXR <> PurchaseHeader.DXImporteRetenidoITBIS) or
                   (PurchaseHeader.ImporteRetenidoISR_DXR <> PurchaseHeader.DXImporteRetenidoISR) or
                   (PurchaseHeader."Vendor Name_DXR" <> PurchaseHeader."DXVendor Name") or
                   (PurchaseHeader."Tipo Servicio Adquirido_DXR" <> PurchaseHeader."DXTipo Servicio Adquirido") or
                   (PurchaseHeader."Det Servicio Adquir_DXR" <> PurchaseHeader."DXDetalle Servicio Adquirido") or
                   (PurchaseHeader."Parte Relacionada_DXR" <> PurchaseHeader."DXParte Relacionada")
                then
                    if PurchaseHeaderToUpdate.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
                        PurchaseHeaderToUpdate."NCF Interno Proveedor_DXR" := PurchaseHeaderToUpdate."DXNCF Interno Proveedor";
                        PurchaseHeaderToUpdate."No. Series NCF Fact._DXR" := PurchaseHeaderToUpdate."DXNo. Series NCF Fact.";
                        PurchaseHeaderToUpdate."No. Series NCF Ab._DXR" := PurchaseHeaderToUpdate."DXNo. Series NCF Ab.";
                        PurchaseHeaderToUpdate."Utiliza Retencion_DXR" := PurchaseHeaderToUpdate."DXUtiliza Retencion";
                        PurchaseHeaderToUpdate.NCF_DXR := PurchaseHeaderToUpdate.DXNCF;
                        PurchaseHeaderToUpdate."Utiliza NCF Externo_DXR" := PurchaseHeaderToUpdate."DXUtiliza NCF Externo";
                        PurchaseHeaderToUpdate."Descripcion NCF_DXR" := PurchaseHeaderToUpdate."DXDescripcion NCF";
                        PurchaseHeaderToUpdate."Cod. Retencion ITBIS_DXR" := PurchaseHeaderToUpdate."DXCod. Retencion ITBIS";
                        PurchaseHeaderToUpdate."Cod. Retencion ISR_DXR" := PurchaseHeaderToUpdate."DXCod. Retencion ISR";
                        PurchaseHeaderToUpdate."Cod. Categoria NCF_DXR" := PurchaseHeaderToUpdate."DXCod. Categoria NCF";
                        PurchaseHeaderToUpdate."Multiples Cat. NCF_DXR" := PurchaseHeaderToUpdate."DXMultiples Cat. NCF";
                        PurchaseHeaderToUpdate."Correccion Int._DXR" := PurchaseHeaderToUpdate."DXCorreccion Int.";
                        PurchaseHeaderToUpdate."Note Description_DXR" := PurchaseHeaderToUpdate."DX Note Description";
                        PurchaseHeaderToUpdate."Num. Importacion_DXR" := PurchaseHeaderToUpdate."DXNum. Importacion";
                        PurchaseHeaderToUpdate."Monto Selectivo_DXR" := PurchaseHeaderToUpdate."DXMonto Selectivo";
                        PurchaseHeaderToUpdate."Propina Legal_DXR" := PurchaseHeaderToUpdate."DXPropina Legal";
                        PurchaseHeaderToUpdate."Tipo NCF_DXR" := PurchaseHeaderToUpdate."DXTipo NCF";
                        PurchaseHeaderToUpdate."Tipo Retencion_DXR" := PurchaseHeaderToUpdate."DXTipo Retencion";
                        PurchaseHeaderToUpdate."Otros Impuestos y Tasas_DXR" := PurchaseHeaderToUpdate."DXOtros Impuestos y Tasas";
                        PurchaseHeaderToUpdate."Razon Social_DXR" := PurchaseHeaderToUpdate."DXRazon Social";
                        PurchaseHeaderToUpdate.ImporteRetenidoITBIS_DXR := PurchaseHeaderToUpdate.DXImporteRetenidoITBIS;
                        PurchaseHeaderToUpdate.ImporteRetenidoISR_DXR := PurchaseHeaderToUpdate.DXImporteRetenidoISR;
                        PurchaseHeaderToUpdate."Vendor Name_DXR" := PurchaseHeaderToUpdate."DXVendor Name";
                        PurchaseHeaderToUpdate."Tipo Servicio Adquirido_DXR" := PurchaseHeaderToUpdate."DXTipo Servicio Adquirido";
                        PurchaseHeaderToUpdate."Det Servicio Adquir_DXR" := PurchaseHeaderToUpdate."DXDetalle Servicio Adquirido";
                        PurchaseHeaderToUpdate."Parte Relacionada_DXR" := PurchaseHeaderToUpdate."DXParte Relacionada";
                        PurchaseHeaderToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 500 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchaseHeader.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // ===== seq21: Purch. Inv. Header field restore (bulk + FlowFields + special conversions) =====
    // Ported from MigrateFields_PurchInvHeader_Bulk() (~line 586, named reconciliation block only -
    // see codeunit-level comment for why the raw-numeric block is excluded),
    // MigrateFields_PurchInvHeader_FlowFields() (~line 714) and
    // MigrateFields_PurchInvHeader_SpecialConversions() (~line 718).
    local procedure BootstrapPurchInvHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-BULK-20260522') then begin
            MigratePurchInvHeaderBulkFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-FLOWFIELDS-20260522') then begin
            MigratePurchInvHeaderFlowFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-FLOWFIELDS-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-SPECIALCONVERSIONS-20260522') then begin
            MigratePurchInvHeaderSpecialConversions();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVHEADER-SPECIALCONVERSIONS-20260522');
        end;
    end;

    // Purch. Inv. Header is a permanent, ever-growing posted-document history table (transaction-
    // volume-scale, unbounded) - periodic Commit() every 100 rows.
    local procedure MigratePurchInvHeaderBulkFields()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderToUpdate: Record "Purch. Inv. Header";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole ever-growing posted-
        // document table for the run and, with no SetLoadFields, joined every tableextension companion
        // table per row. Partial unlocked scan + Get()/lock only on changed rows + Commit per MODIFIED row.
        PurchInvHeader.SetLoadFields(
            "No.",
            "Tipo NCF Provedor_DXR", "DXTipo NCF Provedor",
            "No. Series NCF Fact._DXR", "DXNo. Series NCF Fact.",
            "No. Series NCF Ab._DXR", "DXNo. Series NCF Ab.",
            "Utiliza Retencion_DXR", "DXUtiliza Retencion", NCF_DXR, DXNCF,
            "Utiliza NCF Externo_DXR", "DXUtiliza NCF Externo",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            "Cod. Categoria NCF_DXR", "DXCod. Categoria NCF",
            "Multiples Cat. NCF_DXR", "DXMultiples Cat. NCF",
            "Correccion Int._DXR", "DXCorreccion Int.",
            "Note Description_DXR", "DX Note Description",
            "Monto Selectivo_DXR", "DXMonto Selectivo",
            "Propina Legal_DXR", "DXPropina Legal",
            "Tipo NCF_DXR", "DXTipo NCF", "Tipo Retencion_DXR", "DXTipo Retencion",
            "Otros Impuestos y Tasas_DXR", "DXOtros Impuestos y Tasas",
            "Tipo Compra_DXR", "DXTipo Compra",
            "Fecha Expiracion NCF_DXR", "DXFecha Expiracion NCF",
            "Vendor Name_DXR", "DX Vendor Name",
            "Tipo Servicio Adquirido_DXR", "DXTipo Servicio Adquirido",
            "Det Servicio Adquir_DXR", "DXDetalle Servicio Adquirido",
            "Parte Relacionada_DXR", "DXParte Relacionada",
            "Inv. Status_DXR", "DX Inv. Status");
        if PurchInvHeader.FindSet(false) then
            repeat
                if (PurchInvHeader."Tipo NCF Provedor_DXR" <> PurchInvHeader."DXTipo NCF Provedor") or
                   (PurchInvHeader."No. Series NCF Fact._DXR" <> PurchInvHeader."DXNo. Series NCF Fact.") or
                   (PurchInvHeader."No. Series NCF Ab._DXR" <> PurchInvHeader."DXNo. Series NCF Ab.") or
                   (PurchInvHeader."Utiliza Retencion_DXR" <> PurchInvHeader."DXUtiliza Retencion") or
                   (PurchInvHeader.NCF_DXR <> PurchInvHeader.DXNCF) or
                   (PurchInvHeader."Utiliza NCF Externo_DXR" <> PurchInvHeader."DXUtiliza NCF Externo") or
                   (PurchInvHeader."Cod. Retencion ITBIS_DXR" <> PurchInvHeader."DXCod. Retencion ITBIS") or
                   (PurchInvHeader."Cod. Retencion ISR_DXR" <> PurchInvHeader."DXCod. Retencion ISR") or
                   (PurchInvHeader."Cod. Categoria NCF_DXR" <> PurchInvHeader."DXCod. Categoria NCF") or
                   (PurchInvHeader."Multiples Cat. NCF_DXR" <> PurchInvHeader."DXMultiples Cat. NCF") or
                   (PurchInvHeader."Correccion Int._DXR" <> PurchInvHeader."DXCorreccion Int.") or
                   (PurchInvHeader."Note Description_DXR" <> PurchInvHeader."DX Note Description") or
                   (PurchInvHeader."Monto Selectivo_DXR" <> PurchInvHeader."DXMonto Selectivo") or
                   (PurchInvHeader."Propina Legal_DXR" <> PurchInvHeader."DXPropina Legal") or
                   (PurchInvHeader."Tipo NCF_DXR" <> PurchInvHeader."DXTipo NCF") or
                   (PurchInvHeader."Tipo Retencion_DXR" <> PurchInvHeader."DXTipo Retencion") or
                   (PurchInvHeader."Otros Impuestos y Tasas_DXR" <> PurchInvHeader."DXOtros Impuestos y Tasas") or
                   (PurchInvHeader."Tipo Compra_DXR" <> PurchInvHeader."DXTipo Compra") or
                   (PurchInvHeader."Fecha Expiracion NCF_DXR" <> PurchInvHeader."DXFecha Expiracion NCF") or
                   (PurchInvHeader."Vendor Name_DXR" <> PurchInvHeader."DX Vendor Name") or
                   (PurchInvHeader."Tipo Servicio Adquirido_DXR" <> PurchInvHeader."DXTipo Servicio Adquirido") or
                   (PurchInvHeader."Det Servicio Adquir_DXR" <> PurchInvHeader."DXDetalle Servicio Adquirido") or
                   (PurchInvHeader."Parte Relacionada_DXR" <> PurchInvHeader."DXParte Relacionada") or
                   (PurchInvHeader."Inv. Status_DXR" <> PurchInvHeader."DX Inv. Status")
                then
                    if PurchInvHeaderToUpdate.Get(PurchInvHeader."No.") then begin
                        PurchInvHeaderToUpdate."Tipo NCF Provedor_DXR" := PurchInvHeaderToUpdate."DXTipo NCF Provedor";
                        PurchInvHeaderToUpdate."No. Series NCF Fact._DXR" := PurchInvHeaderToUpdate."DXNo. Series NCF Fact.";
                        PurchInvHeaderToUpdate."No. Series NCF Ab._DXR" := PurchInvHeaderToUpdate."DXNo. Series NCF Ab.";
                        PurchInvHeaderToUpdate."Utiliza Retencion_DXR" := PurchInvHeaderToUpdate."DXUtiliza Retencion";
                        PurchInvHeaderToUpdate.NCF_DXR := PurchInvHeaderToUpdate.DXNCF;
                        PurchInvHeaderToUpdate."Utiliza NCF Externo_DXR" := PurchInvHeaderToUpdate."DXUtiliza NCF Externo";
                        PurchInvHeaderToUpdate."Cod. Retencion ITBIS_DXR" := PurchInvHeaderToUpdate."DXCod. Retencion ITBIS";
                        PurchInvHeaderToUpdate."Cod. Retencion ISR_DXR" := PurchInvHeaderToUpdate."DXCod. Retencion ISR";
                        PurchInvHeaderToUpdate."Cod. Categoria NCF_DXR" := PurchInvHeaderToUpdate."DXCod. Categoria NCF";
                        PurchInvHeaderToUpdate."Multiples Cat. NCF_DXR" := PurchInvHeaderToUpdate."DXMultiples Cat. NCF";
                        PurchInvHeaderToUpdate."Correccion Int._DXR" := PurchInvHeaderToUpdate."DXCorreccion Int.";
                        PurchInvHeaderToUpdate."Note Description_DXR" := PurchInvHeaderToUpdate."DX Note Description";
                        PurchInvHeaderToUpdate."Monto Selectivo_DXR" := PurchInvHeaderToUpdate."DXMonto Selectivo";
                        PurchInvHeaderToUpdate."Propina Legal_DXR" := PurchInvHeaderToUpdate."DXPropina Legal";
                        PurchInvHeaderToUpdate."Tipo NCF_DXR" := PurchInvHeaderToUpdate."DXTipo NCF";
                        PurchInvHeaderToUpdate."Tipo Retencion_DXR" := PurchInvHeaderToUpdate."DXTipo Retencion";
                        PurchInvHeaderToUpdate."Otros Impuestos y Tasas_DXR" := PurchInvHeaderToUpdate."DXOtros Impuestos y Tasas";
                        PurchInvHeaderToUpdate."Tipo Compra_DXR" := PurchInvHeaderToUpdate."DXTipo Compra";
                        PurchInvHeaderToUpdate."Fecha Expiracion NCF_DXR" := PurchInvHeaderToUpdate."DXFecha Expiracion NCF";
                        PurchInvHeaderToUpdate."Vendor Name_DXR" := PurchInvHeaderToUpdate."DX Vendor Name";
                        PurchInvHeaderToUpdate."Tipo Servicio Adquirido_DXR" := PurchInvHeaderToUpdate."DXTipo Servicio Adquirido";
                        PurchInvHeaderToUpdate."Det Servicio Adquir_DXR" := PurchInvHeaderToUpdate."DXDetalle Servicio Adquirido";
                        PurchInvHeaderToUpdate."Parte Relacionada_DXR" := PurchInvHeaderToUpdate."DXParte Relacionada";
                        PurchInvHeaderToUpdate."Inv. Status_DXR" := PurchInvHeaderToUpdate."DX Inv. Status";
                        PurchInvHeaderToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchInvHeader.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // Deliberate no-op, matching real source behavior exactly: both "DX Reports 606" (54133) and
    // "Reports 606_DXR" (51982) are themselves FlowFields (confirmed against
    // DXR_PurchInvHeaderExt.TableExt.AL - both FieldClass = FlowField with an identical CalcFormula
    // shape against "DXR_Archived Purchase - (606)"), so there is nothing to persist via Modify().
    local procedure MigratePurchInvHeaderFlowFields()
    begin
        // Both fields are FlowFields. Their values are calculated and cannot be persisted.
    end;

    // Purch. Inv. Header is a permanent, ever-growing posted-document history table - periodic
    // Commit() every 100 rows.
    local procedure MigratePurchInvHeaderSpecialConversions()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvHeaderToUpdate: Record "Purch. Inv. Header";
        NewPostedInvStatus: Enum "DXR_Posted Inv. Status";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole ever-growing posted-
        // document table for the run and, with no SetLoadFields, joined every tableextension companion
        // table per row. Partial unlocked scan + Get()/lock only on changed rows + Commit per MODIFIED row.
        PurchInvHeader.SetLoadFields("No.", "Posted Inv. Status_DXR", "DX Posted Inv. Status");
        if PurchInvHeader.FindSet(false) then
            repeat
                NewPostedInvStatus := MapPostedInvStatus(PurchInvHeader."DX Posted Inv. Status");
                if PurchInvHeader."Posted Inv. Status_DXR" <> NewPostedInvStatus then
                    if PurchInvHeaderToUpdate.Get(PurchInvHeader."No.") then begin
                        PurchInvHeaderToUpdate."Posted Inv. Status_DXR" := NewPostedInvStatus;
                        PurchInvHeaderToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchInvHeader.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // Verified against Enum "Posted Inv. Status" (standard BC platform enum) and Enum
    // "DXR_Posted Inv. Status" (52187, DXR_PostedInvStatus.enum.al: 0=" ",1=Invoiced,
    // 2="Internal Correction",3="Credit Memo") - ported verbatim.
    local procedure MapPostedInvStatus(PostedInvStatus: Enum "Posted Inv. Status"): Enum "DXR_Posted Inv. Status"
    begin
        case PostedInvStatus of
            PostedInvStatus::Invoiced:
                exit(Enum::"DXR_Posted Inv. Status"::Invoiced);
            PostedInvStatus::"Internal Correction":
                exit(Enum::"DXR_Posted Inv. Status"::"Internal Correction");
            PostedInvStatus::"Credit Memo":
                exit(Enum::"DXR_Posted Inv. Status"::"Credit Memo");
            else
                exit(Enum::"DXR_Posted Inv. Status"::" ");
        end;
    end;

    // ===== seq23: Purch. Cr. Memo Hdr field restore (bulk + FlowFields) =====
    // Ported from MigrateFields_PurchCrMemoHdr_Bulk() (~line 783, named reconciliation block only -
    // see codeunit-level comment for why the raw-numeric block is excluded) and
    // MigrateFields_PurchCrMemoHdr_FlowFields() (~line 883).
    local procedure BootstrapPurchCrMemoHdrFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOHDR-BULK-20260522') then begin
            MigratePurchCrMemoHdrBulkFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOHDR-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOHDR-FLOWFIELDS-20260522') then begin
            MigratePurchCrMemoHdrFlowFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOHDR-FLOWFIELDS-20260522');
        end;
    end;

    // Purch. Cr. Memo Hdr. is a permanent, ever-growing posted-document history table (transaction-
    // volume-scale, unbounded) - periodic Commit() every 100 rows.
    local procedure MigratePurchCrMemoHdrBulkFields()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoHdrToUpdate: Record "Purch. Cr. Memo Hdr.";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole ever-growing posted-
        // document table for the run and, with no SetLoadFields, joined every tableextension companion
        // table per row. Partial unlocked scan + Get()/lock only on changed rows + Commit per MODIFIED row.
        PurchCrMemoHdr.SetLoadFields(
            "No.",
            "Tipo NCF Provedor_DXR", "DXTipo NCF Provedor",
            "No. Series NCF Fact._DXR", "DXNo. Series NCF Fact.",
            "No. Series NCF Ab._DXR", "DXNo. Series NCF Ab.",
            "Utiliza Retencion_DXR", "DXUtiliza Retencion", NCF_DXR, DXNCF,
            "Utiliza NCF Externo_DXR", "DXUtiliza NCF Externo",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            "Cod. Categoria NCF_DXR", "DXCod. Categoria NCF",
            "Multiples Cat. NCF_DXR", "DXMultiples Cat. NCF",
            "Correccion Int._DXR", "DXCorreccion Int.",
            "Monto Selectivo_DXR", "DXMonto Selectivo",
            "Propina Legal_DXR", "DXPropina Legal",
            "Tipo NCF_DXR", "DXTipo NCF", "Tipo Retencion_DXR", "DXTipo Retencion",
            "Otros Impuestos y Tasas_DXR", "DXOtros Impuestos y Tasas",
            "Tipo Compra_DXR", "DXTipo Compra",
            "Fecha Expiracion NCF_DXR", "DXFecha Expiracion NCF");
        if PurchCrMemoHdr.FindSet(false) then
            repeat
                if (PurchCrMemoHdr."Tipo NCF Provedor_DXR" <> PurchCrMemoHdr."DXTipo NCF Provedor") or
                   (PurchCrMemoHdr."No. Series NCF Fact._DXR" <> PurchCrMemoHdr."DXNo. Series NCF Fact.") or
                   (PurchCrMemoHdr."No. Series NCF Ab._DXR" <> PurchCrMemoHdr."DXNo. Series NCF Ab.") or
                   (PurchCrMemoHdr."Utiliza Retencion_DXR" <> PurchCrMemoHdr."DXUtiliza Retencion") or
                   (PurchCrMemoHdr.NCF_DXR <> PurchCrMemoHdr.DXNCF) or
                   (PurchCrMemoHdr."Utiliza NCF Externo_DXR" <> PurchCrMemoHdr."DXUtiliza NCF Externo") or
                   (PurchCrMemoHdr."Cod. Retencion ITBIS_DXR" <> PurchCrMemoHdr."DXCod. Retencion ITBIS") or
                   (PurchCrMemoHdr."Cod. Retencion ISR_DXR" <> PurchCrMemoHdr."DXCod. Retencion ISR") or
                   (PurchCrMemoHdr."Cod. Categoria NCF_DXR" <> PurchCrMemoHdr."DXCod. Categoria NCF") or
                   (PurchCrMemoHdr."Multiples Cat. NCF_DXR" <> PurchCrMemoHdr."DXMultiples Cat. NCF") or
                   (PurchCrMemoHdr."Correccion Int._DXR" <> PurchCrMemoHdr."DXCorreccion Int.") or
                   (PurchCrMemoHdr."Monto Selectivo_DXR" <> PurchCrMemoHdr."DXMonto Selectivo") or
                   (PurchCrMemoHdr."Propina Legal_DXR" <> PurchCrMemoHdr."DXPropina Legal") or
                   (PurchCrMemoHdr."Tipo NCF_DXR" <> PurchCrMemoHdr."DXTipo NCF") or
                   (PurchCrMemoHdr."Tipo Retencion_DXR" <> PurchCrMemoHdr."DXTipo Retencion") or
                   (PurchCrMemoHdr."Otros Impuestos y Tasas_DXR" <> PurchCrMemoHdr."DXOtros Impuestos y Tasas") or
                   (PurchCrMemoHdr."Tipo Compra_DXR" <> PurchCrMemoHdr."DXTipo Compra") or
                   (PurchCrMemoHdr."Fecha Expiracion NCF_DXR" <> PurchCrMemoHdr."DXFecha Expiracion NCF")
                then
                    if PurchCrMemoHdrToUpdate.Get(PurchCrMemoHdr."No.") then begin
                        PurchCrMemoHdrToUpdate."Tipo NCF Provedor_DXR" := PurchCrMemoHdrToUpdate."DXTipo NCF Provedor";
                        PurchCrMemoHdrToUpdate."No. Series NCF Fact._DXR" := PurchCrMemoHdrToUpdate."DXNo. Series NCF Fact.";
                        PurchCrMemoHdrToUpdate."No. Series NCF Ab._DXR" := PurchCrMemoHdrToUpdate."DXNo. Series NCF Ab.";
                        PurchCrMemoHdrToUpdate."Utiliza Retencion_DXR" := PurchCrMemoHdrToUpdate."DXUtiliza Retencion";
                        PurchCrMemoHdrToUpdate.NCF_DXR := PurchCrMemoHdrToUpdate.DXNCF;
                        PurchCrMemoHdrToUpdate."Utiliza NCF Externo_DXR" := PurchCrMemoHdrToUpdate."DXUtiliza NCF Externo";
                        PurchCrMemoHdrToUpdate."Cod. Retencion ITBIS_DXR" := PurchCrMemoHdrToUpdate."DXCod. Retencion ITBIS";
                        PurchCrMemoHdrToUpdate."Cod. Retencion ISR_DXR" := PurchCrMemoHdrToUpdate."DXCod. Retencion ISR";
                        PurchCrMemoHdrToUpdate."Cod. Categoria NCF_DXR" := PurchCrMemoHdrToUpdate."DXCod. Categoria NCF";
                        PurchCrMemoHdrToUpdate."Multiples Cat. NCF_DXR" := PurchCrMemoHdrToUpdate."DXMultiples Cat. NCF";
                        PurchCrMemoHdrToUpdate."Correccion Int._DXR" := PurchCrMemoHdrToUpdate."DXCorreccion Int.";
                        PurchCrMemoHdrToUpdate."Monto Selectivo_DXR" := PurchCrMemoHdrToUpdate."DXMonto Selectivo";
                        PurchCrMemoHdrToUpdate."Propina Legal_DXR" := PurchCrMemoHdrToUpdate."DXPropina Legal";
                        PurchCrMemoHdrToUpdate."Tipo NCF_DXR" := PurchCrMemoHdrToUpdate."DXTipo NCF";
                        PurchCrMemoHdrToUpdate."Tipo Retencion_DXR" := PurchCrMemoHdrToUpdate."DXTipo Retencion";
                        PurchCrMemoHdrToUpdate."Otros Impuestos y Tasas_DXR" := PurchCrMemoHdrToUpdate."DXOtros Impuestos y Tasas";
                        PurchCrMemoHdrToUpdate."Tipo Compra_DXR" := PurchCrMemoHdrToUpdate."DXTipo Compra";
                        PurchCrMemoHdrToUpdate."Fecha Expiracion NCF_DXR" := PurchCrMemoHdrToUpdate."DXFecha Expiracion NCF";
                        PurchCrMemoHdrToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchCrMemoHdr.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // Deliberate no-op, matching real source behavior exactly: both "DX Reports 606" (54133) and
    // "Reports 606_DXR" (51950) are themselves FlowFields (confirmed against
    // DXR_PurchCrMemoHdrExt.TableExt.al - both FieldClass = FlowField with an identical CalcFormula
    // shape against archived-purchase-606 tables), so there is nothing to persist via Modify().
    local procedure MigratePurchCrMemoHdrFlowFields()
    begin
        // Both fields are FlowFields. Their values are calculated and cannot be persisted.
    end;

    // ===== seq20: Purchase Line field restore (bulk + FlowFields) =====
    // Ported from MigrateFields_PurchaseLine_Bulk() (named-field block only - the raw-numeric block
    // is dead/redundant, see codeunit-level shadow-field comment) and
    // MigrateFields_PurchaseLine_FlowFields() (~line 582 in real source).
    local procedure BootstrapPurchaseLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASELINE-BULK-20260522') then begin
            MigratePurchaseLineBulkFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASELINE-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASELINE-FLOWFIELDS-20260522') then begin
            MigratePurchaseLineFlowFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHASELINE-FLOWFIELDS-20260522');
        end;
    end;

    // No periodic Commit() - Purchase Line holds only currently-open documents, not an ever-growing
    // history table (same reasoning as Purchase Header in Batch 1).
    local procedure MigratePurchaseLineBulkFields()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLineToUpdate: Record "Purchase Line";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 + A4 - the unfiltered FindSet(true) held a SQL UPDLOCK on every open
        // purchase line for the whole run and, with no SetLoadFields, joined every Purchase Line
        // tableextension companion table per row. Partial unlocked scan, Get()/lock only on rows that
        // really change, and a Commit every 500 MODIFIED rows (this loop previously never committed).
        PurchaseLine.SetLoadFields(
            "Document Type", "Document No.", "Line No.",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            ImporteRetenidoITBIS_DXR, DXImporteRetenidoITBIS,
            ImporteRetenidoISR_DXR, DXImporteRetenidoISR,
            "Services/Assets_DXR", "DX Services/Assets",
            "Cat. NCF_DXR", "DX Cat. NCF");
        if PurchaseLine.FindSet(false) then
            repeat
                if (PurchaseLine."Cod. Retencion ITBIS_DXR" <> PurchaseLine."DXCod. Retencion ITBIS") or
                   (PurchaseLine."Cod. Retencion ISR_DXR" <> PurchaseLine."DXCod. Retencion ISR") or
                   (PurchaseLine.ImporteRetenidoITBIS_DXR <> PurchaseLine.DXImporteRetenidoITBIS) or
                   (PurchaseLine.ImporteRetenidoISR_DXR <> PurchaseLine.DXImporteRetenidoISR) or
                   (PurchaseLine."Services/Assets_DXR" <> PurchaseLine."DX Services/Assets") or
                   (PurchaseLine."Cat. NCF_DXR" <> PurchaseLine."DX Cat. NCF")
                then
                    if PurchaseLineToUpdate.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then begin
                        PurchaseLineToUpdate."Cod. Retencion ITBIS_DXR" := PurchaseLineToUpdate."DXCod. Retencion ITBIS";
                        PurchaseLineToUpdate."Cod. Retencion ISR_DXR" := PurchaseLineToUpdate."DXCod. Retencion ISR";
                        PurchaseLineToUpdate.ImporteRetenidoITBIS_DXR := PurchaseLineToUpdate.DXImporteRetenidoITBIS;
                        PurchaseLineToUpdate.ImporteRetenidoISR_DXR := PurchaseLineToUpdate.DXImporteRetenidoISR;
                        PurchaseLineToUpdate."Services/Assets_DXR" := PurchaseLineToUpdate."DX Services/Assets";
                        PurchaseLineToUpdate."Cat. NCF_DXR" := PurchaseLineToUpdate."DX Cat. NCF";
                        PurchaseLineToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 500 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchaseLine.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // Deliberate no-op, matching real source behavior exactly: both "DXTipo Compra" (54100) and
    // "Tipo Compra_DXR" (51811) are themselves FlowFields (confirmed against
    // DXR_PurchaseLineExt.TableExt.AL - both FieldClass = FlowField with an identical CalcFormula
    // shape against "DXR_Purchase Type Relation"), so there is nothing to persist via Modify().
    local procedure MigratePurchaseLineFlowFields()
    begin
        // Both fields are FlowFields. Their values are calculated and cannot be persisted.
    end;

    // ===== seq22: Purch. Inv. Line field restore =====
    // Ported from MigrateFields_PurchInvLine() (named-field block only - the raw-numeric block
    // targets dead "_DXR_V1" fields, see codeunit-level shadow-field comment).
    local procedure BootstrapPurchInvLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVLINE-20260522') then begin
            MigratePurchInvLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHINVLINE-20260522');
        end;
    end;

    // Purch. Inv. Line is a permanent, ever-growing posted-document history table (transaction-
    // volume-scale, unbounded) - periodic Commit() every 100 rows, same treatment as Purch. Inv.
    // Header in Batch 1.
    local procedure MigratePurchInvLineFields()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchInvLineToUpdate: Record "Purch. Inv. Line";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole ever-growing posted-
        // document table for the run and, with no SetLoadFields, joined every tableextension companion
        // table per row. Partial unlocked scan + Get()/lock only on changed rows + Commit per MODIFIED row.
        PurchInvLine.SetLoadFields(
            "Document No.", "Line No.",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            ImporteRetenidoITBIS_DXR, DXImporteRetenidoITBIS,
            ImporteRetenidoISR_DXR, DXImporteRetenidoISR);
        if PurchInvLine.FindSet(false) then
            repeat
                if (PurchInvLine."Cod. Retencion ITBIS_DXR" <> PurchInvLine."DXCod. Retencion ITBIS") or
                   (PurchInvLine."Cod. Retencion ISR_DXR" <> PurchInvLine."DXCod. Retencion ISR") or
                   (PurchInvLine.ImporteRetenidoITBIS_DXR <> PurchInvLine.DXImporteRetenidoITBIS) or
                   (PurchInvLine.ImporteRetenidoISR_DXR <> PurchInvLine.DXImporteRetenidoISR)
                then
                    if PurchInvLineToUpdate.Get(PurchInvLine."Document No.", PurchInvLine."Line No.") then begin
                        PurchInvLineToUpdate."Cod. Retencion ITBIS_DXR" := PurchInvLineToUpdate."DXCod. Retencion ITBIS";
                        PurchInvLineToUpdate."Cod. Retencion ISR_DXR" := PurchInvLineToUpdate."DXCod. Retencion ISR";
                        PurchInvLineToUpdate.ImporteRetenidoITBIS_DXR := PurchInvLineToUpdate.DXImporteRetenidoITBIS;
                        PurchInvLineToUpdate.ImporteRetenidoISR_DXR := PurchInvLineToUpdate.DXImporteRetenidoISR;
                        PurchInvLineToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchInvLine.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // ===== seq24: Purch. Cr. Memo Line field restore =====
    // Ported from MigrateFields_PurchCrMemoLine() (named-field block only - the raw-numeric block
    // targets dead "_DXR_V1" fields, see codeunit-level shadow-field comment).
    local procedure BootstrapPurchCrMemoLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOLINE-20260522') then begin
            MigratePurchCrMemoLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-PURCHCRMEMOLINE-20260522');
        end;
    end;

    // Purch. Cr. Memo Line is a permanent, ever-growing posted-document history table (transaction-
    // volume-scale, unbounded) - periodic Commit() every 100 rows, same treatment as Purch. Cr. Memo
    // Hdr. in Batch 1.
    local procedure MigratePurchCrMemoLineFields()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        PurchCrMemoLineToUpdate: Record "Purch. Cr. Memo Line";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27: A1 - unfiltered FindSet(true) update-locked this whole ever-growing posted-
        // document table for the run and, with no SetLoadFields, joined every tableextension companion
        // table per row. Partial unlocked scan + Get()/lock only on changed rows + Commit per MODIFIED row.
        PurchCrMemoLine.SetLoadFields(
            "Document No.", "Line No.",
            "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS",
            "Cod. Retencion ISR_DXR", "DXCod. Retencion ISR",
            ImporteRetenidoITBIS_DXR, DXImporteRetenidoITBIS,
            ImporteRetenidoISR_DXR, DXImporteRetenidoISR);
        if PurchCrMemoLine.FindSet(false) then
            repeat
                if (PurchCrMemoLine."Cod. Retencion ITBIS_DXR" <> PurchCrMemoLine."DXCod. Retencion ITBIS") or
                   (PurchCrMemoLine."Cod. Retencion ISR_DXR" <> PurchCrMemoLine."DXCod. Retencion ISR") or
                   (PurchCrMemoLine.ImporteRetenidoITBIS_DXR <> PurchCrMemoLine.DXImporteRetenidoITBIS) or
                   (PurchCrMemoLine.ImporteRetenidoISR_DXR <> PurchCrMemoLine.DXImporteRetenidoISR)
                then
                    if PurchCrMemoLineToUpdate.Get(PurchCrMemoLine."Document No.", PurchCrMemoLine."Line No.") then begin
                        PurchCrMemoLineToUpdate."Cod. Retencion ITBIS_DXR" := PurchCrMemoLineToUpdate."DXCod. Retencion ITBIS";
                        PurchCrMemoLineToUpdate."Cod. Retencion ISR_DXR" := PurchCrMemoLineToUpdate."DXCod. Retencion ISR";
                        PurchCrMemoLineToUpdate.ImporteRetenidoITBIS_DXR := PurchCrMemoLineToUpdate.DXImporteRetenidoITBIS;
                        PurchCrMemoLineToUpdate.ImporteRetenidoISR_DXR := PurchCrMemoLineToUpdate.DXImporteRetenidoISR;
                        PurchCrMemoLineToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= 100 then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until PurchCrMemoLine.Next() = 0;

        if BatchCount > 0 then
            Commit();
    end;

    // ===== seq25: Archived Purchase 606 legacy table restore (54105 -> 52113) =====
    // Ported from MigrateTable_ArchivedPurchase606() - whole-table clone, TransferFields expanded to
    // explicit typed field-by-field assignment (55 fields, identical names on both old and new
    // sides - see codeunit-level shadow-field comment).
    local procedure BootstrapArchivedPurchase606Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDPURCHASE606-20260522') then begin
            MigrateArchivedPurchase606Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDPURCHASE606-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, being decommissioned - see codeunit-level Commit() placement comment).
    local procedure MigrateArchivedPurchase606Table()
    var
        DXArchivedPurchase606Old: Record "DXArchived Purchase - (606)";
        DXRArchivedPurchase606New: Record "DXR_Archived Purchase - (606)";
        BatchCount: Integer;
    begin
        if DXArchivedPurchase606Old.IsEmpty() then
            exit;

        if DXArchivedPurchase606Old.FindSet(false) then
            repeat
                DXRArchivedPurchase606New.Init();
                DXRArchivedPurchase606New."Tipo Documento" := DXArchivedPurchase606Old."Tipo Documento";
                DXRArchivedPurchase606New."No. Documento" := DXArchivedPurchase606Old."No. Documento";
                DXRArchivedPurchase606New."Tipo Identificacion" := DXArchivedPurchase606Old."Tipo Identificacion";
                DXRArchivedPurchase606New."Cod. Identificacion" := DXArchivedPurchase606Old."Cod. Identificacion";
                DXRArchivedPurchase606New."Cod. Proveedor" := DXArchivedPurchase606Old."Cod. Proveedor";
                DXRArchivedPurchase606New."Nombre Proveedor" := DXArchivedPurchase606Old."Nombre Proveedor";
                DXRArchivedPurchase606New.NCF := DXArchivedPurchase606Old.NCF;
                DXRArchivedPurchase606New."NCF Modificado" := DXArchivedPurchase606Old."NCF Modificado";
                DXRArchivedPurchase606New."Fecha Comprobante" := DXArchivedPurchase606Old."Fecha Comprobante";
                DXRArchivedPurchase606New."ITBIS Facturado" := DXArchivedPurchase606Old."ITBIS Facturado";
                DXRArchivedPurchase606New."Monto Facturado" := DXArchivedPurchase606Old."Monto Facturado";
                DXRArchivedPurchase606New."No. Linea" := DXArchivedPurchase606Old."No. Linea";
                DXRArchivedPurchase606New."Estado Reg." := DXArchivedPurchase606Old."Estado Reg.";
                DXRArchivedPurchase606New."Categoria NCF" := DXArchivedPurchase606Old."Categoria NCF";
                DXRArchivedPurchase606New."Fecha Pago" := DXArchivedPurchase606Old."Fecha Pago";
                DXRArchivedPurchase606New."ITBIS Retenido" := DXArchivedPurchase606Old."ITBIS Retenido";
                DXRArchivedPurchase606New."Estatus Proveedor" := DXArchivedPurchase606Old."Estatus Proveedor";
                DXRArchivedPurchase606New."Importe Ret. Renta" := DXArchivedPurchase606Old."Importe Ret. Renta";
                DXRArchivedPurchase606New."No. Doc. Externo" := DXArchivedPurchase606Old."No. Doc. Externo";
                DXRArchivedPurchase606New."Desc. Categoria NCF" := DXArchivedPurchase606Old."Desc. Categoria NCF";
                DXRArchivedPurchase606New."Razon Social" := DXArchivedPurchase606Old."Razon Social";
                DXRArchivedPurchase606New.AnoMes_Fcomprobante := DXArchivedPurchase606Old.AnoMes_Fcomprobante;
                DXRArchivedPurchase606New.Dia_Fcomprobante := DXArchivedPurchase606Old.Dia_Fcomprobante;
                DXRArchivedPurchase606New.AnoMes_FPago := DXArchivedPurchase606Old.AnoMes_FPago;
                DXRArchivedPurchase606New.Dia_FPago := DXArchivedPurchase606Old.Dia_FPago;
                DXRArchivedPurchase606New."Shortcut Dimension 1 Code" := DXArchivedPurchase606Old."Shortcut Dimension 1 Code";
                DXRArchivedPurchase606New."Shortcut Dimension 2 Code" := DXArchivedPurchase606Old."Shortcut Dimension 2 Code";
                DXRArchivedPurchase606New."Monto Facturado Servicios" := DXArchivedPurchase606Old."Monto Facturado Servicios";
                DXRArchivedPurchase606New."Monto Facturado Bienes" := DXArchivedPurchase606Old."Monto Facturado Bienes";
                DXRArchivedPurchase606New."ITBIS Proporcionalidad" := DXArchivedPurchase606Old."ITBIS Proporcionalidad";
                DXRArchivedPurchase606New."ITBIS llevado al costo" := DXArchivedPurchase606Old."ITBIS llevado al costo";
                DXRArchivedPurchase606New."ITBIS por adelantar" := DXArchivedPurchase606Old."ITBIS por adelantar";
                DXRArchivedPurchase606New."ITBIS Percibido" := DXArchivedPurchase606Old."ITBIS Percibido";
                DXRArchivedPurchase606New."ISR withholding Type" := DXArchivedPurchase606Old."ISR withholding Type";
                DXRArchivedPurchase606New."ISR Percibido" := DXArchivedPurchase606Old."ISR Percibido";
                DXRArchivedPurchase606New."Imp. Selectivo al Consumo" := DXArchivedPurchase606Old."Imp. Selectivo al Consumo";
                DXRArchivedPurchase606New."Otros Impuestos/Tasas" := DXArchivedPurchase606Old."Otros Impuestos/Tasas";
                DXRArchivedPurchase606New."Monto Propina Legal" := DXArchivedPurchase606Old."Monto Propina Legal";
                DXRArchivedPurchase606New."Payment Methods 606-607" := DXArchivedPurchase606Old."Payment Methods 606-607";
                DXRArchivedPurchase606New."Reporta 606" := DXArchivedPurchase606Old."Reporta 606";
                DXRArchivedPurchase606New."Monto USD" := DXArchivedPurchase606Old."Monto USD";
                DXRArchivedPurchase606New."Exchange Rate Factor" := DXArchivedPurchase606Old."Exchange Rate Factor";
                DXRArchivedPurchase606New."NCF Year/Month" := DXArchivedPurchase606Old."NCF Year/Month";
                DXRArchivedPurchase606New."NCF Day" := DXArchivedPurchase606Old."NCF Day";
                DXRArchivedPurchase606New."Posting Year/Month" := DXArchivedPurchase606Old."Posting Year/Month";
                DXRArchivedPurchase606New."Posting Day" := DXArchivedPurchase606Old."Posting Day";
                DXRArchivedPurchase606New."Additional Currency Code" := DXArchivedPurchase606Old."Additional Currency Code";
                DXRArchivedPurchase606New."Additional Currency Factor" := DXArchivedPurchase606Old."Additional Currency Factor";
                DXRArchivedPurchase606New."Document Date" := DXArchivedPurchase606Old."Document Date";
                DXRArchivedPurchase606New."Currency Code" := DXArchivedPurchase606Old."Currency Code";
                DXRArchivedPurchase606New."Currency Factor" := DXArchivedPurchase606Old."Currency Factor";
                DXRArchivedPurchase606New."DX Original Amount" := DXArchivedPurchase606Old."DX Original Amount";
                DXRArchivedPurchase606New."DX Original ITBIS Amount" := DXArchivedPurchase606Old."DX Original ITBIS Amount";
                DXRArchivedPurchase606New."Withholding Date" := DXArchivedPurchase606Old."Withholding Date";
                DXRArchivedPurchase606New."Vendor Ledger Entry No." := DXArchivedPurchase606Old."Vendor Ledger Entry No.";
                DXRArchivedPurchase606New."Importe Ret. Renta ICY" := DXArchivedPurchase606Old."Importe Ret. Renta ICY";
                DXRArchivedPurchase606New."Monto Facturado Servicios ICY" := DXArchivedPurchase606Old."Monto Facturado Servicios ICY";
                DXRArchivedPurchase606New."Monto Facturado Bienes ICY" := DXArchivedPurchase606Old."Monto Facturado Bienes ICY";
                DXRArchivedPurchase606New."ITBIS Proporcionalidad ICY" := DXArchivedPurchase606Old."ITBIS Proporcionalidad ICY";
                DXRArchivedPurchase606New."ITBIS llevado al costo ICY" := DXArchivedPurchase606Old."ITBIS llevado al costo ICY";
                DXRArchivedPurchase606New."ITBIS por adelantar ICY" := DXArchivedPurchase606Old."ITBIS por adelantar ICY";
                DXRArchivedPurchase606New."ITBIS Percibido ICY" := DXArchivedPurchase606Old."ITBIS Percibido ICY";
                DXRArchivedPurchase606New."ISR Percibido ICY" := DXArchivedPurchase606Old."ISR Percibido ICY";
                DXRArchivedPurchase606New."Imp. Selectivo al Consumo ICY" := DXArchivedPurchase606Old."Imp. Selectivo al Consumo ICY";
                DXRArchivedPurchase606New."Otros Impuestos/Tasas ICY" := DXArchivedPurchase606Old."Otros Impuestos/Tasas ICY";
                DXRArchivedPurchase606New."Monto Propina Legal ICY" := DXArchivedPurchase606Old."Monto Propina Legal ICY";
                DXRArchivedPurchase606New."ITBIS Retenido ICY" := DXArchivedPurchase606Old."ITBIS Retenido ICY";
                DXRArchivedPurchase606New."Posting Description" := DXArchivedPurchase606Old."Posting Description";
                DXRArchivedPurchase606New."VAT Bus. Posting Group" := DXArchivedPurchase606Old."VAT Bus. Posting Group";
                DXRArchivedPurchase606New."ITBIS Facturado ICY" := DXArchivedPurchase606Old."ITBIS Facturado ICY";
                if not DXRArchivedPurchase606New.Insert(false) then
                    DXRArchivedPurchase606New.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until DXArchivedPurchase606Old.Next() = 0;
    end;

    // ===== seq26: ITBIS Purchase (606) legacy table restore (54125 -> 52169) =====
    // Ported from MigrateTable_ITBISPurchase606() - whole-table clone, TransferFields expanded to
    // explicit typed field-by-field assignment (39 fields; field 13 "DXMensajes" is a FlowField on
    // both sides and is excluded, matching TransferFields' own behavior - see codeunit-level
    // shadow-field comment for the 5 renamed-field pairs).
    local procedure BootstrapITBISPurchase606Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ITBISPURCHASE606-20260522') then begin
            MigrateITBISPurchase606Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ITBISPURCHASE606-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateITBISPurchase606Table()
    var
        DXITBISPurchase606Old: Record "DXITBIS Purchase (606)";
        DXRITBISPurchase606New: Record "DXR_ITBIS Purchase (606)";
    begin
        if DXITBISPurchase606Old.IsEmpty() then
            exit;

        if DXITBISPurchase606Old.FindSet() then
            repeat
                DXRITBISPurchase606New.Init();
                DXRITBISPurchase606New."Tipo Documento" := DXITBISPurchase606Old."Tipo Documento";
                DXRITBISPurchase606New."No. Documento" := DXITBISPurchase606Old."No. Documento";
                DXRITBISPurchase606New."Tipo Identificacion" := DXITBISPurchase606Old."Tipo Identificacion";
                DXRITBISPurchase606New."Cod. Identificacion" := DXITBISPurchase606Old."Cod. Identificacion";
                DXRITBISPurchase606New."Cod. Proveedor" := DXITBISPurchase606Old."Cod. Proveedor";
                DXRITBISPurchase606New."DXNombre Proveedor" := DXITBISPurchase606Old."DXNombre Proveedor";
                DXRITBISPurchase606New.NCF_DXR := DXITBISPurchase606Old.DXNCF;
                DXRITBISPurchase606New."NCF Modificado" := DXITBISPurchase606Old."NCF Modificado";
                DXRITBISPurchase606New."Fecha Comprobante" := DXITBISPurchase606Old."Fecha Comprobante";
                DXRITBISPurchase606New."ITBIS Facturado" := DXITBISPurchase606Old."ITBIS Facturado";
                DXRITBISPurchase606New."Monto Facturado" := DXITBISPurchase606Old."Monto Facturado";
                DXRITBISPurchase606New."No. Linea" := DXITBISPurchase606Old."No. Linea";
                DXRITBISPurchase606New."Estado Reg." := DXITBISPurchase606Old."Estado Reg.";
                DXRITBISPurchase606New."DXCategoria NCF" := DXITBISPurchase606Old."DXCategoria NCF";
                DXRITBISPurchase606New."DXFecha Pago" := DXITBISPurchase606Old."DXFecha Pago";
                DXRITBISPurchase606New."DXITBIS Retenido" := DXITBISPurchase606Old."DXITBIS Retenido";
                DXRITBISPurchase606New."Estatus_DXR Proveedor" := DXITBISPurchase606Old."DXEstatus Proveedor";
                DXRITBISPurchase606New."DXImporte Ret. Renta" := DXITBISPurchase606Old."DXImporte Ret. Renta";
                DXRITBISPurchase606New."DXNo. Doc. Externo" := DXITBISPurchase606Old."DXNo. Doc. Externo";
                DXRITBISPurchase606New."DXDesc. Categoria NCF" := DXITBISPurchase606Old."DXDesc. Categoria NCF";
                DXRITBISPurchase606New."Razon Social_DXR" := DXITBISPurchase606Old."DXRazon Social";
                DXRITBISPurchase606New.DXAnoMes_Fcomprobante := DXITBISPurchase606Old.DXAnoMes_Fcomprobante;
                DXRITBISPurchase606New.DXDia_Fcomprobante := DXITBISPurchase606Old.DXDia_Fcomprobante;
                DXRITBISPurchase606New.DXAnoMes_FPago := DXITBISPurchase606Old.DXAnoMes_FPago;
                DXRITBISPurchase606New.DXDia_FPago := DXITBISPurchase606Old.DXDia_FPago;
                DXRITBISPurchase606New."Shortcut Dimension 1 Code" := DXITBISPurchase606Old."Shortcut Dimension 1 Code";
                DXRITBISPurchase606New."Shortcut Dimension 2 Code" := DXITBISPurchase606Old."Shortcut Dimension 2 Code";
                DXRITBISPurchase606New."DXMonto Facturado Servicios" := DXITBISPurchase606Old."DXMonto Facturado Servicios";
                DXRITBISPurchase606New."DXMonto Facturado Bienes" := DXITBISPurchase606Old."DXMonto Facturado Bienes";
                DXRITBISPurchase606New."DXITBIS Proporcionalidad" := DXITBISPurchase606Old."DXITBIS Proporcionalidad";
                DXRITBISPurchase606New."DXITBIS llevado al costo" := DXITBISPurchase606Old."DXITBIS llevado al costo";
                DXRITBISPurchase606New."DXITBIS por adelantar" := DXITBISPurchase606Old."DXITBIS por adelantar";
                DXRITBISPurchase606New."ITBIS Percibido" := DXITBISPurchase606Old."ITBIS Percibido";
                DXRITBISPurchase606New."DXR_ISR withholding Type" := DXITBISPurchase606Old."DXISR withholding Type";
                DXRITBISPurchase606New."ISR Percibido" := DXITBISPurchase606Old."ISR Percibido";
                DXRITBISPurchase606New."Imp. Selectivo al Consumo" := DXITBISPurchase606Old."Imp. Selectivo al Consumo";
                DXRITBISPurchase606New."DXOtros Impuestos/Tasas" := DXITBISPurchase606Old."DXOtros Impuestos/Tasas";
                DXRITBISPurchase606New."Monto Propina Legal" := DXITBISPurchase606Old."Monto Propina Legal";
                DXRITBISPurchase606New."DXR_Payment Methods 606-607" := DXITBISPurchase606Old."DXPayment Methods 606-607";
                if not DXRITBISPurchase606New.Insert(false) then
                    DXRITBISPurchase606New.Modify(false);
            until DXITBISPurchase606Old.Next() = 0;
    end;

    // ===== seq27: Purchase Line Settlement legacy table restore (54139 -> 52193) =====
    // Ported from MigrateTable_PurchaseLineSettlement() - whole-table clone, TransferFields expanded
    // to explicit typed field-by-field assignment (19 fields, identical names on both sides).
    local procedure BootstrapPurchaseLineSettlementTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASELINESETTLEMENT-20260522') then begin
            MigratePurchaseLineSettlementTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASELINESETTLEMENT-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigratePurchaseLineSettlementTable()
    var
        DXPurchaseLineSettlementOld: Record "DXPurchase Line Settlement";
        DXRPurchaseLineSettlementNew: Record "DXR_Purchase Line Settlement";
    begin
        if DXPurchaseLineSettlementOld.IsEmpty() then
            exit;

        if DXPurchaseLineSettlementOld.FindSet() then
            repeat
                DXRPurchaseLineSettlementNew.Init();
                DXRPurchaseLineSettlementNew."Num. Importacion" := DXPurchaseLineSettlementOld."Num. Importacion";
                DXRPurchaseLineSettlementNew."Line No." := DXPurchaseLineSettlementOld."Line No.";
                DXRPurchaseLineSettlementNew.Type := DXPurchaseLineSettlementOld.Type;
                DXRPurchaseLineSettlementNew."No." := DXPurchaseLineSettlementOld."No.";
                DXRPurchaseLineSettlementNew.Description := DXPurchaseLineSettlementOld.Description;
                DXRPurchaseLineSettlementNew.Empaque := DXPurchaseLineSettlementOld.Empaque;
                DXRPurchaseLineSettlementNew.St := DXPurchaseLineSettlementOld.St;
                DXRPurchaseLineSettlementNew.Quantity := DXPurchaseLineSettlementOld.Quantity;
                DXRPurchaseLineSettlementNew."Unit Cost US" := DXPurchaseLineSettlementOld."Unit Cost US";
                DXRPurchaseLineSettlementNew."Unit Cost Pack US" := DXPurchaseLineSettlementOld."Unit Cost Pack US";
                DXRPurchaseLineSettlementNew."Unit Cost RD" := DXPurchaseLineSettlementOld."Unit Cost RD";
                DXRPurchaseLineSettlementNew."Unit Cost Pack RD" := DXPurchaseLineSettlementOld."Unit Cost Pack RD";
                DXRPurchaseLineSettlementNew."Unit Price Mayor RD" := DXPurchaseLineSettlementOld."Unit Price Mayor RD";
                DXRPurchaseLineSettlementNew."Unit Price Pack Mayor RD" := DXPurchaseLineSettlementOld."Unit Price Pack Mayor RD";
                DXRPurchaseLineSettlementNew."Unit Price Detalle RD" := DXPurchaseLineSettlementOld."Unit Price Detalle RD";
                DXRPurchaseLineSettlementNew."Unit Price Pack Detalle RD" := DXPurchaseLineSettlementOld."Unit Price Pack Detalle RD";
                DXRPurchaseLineSettlementNew."Document Type" := DXPurchaseLineSettlementOld."Document Type";
                DXRPurchaseLineSettlementNew."Buy-from Vendor No." := DXPurchaseLineSettlementOld."Buy-from Vendor No.";
                DXRPurchaseLineSettlementNew."Document No." := DXPurchaseLineSettlementOld."Document No.";
                if not DXRPurchaseLineSettlementNew.Insert(false) then
                    DXRPurchaseLineSettlementNew.Modify(false);
            until DXPurchaseLineSettlementOld.Next() = 0;
    end;

    // ===== seq28: Purchase WS Settlement legacy table restore (54141 -> 52196) =====
    // Ported from MigrateTable_PurchaseWSSettlement() - whole-table clone, TransferFields expanded to
    // explicit typed field-by-field assignment (15 fields, identical names on both sides).
    local procedure BootstrapPurchaseWSSettlementTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASEWSSETTLEMENT-20260522') then begin
            MigratePurchaseWSSettlementTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-PURCHASEWSSETTLEMENT-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigratePurchaseWSSettlementTable()
    var
        DXPurchaseWSSettlementOld: Record "DXPurchase WS Settlement";
        DXRPurchaseWSSettlementNew: Record "DXR_Purchase WS Settlement";
    begin
        if DXPurchaseWSSettlementOld.IsEmpty() then
            exit;

        if DXPurchaseWSSettlementOld.FindSet() then
            repeat
                DXRPurchaseWSSettlementNew.Init();
                DXRPurchaseWSSettlementNew."Num. Importacion" := DXPurchaseWSSettlementOld."Num. Importacion";
                DXRPurchaseWSSettlementNew.Fob := DXPurchaseWSSettlementOld.Fob;
                DXRPurchaseWSSettlementNew.Flete := DXPurchaseWSSettlementOld.Flete;
                DXRPurchaseWSSettlementNew.Prima := DXPurchaseWSSettlementOld.Prima;
                DXRPurchaseWSSettlementNew."Comisiones Bancaria" := DXPurchaseWSSettlementOld."Comisiones Bancaria";
                DXRPurchaseWSSettlementNew."Impuestos Aduanales" := DXPurchaseWSSettlementOld."Impuestos Aduanales";
                DXRPurchaseWSSettlementNew."Verificacion Despacho" := DXPurchaseWSSettlementOld."Verificacion Despacho";
                DXRPurchaseWSSettlementNew."Otros Transporte" := DXPurchaseWSSettlementOld."Otros Transporte";
                DXRPurchaseWSSettlementNew.Otros := DXPurchaseWSSettlementOld.Otros;
                DXRPurchaseWSSettlementNew."Porciento Detalle" := DXPurchaseWSSettlementOld."Porciento Detalle";
                DXRPurchaseWSSettlementNew."Porciento Por Mayor" := DXPurchaseWSSettlementOld."Porciento Por Mayor";
                DXRPurchaseWSSettlementNew."Factor % Pagado" := DXPurchaseWSSettlementOld."Factor % Pagado";
                DXRPurchaseWSSettlementNew."Total General" := DXPurchaseWSSettlementOld."Total General";
                DXRPurchaseWSSettlementNew."Fecha Registro" := DXPurchaseWSSettlementOld."Fecha Registro";
                DXRPurchaseWSSettlementNew.IDuser := DXPurchaseWSSettlementOld.IDuser;
                if not DXRPurchaseWSSettlementNew.Insert(false) then
                    DXRPurchaseWSSettlementNew.Modify(false);
            until DXPurchaseWSSettlementOld.Next() = 0;
    end;

    // ===== seq29: Vendor Withholding Header legacy table restore (54144 -> 52202) =====
    // Ported from MigrateTable_VendorWithholdingHeader() - whole-table clone, TransferFields expanded
    // to explicit typed field-by-field assignment (17 fields, identical names on both sides).
    local procedure BootstrapVendorWithholdingHeaderTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-VENDORWITHHOLDINGHEADER-20260522') then begin
            MigrateVendorWithholdingHeaderTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-VENDORWITHHOLDINGHEADER-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateVendorWithholdingHeaderTable()
    var
        DXVendorWithholdingHeaderOld: Record "DXVendor Withholding Header";
        DXRVendorWithholdingHeaderNew: Record "DXR_Vendor Withholding Header";
    begin
        if DXVendorWithholdingHeaderOld.IsEmpty() then
            exit;

        if DXVendorWithholdingHeaderOld.FindSet() then
            repeat
                DXRVendorWithholdingHeaderNew.Init();
                DXRVendorWithholdingHeaderNew."No." := DXVendorWithholdingHeaderOld."No.";
                DXRVendorWithholdingHeaderNew.Fecha := DXVendorWithholdingHeaderOld.Fecha;
                DXRVendorWithholdingHeaderNew."Cod. Proveedor" := DXVendorWithholdingHeaderOld."Cod. Proveedor";
                DXRVendorWithholdingHeaderNew.Nombre := DXVendorWithholdingHeaderOld.Nombre;
                DXRVendorWithholdingHeaderNew."Cod. Divisa" := DXVendorWithholdingHeaderOld."Cod. Divisa";
                DXRVendorWithholdingHeaderNew."Factor Divisa" := DXVendorWithholdingHeaderOld."Factor Divisa";
                DXRVendorWithholdingHeaderNew."No. Serie" := DXVendorWithholdingHeaderOld."No. Serie";
                DXRVendorWithholdingHeaderNew."No. Serie Registro" := DXVendorWithholdingHeaderOld."No. Serie Registro";
                DXRVendorWithholdingHeaderNew."Aplicar a Factura No." := DXVendorWithholdingHeaderOld."Aplicar a Factura No.";
                DXRVendorWithholdingHeaderNew."Imp. ITBIS Facturado" := DXVendorWithholdingHeaderOld."Imp. ITBIS Facturado";
                DXRVendorWithholdingHeaderNew."Imp. Fact. Sin ITBIS" := DXVendorWithholdingHeaderOld."Imp. Fact. Sin ITBIS";
                DXRVendorWithholdingHeaderNew."Total Fact. Incl. ITBIS" := DXVendorWithholdingHeaderOld."Total Fact. Incl. ITBIS";
                DXRVendorWithholdingHeaderNew."Shortcut Dimension 1 Code" := DXVendorWithholdingHeaderOld."Shortcut Dimension 1 Code";
                DXRVendorWithholdingHeaderNew."Shortcut Dimension 2 Code" := DXVendorWithholdingHeaderOld."Shortcut Dimension 2 Code";
                DXRVendorWithholdingHeaderNew."Cod. Retencion ISR" := DXVendorWithholdingHeaderOld."Cod. Retencion ISR";
                DXRVendorWithholdingHeaderNew."Cod. Retencion ITBIS" := DXVendorWithholdingHeaderOld."Cod. Retencion ITBIS";
                DXRVendorWithholdingHeaderNew."Dimension Set ID" := DXVendorWithholdingHeaderOld."Dimension Set ID";
                if not DXRVendorWithholdingHeaderNew.Insert(false) then
                    DXRVendorWithholdingHeaderNew.Modify(false);
            until DXVendorWithholdingHeaderOld.Next() = 0;
    end;

    // ===== seq30: Withholding Vendor Lines legacy table restore (54149 -> 52211) =====
    // Ported from MigrateTable_WithholdingVendorLines() - whole-table clone, TransferFields expanded
    // to explicit typed field-by-field assignment (4 fields, identical names on both sides).
    local procedure BootstrapWithholdingVendorLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGVENDORLINES-20260522') then begin
            MigrateWithholdingVendorLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-WITHHOLDINGVENDORLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateWithholdingVendorLinesTable()
    var
        DXWithholdingVendorLinesOld: Record "DXWithholding Vendor Lines";
        DXRWithholdingVendorLinesNew: Record "DXR_Withholding Vendor Lines";
    begin
        if DXWithholdingVendorLinesOld.IsEmpty() then
            exit;

        if DXWithholdingVendorLinesOld.FindSet() then
            repeat
                DXRWithholdingVendorLinesNew.Init();
                DXRWithholdingVendorLinesNew."No." := DXWithholdingVendorLinesOld."No.";
                DXRWithholdingVendorLinesNew."Cod. Retencion" := DXWithholdingVendorLinesOld."Cod. Retencion";
                DXRWithholdingVendorLinesNew."Monto a Retener" := DXWithholdingVendorLinesOld."Monto a Retener";
                DXRWithholdingVendorLinesNew."No. Linea" := DXWithholdingVendorLinesOld."No. Linea";
                if not DXRWithholdingVendorLinesNew.Insert(false) then
                    DXRWithholdingVendorLinesNew.Modify(false);
            until DXWithholdingVendorLinesOld.Next() = 0;
    end;
}
