// Adapter for "Interfaz Nomina BC" (App ID 1c09dc85-18ef-4c7e-9087-26a896040b93, adapter code
// INBC). Dependency of this branch's app.json.
//
// Source: extracted from the compiled .alpackages/Dextra_Interfaz Nomina BC_28.3.0.1.app's own
// SymbolReference.json (no source .al files for this extension are present in this repo).
//
// SCOPE FOUND: this extension already ships its own complete, public, self-gating migration
// framework - it is NOT re-implemented here (same "delegate, don't reimplement" pattern used for
// DX-Prontopago-module), avoiding any risk of enum/type mismatches from guessing field types:
//   - Codeunit "DXR_MigrPhaseDispatcher" (56117), public:
//       procedure RunPhase1IfNeeded()
//       procedure GetPhase1Tag(): Code[250]
//   - Codeunit "DXR_MigrPhase1PayrollData" (56119), public: procedure Execute() (the actual
//     payroll-data field/table restore; invoked internally by RunPhase1IfNeeded(), not called
//     directly here).
//   - Codeunit "DXR_MigrUpgrade" (56118, Subtype=Upgrade) - runs on its own schema-sync upgrade
//     cycle only, not reachable via Codeunit.Run() outside that context; not invoked here.
// RunPhase1IfNeeded() already checks its own Upgrade Tag (GetPhase1Tag()) before doing any work,
// so it is safe to call redundantly from every category worker below.
//
// PROPOSED REGISTRY ENTRIES (see src/DXRMCCRegistryLoader.Codeunit.al):
//   InsExt('INBC', 'Interfaz Nomina BC', '1c09dc85-18ef-4c7e-9087-26a896040b93', 1050, '...');
//   InsConcept('INBC', 'INBC-P1', 1, 'Payroll data field/table restore (delegates to the '
//       + 'extension''s own DXR_MigrPhaseDispatcher.RunPhase1IfNeeded())', 60640, 0, 0, 'MASTER');

codeunit 60640 "DXR MCC INBC Migr Dispatcher"
{
    trigger OnRun()
    begin
        RunMaster();
    end;

    procedure RunMaster()
    var
        Dispatcher: Codeunit "DXR_MigrPhaseDispatcher";
    begin
        Dispatcher.RunPhase1IfNeeded();
    end;
}
