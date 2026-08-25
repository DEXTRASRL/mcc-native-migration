page 60020 "DXR Migration Control Center"
{
    PageType = ListPlus;
    SourceTable = "DXR MCC Extension";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'DXR Migration Control Center';
    SourceTableView = sorting("Order No.");

    layout
    {
        area(content)
        {
            group(Portfolio)
            {
                Caption = 'Portafolio';
                field(OldRecordsPendingMigration; OldRecordsPendingMigration)
                {
                    Caption = 'Old Records Pending Migration';
                    ToolTip = 'Sum of Gap (Old Record Count - Migrated Record Count) across every table-pair concept in the whole portfolio - literal record count still not migrated. 0 only means every table-pair concept has been recounted and shows no gap; concepts never counted yet (Status = Not Counted) don''t contribute here until Recount All or a real run has touched them - see the "Not Counted" total alongside it.';
                    Editable = false;
                    StyleExpr = 'Strong';
                }
                field(ConceptsNotYetCounted; ConceptsNotYetCounted)
                {
                    Caption = 'Concepts Not Yet Counted';
                    ToolTip = 'Table-pair concepts that have never been counted (Recount All / a run hasn''t touched them yet) - their real Gap isn''t known and isn''t included in "Old Records Pending Migration" above until they are.';
                    Editable = false;
                }
            }
            repeater(Group)
            {
                field(Code; Rec.Code) { }
                field(Name; Rec.Name) { }
                field("Order No."; Rec."Order No.") { }
                field("Total Concepts"; Rec."Total Concepts") { }
                field("Total Gap"; Rec."Total Gap") { }
                field("Last Run DateTime"; Rec."Last Run DateTime") { }
                field(Notes; Rec.Notes) { }
            }
            part(Concepts; "DXR MCC Concept Subform")
            {
                Caption = 'Concepts';
                SubPageLink = "Extension Code" = field(Code);
                UpdatePropagation = Both;
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunExtension)
            {
                Caption = 'Run All Phases For This Extension';
                ApplicationArea = All;
                Image = Start;
                ToolTip = 'Schedules every non-blocked phase for this extension as an immediate background task. The page never executes a dispatcher synchronously; monitor status, heartbeat and outcome in DXR MCC Run Requests/Run Log.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                begin
                    Executor.ScheduleExtension(Rec.Code);
                    CurrPage.Update(false);
                    CurrPage.Concepts.Page.Update(false);
                    Message('Scheduled. Open "DXR MCC Run Requests" to monitor %1, or Run Log for dispatcher details.', Rec.Code);
                end;
            }
            action(RunPortfolio)
            {
                Caption = 'Run Entire Portfolio';
                ApplicationArea = All;
                Image = ExecuteBatch;
                ToolTip = 'Schedules a background task that runs every non-blocked migration phase across the whole portfolio, in 4 passes - Setup, then Master/Accounting, then Historic, then Other - each pass in extension dependency order. Setup always finishes for every dependent module before Master/Accounting or Historic starts anywhere. Runs in the background (2026-08-22: reverted from inline execution - the whole portfolio in one interactive request caused a server-side timeout on a real tenant once the registry grew past ~600 concepts). Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                begin
                    if not Confirm('Schedule a background run of every non-blocked migration phase across the whole portfolio (Setup pass, then Master/Accounting, then Historic, then Other - each in dependency order)? This is the whole portfolio and can take several minutes to finish.') then
                        exit;
                    Executor.SchedulePortfolio();
                    Message('Scheduled. Open "DXR MCC Run Requests" to watch progress, or Run Log once it finishes.');
                end;
            }
            action(RunAllSetup)
            {
                Caption = 'Run All Setup';
                ApplicationArea = All;
                Image = Setup;
                ToolTip = 'Schedules a background task that runs every non-blocked Setup-category concept across every extension that has one, in dependency order (Order No.). Use this to bring every dependent module''s setup/configuration data current before running Master/Accounting or Historic. Runs in the background (2026-08-22: reverted from inline execution - a dispatcher can''t be scoped to only its Setup-tagged work, so this triggers each affected extension''s FULL migration workload, which caused a server-side timeout when run inline once the registry grew past ~600 concepts). Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                    Concept: Record "DXR MCC Concept";
                begin
                    if not Confirm('Schedule a background run of every non-blocked Setup-category migration phase across the whole portfolio, in dependency order?') then
                        exit;
                    Executor.ScheduleCategory(Concept.Category::Setup);
                    Message('Scheduled. Open "DXR MCC Run Requests" to watch progress, or Run Log once it finishes.');
                end;
            }
            action(RunAllMasterAccounting)
            {
                Caption = 'Run All Master/Accounting';
                ApplicationArea = All;
                Image = ChartOfAccounts;
                ToolTip = 'Schedules a background task that runs every non-blocked Master/Accounting-category concept (master data, ledgers, transactional documents) across every extension that has one, in dependency order. Run All Setup first if it hasn''t already run - master/accounting data can reference setup rows. Runs in the background, same reason as Run All Setup. Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                    Concept: Record "DXR MCC Concept";
                begin
                    if not Confirm('Schedule a background run of every non-blocked Master/Accounting-category migration phase across the whole portfolio, in dependency order?') then
                        exit;
                    Executor.ScheduleCategory(Concept.Category::"Master/Accounting");
                    Message('Scheduled. Open "DXR MCC Run Requests" to watch progress, or Run Log once it finishes.');
                end;
            }
            action(RunAllHistoric)
            {
                Caption = 'Run All Historic';
                ApplicationArea = All;
                Image = History;
                ToolTip = 'Schedules a background task that runs every non-blocked Historic-category concept (logs, posted/archival data, status history) across every extension that has one, in dependency order. Runs in the background, same reason as Run All Setup. Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                    Concept: Record "DXR MCC Concept";
                begin
                    if not Confirm('Schedule a background run of every non-blocked Historic-category migration phase across the whole portfolio, in dependency order?') then
                        exit;
                    Executor.ScheduleCategory(Concept.Category::Historic);
                    Message('Scheduled. Open "DXR MCC Run Requests" to watch progress, or Run Log once it finishes.');
                end;
            }
            action(RecountAll)
            {
                Caption = 'Recount All';
                ApplicationArea = All;
                Image = Refresh;
                ToolTip = 'Recounts Old/Migrated/Gap for every concept (does not run any dispatcher, just reopens and counts the Legacy/New tables). Runs as a background task, not inline - with 600+ concepts across the portfolio, some pointing at large standard tables, doing this in one interactive request caused a server-side timeout on a real tenant. Check DXR MCC Run Requests for the outcome.';
                trigger OnAction()
                var
                    Executor: Codeunit "DXR MCC Executor";
                begin
                    Executor.ScheduleRecountAll();
                    Message('Scheduled. Open "DXR MCC Run Requests" to watch progress - with 600+ concepts this can take a few minutes.');
                end;
            }
            action(ReloadRegistry)
            {
                Caption = 'Reload Registry';
                ApplicationArea = All;
                Image = RefreshLines;
                trigger OnAction()
                var
                    Loader: Codeunit "DXR MCC Registry Loader";
                begin
                    Loader.Run();
                    CurrPage.Update(false);
                    Message('Registry reloaded.');
                end;
            }
            action(SeedUpgradeTags)
            {
                Caption = 'Seed Known Upgrade Tags';
                ApplicationArea = All;
                Image = TileSettings;
                ToolTip = 'Fills in "Upgrade Tags" for concepts whose exact tag has been verified against the owning extension''s own source - only where currently blank, never overwrites an operator-set value. Run this once after Reload Registry to unlock "Force Rerun" for the concepts it covers.';
                trigger OnAction()
                var
                    Seeder: Codeunit "DXR MCC Upgrade Tag Seed";
                begin
                    Seeder.SeedAllKnownTags();
                    CurrPage.Update(false);
                end;
            }
            action(OpenRunRequests)
            {
                Caption = 'Run Requests';
                ApplicationArea = All;
                Image = TaskList;
                ToolTip = 'Background runs scheduled from this page - status, timing, and result summary per run.';
                RunObject = page "DXR MCC Run Requests";
            }
            action(OpenRunLog)
            {
                Caption = 'Run Log';
                ApplicationArea = All;
                Image = Log;
                RunObject = page "DXR MCC Run Log";
            }
            action(OpenGapReport)
            {
                Caption = 'Extension Gap Report';
                ApplicationArea = All;
                Image = Report;
                RunObject = report "DXR MCC Extension Gap Report";
            }
            action(OpenTableMap)
            {
                Caption = 'Table Map (Legacy -> Active)';
                ApplicationArea = All;
                Image = ItemTracking;
                ToolTip = 'Shows every legacy table this portfolio migrates and exactly which active table it feeds - real table names resolved, not just IDs.';
                RunObject = page "DXR MCC Table Map";
            }
        }
    }

    trigger OnOpenPage()
    begin
        RefreshPortfolioTotals();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshPortfolioTotals();
    end;

    local procedure RefreshPortfolioTotals()
    var
        Concept: Record "DXR MCC Concept";
    begin
        Concept.SetFilter("Legacy Table ID", '<>%1', 0);
        Concept.SetRange(Status, Concept.Status::"Not Counted");
        ConceptsNotYetCounted := Concept.Count();

        Concept.SetRange(Status);
        Concept.SetFilter(Status, '<>%1', Concept.Status::"Not Counted");
        Concept.CalcSums(Gap);
        OldRecordsPendingMigration := Concept.Gap;
    end;

    var
        OldRecordsPendingMigration: Integer;
        ConceptsNotYetCounted: Integer;
}
