codeunit 60115 "DXR MCC VP Migr Phase1"
{
    // Native local migration (2026-08-23, per user directive to stop delegating via .Run() and
    // instead have MCC perform the actual copy itself): ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase1 Setup".Run() - 4 legacy setup tables to their DXR_ clones
    // (VP-P1 concepts). One codeunit per PHASE (not per concept, matching DXP's precedent, not
    // SD/BC/RBPD's): every VP phase bundles many internal table/field steps behind a single
    // shared generic RecordRef copy helper, and each step keeps its own Upgrade Tag (reused
    // verbatim from VP's own tag namespace, "VP-DXR-MIGR-P1-...-20260728") so re-running is safe
    // and step-level progress survives a partial failure, exactly as in the original.
    Permissions =
        tabledata "VP Setup" = R,
        tabledata "DXR_VP Setup" = RIMD,
        tabledata "VP Bank" = R,
        tabledata "DXR_VP Bank" = RIMD,
        tabledata "VP Currency Relation" = R,
        tabledata "DXR_VP Currency Relation" = RIMD,
        tabledata "VP Provincia" = R,
        tabledata "DXR_VP Provincia" = RIMD,
        tabledata Field = R;

    trigger OnRun()
    var
        ErrorText: Text;
        ProgressCount: Integer;
        TotalCount: Integer;
    begin
        if not MigrateTableStep(Database::"VP Setup", Database::"DXR_VP Setup", 'SETUP', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Bank", Database::"DXR_VP Bank", 'BANK', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Currency Relation", Database::"DXR_VP Currency Relation", 'CURRENCY-RELATION', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Provincia", Database::"DXR_VP Provincia", 'PROVINCIA', ErrorText) then
            Error(ErrorText);
    end;

    local procedure MigrateTableStep(SourceTableNo: Integer; DestTableNo: Integer; TagSuffix: Text; var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag(TagSuffix)) then
            exit(true);

        if not CopyClonedTable(SourceTableNo, DestTableNo, ErrorText) then
            exit(false);

        UpgradeTag.SetUpgradeTag(GetStepTag(TagSuffix));
        exit(true);
    end;

    local procedure CopyClonedTable(SourceTableNo: Integer; DestTableNo: Integer; var ErrorText: Text): Boolean
    var
        SourceRef: RecordRef;
        DestRef: RecordRef;
        SourceCount: Integer;
        DestCount: Integer;
    begin
        SourceRef.Open(SourceTableNo);
        DestRef.Open(DestTableNo);
        SourceCount := SourceRef.Count();
        DestCount := DestRef.Count();

        if DestCount = SourceCount then
            exit(true);

        if DestCount > 0 then
            DestRef.DeleteAll(false);

        if not TryRunDataTransfer(SourceTableNo, DestTableNo) then begin
            ErrorText := CopyStr(GetLastErrorText(), 1, 2048);
            exit(false);
        end;

        Clear(DestRef);
        DestRef.Open(DestTableNo);
        DestCount := DestRef.Count();
        if DestCount <> SourceCount then begin
            ErrorText := CopyStr(StrSubstNo('Row count mismatch after copy: source=%1 destination=%2 (table %3 -> %4)', SourceCount, DestCount, SourceTableNo, DestTableNo), 1, 2048);
            exit(false);
        end;

        exit(true);
    end;

    [TryFunction]
    local procedure TryRunDataTransfer(SourceTableNo: Integer; DestTableNo: Integer)
    var
        SourceField: Record Field;
        FieldNos: List of [Integer];
        FieldNo: Integer;
        SourceRecRef: RecordRef;
        DestRecRef: RecordRef;
        SourceFieldRef: FieldRef;
        DestFieldRef: FieldRef;
    begin
        SourceField.SetRange(TableNo, SourceTableNo);
        SourceField.SetRange(Class, SourceField.Class::Normal);
        SourceField.SetFilter("No.", '<%1', 2000000000);
        if SourceField.FindSet() then
            repeat
                FieldNos.Add(SourceField."No.");
            until SourceField.Next() = 0;

        SourceRecRef.Open(SourceTableNo);
        if SourceRecRef.FindSet() then
            repeat
                DestRecRef.Open(DestTableNo);
                DestRecRef.Init();
                foreach FieldNo in FieldNos do
                    if DestRecRef.FieldExist(FieldNo) then begin
                        SourceFieldRef := SourceRecRef.Field(FieldNo);
                        DestFieldRef := DestRecRef.Field(FieldNo);
                        DestFieldRef.Value := SourceFieldRef.Value;
                    end;
                DestRecRef.Insert(false);
                DestRecRef.Close();
            until SourceRecRef.Next() = 0;
        SourceRecRef.Close();
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P1-%1-20260728', Suffix), 1, 250));
    end;
}
