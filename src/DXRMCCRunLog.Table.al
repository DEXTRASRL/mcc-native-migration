table 60002 "DXR MCC Run Log"
{
    Caption = 'Migration Control Center Run Log';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Concept Entry No."; Integer)
        {
            Caption = 'Concept Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Concept"."Entry No.";
        }
        field(3; "Extension Code"; Code[20])
        {
            Caption = 'Extension Code';
            DataClassification = SystemMetadata;
        }
        field(4; "Phase Code"; Code[20])
        {
            Caption = 'Phase Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Run DateTime"; DateTime)
        {
            Caption = 'Run DateTime';
            DataClassification = SystemMetadata;
        }
        field(7; "Old Record Count"; Integer)
        {
            Caption = 'Old Record Count';
            DataClassification = SystemMetadata;
        }
        field(8; "Migrated Record Count"; Integer)
        {
            Caption = 'Migrated Record Count';
            DataClassification = SystemMetadata;
        }
        field(9; "Status"; Option)
        {
            Caption = 'Status';
            OptionMembers = Pending,Running,Completed,"Completed With Gaps",Error,Skipped;
            OptionCaption = 'Pending,Running,Completed,Completed With Gaps,Error,Skipped';
            DataClassification = SystemMetadata;
        }
        field(10; "Error Message"; Text[2048])
        {
            Caption = 'Error Message';
            DataClassification = SystemMetadata;
        }
        field(11; "Duration (ms)"; Integer)
        {
            Caption = 'Duration (ms)';
            DataClassification = SystemMetadata;
        }
        field(12; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; "Run Request Entry No."; Integer)
        {
            Caption = 'Run Request Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Run Request"."Entry No.";
            // Added 2026-08-22 (reported: "Category Setup: 53 completed, 4 completed with gaps,
            // 90 failed, 0 skipped" and nothing else - the per-concept Error Message detail always
            // existed here, just with no way to filter it down to ONE specific run). 0 for entries
            // logged before this field existed.
        }
        field(14; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            DataClassification = SystemMetadata;
            // Added 2026-08-22 (requested: "agrega la tabla procesada en ese momento"). Snapshot,
            // not a live lookup - resolved once via AllObjWithCaption at the moment this log entry
            // was written (DXR MCC Executor.ResolveConceptTableName), so it stays accurate even if
            // the concept's Legacy/New Table ID changes later via Reload Registry. Blank for
            // entries logged before this field existed.
            //
            // Kept as-is for entries logged before "Legacy Table Name"/"New Table Name" existed
            // (2026-08-22, this same day) - prefers the NEW table's caption, falls back to Legacy,
            // so it stays a reasonable single-column summary. New code should read the two
            // dedicated fields below instead, which show old and new side by side as requested
            // ("en los logs debe de verse la tabla vieja y la nueva que se migra").
        }
        field(15; "Legacy Table Name"; Text[250])
        {
            Caption = 'Legacy Table Name';
            DataClassification = SystemMetadata;
            // Added 2026-08-22 (reported: "Table Name" only ever showed ONE resolved name -
            // whichever of Legacy/New Table ID it preferred - not both side by side). Resolved via
            // AllObjWithCaption from the concept's own Legacy Table ID at log time; blank if the
            // concept has no legacy table (a field-only concept, Legacy Table ID = 0) or the table
            // isn't found (extension not published here).
        }
        field(16; "New Table Name"; Text[250])
        {
            Caption = 'New Table Name';
            DataClassification = SystemMetadata;
            // Companion to "Legacy Table Name" above - resolved from the concept's New Table ID.
        }
        field(17; "Legacy Table ID"; Integer)
        {
            Caption = 'Legacy Table ID';
            DataClassification = SystemMetadata;
        }
        field(18; "New Table ID"; Integer)
        {
            Caption = 'New Table ID';
            DataClassification = SystemMetadata;
        }
        field(19; "Concept Description"; Text[250])
        {
            Caption = 'Concept Description';
            DataClassification = SystemMetadata;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Concept; "Concept Entry No.", "Run DateTime") { }
        key(RunRequest; "Run Request Entry No.") { }
    }
}
