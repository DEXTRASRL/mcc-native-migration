codeunit 60136 "DXR MCC FE Migr Phase7"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 7 Bootstrap".OnRun(), which delegates entirely to "DXR_Upgrade".
    // ExecutePhase1DependencyMigration() (codeunit "DXR_Upgrade", Subtype = Upgrade,
    // Access = Internal). Copies 4 pairs of NCF/Payment setup fields (registry rows FE-P7 seq1/
    // 304/305/306, all SETUP) plus a later-added "Applies Withholding_DXR" fill on 5 line tables
    // (untracked repair step, no registry row - see MigrateLegacyDependencyTableFields comment).
    //
    // The 4 in-scope target tables (DXR_NCF Purchase Setup 52177, DXR_NCF Sales Setup 52178,
    // DXR_NCF Setup 52179, DXR_Payment Method Relation 52180) are owned by DR-Localization and
    // Access = Internal there. DR-Localization now grants MCC's own app ID internalsVisibleTo
    // directly (see DR-Localization/Localization/app.json), so MCC can declare typed Record
    // variables on all 4 directly - including the "_DXR" fields FE itself added via its own
    // tableextensions on those tables (EFDxNcfPurchaseSetup/EFDxNcfSalesSetup/EFNcfSetup/
    // EFPaymentMethodRelation.TableExt.al): the internalsVisibleTo grant covers the whole table,
    // not just fields DR-Localization's own package declared. The 4 legacy source tables
    // (DXNCF Purchase Setup 54130, DXNCF Sales Setup 54131, DXNCF Setup 54132, DXPayment Method
    // Relation 54133) are also owned by DR-Localization but have no Access modifier (default
    // Public), so they were always directly declarable. Zero RecordRef/FieldRef/TransferFields:
    // each procedure below (the 4 NCF/Payment ones and the 5 "Applies Withholding_DXR" ones) is
    // a direct typed field copy, replicated verbatim from FE's now-retired "DXR_EF MCC Migr
    // Bridge" (52544, left in place in FE's own repo, unused) - the cross-repo bridge this
    // codeunit used to call into is no longer needed.
    Permissions =
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Cr.Memo Line" = RM,
        tabledata "DXNCF Purchase Setup" = R,
        tabledata "DXR_NCF Purchase Setup" = RM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RM,
        tabledata "DXPayment Method Relation" = R,
        tabledata "DXR_Payment Method Relation" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625') then
            exit;

        if UpgradeTag.HasUpgradeTag('DXR-EF-LEGACY-DEPS-20260822') then begin
            UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625');
            exit;
        end;

        MigrateLegacyDependencyTableFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-LEGACY-DEPS-20260822');
        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE1-BOOTSTRAP-20260625');
    end;

    procedure RunNCFPurchaseSetup()
    begin
        MigrateNCFPurchaseSetupDependencyFields();
    end;

    procedure RunNCFSalesSetup()
    begin
        MigrateNCFSalesSetupDependencyFields();
    end;

    procedure RunNCFSetup()
    begin
        MigrateNCFSetupDependencyFields();
    end;

    procedure RunPaymentMethodRelation()
    begin
        MigratePaymentMethodRelationDependencyFields();
    end;

    procedure RunAppliesWithholdingRepair()
    begin
        CopyPurchCrMemoLineAppliesWithholding();
        CopyPurchInvLineAppliesWithholding();
        CopySalesLineAppliesWithholding();
        CopySalesInvoiceLineAppliesWithholding();
        CopySalesCrMemoLineAppliesWithholding();
    end;

    procedure RunPurchCrMemoLineWithholding()
    begin
        CopyPurchCrMemoLineAppliesWithholding();
    end;

    procedure RunPurchInvLineWithholding()
    begin
        CopyPurchInvLineAppliesWithholding();
    end;

    procedure RunSalesLineWithholding()
    begin
        CopySalesLineAppliesWithholding();
    end;

    procedure RunSalesInvoiceLineWithholding()
    begin
        CopySalesInvoiceLineAppliesWithholding();
    end;

    procedure RunSalesCrMemoLineWithholding()
    begin
        CopySalesCrMemoLineAppliesWithholding();
    end;

    local procedure MigrateLegacyDependencyTableFields()
    begin
        // seq1: DXNCF Purchase Setup (54130) -> DXR_NCF Purchase Setup (52177): Alternal No.
        // Series_DXR (55501->52333), Alt No. Series NC_DXR (55502->52334).
        MigrateNCFPurchaseSetupDependencyFields();

        // seq304: DXNCF Sales Setup (54131) -> DXR_NCF Sales Setup (52178): same field pair.
        MigrateNCFSalesSetupDependencyFields();

        // seq305: DXNCF Setup (54132) -> DXR_NCF Setup (52179): Base URL_DXR only.
        MigrateNCFSetupDependencyFields();

        // seq306: DXPayment Method Relation (54133) -> DXR_Payment Method Relation (52180):
        // Payment Type_DXR (55501->52333), Payment Type Form_DXR (55502->52334).
        MigratePaymentMethodRelationDependencyFields();

        // "Applies Withholding_DXR" (52335) fill on the 5 line tables - same table on both sides
        // (field 55504 "EF Applies for Withholding" -> 52335 "Applies Withholding_DXR", both
        // Boolean), added 2026-08-22 after Phase 9/10's FieldMap was found missing it (their
        // completion tags short-circuit true on the legacy umbrella tag for any tenant that
        // already ran, so relying on Phase 9/10 alone would not reach an already-migrated
        // company). Phase 9/10's own FieldMaps have since been confirmed to already carry this
        // pair (see those codeunits), so this repair step is now redundant/idempotent but kept
        // for tenants whose upgrade tag ordering already passed this point.
        CopyPurchCrMemoLineAppliesWithholding();
        CopyPurchInvLineAppliesWithholding();
        CopySalesLineAppliesWithholding();
        CopySalesInvoiceLineAppliesWithholding();
        CopySalesCrMemoLineAppliesWithholding();
    end;

    /// <summary>
    /// Fills "Alternal No. Series_DXR"/"Alt No. Series NC_DXR" on "DXR_NCF Purchase Setup" from
    /// the legacy "DXNCF Purchase Setup" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFPurchaseSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Purchase Setup";
        NewSetup: Record "DXR_NCF Purchase Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if not NewSetup.Get(LegacySetup.DXCodigo) then begin
                    NewSetup.Init();
                    NewSetup."DXCodigo" := LegacySetup.DXCodigo;
                    NewSetup.Insert(false);
                end;
                NewSetup."Alternal No. Series_DXR" := LegacySetup."EF Alternal No. Series";
                NewSetup."Alt No. Series NC_DXR" := LegacySetup."EF Alternal No. Series NC";
                NewSetup.Modify(false);
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Alternal No. Series_DXR"/"Alt No. Series NC_DXR" on "DXR_NCF Sales Setup" from the
    /// legacy "DXNCF Sales Setup" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFSalesSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Sales Setup";
        NewSetup: Record "DXR_NCF Sales Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if not NewSetup.Get(LegacySetup.Codigo) then begin
                    NewSetup.Init();
                    NewSetup.Codigo := LegacySetup.Codigo;
                    NewSetup.Insert(false);
                end;
                NewSetup."Alternal No. Series_DXR" := LegacySetup."EF Alternal No. Series";
                NewSetup."Alt No. Series NC_DXR" := LegacySetup."EF Alternal No. Series NC";
                NewSetup.Modify(false);
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Base URL_DXR" on "DXR_NCF Setup" from the legacy "DXNCF Setup" table, for every row
    /// that already exists on the target (fill-only-if-target-row-exists; never inserts).
    /// </summary>
    local procedure MigrateNCFSetupDependencyFields()
    var
        LegacySetup: Record "DXNCF Setup";
        NewSetup: Record "DXR_NCF Setup";
    begin
        if LegacySetup.FindSet() then
            repeat
                if not NewSetup.Get(LegacySetup."Primary Key") then begin
                    NewSetup.Init();
                    NewSetup."Primary Key" := LegacySetup."Primary Key";
                    NewSetup.Insert(false);
                end;
                NewSetup."Base URL_DXR" := LegacySetup."EF Base URL";
                NewSetup.Modify(false);
            until LegacySetup.Next() = 0;
    end;

    /// <summary>
    /// Fills "Payment Type_DXR"/"Payment Type Form_DXR" on "DXR_Payment Method Relation" from the
    /// legacy "DXPayment Method Relation" table, for every row that already exists on the target
    /// (fill-only-if-target-row-exists; never inserts). "EF Payment Type" (enum "EF Payment
    /// Type": Cash=1/Credit=2/Free=3) and "Payment Type_DXR" (enum "DXR_Payment Type": same
    /// value names/ordinals) are structurally identical enums, so the ordinal round-trip via
    /// AsInteger()/FromInteger() below is safe.
    /// </summary>
    local procedure MigratePaymentMethodRelationDependencyFields()
    var
        LegacyRelation: Record "DXPayment Method Relation";
        NewRelation: Record "DXR_Payment Method Relation";
    begin
        if LegacyRelation.FindSet() then
            repeat
                if not NewRelation.Get(LegacyRelation.Code, LegacyRelation."Payment Method Code") then begin
                    NewRelation.Init();
                    NewRelation.Code := LegacyRelation.Code;
                    NewRelation."Payment Method Code" := LegacyRelation."Payment Method Code";
                    NewRelation.Insert(false);
                end;
                NewRelation."Payment Type_DXR" := Enum::"DXR_Payment Type".FromInteger(LegacyRelation."EF Payment Type".AsInteger());
                NewRelation."Payment Type Form_DXR" := LegacyRelation."EF Payment Type Form";
                NewRelation.Modify(false);
            until LegacyRelation.Next() = 0;
    end;

    // The 5 procedures below replace the former generic RecordRef/FieldRef same-table helper
    // (CopyLegacyDependencyTableFieldsSameTable/CopyFieldValueIfExists) that served only the
    // "Applies Withholding_DXR" same-table fill (field 55504 "EF Applies for Withholding" ->
    // 52335 "Applies Withholding_DXR", both Boolean, confirmed against EFPurchCrMemoLine/
    // EFPurchInvLine/EFSalesLine/EFSalesInvoiceLine/EFSalesCrMemoLine.TableExt.al in FE's own
    // repo) - batched in Commit-groups of 100 to match this campaign's precedent for posted/
    // unposted document line tables of unbounded row volume.
    local procedure CopyPurchCrMemoLineAppliesWithholding()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        BatchCount: Integer;
    begin
        if PurchCrMemoLine.FindSet() then
            repeat
                if PurchCrMemoLine."Applies Withholding_DXR" <> PurchCrMemoLine."EF Applies for Withholding" then begin
                    PurchCrMemoLine."Applies Withholding_DXR" := PurchCrMemoLine."EF Applies for Withholding";
                    PurchCrMemoLine.Modify(false);
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure CopyPurchInvLineAppliesWithholding()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        BatchCount: Integer;
    begin
        if PurchInvLine.FindSet() then
            repeat
                if PurchInvLine."Applies Withholding_DXR" <> PurchInvLine."EF Applies for Withholding" then begin
                    PurchInvLine."Applies Withholding_DXR" := PurchInvLine."EF Applies for Withholding";
                    PurchInvLine.Modify(false);
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until PurchInvLine.Next() = 0;
    end;

    local procedure CopySalesLineAppliesWithholding()
    var
        SalesLine: Record "Sales Line";
        BatchCount: Integer;
    begin
        if SalesLine.FindSet() then
            repeat
                if SalesLine."Applies Withholding_DXR" <> SalesLine."EF Applies for Withholding" then begin
                    SalesLine."Applies Withholding_DXR" := SalesLine."EF Applies for Withholding";
                    SalesLine.Modify(false);
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until SalesLine.Next() = 0;
    end;

    local procedure CopySalesInvoiceLineAppliesWithholding()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        BatchCount: Integer;
    begin
        if SalesInvoiceLine.FindSet() then
            repeat
                if SalesInvoiceLine."Applies Withholding_DXR" <> SalesInvoiceLine."EF Applies for Withholding" then begin
                    SalesInvoiceLine."Applies Withholding_DXR" := SalesInvoiceLine."EF Applies for Withholding";
                    SalesInvoiceLine.Modify(false);
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CopySalesCrMemoLineAppliesWithholding()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        BatchCount: Integer;
    begin
        if SalesCrMemoLine.FindSet() then
            repeat
                if SalesCrMemoLine."Applies Withholding_DXR" <> SalesCrMemoLine."EF Applies for Withholding" then begin
                    SalesCrMemoLine."Applies Withholding_DXR" := SalesCrMemoLine."EF Applies for Withholding";
                    SalesCrMemoLine.Modify(false);
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until SalesCrMemoLine.Next() = 0;
    end;
}
