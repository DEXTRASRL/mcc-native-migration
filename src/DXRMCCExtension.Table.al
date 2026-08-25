table 60000 "DXR MCC Extension"
{
    Caption = 'Migration Control Center Extension';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; "App ID"; Guid)
        {
            Caption = 'App ID';
            DataClassification = SystemMetadata;
        }
        field(4; "Order No."; Integer)
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Notes"; Text[250])
        {
            Caption = 'Notes';
            DataClassification = SystemMetadata;
        }
        field(6; "Total Concepts"; Integer)
        {
            Caption = 'Total Concepts';
            FieldClass = FlowField;
            CalcFormula = count("DXR MCC Concept" where("Extension Code" = field(Code), Retired = const(false)));
            Editable = false;
        }
        field(7; "Total Gap"; Integer)
        {
            Caption = 'Total Gap';
            FieldClass = FlowField;
            CalcFormula = sum("DXR MCC Concept".Gap where("Extension Code" = field(Code), Retired = const(false)));
            Editable = false;
        }
        field(8; "Last Run DateTime"; DateTime)
        {
            Caption = 'Last Run DateTime';
            FieldClass = FlowField;
            CalcFormula = max("DXR MCC Concept"."Last Run DateTime" where("Extension Code" = field(Code), Retired = const(false)));
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Order; "Order No.", Code) { }
    }
}
