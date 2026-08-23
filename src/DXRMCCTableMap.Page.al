page 60026 "DXR MCC Table Map"
{
    // Requested 2026-08-22: "una vista para ver las tablas viejas que se van a migrar y a cuales
    // van". Every real table-pair concept (Legacy Table ID <> 0 - field-only concepts have nothing
    // to map, so they're filtered out) with both table names resolved from AllObjWithCaption so an
    // operator can see "old table X -> new table Y" without knowing either table's numeric ID.
    PageType = List;
    SourceTable = "DXR MCC Concept";
    SourceTableView = where("Legacy Table ID" = filter(<> 0));
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'DXR MCC Table Map (Legacy -> Active)';
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Extension Code"; Rec."Extension Code") { }
                field(Category; Rec.Category) { }
                field("Legacy Table ID"; Rec."Legacy Table ID") { }
                field(LegacyTableName; LegacyTableName)
                {
                    Caption = 'Legacy Table Name';
                    ToolTip = 'The old/legacy table this concept restores data from - never modified or cleared by any migration in this portfolio, per the standing "no perder ni borrar data legacy" requirement.';
                }
                field("New Table ID"; Rec."New Table ID") { }
                field(NewTableName; NewTableName)
                {
                    Caption = 'Active Table Name';
                    ToolTip = 'The current, active table this concept restores data into.';
                }
                field(Description; Rec.Description) { }
                field(Status; Rec.Status) { }
                field("Old Record Count"; Rec."Old Record Count") { }
                field("Migrated Record Count"; Rec."Migrated Record Count") { }
                field(Gap; Rec.Gap) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LegacyTableName := ResolveTableName(Rec."Legacy Table ID");
        NewTableName := ResolveTableName(Rec."New Table ID");
    end;

    local procedure ResolveTableName(TableId: Integer): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if TableId = 0 then
            exit('');
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableId) then
            exit(AllObjWithCaption."Object Caption");
        exit('(no publicada en este ambiente)');
    end;

    var
        LegacyTableName: Text[250];
        NewTableName: Text[250];
}
