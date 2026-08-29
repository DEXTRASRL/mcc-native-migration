page 60446 "DXR MCC Tenant Runs"
{
    PageType = List;
    SourceTable = "DXR MCC Run Request";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'DXR MCC Tenant Runs';
    Editable = false;
    RefreshOnActivate = true;
    Permissions = tabledata Company = R,
                  tabledata "DXR MCC Run Request" = R;

    layout
    {
        area(content)
        {
            repeater(Runs)
            {
                field("Tenant Run ID"; Rec."Tenant Run ID") { }
                field("Company Sequence"; Rec."Company Sequence") { }
                field("Company Name"; Rec."Company Name") { }
                field("Company Entry No."; Rec."Company Entry No.") { }
                field(Scope; Rec.Scope) { }
                field(Category; Rec.Category) { }
                field(Status; Rec.Status) { }
                field("Current Step"; Rec."Current Step") { }
                field("Last Heartbeat"; Rec."Last Heartbeat") { }
                field("Processed Count"; Rec."Processed Count") { }
                field("Attempt No."; Rec."Attempt No.") { }
                field("Scheduled At"; Rec."Scheduled At") { }
                field("Started At"; Rec."Started At") { }
                field("Completed At"; Rec."Completed At") { }
                field("Result Summary"; Rec."Result Summary") { }
                field("Requested By"; Rec."Requested By") { }
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
                    LoadOverview();
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        LoadOverview();
    end;

    local procedure LoadOverview()
    var
        Company: Record Company;
        CompanyRunRequest: Record "DXR MCC Run Request";
        OverviewEntryNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();

        Company.SetCurrentKey(Name);
        if Company.FindSet() then
            repeat
                CompanyRunRequest.Reset();
                CompanyRunRequest.ChangeCompany(Company.Name);
                CompanyRunRequest.SetRange("Tenant Chain", true);
                if CompanyRunRequest.FindSet() then
                    repeat
                        OverviewEntryNo += 1;
                        Rec := CompanyRunRequest;
                        Rec."Company Entry No." := CompanyRunRequest."Entry No.";
                        Rec."Entry No." := OverviewEntryNo;
                        Rec.Insert(false);
                    until CompanyRunRequest.Next() = 0;
            until Company.Next() = 0;

        Rec.SetCurrentKey("Tenant Run ID", "Company Sequence");
    end;
}
