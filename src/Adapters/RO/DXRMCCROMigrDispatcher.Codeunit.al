// DRAFT - NOT YET ENABLED. Reviewed against "Dextra_Reportes Operativos_28.4.0.3.app" from an
// earlier branch snapshot of .alpackages - Reportes Operativos is NOT a dependency of the current
// app.json and its .app is not currently present in .alpackages, so this draft could not be
// re-verified against this branch's exact build. Re-run the extraction below against the current
// .app before enabling if/when Reportes Operativos becomes a dependency again:
//   $bytes = [System.IO.File]::ReadAllBytes(".alpackages\Dextra_Reportes Operativos_*.app")
//   (skip to the first PK\x03\x04 signature, unzip, read SymbolReference.json)
// Adapter code: RO. App ID: e02aa60f-28f3-4d39-ad95-16f2904b29a6.
//
// SCOPE FOUND (as of the 28.4.0.3 build): Reportes Operativos is almost entirely reporting/UI
// (Reports, PageExtensions, ReportExtensions) - it owns exactly ONE renumbered table pair and a
// handful of renumbered fields added via table extensions on core BC tables. No Access = Internal
// objects were found anywhere in this extension's own Tables/TableExtensions, so no app.json
// internalsVisibleTo change was needed for this adapter.
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
// PROPOSED REGISTRY ENTRIES (human to add to src/DXRMCCRegistryLoader.Codeunit.al - NOT edited
// here):
//   InsExt('RO', 'Reportes Operativos', 'e02aa60f-28f3-4d39-ad95-16f2904b29a6', 1000,
//       'Draft adapter, pending review (src/Adapters/RO). NOT a dependency of this branch''s
//       app.json - .app not present in current .alpackages, re-verify before enabling.');
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
        if not UpgradeTag.HasUpgradeTag(ReportConfigTag()) then begin
            MigrateReportConfiguration();
            UpgradeTag.SetUpgradeTag(ReportConfigTag());
        end;
    end;

    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(PaymentMethodTag()) then begin
            MigratePaymentMethod();
            UpgradeTag.SetUpgradeTag(PaymentMethodTag());
        end;
        if not UpgradeTag.HasUpgradeTag(BankAccountLedgerEntryTag()) then begin
            MigrateBankAccountLedgerEntry();
            UpgradeTag.SetUpgradeTag(BankAccountLedgerEntryTag());
        end;
        if not UpgradeTag.HasUpgradeTag(CustLedgerEntryTag()) then begin
            MigrateCustLedgerEntry();
            UpgradeTag.SetUpgradeTag(CustLedgerEntryTag());
        end;
        if not UpgradeTag.HasUpgradeTag(GenJournalLineTag()) then begin
            MigrateGenJournalLine();
            UpgradeTag.SetUpgradeTag(GenJournalLineTag());
        end;
        if not UpgradeTag.HasUpgradeTag(GLEntryTag()) then begin
            MigrateGLEntry();
            UpgradeTag.SetUpgradeTag(GLEntryTag());
        end;
        if not UpgradeTag.HasUpgradeTag(VendorLedgerEntryTag()) then begin
            MigrateVendorLedgerEntry();
            UpgradeTag.SetUpgradeTag(VendorLedgerEntryTag());
        end;
        if not UpgradeTag.HasUpgradeTag(SalesHeaderTag()) then begin
            MigrateSalesHeader();
            UpgradeTag.SetUpgradeTag(SalesHeaderTag());
        end;
        if not UpgradeTag.HasUpgradeTag(UserSetupTag()) then begin
            MigrateUserSetup();
            UpgradeTag.SetUpgradeTag(UserSetupTag());
        end;
    end;

    local procedure MigrateReportConfiguration()
    var
        OldRec: Record "DX Report Configuration";
        NewRec: Record "DXR_Report Configuration";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Primary Key") then begin
                    NewRec.Init();
                    NewRec."Primary Key" := OldRec."Primary Key";
                    NewRec."Show Approval Signatures" := OldRec."Show Approval Signatures";
                    NewRec."Last Modified By" := OldRec."Last Modified By";
                    NewRec."Last Modified Date" := OldRec."Last Modified Date";
                    NewRec."Enable Job Ledger Entries Rep" := OldRec."Enable Job Ledger Entries Rep";
                    NewRec."EF QR Testing" := OldRec."EF QR Testing";
                    NewRec."Test RNC Contribuyente" := OldRec."Test RNC Contribuyente";
                    NewRec."Test NCF" := OldRec."Test NCF";
                    NewRec."Test RNC Comprador" := OldRec."Test RNC Comprador";
                    NewRec."Test Codigo Seguridad" := OldRec."Test Codigo Seguridad";
                    NewRec."Test Fecha Estampado" := OldRec."Test Fecha Estampado";
                    NewRec."Test Fecha Emision" := OldRec."Test Fecha Emision";
                    NewRec."Test Monto Total" := OldRec."Test Monto Total";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigratePaymentMethod()
    var
        Rec: Record "Payment Method";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Type_DXR" := Rec."DX Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateBankAccountLedgerEntry()
    var
        Rec: Record "Bank Account Ledger Entry";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Payment Method Type_DXR" := Rec."DX Payment Method Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateCustLedgerEntry()
    var
        Rec: Record "Cust. Ledger Entry";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Payment Method Type_DXR" := Rec."DX Payment Method Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateGenJournalLine()
    var
        Rec: Record "Gen. Journal Line";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Payment Method Type_DXR" := Rec."DX Payment Method Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateGLEntry()
    var
        Rec: Record "G/L Entry";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Payment Method Type_DXR" := Rec."DX Payment Method Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateVendorLedgerEntry()
    var
        Rec: Record "Vendor Ledger Entry";
    begin
        if Rec.FindSet(true) then
            repeat
                Rec."DX Payment Method Type_DXR" := Rec."DX Payment Method Type";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure MigrateSalesHeader()
    var
        Rec: Record "Sales Header";
        InStream: InStream;
        OutStream: OutStream;
    begin
        if Rec.FindSet(true) then
            repeat
                Rec.CalcFields("DX Work Description");
                if Rec."DX Work Description".HasValue() then begin
                    Rec."DX Work Description".CreateInStream(InStream);
                    Rec."Work Description_DXR".CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                    Rec.Modify(false);
                end;
            until Rec.Next() = 0;
    end;

    local procedure MigrateUserSetup()
    var
        Rec: Record "User Setup";
        InStream: InStream;
        OutStream: OutStream;
    begin
        if Rec.FindSet(true) then
            repeat
                Rec.CalcFields("DXFirma Encargado");
                if Rec."DXFirma Encargado".HasValue() then begin
                    Rec."DXFirma Encargado".CreateInStream(InStream);
                    Rec."Firma Encargado_DXR".CreateOutStream(OutStream);
                    CopyStream(OutStream, InStream);
                end;
                Rec."Cargo_DXR" := Rec.DXCargo;
                Rec."Nombre Archivo_DXR" := Rec."DXNombre Archivo";
                Rec.Modify(false);
            until Rec.Next() = 0;
    end;

    local procedure ReportConfigTag(): Code[250]
    begin
        exit('DXR-MCC-RO-SETUP-REPORTCONFIG-20260826.');
    end;

    local procedure PaymentMethodTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-PAYMETHOD-20260826.');
    end;

    local procedure BankAccountLedgerEntryTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-BANKACCTLEDG-20260826.');
    end;

    local procedure CustLedgerEntryTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-CUSTLEDG-20260826.');
    end;

    local procedure GenJournalLineTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-GENJNLLINE-20260826.');
    end;

    local procedure GLEntryTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-GLENTRY-20260826.');
    end;

    local procedure VendorLedgerEntryTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-VENDLEDG-20260826.');
    end;

    local procedure SalesHeaderTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-SALESHDR-20260826.');
    end;

    local procedure UserSetupTag(): Code[250]
    begin
        exit('DXR-MCC-RO-MA-USERSETUP-20260826.');
    end;
}

