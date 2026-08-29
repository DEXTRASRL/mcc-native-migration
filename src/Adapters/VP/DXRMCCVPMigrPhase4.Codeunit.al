#if not ESCUDEA and not BCDX
codeunit 60118 "DXR MCC VP Migr Phase4"
{
    // Native local migration - ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase4 Benef".Run() - see "DXR MCC VP Migr Phase1" for the full
    // per-phase-not-per-concept rationale. 5 table copies (VP-P4 concepts).
    Permissions =
        tabledata VPCargaMasivaBeneficiariosBPD = R,
        tabledata DXR_VPCargaMasBeneficiariosBPD = RIMD,
        tabledata "VPLineasCargaMasivaBen.BPD" = R,
        tabledata "DXR_VPLineasCargaMasivaBen.BPD" = RIMD,
        tabledata VPHisCargaMasBeneficiariosBPD = R,
        tabledata DXR_VPHisCargaMasBenefBPD = RIMD,
        tabledata VPHisLineasCargaMasBenefBPD = R,
        tabledata DXR_VPHisLineaCargaMasBenefBPD = RIMD,
        tabledata "VP Hist. Beneficiarios BPD" = R,
        tabledata "DXR_VP Hist. Beneficiarios BPD" = RIMD,
        tabledata Field = R;

    trigger OnRun()
    begin
        RunMaster();
        RunHistoric();
    end;

    procedure RunMaster()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::VPCargaMasivaBeneficiariosBPD, Database::DXR_VPCargaMasBeneficiariosBPD, 'CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VPLineasCargaMasivaBen.BPD", Database::"DXR_VPLineasCargaMasivaBen.BPD", 'LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunHistoric()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::VPHisCargaMasBeneficiariosBPD, Database::DXR_VPHisCargaMasBenefBPD, 'HIS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::VPHisLineasCargaMasBenefBPD, Database::DXR_VPHisLineaCargaMasBenefBPD, 'HIS-LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Hist. Beneficiarios BPD", Database::"DXR_VP Hist. Beneficiarios BPD", 'HIST-BENEFICIARIOS-BPD', ErrorText) then
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
        BatchCount: Integer;
    begin
        SourceField.SetRange(TableNo, SourceTableNo);
        SourceField.SetRange(Class, SourceField.Class::Normal);
        SourceField.SetFilter("No.", '<%1', 2000000000);
        if SourceField.FindSet(false) then
            repeat
                FieldNos.Add(SourceField."No.");
            until SourceField.Next() = 0;

        SourceRecRef.Open(SourceTableNo);
        if SourceRecRef.FindSet(false) then
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
                CommitBatch(BatchCount);
            until SourceRecRef.Next() = 0;
        SourceRecRef.Close();
    end;

    local procedure CommitBatch(var BatchCount: Integer)
    begin
        BatchCount += 1;
        if BatchCount < 500 then
            exit;
        Commit();
        BatchCount := 0;
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P4-%1-20260728', Suffix), 1, 250));
    end;
}

#endif
