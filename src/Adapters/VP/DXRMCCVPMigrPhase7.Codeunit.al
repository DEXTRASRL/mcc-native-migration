#if not ESCUDEA and not BCDX
codeunit 60121 "DXR MCC VP Migr Phase7"
{
    // Native local migration - ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase7 IdCut".Run() - see "DXR MCC VP Migr Phase1" for the full
    // per-phase-not-per-concept rationale. 22 table-level never-overwrite/fill-gaps merges
    // (MergeMissingRows) + 7 field-level fill-only-if-default merges (VP-P7 concepts).
    // "DXR_VP Migration Status" (table 55347) is the framework's own bookkeeping table and is
    // deliberately excluded from the merge, matching the source's own comment.
    Permissions =
        tabledata "DXR_VP Setup_Old" = R,
        tabledata "DXR_VP Setup" = RIM,
        tabledata "DXR_VP Payload Header_Old" = R,
        tabledata "DXR_VP Payload Header" = RIM,
        tabledata "DXR_VP Payload Journal Lin_Old" = R,
        tabledata "DXR_VP Payload Journal Lines" = RIM,
        tabledata "DXR_VP VendorPay Group_Old" = R,
        tabledata "DXR_VP VendorPay Group" = RIM,
        tabledata "DXR_VP Historic Payload He_Old" = R,
        tabledata "DXR_VP Historic Payload Header" = RIM,
        tabledata "DXR_VP Historic Payload Li_Old" = R,
        tabledata "DXR_VP Historic Payload Lines" = RIM,
        tabledata "DXR_VP Hist VendorPay Grou_Old" = R,
        tabledata "DXR_VP Hist VendorPay Group" = RIM,
        tabledata "DXR_VP Logs_Old" = R,
        tabledata "DXR_VP Logs" = RIM,
        tabledata "DXR_VP Jounal Bank Account_Old" = R,
        tabledata "DXR_VP Jounal Bank Account" = RIM,
        tabledata "DXR_VP Order Item Status_Old" = R,
        tabledata "DXR_VP Order Item Status" = RIM,
        tabledata "DXR_VP Order Status Log_Old" = R,
        tabledata "DXR_VP Order Status Log" = RIM,
        tabledata "DXR_VP Bank_Old" = R,
        tabledata "DXR_VP Bank" = RIM,
        tabledata "DXR_VP Currency Relation_Old" = R,
        tabledata "DXR_VP Currency Relation" = RIM,
        tabledata "DXR_VPCargaMasBeneficiario_Old" = R,
        tabledata DXR_VPCargaMasBeneficiariosBPD = RIM,
        tabledata "DXR_VPHisCargaMasBenefBPD_Old" = R,
        tabledata DXR_VPHisCargaMasBenefBPD = RIM,
        tabledata "DXR_VPHisLineaCargaMasBene_Old" = R,
        tabledata DXR_VPHisLineaCargaMasBenefBPD = RIM,
        tabledata "DXR_VP Hist. Beneficiarios_Old" = R,
        tabledata "DXR_VP Hist. Beneficiarios BPD" = RIM,
        tabledata "DXR_VPLineasCargaMasivaBen_Old" = R,
        tabledata "DXR_VPLineasCargaMasivaBen.BPD" = RIM,
        tabledata "DXR_VP Provincia_Old" = R,
        tabledata "DXR_VP Provincia" = RIM,
        tabledata "DXR_VP API Log Entry_Old" = R,
        tabledata "DXR_VP API Log Entry" = RIM,
        tabledata "DXR_VPOrderNoRelPayment_Old" = R,
        tabledata DXR_VPOrderNoRelPayment = RIM,
        tabledata "DXR_VP Response Log_Old" = R,
        tabledata "DXR_VP Response Log" = RIM,
        tabledata "Bank Account" = RM,
        tabledata "Gen. Journal Line" = RM,
        tabledata "Post Code" = RM,
        tabledata "User Setup" = RM,
        tabledata Vendor = RM,
        tabledata "Vendor Bank Account" = RM,
        tabledata "Purchase Header" = RM,
        tabledata Field = R;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunAccounting();
        RunHistoric();
        RunOther();
    end;

    procedure RunSetup()
    var
        ErrorText: Text;
    begin
        if not MergeVPSetupTable(ErrorText) then
            Error(ErrorText);
        if not MergeVPVendorPayGroupTable(ErrorText) then
            Error(ErrorText);
        if not MergeVPCurrencyRelationTable(ErrorText) then
            Error(ErrorText);
        if not MergeVPProvinciaTable(ErrorText) then
            Error(ErrorText);
    end;

    procedure RunMaster()
    var
        ErrorText: Text;
    begin
        if not MergeTableStep(Database::"DXR_VP Order Item Status_Old", Database::"DXR_VP Order Item Status", 'TBL-ORDER-ITEM-STATUS', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Bank_Old", Database::"DXR_VP Bank", 'TBL-BANK', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPCargaMasBeneficiario_Old", Database::DXR_VPCargaMasBeneficiariosBPD, 'TBL-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPLineasCargaMasivaBen_Old", Database::"DXR_VPLineasCargaMasivaBen.BPD", 'TBL-LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunAccounting()
    var
        ErrorText: Text;
    begin
        if not MergeTableStep(Database::"DXR_VP Payload Header_Old", Database::"DXR_VP Payload Header", 'TBL-PAYLOAD-HEADER', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Payload Journal Lin_Old", Database::"DXR_VP Payload Journal Lines", 'TBL-PAYLOAD-JOURNAL-LINES', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Jounal Bank Account_Old", Database::"DXR_VP Jounal Bank Account", 'TBL-JOURNAL-BANK-ACCOUNT', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPOrderNoRelPayment_Old", Database::DXR_VPOrderNoRelPayment, 'TBL-ORDER-NO-REL-PAYMENT', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunHistoric()
    var
        ErrorText: Text;
    begin
        if not MergeTableStep(Database::"DXR_VP Historic Payload He_Old", Database::"DXR_VP Historic Payload Header", 'TBL-HISTORIC-PAYLOAD-HEADER', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Historic Payload Li_Old", Database::"DXR_VP Historic Payload Lines", 'TBL-HISTORIC-PAYLOAD-LINES', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Hist VendorPay Grou_Old", Database::"DXR_VP Hist VendorPay Group", 'TBL-HIST-VENDORPAY-GROUP', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Logs_Old", Database::"DXR_VP Logs", 'TBL-LOGS', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Order Status Log_Old", Database::"DXR_VP Order Status Log", 'TBL-ORDER-STATUS-LOG', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPHisCargaMasBenefBPD_Old", Database::DXR_VPHisCargaMasBenefBPD, 'TBL-HIS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPHisLineaCargaMasBene_Old", Database::DXR_VPHisLineaCargaMasBenefBPD, 'TBL-HIS-LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Hist. Beneficiarios_Old", Database::"DXR_VP Hist. Beneficiarios BPD", 'TBL-HIST-BENEFICIARIOS-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP API Log Entry_Old", Database::"DXR_VP API Log Entry", 'TBL-API-LOG-ENTRY', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Response Log_Old", Database::"DXR_VP Response Log", 'TBL-RESPONSE-LOG', ErrorText) then
            Error(ErrorText);
    end;

    procedure RunOther()
    begin
        MergeBankAccountFields();
        MergeGenJournalLineFields();
        MergePostCodeFields();
        MergeUserSetupFields();
        MergeVendorFields();
        MergeVendorBankAccountFields();
        MergePurchaseHeaderFields();
    end;

    local procedure MergeTableStep(SourceTableNo: Integer; DestTableNo: Integer; TagSuffix: Text; var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRef: RecordRef;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag(TagSuffix)) then
            exit(true);

        SourceRef.Open(SourceTableNo);
        if SourceRef.Count() = 0 then begin
            SourceRef.Close();
            UpgradeTag.SetUpgradeTag(GetStepTag(TagSuffix));
            exit(true);
        end;
        SourceRef.Close();

        if not TryMergeMissingRows(SourceTableNo, DestTableNo) then begin
            ErrorText := CopyStr(GetLastErrorText(), 1, 2048);
            exit(false);
        end;

        UpgradeTag.SetUpgradeTag(GetStepTag(TagSuffix));
        exit(true);
    end;

    // Never-overwrite/fill-gaps semantics: only rows absent in the destination (by primary key)
    // are inserted; a duplicate-key error from TryInsertRow means "already there", not a failure.
    [TryFunction]
    local procedure TryMergeMissingRows(SourceTableNo: Integer; DestTableNo: Integer)
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
                TryInsertRow(DestRecRef);
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

    [TryFunction]
    local procedure TryInsertRow(var DestRecRef: RecordRef)
    begin
        DestRecRef.Insert(false);
    end;

    // VP-P7 concepts 1/4/13/19 (Category=SETUP): typed, zero-RecordRef, zero-TransferFields
    // replacements for the 4 in-scope table-level merges below. Same never-overwrite/fill-gaps
    // semantics as TryMergeMissingRows (only rows absent in the destination by primary key are
    // inserted), just expressed as a typed Get()-before-Insert() check with EXPLICIT per-field
    // assignment (no TransferFields, no RecordRef/FieldRef of any kind - both banned after a real
    // production "The record is already open." failure traced to RecordRef-heavy code elsewhere
    // in this portfolio). Field layouts independently re-verified 1:1 identical between source and
    // destination for all 4 tables against the real VP source (every field, its type, and the
    // primary key byte-for-byte the same in every case), so every Normal-class field is copied
    // explicitly by name below:
    //   - DXR_VP Setup_Old (55325) / DXR_VP Setup (52684): 51 fields (1-8,14-54,55-57), PK
    //     "Primary Key" - see
    //     .../vendorpayload/DxPayloads-BC/Vendor Payloads/src/Base/Tables.old/DXR_ePagosSetup_Old.Table.al
    //     and .../Tables/DXR_ePagosSetup.Table.al. Field 34 "VP Method Process" is enum
    //     "DXR_VP Method Process" on both sides here, so a plain assignment compiles and is exact.
    //   - DXR_VP VendorPay Group_Old (55328) / DXR_VP VendorPay Group (52691): 29 simple Normal
    //     fields + 3 BLOB Normal fields (NCF/Memo/Remarks, copied via CreateInStream/
    //     CreateOutStream/CopyStream, the documented way to move BLOB content since AL has no
    //     `:=` operator for Blob) + 8 FlowFields deliberately skipped (NetAmount, Amount, Status,
    //     "Qty Inv", OrderStatus, StatusProcess, StatusReject, "NetAmount BPD LCY" - these are
    //     calculated, never stored, and TransferFields itself never copied them either). PK
    //     "Payload No.","Vendor No.",Currency,"VendorPay No." (4 fields, this order) - see
    //     .../Tables.old/DXR_VendorPayGroup_Old.Table.al and .../Tables/DXR_VendorPayGroup.Table.al
    //   - DXR_VP Currency Relation_Old (55337) / DXR_VP Currency Relation (52707): fields 1-3,
    //     PK "Bank Code","Currency Code","Currency External Code" - see
    //     .../Tables.old/DXR_CurrencyRelation_Old.Table.al and .../Tables/DXR_CurrencyRelation.Table.al
    //   - DXR_VP Provincia_Old (55343) / DXR_VP Provincia (52713): fields 1-3, PK "Code" - see
    //     .../Tables.old/DXR_Provincia_Old.Table.al and .../Tables/DXR_Provincia.Table.al
    local procedure MergeVPSetupTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceSetup: Record "DXR_VP Setup_Old";
        DestSetup: Record "DXR_VP Setup";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('TBL-SETUP')) then
            exit(true);

        if not SourceSetup.IsEmpty() then
            if SourceSetup.FindSet() then
                repeat
                    if not DestSetup.Get(SourceSetup."Primary Key") then begin
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
                        DestSetup."VP Method Process" := SourceSetup."VP Method Process";
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
                    end;
                until SourceSetup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('TBL-SETUP'));
        exit(true);
    end;

    local procedure MergeVPVendorPayGroupTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceGroup: Record "DXR_VP VendorPay Group_Old";
        DestGroup: Record "DXR_VP VendorPay Group";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('TBL-VENDORPAY-GROUP')) then
            exit(true);

        if not SourceGroup.IsEmpty() then
            if SourceGroup.FindSet() then
                repeat
                    if not DestGroup.Get(SourceGroup."Payload No.", SourceGroup."Vendor No.", SourceGroup.Currency, SourceGroup."VendorPay No.") then begin
                        DestGroup.Init();
                        DestGroup."Payload No." := SourceGroup."Payload No.";
                        DestGroup."Vendor No." := SourceGroup."Vendor No.";
                        DestGroup.Currency := SourceGroup.Currency;
                        DestGroup."VendorPay No." := SourceGroup."VendorPay No.";
                        DestGroup.Name1 := SourceGroup.Name1;
                        DestGroup.OrderNr := SourceGroup.OrderNr;
                        DestGroup.DocumentClassId := SourceGroup.DocumentClassId;
                        DestGroup.DocumentDate := SourceGroup.DocumentDate;
                        DestGroup.PaymentDate := SourceGroup.PaymentDate;
                        DestGroup.PaymentMethodId := SourceGroup.PaymentMethodId;
                        DestGroup.BankAccountFromKey := SourceGroup.BankAccountFromKey;
                        DestGroup.BankAccountToKey := SourceGroup.BankAccountToKey;
                        DestGroup.IdentityNr := SourceGroup.IdentityNr;
                        DestGroup.IdentityTypeId := SourceGroup.IdentityTypeId;
                        DestGroup."No. Lote" := SourceGroup."No. Lote";
                        DestGroup.Reference := SourceGroup.Reference;
                        DestGroup.Name2 := SourceGroup.Name2;
                        DestGroup.OrderStatusID := SourceGroup.OrderStatusID;
                        DestGroup."Posted Journal" := SourceGroup."Posted Journal";
                        DestGroup.VendorID := SourceGroup.VendorID;
                        DestGroup.Cancelled := SourceGroup.Cancelled;
                        DestGroup."Vendor Invoice No." := SourceGroup."Vendor Invoice No.";
                        DestGroup."Has Error" := SourceGroup."Has Error";
                        DestGroup."Error Message" := SourceGroup."Error Message";
                        DestGroup."Error Code" := SourceGroup."Error Code";
                        DestGroup."Dimension Set ID" := SourceGroup."Dimension Set ID";
                        DestGroup."Shortcut Dimension 1 Code" := SourceGroup."Shortcut Dimension 1 Code";
                        DestGroup."Shortcut Dimension 2 Code" := SourceGroup."Shortcut Dimension 2 Code";
                        DestGroup."External Document No." := SourceGroup."External Document No.";
                        CopyVendorPayGroupBlobFields(SourceGroup, DestGroup);
                        DestGroup.Insert(false);
                    end;
                until SourceGroup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('TBL-VENDORPAY-GROUP'));
        exit(true);
    end;

    // BLOB fields (NCF, Memo, Remarks) have no `:=` assignment operator in AL - the documented way
    // to copy their content is CreateInStream/CreateOutStream + CopyStream.
    local procedure CopyVendorPayGroupBlobFields(var SourceGroup: Record "DXR_VP VendorPay Group_Old"; var DestGroup: Record "DXR_VP VendorPay Group")
    var
        InStr: InStream;
        OutStr: OutStream;
    begin
        SourceGroup.CalcFields(NCF, Memo, Remarks);

        if SourceGroup.NCF.HasValue() then begin
            SourceGroup.NCF.CreateInStream(InStr);
            DestGroup.NCF.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;

        if SourceGroup.Memo.HasValue() then begin
            SourceGroup.Memo.CreateInStream(InStr);
            DestGroup.Memo.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;

        if SourceGroup.Remarks.HasValue() then begin
            SourceGroup.Remarks.CreateInStream(InStr);
            DestGroup.Remarks.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
        end;
    end;

    local procedure MergeVPCurrencyRelationTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceRelation: Record "DXR_VP Currency Relation_Old";
        DestRelation: Record "DXR_VP Currency Relation";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('TBL-CURRENCY-RELATION')) then
            exit(true);

        if not SourceRelation.IsEmpty() then
            if SourceRelation.FindSet() then
                repeat
                    if not DestRelation.Get(SourceRelation."Bank Code", SourceRelation."Currency Code", SourceRelation."Currency External Code") then begin
                        DestRelation.Init();
                        DestRelation."Currency Code" := SourceRelation."Currency Code";
                        DestRelation."Currency External Code" := SourceRelation."Currency External Code";
                        DestRelation."Bank Code" := SourceRelation."Bank Code";
                        DestRelation.Insert(false);
                    end;
                until SourceRelation.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('TBL-CURRENCY-RELATION'));
        exit(true);
    end;

    local procedure MergeVPProvinciaTable(var ErrorText: Text): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SourceProvincia: Record "DXR_VP Provincia_Old";
        DestProvincia: Record "DXR_VP Provincia";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('TBL-PROVINCIA')) then
            exit(true);

        if not SourceProvincia.IsEmpty() then
            if SourceProvincia.FindSet() then
                repeat
                    if not DestProvincia.Get(SourceProvincia.Code) then begin
                        DestProvincia.Init();
                        DestProvincia.Code := SourceProvincia.Code;
                        DestProvincia.Name := SourceProvincia.Name;
                        DestProvincia."Cod. BPD" := SourceProvincia."Cod. BPD";
                        DestProvincia.Insert(false);
                    end;
                until SourceProvincia.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('TBL-PROVINCIA'));
        exit(true);
    end;

    // Fixed 2026-08-27 (A1), applied to all seven FLD-* merges below. These loops used
    // FindSet(true) over a WHOLE base table with no partial-record hint, yet only a small minority
    // of rows ever needs a value copied. Per Learn ("Record.FindSet"), FindSet "will request all
    // rows at once" and with ForUpdate = true reads them "using IsolationLevel::UpdLock (SQL
    // UPDLOCK)" - i.e. an update lock on every row of Vendor / Gen. Journal Line / Purchase Header
    // for the whole run, serializing against every other migration codeunit touching the same
    // tables. Three changes, none of which alter what is migrated:
    //   * SetLoadFields limits the scan to the fields actually read (plus the primary key used for
    //     the Get()), so the companion table of every unrelated tableextension is no longer joined
    //     per row.
    //   * FindSet(false) reads without UPDLOCK; the row is re-read with Get() into a second Record
    //     variable and locked only when it genuinely needs a value copied.
    //   * The commit counter advances per MODIFIED row instead of per scanned row, and the trailing
    //     Commit only fires when there is an uncommitted remainder.
    // The per-field fill-only-if-default guards are unchanged and are re-evaluated on the row that
    // is actually written, exactly as before.
    local procedure MergeBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        BankAccount: Record "Bank Account";
        BankAccountToUpdate: Record "Bank Account";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-BANK-ACCOUNT')) then
            exit;

        BankAccount.SetLoadFields("No.", "VP Account Type_DXR", "VP Account Type_Old");
        if BankAccount.FindSet(false) then
            repeat
                if (BankAccount."VP Account Type_DXR".AsInteger() = 0) and (BankAccount."VP Account Type_Old".AsInteger() <> 0) then
                    if BankAccountToUpdate.Get(BankAccount."No.") then
                        if (BankAccountToUpdate."VP Account Type_DXR".AsInteger() = 0) and (BankAccountToUpdate."VP Account Type_Old".AsInteger() <> 0) then begin
                            BankAccountToUpdate."VP Account Type_DXR" := BankAccountToUpdate."VP Account Type_Old";
                            BankAccountToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
            until BankAccount.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-BANK-ACCOUNT'));
    end;

    local procedure MergeGenJournalLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLineToUpdate: Record "Gen. Journal Line";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-GEN-JOURNAL-LINE')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        GenJournalLine.SetLoadFields(
            "Journal Template Name", "Journal Batch Name", "Line No.",
            "VP From VP_DXR", "VP From VP_Old",
            "VP VendorPay No._DXR", "VP VendorPay No._Old");
        if GenJournalLine.FindSet(false) then
            repeat
                if GenJournalLineNeedsMerge(GenJournalLine) then
                    if GenJournalLineToUpdate.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.") then begin
                        Modified := false;
                        if (not GenJournalLineToUpdate."VP From VP_DXR") and GenJournalLineToUpdate."VP From VP_Old" then begin
                            GenJournalLineToUpdate."VP From VP_DXR" := GenJournalLineToUpdate."VP From VP_Old";
                            Modified := true;
                        end;
                        if (GenJournalLineToUpdate."VP VendorPay No._DXR" = '') and (GenJournalLineToUpdate."VP VendorPay No._Old" <> '') then begin
                            GenJournalLineToUpdate."VP VendorPay No._DXR" := GenJournalLineToUpdate."VP VendorPay No._Old";
                            Modified := true;
                        end;
                        if Modified then begin
                            GenJournalLineToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
                    end;
            until GenJournalLine.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-GEN-JOURNAL-LINE'));
    end;

    local procedure GenJournalLineNeedsMerge(var GenJournalLine: Record "Gen. Journal Line"): Boolean
    begin
        exit(
            ((not GenJournalLine."VP From VP_DXR") and GenJournalLine."VP From VP_Old") or
            ((GenJournalLine."VP VendorPay No._DXR" = '') and (GenJournalLine."VP VendorPay No._Old" <> '')));
    end;

    local procedure MergePostCodeFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostCode: Record "Post Code";
        PostCodeToUpdate: Record "Post Code";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-POST-CODE')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        PostCode.SetLoadFields(Code, City, "VP Cod. Province_DXR", "VP Cod. Province_Old");
        if PostCode.FindSet(false) then
            repeat
                if (PostCode."VP Cod. Province_DXR" = '') and (PostCode."VP Cod. Province_Old" <> '') then
                    if PostCodeToUpdate.Get(PostCode.Code, PostCode.City) then
                        if (PostCodeToUpdate."VP Cod. Province_DXR" = '') and (PostCodeToUpdate."VP Cod. Province_Old" <> '') then begin
                            PostCodeToUpdate."VP Cod. Province_DXR" := PostCodeToUpdate."VP Cod. Province_Old";
                            PostCodeToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
            until PostCode.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-POST-CODE'));
    end;

    local procedure MergeUserSetupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetup: Record "User Setup";
        UserSetupToUpdate: Record "User Setup";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-USER-SETUP')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        UserSetup.SetLoadFields(
            "User ID",
            "VP Amount Approval Limit_DXR", "VP Amount Approval Limit_Old",
            "VP Unlimited VP Approval_DXR", "VP Unlimited VP Approval_Old",
            "VP Approver ID_DXR", "VP Approver ID_Old",
            "VP Approver VP_DXR", "VP Approver VP_Old",
            "VP Reprint TXT_DXR", "VP Reprint TXT_Old",
            "VP Allow Reopen_DXR", "VP Allow Reopen_Old");
        if UserSetup.FindSet(false) then
            repeat
                if UserSetupNeedsMerge(UserSetup) then
                    if UserSetupToUpdate.Get(UserSetup."User ID") then begin
                        Modified := false;
                        if (UserSetupToUpdate."VP Amount Approval Limit_DXR" = 0) and (UserSetupToUpdate."VP Amount Approval Limit_Old" <> 0) then begin
                            UserSetupToUpdate."VP Amount Approval Limit_DXR" := UserSetupToUpdate."VP Amount Approval Limit_Old";
                            Modified := true;
                        end;
                        if (not UserSetupToUpdate."VP Unlimited VP Approval_DXR") and UserSetupToUpdate."VP Unlimited VP Approval_Old" then begin
                            UserSetupToUpdate."VP Unlimited VP Approval_DXR" := UserSetupToUpdate."VP Unlimited VP Approval_Old";
                            Modified := true;
                        end;
                        if (UserSetupToUpdate."VP Approver ID_DXR" = '') and (UserSetupToUpdate."VP Approver ID_Old" <> '') then begin
                            UserSetupToUpdate."VP Approver ID_DXR" := UserSetupToUpdate."VP Approver ID_Old";
                            Modified := true;
                        end;
                        if (not UserSetupToUpdate."VP Approver VP_DXR") and UserSetupToUpdate."VP Approver VP_Old" then begin
                            UserSetupToUpdate."VP Approver VP_DXR" := UserSetupToUpdate."VP Approver VP_Old";
                            Modified := true;
                        end;
                        if (not UserSetupToUpdate."VP Reprint TXT_DXR") and UserSetupToUpdate."VP Reprint TXT_Old" then begin
                            UserSetupToUpdate."VP Reprint TXT_DXR" := UserSetupToUpdate."VP Reprint TXT_Old";
                            Modified := true;
                        end;
                        if (not UserSetupToUpdate."VP Allow Reopen_DXR") and UserSetupToUpdate."VP Allow Reopen_Old" then begin
                            UserSetupToUpdate."VP Allow Reopen_DXR" := UserSetupToUpdate."VP Allow Reopen_Old";
                            Modified := true;
                        end;
                        if Modified then begin
                            UserSetupToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
                    end;
            until UserSetup.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-USER-SETUP'));
    end;

    local procedure UserSetupNeedsMerge(var UserSetup: Record "User Setup"): Boolean
    begin
        exit(
            ((UserSetup."VP Amount Approval Limit_DXR" = 0) and (UserSetup."VP Amount Approval Limit_Old" <> 0)) or
            ((not UserSetup."VP Unlimited VP Approval_DXR") and UserSetup."VP Unlimited VP Approval_Old") or
            ((UserSetup."VP Approver ID_DXR" = '') and (UserSetup."VP Approver ID_Old" <> '')) or
            ((not UserSetup."VP Approver VP_DXR") and UserSetup."VP Approver VP_Old") or
            ((not UserSetup."VP Reprint TXT_DXR") and UserSetup."VP Reprint TXT_Old") or
            ((not UserSetup."VP Allow Reopen_DXR") and UserSetup."VP Allow Reopen_Old"));
    end;

    local procedure MergeVendorFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Vendor: Record Vendor;
        VendorToUpdate: Record Vendor;
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-VENDOR')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        Vendor.SetLoadFields(
            "No.",
            "VP Name BPD_DXR", "VP Name BPD_Old",
            "VP Sent BPD_DXR", "VP Sent BPD_Old",
            "VP Date Sent BPD_DXR", "VP Date Sent BPD_Old",
            "VP Document Type BPD_DXR", "VP Document Type BPD_Old",
            "VP Contract account type_DXR", "VP Contract account type_Old",
            "VP Send BPD_DXR", "VP Send BPD_Old",
            "VP Ident Type BPD_DXR", "VP Ident Type BPD_Old",
            "VPTaxIdentTypeBPD_DXR", "VPTaxIdentTypeBPD_Old",
            "Business Partnert Id 1_DXR", "Business Partnert Id 1_Old",
            "Business Partnert Id 2_DXR", "Business Partnert Id 2_Old");
        if Vendor.FindSet(false) then
            repeat
                if VendorNeedsMerge(Vendor) then
                    if VendorToUpdate.Get(Vendor."No.") then begin
                        Modified := false;
                        if (VendorToUpdate."VP Name BPD_DXR" = '') and (VendorToUpdate."VP Name BPD_Old" <> '') then begin
                            VendorToUpdate."VP Name BPD_DXR" := VendorToUpdate."VP Name BPD_Old";
                            Modified := true;
                        end;
                        if (not VendorToUpdate."VP Sent BPD_DXR") and VendorToUpdate."VP Sent BPD_Old" then begin
                            VendorToUpdate."VP Sent BPD_DXR" := VendorToUpdate."VP Sent BPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."VP Date Sent BPD_DXR" = 0D) and (VendorToUpdate."VP Date Sent BPD_Old" <> 0D) then begin
                            VendorToUpdate."VP Date Sent BPD_DXR" := VendorToUpdate."VP Date Sent BPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."VP Document Type BPD_DXR".AsInteger() = 0) and (VendorToUpdate."VP Document Type BPD_Old".AsInteger() <> 0) then begin
                            VendorToUpdate."VP Document Type BPD_DXR" := VendorToUpdate."VP Document Type BPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."VP Contract account type_DXR".AsInteger() = 0) and (VendorToUpdate."VP Contract account type_Old".AsInteger() <> 0) then begin
                            VendorToUpdate."VP Contract account type_DXR" := VendorToUpdate."VP Contract account type_Old";
                            Modified := true;
                        end;
                        if (not VendorToUpdate."VP Send BPD_DXR") and VendorToUpdate."VP Send BPD_Old" then begin
                            VendorToUpdate."VP Send BPD_DXR" := VendorToUpdate."VP Send BPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."VP Ident Type BPD_DXR".AsInteger() = 0) and (VendorToUpdate."VP Ident Type BPD_Old".AsInteger() <> 0) then begin
                            VendorToUpdate."VP Ident Type BPD_DXR" := VendorToUpdate."VP Ident Type BPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."VPTaxIdentTypeBPD_DXR".AsInteger() = 0) and (VendorToUpdate."VPTaxIdentTypeBPD_Old".AsInteger() <> 0) then begin
                            VendorToUpdate."VPTaxIdentTypeBPD_DXR" := VendorToUpdate."VPTaxIdentTypeBPD_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."Business Partnert Id 1_DXR" = '') and (VendorToUpdate."Business Partnert Id 1_Old" <> '') then begin
                            VendorToUpdate."Business Partnert Id 1_DXR" := VendorToUpdate."Business Partnert Id 1_Old";
                            Modified := true;
                        end;
                        if (VendorToUpdate."Business Partnert Id 2_DXR" = '') and (VendorToUpdate."Business Partnert Id 2_Old" <> '') then begin
                            VendorToUpdate."Business Partnert Id 2_DXR" := VendorToUpdate."Business Partnert Id 2_Old";
                            Modified := true;
                        end;
                        if Modified then begin
                            VendorToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
                    end;
            until Vendor.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-VENDOR'));
    end;

    local procedure VendorNeedsMerge(var Vendor: Record Vendor): Boolean
    begin
        exit(
            ((Vendor."VP Name BPD_DXR" = '') and (Vendor."VP Name BPD_Old" <> '')) or
            ((not Vendor."VP Sent BPD_DXR") and Vendor."VP Sent BPD_Old") or
            ((Vendor."VP Date Sent BPD_DXR" = 0D) and (Vendor."VP Date Sent BPD_Old" <> 0D)) or
            ((Vendor."VP Document Type BPD_DXR".AsInteger() = 0) and (Vendor."VP Document Type BPD_Old".AsInteger() <> 0)) or
            ((Vendor."VP Contract account type_DXR".AsInteger() = 0) and (Vendor."VP Contract account type_Old".AsInteger() <> 0)) or
            ((not Vendor."VP Send BPD_DXR") and Vendor."VP Send BPD_Old") or
            ((Vendor."VP Ident Type BPD_DXR".AsInteger() = 0) and (Vendor."VP Ident Type BPD_Old".AsInteger() <> 0)) or
            ((Vendor."VPTaxIdentTypeBPD_DXR".AsInteger() = 0) and (Vendor."VPTaxIdentTypeBPD_Old".AsInteger() <> 0)) or
            ((Vendor."Business Partnert Id 1_DXR" = '') and (Vendor."Business Partnert Id 1_Old" <> '')) or
            ((Vendor."Business Partnert Id 2_DXR" = '') and (Vendor."Business Partnert Id 2_Old" <> '')));
    end;

    local procedure MergeVendorBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        VendorBankAccount: Record "Vendor Bank Account";
        VendorBankAccToUpdate: Record "Vendor Bank Account";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-VENDOR-BANK-ACCOUNT')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        VendorBankAccount.SetLoadFields(
            "Vendor No.", Code,
            "VP ID Bank_DXR", "VP ID Bank_Old",
            "VP Payment Method Bank_DXR", "VP Payment Method Bank_Old",
            "VP Acc. Type_DXR", "VP Acc. Type_Old",
            "VP Default_DXR", "VP Default_Old",
            "VP ID Type_DXR", "VP ID Type_Old",
            "VP Sent BPD_DXR", "VP Sent BPD_Old",
            "VP Status_DXR", "VP Status_Old",
            "VP Send BPD_DXR", "VP Send BPD_Old",
            "VP Date Sent BPD_DXR", "VP Date Sent BPD_Old",
            "VP Default Currency_DXR", "VP Default Currency_Old");
        if VendorBankAccount.FindSet(false) then
            repeat
                if VendorBankAccountNeedsMerge(VendorBankAccount) then
                    if VendorBankAccToUpdate.Get(VendorBankAccount."Vendor No.", VendorBankAccount.Code) then begin
                        Modified := false;
                        if (VendorBankAccToUpdate."VP ID Bank_DXR" = '') and (VendorBankAccToUpdate."VP ID Bank_Old" <> '') then begin
                            VendorBankAccToUpdate."VP ID Bank_DXR" := VendorBankAccToUpdate."VP ID Bank_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP Payment Method Bank_DXR".AsInteger() = 0) and (VendorBankAccToUpdate."VP Payment Method Bank_Old".AsInteger() <> 0) then begin
                            VendorBankAccToUpdate."VP Payment Method Bank_DXR" := VendorBankAccToUpdate."VP Payment Method Bank_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP Acc. Type_DXR".AsInteger() = 0) and (VendorBankAccToUpdate."VP Acc. Type_Old".AsInteger() <> 0) then begin
                            VendorBankAccToUpdate."VP Acc. Type_DXR" := VendorBankAccToUpdate."VP Acc. Type_Old";
                            Modified := true;
                        end;
                        if (not VendorBankAccToUpdate."VP Default_DXR") and VendorBankAccToUpdate."VP Default_Old" then begin
                            VendorBankAccToUpdate."VP Default_DXR" := VendorBankAccToUpdate."VP Default_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP ID Type_DXR".AsInteger() = 0) and (VendorBankAccToUpdate."VP ID Type_Old".AsInteger() <> 0) then begin
                            VendorBankAccToUpdate."VP ID Type_DXR" := VendorBankAccToUpdate."VP ID Type_Old";
                            Modified := true;
                        end;
                        if (not VendorBankAccToUpdate."VP Sent BPD_DXR") and VendorBankAccToUpdate."VP Sent BPD_Old" then begin
                            VendorBankAccToUpdate."VP Sent BPD_DXR" := VendorBankAccToUpdate."VP Sent BPD_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP Status_DXR".AsInteger() = 0) and (VendorBankAccToUpdate."VP Status_Old".AsInteger() <> 0) then begin
                            VendorBankAccToUpdate."VP Status_DXR" := VendorBankAccToUpdate."VP Status_Old";
                            Modified := true;
                        end;
                        if (not VendorBankAccToUpdate."VP Send BPD_DXR") and VendorBankAccToUpdate."VP Send BPD_Old" then begin
                            VendorBankAccToUpdate."VP Send BPD_DXR" := VendorBankAccToUpdate."VP Send BPD_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP Date Sent BPD_DXR" = 0D) and (VendorBankAccToUpdate."VP Date Sent BPD_Old" <> 0D) then begin
                            VendorBankAccToUpdate."VP Date Sent BPD_DXR" := VendorBankAccToUpdate."VP Date Sent BPD_Old";
                            Modified := true;
                        end;
                        if (VendorBankAccToUpdate."VP Default Currency_DXR" = '') and (VendorBankAccToUpdate."VP Default Currency_Old" <> '') then begin
                            VendorBankAccToUpdate."VP Default Currency_DXR" := VendorBankAccToUpdate."VP Default Currency_Old";
                            Modified := true;
                        end;
                        if Modified then begin
                            VendorBankAccToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
                    end;
            until VendorBankAccount.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-VENDOR-BANK-ACCOUNT'));
    end;

    local procedure VendorBankAccountNeedsMerge(var VendorBankAccount: Record "Vendor Bank Account"): Boolean
    begin
        exit(
            ((VendorBankAccount."VP ID Bank_DXR" = '') and (VendorBankAccount."VP ID Bank_Old" <> '')) or
            ((VendorBankAccount."VP Payment Method Bank_DXR".AsInteger() = 0) and (VendorBankAccount."VP Payment Method Bank_Old".AsInteger() <> 0)) or
            ((VendorBankAccount."VP Acc. Type_DXR".AsInteger() = 0) and (VendorBankAccount."VP Acc. Type_Old".AsInteger() <> 0)) or
            ((not VendorBankAccount."VP Default_DXR") and VendorBankAccount."VP Default_Old") or
            ((VendorBankAccount."VP ID Type_DXR".AsInteger() = 0) and (VendorBankAccount."VP ID Type_Old".AsInteger() <> 0)) or
            ((not VendorBankAccount."VP Sent BPD_DXR") and VendorBankAccount."VP Sent BPD_Old") or
            ((VendorBankAccount."VP Status_DXR".AsInteger() = 0) and (VendorBankAccount."VP Status_Old".AsInteger() <> 0)) or
            ((not VendorBankAccount."VP Send BPD_DXR") and VendorBankAccount."VP Send BPD_Old") or
            ((VendorBankAccount."VP Date Sent BPD_DXR" = 0D) and (VendorBankAccount."VP Date Sent BPD_Old" <> 0D)) or
            ((VendorBankAccount."VP Default Currency_DXR" = '') and (VendorBankAccount."VP Default Currency_Old" <> '')));
    end;

    local procedure MergePurchaseHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderToUpdate: Record "Purchase Header";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-PURCHASE-HEADER')) then
            exit;

        // Fixed 2026-08-27 (A1) - see MergeBankAccountFields above for the full rationale.
        PurchaseHeader.SetLoadFields("Document Type", "No.", VPAmountCredit_DXR, VPAmountCredit_Old);
        if PurchaseHeader.FindSet(false) then
            repeat
                if (PurchaseHeader.VPAmountCredit_DXR = 0) and (PurchaseHeader.VPAmountCredit_Old <> 0) then
                    if PurchaseHeaderToUpdate.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then
                        if (PurchaseHeaderToUpdate.VPAmountCredit_DXR = 0) and (PurchaseHeaderToUpdate.VPAmountCredit_Old <> 0) then begin
                            PurchaseHeaderToUpdate.VPAmountCredit_DXR := PurchaseHeaderToUpdate.VPAmountCredit_Old;
                            PurchaseHeaderToUpdate.Modify(false);
                            CommitBatch(BatchCount);
                        end;
            until PurchaseHeader.Next() = 0;
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-PURCHASE-HEADER'));
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P7-%1-20260820', Suffix), 1, 250));
    end;
}

#endif
