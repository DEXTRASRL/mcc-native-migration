codeunit 60167 "DXR MCC DRLOC Migr Phase3"
{
    // Native local migration - ported (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization's own "DXR_Migr. Phase 3 Purchase" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Migr_Phase_3_Purchase.Codeunit.al), start of the DRLOC Phase 3
    // (Purchase) native-porting campaign. This batch covers 3 document HEADER concepts (registry
    // seq19/21/23): Purchase Header, Purch. Inv. Header, Purch. Cr. Memo Hdr. field restores.
    // Registry rows are repointed from the generic forwarding adapter (60069, "DXR MCC Adapt DRLOC
    // Dispatch") to this codeunit, matching the Phase 2 (60165) precedent.
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
        tabledata "Purch. Cr. Memo Hdr." = RM;

    trigger OnRun()
    begin
        BootstrapPurchaseHeaderFields();
        BootstrapPurchInvHeaderFields();
        BootstrapPurchCrMemoHdrFields();
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
    begin
        if PurchaseHeader.FindSet(true) then
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
                then begin
                    PurchaseHeader."NCF Interno Proveedor_DXR" := PurchaseHeader."DXNCF Interno Proveedor";
                    PurchaseHeader."No. Series NCF Fact._DXR" := PurchaseHeader."DXNo. Series NCF Fact.";
                    PurchaseHeader."No. Series NCF Ab._DXR" := PurchaseHeader."DXNo. Series NCF Ab.";
                    PurchaseHeader."Utiliza Retencion_DXR" := PurchaseHeader."DXUtiliza Retencion";
                    PurchaseHeader.NCF_DXR := PurchaseHeader.DXNCF;
                    PurchaseHeader."Utiliza NCF Externo_DXR" := PurchaseHeader."DXUtiliza NCF Externo";
                    PurchaseHeader."Descripcion NCF_DXR" := PurchaseHeader."DXDescripcion NCF";
                    PurchaseHeader."Cod. Retencion ITBIS_DXR" := PurchaseHeader."DXCod. Retencion ITBIS";
                    PurchaseHeader."Cod. Retencion ISR_DXR" := PurchaseHeader."DXCod. Retencion ISR";
                    PurchaseHeader."Cod. Categoria NCF_DXR" := PurchaseHeader."DXCod. Categoria NCF";
                    PurchaseHeader."Multiples Cat. NCF_DXR" := PurchaseHeader."DXMultiples Cat. NCF";
                    PurchaseHeader."Correccion Int._DXR" := PurchaseHeader."DXCorreccion Int.";
                    PurchaseHeader."Note Description_DXR" := PurchaseHeader."DX Note Description";
                    PurchaseHeader."Num. Importacion_DXR" := PurchaseHeader."DXNum. Importacion";
                    PurchaseHeader."Monto Selectivo_DXR" := PurchaseHeader."DXMonto Selectivo";
                    PurchaseHeader."Propina Legal_DXR" := PurchaseHeader."DXPropina Legal";
                    PurchaseHeader."Tipo NCF_DXR" := PurchaseHeader."DXTipo NCF";
                    PurchaseHeader."Tipo Retencion_DXR" := PurchaseHeader."DXTipo Retencion";
                    PurchaseHeader."Otros Impuestos y Tasas_DXR" := PurchaseHeader."DXOtros Impuestos y Tasas";
                    PurchaseHeader."Razon Social_DXR" := PurchaseHeader."DXRazon Social";
                    PurchaseHeader.ImporteRetenidoITBIS_DXR := PurchaseHeader.DXImporteRetenidoITBIS;
                    PurchaseHeader.ImporteRetenidoISR_DXR := PurchaseHeader.DXImporteRetenidoISR;
                    PurchaseHeader."Vendor Name_DXR" := PurchaseHeader."DXVendor Name";
                    PurchaseHeader."Tipo Servicio Adquirido_DXR" := PurchaseHeader."DXTipo Servicio Adquirido";
                    PurchaseHeader."Det Servicio Adquir_DXR" := PurchaseHeader."DXDetalle Servicio Adquirido";
                    PurchaseHeader."Parte Relacionada_DXR" := PurchaseHeader."DXParte Relacionada";
                    PurchaseHeader.Modify(false);
                end;
            until PurchaseHeader.Next() = 0;
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
        BatchCount: Integer;
    begin
        if PurchInvHeader.FindSet(true) then
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
                then begin
                    PurchInvHeader."Tipo NCF Provedor_DXR" := PurchInvHeader."DXTipo NCF Provedor";
                    PurchInvHeader."No. Series NCF Fact._DXR" := PurchInvHeader."DXNo. Series NCF Fact.";
                    PurchInvHeader."No. Series NCF Ab._DXR" := PurchInvHeader."DXNo. Series NCF Ab.";
                    PurchInvHeader."Utiliza Retencion_DXR" := PurchInvHeader."DXUtiliza Retencion";
                    PurchInvHeader.NCF_DXR := PurchInvHeader.DXNCF;
                    PurchInvHeader."Utiliza NCF Externo_DXR" := PurchInvHeader."DXUtiliza NCF Externo";
                    PurchInvHeader."Cod. Retencion ITBIS_DXR" := PurchInvHeader."DXCod. Retencion ITBIS";
                    PurchInvHeader."Cod. Retencion ISR_DXR" := PurchInvHeader."DXCod. Retencion ISR";
                    PurchInvHeader."Cod. Categoria NCF_DXR" := PurchInvHeader."DXCod. Categoria NCF";
                    PurchInvHeader."Multiples Cat. NCF_DXR" := PurchInvHeader."DXMultiples Cat. NCF";
                    PurchInvHeader."Correccion Int._DXR" := PurchInvHeader."DXCorreccion Int.";
                    PurchInvHeader."Note Description_DXR" := PurchInvHeader."DX Note Description";
                    PurchInvHeader."Monto Selectivo_DXR" := PurchInvHeader."DXMonto Selectivo";
                    PurchInvHeader."Propina Legal_DXR" := PurchInvHeader."DXPropina Legal";
                    PurchInvHeader."Tipo NCF_DXR" := PurchInvHeader."DXTipo NCF";
                    PurchInvHeader."Tipo Retencion_DXR" := PurchInvHeader."DXTipo Retencion";
                    PurchInvHeader."Otros Impuestos y Tasas_DXR" := PurchInvHeader."DXOtros Impuestos y Tasas";
                    PurchInvHeader."Tipo Compra_DXR" := PurchInvHeader."DXTipo Compra";
                    PurchInvHeader."Fecha Expiracion NCF_DXR" := PurchInvHeader."DXFecha Expiracion NCF";
                    PurchInvHeader."Vendor Name_DXR" := PurchInvHeader."DX Vendor Name";
                    PurchInvHeader."Tipo Servicio Adquirido_DXR" := PurchInvHeader."DXTipo Servicio Adquirido";
                    PurchInvHeader."Det Servicio Adquir_DXR" := PurchInvHeader."DXDetalle Servicio Adquirido";
                    PurchInvHeader."Parte Relacionada_DXR" := PurchInvHeader."DXParte Relacionada";
                    PurchInvHeader."Inv. Status_DXR" := PurchInvHeader."DX Inv. Status";
                    PurchInvHeader.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchInvHeader.Next() = 0;
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
        NewPostedInvStatus: Enum "DXR_Posted Inv. Status";
        BatchCount: Integer;
    begin
        if PurchInvHeader.FindSet(true) then
            repeat
                NewPostedInvStatus := MapPostedInvStatus(PurchInvHeader."DX Posted Inv. Status");
                if PurchInvHeader."Posted Inv. Status_DXR" <> NewPostedInvStatus then begin
                    PurchInvHeader."Posted Inv. Status_DXR" := NewPostedInvStatus;
                    PurchInvHeader.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchInvHeader.Next() = 0;
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
        BatchCount: Integer;
    begin
        if PurchCrMemoHdr.FindSet(true) then
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
                then begin
                    PurchCrMemoHdr."Tipo NCF Provedor_DXR" := PurchCrMemoHdr."DXTipo NCF Provedor";
                    PurchCrMemoHdr."No. Series NCF Fact._DXR" := PurchCrMemoHdr."DXNo. Series NCF Fact.";
                    PurchCrMemoHdr."No. Series NCF Ab._DXR" := PurchCrMemoHdr."DXNo. Series NCF Ab.";
                    PurchCrMemoHdr."Utiliza Retencion_DXR" := PurchCrMemoHdr."DXUtiliza Retencion";
                    PurchCrMemoHdr.NCF_DXR := PurchCrMemoHdr.DXNCF;
                    PurchCrMemoHdr."Utiliza NCF Externo_DXR" := PurchCrMemoHdr."DXUtiliza NCF Externo";
                    PurchCrMemoHdr."Cod. Retencion ITBIS_DXR" := PurchCrMemoHdr."DXCod. Retencion ITBIS";
                    PurchCrMemoHdr."Cod. Retencion ISR_DXR" := PurchCrMemoHdr."DXCod. Retencion ISR";
                    PurchCrMemoHdr."Cod. Categoria NCF_DXR" := PurchCrMemoHdr."DXCod. Categoria NCF";
                    PurchCrMemoHdr."Multiples Cat. NCF_DXR" := PurchCrMemoHdr."DXMultiples Cat. NCF";
                    PurchCrMemoHdr."Correccion Int._DXR" := PurchCrMemoHdr."DXCorreccion Int.";
                    PurchCrMemoHdr."Monto Selectivo_DXR" := PurchCrMemoHdr."DXMonto Selectivo";
                    PurchCrMemoHdr."Propina Legal_DXR" := PurchCrMemoHdr."DXPropina Legal";
                    PurchCrMemoHdr."Tipo NCF_DXR" := PurchCrMemoHdr."DXTipo NCF";
                    PurchCrMemoHdr."Tipo Retencion_DXR" := PurchCrMemoHdr."DXTipo Retencion";
                    PurchCrMemoHdr."Otros Impuestos y Tasas_DXR" := PurchCrMemoHdr."DXOtros Impuestos y Tasas";
                    PurchCrMemoHdr."Tipo Compra_DXR" := PurchCrMemoHdr."DXTipo Compra";
                    PurchCrMemoHdr."Fecha Expiracion NCF_DXR" := PurchCrMemoHdr."DXFecha Expiracion NCF";
                    PurchCrMemoHdr.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchCrMemoHdr.Next() = 0;
    end;

    // Deliberate no-op, matching real source behavior exactly: both "DX Reports 606" (54133) and
    // "Reports 606_DXR" (51950) are themselves FlowFields (confirmed against
    // DXR_PurchCrMemoHdrExt.TableExt.al - both FieldClass = FlowField with an identical CalcFormula
    // shape against archived-purchase-606 tables), so there is nothing to persist via Modify().
    local procedure MigratePurchCrMemoHdrFlowFields()
    begin
        // Both fields are FlowFields. Their values are calculated and cannot be persisted.
    end;
}
