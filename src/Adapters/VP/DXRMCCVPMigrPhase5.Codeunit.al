codeunit 60119 "DXR MCC VP Migr Phase5"
{
    // Native local migration - ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase5 LogsAP".Run() - see "DXR MCC VP Migr Phase1" for the full
    // per-phase-not-per-concept rationale. 3 table copies + 1 BLOB field copy (VP-P5 concepts).
    Permissions =
        tabledata "VP Logs" = R,
        tabledata "DXR_VP Logs" = RIMD,
        tabledata "VP API Log Entry" = R,
        tabledata "DXR_VP API Log Entry" = RIMD,
        tabledata "VP Response Log" = R,
        tabledata "DXR_VP Response Log" = RIMD,
        tabledata Field = R;

    trigger OnRun()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::"VP Logs", Database::"DXR_VP Logs", 'LOGS', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP API Log Entry", Database::"DXR_VP API Log Entry", 'API-LOG-ENTRY', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Response Log", Database::"DXR_VP Response Log", 'RESPONSE-LOG', ErrorText) then
            Error(ErrorText);
        MigrateResponseLogBlobStep();
    end;

    local procedure MigrateResponseLogBlobStep()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        OldRec: Record "VP Response Log";
        NewRec: Record "DXR_VP Response Log";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('RESPONSE-LOG-BLOB')) then
            exit;

        if OldRec.FindSet() then
            repeat
                if NewRec.Get(OldRec."Entry No.") then begin
                    OldRec.CalcFields("Response Body", "Request Body");
                    NewRec."Response Body" := OldRec."Response Body";
                    NewRec."Request Body" := OldRec."Request Body";
                    NewRec.Modify(false);
                end;
            until OldRec.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('RESPONSE-LOG-BLOB'));
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

    // VP Response Log field exclusion (12/13 = Response Body/Request Body BLOBs) preserved -
    // migrated separately by MigrateResponseLogBlobStep.
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
        if SourceTableNo = Database::"VP Response Log" then
            SourceField.SetFilter("No.", '<%1&<>12&<>13', 2000000000)
        else
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
                foreach FieldNo in FieldNos do begin
                    SourceFieldRef := SourceRecRef.Field(FieldNo);
                    if DestRecRef.FieldExist(SourceFieldRef.Name) then begin
                        DestFieldRef := DestRecRef.Field(SourceFieldRef.Name);
                        if (DestFieldRef.Class = FieldClass::Normal) and
                           (SourceFieldRef.Type = DestFieldRef.Type)
                        then
                            DestFieldRef.Value := SourceFieldRef.Value;
                    end;
                end;
                DestRecRef.Insert(false);
                DestRecRef.Close();
            until SourceRecRef.Next() = 0;
        SourceRecRef.Close();
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P5-%1-20260728', Suffix), 1, 250));
    end;
}
