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
        tabledata "DXArchived Sales 607" = RMD,
        tabledata "DXGaps Setup" = R,
        tabledata "DXR_Gaps Setup" = RM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LS-LEGACY-DEPS-20260623') then
            exit;

        Execute();

        UpgradeTag.SetUpgradeTag('DXR-LS-LEGACY-DEPS-20260623');
    end;

    local procedure Execute()
    begin
        MigrateArchivedConsumerSales607(); // seq3, MA -> DXR_Arch Consumer Sales 607
        MigrateConsumerSales607Buffer(); // seq15, MA -> DXR_Consumer Sales 607 Buffer
        MigrateGapsSetup(); // seq16, SETUP -> DXR_Gaps Setup
        MigrateNCFSetup(); // seq17, SETUP -> DXR_NCF Setup
        CopyDependencyFieldRange(Database::"DX Report Sales 607 Buffer", 52215, 54300, 54500, 4); // -> DXR_Report Sales 607 Buffer [HIST, out of scope]
        CopyDependencyFieldRange(Database::"DXArchived Sales 607", 52115, 54300, 54500, 4); // -> DXR_Archived Sales 607 [HIST, out of scope]
        MigrateNCFSalesSetup(); // seq20, SETUP -> DXR_NCF Sales Setup
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
                if Target.Get(Source."Key") then begin
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
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateNCFSetup()
    var
        Source: Record "DXNCF Setup";
        Target: Record "DXR_NCF Setup";
    begin
        if Source.FindSet() then
            repeat
                if Target.Get(Source."Primary Key") then begin
                    Target."Enable RNC Update Excel_DXR" := Source."LSDX Enable RNC Update Excel";
                    Target.Modify(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure MigrateNCFSalesSetup()
    var
        Source: Record "DXNCF Sales Setup";
        Target: Record "DXR_NCF Sales Setup";
    begin
        if Source.FindSet() then
            repeat
                if Target.Get(Source."Codigo") then begin
                    Target."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(Source."LSDX Tipo Doc. Fiscal".AsInteger());
                    Target.Modify(false);
                end;
            until Source.Next() = 0;
    end;

    local procedure CopyDependencyFieldRange(SourceTableId: Integer; TargetTableId: Integer; SourceStartFieldNo: Integer; TargetStartFieldNo: Integer; FieldCount: Integer)
    var
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        FieldOffset: Integer;
        KeyFieldIndex: Integer;
    begin
        SourceRef.Open(SourceTableId);
        TargetRef.Open(TargetTableId);
        SourceKeyRef := SourceRef.KeyIndex(1);

        if SourceRef.FindSet() then
            repeat
                TargetRef.Reset();
                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
                    if TargetRef.FieldExist(SourcePkFieldRef.Number) then begin
                        TargetPkFieldRef := TargetRef.Field(SourcePkFieldRef.Number);
                        TargetPkFieldRef.SetRange(SourcePkFieldRef.Value);
                    end;
                end;

                if TargetRef.FindFirst() then begin
                    for FieldOffset := 0 to FieldCount - 1 do
                        CopyFieldValueIfExists(SourceRef, TargetRef, SourceStartFieldNo + FieldOffset, TargetStartFieldNo + FieldOffset);
                    TargetRef.Modify(false);
                end;
            until SourceRef.Next() = 0;

        TargetRef.Close();
        SourceRef.Close();
    end;

    local procedure CopyFieldValueIfExists(SourceRef: RecordRef; var TargetRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    var
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        EnumOrdinal: Integer;
    begin
        if not SourceRef.FieldExist(SourceFieldNo) or not TargetRef.FieldExist(TargetFieldNo) then
            exit;

        SourceFieldRef := SourceRef.Field(SourceFieldNo);
        TargetFieldRef := TargetRef.Field(TargetFieldNo);
        if TargetFieldRef.Class <> FieldClass::Normal then
            exit;

        if TargetFieldRef.Type = FieldType::Option then begin
            if Evaluate(EnumOrdinal, Format(SourceFieldRef.Value, 0, 2)) then
                TargetFieldRef.Value := EnumOrdinal;
        end else
            TargetFieldRef.Value := SourceFieldRef.Value;
    end;
}
