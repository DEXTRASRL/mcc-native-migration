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
    //    types. A real ObsoleteReason on nearly every one of these fields quotes "TransferFields
    //    \"must have the same type\" crash" / "the exact user-reported crash" and documents each
    //    field's relocation to a new, non-colliding ID with a "_V2" suffix. On BOTH tables the
    //    ORIGINAL (non-suffixed) field at the old shared ID is ObsoleteState = Removed; the renamed
    //    "_V2" field at the new ID is the live, current one. This is the OPPOSITE direction of
    //    Phase 3's "_V1 removed intermediate" pattern (there, the SHORTER name was dead; here, the
    //    SHORTER name is dead and the "_V2"-suffixed name is live) - confirmed by direct read of
    //    every field's own ObsoleteState/ObsoleteReason property, not inferred from naming
    //    convention.
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
    // 5) Sales Cr.Memo Header's own #if __SAAS__ raw-numeric block is DIFFERENT from every other raw
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
    //    ignorable-as-dead, it is reachable-and-wrong. The 10 named-field pairs (already
    //    SourceRecord-typed in real source, and independently confirmed live/correct-type/correct-ID
    //    against the current tableextension) are ported below verbatim.
    // 6) Sales Line and Sales Invoice Line have no raw-numeric block in real source at all (only a
    //    4-field named block each) - both sets of 4 pairs (Cod. Retencion ITBIS_DXR/Cod. Retencion
    //    ISR_DXR/ImporteRetenidoITBIS_DXR/ImporteRetenidoISR_DXR, both sides always plain "_DXR" -
    //    no collision, no relocation) independently confirmed live/non-obsolete against
    //    DXR_SalesLine.TableExt.al / DXR_SalesInvoiceLine.TableExt.al and cross-confirmed identical
    //    against the parallel "always-clean" DataTransfer implementation for both tables. Ported
    //    below verbatim/typed.
    //
    // Net effect: all 5 concepts in this batch port DR-Localization's own real, CURRENT, already
    // internally-consistent field-restore logic with zero shadow-field/dead-target substitutions.
    // The only confirmed functional gaps versus real DR-Localization behavior are the 6 Sales Header
    // fields (item 4 above) and the 7 relocated Alternate-NCF/Reconciliation fields on Sales
    // Cr.Memo Header (item 5 above) - both are genuine gaps already present in DR-Localization's own
    // real Phase 4 Sales Header/Sales Cr.Memo Header procedures, not introduced by this port.
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
    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Cr.Memo Header" = RM;

    trigger OnRun()
    begin
        BootstrapSalesHeaderFields();
        BootstrapSalesLineFields();
        BootstrapSalesInvoiceHeaderFields();
        BootstrapSalesInvoiceLineFields();
        BootstrapSalesCrMemoHeaderFields();
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
    // source, only this 4-field named block.
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
    // tableextension source, see codeunit-level comment items 1-3.
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
    // no relocation, both sides plain "_DXR").
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
    // is reachable-but-wrong, not merely dead, see codeunit-level shadow-field comment item 5).
    // Every "_V2"-suffixed target below is the LIVE post-collision-fix field - independently
    // re-verified field by field against the current tableextension source, see codeunit-level
    // comment items 1-3.
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
}
