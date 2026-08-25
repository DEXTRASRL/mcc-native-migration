codeunit 60163 "DXR MCC LSLOC Migr DepFields"
{
    // Native local migration - ported from LS Central DR Localization's own
    // "DXR_LS Dependency Fields Upgr." (54512, Access = Internal) -> Execute(). Fill-only-if-
    // target-row-exists semantics throughout.
    //
    // Of the 7 dependency-field pairs this codeunit's original source copies, 5 are Direct
    // (native, zero-RecordRef/FieldRef/TransferFields, both DR-Localization's grant and LS
    // Central DR Localization ("LSLOC")'s own added fields on DR-Localization's Internal tables
    // now resolve directly for MCC): seq3 Archived Consumer Sales 607 and seq15 Consumer Sales
    // 607 Buffer (MA), plus seq16 Gaps Setup, seq17 NCF Setup and seq20 NCF Sales Setup (SETUP,
    // LSLOC-DEPFLD). The remaining 2 (Report Sales 607 Buffer/seq18, Archived Sales 607/seq19,
    // both HIST) are out of scope for this pass and are left exactly as before (RecordRef/
    // FieldRef via CopyDependencyFieldRange).
    //
    // All 5 Direct target tables ("DXR_Arch Consumer Sales 607" 52111, "DXR_Consumer Sales 607
    // Buffer" 52213, "DXR_Gaps Setup" 52165, "DXR_NCF Setup" 52179, "DXR_NCF Sales Setup" 52178)
    // are Access = Internal in DR-Localization; their specific target fields (all suffixed _DXR)
    // are owned by LSLOC's own tableextensions of those Internal tables. DR-Localization's
    // internalsVisibleTo grant to MCC makes the base Internal tables nameable, and LSLOC's own
    // tableextensions (public, not Access = Internal) are already visible to MCC via MCC's
    // existing direct dependency on the "LS Central DR Localization" app - no additional grant
    // from LSLOC itself is needed (verified: MCC compiles cleanly referencing LSLOC-added _DXR
    // fields once DR-Localization's grant alone is present). The 5 legacy source tables/fields
    // (LSDX-prefixed, also LSLOC's own tableextensions of DR-Localization's public legacy
    // tables) resolve the same way. LSLOC's own "DXR_LS Migr. Dispatcher" (54506) thin-wrapper
    // procedures (RunDependencyFieldSync_GapsSetup/NCFSetup/NCFSalesSetup) are left in place,
    // unmodified, now orphaned/unused (harmless - established safe default this session).
    Permissions =
        tabledata "DXArchived Consumer Sales 607" = R,
        tabledata "DXR_Arch Consumer Sales 607" = RM,
        tabledata "DX Consumer Sales 607 Buffer" = R,
        tabledata "DXR_Consumer Sales 607 Buffer" = RM,
        tabledata "DX Report Sales 607 Buffer" = R,
        tabledata "DXR_Report Sales 607 Buffer" = RM,
        tabledata "DXArchived Sales 607" = R,
        tabledata "DXR_Archived Sales 607" = RM,
        tabledata "DXGaps Setup" = R,
        tabledata "DXR_Gaps Setup" = RIM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RIM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LS-LEGACY-DEPS-20260623') then
            exit;

        Execute();

        UpgradeTag.SetUpgradeTag('DXR-LS-LEGACY-DEPS-20260623');
    end;

    procedure RunSetupDependencies()
    begin
        MigrateGapsSetup();
        MigrateNCFSetup();
        MigrateNCFSalesSetup();
    end;

    procedure RunMasterDependencies()
    begin
    end;

    procedure RunAccountingDependencies()
    begin
        MigrateArchivedConsumerSales607();
        MigrateConsumerSales607Buffer();
    end;

    procedure RunHistoricDependencies()
    begin
        MigrateReportSales607Buffer();
        MigrateArchivedSales607();
    end;

    local procedure Execute()
    begin
        MigrateArchivedConsumerSales607(); // seq3, MA -> DXR_Arch Consumer Sales 607
        MigrateConsumerSales607Buffer(); // seq15, MA -> DXR_Consumer Sales 607 Buffer
        MigrateGapsSetup(); // seq16, SETUP -> DXR_Gaps Setup
        MigrateNCFSetup(); // seq17, SETUP -> DXR_NCF Setup
        MigrateReportSales607Buffer();
        MigrateArchivedSales607();
        MigrateNCFSalesSetup(); // seq20, SETUP -> DXR_NCF Sales Setup
    end;

    local procedure MigrateReportSales607Buffer()
    var
        Source: Record "DX Report Sales 607 Buffer";
        Target: Record "DXR_Report Sales 607 Buffer";
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                if Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea") then begin
                    Target."Statement No._DXR" := Source."LSDX Statement No.";
                    Target."Posted Statement No._DXR" := Source."LSDX Posted Statement No.";
                    Target."Posted Statement Date_DXR" := Source."LSDX Posted Statement Date";
                    Target."Stmt. Posting Date_DXR" := Source."LSDX Stmt. Posting Date";
                    Target.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateArchivedSales607()
    var
        Source: Record "DXArchived Sales 607";
        Target: Record "DXR_Archived Sales 607";
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                if Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea", Source.NCF) then begin
                    Target."Statement No._DXR" := Source."LSDX Statement No.";
                    Target."Posted Statement No._DXR" := Source."LSDX Posted Statement No.";
                    Target."Posted Statement Date_DXR" := Source."LSDX Posted Statement Date";
                    Target."Stmt. Posting Date_DXR" := Source."LSDX Stmt. Posting Date";
                    Target.Modify(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateArchivedConsumerSales607()
    var
        Source: Record "DXArchived Consumer Sales 607";
        Target: Record "DXR_Arch Consumer Sales 607";
    begin
        if Source.FindSet() then
            repeat
                if Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea", Source.NCF) then begin
                    Target."Statement No._DXR" := Source."LSDX Statement No.";
                    Target."Posted Statement No._DXR" := Source."LSDX Posted Statement No.";
                    Target."Posted Statement Date_DXR" := Source."LSDX Posted Statement Date";
                    Target."Stmt. Posting Date_DXR" := Source."LSDX Stmt. Posting Date";
                    Target.Modify(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateConsumerSales607Buffer()
    var
        Source: Record "DX Consumer Sales 607 Buffer";
        Target: Record "DXR_Consumer Sales 607 Buffer";
    begin
        if Source.FindSet() then
            repeat
                if Target.Get(Source."Tipo Documento", Source."No. Documento", Source."No. Linea") then begin
                    Target."Statement No._DXR" := Source."LSDX Statement No.";
                    Target."Posted Statement No._DXR" := Source."LSDX Posted Statement No.";
                    Target."Posted Statement Date_DXR" := Source."LSDX Posted Statement Date";
                    Target."Stmt. Posting Date_DXR" := Source."LSDX Stmt. Posting Date";
                    Target.Modify(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateGapsSetup()
    var
        Source: Record "DXGaps Setup";
        Target: Record "DXR_Gaps Setup";
    begin
        if Source.FindSet() then
            repeat
                if not Target.Get(Source."Key") then begin
                    Target.Init();
                    Target."Key" := Source."Key";
                    Target.Insert(false);
                end;
                Target."Print NCF_DXR" := Source."Print NCF";
                Target."Print Company Name_DXR" := Source."Print Company Name";
                Target."Print Employee and Trans_DXR" := Source."Print Employee and Trans";
                Target."Print Cashier_DXR" := Source."Print Cashier";
                Target."Print Site Name_DXR" := Source."Print Site Name";
                Target."LineBreakInRNC_DXR" := Source."LineBreakInRNC";
                Target."Print Transaction Time_DXR" := Source."Print Transaction Time";
                Target."LineBreakCustomerName_DXR" := Source."LineBreakCustomerName";
                Target."Print Qty Footer_DXR" := Source."Print Qty Footer";
                Target."Print Staff Sales Person_DXR" := Source."Print Staff Sales Person";
                Target."Staff Sales Person Label_DXR" := Source."Staff Sales Person Label";
                Target.Modify(false);
            until Source.Next() = 0;
    end;

    local procedure MigrateNCFSetup()
    var
        Source: Record "DXNCF Setup";
        Target: Record "DXR_NCF Setup";
    begin
        if Source.FindSet() then
            repeat
                if not Target.Get(Source."Primary Key") then begin
                    Target.Init();
                    Target."Primary Key" := Source."Primary Key";
                    Target.Insert(false);
                end;
                Target."Enable RNC Update Excel_DXR" := Source."LSDX Enable RNC Update Excel";
                Target.Modify(false);
            until Source.Next() = 0;
    end;

    local procedure MigrateNCFSalesSetup()
    var
        Source: Record "DXNCF Sales Setup";
        Target: Record "DXR_NCF Sales Setup";
    begin
        if Source.FindSet() then
            repeat
                if not Target.Get(Source."Codigo") then begin
                    Target.Init();
                    Target."Codigo" := Source."Codigo";
                    Target.Insert(false);
                end;
                Target."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(Source."LSDX Tipo Doc. Fiscal".AsInteger());
                Target.Modify(false);
            until Source.Next() = 0;
    end;

}
