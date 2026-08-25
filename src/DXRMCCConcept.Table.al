table 60001 "DXR MCC Concept"
{
    Caption = 'Migration Control Center Concept';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Extension Code"; Code[20])
        {
            Caption = 'Extension Code';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Extension".Code;
        }
        field(3; "Phase Code"; Code[20])
        {
            Caption = 'Phase Code';
            DataClassification = SystemMetadata;
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Description"; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(6; "Dispatcher Codeunit ID"; Integer)
        {
            Caption = 'Dispatcher Codeunit ID';
            DataClassification = SystemMetadata;
        }
        field(7; "Legacy Table ID"; Integer)
        {
            Caption = 'Legacy Table ID';
            DataClassification = SystemMetadata;
        }
        field(8; "New Table ID"; Integer)
        {
            Caption = 'New Table ID';
            DataClassification = SystemMetadata;
        }
        field(9; "Old Record Count"; Integer)
        {
            Caption = 'Old Record Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Migrated Record Count"; Integer)
        {
            Caption = 'Migrated Record Count';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; "Gap"; Integer)
        {
            Caption = 'Gap';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(12; "Status"; Option)
        {
            Caption = 'Status';
            OptionMembers = "Not Counted",Pending,Running,Completed,"Completed With Gaps",Error,"Not Row-Based","Completed (Fallback)",Skipped;
            OptionCaption = 'Not Counted,Pending,Running,Completed,Completed With Gaps,Error,Not Row-Based,Completed (Fallback),Skipped';
            // "Completed (Fallback)" appended at the end deliberately - new OptionMembers must go
            // last so already-stored numeric Status values on existing rows don't shift meaning.
            DataClassification = SystemMetadata;
        }
        field(13; "Last Run DateTime"; DateTime)
        {
            Caption = 'Last Run DateTime';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(14; "Blocked"; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = SystemMetadata;
        }
        field(15; "Blocked Reason"; Text[250])
        {
            Caption = 'Blocked Reason';
            DataClassification = SystemMetadata;
        }
        field(16; "Upgrade Tags"; Text[250])
        {
            Caption = 'Upgrade Tags';
            DataClassification = SystemMetadata;
            // Operator-maintained, semicolon-separated list of the exact Upgrade Tag code(s)
            // that gate this concept's dispatcher codeunit (e.g. "DXR-EF-NCF-MODREASON-ID-
            // REALIGNMENT-20260820"). NOT auto-populated by Reload Registry, same as Blocked/
            // Blocked Reason - MCC has no way to introspect which tags a given dispatcher
            // codeunit checks, the operator has to read the target codeunit's source once and
            // record it here. Used only by "Force Rerun" (see DXR MCC Concept Subform) to know
            // which rows to delete from the platform's Upgrade Tags table (9999) before
            // re-scheduling - leave blank and Force Rerun refuses to run rather than guess.
        }
        field(17; "Category"; Option)
        {
            Caption = 'Category';
            OptionMembers = Setup,"Master/Accounting",Historic,Other;
            OptionCaption = 'Setup,Master/Accounting,Historic,Other';
            DataClassification = SystemMetadata;
            // Refreshed from source by Reload Registry (same treatment as Description/Dispatcher/
            // Legacy/New Table ID - this is derived classification metadata, not operator-set
            // triage state like Blocked/Blocked Reason/Upgrade Tags), but left Editable so an
            // operator can correct a misclassification without waiting for a registry change.
            // "Other" covers concepts whose own scope genuinely spans more than one category (a
            // single phase-level dispatcher touching Setup + transactional + historic tables in
            // one sweep) - forcing those into Setup/Master-Accounting/Historic would misrepresent
            // what running "just Setup" or "just Historic" actually covers, so Run All Setup/
            // Master-Accounting/Historic deliberately never include Other; Run Portfolio still
            // does, as its own trailing pass.
        }
        field(18; Retired; Boolean)
        {
            Caption = 'Retired';
            DataClassification = SystemMetadata;
            Editable = false;
            // Derived registry metadata. Retired rows stay stored so historical Run Log entries
            // keep their Concept Entry No., but active pages, counters and executors exclude them.
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Order; "Extension Code", "Sequence No.") { }
        key(CategoryOrder; Category, "Extension Code", "Sequence No.") { }
    }
}
