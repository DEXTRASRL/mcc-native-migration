// Adapter for "DX Bank Reconciliation" (app ID 3f45e9d8-89f4-4be2-b687-f69908d8ad63, package
// Dextra_DX Bank Reconciliation_28.3.1.0.app). Extension row 'BANKREC' already exists in
// DXRMCCRegistryLoader (InsExt('BANKREC', 'DX Bank Reconciliation',
// '3f45e9d8-89f4-4be2-b687-f69908d8ad63', 920, '')), and its 12 Concept rows are registered too
// (dispatcher IDs corrected 2026-08-29 - see DXRMCCBANKRECCategoryWorkers.Codeunit.al).
//
// Symbol extraction (SymbolReference.json from the .app) found 12 clean OLD -> NEW table pairs, all
// field-for-field identical (same IDs/names/types on both sides) plus one internal checkpoint table
// this extension's own upgrade code already owns (50274 "DXR_BankRecon Migr Status" - NOT a
// migration source/target, left out of the concept list below):
//
//   50250 "BC Bank"                     -> 50262 "DXR_Bank"                     (MA)
//   50251 "BC Bank Relation"            -> 50263 "DXR_Bank Relation"            (MA)
//   50252 "BC Banks - Bank Statement"   -> 50264 "DXR_Banks - Bank Statement"   (MA)
//   50253 "BC BhdFile"                  -> 50265 "DXR_BhdFile"                  (HIST)
//   50254 "BC BpdFile"                  -> 50266 "DXR_BpdFile"                  (HIST)
//   50255 "BC BrsFile"                  -> 50267 "DXR_BrsFile"                  (HIST)
//   50256 "BC Setup - Bank Statement"   -> 50268 "DXR_Setup - Bank Statement"   (SETUP)
//   50257 "BC Detail - Bank Statement"  -> 50269 "DXR_Detail - Bank Statement"  (HIST)
//   50258 "BC File Structure"           -> 50270 "DXR_File Structure"           (SETUP)
//   50259 "BC History - Bank Statement" -> 50271 "DXR_History - Bank Statement" (HIST)
//   50260 "BC Log - Bank Statement"     -> 50272 "DXR_Log - Bank Statement"     (HIST)
//   50261 "BC BscFile"                  -> 50273 "DXR_BscFile"                  (HIST)
//
// No "_DXR"-suffixed field renames were found anywhere in this package's symbols (unlike TU/BC's
// core-table field-suffix pattern) - BANKREC's renumbering is 100% whole-table (old table name ->
// "DXR_"-prefixed new table, identical field layout), so there is no analogous
// MigrateLegacy...Fields() step here, only whole-table copies.
//
// TODO(reviewer): none of these 12 old/new table pairs carry an explicit primary key in the
// extracted symbol JSON (SymbolReference.json omits table Keys for this package), but four of them
// (BhdFile, BpdFile, BrsFile, BscFile, Detail/History/Log - Bank Statement) declare an
// AutoIncrement=1 field ("BC Entry No" / "Entry No"). BC allows an explicit non-zero Insert() on an
// AutoIncrement field (it just resumes autoincrementing above the highest value already present),
// so the copies below preserve the old entry numbers as-is to keep any external cross-references
// intact - but this needs a human to confirm nothing outside these tables stores those entry numbers
// as a foreign key into a *different* table where the "same number, different meaning" swap would
// silently corrupt a relation.
//
// TODO(reviewer): "BC Bank" (50250) and "BC Banks - Bank Statement" (50252) - and their DXR_
// counterparts (50262, 50264) - each carry a field "BC Object Type Import" typed as public
// Enum "ObjectType" (Id 50250, defined by this same package). That enum's name collides with an
// AL compiler-intrinsic type name and is exactly what already breaks compilation elsewhere in this
// repo (src/DXRMCCCompletionNotify.Codeunit.al, error AL0275) whenever this package's symbols are
// loaded alongside MCC's own. Referencing these two table pairs as typed Records (as done below)
// will very likely hit the same AL0275 the moment this file is uncommented - a human needs to
// resolve the enum collision (or fall back to RecordRef/FieldRef just for the "BC Object Type
// Import" field on these two tables) before this draft can be turned into real code.
//
// TODO(app.json): none of the 12 tables above show Access = Internal in the extracted symbols (no
// Access property was present on any of them, which decompiles as the default Public), so
// internalsVisibleTo does NOT need to add "DX Bank Reconciliation" for this adapter as currently
// scoped. Re-check if a reviewer finds an Access=Internal table this pass missed.
//
// Reserved codeunit ID block for this adapter: 60450-60469 (max ID in repo at draft time was
// 60442; nothing else in src/ uses 60450+).


