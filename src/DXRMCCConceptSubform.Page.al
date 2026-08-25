page 60022 "DXR MCC Concept Subform"
{
    PageType = ListPart;
    SourceTable = "DXR MCC Concept";
    SourceTableView = where(Retired = const(false));
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Sequence No."; Rec."Sequence No.") { Editable = false; }
                field("Phase Code"; Rec."Phase Code") { Editable = false; }
                field(Description; Rec.Description) { Editable = false; }
                field(Category; Rec.Category)
                {
                    ToolTip = 'Refreshed from source by Reload Registry, but editable here if a concept is misclassified - Run All Setup/Master-Accounting/Historic filter strictly on this value.';
                }
                field("Old Record Count"; Rec."Old Record Count") { Editable = false; }
                field("Migrated Record Count"; Rec."Migrated Record Count") { Editable = false; }
                field(Gap; Rec.Gap) { Editable = false; }
                field(Status; Rec.Status) { Editable = false; }
                field("Last Run DateTime"; Rec."Last Run DateTime") { Editable = false; }
                field(Blocked; Rec.Blocked)
                {
                    ToolTip = 'Operator-controlled: mark true if the owning extension does not currently compile/publish. Reload Registry never overwrites this.';
                }
                field("Blocked Reason"; Rec."Blocked Reason")
                {
                }
                field("Upgrade Tags"; Rec."Upgrade Tags")
                {
                    ToolTip = 'Operator-maintained, semicolon-separated: the exact Upgrade Tag code(s) this concept''s dispatcher checks before running. Required for "Force Rerun" - MCC can''t discover these on its own.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunConcept)
            {
                Caption = 'Run';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Schedules a background task that runs this one phase (same execution model as the extensions'' own dispatchers - never runs in this page''s transaction). Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                begin
                    if Rec.Retired then
                        Error('This concept is retired and has no runtime migration to execute.');
                    if Rec.Blocked then
                        Error('This concept is blocked: %1', Rec."Blocked Reason");
                    Executor.ScheduleConcept(Rec);
                    Message('Scheduled. Open "DXR MCC Run Requests" (or Run Log once it finishes) to see the outcome for "%1".', Rec.Description);
                end;
            }
            action(ForceRerun)
            {
                Caption = 'Force Rerun';
                ApplicationArea = All;
                Image = ReOpen;
                ToolTip = 'Clears this concept''s Upgrade Tag(s) directly from the platform''s Upgrade Tags table, then schedules a fresh run - use when a phase completed a previous run but you need it to redo its field copies. Irreversible and undocumented by Microsoft (only the exact tags you list in "Upgrade Tags" are touched); read that tooltip before using.';
                trigger OnAction()
                var
                    UpgradeTagMgt: Codeunit "DXR MCC Upgrade Tag Mgt";
                    Executor: Codeunit "DXR MCC Executor";
                    NotFoundList: List of [Text];
                    ClearedCount: Integer;
                    NotFoundText: Text;
                    NotFoundItem: Text;
                begin
                    if Rec.Retired then
                        Error('This concept is retired and has no Upgrade Tag or runtime migration to rerun.');
                    if Rec.Blocked then
                        Error('This concept is blocked: %1', Rec."Blocked Reason");
                    if Rec."Upgrade Tags" = '' then
                        Error('"Upgrade Tags" is blank for "%1". Force Rerun refuses to guess which tag(s) gate this phase - fill in the exact tag code(s) (semicolon-separated if more than one) from the dispatcher codeunit''s own source first.', Rec.Description);

                    if not Confirm(
                        'This will permanently delete the following Upgrade Tag(s) for company %1, then schedule "%2" to run again:\n\n%3\n\nThis is an undocumented, irreversible platform operation - Business Central has no supported "clear tag" API. Proceed only if you''re certain these are the right tags.',
                        false, CompanyName(), Rec.Description, Rec."Upgrade Tags")
                    then
                        exit;

                    ClearedCount := UpgradeTagMgt.ClearUpgradeTags(Rec."Upgrade Tags", NotFoundList);
                    if NotFoundList.Count() > 0 then begin
                        NotFoundText := '';
                        foreach NotFoundItem in NotFoundList do
                            if NotFoundText = '' then
                                NotFoundText := NotFoundItem
                            else
                                NotFoundText += '; ' + NotFoundItem;
                        Message('Cleared %1 tag(s). %2 tag(s) not found (check for typos): %3.\n\nScheduling anyway - clearing 0 tags just means this run won''t redo already-completed steps.',
                            ClearedCount, NotFoundList.Count(), NotFoundText);
                    end;

                    Executor.ScheduleConcept(Rec);
                    Message('Force rerun scheduled for "%1" (%2 tag(s) cleared). Check DXR MCC Run Requests for the outcome.', Rec.Description, ClearedCount);
                end;
            }
            action(Recount)
            {
                Caption = 'Recount';
                ApplicationArea = All;
                Image = Refresh;
                trigger OnAction()
                var
                    Counter: Codeunit "DXR MCC Counter";
                begin
                    Counter.CountConcept(Rec);
                    CurrPage.Update(false);
                    Message('Recounted "%1": %2 of %3 migrated (gap %4).', Rec.Description, Rec."Migrated Record Count", Rec."Old Record Count", Rec.Gap);
                end;
            }
        }
    }
}
