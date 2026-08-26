// DRAFT - NOT YET ENABLED. Reviewed against "Dextra_Reportes Operativos_28.4.0.3.app" (fallback
// 28.3.0.1 not needed - the 28.4 symbol table already had everything below). Adapter code: RO.
// App ID: e02aa60f-28f3-4d39-ad95-16f2904b29a6.
//
// SCOPE FOUND: Reportes Operativos is almost entirely reporting/UI (Reports, PageExtensions,
// ReportExtensions) - it owns exactly ONE renumbered table pair and a handful of renumbered
// fields added via table extensions on core BC tables. No Access = Internal objects were found
// anywhere in this extension's own Tables/TableExtensions, so no app.json internalsVisibleTo
// change is needed for this adapter (unlike TU/DRLOC).
//
// TABLE PAIR:
//   51200 "DX Report Configuration" (OLD) -> 51261 "DXR_Report Configuration" (NEW)
//   Field-for-field identical: 1 Primary Key Code[10], 2 Show Approval Signatures Boolean,
//   3 Last Modified By Code[50], 4 Last Modified Date DateTime, 5 Enable Job Ledger Entries Rep
//   Boolean, 9 EF QR Testing Boolean, 10 Test RNC Contribuyente Text[20], 11 Test NCF Text[19],
//   12 Test RNC Comprador Text[20], 13 Test Codigo Seguridad Text[100], 14 Test Fecha Estampado
//   DateTime, 15 Test Fecha Emision Date, 16 Test Monto Total Decimal. Singleton setup table
//   (Primary Key Code[10], expect at most one row, typically blank code).
//
// RENAMED-FIELD PAIRS (all added via TableExtensions onto core BC tables, same table on both
// sides - these are "_DXR"-suffixed replacements of differently-prefixed originals, not separate
// legacy tables):
//   "Payment Method" (base table):       51250 "DX Type"                 -> 51268 "DX Type_DXR" (Enum "DX Payment Method Type" 51250, unchanged both sides)
//   "Bank Account Ledger Entry":         51251 "DX Payment Method Type"  -> 51263 "DX Payment Method Type_DXR" (same enum)
//   "Cust. Ledger Entry":                51256 "DX Payment Method Type"  -> 51264 "DX Payment Method Type_DXR" (same enum)
//   "Gen. Journal Line":                 51252 "DX Payment Method Type"  -> 51266 "DX Payment Method Type_DXR" (same enum)
//   "G/L Entry":                         51254 "DX Payment Method Type"  -> 51265 "DX Payment Method Type_DXR" (same enum)
//   "Vendor Ledger Entry":               51255 "DX Payment Method Type"  -> 51267 "DX Payment Method Type_DXR" (same enum)
//   "Sales Header":                      51200 "DX Work Description" (Blob) -> 51272 "Work Description_DXR" (Blob)
//   "User Setup":                        51201 "DXFirma Encargado" (Blob, Subtype=Bitmap) -> 51269 "Firma Encargado_DXR" (Blob, Subtype=Bitmap)
//                                        51202 "DXCargo" (Text[100])         -> 51270 "Cargo_DXR" (Text[100])
//                                        51203 "DXNombre Archivo" (Text[100]) -> 51271 "Nombre Archivo_DXR" (Text[100])
//
// All of the above were confirmed directly against the 28.4.0.3 symbol table (TableExtensions
// section); every OLD/NEW field pair has matching type/subtype on both sides, so plain typed
// assignment is used (no TransferFields, no RecordRef/FieldRef).
//
// PROPOSED REGISTRY ENTRIES (human to add to src/DXRMCCRegistryLoader.Codeunit.al - NOT edited
// here):
//
//   InsExt('RO', 'Reportes Operativos', 'e02aa60f-28f3-4d39-ad95-16f2904b29a6', 1000,
//       'Reporting-only extension (Reports/PageExtensions/ReportExtensions) - only one owned
//       table pair (DX/DXR_ Report Configuration) plus 8 renamed fields added via table
//       extensions on core BC tables (Payment Method, 5 ledger-entry tables, Sales Header, User
//       Setup). No Access = Internal objects found; no internalsVisibleTo change needed.');
//
//   InsConcept('RO', 'RO-P1', 1, 'DX Report Configuration legacy table restore (51200 -> 51261)', 60610, 51200, 51261, 'SETUP');
//   InsConcept('RO', 'RO-P1', 2, 'Payment Method: DX Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 3, 'Bank Account Ledger Entry: DX Payment Method Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 4, 'Cust. Ledger Entry: DX Payment Method Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 5, 'Gen. Journal Line: DX Payment Method Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 6, 'G/L Entry: DX Payment Method Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 7, 'Vendor Ledger Entry: DX Payment Method Type field restore', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 8, 'Sales Header: DX Work Description field restore (Blob)', 60610, 0, 0, 'MA');
//   InsConcept('RO', 'RO-P1', 9, 'User Setup: Firma Encargado/Cargo/Nombre Archivo field restore (2 Text + 1 Blob)', 60610, 0, 0, 'MA');
//
// TODO(human review): confirm none of these 8 tables/fields are actually populated by a THIRD
// generation (an "_Old2" style table or a "Gen2" source) the way TU had - the 28.4.0.3 symbol
// table showed no such objects for RO, but only the newer .app was inspected in depth; re-check
// against 28.3.0.1 if a discrepancy is suspected.
// TODO(human review): "Primary Key" on 51200/51261 suggests a true singleton setup table - verify
// there is normally at most one row before assuming FindSet()/Insert() loop below is safe/adequate
// (matches the TU Setup pattern, which also loops even though TU Setup is effectively singleton).