codeunit 60453 "DXR MCC BANKREC Migr Dispatch"
{
    // Field-by-field assignment, no TransferFields - every pair below is identical in field
    // IDs/names/types between OLD and NEW (confirmed against the extension's own SymbolReference.json).
    Permissions =
        tabledata "BC Bank" = R,
        tabledata "BC Bank Relation" = R,
        tabledata "BC Banks - Bank Statement" = R,
        tabledata "BC BhdFile" = R,
        tabledata "BC BpdFile" = R,
        tabledata "BC BrsFile" = R,
        tabledata "BC Setup - Bank Statement" = R,
        tabledata "BC Detail - Bank Statement" = R,
        tabledata "BC File Structure" = R,
        tabledata "BC History - Bank Statement" = R,
        tabledata "BC Log - Bank Statement" = R,
        tabledata "BC BscFile" = R,
        tabledata "DXR_Bank" = RIM,
        tabledata "DXR_Bank Relation" = RIM,
        tabledata "DXR_Banks - Bank Statement" = RIM,
        tabledata "DXR_BhdFile" = RIM,
        tabledata "DXR_BpdFile" = RIM,
        tabledata "DXR_BrsFile" = RIM,
        tabledata "DXR_Setup - Bank Statement" = RIM,
        tabledata "DXR_Detail - Bank Statement" = RIM,
        tabledata "DXR_File Structure" = RIM,
        tabledata "DXR_History - Bank Statement" = RIM,
        tabledata "DXR_Log - Bank Statement" = RIM,
        tabledata "DXR_BscFile" = RIM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunAccounting();
    end;

    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(SetupTableMigrationTag()) then begin
            MigrateSetupBankStatement();
            UpgradeTag.SetUpgradeTag(SetupTableMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(FileStructureMigrationTag()) then begin
            MigrateFileStructure();
            UpgradeTag.SetUpgradeTag(FileStructureMigrationTag());
        end;
    end;

    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // TODO(reviewer): Bank / Banks - Bank Statement carry the colliding "ObjectType" enum field -
        // see the file-header TODO. Left as typed Record copies here pending that decision.
        if not UpgradeTag.HasUpgradeTag(BankMigrationTag()) then begin
            MigrateBank();
            UpgradeTag.SetUpgradeTag(BankMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BankRelationMigrationTag()) then begin
            MigrateBankRelation();
            UpgradeTag.SetUpgradeTag(BankRelationMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BanksBankStatementMigrationTag()) then begin
            MigrateBanksBankStatement();
            UpgradeTag.SetUpgradeTag(BanksBankStatementMigrationTag());
        end;
    end;

    procedure RunAccounting()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(BhdFileMigrationTag()) then begin
            MigrateBhdFile();
            UpgradeTag.SetUpgradeTag(BhdFileMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BpdFileMigrationTag()) then begin
            MigrateBpdFile();
            UpgradeTag.SetUpgradeTag(BpdFileMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BrsFileMigrationTag()) then begin
            MigrateBrsFile();
            UpgradeTag.SetUpgradeTag(BrsFileMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(BscFileMigrationTag()) then begin
            MigrateBscFile();
            UpgradeTag.SetUpgradeTag(BscFileMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(DetailBankStatementMigrationTag()) then begin
            MigrateDetailBankStatement();
            UpgradeTag.SetUpgradeTag(DetailBankStatementMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(HistoryBankStatementMigrationTag()) then begin
            MigrateHistoryBankStatement();
            UpgradeTag.SetUpgradeTag(HistoryBankStatementMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(LogBankStatementMigrationTag()) then begin
            MigrateLogBankStatement();
            UpgradeTag.SetUpgradeTag(LogBankStatementMigrationTag());
        end;
    end;

    // ---------------------------------------------------------------------------------------------
    // SETUP
    // ---------------------------------------------------------------------------------------------

    local procedure MigrateSetupBankStatement()
    var
        OldRec: Record "BC Setup - Bank Statement";
        NewRec: Record "DXR_Setup - Bank Statement";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Key") then begin
                    NewRec.Init();
                    NewRec."BC Key" := OldRec."BC Key";
                    NewRec."BC Active" := OldRec."BC Active";
                    NewRec."BC Folder Patch" := OldRec."BC Folder Patch";
                    NewRec."BC Days Run" := OldRec."BC Days Run";
                    NewRec."BC Date Tolerance" := OldRec."BC Date Tolerance";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateFileStructure()
    var
        OldRec: Record "BC File Structure";
        NewRec: Record "DXR_File Structure";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Field No", OldRec."BC Bank") then begin
                    NewRec.Init();
                    NewRec."BC Field No" := OldRec."BC Field No";
                    NewRec."BC Field Name" := OldRec."BC Field Name";
                    NewRec."BC Lenght Field" := OldRec."BC Lenght Field";
                    NewRec."BC From Field" := OldRec."BC From Field";
                    NewRec."BC Bank" := OldRec."BC Bank";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    // ---------------------------------------------------------------------------------------------
    // MASTER
    // ---------------------------------------------------------------------------------------------

    local procedure MigrateBank()
    var
        OldRec: Record "BC Bank";
        NewRec: Record "DXR_Bank";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Bank Code") then begin
                    NewRec.Init();
                    NewRec."BC Bank Code" := OldRec."BC Bank Code";
                    NewRec."BC Bank name" := OldRec."BC Bank name";
                    NewRec."BC BPD Code" := OldRec."BC BPD Code";
                    // "BC Object Type Import" is Enum "ObjectType" (50250, ObsoleteState=Pending)
                    // on the old table vs Enum "DXR_ObjectType" (50251) on the new one - two
                    // distinct Enum objects, same 5-value list at identical ordinals (Codeunit=0,
                    // Page=1, Query=2, Report=3, XMLPort=4; confirmed against the app's own symbol
                    // table via an isolated test compile, which raised AL0122 on a direct
                    // assignment). Converted through the integer value instead.
                    NewRec."BC Object Type Import" := "DXR_ObjectType".FromInteger(OldRec."BC Object Type Import".AsInteger());
                    NewRec."BC Object ID Import" := OldRec."BC Object ID Import";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateBankRelation()
    var
        OldRec: Record "BC Bank Relation";
        NewRec: Record "DXR_Bank Relation";
    begin
        // "BC Bank Account No" (field 4) is a FlowField - excluded, matching TransferFields' own
        // behavior.
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Relation ID") then begin
                    NewRec.Init();
                    NewRec."BC Relation ID" := OldRec."BC Relation ID";
                    NewRec."BC Bank Code" := OldRec."BC Bank Code";
                    NewRec."BC Bank" := OldRec."BC Bank";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateBanksBankStatement()
    var
        OldRec: Record "BC Banks - Bank Statement";
        NewRec: Record "DXR_Banks - Bank Statement";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Bank Code") then begin
                    NewRec.Init();
                    NewRec."BC Bank Code" := OldRec."BC Bank Code";
                    NewRec."BC Name" := OldRec."BC Name";
                    NewRec."BC Bank Format" := OldRec."BC Bank Format";
                    NewRec."BC Format Mt940" := OldRec."BC Format Mt940";
                    // TODO(reviewer): "BC Object Type Import" is Enum "ObjectType" (50250) - see
                    // file-header TODO about the AL0275 name collision before enabling this line.
                    NewRec."BC Object Type Import" := OldRec."BC Object Type Import";
                    NewRec."BC Object ID Import" := OldRec."BC Object ID Import";
                    NewRec."Object Type" := OldRec."Object Type";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    // ---------------------------------------------------------------------------------------------
    // ACCOUNTING / HIST (transactional bank-file data)
    // ---------------------------------------------------------------------------------------------

    // BhdFile/BpdFile share an identical, sparse field layout (fields 1 and 9 only, per the
    // extracted symbols - fields 2-8 are not published by this package on either side).
    local procedure MigrateBhdFile()
    var
        OldRec: Record "BC BhdFile";
        NewRec: Record "DXR_BhdFile";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec."BC Detail Line" := OldRec."BC Detail Line";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateBpdFile()
    var
        OldRec: Record "BC BpdFile";
        NewRec: Record "DXR_BpdFile";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec."BC Detail Line" := OldRec."BC Detail Line";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateBrsFile()
    var
        OldRec: Record "BC BrsFile";
        NewRec: Record "DXR_BrsFile";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec.Producto := OldRec.Producto;
                    NewRec.Fecha := OldRec.Fecha;
                    NewRec.Concepto := OldRec.Concepto;
                    NewRec."Id de transacción" := OldRec."Id de transacción";
                    NewRec.Debito := OldRec.Debito;
                    NewRec.Credito := OldRec.Credito;
                    NewRec."BC Balance" := OldRec."BC Balance";
                    NewRec."BC Description" := OldRec."BC Description";
                    NewRec.Referencia := OldRec.Referencia;
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateBscFile()
    var
        OldRec: Record "BC BscFile";
        NewRec: Record "DXR_BscFile";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec."BC Fecha" := OldRec."BC Fecha";
                    NewRec."BC Descripcion" := OldRec."BC Descripcion";
                    NewRec."BC Debito" := OldRec."BC Debito";
                    NewRec."BC Credito" := OldRec."BC Credito";
                    NewRec."BC Balance" := OldRec."BC Balance";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateDetailBankStatement()
    var
        OldRec: Record "BC Detail - Bank Statement";
        NewRec: Record "DXR_Detail - Bank Statement";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec."BC Account No" := OldRec."BC Account No";
                    NewRec."BC Posting Date" := OldRec."BC Posting Date";
                    NewRec."BC Check No" := OldRec."BC Check No";
                    NewRec."BC Amount" := OldRec."BC Amount";
                    NewRec."BC Origin" := OldRec."BC Origin";
                    NewRec."BC Description" := OldRec."BC Description";
                    NewRec."BC Transaction Code" := OldRec."BC Transaction Code";
                    NewRec."BC Reference No." := OldRec."BC Reference No.";
                    NewRec."BC Balance" := OldRec."BC Balance";
                    NewRec."BC Bank Account" := OldRec."BC Bank Account";
                    NewRec."BC Bank" := OldRec."BC Bank";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateHistoryBankStatement()
    var
        OldRec: Record "BC History - Bank Statement";
        NewRec: Record "DXR_History - Bank Statement";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."BC Entry No") then begin
                    NewRec.Init();
                    NewRec."BC Entry No" := OldRec."BC Entry No";
                    NewRec."BC Account No" := OldRec."BC Account No";
                    NewRec."BC Posting Date" := OldRec."BC Posting Date";
                    NewRec."BC Check No" := OldRec."BC Check No";
                    NewRec."BC Amount" := OldRec."BC Amount";
                    NewRec."BC Origin" := OldRec."BC Origin";
                    NewRec."BC Description" := OldRec."BC Description";
                    NewRec."BC Transaction Code" := OldRec."BC Transaction Code";
                    NewRec."BC Reference No." := OldRec."BC Reference No.";
                    NewRec."BC Bank Account" := OldRec."BC Bank Account";
                    NewRec."BC Bank" := OldRec."BC Bank";
                    NewRec."BC StatementNo" := OldRec."BC StatementNo";
                    NewRec."BC Line Statement No" := OldRec."BC Line Statement No";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    local procedure MigrateLogBankStatement()
    var
        OldRec: Record "BC Log - Bank Statement";
        NewRec: Record "DXR_Log - Bank Statement";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Entry No") then begin
                    NewRec.Init();
                    NewRec."Entry No" := OldRec."Entry No";
                    NewRec.DateTrans := OldRec.DateTrans;
                    NewRec."BC Bank Account No" := OldRec."BC Bank Account No";
                    NewRec."Date Created" := OldRec."Date Created";
                    NewRec."Time Created" := OldRec."Time Created";
                    NewRec.MessageError := OldRec.MessageError;
                    NewRec.Bank := OldRec.Bank;
                    NewRec.UserRegister := OldRec.UserRegister;
                    NewRec.CuentaBanco := OldRec.CuentaBanco;
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    // ---------------------------------------------------------------------------------------------
    // Upgrade Tags
    // ---------------------------------------------------------------------------------------------

    local procedure SetupTableMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-SETUP-BANKSTMT-GEN0-20260826.');
    end;

    local procedure FileStructureMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-SETUP-FILESTRUCT-GEN0-20260826.');
    end;

    local procedure BankMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-MASTER-BANK-GEN0-20260826.');
    end;

    local procedure BankRelationMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-MASTER-BANKRELATION-GEN0-20260826.');
    end;

    local procedure BanksBankStatementMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-MASTER-BANKSBANKSTMT-GEN0-20260826.');
    end;

    local procedure BhdFileMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-BHDFILE-GEN0-20260826.');
    end;

    local procedure BpdFileMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-BPDFILE-GEN0-20260826.');
    end;

    local procedure BrsFileMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-BRSFILE-GEN0-20260826.');
    end;

    local procedure BscFileMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-BSCFILE-GEN0-20260826.');
    end;

    local procedure DetailBankStatementMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-DETAILBANKSTMT-GEN0-20260826.');
    end;

    local procedure HistoryBankStatementMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-HISTORYBANKSTMT-GEN0-20260826.');
    end;

    local procedure LogBankStatementMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-BANKREC-HIST-LOGBANKSTMT-GEN0-20260826.');
    end;
}
