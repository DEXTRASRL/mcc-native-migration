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
        Blank: Record "Bank Account";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('BANK-ACCOUNT')) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields (A1). FindSet(true) over the whole table without a
        // partial-record hint makes the server join the companion table of every tableextension on
        // "Bank Account" for every row; only these two fields are read/written here.
        BankAccount.SetLoadFields("VP Account Type_DXR", "VP Account Type");
        if BankAccount.FindSet(true) then
            repeat
                // Fixed 2026-08-27 (never-overwrite): unconditional copy - a re-run of this upgrade
                // tag (e.g. per-table upgrade tags with a company already migrated) would blindly
                // overwrite an already-populated _DXR value.
                if BankAccount."VP Account Type_DXR" = Blank."VP Account Type_DXR" then
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

        // Fixed 2026-08-27: added SetLoadFields (A1) - "Gen. Journal Line" is very wide and carries
        // many tableextensions in this portfolio; only these four fields are read/written here.
        GenJournalLine.SetLoadFields("VP From VP_DXR", "VP From VP", "VP VendorPay No._DXR", "VP VendorPay No.");
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

        // Fixed 2026-08-27: added SetLoadFields (A1) - only these two fields are read/written here.
        PostCode.SetLoadFields("VP Cod. Province_DXR", "VP Cod. Province");
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

        // Fixed 2026-08-27: added SetLoadFields (A1) - only these twelve fields are read/written.
        UserSetup.SetLoadFields(
            "VP Amount Approval Limit_DXR", "VP Amount Approval Limit",
            "VP Unlimited VP Approval_DXR", "VP Unlimited VP Approval",
            "VP Approver ID_DXR", "VP Approver ID",
            "VP Approver VP_DXR", "VP Approver VP",
            "VP Reprint TXT_DXR", "VP Reprint TXT",
            "VP Allow Reopen_DXR", "VP Allow Reopen");
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
        Blank: Record Vendor;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetStepTag('VENDOR')) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields (A1) - Vendor is a master table carrying many
        // tableextensions in this portfolio; only these twenty fields are read/written here.
        Vendor.SetLoadFields(
            "VP Name BPD_DXR", "VP Name BPD",
            "VP Sent BPD_DXR", "VP Sent BPD",
            "VP Date Sent BPD_DXR", "VP Date Sent BPD",
            "VP Document Type BPD_DXR", "VP Document Type BPD",
            "VP Contract account type_DXR", "VP Contract account type",
            "VP Send BPD_DXR", "VP Send BPD",
            "VP Ident Type BPD_DXR", "VP Identificaction Type BPD",
            "VPTaxIdentTypeBPD_DXR", "VPTaxIdentificactionTypeBPD",
            "Business Partnert Id 1_DXR", "Business Partnert Id 1",
            "Business Partnert Id 2_DXR", "Business Partnert Id 2");
        if Vendor.FindSet(true) then
            repeat
                // Fixed 2026-08-27 (never-overwrite): unconditional copy - a re-run of this upgrade
                // tag (e.g. per-table upgrade tags with a company already migrated) would blindly
                // overwrite an already-populated _DXR value.
                if Vendor."VP Name BPD_DXR" = Blank."VP Name BPD_DXR" then
                    Vendor."VP Name BPD_DXR" := Vendor."VP Name BPD";
                if Vendor."VP Sent BPD_DXR" = Blank."VP Sent BPD_DXR" then
                    Vendor."VP Sent BPD_DXR" := Vendor."VP Sent BPD";
                if Vendor."VP Date Sent BPD_DXR" = Blank."VP Date Sent BPD_DXR" then
                    Vendor."VP Date Sent BPD_DXR" := Vendor."VP Date Sent BPD";
                if Vendor."VP Document Type BPD_DXR" = Blank."VP Document Type BPD_DXR" then
                    Vendor."VP Document Type BPD_DXR" := Enum::"DXR_VP Document Type".FromInteger(Vendor."VP Document Type BPD".AsInteger());
                if Vendor."VP Contract account type_DXR" = Blank."VP Contract account type_DXR" then
                    Vendor."VP Contract account type_DXR" := Enum::"DXR_VP Contract Account Type".FromInteger(Vendor."VP Contract account type".AsInteger());
                if Vendor."VP Send BPD_DXR" = Blank."VP Send BPD_DXR" then
                    Vendor."VP Send BPD_DXR" := Vendor."VP Send BPD";
                if Vendor."VP Ident Type BPD_DXR" = Blank."VP Ident Type BPD_DXR" then
                    Vendor."VP Ident Type BPD_DXR" := Enum::"DXR_VP ID Types".FromInteger(Vendor."VP Identificaction Type BPD".AsInteger());
                if Vendor."VPTaxIdentTypeBPD_DXR" = Blank."VPTaxIdentTypeBPD_DXR" then
                    Vendor."VPTaxIdentTypeBPD_DXR" := Enum::"DXR_VP TaxIdentificactionType".FromInteger(Vendor."VPTaxIdentificactionTypeBPD".AsInteger());
                if Vendor."Business Partnert Id 1_DXR" = Blank."Business Partnert Id 1_DXR" then
                    Vendor."Business Partnert Id 1_DXR" := Vendor."Business Partnert Id 1";
                if Vendor."Business Partnert Id 2_DXR" = Blank."Business Partnert Id 2_DXR" then
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

        // Fixed 2026-08-27: added SetLoadFields (A1) - only these twenty fields are read/written.
        VendorBankAccount.SetLoadFields(
            "VP ID Bank_DXR", "VP ID Bank",
            "VP Payment Method Bank_DXR", "VP Payment Method Bank",
            "VP Acc. Type_DXR", "VP Acc. Type",
            "VP Default_DXR", "VP Default",
            "VP ID Type_DXR", "VP ID Type",
            "VP Sent BPD_DXR", "VP Sent BPD",
            "VP Status_DXR", "VP Status",
            "VP Send BPD_DXR", "VP Send BPD",
            "VP Date Sent BPD_DXR", "VP Date Sent BPD",
            "VP Default Currency_DXR", "VP Default Currency");
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

        // Fixed 2026-08-27: added SetLoadFields (A1) - "Purchase Header" carries many
        // tableextensions in this portfolio; only these two fields are read/written here.
        PurchaseHeader.SetLoadFields(VPAmountCredit_DXR, VPAmountCredit);
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
