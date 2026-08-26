// DRAFT - NOT ENABLED. Adapter for "ECF Simple" (App ID 48545db5-4c13-4b3a-ac3b-75e7aa30e15e,
// adapter code ECF). This is the ONLY one of this branch's 8 non-core dependencies (Brik
// Interfaces, DXR-POS Advanced Features, DXR-POS-PRINTING, ECF Simple, ECF Simple Credito
// Parcial, POS Delivery, Price Checker, STRATA KPI Connector) that has a genuine 27->28
// table-move to migrate - the other 7 were checked the same way and show zero
// "Moved to table..." / "Renamed to..." ObsoleteReason markers (their ObsoleteState fields are
// plain same-table feature deprecations, nothing to copy).
//
// Source: extracted from the compiled .alpackages/Dextra_ECF Simple_28.0.0.79.app's own
// SymbolReference.json (no source .al files for this extension are present in this repo). Note
// the raw JSON has ~74KB of trailing null-byte padding after the real content - truncate at the
// first \x00 before parsing/grepping.
//
// WHAT WAS FOUND: ECF Simple's own tableextension (obsolete, ObsoleteTag=28.0.0.79) added 13
// fields to the base "EF Administration Setup" table (owned by Facturacion Electronica, App ID
// 4ccf94f0-8e86-437f-99fc-a4eeda4a5122). Every one of those 13 fields carries
// ObsoleteReason = 'Moved to tableextension 59120 on "DXR_Administration Setup".' - and a SECOND,
// still-live tableextension (object 59120, "SIPL EF Admin Setup DXR") adds the SAME 13 fields,
// same local IDs (59100-59112), same Names, same TypeDefinitions, onto "DXR_Administration Setup"
// (the renumbered replacement table, also owned by Facturacion Electronica). This is a pure
// same-name/same-type field relocation - no renaming, no type changes - so a direct field-by-field
// copy is correct.
//
//   Old table: "EF Administration Setup" (ECF Simple's own now-obsolete tableextension)
//   New table: "DXR_Administration Setup" (ECF Simple's own tableextension 59120, still live)
//   Fields (all present on both sides, identical Id/Name/Type):
//     59100 "SIPL ECF Simple URL"        Text[500]
//     59101 "SIPL ECF Simple Username"   Text[100]
//     59102 "SIPL ECF Simple Password"   Text[100]
//     59103 "SIPL ECF Simple Token"      Text[500]
//     59104 "SIPL Token Expiration"      DateTime
//     59105 "SIPL ECF Simple Timeout"    Integer
//     59106 "SIPL ECF Download Logs"     Boolean
//     59107 "SIPL ECF Auth URL"          Text[500]
//     59108 "SIPL ECF Send URL"          Text[500]
//     59109 "SIPL ECF Simulation Mode"   Boolean
//     59110 "SIPL ECF Sim Success Rate"  Integer
//     59111 "SIPL Block on ECF Error"    Boolean
//     59112 "SIPL ECF Max Retries"       Integer
//
// Both "EF Administration Setup" and "DXR_Administration Setup" are public (Access blank) in the
// symbol table - no app.json internalsVisibleTo change is needed. This is a singleton setup table
// (Administration Setup pattern) - migrated by reading the old row's primary key and copying it
// onto the new row rather than assuming a blank key, since the exact primary key value was not
// independently confirmed against Facturacion Electronica's own table definition.
//
// EXCLUDED (checked and ruled out, not part of this adapter):
//  - Page extensions "SIPL LSC Transaction Register"/"SIPL LSC Transaction Card" (LS Central) -
//    these are UI objects with Visible/StyleExpr control properties, not data tables. The fields
//    they display ("SIPL ECF Sent", "SIPL ECF Security Code", etc.) live as FlowFields on a
//    tableextension of "LSC Transaction Header" that itself carries NO ObsoleteState markers - the
//    real stored data behind those FlowFields is in a table called "SIPL EF Resend Archive",
//    which was not found to have any DXR_/renumbered counterpart in this app's own symbol table.
//  - EnumExtension "DXR_Service Provider" (adds option "ECF SIMPLE" = 59100) - enum extensions add
//    option values, not stored data; nothing to migrate.
//
// PROPOSED REGISTRY ENTRIES (human to add to src/DXRMCCRegistryLoader.Codeunit.al - NOT applied
// here):
//   InsExt('ECF', 'ECF Simple', '48545db5-4c13-4b3a-ac3b-75e7aa30e15e', 1030, '');
//   InsConcept('ECF', 'ECF-P1', 1, 'Administration Setup field restore (EF Administration Setup -> DXR_Administration Setup, 13 fields)', 60446, 0, 0, 'SETUP');


codeunit 60446 "DXR MCC ECF Migr Dispatcher"
{
    Permissions =
        tabledata "EF Administration Setup" = R,
        tabledata "DXR_Administration Setup" = RIM;

    trigger OnRun()
    begin
        RunSetup();
    end;

    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        MigrateAdministrationSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure MigrateAdministrationSetup()
    var
        OldRec: Record "EF Administration Setup";
        NewRec: Record "DXR_Administration Setup";
    begin
        if not OldRec.FindFirst() then
            exit;
        if not NewRec.Get(OldRec."Primary Key") then begin
            NewRec.Init();
            NewRec."Primary Key" := OldRec."Primary Key";
            NewRec.Insert(false);
        end;
        NewRec."SIPL ECF Simple URL" := OldRec."SIPL ECF Simple URL";
        NewRec."SIPL ECF Simple Username" := OldRec."SIPL ECF Simple Username";
        NewRec."SIPL ECF Simple Password" := OldRec."SIPL ECF Simple Password";
        NewRec."SIPL ECF Simple Token" := OldRec."SIPL ECF Simple Token";
        NewRec."SIPL Token Expiration" := OldRec."SIPL Token Expiration";
        NewRec."SIPL ECF Simple Timeout" := OldRec."SIPL ECF Simple Timeout";
        NewRec."SIPL ECF Download Logs" := OldRec."SIPL ECF Download Logs";
        NewRec."SIPL ECF Auth URL" := OldRec."SIPL ECF Auth URL";
        NewRec."SIPL ECF Send URL" := OldRec."SIPL ECF Send URL";
        NewRec."SIPL ECF Simulation Mode" := OldRec."SIPL ECF Simulation Mode";
        NewRec."SIPL ECF Sim Success Rate" := OldRec."SIPL ECF Sim Success Rate";
        NewRec."SIPL Block on ECF Error" := OldRec."SIPL Block on ECF Error";
        NewRec."SIPL ECF Max Retries" := OldRec."SIPL ECF Max Retries";
        NewRec.Modify(false);
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-ECF-SETUP-ADMINSETUP-20260826.');
    end;
}
