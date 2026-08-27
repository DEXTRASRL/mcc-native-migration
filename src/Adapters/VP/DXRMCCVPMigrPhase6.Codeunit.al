#if not ESCUDEA and not BCDX
codeunit 60120 "DXR MCC VP Migr Phase6"
{
    // Native local migration - ported verbatim from Vendor Payloads' own
    // "DXR_VP Migration Phase6 FldCut".Run() - see "DXR MCC VP Migr Phase1" for the full
    // per-phase-not-per-concept rationale. Tableextension field-to-field cutover on 7 base
    // tables (the single bundled VP-P6 concept row).
    Permissions =
        tabledata "Bank Account" = RM,
        tabledata "Gen. Journal Line" = RM,
        tabledata "Post Code" = RM,
        tabledata "User Setup" = RM,
        tabledata Vendor = RM,
        tabledata "Vendor Bank Account" = RM,
        tabledata "Purchase Header" = RM;

    trigger OnRun()
    begin
        MigrateBankAccountFields();
        MigrateGenJournalLineFields();
        MigratePostCodeFields();
        MigrateUserSetupFields();
        MigrateVendorFields();
        MigrateVendorBankAccountFields();
        MigratePurchaseHeaderFields();
    end;

    local procedure MigrateBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        BankAccount: Record "Bank Account";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('BANK-ACCOUNT')) then
            exit;

        if BankAccount.FindSet(true) then
            repeat
                BankAccount."VP Account Type_DXR" := Enum::"DXR_VP Account Type Bank".FromInteger(BankAccount."VP Account Type".AsInteger());
                BankAccount.Modify(false);
                CommitBatch(BatchCount);
            until BankAccount.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('BANK-ACCOUNT'));
    end;

    local procedure MigrateGenJournalLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        GenJournalLine: Record "Gen. Journal Line";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('GEN-JOURNAL-LINE')) then
            exit;

        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine."VP From VP_DXR" := GenJournalLine."VP From VP";
                GenJournalLine."VP VendorPay No._DXR" := GenJournalLine."VP VendorPay No.";
                GenJournalLine.Modify(false);
                CommitBatch(BatchCount);
            until GenJournalLine.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('GEN-JOURNAL-LINE'));
    end;

    local procedure MigratePostCodeFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostCode: Record "Post Code";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('POST-CODE')) then
            exit;

        if PostCode.FindSet(true) then
            repeat
                PostCode."VP Cod. Province_DXR" := PostCode."VP Cod. Province";
                PostCode.Modify(false);
                CommitBatch(BatchCount);
            until PostCode.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('POST-CODE'));
    end;

    local procedure MigrateUserSetupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetup: Record "User Setup";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('USER-SETUP')) then
            exit;

        if UserSetup.FindSet(true) then
            repeat
                UserSetup."VP Amount Approval Limit_DXR" := UserSetup."VP Amount Approval Limit";
                UserSetup."VP Unlimited VP Approval_DXR" := UserSetup."VP Unlimited VP Approval";
                UserSetup."VP Approver ID_DXR" := UserSetup."VP Approver ID";
                UserSetup."VP Approver VP_DXR" := UserSetup."VP Approver VP";
                UserSetup."VP Reprint TXT_DXR" := UserSetup."VP Reprint TXT";
                UserSetup."VP Allow Reopen_DXR" := UserSetup."VP Allow Reopen";
                UserSetup.Modify(false);
                CommitBatch(BatchCount);
            until UserSetup.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('USER-SETUP'));
    end;

    local procedure MigrateVendorFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Vendor: Record Vendor;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('VENDOR')) then
            exit;

        if Vendor.FindSet(true) then
            repeat
                Vendor."VP Name BPD_DXR" := Vendor."VP Name BPD";
                Vendor."VP Sent BPD_DXR" := Vendor."VP Sent BPD";
                Vendor."VP Date Sent BPD_DXR" := Vendor."VP Date Sent BPD";
                Vendor."VP Document Type BPD_DXR" := Enum::"DXR_VP Document Type".FromInteger(Vendor."VP Document Type BPD".AsInteger());
                Vendor."VP Contract account type_DXR" := Enum::"DXR_VP Contract Account Type".FromInteger(Vendor."VP Contract account type".AsInteger());
                Vendor."VP Send BPD_DXR" := Vendor."VP Send BPD";
                Vendor."VP Ident Type BPD_DXR" := Enum::"DXR_VP ID Types".FromInteger(Vendor."VP Identificaction Type BPD".AsInteger());
                Vendor."VPTaxIdentTypeBPD_DXR" := Enum::"DXR_VP TaxIdentificactionType".FromInteger(Vendor."VPTaxIdentificactionTypeBPD".AsInteger());
                Vendor."Business Partnert Id 1_DXR" := Vendor."Business Partnert Id 1";
                Vendor."Business Partnert Id 2_DXR" := Vendor."Business Partnert Id 2";
                Vendor.Modify(false);
                CommitBatch(BatchCount);
            until Vendor.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('VENDOR'));
    end;

    local procedure MigrateVendorBankAccountFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        VendorBankAccount: Record "Vendor Bank Account";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('VENDOR-BANK-ACCOUNT')) then
            exit;

        if VendorBankAccount.FindSet(true) then
            repeat
                VendorBankAccount."VP ID Bank_DXR" := VendorBankAccount."VP ID Bank";
                VendorBankAccount."VP Payment Method Bank_DXR" := Enum::"DXR_VP Payment Method Bank".FromInteger(VendorBankAccount."VP Payment Method Bank".AsInteger());
                VendorBankAccount."VP Acc. Type_DXR" := Enum::"DXR_VP Account Type Bank".FromInteger(VendorBankAccount."VP Acc. Type".AsInteger());
                VendorBankAccount."VP Default_DXR" := VendorBankAccount."VP Default";
                VendorBankAccount."VP ID Type_DXR" := Enum::"DXR_VP ID Types".FromInteger(VendorBankAccount."VP ID Type".AsInteger());
                VendorBankAccount."VP Sent BPD_DXR" := VendorBankAccount."VP Sent BPD";
                VendorBankAccount."VP Status_DXR" := Enum::"DXR_VP Status Vendor Bank Account".FromInteger(VendorBankAccount."VP Status".AsInteger());
                VendorBankAccount."VP Send BPD_DXR" := VendorBankAccount."VP Send BPD";
                VendorBankAccount."VP Date Sent BPD_DXR" := VendorBankAccount."VP Date Sent BPD";
                VendorBankAccount."VP Default Currency_DXR" := VendorBankAccount."VP Default Currency";
                VendorBankAccount.Modify(false);
                CommitBatch(BatchCount);
            until VendorBankAccount.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('VENDOR-BANK-ACCOUNT'));
    end;

    local procedure MigratePurchaseHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchaseHeader: Record "Purchase Header";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('PURCHASE-HEADER')) then
            exit;

        if PurchaseHeader.FindSet(true) then
            repeat
                PurchaseHeader.VPAmountCredit_DXR := PurchaseHeader.VPAmountCredit;
                PurchaseHeader.Modify(false);
                CommitBatch(BatchCount);
            until PurchaseHeader.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(GetStepTag('PURCHASE-HEADER'));
    end;

    // Row-checkpoint safety for large tenants: commits every BatchSize() rows so a single
    // FindSet(true) loop over a large table (Vendor, Purchase Header, Gen. Journal Line, etc.)
    // never runs as one giant uncommitted transaction. Mirrors "DXR MCC Bellon Migr Phase3"'s
    // PersistChangedRecord/FinishTable pattern, adapted for typed Record variables instead of
    // RecordRef.
    local procedure CommitBatch(var BatchCount: Integer)
    begin
        BatchCount += 1;
        if BatchCount < BatchSize() then
            exit;
        Commit();
        BatchCount := 0;
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure GetStepTag(Suffix: Text): Code[250]
    begin
        exit(CopyStr(StrSubstNo('VP-DXR-MIGR-P6-%1-20260728', Suffix), 1, 250));
    end;
}

#endif
