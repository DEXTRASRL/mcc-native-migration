codeunit 60163 "DXR MCC LSLOC Migr DepFields"
{
    // Native local migration - ported verbatim from LS Central DR Localization's own
    // "DXR_LS Dependency Fields Upgr." (54512, Access = Internal) -> Execute(). Fill-only-if-
    // target-row-exists semantics throughout (CopyDependencyFieldRange only writes when the
    // target row is already present via TargetRef.FindFirst() - never inserts).
    // The 7 DXR_-prefixed target tables (DXR_Arch Consumer Sales 607, DXR_Consumer Sales 607
    // Buffer, DXR_Gaps Setup, DXR_NCF Setup, DXR_Report Sales 607 Buffer, DXR_Archived Sales 607,
    // DXR_NCF Sales Setup) are all Access = Internal in DR-Localization - accessed here purely via
    // RecordRef by numeric table ID, so none of them can be (or need to be) named below.
    Permissions =
        tabledata "DXArchived Consumer Sales 607" = R,
        tabledata "DX Consumer Sales 607 Buffer" = R,
        tabledata "DXGaps Setup" = R,
        tabledata "DXNCF Setup" = R,
        tabledata "DX Report Sales 607 Buffer" = R,
        tabledata "DXArchived Sales 607" = RMD,
        tabledata "DXNCF Sales Setup" = R;

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
        CopyDependencyFieldRange(Database::"DXArchived Consumer Sales 607", 52111, 54300, 54500, 4); // -> DXR_Arch Consumer Sales 607
        CopyDependencyFieldRange(Database::"DX Consumer Sales 607 Buffer", 52213, 54300, 54500, 4); // -> DXR_Consumer Sales 607 Buffer
        CopyDependencyFieldRange(Database::"DXGaps Setup", 52165, 54300, 54500, 11); // -> DXR_Gaps Setup
        CopyDependencyFieldRange(Database::"DXNCF Setup", 52179, 54300, 54500, 1); // -> DXR_NCF Setup
        CopyDependencyFieldRange(Database::"DX Report Sales 607 Buffer", 52215, 54300, 54500, 4); // -> DXR_Report Sales 607 Buffer
        CopyDependencyFieldRange(Database::"DXArchived Sales 607", 52115, 54300, 54500, 4); // -> DXR_Archived Sales 607
        CopyDependencyFieldRange(Database::"DXNCF Sales Setup", 52178, 54300, 54500, 1); // -> DXR_NCF Sales Setup
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
