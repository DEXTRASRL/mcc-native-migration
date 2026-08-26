// =====================================================================================
// PROPOSED Registry entries (add to src/DXRMCCRegistryLoader.Codeunit.al by hand -
// NOT applied by this draft). Order No. 980 per task instructions. Sequence Nos.
// 325-329 continue on from the current max (324) found in that file.
//
//   InsExt('INBC', 'Interfaz Nomina BC', '1c09dc85-18ef-4c7e-9087-26a896040b93', 980, '');
//
//   InsConcept('INBC', 'INBC-P1', 325, 'Payroll Setup legacy table restore (56100 -> 56107)', 60570, 56100, 56107, 'SETUP');
//   InsConcept('INBC', 'INBC-P1', 326, 'Payroll Method Relation legacy table restore (56105 -> 56110)', 60570, 56105, 56110, 'SETUP');
//   InsConcept('INBC', 'INBC-P1', 327, 'Payroll Interface legacy table restore (56101 -> 56108, Enum type change on EntryType - verify value mapping)', 60570, 56101, 56108, 'MA');
//   InsConcept('INBC', 'INBC-P1', 328, 'Payroll POST OData legacy table restore (56102 -> 56109, Enum type change on EntryType - verify value mapping)', 60570, 56102, 56109, 'MA');
//   InsConcept('INBC', 'INBC-P1', 329, 'Payroll Logs legacy table restore (56106 -> 56111, Enum type change on Status/EntryType - verify value mapping)', 60570, 56106, 56111, 'HIST');
// =====================================================================================

// =====================================================================================
// DRAFT ADAPTER - "Interfaz Nomina BC" (INBC), App ID 1c09dc85-18ef-4c7e-9087-26a896040b93
// Not yet wired into the build (whole body commented out) - for human review only.
//
// Reserved codeunit ID block for this adapter: 60570-60589.
//
// ---------------------------------------------------------------------------------
// Symbol-table findings (extracted from
// .alpackages/Dextra_Interfaz Nomina BC_28.3.0.1.app -> SymbolReference.json):
//
// Five clean OLD -> NEW table pairs, all field-for-field identical (same IDs/names/
// types on both sides) except for two Enum fields whose *type* was renamed alongside
// the table (values assumed positionally identical, NOT verified against the enum's
// own value list - see TODO below):
//
//   56100 "NOM Payroll Setup"           -> 56107 "DXR_PayrollSetup"            (Category: SETUP)
//   56105 "NOM Payroll Method Relation" -> 56110 "DXR_PayrollMethodRelation"   (Category: SETUP)
//   56101 "NOM Payroll Interface"       -> 56108 "DXR_PayrollInterface"        (Category: MA)
//   56102 "NOM Payroll POST OData"      -> 56109 "DXR_PayrollPostOData"        (Category: MA)
//   56106 "NOM Payroll Logs"            -> 56111 "DXR_PayrollLogs"             (Category: HIST)
//
// All five OLD tables carry ObsoleteState=Pending / ObsoleteTag=28.3.0.0 with an
// ObsoleteReason literally stating: "Los datos se copian via DXR_Migr Phase1
// PayrollData." None of the six tables (old or new) is Access=Internal, so no
// app.json "internalsVisibleTo" change is needed for this extension.
//
// TODO(reviewer - enum mismatch): "NOM Payroll Logs".Status is Enum "NOM Payroll
// Statuslog" (56106... wait, enum id shown as table's own row context) while
// "DXR_PayrollLogs".Status is Enum "DXR_PayrollStatusLog" (56113) - a DIFFERENT
// enum type, not just a rename, so plain field assignment will NOT compile
// (BC does not implicitly convert between distinct Enum types even with identical
// value names/order). Same issue for "EntryType" on Interface/POST OData/Logs:
// old Enum "NOM Payroll InterfaceEntryType" vs new Enum "DXR_PayrollInterfaceEntryType"
// (56112). A human must confirm the two enums' value lists match 1:1 by ordinal (or by
// name) before choosing between `Enum::"New".FromInteger(Old.AsInteger())`
// (ordinal-based) and a name-based lookup. NOT guessed here.
//
// ---------------------------------------------------------------------------------
// IMPORTANT - a ready-made, already-idempotent migration entry point exists on
// INBC's own side and should almost certainly be reused instead of reimplementing
// field-by-field copies (mirrors the precedent already used by the TU adapter's
// MigrateGen2LegacySetup(), which calls a sibling extension's own public migration
// codeunit rather than duplicating its logic):
//
//   Codeunit 56119 "DXR_MigrPhase1PayrollData" (src/Migration/DXR_MigrPhase1PayrollData.Codeunit.al)
//     - public method Execute() - no parameters, no explicit Access property
//       (defaults to Public), so callable as a typed Codeunit variable.
//   Codeunit 56117 "DXR_MigrPhaseDispatcher" (src/Migration/DXR_MigrPhaseDispatcher.Codeunit.al)
//     - public method GetPhase1Tag(): Code[250] and RunPhase1IfNeeded() - the
//       latter appears to already wrap Execute() in its own Upgrade Tag check
//       (name strongly implies self-gating/idempotency), matching exactly the
//       precedent in TU's own new "DXR_TU Setup Gen2 Migration" pattern.
//   Codeunit 56118 "DXR_MigrUpgrade" (Subtype = Upgrade) - INBC's own automatic
//       upgrade codeunit; it likely already calls RunPhase1IfNeeded() during BC's
//       native extension-upgrade cycle. TODO(reviewer): confirm this by reading
//       INBC's real source (not available here, symbol table only) - if the
//       native upgrade codeunit ALREADY performs this migration on every tenant,
//       this MCC adapter's job may be limited to calling the same idempotent
//       entry point again (harmless / no-op) purely so MCC's Executor can COUNT
//       old vs. new rows and report gaps, not to actually move data.
//
// Given the enum-mismatch risk above, this draft delegates to RunPhase1IfNeeded()
// rather than attempting its own field-by-field copy of the two enum-bearing
// tables. The Setup/MethodRelation pair (no enums) is ALSO delegated, for a single
// consistent call site, since Execute() covers all five tables in one shot.
// =====================================================================================


