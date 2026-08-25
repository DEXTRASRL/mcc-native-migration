table 60005 "DXR MCC Bulk Checkpoint"
{
    Caption = 'DXR MCC Bulk Checkpoint';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Company Name"; Text[30]) { DataClassification = SystemMetadata; }
        field(2; "Concept Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Concept"."Entry No.";
        }
        field(3; "Last Source Record ID"; RecordId) { DataClassification = SystemMetadata; }
        field(4; "Processed Count"; Integer) { DataClassification = SystemMetadata; }
        field(5; "Inserted Count"; Integer) { DataClassification = SystemMetadata; }
        field(6; "Updated At"; DateTime) { DataClassification = SystemMetadata; }
        field(7; Completed; Boolean) { DataClassification = SystemMetadata; }
    }

    keys
    {
        key(PK; "Company Name", "Concept Entry No.") { Clustered = true; }
    }
}
