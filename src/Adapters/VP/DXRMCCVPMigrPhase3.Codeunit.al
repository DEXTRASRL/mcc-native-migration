// #if not ESCUDEA and not BCDX
// codeunit 60117 "DXR MCC VP Migr Phase3"
// {
//     // Native local migration - ported verbatim from Vendor Payloads' own
//     // "DXR_VP Migration Phase3 PayldH".Run() - see "DXR MCC VP Migr Phase1" for the full
//     // per-phase-not-per-concept rationale. 3 table copies + 1 BLOB field copy (VP-P3 concepts).
//     Permissions =
//         tabledata "VP Historic Payload Header" = R,
//         tabledata "DXR_VP Historic Payload Header" = RIMD,
//         tabledata "VP Historic Payload Lines" = R,
//         tabledata "DXR_VP Historic Payload Lines" = RIMD,
//         tabledata "VP Historic VendorPay Group" = R,
//         tabledata "DXR_VP Hist VendorPay Group" = RIMD,
//         tabledata Field = R;

//     trigger OnRun()
//     var
//         ErrorText: Text;
//     begin
//         if not MigrateTableStep(Database::"VP Historic Payload Header", Database::"DXR_VP Historic Payload Header", 'HIST-PAYLOAD-HEADER', ErrorText) then
//             Error(ErrorText);
//         if not MigrateTableStep(Database::"VP Historic Payload Lines", Database::"DXR_VP Historic Payload Lines", 'HIST-PAYLOAD-LINES', ErrorText) then
//             Error(ErrorText);
//         if not MigrateTableStep(Database::"VP Historic VendorPay Group", Database::"DXR_VP Hist VendorPay Group", 'HIST-VENDORPAY-GROUP', ErrorText) then
//             Error(ErrorText);
//         MigrateHistVendorPayGroupBlobStep();
//     end;

//     local procedure MigrateHistVendorPayGroupBlobStep()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//         OldRec: Record "VP Historic VendorPay Group";
//         NewRec: Record "DXR_VP Hist VendorPay Group";
//         BatchCount: Integer;
//     begin
//         if UpgradeTag.HasUpgradeTag(GetStepTag('HIST-VENDORPAY-GROUP-BLOB')) then
//             exit;

//         if OldRec.FindSet(false) then
//             repeat
//                 if NewRec.Get(OldRec."Payload No.", OldRec."Vendor No.", OldRec.Currency, OldRec."VendorPay No.") then begin
//                     OldRec.CalcFields(Memo, Remarks);
//                     NewRec.Memo := OldRec.Memo;
//                     NewRec.Remarks := OldRec.Remarks;
//                     NewRec.Modify(false);
//                 end;
//                 CommitBatch(BatchCount);
//             until OldRec.Next() = 0;

//         UpgradeTag.SetUpgradeTag(GetStepTag('HIST-VENDORPAY-GROUP-BLOB'));
//     end;

//     local procedure MigrateTableStep(SourceTableNo: Integer; DestTableNo: Integer; TagSuffix: Text; var ErrorText: Text): Boolean
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag(GetStepTag(TagSuffix)) then
//             exit(true);

//         if not CopyClonedTable(SourceTableNo, DestTableNo, ErrorText) then
//             exit(false);

//         UpgradeTag.SetUpgradeTag(GetStepTag(TagSuffix));
//         exit(true);
//     end;

//     local procedure CopyClonedTable(SourceTableNo: Integer; DestTableNo: Integer; var ErrorText: Text): Boolean
//     var
//         SourceRef: RecordRef;
//         DestRef: RecordRef;
//         SourceCount: Integer;
//         DestCount: Integer;
//     begin
//         SourceRef.Open(SourceTableNo);
//         DestRef.Open(DestTableNo);
//         SourceCount := SourceRef.Count();
//         DestCount := DestRef.Count();

//         if DestCount = SourceCount then
//             exit(true);

//         if DestCount > 0 then
//             DestRef.DeleteAll(false);

//         if not TryRunDataTransfer(SourceTableNo, DestTableNo) then begin
//             ErrorText := CopyStr(GetLastErrorText(), 1, 2048);
//             exit(false);
//         end;

//         Clear(DestRef);
//         DestRef.Open(DestTableNo);
//         DestCount := DestRef.Count();
//         if DestCount <> SourceCount then begin
//             ErrorText := CopyStr(StrSubstNo('Row count mismatch after copy: source=%1 destination=%2 (table %3 -> %4)', SourceCount, DestCount, SourceTableNo, DestTableNo), 1, 2048);
//             exit(false);
//         end;

//         exit(true);
//     end;

//     // VP Historic VendorPay Group field exclusion (19/22 = Memo/Remarks BLOBs) preserved -
//     // migrated separately by MigrateHistVendorPayGroupBlobStep.
//     [TryFunction]
//     local procedure TryRunDataTransfer(SourceTableNo: Integer; DestTableNo: Integer)
//     var
//         SourceField: Record Field;
//         FieldNos: List of [Integer];
//         FieldNo: Integer;
//         SourceRecRef: RecordRef;
//         DestRecRef: RecordRef;
//         SourceFieldRef: FieldRef;
//         DestFieldRef: FieldRef;
//         BatchCount: Integer;
//     begin
//         SourceField.SetRange(TableNo, SourceTableNo);
//         SourceField.SetRange(Class, SourceField.Class::Normal);
//         if SourceTableNo = Database::"VP Historic VendorPay Group" then
//             SourceField.SetFilter("No.", '<%1&<>19&<>22', 2000000000)
//         else
//             SourceField.SetFilter("No.", '<%1', 2000000000);
//         if SourceField.FindSet(false) then
//             repeat
//                 FieldNos.Add(SourceField."No.");
//             until SourceField.Next() = 0;

//         SourceRecRef.Open(SourceTableNo);
//         if SourceRecRef.FindSet(false) then
//             repeat
//                 DestRecRef.Open(DestTableNo);
//                 DestRecRef.Init();
//                 foreach FieldNo in FieldNos do begin
//                     SourceFieldRef := SourceRecRef.Field(FieldNo);
//                     if DestRecRef.FieldExist(SourceFieldRef.Name) then begin
//                         DestFieldRef := DestRecRef.Field(SourceFieldRef.Name);
//                         if (DestFieldRef.Class = FieldClass::Normal) and
//                            (SourceFieldRef.Type = DestFieldRef.Type)
//                         then
//                             DestFieldRef.Value := SourceFieldRef.Value;
//                     end;
//                 end;
//                 DestRecRef.Insert(false);
//                 DestRecRef.Close();
//                 CommitBatch(BatchCount);
//             until SourceRecRef.Next() = 0;
//         SourceRecRef.Close();
//     end;

//     local procedure CommitBatch(var BatchCount: Integer)
//     begin
//         BatchCount += 1;
//         if BatchCount < 500 then
//             exit;
//         Commit();
//         BatchCount := 0;
//     end;

//     local procedure GetStepTag(Suffix: Text): Code[250]
//     begin
//         exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P3-%1-20260728', Suffix), 1, 250));
//     end;
// }

// #endif
