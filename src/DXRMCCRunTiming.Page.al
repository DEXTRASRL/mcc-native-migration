page 60024 "DXR MCC Run Timing"
{
    PageType = Card;
    SourceTable = "DXR MCC Run Request";
    ApplicationArea = All;
    Caption = 'DXR MCC Run Timing';
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(Run)
            {
                Caption = 'Run';
                field("Entry No."; Rec."Entry No.") { }
                field(Status; Rec.Status) { }
                field("Scheduled At"; Rec."Scheduled At") { }
                field("Started At"; Rec."Started At") { }
                field("Completed At"; Rec."Completed At") { }
                field("Current Step"; Rec."Current Step") { }
            }
            group(Setup)
            {
                Caption = 'Setup';
                field("Setup Phase Status"; Rec."Setup Phase Status") { }
                field("Setup Started At"; Rec."Setup Started At") { }
                field("Setup Completed At"; Rec."Setup Completed At") { }
                field("Setup Duration"; Rec."Setup Duration") { }
            }
            group(MasterAccounting)
            {
                Caption = 'Master/Accounting';
                field("Master/Accounting Status"; Rec."Master/Accounting Status") { }
                field("Master/Accounting Started At"; Rec."Master/Accounting Started At") { }
                field("Master/Accounting Completed At"; Rec."Master/Accounting Completed At") { }
                field("Master/Accounting Duration"; Rec."Master/Accounting Duration") { }
            }
            group(Historic)
            {
                Caption = 'Historic';
                field("Historic Phase Status"; Rec."Historic Phase Status") { }
                field("Historic Started At"; Rec."Historic Started At") { }
                field("Historic Completed At"; Rec."Historic Completed At") { }
                field("Historic Duration"; Rec."Historic Duration") { }
            }
            group(Other)
            {
                Caption = 'Other';
                field("Other Phase Status"; Rec."Other Phase Status") { }
                field("Other Started At"; Rec."Other Started At") { }
                field("Other Completed At"; Rec."Other Completed At") { }
                field("Other Duration"; Rec."Other Duration") { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                Caption = 'Refresh';
                ApplicationArea = All;
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