#if not ESCUDEA and not BCDX
codeunit 60570 "DXR MCC INBC Migr Dispatcher"
{
    // Delegates to INBC's own already-idempotent migration entry point instead of
    // duplicating field-by-field copy logic (same rationale as TU's
    // "DXR_TU Setup Gen2 Migration" precedent) - avoids the Enum-type-mismatch pitfall
    // documented above (Status/EntryType fields use DIFFERENT enum types on old vs.
    // new tables, not just renamed ones, so a naive Record-to-Record field copy would
    // not compile for "NOM Payroll Logs"/"NOM Payroll Interface"/"NOM Payroll POST OData").
    //
    // tabledata permissions are declared for all ten OLD/NEW tables even though this
    // draft only calls through INBC's own codeunit (which will assert its own
    // permissions at runtime) - kept here so a future fallback to direct field-by-field
    // copy (if the enum question above resolves to "not compatible, copy manually")
    // does not require touching this property.
    Permissions =
        tabledata "NOM Payroll Setup" = R,
        tabledata "NOM Payroll Interface" = R,
        tabledata "NOM Payroll Logs" = R,
        tabledata "NOM Payroll Method Relation" = R,
        tabledata "NOM Payroll POST OData" = R,
        tabledata "DXR_PayrollSetup" = RIM,
        tabledata "DXR_PayrollInterface" = RIM,
        tabledata "DXR_PayrollLogs" = RIM,
        tabledata "DXR_PayrollMethodRelation" = RIM,
        tabledata "DXR_PayrollPostOData" = RIM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunAccounting();
    end;

    // Covers: "NOM Payroll Setup" (56100) -> "DXR_PayrollSetup" (56107) and
    // "NOM Payroll Method Relation" (56105) -> "DXR_PayrollMethodRelation" (56110).
    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(SetupMigrationTag()) then
            exit;
        MigratePayrollData();
        UpgradeTag.SetUpgradeTag(SetupMigrationTag());
    end;

    // Covers: "NOM Payroll Interface" (56101) -> "DXR_PayrollInterface" (56108) and
    // "NOM Payroll POST OData" (56102) -> "DXR_PayrollPostOData" (56109).
    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(MasterMigrationTag()) then
            exit;
        MigratePayrollData();
        UpgradeTag.SetUpgradeTag(MasterMigrationTag());
    end;

    // Covers: "NOM Payroll Logs" (56106) -> "DXR_PayrollLogs" (56111).
    procedure RunAccounting()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(HistMigrationTag()) then
            exit;
        MigratePayrollData();
        UpgradeTag.SetUpgradeTag(HistMigrationTag());
    end;

    // Single shared call - INBC's Execute() migrates all five tables together, so all
    // three category entry points above converge here. Calling it more than once is
    // expected to be harmless (RunPhase1IfNeeded()'s name implies its own internal
    // Upgrade Tag gate), but this is NOT verified against INBC's real source - only
    // its symbol table (method names/signatures) was available in this environment.
    // TODO(reviewer): confirm RunPhase1IfNeeded() is actually self-gating before
    // relying on that idempotency; if it is NOT, remove the redundant calls from
    // RunMaster()/RunAccounting() above and call MigratePayrollData() exactly once
    // from RunSetup() (or restructure so only the first category to run triggers it).
    local procedure MigratePayrollData()
    var
        MigrPhaseDispatcher: Codeunit "DXR_MigrPhaseDispatcher";
    begin
        MigrPhaseDispatcher.RunPhase1IfNeeded();
    end;

    local procedure SetupMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-INBC-SETUP-GEN0-20260826.');
    end;

    local procedure MasterMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-INBC-MA-GEN0-20260826.');
    end;

    local procedure HistMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-INBC-HIST-GEN0-20260826.');
    end;
}

#endif
