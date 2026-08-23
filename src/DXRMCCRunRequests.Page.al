page 60023 "DXR MCC Run Requests"
{
    PageType = List;
    SourceTable = "DXR MCC Run Request";
    ApplicationArea = All;
    UsageCategory = History;
    Caption = 'DXR MCC Run Requests';
    Editable = false;
    SourceTableView = sorting("Entry No.") order(descending);
    // 2026-08-22 (requested: avoid pressing Refresh constantly to see progress). RefreshOnActivate
    // is the one real, documented AL mechanism for this - it re-reads the page's data whenever the
    // user navigates BACK to it from another page (e.g. after opening "Ver Detalle/Errores" and
    // closing it). There is no native AL/BC platform feature for a page to poll/refresh itself on a
    // timer while the user stays on it without navigating away - that would require a custom
    // JavaScript control add-in (confirmed via Microsoft Learn docs search, not guessed); flagging
    // this limitation honestly rather than pretending to implement a timer that doesn't exist.
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.") { }
                field(Scope; Rec.Scope) { }
                field(Category; Rec.Category) { Visible = false; }
                field("Extension Code"; Rec."Extension Code") { }
                field("Concept Entry No."; Rec."Concept Entry No.") { }
                field(Status; Rec.Status) { }
                field("Current Step"; Rec."Current Step") { }
                field("Last Heartbeat"; Rec."Last Heartbeat")
                {
                    ToolTip = 'Last time this request proved it was still actively running. If Status is still Running well after this stops updating, the background session was likely killed by the platform - it will auto-correct to Failed next time a run is scheduled or this page is opened.';
                }
                field("Checkpoint Key"; Rec."Checkpoint Key") { Visible = false; }
                field("Processed Count"; Rec."Processed Count") { }
                field("Cancel Requested"; Rec."Cancel Requested") { Visible = false; }
                field("Attempt No."; Rec."Attempt No.") { }
                field("Scheduled At"; Rec."Scheduled At") { }
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
                    CurrPage.Update(false);
                end;
            }
            action(ViewLog)
            {
                Caption = 'Ver Detalle/Errores';
                ApplicationArea = All;
                Image = ErrorLog;
                ToolTip = 'Abre DXR MCC Run Log filtrado a únicamente los conceptos que este run tocó - la causa real de cada "failed"/"completed with gaps" del resumen agregado (Result Summary solo trae el conteo, no el detalle).';
                trigger OnAction()
                var
                    RunLog: Record "DXR MCC Run Log";
                begin
                    RunLog.SetRange("Run Request Entry No.", Rec."Entry No.");
                    Page.Run(Page::"DXR MCC Run Log", RunLog);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Requests cancellation of this run. Takes effect at the next safe boundary (between extensions/concepts, not mid-dispatcher-call - a dispatcher already running can''t be interrupted), same granularity as its own checkpointing. A Scheduled row not yet started is cancelled immediately.';
                Enabled = IsCancellableStatus;
                trigger OnAction()
                begin
                    if IsCancellableStatus then begin
                        Rec."Cancel Requested" := true;
                        Rec.Modify(true);
                        Message('Cancelación solicitada. El estado cambiará a Cancelled en el próximo punto seguro (no instantáneo si hay un dispatcher en ejecución).');
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        Executor: Codeunit "DXR MCC Executor";
    begin
        // Self-heal any row stuck at Running with a stale/blank heartbeat before the operator sees
        // it - see "Last Heartbeat" on the table and ReconcileStaleRunningRequests's own comment.
        Executor.ReconcileStaleRunningRequests();
    end;

    trigger OnAfterGetRecord()
    begin
        IsCancellableStatus := Rec.Status in [Rec.Status::Scheduled, Rec.Status::Running];
    end;

    var
        IsCancellableStatus: Boolean;
}
