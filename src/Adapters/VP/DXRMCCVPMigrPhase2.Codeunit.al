codeunit 60116 "DXR MCC VP Migr Phase2"
{
    // Native local migration - ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase2 PayldC".Run() - see "DXR MCC VP Migr Phase1" for the full
    // per-phase-not-per-concept rationale. 6 table copies + 1 BLOB field copy (VP-P2 concepts).
    Permissions =
        tabledata "VP Payload Header" = R,
        tabledata "DXR_VP Payload Header" = RIMD,
        tabledata "VP Payload Journal Lines" = R,
        tabledata "DXR_VP Payload Journal Lines" = RIMD,
        tabledata "VP VendorPay Group" = R,
        tabledata "DXR_VP VendorPay Group" = RIMD,
        tabledata "VP Jounal Bank Account" = R,
        tabledata "DXR_VP Jounal Bank Account" = RIMD,
        tabledata "VP Order Item Status" = R,
        tabledata "DXR_VP Order Item Status" = RIMD,
        tabledata "VP Order Status Log" = R,
        tabledata "DXR_VP Order Status Log" = RIMD,
        tabledata VPOrderNoRelPayment = R,
        tabledata DXR_VPOrderNoRelPayment = RIMD,
        tabledata Field = R;

    trigger OnRun()
    begin
        RunMaster();
        RunAccounting();
        RunHistoric();
    end;

    procedure RunMaster()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::"VP Order Item Status", Database::"DXR_VP Order Item Status", 'ORDER-ITEM-STATUS', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunAccounting()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::"VP Payload Header", Database::"DXR_VP Payload Header", 'PAYLOAD-HEADER', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP Payload Journal Lines", Database::"DXR_VP Payload Journal Lines", 'PAYLOAD-JOURNAL-LINES', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::"VP VendorPay Group", Database::"DXR_VP VendorPay Group", 'VENDORPAY-GROUP', ErrorText) then
            Error(ErrorText);
        MigrateVendorPayGroupBlobStep();
        if not MigrateTableStep(Database::"VP Jounal Bank Account", Database::"DXR_VP Jounal Bank Account", 'JOURNAL-BANK-ACCOUNT', ErrorText) then
            Error(ErrorText);
        if not MigrateTableStep(Database::VPOrderNoRelPayment, Database::DXR_VPOrderNoRelPayment, 'ORDER-NO-REL-PAYMENT', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunHistoric()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::"VP Order Status Log", Database::"DXR_VP Order Status Log", 'ORDER-STATUS-LOG', ErrorText) then
            Error(ErrorText);
    end;

    local procedure MigrateVendorPayGroupBlobStep()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        OldRec: Record "VP VendorPay Group";
        NewRec: Record "DXR_VP VendorPay Group";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('VENDORPAY-GROUP-BLOB')) then
            exit;

        if OldRec.FindSet(false) then
            repeat
                if NewRec.Get(OldRec."Payload No.", OldRec."Vendor No.", OldRec.Currency, OldRec."VendorPay No.") then begin
                    OldRec.CalcFields(NCF, Memo, Remarks);
                    NewRec.NCF := OldRec.NCF;
                    NewRec.Memo := OldRec.Memo;
                    NewRec.Remarks := OldRec.Remarks;
                    NewRec.Modify(false);
                end;
                CommitBatch(BatchCount);
            until OldRec.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('VENDORPAY-GROUP-BLOB'));
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

    // VP VendorPay Group field exclusion (7/19/22 = NCF/Memo/Remarks BLOBs) preserved - migrated
    // separately by MigrateVendorPayGroupBlobStep.
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
        if SourceTableNo = Database::"VP VendorPay Group" then
            SourceField.SetFilter("No.", '<%1&<>7&<>19&<>22', 2000000000)
        else
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
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P2-%1-20260728', Suffix), 1, 250));
    end;
}
