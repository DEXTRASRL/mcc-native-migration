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
            action(ViewTiming)
            {
                Caption = 'Ver Tiempos por Fase';
                ApplicationArea = All;
                Image = Timesheet;
                ToolTip = 'Muestra inicio, finalización, duración y estado de Setup, Master/Accounting, Historic y Other para el Run Entire Portfolio seleccionado.';

                trigger OnAction()
                begin
                    Page.Run(Page::"DXR MCC Run Timing", Rec);
                end;
            }
            action(Cancel)
            {
                Caption = 'Cancel';
                ApplicationArea = All;
                Image = Cancel;
                ToolTip = 'Requests cancellation of this run. Takes effect at the next safe boundary (between extensions/concepts, not mid-dispatcher-call - a dispatcher already running can''t be interrupted), same granularity as its own checkpointing. A Scheduled row not yet started is cancelled immediately (removed from the platform''s own task queue via TaskScheduler.CancelTask, not just a cooperative flag).';
                Enabled = IsCancellableStatus;
                trigger OnAction()
                begin
                    if IsCancellableStatus then begin
                        // 2026-08-25: for a Status = Scheduled row (CreateTask already called, task
                        // not yet started), the cooperative "Cancel Requested" flag alone still lets
                        // the background session spin up, run OnRun(), check the flag, and exit - a
                        // wasted TaskScheduler slot, and (per Microsoft's own Task Scheduler docs,
                        // https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/
                        // developer/devenv-task-scheduler) not the documented way to remove a task
                        // from the platform's own Scheduled Task queue (table 2000000175) - that's
                        // TaskScheduler.CancelTask(Guid), gated by TaskExists() since a task that
                        // already started (or never existed, e.g. "Task Id" left blank because
                        // CanCreateTask() was false and the run went synchronous) can't be cancelled
                        // this way. Once a task has actually STARTED executing as a background
                        // session, AL offers no API to forcibly kill it - CancelTask only ever
                        // touches the queue entry, never a live session (confirmed against the same
                        // docs; killing an active session is an admin/Session-Management action, not
                        // something callable from here) - the cooperative flag below remains the only
                        // mechanism for a run that's already in progress, same as before this change.
                        if not IsNullGuid(Rec."Task Id") then
                            if TaskScheduler.TaskExists(Rec."Task Id") then
                                TaskScheduler.CancelTask(Rec."Task Id");

                        Rec."Cancel Requested" := true;
                        Rec.Modify(true);
                        Message('Cancelación solicitada. El estado cambiará a Cancelled en el próximo punto seguro (no instantáneo si hay un dispatcher en ejecución).');
                        CurrPage.Update(false);
                    end;
                end;
            }
            action(ForceDelete)
            {
                Caption = 'Forzar Cancelación y Eliminar';
                ApplicationArea = All;
                Image = Delete;
                ToolTip = 'Uso de emergencia: para una fila que queda "enganchada" en Running/Scheduled sin avanzar y que "Cancel" no logra destrabar (la sesión en background está genuinamente colgada, no solo lenta). Cancela la tarea en la cola de TaskScheduler si todavía existe, libera el lock de migración de inmediato (sin esperar su expiración ni el auto-heal de 4 horas) y ELIMINA esta fila por completo - no queda en Cancelled, desaparece de la lista - para poder iniciar una ejecución nueva sin obstáculos. No puede detener una sesión en background que ya esté genuinamente en ejecución (AL no ofrece esa capacidad - ver el comentario de la acción "Cancel"); si la tarea vieja de verdad sigue viva, podría seguir corriendo en paralelo con la nueva hasta que la plataforma la termine por su cuenta.';
                trigger OnAction()
                var
                    LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
                    EntryNo: Integer;
                begin
                    if not Confirm('¿Forzar cancelación y ELIMINAR por completo la fila %1 (Estado: %2)? Esta acción no se puede deshacer.', false, Rec."Entry No.", Format(Rec.Status)) then
                        exit;

                    EntryNo := Rec."Entry No.";

                    if not IsNullGuid(Rec."Task Id") then
                        if TaskScheduler.TaskExists(Rec."Task Id") then
                            TaskScheduler.CancelTask(Rec."Task Id");

                    LockMgt.ForceReleaseLockForRunRequest(EntryNo);
                    Rec.Delete(false);

                    Message('Fila %1 eliminada y lock liberado. Ya puede iniciar una nueva ejecución.', EntryNo);
                    CurrPage.Update(false);
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
