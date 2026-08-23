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
    var
        ErrorText: Text;
    begin
        if not MergeTableStep(Database::"DXR_VP Setup_Old", Database::"DXR_VP Setup", 'TBL-SETUP', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Payload Header_Old", Database::"DXR_VP Payload Header", 'TBL-PAYLOAD-HEADER', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Payload Journal Lin_Old", Database::"DXR_VP Payload Journal Lines", 'TBL-PAYLOAD-JOURNAL-LINES', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP VendorPay Group_Old", Database::"DXR_VP VendorPay Group", 'TBL-VENDORPAY-GROUP', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Historic Payload He_Old", Database::"DXR_VP Historic Payload Header", 'TBL-HISTORIC-PAYLOAD-HEADER', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Historic Payload Li_Old", Database::"DXR_VP Historic Payload Lines", 'TBL-HISTORIC-PAYLOAD-LINES', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Hist VendorPay Grou_Old", Database::"DXR_VP Hist VendorPay Group", 'TBL-HIST-VENDORPAY-GROUP', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Logs_Old", Database::"DXR_VP Logs", 'TBL-LOGS', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Jounal Bank Account_Old", Database::"DXR_VP Jounal Bank Account", 'TBL-JOURNAL-BANK-ACCOUNT', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Order Item Status_Old", Database::"DXR_VP Order Item Status", 'TBL-ORDER-ITEM-STATUS', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Order Status Log_Old", Database::"DXR_VP Order Status Log", 'TBL-ORDER-STATUS-LOG', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Bank_Old", Database::"DXR_VP Bank", 'TBL-BANK', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Currency Relation_Old", Database::"DXR_VP Currency Relation", 'TBL-CURRENCY-RELATION', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPCargaMasBeneficiario_Old", Database::DXR_VPCargaMasBeneficiariosBPD, 'TBL-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPHisCargaMasBenefBPD_Old", Database::DXR_VPHisCargaMasBenefBPD, 'TBL-HIS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPHisLineaCargaMasBene_Old", Database::DXR_VPHisLineaCargaMasBenefBPD, 'TBL-HIS-LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Hist. Beneficiarios_Old", Database::"DXR_VP Hist. Beneficiarios BPD", 'TBL-HIST-BENEFICIARIOS-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPLineasCargaMasivaBen_Old", Database::"DXR_VPLineasCargaMasivaBen.BPD", 'TBL-LINEAS-CARGA-MASIVA-BENEF-BPD', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Provincia_Old", Database::"DXR_VP Provincia", 'TBL-PROVINCIA', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP API Log Entry_Old", Database::"DXR_VP API Log Entry", 'TBL-API-LOG-ENTRY', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VPOrderNoRelPayment_Old", Database::DXR_VPOrderNoRelPayment, 'TBL-ORDER-NO-REL-PAYMENT', ErrorText) then
            Error(ErrorText);
        if not MergeTableStep(Database::"DXR_VP Response Log_Old", Database::"DXR_VP Response Log", 'TBL-RESPONSE-LOG', ErrorText) then
            Error(ErrorText);

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
                        if DestFieldRef.Class = FieldClass::Normal then
                            DestFieldRef.Value := SourceFieldRef.Value;
                    end;
                TryInsertRow(DestRecRef);
                DestRecRef.Close();
            until SourceRecRef.Next() = 0;
        SourceRecRef.Close();
    end;

    [TryFunction]
    local procedure TryInsertRow(var DestRecRef: RecordRef)
    begin
        DestRecRef.Insert(false);
    end;

    local procedure MergeBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        BankAccount: Record "Bank Account";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-BANK-ACCOUNT')) then
            exit;

        if BankAccount.FindSet(true) then
            repeat
                if (BankAccount."VP Account Type_DXR".AsInteger() = 0) and (BankAccount."VP Account Type_Old".AsInteger() <> 0) then begin
                    BankAccount."VP Account Type_DXR" := BankAccount."VP Account Type_Old";
                    BankAccount.Modify(false);
                end;
            until BankAccount.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-BANK-ACCOUNT'));
    end;

    local procedure MergeGenJournalLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        GenJournalLine: Record "Gen. Journal Line";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-GEN-JOURNAL-LINE')) then
            exit;

        if GenJournalLine.FindSet(true) then
            repeat
                Modified := false;
                if (not GenJournalLine."VP From VP_DXR") and GenJournalLine."VP From VP_Old" then begin
                    GenJournalLine."VP From VP_DXR" := GenJournalLine."VP From VP_Old";
                    Modified := true;
                end;
                if (GenJournalLine."VP VendorPay No._DXR" = '') and (GenJournalLine."VP VendorPay No._Old" <> '') then begin
                    GenJournalLine."VP VendorPay No._DXR" := GenJournalLine."VP VendorPay No._Old";
                    Modified := true;
                end;
                if Modified then
                    GenJournalLine.Modify(false);
            until GenJournalLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-GEN-JOURNAL-LINE'));
    end;

    local procedure MergePostCodeFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostCode: Record "Post Code";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-POST-CODE')) then
            exit;

        if PostCode.FindSet(true) then
            repeat
                Modified := false;
                if (PostCode."VP Cod. Province_DXR" = '') and (PostCode."VP Cod. Province_Old" <> '') then begin
                    PostCode."VP Cod. Province_DXR" := PostCode."VP Cod. Province_Old";
                    Modified := true;
                end;
                if Modified then
                    PostCode.Modify(false);
            until PostCode.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-POST-CODE'));
    end;

    local procedure MergeUserSetupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetup: Record "User Setup";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-USER-SETUP')) then
            exit;

        if UserSetup.FindSet(true) then
            repeat
                Modified := false;
                if (UserSetup."VP Amount Approval Limit_DXR" = 0) and (UserSetup."VP Amount Approval Limit_Old" <> 0) then begin
                    UserSetup."VP Amount Approval Limit_DXR" := UserSetup."VP Amount Approval Limit_Old";
                    Modified := true;
                end;
                if (not UserSetup."VP Unlimited VP Approval_DXR") and UserSetup."VP Unlimited VP Approval_Old" then begin
                    UserSetup."VP Unlimited VP Approval_DXR" := UserSetup."VP Unlimited VP Approval_Old";
                    Modified := true;
                end;
                if (UserSetup."VP Approver ID_DXR" = '') and (UserSetup."VP Approver ID_Old" <> '') then begin
                    UserSetup."VP Approver ID_DXR" := UserSetup."VP Approver ID_Old";
                    Modified := true;
                end;
                if (not UserSetup."VP Approver VP_DXR") and UserSetup."VP Approver VP_Old" then begin
                    UserSetup."VP Approver VP_DXR" := UserSetup."VP Approver VP_Old";
                    Modified := true;
                end;
                if (not UserSetup."VP Reprint TXT_DXR") and UserSetup."VP Reprint TXT_Old" then begin
                    UserSetup."VP Reprint TXT_DXR" := UserSetup."VP Reprint TXT_Old";
                    Modified := true;
                end;
                if (not UserSetup."VP Allow Reopen_DXR") and UserSetup."VP Allow Reopen_Old" then begin
                    UserSetup."VP Allow Reopen_DXR" := UserSetup."VP Allow Reopen_Old";
                    Modified := true;
                end;
                if Modified then
                    UserSetup.Modify(false);
            until UserSetup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-USER-SETUP'));
    end;

    local procedure MergeVendorFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Vendor: Record Vendor;
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-VENDOR')) then
            exit;

        if Vendor.FindSet(true) then
            repeat
                Modified := false;
                if (Vendor."VP Name BPD_DXR" = '') and (Vendor."VP Name BPD_Old" <> '') then begin
                    Vendor."VP Name BPD_DXR" := Vendor."VP Name BPD_Old";
                    Modified := true;
                end;
                if (not Vendor."VP Sent BPD_DXR") and Vendor."VP Sent BPD_Old" then begin
                    Vendor."VP Sent BPD_DXR" := Vendor."VP Sent BPD_Old";
                    Modified := true;
                end;
                if (Vendor."VP Date Sent BPD_DXR" = 0D) and (Vendor."VP Date Sent BPD_Old" <> 0D) then begin
                    Vendor."VP Date Sent BPD_DXR" := Vendor."VP Date Sent BPD_Old";
                    Modified := true;
                end;
                if (Vendor."VP Document Type BPD_DXR".AsInteger() = 0) and (Vendor."VP Document Type BPD_Old".AsInteger() <> 0) then begin
                    Vendor."VP Document Type BPD_DXR" := Vendor."VP Document Type BPD_Old";
                    Modified := true;
                end;
                if (Vendor."VP Contract account type_DXR".AsInteger() = 0) and (Vendor."VP Contract account type_Old".AsInteger() <> 0) then begin
                    Vendor."VP Contract account type_DXR" := Vendor."VP Contract account type_Old";
                    Modified := true;
                end;
                if (not Vendor."VP Send BPD_DXR") and Vendor."VP Send BPD_Old" then begin
                    Vendor."VP Send BPD_DXR" := Vendor."VP Send BPD_Old";
                    Modified := true;
                end;
                if (Vendor."VP Ident Type BPD_DXR".AsInteger() = 0) and (Vendor."VP Ident Type BPD_Old".AsInteger() <> 0) then begin
                    Vendor."VP Ident Type BPD_DXR" := Vendor."VP Ident Type BPD_Old";
                    Modified := true;
                end;
                if (Vendor."VPTaxIdentTypeBPD_DXR".AsInteger() = 0) and (Vendor."VPTaxIdentTypeBPD_Old".AsInteger() <> 0) then begin
                    Vendor."VPTaxIdentTypeBPD_DXR" := Vendor."VPTaxIdentTypeBPD_Old";
                    Modified := true;
                end;
                if (Vendor."Business Partnert Id 1_DXR" = '') and (Vendor."Business Partnert Id 1_Old" <> '') then begin
                    Vendor."Business Partnert Id 1_DXR" := Vendor."Business Partnert Id 1_Old";
                    Modified := true;
                end;
                if (Vendor."Business Partnert Id 2_DXR" = '') and (Vendor."Business Partnert Id 2_Old" <> '') then begin
                    Vendor."Business Partnert Id 2_DXR" := Vendor."Business Partnert Id 2_Old";
                    Modified := true;
                end;
                if Modified then
                    Vendor.Modify(false);
            until Vendor.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-VENDOR'));
    end;

    local procedure MergeVendorBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        VendorBankAccount: Record "Vendor Bank Account";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-VENDOR-BANK-ACCOUNT')) then
            exit;

        if VendorBankAccount.FindSet(true) then
            repeat
                Modified := false;
                if (VendorBankAccount."VP ID Bank_DXR" = '') and (VendorBankAccount."VP ID Bank_Old" <> '') then begin
                    VendorBankAccount."VP ID Bank_DXR" := VendorBankAccount."VP ID Bank_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP Payment Method Bank_DXR".AsInteger() = 0) and (VendorBankAccount."VP Payment Method Bank_Old".AsInteger() <> 0) then begin
                    VendorBankAccount."VP Payment Method Bank_DXR" := VendorBankAccount."VP Payment Method Bank_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP Acc. Type_DXR".AsInteger() = 0) and (VendorBankAccount."VP Acc. Type_Old".AsInteger() <> 0) then begin
                    VendorBankAccount."VP Acc. Type_DXR" := VendorBankAccount."VP Acc. Type_Old";
                    Modified := true;
                end;
                if (not VendorBankAccount."VP Default_DXR") and VendorBankAccount."VP Default_Old" then begin
                    VendorBankAccount."VP Default_DXR" := VendorBankAccount."VP Default_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP ID Type_DXR".AsInteger() = 0) and (VendorBankAccount."VP ID Type_Old".AsInteger() <> 0) then begin
                    VendorBankAccount."VP ID Type_DXR" := VendorBankAccount."VP ID Type_Old";
                    Modified := true;
                end;
                if (not VendorBankAccount."VP Sent BPD_DXR") and VendorBankAccount."VP Sent BPD_Old" then begin
                    VendorBankAccount."VP Sent BPD_DXR" := VendorBankAccount."VP Sent BPD_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP Status_DXR".AsInteger() = 0) and (VendorBankAccount."VP Status_Old".AsInteger() <> 0) then begin
                    VendorBankAccount."VP Status_DXR" := VendorBankAccount."VP Status_Old";
                    Modified := true;
                end;
                if (not VendorBankAccount."VP Send BPD_DXR") and VendorBankAccount."VP Send BPD_Old" then begin
                    VendorBankAccount."VP Send BPD_DXR" := VendorBankAccount."VP Send BPD_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP Date Sent BPD_DXR" = 0D) and (VendorBankAccount."VP Date Sent BPD_Old" <> 0D) then begin
                    VendorBankAccount."VP Date Sent BPD_DXR" := VendorBankAccount."VP Date Sent BPD_Old";
                    Modified := true;
                end;
                if (VendorBankAccount."VP Default Currency_DXR" = '') and (VendorBankAccount."VP Default Currency_Old" <> '') then begin
                    VendorBankAccount."VP Default Currency_DXR" := VendorBankAccount."VP Default Currency_Old";
                    Modified := true;
                end;
                if Modified then
                    VendorBankAccount.Modify(false);
            until VendorBankAccount.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-VENDOR-BANK-ACCOUNT'));
    end;

    local procedure MergePurchaseHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchaseHeader: Record "Purchase Header";
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('FLD-PURCHASE-HEADER')) then
            exit;

        if PurchaseHeader.FindSet(true) then
            repeat
                if (PurchaseHeader.VPAmountCredit_DXR = 0) and (PurchaseHeader.VPAmountCredit_Old <> 0) then begin
                    PurchaseHeader.VPAmountCredit_DXR := PurchaseHeader.VPAmountCredit_Old;
                    PurchaseHeader.Modify(false);
                end;
            until PurchaseHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetStepTag('FLD-PURCHASE-HEADER'));
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P7-%1-20260820', Suffix), 1, 250));
    end;
}