codeunit 60610 "DXR MCC RO Migr Dispatcher"
{
    Permissions =
        tabledata "DX Report Configuration" = R,
        tabledata "DXR_Report Configuration" = RIM,
        tabledata "Payment Method" = RM,
        tabledata "Bank Account Ledger Entry" = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata "Gen. Journal Line" = RM,
        tabledata "G/L Entry" = RM,
        tabledata "Vendor Ledger Entry" = RM,
        tabledata "Sales Header" = RM,
        tabledata "User Setup" = RM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
    end;

    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(ReportConfigMigrationTag()) then begin
            MigrateReportConfiguration();
            UpgradeTag.SetUpgradeTag(ReportConfigMigrationTag());
        end;
    end;

    // Grouped under "Master" the way TU groups its cross-table field restores under RunMaster -
    // these are all field-level restores on core BC tables, no dedicated Accounting/Master split
    // documented by RO itself, so category MA (Master/Accounting) is used for all of them,
    // matching DRLOC's own convention for this kind of bulk field restore.
    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(PaymentMethodFieldMigrationTag()) then begin
            MigratePaymentMethodField();
            UpgradeTag.SetUpgradeTag(PaymentMethodFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BankAccountLedgerEntryFieldMigrationTag()) then begin
            MigrateBankAccountLedgerEntryField();
            UpgradeTag.SetUpgradeTag(BankAccountLedgerEntryFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(CustLedgerEntryFieldMigrationTag()) then begin
            MigrateCustLedgerEntryField();
            UpgradeTag.SetUpgradeTag(CustLedgerEntryFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GenJournalLineFieldMigrationTag()) then begin
            MigrateGenJournalLineField();
            UpgradeTag.SetUpgradeTag(GenJournalLineFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(GLEntryFieldMigrationTag()) then begin
            MigrateGLEntryField();
            UpgradeTag.SetUpgradeTag(GLEntryFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(VendorLedgerEntryFieldMigrationTag()) then begin
            MigrateVendorLedgerEntryField();
            UpgradeTag.SetUpgradeTag(VendorLedgerEntryFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(SalesHeaderFieldMigrationTag()) then begin
            MigrateSalesHeaderField();
            UpgradeTag.SetUpgradeTag(SalesHeaderFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(UserSetupFieldMigrationTag()) then begin
            MigrateUserSetupFields();
            UpgradeTag.SetUpgradeTag(UserSetupFieldMigrationTag());
        end;
    end;

    // 51200 "DX Report Configuration" -> 51261 "DXR_Report Configuration": field-for-field
    // identical (same IDs/names/types on both sides, confirmed against the 28.4.0.3 symbol
    // table). No FlowFields present on either side.
    local procedure MigrateReportConfiguration()
    var
        OldConfig: Record "DX Report Configuration";
        NewConfig: Record "DXR_Report Configuration";
    begin
        if OldConfig.FindSet() then
            repeat
                if not NewConfig.Get(OldConfig."Primary Key") then begin
                    NewConfig.Init();
                    NewConfig."Primary Key" := OldConfig."Primary Key";
                    NewConfig."Show Approval Signatures" := OldConfig."Show Approval Signatures";
                    NewConfig."Last Modified By" := OldConfig."Last Modified By";
                    NewConfig."Last Modified Date" := OldConfig."Last Modified Date";
                    NewConfig."Enable Job Ledger Entries Rep" := OldConfig."Enable Job Ledger Entries Rep";
                    NewConfig."EF QR Testing" := OldConfig."EF QR Testing";
                    NewConfig."Test RNC Contribuyente" := OldConfig."Test RNC Contribuyente";
                    NewConfig."Test NCF" := OldConfig."Test NCF";
                    NewConfig."Test RNC Comprador" := OldConfig."Test RNC Comprador";
                    NewConfig."Test Codigo Seguridad" := OldConfig."Test Codigo Seguridad";
                    NewConfig."Test Fecha Estampado" := OldConfig."Test Fecha Estampado";
                    NewConfig."Test Fecha Emision" := OldConfig."Test Fecha Emision";
                    NewConfig."Test Monto Total" := OldConfig."Test Monto Total";
                    NewConfig.Insert(false);
                end;
            until OldConfig.Next() = 0;
    end;

    // Same table on both sides ("Payment Method" is a core BC table) - "DX Type" (51250) ->
    // "DX Type_DXR" (51268), both Enum "DX Payment Method Type" (51250), so this is a plain
    // in-place field copy, not a table restore.
    local procedure MigratePaymentMethodField()
    var
        PaymentMethod: Record "Payment Method";
    begin
        if PaymentMethod.FindSet(true) then
            repeat
                PaymentMethod."DX Type_DXR" := PaymentMethod."DX Type";
                PaymentMethod.Modify(false);
            until PaymentMethod.Next() = 0;
    end;

    local procedure MigrateBankAccountLedgerEntryField()
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        if BankAccountLedgerEntry.FindSet(true) then
            repeat
                BankAccountLedgerEntry."DX Payment Method Type_DXR" := BankAccountLedgerEntry."DX Payment Method Type";
                BankAccountLedgerEntry.Modify(false);
            until BankAccountLedgerEntry.Next() = 0;
    end;

    local procedure MigrateCustLedgerEntryField()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.FindSet(true) then
            repeat
                CustLedgerEntry."DX Payment Method Type_DXR" := CustLedgerEntry."DX Payment Method Type";
                CustLedgerEntry.Modify(false);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure MigrateGenJournalLineField()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine."DX Payment Method Type_DXR" := GenJournalLine."DX Payment Method Type";
                GenJournalLine.Modify(false);
            until GenJournalLine.Next() = 0;
    end;

    local procedure MigrateGLEntryField()
    var
        GLEntry: Record "G/L Entry";
    begin
        if GLEntry.FindSet(true) then
            repeat
                GLEntry."DX Payment Method Type_DXR" := GLEntry."DX Payment Method Type";
                GLEntry.Modify(false);
            until GLEntry.Next() = 0;
    end;

    local procedure MigrateVendorLedgerEntryField()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        if VendorLedgerEntry.FindSet(true) then
            repeat
                VendorLedgerEntry."DX Payment Method Type_DXR" := VendorLedgerEntry."DX Payment Method Type";
                VendorLedgerEntry.Modify(false);
            until VendorLedgerEntry.Next() = 0;
    end;

    // Both "DX Work Description" (51200) and "Work Description_DXR" (51272) are Blob fields on
    // "Sales Header" - Blob fields are not auto-loaded, so CalcFields is required on the old
    // field before the direct assignment (a Blob field behaves like a normal typed variable once
    // loaded; no RecordRef/FieldRef needed).
    local procedure MigrateSalesHeaderField()
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader.CalcFields("DX Work Description");
                SalesHeader."Work Description_DXR" := SalesHeader."DX Work Description";
                SalesHeader.Modify(false);
            until SalesHeader.Next() = 0;
    end;

    // "User Setup": 2 Text[100] fields (plain copy) + 1 Blob/Bitmap field (needs CalcFields
    // first, same reasoning as Sales Header above).
    local procedure MigrateUserSetupFields()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.FindSet(true) then
            repeat
                UserSetup.CalcFields("DXFirma Encargado");
                UserSetup."Firma Encargado_DXR" := UserSetup."DXFirma Encargado";
                UserSetup."Cargo_DXR" := UserSetup.DXCargo;
                UserSetup."Nombre Archivo_DXR" := UserSetup."DXNombre Archivo";
                UserSetup.Modify(false);
            until UserSetup.Next() = 0;
    end;

    local procedure ReportConfigMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-SETUP-REPORTCONFIG-GEN0-20260826.');
    end;

    local procedure PaymentMethodFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-PAYMENTMETHOD-GEN0-20260826.');
    end;

    local procedure BankAccountLedgerEntryFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-BANKACCLEDGENTRY-GEN0-20260826.');
    end;

    local procedure CustLedgerEntryFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-CUSTLEDGENTRY-GEN0-20260826.');
    end;

    local procedure GenJournalLineFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-GENJNLLINE-GEN0-20260826.');
    end;

    local procedure GLEntryFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-GLENTRY-GEN0-20260826.');
    end;

    local procedure VendorLedgerEntryFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-VENDLEDGENTRY-GEN0-20260826.');
    end;

    local procedure SalesHeaderFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-SALESHEADER-GEN0-20260826.');
    end;

    local procedure UserSetupFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-USERSETUP-GEN0-20260826.');
    end;
}
