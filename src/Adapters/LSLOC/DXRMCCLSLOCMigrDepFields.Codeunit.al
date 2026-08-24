codeunit 60163 "DXR MCC LSLOC Migr DepFields"
{
    // Native local migration - ported verbatim from LS Central DR Localization's own
    // "DXR_LS Dependency Fields Upgr." (54512, Access = Internal) -> Execute(). Fill-only-if-
    // target-row-exists semantics throughout.
    //
    // Of the 7 dependency-field pairs this codeunit's original source copies, only 3 are
    // MCC-registry-tracked SETUP concepts (seq16 Gaps Setup, seq17 NCF Setup, seq20 NCF Sales
    // Setup - LSLOC-DEPFLD). The other 4 (Archived Consumer Sales 607/seq3, Consumer Sales 607
    // Buffer/seq15, Report Sales 607 Buffer/seq18, Archived Sales 607/seq19) are tracked under
    // MA/HIST categories, out of scope for this pass, and are left exactly as before
    // (RecordRef/FieldRef via CopyDependencyFieldRange) - their target tables ("DXR_Arch
    // Consumer Sales 607", "DXR_Consumer Sales 607 Buffer", "DXR_Report Sales 607 Buffer",
    // "DXR_Archived Sales 607") are also Access = Internal in DR-Localization, so those 4 still
    // cannot be named below.
    //
    // The 3 in-scope target tables ("DXR_Gaps Setup" 52165, "DXR_NCF Setup" 52179, "DXR_NCF
    // Sales Setup" 52178) are likewise Access = Internal in DR-Localization, and their specific
    // target fields (all suffixed _DXR) are themselves owned by LSLOC's own tableextensions of
    // those Internal tables - fields DR-Localization's own package cannot see either, since
    // DR-Localization does not depend on LSLOC. Zero-RecordRef therefore requires a thin typed
    // wrapper: LSLOC's own public "DXR_LS Migr. Dispatcher" (54506) now exposes
    // RunDependencyFieldSync_GapsSetup/NCFSetup/NCFSalesSetup(), each a direct typed field
    // copy living inside LSLOC's own package (which DOES have internalsVisibleTo from
    // DR-Localization, and owns the target fields).
    Permissions =
        tabledata "DXArchived Consumer Sales 607" = R,
        tabledata "DX Consumer Sales 607 Buffer" = R,
        tabledata "DX Report Sales 607 Buffer" = R,
        tabledata "DXArchived Sales 607" = RMD;

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
    var
        LSLOCDispatcher: Codeunit "DXR_LS Migr. Dispatcher";
    begin
        CopyDependencyFieldRange(Database::"DXArchived Consumer Sales 607", 52111, 54300, 54500, 4); // -> DXR_Arch Consumer Sales 607 [MA, out of scope]
        CopyDependencyFieldRange(Database::"DX Consumer Sales 607 Buffer", 52213, 54300, 54500, 4); // -> DXR_Consumer Sales 607 Buffer [MA, out of scope]
        LSLOCDispatcher.RunDependencyFieldSync_GapsSetup(); // seq16, SETUP -> DXR_Gaps Setup
        LSLOCDispatcher.RunDependencyFieldSync_NCFSetup(); // seq17, SETUP -> DXR_NCF Setup
        CopyDependencyFieldRange(Database::"DX Report Sales 607 Buffer", 52215, 54300, 54500, 4); // -> DXR_Report Sales 607 Buffer [HIST, out of scope]
        CopyDependencyFieldRange(Database::"DXArchived Sales 607", 52115, 54300, 54500, 4); // -> DXR_Archived Sales 607 [HIST, out of scope]
        LSLOCDispatcher.RunDependencyFieldSync_NCFSalesSetup(); // seq20, SETUP -> DXR_NCF Sales Setup
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
