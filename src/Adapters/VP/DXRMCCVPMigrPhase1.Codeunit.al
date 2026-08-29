#if not ESCUDEA and not BCDX
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
    begin
        RunSetup();
        RunMaster();
    end;

    procedure RunSetup()
    var
        ErrorText: Text;
    begin
        if not MigrateVPSetupTable(ErrorText) then
            Error(ErrorText);
        if not MigrateVPCurrencyRelationTable(ErrorText) then
            Error(ErrorText);
        if not MigrateVPProvinciaTable(ErrorText) then
            Error(ErrorText);
    end;

    procedure RunMaster()
    var
        ErrorText: Text;
    begin
        if not MigrateTableStep(Database::"VP Bank", Database::"DXR_VP Bank", 'BANK', ErrorText) then
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

    // VP-P1 concepts 24/26/27 (Category=SETUP): typed, zero-RecordRef, zero-TransferFields
    // replacements for 3 of the 4 in-scope table-level clone-copies below ("VP Bank" stays on the
    // generic MigrateTableStep/CopyClonedTable/TryRunDataTransfer helpers above - out of scope,
    // untouched). Same "clone if row counts diverge" semantics as CopyClonedTable: if source and
    // destination row counts already match, nothing is done (treated as already-migrated);
    // otherwise the destination is fully cleared and every source row is re-inserted with EXPLICIT
    // per-field assignment (no TransferFields, no RecordRef/FieldRef - both banned after a real
    // production "The record is already open." failure traced to RecordRef-heavy code elsewhere in
    // this portfolio), followed by the same post-copy row-count reconciliation check as the
    // original. Field layouts independently verified against the real VP source under
    // vendorpayload\DxPayloads-BC\Vendor Payloads\src\Base\Tables.old\*.Table.al:
    //   - VP Setup (55300) / DXR_VP Setup (52684): same 51 fields as the Phase7 Setup merge above
    //     (see .../Tables.old/ePagosSetup.Table.al vs .../Tables/DXR_ePagosSetup.Table.al) - PK
    //     "Primary Key". Field 34 "VP Method Process" is enum "VP Method Process" on the source
    //     (52120382/55300) but enum "DXR_VP Method Process" on the destination - two DIFFERENT
    //     enum objects, so a plain `:=` would not compile here (unlike the Phase7 case where both
    //     sides share the same enum). Both enums have the identical value list (0 EndPoint /
    //     1 Export File / 2 Register in Journal - see .../Enums.old/EpagosMethodProcess.Enum.al vs
    //     .../Enums/DXR_EpagosMethodProcess.Enum.al), so the field is copied via
    //     Enum::"DXR_VP Method Process".FromInteger(SourceSetup."VP Method Process".AsInteger()).
    //   - VP Currency Relation (55312) / DXR_VP Currency Relation (52707): fields 1-3, PK
    //     "Bank Code","Currency Code","Currency External Code" - see
    //     .../Tables.old/CurrencyRelation.Table.al vs .../Tables/DXR_CurrencyRelation.Table.al
    //   - VP Provincia (55318) / DXR_VP Provincia (52713): fields 1-3, PK "Code" - see
    //     .../Tables.old/Provincia.Table.al vs .../Tables/DXR_Provincia.Table.al
    local procedure MigrateVPSetupTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceSetup: Record "VP Setup";
        DestSetup: Record "DXR_VP Setup";
        SourceCount: Integer;
        DestCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('SETUP')) then
            exit(true);

        SourceCount := SourceSetup.Count();
        DestCount := DestSetup.Count();
        if DestCount <> SourceCount then begin
            if DestCount > 0 then
                DestSetup.DeleteAll(false);

            if SourceSetup.FindSet() then
                repeat
                    DestSetup.Init();
                    DestSetup."Primary Key" := SourceSetup."Primary Key";
                    DestSetup."Journal Template Name" := SourceSetup."Journal Template Name";
                    DestSetup."Journal Batch Name" := SourceSetup."Journal Batch Name";
                    DestSetup."Epago WS url" := SourceSetup."Epago WS url";
                    DestSetup.User := SourceSetup.User;
                    DestSetup.Password := SourceSetup.Password;
                    DestSetup."No Series Payload" := SourceSetup."No Series Payload";
                    DestSetup."Use Approval" := SourceSetup."Use Approval";
                    DestSetup."EndPoint Login" := SourceSetup."EndPoint Login";
                    DestSetup."EndPoint SendData" := SourceSetup."EndPoint SendData";
                    DestSetup."EndPoint StatusGlobal" := SourceSetup."EndPoint StatusGlobal";
                    DestSetup."Url" := SourceSetup."Url";
                    DestSetup."Payment Method Code" := SourceSetup."Payment Method Code";
                    DestSetup."No Series to Journal Line" := SourceSetup."No Series to Journal Line";
                    DestSetup."No Series to VendorPay" := SourceSetup."No Series to VendorPay";
                    DestSetup."No Series to Credit to" := SourceSetup."No Series to Credit to";
                    DestSetup."ShowJson" := SourceSetup."ShowJson";
                    DestSetup."Deny Multi Currency" := SourceSetup."Deny Multi Currency";
                    DestSetup."Use StartSession" := SourceSetup."Use StartSession";
                    DestSetup."Register Movs. Consolidated" := SourceSetup."Register Movs. Consolidated";
                    DestSetup."Automatic Posting" := SourceSetup."Automatic Posting";
                    DestSetup."Use Limit ACH" := SourceSetup."Use Limit ACH";
                    DestSetup."Amount Limit ACH" := SourceSetup."Amount Limit ACH";
                    DestSetup."Days To" := SourceSetup."Days To";
                    DestSetup."Days From" := SourceSetup."Days From";
                    DestSetup."Next Day" := SourceSetup."Next Day";
                    DestSetup."Use Status Logs" := SourceSetup."Use Status Logs";
                    DestSetup."VP Method Process" := Enum::"DXR_VP Method Process".FromInteger(SourceSetup."VP Method Process".AsInteger());
                    DestSetup."Validate Vendor Bank Acc." := SourceSetup."Validate Vendor Bank Acc.";
                    DestSetup."Register in Journal" := SourceSetup."Register in Journal";
                    DestSetup."Export File" := SourceSetup."Export File";
                    DestSetup."EndPoint" := SourceSetup."EndPoint";
                    DestSetup.VPPostNoSeriesBeneficiBPD := SourceSetup.VPPostNoSeriesBeneficiBPD;
                    DestSetup."Add Beneficiaries URL" := SourceSetup."Add Beneficiaries URL";
                    DestSetup."Filter Only Sent BPD Vendors" := SourceSetup."Filter Only Sent BPD Vendors";
                    DestSetup."Enable Bank Journal Curr Val" := SourceSetup."Enable Bank Journal Curr Val";
                    DestSetup."Use Payment Description" := SourceSetup."Use Payment Description";
                    DestSetup."Payment Description" := SourceSetup."Payment Description";
                    DestSetup."Test Request Process" := SourceSetup."Test Request Process";
                    DestSetup."LCY Code VP" := SourceSetup."LCY Code VP";
                    DestSetup."Allow Add Orders" := SourceSetup."Allow Add Orders";
                    DestSetup."Allow Currency Exchange" := SourceSetup."Allow Currency Exchange";
                    DestSetup."Change Status List" := SourceSetup."Change Status List";
                    DestSetup."Enable Flex Currency Filt" := SourceSetup."Enable Flex Currency Filt";
                    DestSetup."Use Default LCY in Vend Bank" := SourceSetup."Use Default LCY in Vend Bank";
                    DestSetup."Show Order No. Column" := SourceSetup."Show Order No. Column";
                    DestSetup."EPG Note Filter By Payload" := SourceSetup."EPG Note Filter By Payload";
                    DestSetup."VP Enhanced Report" := SourceSetup."VP Enhanced Report";
                    DestSetup."Allow Currency Diff.Validation" := SourceSetup."Allow Currency Diff.Validation";
                    DestSetup."Allow Edit PaymentDate OnSent" := SourceSetup."Allow Edit PaymentDate OnSent";
                    DestSetup."View BPD Amounts" := SourceSetup."View BPD Amounts";
                    DestSetup.Insert(false);
                until SourceSetup.Next() = 0;

            DestCount := DestSetup.Count();
            if DestCount <> SourceCount then begin
                ErrorText := CopyStr(StrSubstNo('Row count mismatch after copy: source=%1 destination=%2 (table VP Setup -> DXR_VP Setup)', SourceCount, DestCount), 1, 2048);
                exit(false);
            end;
        end;

        UpgradeTag.SetUpgradeTag(GetStepTag('SETUP'));
        exit(true);
    end;

    local procedure MigrateVPCurrencyRelationTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRelation: Record "VP Currency Relation";
        DestRelation: Record "DXR_VP Currency Relation";
        SourceCount: Integer;
        DestCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('CURRENCY-RELATION')) then
            exit(true);

        SourceCount := SourceRelation.Count();
        DestCount := DestRelation.Count();
        if DestCount <> SourceCount then begin
            if DestCount > 0 then
                DestRelation.DeleteAll(false);

            if SourceRelation.FindSet() then
                repeat
                    DestRelation.Init();
                    DestRelation."Currency Code" := SourceRelation."Currency Code";
                    DestRelation."Currency External Code" := SourceRelation."Currency External Code";
                    DestRelation."Bank Code" := SourceRelation."Bank Code";
                    DestRelation.Insert(false);
                until SourceRelation.Next() = 0;

            DestCount := DestRelation.Count();
            if DestCount <> SourceCount then begin
                ErrorText := CopyStr(StrSubstNo('Row count mismatch after copy: source=%1 destination=%2 (table VP Currency Relation -> DXR_VP Currency Relation)', SourceCount, DestCount), 1, 2048);
                exit(false);
            end;
        end;

        UpgradeTag.SetUpgradeTag(GetStepTag('CURRENCY-RELATION'));
        exit(true);
    end;

    local procedure MigrateVPProvinciaTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceProvincia: Record "VP Provincia";
        DestProvincia: Record "DXR_VP Provincia";
        SourceCount: Integer;
        DestCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('PROVINCIA')) then
            exit(true);

        SourceCount := SourceProvincia.Count();
        DestCount := DestProvincia.Count();
        if DestCount <> SourceCount then begin
            if DestCount > 0 then
                DestProvincia.DeleteAll(false);

            if SourceProvincia.FindSet() then
                repeat
                    DestProvincia.Init();
                    DestProvincia.Code := SourceProvincia.Code;
                    DestProvincia.Name := SourceProvincia.Name;
                    DestProvincia."Cod. BPD" := SourceProvincia."Cod. BPD";
                    DestProvincia.Insert(false);
                until SourceProvincia.Next() = 0;

            DestCount := DestProvincia.Count();
            if DestCount <> SourceCount then begin
                ErrorText := CopyStr(StrSubstNo('Row count mismatch after copy: source=%1 destination=%2 (table VP Provincia -> DXR_VP Provincia)', SourceCount, DestCount), 1, 2048);
                exit(false);
            end;
        end;

        UpgradeTag.SetUpgradeTag(GetStepTag('PROVINCIA'));
        exit(true);
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P1-%1-20260728', Suffix), 1, 250));
    end;
}

#endif
