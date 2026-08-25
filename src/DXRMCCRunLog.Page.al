page 60021 "DXR MCC Run Log"
{
    PageType = List;
    SourceTable = "DXR MCC Run Log";
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'DXR MCC Run Log';
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { }
                field("Run Request Entry No."; Rec."Run Request Entry No.") { Visible = false; }
                field("Extension Code"; Rec."Extension Code") { }
                field("Concept Description"; Rec."Concept Description") { }
                field("Legacy Table ID"; Rec."Legacy Table ID") { }
                field("Legacy Table Name"; Rec."Legacy Table Name")
                {
                    ToolTip = 'The old/legacy table this concept migrates data FROM.';
                }
                field("New Table ID"; Rec."New Table ID") { }
                field("New Table Name"; Rec."New Table Name")
                {
                    ToolTip = 'The new/active table this concept migrates data TO.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    Visible = false;
                    ToolTip = 'Superseded by "Legacy Table Name"/"New Table Name" (2026-08-22) - kept for log entries written before those existed.';
                }
                field("Phase Code"; Rec."Phase Code") { }
                field("Company Name"; Rec."Company Name") { }
                field("Run DateTime"; Rec."Run DateTime") { }
                field("Old Record Count"; Rec."Old Record Count") { }
                field("Migrated Record Count"; Rec."Migrated Record Count") { }
                field(Status; Rec.Status) { }
                field("Duration (ms)"; Rec."Duration (ms)") { }
                field("User ID"; Rec."User ID") { }
                field("Error Message"; Rec."Error Message") { }
            }
        }
    }
}
