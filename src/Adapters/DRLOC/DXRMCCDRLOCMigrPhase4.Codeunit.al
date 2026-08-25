codeunit 60168 "DXR MCC DRLOC Migr Phase4"
{
    // Native local migration - ported (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization's own "DXR_Migr. Phase 4 Sales" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Migr_Phase_4_Sales.Codeunit.al), start of the DRLOC Phase 4
    // (Sales) native-porting campaign. Batch 1 (registry seq31/32/33) covers the 3 document
    // concepts: Sales Header/Line, Sales Invoice Header/Line, Sales Cr.Memo Header field restores.
    // Registry rows are repointed from the generic forwarding adapter (60069, "DXR MCC Adapt DRLOC
    // Dispatch") to this codeunit, matching the Phase 2 (60165) / Phase 3 (60167) precedent.
    // Registry seq34 (Cust. Ledger Entry) was already ported earlier this session into codeunit
    // 60165 and is NOT touched here.
    //
    // ===== MANDATORY MAXIMUM-rigor shadow-field investigation (2026-08-24) =====
    // This exact table family (Sales Header / Sales Invoice Header / Sales Cr.Memo Header) is the
    // one MCC's own registry notes identify as the LIVE PRODUCTION CRASH root cause ("Sales family
    // NCF field cross-table ID collision fix, 20 fields" - see 'DRLOC-NCF' row in
    // DXRMCCRegistryLoader.Codeunit.al). Every field pair below was independently re-derived
    // against the CURRENT real tableextension sources (DXR_SalesHeaderExt.TableExt.Al,
    // DXR_SalesLine.TableExt.al, DXR_SalesInvoiceHeaderExt.TableExt.AL,
    // DXR_SalesInvoiceLine.TableExt.al, DXR_SalesCrMemoHeaderExt.TableExt.AL), not trusted from any
    // comment or from the real source procedure body at face value.
    //
    // 1) CONFIRMED the live-crash root cause directly in the tableextension source: Sales Invoice
    //    Header and Sales Cr.Memo Header both share the SAME "_DXR" field-ID block (51811-51829) as
    //    Sales Header, but at those shared IDs the concepts differ table-to-table with incompatible
    //    types. A real ObsoleteReason on MOST of these fields quotes "TransferFields \"must have the
    //    same type\" crash" / "the exact user-reported crash" and documents each field's relocation
    //    to a new, non-colliding ID with a "_V2" suffix. On BOTH tables the ORIGINAL (non-suffixed)
    //    field at the old shared ID is ObsoleteState = Removed; the renamed "_V2" field at the new
    //    ID is the live, current one. This is the OPPOSITE direction of Phase 3's "_V1 removed
    //    intermediate" pattern (there, the SHORTER name was dead; here, the SHORTER name is dead and
    //    the "_V2"-suffixed name is live) - confirmed by direct read of every field's own
    //    ObsoleteState/ObsoleteReason property, not inferred from naming convention. NUANCE: not
    //    every relocation in this block is a hard type-mismatch crash - Sales Cr.Memo Header's
    //    "Correccion Int._DXR" (51817, relocated to "Correccion Int._DXR_V2" 51860) collides with
    //    Sales Header's Boolean field at the SAME field ID and SAME type (Boolean), just a DIFFERENT
    //    concept - its own real ObsoleteReason explicitly describes this as a silent
    //    wrong-value-copy risk during cross-table field access, not a TransferFields crash. Quoted
    //    precisely per field below rather than generalized.
    // 2) Cross-checked DXR_Migr_Phase_4_Sales.Codeunit.al's own real procedure bodies
    //    (MigrateFields_SalesInvoiceHeader/MigrateFields_SalesCrMemoHeader) against this: DRLOC's
    //    own real source ALREADY correctly uses the "_V2" name on every field that was relocated
    //    (e.g. "Mult Tipos Ingresos_DXR_V2", "Fecha Expiracion NCF_DXR_V2", "Utiliza Retencion_DXR_V2")
    //    and correctly keeps the plain "_DXR" name on the handful of fields that were NOT collided
    //    (e.g. Sales Invoice Header's "Is Debit Note_DXR", "Correccion Int._DXR", "Cod. Retencion
    //    ITBIS_DXR"; Sales Cr.Memo Header's "Tipo NCF_DXR", "Tipo NCF Cliente_DXR"). Ported below
    //    verbatim/typed - all 15 (Sales Invoice Header) / 10 (Sales Cr.Memo Header) pairs verified
    //    live-to-live, correct-type, correct-ID against the current tableextension source field by
    //    field, not assumed from the source procedure text.
    // 3) IMPORTANT DIVERGENCE FOUND from DR-Localization's own PARALLEL "always-clean" DataTransfer
    //    implementation ("DXR_Internal Closure Migration".MigrateFields_SalesInvoiceHeader /
    //    MigrateFields_SalesCrMemoHeader in DXR_Internal_Closure_Migration_Upgrade_Clean.al), which
    //    Phase 3 successfully used as a cross-confirmation oracle: for Sales Invoice Header, that
    //    parallel implementation references the OLD, now-Removed field names (no "_V2" suffix -
    //    e.g. plain "Mult Tipos Ingresos_DXR", "Utiliza Retencion_DXR") for exactly the fields that
    //    were later relocated. That parallel codeunit's Sales Invoice Header/Sales Cr.Memo Header
    //    procedures reference Removed fields and would not compile against the current schema - it
    //    is stale/out-of-date for this table family specifically (unlike Purchase, where it was a
    //    clean confirmation oracle). NOT used as a source of truth here for that reason; the
    //    authoritative source for every field pair below is direct verification against the CURRENT
    //    tableextension property blocks (ObsoleteState of each candidate field), cross-checked
    //    against DXR_Migr_Phase_4_Sales.Codeunit.al's own real, current, already-fixed procedure
    //    bodies. (The parallel implementation's Sales Header/Sales Line/Sales Invoice Line field
    //    lists, which are NOT part of the collision, were still used as confirmation and matched
    //    exactly - see below.)
    // 4) Sales Header's own #if __SAAS__ raw-numeric CopyFieldIfExists(RecRef, ...) block: every
    //    single source field number it references (54124-54146) does not exist at all on
    //    DXR_SalesHeaderExt.TableExt.Al (that file only declares 54100-54123, with gaps) - fully
    //    dead/unreachable, confirmed via exhaustive field-by-field read of the tableextension.
    //    Several of its TARGET fields (51825 Declaracion_DXR, 51829 "NCF_DXR Modificado_DXR", 51815
    //    "NCF_DXR Afectado_DXR", 51814 "NCF_DXR Factura_DXR", 51816 "Type of Income_DXR", 51828
    //    "Apply Cust Withhold_DXR") ARE live, legitimate fields not covered by the adjacent
    //    named-field block either - but since the raw block's source IDs are all dead, DRLOC's own
    //    real source never migrates these 6 fields via this procedure (confirmed against the
    //    parallel "always-clean" DataTransfer implementation, which lists the exact same 14 pairs as
    //    the named block and none of these 6 - a genuine, confirmed gap in DR-Localization's own
    //    Phase 4 Sales Header migration, not something introduced or hidden by this port). The 14
    //    named-field pairs (already SourceRecord-typed in real source) are ported below verbatim.
    // 5) Sales Invoice Header ALSO has live, non-obsolete target fields that neither the (dead) raw
    //    block nor the named block ever reach: "NCF_DXR Afectado_DXR" (51816), Declaracion_DXR
    //    (51826), "Type of Income_DXR_V2" (51847 - the live post-collision-fix replacement for
    //    Removed 51817 "Type of Income_DXR") and "Apply Cust Withhold_DXR_V2" (51855 - the live
    //    replacement for Removed 51829 "Apply Cust Withhold_DXR"). All 4 independently confirmed
    //    live via direct read of DXR_SalesInvoiceHeaderExt.TableExt.AL; none referenced by
    //    DR-Localization's own real MigrateFields_SalesInvoiceHeader() body (the raw block's would-be
    //    source numbers for 2 of them - 54144->51847, 54142->51855 - also do not exist on the
    //    current table, same dead-source pattern as the rest of that block; "NCF_DXR Afectado_DXR"
    //    and Declaracion_DXR are not referenced by the raw block at all). A genuine, confirmed
    //    pre-existing gap in DR-Localization's own Phase 4 Sales Invoice Header migration, not
    //    introduced or hidden by this port. The 15 named-field pairs ARE ported below verbatim.
    // 6) Sales Cr.Memo Header's own #if __SAAS__ raw-numeric block is DIFFERENT from every other raw
    //    block encountered in this campaign so far: several of its source field numbers
    //    (54125-54131, "DX Alternate NCF"/"DX Alternate No. Series"/"DX Has NCF Contingency"/"DX NCF
    //    Reconciliation Status"/"DX NCF Reconciliation Blocked"/"DX NCF Reconciliation
    //    DateTime"/"DX NCF Provider Reference") DO genuinely exist on the current table (unlike
    //    Sales Header/Sales Invoice Header, where every raw-block source number was purely
    //    nonexistent) - but every pair is semantically or type mismatched against its claimed target
    //    (e.g. 54125 "DX Alternate NCF" -> 51823 NCF_DXR copies the wrong concept into the main NCF
    //    field; 54128 "DX NCF Reconciliation Status" (Enum) -> 51815 "Tipo NCF_DXR" (Code[20]) is an
    //    outright type mismatch that would throw a runtime error if it ever executed). These 7 DX
    //    Alternate-NCF/Reconciliation fields were relocated to a dedicated tableextension
    //    ("DXR_Sales Cr NCF Recon", confirmed via their own ObsoleteReason text) and are out of scope
    //    for this concept regardless. This reinforces - independent of the zero-RecordRef/FieldRef
    //    global constraint that already excludes this whole block - that the raw block should not be
    //    ported even if RecordRef were allowed: it is neither reachable-and-correct nor safely
    //    ignorable-as-dead, it is reachable-and-wrong. THREE MORE live target fields on this table
    //    are also never correctly reached, on top of the 7 above: "NCF_DXR Afectado_DXR" (51812) IS
    //    technically reachable via the raw block (54126 "DX Alternate No. Series" -> 51812), but that
    //    pairing is semantically wrong (an Alternate No. Series value would land in the NCF-Afectado
    //    field) - functionally never correctly migrated either way; "Type of Income_DXR" (51813) and
    //    "Apply Cust Withhold_DXR_V2" (51865, the live replacement for Removed 51822
    //    "Apply Cust Withhold_DXR") both have dead raw-block source numbers (54137 and 54136
    //    respectively do not exist on the current table) and are not referenced by the named block
    //    either. All 3 confirmed live via direct read of DXR_SalesCrMemoHeaderExt.TableExt.AL; none
    //    referenced by DR-Localization's own real MigrateFields_SalesCrMemoHeader() body - genuine,
    //    confirmed pre-existing gaps, not introduced or hidden by this port. The 10 named-field pairs
    //    (already SourceRecord-typed in real source, and independently confirmed live/correct-type/
    //    correct-ID against the current tableextension) ARE ported below verbatim.
    // 7) Sales Line and Sales Invoice Line have no raw-numeric block in real source at all (only a
    //    4-field named block each) - both sets of 4 pairs (Cod. Retencion ITBIS_DXR/Cod. Retencion
    //    ISR_DXR/ImporteRetenidoITBIS_DXR/ImporteRetenidoISR_DXR, both sides always plain "_DXR" -
    //    no collision, no relocation) independently confirmed live/non-obsolete against
    //    DXR_SalesLine.TableExt.al / DXR_SalesInvoiceLine.TableExt.al and cross-confirmed identical
    //    against the parallel "always-clean" DataTransfer implementation for both tables. Ported
    //    below verbatim/typed. BOTH tables also carry a live "Is Debit Note_DXR" field (51815) with a
    //    corresponding legacy "DX Is Debit Note" (54145, ObsoleteState = Pending) - a valid migration
    //    candidate by the exact same live-source/live-target pattern as every other field already
    //    ported in this campaign (including Sales Header's and Sales Invoice Header's own
    //    "Is Debit Note_DXR" pairs, which DR-Localization's real source DOES migrate on those two
    //    tables) - but DR-Localization's own real MigrateFields_SalesLine()/
    //    MigrateFields_SalesInvoiceLine() bodies never reference this pair on Sales Line/Sales
    //    Invoice Line specifically. A genuine, confirmed pre-existing gap, not introduced or hidden
    //    by this port.
    //
    // Net effect: all 5 concepts in this batch port DR-Localization's own real, CURRENT, already
    // internally-consistent field-restore logic with zero shadow-field/dead-target substitutions.
    // The confirmed functional gaps versus real DR-Localization behavior, ALL pre-existing in
    // DR-Localization's own real Phase 4 Sales procedures and NOT introduced or silently papered over
    // by this port (porting fields DR-Localization's own real source never migrates would be new
    // behavior beyond this batch's scope - a decision for the controller/user later, not this port):
    //   - Sales Header (6 fields, item 4): Declaracion_DXR (51825), "NCF_DXR Modificado_DXR" (51829),
    //     "NCF_DXR Afectado_DXR" (51815), "NCF_DXR Factura_DXR" (51814), "Type of Income_DXR" (51816),
    //     "Apply Cust Withhold_DXR" (51828).
    //   - Sales Invoice Header (4 fields, item 5): "NCF_DXR Afectado_DXR" (51816), Declaracion_DXR
    //     (51826), "Type of Income_DXR_V2" (51847), "Apply Cust Withhold_DXR_V2" (51855).
    //   - Sales Cr.Memo Header (10 fields, item 6): the 7 relocated Alternate-NCF/Reconciliation
    //     fields (item 6) plus "NCF_DXR Afectado_DXR" (51812), "Type of Income_DXR" (51813),
    //     "Apply Cust Withhold_DXR_V2" (51865).
    //   - Sales Line (1 field, item 7): "Is Debit Note_DXR" (51815).
    //   - Sales Invoice Line (1 field, item 7): "Is Debit Note_DXR" (51815).
    //
    // Upgrade Tag reuse: every procedure below is gated by DR-Localization's OWN real per-procedure
    // completion tag, copied as literals from DXR_UpgradeTagMgt.Codeunit.al - the "DXR_Internal
    // Closure Migration"-family tags (UpgradeTagInternalClosureFieldsSalesHeader/SalesLine/
    // SalesInvoiceHeader/SalesInvoiceLine/SalesCrMemoHeader), confirmed via source read to exist and
    // to gate that sibling codeunit's own RunMigrateFields_*() wrappers for these exact concepts -
    // same "reuse the granular tag from the mechanism that already ran these exact fields" rationale
    // already established by the Phase 2 (60165) and Phase 3 (60167) codeunits. (Item 3 above notes
    // that sibling codeunit's Sales Invoice Header/Sales Cr.Memo Header procedure BODIES are stale
    // for this table family - the tag identity itself, which only marks "these fields have been
    // reconciled", is unaffected by that and is still the correct one to reuse.)
    //
    // Commit() placement: Sales Header and Sales Line hold only currently-open (not-yet-posted)
    // documents - working/staging tables, not ever-growing history tables - no periodic Commit(),
    // matching Purchase Header/Purchase Line's Batch 1-2 precedent. Sales Invoice Header, Sales
    // Invoice Line and Sales Cr.Memo Header are permanent, ever-growing posted-document history
    // tables (transaction-volume-scale, unbounded) - periodic Commit() every 100 rows, matching
    // their Purch. Inv. Header/Purch. Inv. Line/Purch. Cr. Memo Hdr. Batch 1-2 precedent.
    // ===== Batch 2 (FINAL for Phase 4) - registry seq35-39, 5 whole-table clones (2026-08-24) =====
    // Ported from DXR_Migr_Phase_4_Sales.Codeunit.al's own real MigrateTable_ArchivedSales607() /
    // MigrateTable_ITBISSales607() / MigrateTable_Consumer02sales607() /
    // MigrateTable_CustomerWithholdingLines() / MigrateTable_CashJournalReceiptList(), each already a
    // typed Record TransferFields(..., true) whole-table clone in real source (no RecordRef/FieldRef
    // in the real procedures either - the raw-numeric #if __SAAS__ blocks that complicated Batch 1's
    // document tables do NOT exist for these 5 concepts). TransferFields(..., true) expanded below
    // into explicit per-field typed assignment, one pair per live field on each old/new table,
    // independently re-derived against the CURRENT real .Table.al sources (not trusted from
    // TransferFields' field-ID-based matching semantics at face value) - this is the same Phase 4
    // (Sales) file family with the confirmed live-crash history from Batch 1, so the same no-trust
    // discipline applies even though these are simpler whole-table clones, not raw-numeric-ID blocks.
    // FlowFields are excluded from every field list (TransferFields never copies FlowFields either -
    // they are calculated, not stored): "Mensajes" (seq35/36/37, each table's own message-log
    // FlowField) and "Customer Name" (seq39, a lookup into Customer.Name).
    //
    // Shadow-field findings - 2 confirmed field renames (same-ID, different-name; TransferFields
    // matches by field ID, so functionally harmless for the whole-table clone, but the explicit typed
    // expansion below correctly pairs by ID, not by name, per field):
    //   - seq36 ITBIS Sales (607): field 54120 old "DXITBIS Withholding Amount" -> new "ITBIS
    //     Withholding Amount_DXR"; field 54121 old "DXISR Withholding Amount" -> new "ISR Withholding
    //     Amount_DXR". This confirms the general rename-risk this table's Purchase-side sibling (Phase
    //     3's ITBIS Purchase (606)) had already flagged, but NOT the exact field the brief predicted:
    //     field 54100 "Type of Income" is NOT renamed on THIS table (stays plain "Type of Income" on
    //     both old and new) - the compiler rejected an initial draft that assumed the same
    //     54100 rename seq37 (below) genuinely has, confirming per-field verification was necessary
    //     rather than pattern-matching from a sibling table. All other fields on this table pair
    //     identically by name and ID with no rename.
    //   - seq37 Consumer (02) Sales (607): field 54100 old "DXType of Income" -> new "Type of
    //     Income_DXR". All other fields on this table pair identically by name and ID with no rename.
    // All other field pairs across all 5 tables (seq35, seq38, seq39 entirely; the remaining fields of
    // seq36/seq37) are plain identical-name/identical-ID/identical-type pairs, confirmed field-by-field
    // against the current .Table.al sources.
    //
    // seq39 (Cash Journal Receipt List) mapping-correction re-verification: the registry row's own
    // comment documents a real prior correction (briefly logged as 54111 -> 54184, fixed to
    // 54111 -> 52132). Independently re-confirmed fresh against the CURRENT real
    // DXR_CashJournalReceiptList.Table.al: the live "DXR_Cash Journal Receipt List" table is object ID
    // 52132 (SaaS) / 36002847 (on-prem), field-for-field identical (by name, ID and type, no rename)
    // to "DXCash Journal Receipt List" (54111 SaaS / 36002773 on-prem, ObsoleteState = Pending). ID
    // 54184 belongs to two entirely unrelated real objects found during this search (NCFSetup's "Bank
    // Commission Account" field and a Gen. Journal Template tableextension's "Cash Recpt. Report ID"
    // field) - confirming the briefly-logged 54184 pairing was a genuine documentation-only mistake
    // in one of DR-Localization's own ID-mapping markdown docs (MAPEO_IDS_OLD_VS_NEW.md /
    // MAPEO_MAESTRO_IDS_LEGACY_VS_DX28.md still carry the stale 54184 entry), never a real code defect
    // - the registry's already-corrected 54111 -> 52132 pairing is confirmed still current and correct.
    //
    // Notable non-blocking finding: the NEW target table for seq38 ("DXR_Customer Withholding Lines")
    // is itself ObsoleteState = Pending / ObsoleteReason = 'The customer withholding module is
    // deprecated.' in real source - the entire customer-withholding module (both old and new sides) is
    // being phased out. Still ported here because DR-Localization's own real orchestrator
    // (DXR_Migr_Phase_4_Sales.Codeunit.al) still calls MigrateTable_CustomerWithholdingLines()
    // unconditionally, and the registry row (seq38, Category 'MA') calls for this exact restore -
    // scope/deprecation-timeline decisions for the module itself are for the controller/user, not this
    // port.
    //
    // Commit() placement: all 5 old source tables are independently confirmed ObsoleteState = Pending
    // in real source (being decommissioned in favor of the DXR-prefixed tables) - matching the "one-
    // time backfill of a frozen legacy snapshot" reasoning already established for Phase 3 Batch 2's 6
    // whole-table clones (which withheld periodic Commit() from all 6 on that same basis). No new rows
    // can land in any of these 5 old tables going forward (current DR-Localization code writes only to
    // the new DXR_-prefixed tables), so every one of these 5 backfills is bounded by however much
    // historical data already exists - no periodic Commit() for any of the 5, same precedent, verified
    // per-table via each old table's own ObsoleteState property rather than assumed from table "shape"
    // alone (Cash Journal Receipt List is a per-transaction receipt log and was considered as a
    // possible transaction-volume-scale exception, but the same frozen-snapshot reasoning applies
    // identically - its row count is likewise now fixed).
    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "DXArchived Sales 607" = R,
        tabledata "DXR_Archived Sales 607" = RIM,
        tabledata "DXITBIS Sales (607)" = R,
        tabledata "DXR_ITBIS Sales (607)" = RIM,
        tabledata "DXConsumer(02) sales(607)" = R,
        tabledata "DXR_Consumer(02) sales(607)" = RIM,
        tabledata "DXCustomer Withholding Lines" = R,
        tabledata "DXR_Customer Withholding Lines" = RIM,
        tabledata "DXCash Journal Receipt List" = R,
        tabledata "DXR_Cash Journal Receipt List" = RIM;

    trigger OnRun()
    var
        UpgradeTagMgt: Codeunit "Upgrade Tag";
        PhaseTags: Codeunit "DXR_Internal Migr. Phase Tags";
    begin
        // 2026-08-25 fix: added the outer completion gate real DR-Localization's own
        // "DXR_Migr. Phase 4 Sales" OnRun() uses (Phase4CompletedTag(), reused verbatim) - same
        // root-cause/fix as codeunit 60165's OnRun() comment (full re-scan on every invocation,
        // forever, contributing to a real reported production hang).
        if UpgradeTagMgt.HasUpgradeTag(PhaseTags.Phase4CompletedTag()) then
            exit;

        BootstrapSalesHeaderFields();
        BootstrapSalesLineFields();
        BootstrapSalesInvoiceHeaderFields();
        BootstrapSalesInvoiceLineFields();
        BootstrapSalesCrMemoHeaderFields();
        BootstrapArchivedSales607Table();
        BootstrapITBISSales607Table();
        BootstrapConsumer02Sales607Table();
        BootstrapCustomerWithholdingLinesTable();
        BootstrapCashJournalReceiptListTable();

        UpgradeTagMgt.SetUpgradeTag(PhaseTags.Phase4CompletedTag());
    end;

    procedure RunMaster()
    begin
        BootstrapSalesHeaderFields();
        BootstrapSalesLineFields();
        BootstrapSalesInvoiceHeaderFields();
        BootstrapSalesInvoiceLineFields();
        BootstrapSalesCrMemoHeaderFields();
        BootstrapITBISSales607Table();
        BootstrapConsumer02Sales607Table();
        BootstrapCustomerWithholdingLinesTable();
        BootstrapCashJournalReceiptListTable();
    end;

    procedure RunHistoric()
    begin
        BootstrapArchivedSales607Table();
    end;

    // ===== seq31: Sales Header field restore =====
    // Ported from MigrateFields_SalesHeader() (named-field block only - the raw-numeric block is
    // dead, see codeunit-level shadow-field comment item 4).
    local procedure BootstrapSalesHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESHEADER-20260522') then begin
            MigrateSalesHeaderFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESHEADER-20260522');
        end;
    end;

    // No periodic Commit() - Sales Header holds only currently-open documents, not an ever-growing
    // history table (see codeunit-level Commit() placement comment).
    local procedure MigrateSalesHeaderFields()
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.FindSet(true) then
            repeat
                if (SalesHeader."Tipo NCF Cliente_DXR" <> SalesHeader."DXTipo NCF Cliente") or
                   (SalesHeader."No. Series NCF Fact._DXR" <> SalesHeader."DXNo. Series NCF Fact.") or
                   (SalesHeader."No. Series NCF Cr._DXR" <> SalesHeader."DXNo. Series NCF Cr.") or
                   (SalesHeader."Customer Name_DXR" <> SalesHeader."DXCustomer Name") or
                   (SalesHeader."Mult Tipos Ingresos_DXR" <> SalesHeader."DXMultiples Tipos de Ingresos") or
                   (SalesHeader."Tipo NCF_DXR" <> SalesHeader."DXTipo NCF") or
                   (SalesHeader."Is Debit Note_DXR" <> SalesHeader."DX Is Debit Note") or
                   (SalesHeader."Utiliza Retencion_DXR" <> SalesHeader."DXUtiliza Retencion") or
                   (SalesHeader."Cod. Retencion ITBIS_DXR" <> SalesHeader."DXCod. Retencion ITBIS") or
                   (SalesHeader."Cod. Retencion ISR_DXR" <> SalesHeader."DXCod. Retencion ISR") or
                   (SalesHeader."Puerto_DXR" <> SalesHeader.DXPuerto) or
                   (SalesHeader."NCF Expiration Date_DXR" <> SalesHeader."DX NCF Expiration Date") or
                   (SalesHeader."Correccion Int._DXR" <> SalesHeader."DXCorreccion Int.") or
                   (SalesHeader."Tipo Retencion_DXR" <> SalesHeader."DXTipo Retencion")
                then begin
                    SalesHeader."Tipo NCF Cliente_DXR" := SalesHeader."DXTipo NCF Cliente";
                    SalesHeader."No. Series NCF Fact._DXR" := SalesHeader."DXNo. Series NCF Fact.";
                    SalesHeader."No. Series NCF Cr._DXR" := SalesHeader."DXNo. Series NCF Cr.";
                    SalesHeader."Customer Name_DXR" := SalesHeader."DXCustomer Name";
                    SalesHeader."Mult Tipos Ingresos_DXR" := SalesHeader."DXMultiples Tipos de Ingresos";
                    SalesHeader."Tipo NCF_DXR" := SalesHeader."DXTipo NCF";
                    SalesHeader."Is Debit Note_DXR" := SalesHeader."DX Is Debit Note";
                    SalesHeader."Utiliza Retencion_DXR" := SalesHeader."DXUtiliza Retencion";
                    SalesHeader."Cod. Retencion ITBIS_DXR" := SalesHeader."DXCod. Retencion ITBIS";
                    SalesHeader."Cod. Retencion ISR_DXR" := SalesHeader."DXCod. Retencion ISR";
                    SalesHeader."Puerto_DXR" := SalesHeader.DXPuerto;
                    SalesHeader."NCF Expiration Date_DXR" := SalesHeader."DX NCF Expiration Date";
                    SalesHeader."Correccion Int._DXR" := SalesHeader."DXCorreccion Int.";
                    SalesHeader."Tipo Retencion_DXR" := SalesHeader."DXTipo Retencion";
                    SalesHeader.Modify(false);
                end;
            until SalesHeader.Next() = 0;
    end;

    // ===== seq31: Sales Line field restore =====
    // Ported from MigrateFields_SalesLine() - no raw-numeric block exists for this table in real
    // source, only this 4-field named block. "Is Debit Note_DXR" (51815) is live but never touched
    // by DR-Localization's own real source on this table (not a gap in this port) - see codeunit-
    // level comment item 7.
    local procedure BootstrapSalesLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESLINE-20260522') then begin
            MigrateSalesLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESLINE-20260522');
        end;
    end;

    // No periodic Commit() - Sales Line holds only currently-open documents, not an ever-growing
    // history table (same reasoning as Sales Header above).
    local procedure MigrateSalesLineFields()
    var
        SalesLine: Record "Sales Line";
    begin
        if SalesLine.FindSet(true) then
            repeat
                if (SalesLine."Cod. Retencion ITBIS_DXR" <> SalesLine."DXCod. Retencion ITBIS") or
                   (SalesLine."Cod. Retencion ISR_DXR" <> SalesLine."DXCod. Retencion ISR") or
                   (SalesLine.ImporteRetenidoITBIS_DXR <> SalesLine.DXImporteRetenidoITBIS) or
                   (SalesLine.ImporteRetenidoISR_DXR <> SalesLine.DXImporteRetenidoISR)
                then begin
                    SalesLine."Cod. Retencion ITBIS_DXR" := SalesLine."DXCod. Retencion ITBIS";
                    SalesLine."Cod. Retencion ISR_DXR" := SalesLine."DXCod. Retencion ISR";
                    SalesLine.ImporteRetenidoITBIS_DXR := SalesLine.DXImporteRetenidoITBIS;
                    SalesLine.ImporteRetenidoISR_DXR := SalesLine.DXImporteRetenidoISR;
                    SalesLine.Modify(false);
                end;
            until SalesLine.Next() = 0;
    end;

    // ===== seq32: Sales Invoice Header field restore =====
    // Ported from MigrateFields_SalesInvoiceHeader() (named-field block only - the raw-numeric block
    // is dead, source numbers 54124-54144/54221 do not exist on
    // DXR_SalesInvoiceHeaderExt.TableExt.AL). Every "_V2"-suffixed target below is the LIVE
    // post-collision-fix field - independently re-verified field by field against the current
    // tableextension source, see codeunit-level comment items 1-3. 4 additional live fields on this
    // table are never touched by DR-Localization's own real source (not a gap in this port) - see
    // codeunit-level comment item 5.
    local procedure BootstrapSalesInvoiceHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESINVOICEHEADER-20260522') then begin
            MigrateSalesInvoiceHeaderFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESINVOICEHEADER-20260522');
        end;
    end;

    // Sales Invoice Header is a permanent, ever-growing posted-document history table
    // (transaction-volume-scale, unbounded) - periodic Commit() every 100 rows.
    local procedure MigrateSalesInvoiceHeaderFields()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BatchCount: Integer;
    begin
        if SalesInvoiceHeader.FindSet(true) then
            repeat
                if (SalesInvoiceHeader."Tipo NCF Cliente_DXR" <> SalesInvoiceHeader."DXTipo NCF Cliente") or
                   (SalesInvoiceHeader."No. Series NCF Fact._DXR" <> SalesInvoiceHeader."DXNo. Series NCF Fact.") or
                   (SalesInvoiceHeader."No. Series NCF Cr._DXR" <> SalesInvoiceHeader."DXNo. Series NCF Cr.") or
                   (SalesInvoiceHeader.NCF_DXR <> SalesInvoiceHeader.DXNCF) or
                   (SalesInvoiceHeader."Mult Tipos Ingresos_DXR_V2" <> SalesInvoiceHeader."DXMultiples Tipos de Ingresos") or
                   (SalesInvoiceHeader."Tipo NCF_DXR_V2" <> SalesInvoiceHeader."DXTipo NCF") or
                   (SalesInvoiceHeader."Fecha Expiracion NCF_DXR_V2" <> SalesInvoiceHeader."DXFecha Expiracion NCF") or
                   (SalesInvoiceHeader."Is Debit Note_DXR" <> SalesInvoiceHeader."DX Is Debit Note") or
                   (SalesInvoiceHeader."Puerto_DXR_V2" <> SalesInvoiceHeader.DXPuerto) or
                   (SalesInvoiceHeader."NCF Expiration Date_DXR_V2" <> SalesInvoiceHeader."DX NCF Expiration Date") or
                   (SalesInvoiceHeader."Correccion Int._DXR" <> SalesInvoiceHeader."DXCorreccion Int.") or
                   (SalesInvoiceHeader."Utiliza Retencion_DXR_V2" <> SalesInvoiceHeader."DXUtiliza Retencion") or
                   (SalesInvoiceHeader."Cod. Retencion ITBIS_DXR" <> SalesInvoiceHeader."DXCod. Retencion ITBIS") or
                   (SalesInvoiceHeader."Cod. Retencion ISR_DXR_V2" <> SalesInvoiceHeader."DXCod. Retencion ISR") or
                   (SalesInvoiceHeader."Tipo Retencion_DXR_V2" <> SalesInvoiceHeader."DXTipo Retencion")
                then begin
                    SalesInvoiceHeader."Tipo NCF Cliente_DXR" := SalesInvoiceHeader."DXTipo NCF Cliente";
                    SalesInvoiceHeader."No. Series NCF Fact._DXR" := SalesInvoiceHeader."DXNo. Series NCF Fact.";
                    SalesInvoiceHeader."No. Series NCF Cr._DXR" := SalesInvoiceHeader."DXNo. Series NCF Cr.";
                    SalesInvoiceHeader.NCF_DXR := SalesInvoiceHeader.DXNCF;
                    SalesInvoiceHeader."Mult Tipos Ingresos_DXR_V2" := SalesInvoiceHeader."DXMultiples Tipos de Ingresos";
                    SalesInvoiceHeader."Tipo NCF_DXR_V2" := SalesInvoiceHeader."DXTipo NCF";
                    SalesInvoiceHeader."Fecha Expiracion NCF_DXR_V2" := SalesInvoiceHeader."DXFecha Expiracion NCF";
                    SalesInvoiceHeader."Is Debit Note_DXR" := SalesInvoiceHeader."DX Is Debit Note";
                    SalesInvoiceHeader."Puerto_DXR_V2" := SalesInvoiceHeader.DXPuerto;
                    SalesInvoiceHeader."NCF Expiration Date_DXR_V2" := SalesInvoiceHeader."DX NCF Expiration Date";
                    SalesInvoiceHeader."Correccion Int._DXR" := SalesInvoiceHeader."DXCorreccion Int.";
                    SalesInvoiceHeader."Utiliza Retencion_DXR_V2" := SalesInvoiceHeader."DXUtiliza Retencion";
                    SalesInvoiceHeader."Cod. Retencion ITBIS_DXR" := SalesInvoiceHeader."DXCod. Retencion ITBIS";
                    SalesInvoiceHeader."Cod. Retencion ISR_DXR_V2" := SalesInvoiceHeader."DXCod. Retencion ISR";
                    SalesInvoiceHeader."Tipo Retencion_DXR_V2" := SalesInvoiceHeader."DXTipo Retencion";
                    SalesInvoiceHeader.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceHeader.Next() = 0;
    end;

    // ===== seq32: Sales Invoice Line field restore =====
    // Ported from MigrateFields_SalesInvoiceLine() - no raw-numeric block exists for this table in
    // real source, only this 4-field named block (identical pair set to Sales Line - no collision,
    // no relocation, both sides plain "_DXR"). "Is Debit Note_DXR" (51815) is live but never touched
    // by DR-Localization's own real source on this table (not a gap in this port) - see codeunit-
    // level comment item 7.
    local procedure BootstrapSalesInvoiceLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESINVOICELINE-20260522') then begin
            MigrateSalesInvoiceLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESINVOICELINE-20260522');
        end;
    end;

    // Sales Invoice Line is a permanent, ever-growing posted-document history table
    // (transaction-volume-scale, unbounded) - periodic Commit() every 100 rows.
    local procedure MigrateSalesInvoiceLineFields()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        BatchCount: Integer;
    begin
        if SalesInvoiceLine.FindSet(true) then
            repeat
                if (SalesInvoiceLine."Cod. Retencion ITBIS_DXR" <> SalesInvoiceLine."DXCod. Retencion ITBIS") or
                   (SalesInvoiceLine."Cod. Retencion ISR_DXR" <> SalesInvoiceLine."DXCod. Retencion ISR") or
                   (SalesInvoiceLine.ImporteRetenidoITBIS_DXR <> SalesInvoiceLine.DXImporteRetenidoITBIS) or
                   (SalesInvoiceLine.ImporteRetenidoISR_DXR <> SalesInvoiceLine.DXImporteRetenidoISR)
                then begin
                    SalesInvoiceLine."Cod. Retencion ITBIS_DXR" := SalesInvoiceLine."DXCod. Retencion ITBIS";
                    SalesInvoiceLine."Cod. Retencion ISR_DXR" := SalesInvoiceLine."DXCod. Retencion ISR";
                    SalesInvoiceLine.ImporteRetenidoITBIS_DXR := SalesInvoiceLine.DXImporteRetenidoITBIS;
                    SalesInvoiceLine.ImporteRetenidoISR_DXR := SalesInvoiceLine.DXImporteRetenidoISR;
                    SalesInvoiceLine.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    // ===== seq33: Sales Cr.Memo Header field restore =====
    // Ported from MigrateFields_SalesCrMemoHeader() (named-field block only - the raw-numeric block
    // is reachable-but-wrong, not merely dead, see codeunit-level shadow-field comment item 6).
    // Every "_V2"-suffixed target below is the LIVE post-collision-fix field - independently
    // re-verified field by field against the current tableextension source, see codeunit-level
    // comment items 1-3. 10 additional live fields on this table are never touched by
    // DR-Localization's own real source (not a gap in this port) - see codeunit-level comment item 6.
    local procedure BootstrapSalesCrMemoHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESCRMEMOHEADER-20260522') then begin
            MigrateSalesCrMemoHeaderFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-SALESCRMEMOHEADER-20260522');
        end;
    end;

    // Sales Cr.Memo Header is a permanent, ever-growing posted-document history table
    // (transaction-volume-scale, unbounded) - periodic Commit() every 100 rows.
    local procedure MigrateSalesCrMemoHeaderFields()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        BatchCount: Integer;
    begin
        if SalesCrMemoHeader.FindSet(true) then
            repeat
                if (SalesCrMemoHeader.NCF_DXR <> SalesCrMemoHeader.DXNCF) or
                   (SalesCrMemoHeader."Mult Tipos Ingresos_DXR_V2" <> SalesCrMemoHeader."DXMultiples Tipos de Ingresos") or
                   (SalesCrMemoHeader."Tipo NCF_DXR" <> SalesCrMemoHeader."DXTipo NCF") or
                   (SalesCrMemoHeader."Fecha Expiracion NCF_DXR_V2" <> SalesCrMemoHeader."DXFecha Expiracion NCF") or
                   (SalesCrMemoHeader."Tipo NCF Cliente_DXR" <> SalesCrMemoHeader."DXTipo NCF Cliente") or
                   (SalesCrMemoHeader."Correccion Int._DXR_V2" <> SalesCrMemoHeader."DXCorreccion Int.") or
                   (SalesCrMemoHeader."Utiliza Retencion_DXR_V2" <> SalesCrMemoHeader."DXUtiliza Retencion") or
                   (SalesCrMemoHeader."Cod. Retencion ITBIS_DXR_V2" <> SalesCrMemoHeader."DXCod. Retencion ITBIS") or
                   (SalesCrMemoHeader."Cod. Retencion ISR_DXR_V2" <> SalesCrMemoHeader."DXCod. Retencion ISR") or
                   (SalesCrMemoHeader."Tipo Retencion_DXR_V2" <> SalesCrMemoHeader."DXTipo Retencion")
                then begin
                    SalesCrMemoHeader.NCF_DXR := SalesCrMemoHeader.DXNCF;
                    SalesCrMemoHeader."Mult Tipos Ingresos_DXR_V2" := SalesCrMemoHeader."DXMultiples Tipos de Ingresos";
                    SalesCrMemoHeader."Tipo NCF_DXR" := SalesCrMemoHeader."DXTipo NCF";
                    SalesCrMemoHeader."Fecha Expiracion NCF_DXR_V2" := SalesCrMemoHeader."DXFecha Expiracion NCF";
                    SalesCrMemoHeader."Tipo NCF Cliente_DXR" := SalesCrMemoHeader."DXTipo NCF Cliente";
                    SalesCrMemoHeader."Correccion Int._DXR_V2" := SalesCrMemoHeader."DXCorreccion Int.";
                    SalesCrMemoHeader."Utiliza Retencion_DXR_V2" := SalesCrMemoHeader."DXUtiliza Retencion";
                    SalesCrMemoHeader."Cod. Retencion ITBIS_DXR_V2" := SalesCrMemoHeader."DXCod. Retencion ITBIS";
                    SalesCrMemoHeader."Cod. Retencion ISR_DXR_V2" := SalesCrMemoHeader."DXCod. Retencion ISR";
                    SalesCrMemoHeader."Tipo Retencion_DXR_V2" := SalesCrMemoHeader."DXTipo Retencion";
                    SalesCrMemoHeader.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesCrMemoHeader.Next() = 0;
    end;

    // ===== seq35: Archived Sales 607 whole-table clone =====
    // Ported from MigrateTable_ArchivedSales607(). Upgrade Tag reused verbatim from
    // DXR_UpgradeTagMgt.Codeunit.al's UpgradeTagInternalClosureTableArchivedSales607(), the tag that
    // gates the sibling "always-clean" codeunit's own RunMigrateTable_ArchivedSales607() wrapper for
    // this exact concept.
    local procedure BootstrapArchivedSales607Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDSALES607-20260522') then begin
            MigrateArchivedSales607Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ARCHIVEDSALES607-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (old table is
    // ObsoleteState = Pending, being decommissioned - see codeunit-level Commit() placement comment).
    local procedure MigrateArchivedSales607Table()
    var
        OldRec: Record "DXArchived Sales 607";
        NewRec: Record "DXR_Archived Sales 607";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."Tipo Documento" := OldRec."Tipo Documento";
                NewRec."No. Documento" := OldRec."No. Documento";
                NewRec."Tipo Identificacion" := OldRec."Tipo Identificacion";
                NewRec."Cod. Identificacion" := OldRec."Cod. Identificacion";
                NewRec."Cod. Cliente" := OldRec."Cod. Cliente";
                NewRec."Nombre Cliente" := OldRec."Nombre Cliente";
                NewRec.NCF := OldRec.NCF;
                NewRec."NCF Modificado" := OldRec."NCF Modificado";
                NewRec."Fecha Comprobante" := OldRec."Fecha Comprobante";
                NewRec."ITBIS Facturado" := OldRec."ITBIS Facturado";
                NewRec."Monto Facturado" := OldRec."Monto Facturado";
                NewRec."No. Linea" := OldRec."No. Linea";
                NewRec."Estado Reg." := OldRec."Estado Reg.";
                NewRec."Report 607" := OldRec."Report 607";
                NewRec."Type of Income" := OldRec."Type of Income";
                NewRec."Fecha Retencion" := OldRec."Fecha Retencion";
                NewRec."ITBIS Retenido por Terceros" := OldRec."ITBIS Retenido por Terceros";
                NewRec."ITBIS Percibido" := OldRec."ITBIS Percibido";
                NewRec."Retencion Renta por Terceros" := OldRec."Retencion Renta por Terceros";
                NewRec."ISR Percibido" := OldRec."ISR Percibido";
                NewRec."Imp. Selectivo al Consumo" := OldRec."Imp. Selectivo al Consumo";
                NewRec."Otros Impuestos o Tasas" := OldRec."Otros Impuestos o Tasas";
                NewRec."Monto Propina Legal" := OldRec."Monto Propina Legal";
                NewRec.Efectivo := OldRec.Efectivo;
                NewRec."Cheque/Transferencia/Deposito" := OldRec."Cheque/Transferencia/Deposito";
                NewRec."Tarjeta Debito/Credito" := OldRec."Tarjeta Debito/Credito";
                NewRec."Venta a Credito" := OldRec."Venta a Credito";
                NewRec."Bonos o Certificados de Regalo" := OldRec."Bonos o Certificados de Regalo";
                NewRec.Permuta := OldRec.Permuta;
                NewRec."Otras Formas de Ventas" := OldRec."Otras Formas de Ventas";
                NewRec."Fuente Datos" := OldRec."Fuente Datos";
                NewRec."Additional Currency Factor" := OldRec."Additional Currency Factor";
                NewRec."Additional Currency Code" := OldRec."Additional Currency Code";
                NewRec."Currency Code" := OldRec."Currency Code";
                NewRec."Currency Factor" := OldRec."Currency Factor";
                NewRec."DX Original Amount" := OldRec."DX Original Amount";
                NewRec."DX Original ITBIS Amount" := OldRec."DX Original ITBIS Amount";
                NewRec."Efectivo ICY" := OldRec."Efectivo ICY";
                NewRec."Cheque/Transf./Deposito ICY" := OldRec."Cheque/Transf./Deposito ICY";
                NewRec."Tarjeta Debito/Credito ICY" := OldRec."Tarjeta Debito/Credito ICY";
                NewRec."Venta a Credito ICY" := OldRec."Venta a Credito ICY";
                NewRec."Bonos o Certif. de Regalo ICY" := OldRec."Bonos o Certif. de Regalo ICY";
                NewRec."Permuta ICY" := OldRec."Permuta ICY";
                NewRec."Otras Formas de Ventas ICY" := OldRec."Otras Formas de Ventas ICY";
                NewRec."Imp. Selectivo al Consumo ICY" := OldRec."Imp. Selectivo al Consumo ICY";
                NewRec."ITBIS Ret. por Terceros ICY" := OldRec."ITBIS Ret. por Terceros ICY";
                NewRec."ITBIS Percibido ICY" := OldRec."ITBIS Percibido ICY";
                NewRec."Ret. Renta por Terceros ICY'" := OldRec."Ret. Renta por Terceros ICY'";
                NewRec."ISR Percibido ICY" := OldRec."ISR Percibido ICY";
                NewRec."Monto Propina Legal ICY" := OldRec."Monto Propina Legal ICY";
                NewRec."Otros Impuestos o Tasas ICY" := OldRec."Otros Impuestos o Tasas ICY";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== seq36: ITBIS Sales (607) whole-table clone =====
    // Ported from MigrateTable_ITBISSales607(). 2 confirmed same-ID renamed-field pairs (54120,
    // 54121) - see codeunit-level shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableITBISSales607().
    local procedure BootstrapITBISSales607Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ITBISSALES607-20260522') then begin
            MigrateITBISSales607Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-ITBISSALES607-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateITBISSales607Table()
    var
        OldRec: Record "DXITBIS Sales (607)";
        NewRec: Record "DXR_ITBIS Sales (607)";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."Tipo Documento" := OldRec."Tipo Documento";
                NewRec."No. Documento" := OldRec."No. Documento";
                NewRec."Tipo Identificacion" := OldRec."Tipo Identificacion";
                NewRec."Cod. Identificacion" := OldRec."Cod. Identificacion";
                NewRec."Cod. Cliente" := OldRec."Cod. Cliente";
                NewRec."Nombre Cliente" := OldRec."Nombre Cliente";
                NewRec.NCF := OldRec.NCF;
                NewRec."NCF Modificado" := OldRec."NCF Modificado";
                NewRec."Fecha Comprobante" := OldRec."Fecha Comprobante";
                NewRec."ITBIS Facturado" := OldRec."ITBIS Facturado";
                NewRec."Monto Facturado" := OldRec."Monto Facturado";
                NewRec."No. Linea" := OldRec."No. Linea";
                NewRec."Estado Reg." := OldRec."Estado Reg.";
                NewRec."Report 607" := OldRec."Report 607";
                NewRec."Type of Income" := OldRec."Type of Income";
                NewRec."Fecha Retencion" := OldRec."Fecha Retencion";
                NewRec."ITBIS Retenido por Terceros" := OldRec."ITBIS Retenido por Terceros";
                NewRec."ITBIS Percibido" := OldRec."ITBIS Percibido";
                NewRec."Retencion Renta por Terceros" := OldRec."Retencion Renta por Terceros";
                NewRec."ISR Percibido" := OldRec."ISR Percibido";
                NewRec."Imp. Selectivo al Consumo" := OldRec."Imp. Selectivo al Consumo";
                NewRec."Otros Impuestos o Tasas" := OldRec."Otros Impuestos o Tasas";
                NewRec."Monto Propina Legal" := OldRec."Monto Propina Legal";
                NewRec.Efectivo := OldRec.Efectivo;
                NewRec."Cheque/Transferencia/Deposito" := OldRec."Cheque/Transferencia/Deposito";
                NewRec."Tarjeta Debito/Credito" := OldRec."Tarjeta Debito/Credito";
                NewRec."Venta a Credito" := OldRec."Venta a Credito";
                NewRec."Bonos o Certificados de Regalo" := OldRec."Bonos o Certificados de Regalo";
                NewRec.Permuta := OldRec.Permuta;
                NewRec."Otras Formas de Ventas" := OldRec."Otras Formas de Ventas";
                NewRec."Fuente Datos" := OldRec."Fuente Datos";
                NewRec."ITBIS Withholding Amount_DXR" := OldRec."DXITBIS Withholding Amount";
                NewRec."ISR Withholding Amount_DXR" := OldRec."DXISR Withholding Amount";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== seq37: Consumer (02) Sales (607) whole-table clone =====
    // Ported from MigrateTable_Consumer02sales607(). 1 confirmed same-ID renamed-field pair (54100) -
    // see codeunit-level shadow-field comment. Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableConsumer02sales607().
    local procedure BootstrapConsumer02Sales607Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CONSUMER02SALES607-20260522') then begin
            MigrateConsumer02Sales607Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CONSUMER02SALES607-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateConsumer02Sales607Table()
    var
        OldRec: Record "DXConsumer(02) sales(607)";
        NewRec: Record "DXR_Consumer(02) sales(607)";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."Tipo Documento" := OldRec."Tipo Documento";
                NewRec."No. Documento" := OldRec."No. Documento";
                NewRec."Tipo Identificacion" := OldRec."Tipo Identificacion";
                NewRec."Cod. Identificacion" := OldRec."Cod. Identificacion";
                NewRec."Cod. Cliente" := OldRec."Cod. Cliente";
                NewRec."Nombre Cliente" := OldRec."Nombre Cliente";
                NewRec.NCF := OldRec.NCF;
                NewRec."NCF Modificado" := OldRec."NCF Modificado";
                NewRec."Fecha Comprobante" := OldRec."Fecha Comprobante";
                NewRec."ITBIS Facturado" := OldRec."ITBIS Facturado";
                NewRec."Monto Facturado" := OldRec."Monto Facturado";
                NewRec."No. Linea" := OldRec."No. Linea";
                NewRec."Estado Reg." := OldRec."Estado Reg.";
                NewRec."Report 607" := OldRec."Report 607";
                NewRec."Type of Income_DXR" := OldRec."DXType of Income";
                NewRec."Fecha Retencion" := OldRec."Fecha Retencion";
                NewRec."ITBIS Retenido por Terceros" := OldRec."ITBIS Retenido por Terceros";
                NewRec."ITBIS Percibido" := OldRec."ITBIS Percibido";
                NewRec."Retencion Renta por Terceros" := OldRec."Retencion Renta por Terceros";
                NewRec."ISR Percibido" := OldRec."ISR Percibido";
                NewRec."Imp. Selectivo al Consumo" := OldRec."Imp. Selectivo al Consumo";
                NewRec."Otros Impuestos o Tasas" := OldRec."Otros Impuestos o Tasas";
                NewRec."Monto Propina Legal" := OldRec."Monto Propina Legal";
                NewRec.Efectivo := OldRec.Efectivo;
                NewRec."Cheque/Transferencia/Deposito" := OldRec."Cheque/Transferencia/Deposito";
                NewRec."Tarjeta Debito/Credito" := OldRec."Tarjeta Debito/Credito";
                NewRec."Venta a Credito" := OldRec."Venta a Credito";
                NewRec."Bonos o Certificados de Regalo" := OldRec."Bonos o Certificados de Regalo";
                NewRec.Permuta := OldRec.Permuta;
                NewRec."Otras Formas de Ventas" := OldRec."Otras Formas de Ventas";
                NewRec."Fuente Datos" := OldRec."Fuente Datos";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== seq38: Customer Withholding Lines whole-table clone =====
    // Ported from MigrateTable_CustomerWithholdingLines() - all 4 fields identical name/ID/type on
    // both sides, no rename. Note: the NEW target table itself is ObsoleteState = Pending in real
    // source (the whole customer-withholding module is deprecated) - see codeunit-level comment.
    // Upgrade Tag reused verbatim from UpgradeTagInternalClosureTableCustomerWithholdingLines().
    local procedure BootstrapCustomerWithholdingLinesTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CUSTOMERWITHHOLDINGLINES-20260522') then begin
            MigrateCustomerWithholdingLinesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CUSTOMERWITHHOLDINGLINES-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment).
    local procedure MigrateCustomerWithholdingLinesTable()
    var
        OldRec: Record "DXCustomer Withholding Lines";
        NewRec: Record "DXR_Customer Withholding Lines";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."No." := OldRec."No.";
                NewRec."Cod. Retencion" := OldRec."Cod. Retencion";
                NewRec."Monto a Retener" := OldRec."Monto a Retener";
                NewRec."No. Linea" := OldRec."No. Linea";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;

    // ===== seq39: Cash Journal Receipt List whole-table clone =====
    // Ported from MigrateTable_CashJournalReceiptList(). All fields identical name/ID/type on both
    // sides, no rename - independently re-confirmed fresh against the CURRENT
    // DXR_CashJournalReceiptList.Table.al (see codeunit-level comment for the seq39
    // mapping-correction re-verification, given this table's own history of a briefly-wrong target ID
    // in the registry row's own comment). "Customer Name" (24) is a FlowField, excluded (not copied by
    // TransferFields either). Upgrade Tag reused verbatim from
    // UpgradeTagInternalClosureTableCashJournalReceiptList().
    local procedure BootstrapCashJournalReceiptListTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CASHJOURNALRECEIPTLIST-20260522') then begin
            MigrateCashJournalReceiptListTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-CASHJOURNALRECEIPTLIST-20260522');
        end;
    end;

    // No periodic Commit() - one-time backfill of a frozen legacy snapshot (see codeunit-level
    // Commit() placement comment - old table is ObsoleteState = Pending, so its row count is now
    // fixed regardless of this concept's per-transaction-log shape).
    local procedure MigrateCashJournalReceiptListTable()
    var
        OldRec: Record "DXCash Journal Receipt List";
        NewRec: Record "DXR_Cash Journal Receipt List";
    begin
        if OldRec.IsEmpty() then
            exit;

        if OldRec.FindSet() then
            repeat
                NewRec.Init();
                NewRec."Posting Date" := OldRec."Posting Date";
                NewRec."Document type" := OldRec."Document type";
                NewRec."Document No." := OldRec."Document No.";
                NewRec."External Document No." := OldRec."External Document No.";
                NewRec."Account Type" := OldRec."Account Type";
                NewRec."Account No." := OldRec."Account No.";
                NewRec.Description := OldRec.Description;
                NewRec."Currency code" := OldRec."Currency code";
                NewRec."Exchange Rate" := OldRec."Exchange Rate";
                NewRec."Cash Amount" := OldRec."Cash Amount";
                NewRec."Card Amount" := OldRec."Card Amount";
                NewRec."Check Amount" := OldRec."Check Amount";
                NewRec."Transf. Amount" := OldRec."Transf. Amount";
                NewRec.Amount := OldRec.Amount;
                NewRec."Bal. Account Type" := OldRec."Bal. Account Type";
                NewRec."Cta. Contrapartida" := OldRec."Cta. Contrapartida";
                NewRec."Shortcut Dimension 1 Code" := OldRec."Shortcut Dimension 1 Code";
                NewRec."Shortcut Dimension 2 Code" := OldRec."Shortcut Dimension 2 Code";
                NewRec."User Id" := OldRec."User Id";
                NewRec.Impreso := OldRec.Impreso;
                NewRec.Reversada := OldRec.Reversada;
                NewRec."Additional Currency Amount" := OldRec."Additional Currency Amount";
                if not NewRec.Insert(false) then
                    NewRec.Modify(false);
            until OldRec.Next() = 0;
    end;
}
