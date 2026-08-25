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
    Permissions =
        tabledata "DX EF Send Registry" = R,
        tabledata "DXR_EF Send Registry" = RIM,
        tabledata "DX NCF Fiscal Queue" = R,
        tabledata "DXR_NCF Fiscal Queue" = RIM,
        tabledata "Application Area Setup" = RM,
        tabledata "Purchase Header" = RM,
        tabledata "Sales Header" = RM;

    trigger OnRun()
    begin
        MigrateOmittedStandardTableFields();
        MigrateEFSendRegistry();
        MigrateNCFFiscalQueue();
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
}
