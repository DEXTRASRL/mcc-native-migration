codeunit 60013 "DXR MCC Background Runner"
{
    // Invoked by TaskScheduler (see the "Run" actions on page 60020/60022), never called
    // directly from a page action. Runs detached from the interactive session, so a long
    // dispatcher chain (BELLON alone chains 7 phase codeunits, each a full-table RecordRef scan)
    // no longer blocks/appears-to-freeze the BC client the way a synchronous Codeunit.Run() call
    // from a button click did.
    //
    // Deliberately no ErrorCodeunitID on the CreateTask call (see the "Run" actions): whether
    // TaskScheduler actually passes the same RecordId through to an error codeunit is not
    // something this session could verify against a real server, and Bellon Migr. Failure
    // Handler's own comment notes AL doesn't expose the original exception text in that context
    // anyway. Instead this codeunit catches its own errors via TryFunction, which reliably has
    // GetLastErrorText() available, and writes the failure onto its own Run Request row directly
    // — the one case this doesn't cover directly is the task being killed by the platform itself
    // (session terminated, resource pressure, or the 12-hour SaaS TaskScheduler default timeout
    // - confirmed via Microsoft Learn, since CreateTask is never called here with an explicit
    // Timeout), which used to leave the row stuck showing Running forever with no way to tell it
    // apart from "still working". "Last Heartbeat" (stamped here and by Executor.
    // CheckCancelAndUpdateStep) plus Executor.ReconcileStaleRunningRequests now self-heal that:
    // any Running row whose heartbeat has gone stale gets marked Failed the next time a Schedule*
    // action runs or the Run Requests page opens.
    TableNo = "DXR MCC Run Request";
    Permissions =
        tabledata "DXR MCC Run Request" = RIMD,
        tabledata "DXR MCC Concept" = RIMD,
        tabledata "DXR MCC Run Log" = RIMD;

    trigger OnRun()
    var
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
        ResultSummary: Text[250];
        FailureText: Text;
    begin
        // Cooperative cancel: if "Cancel" was pressed while this request was still Scheduled
        // (waiting for its TaskScheduler slot), honor it here instead of starting the work at all.
        if Rec."Cancel Requested" then begin
            Rec.Status := Rec.Status::Cancelled;
            Rec."Completed At" := CurrentDateTime();
            Rec."Result Summary" := 'Cancelado antes de iniciar.';
            Rec.Modify(true);
            LockMgt.ForceReleaseLockForRunRequest(Rec."Entry No.");
            exit;
        end;

        Rec.Status := Rec.Status::Running;
        Rec."Last Heartbeat" := CurrentDateTime();
        Rec.Modify(true);
        Commit();

        if TryRunScope(Rec, ResultSummary) then begin
            // RunCategory/RunPortfolio/RecountAllConcepts write Status = Cancelled directly onto
            // this same row (MarkRunRequestCancelled) if Cancel Requested was set mid-run - never
            // overwrite that back to Completed just because TryRunScope itself didn't error.
            Rec.Find();
            if Rec.Status = Rec.Status::Cancelled then begin
                LockMgt.ForceReleaseLockForRunRequest(Rec."Entry No.");
                exit;
            end;

            Rec.Status := Rec.Status::Completed;
            Rec."Result Summary" := ResultSummary;
            Rec."Completed At" := CurrentDateTime();
            Rec."Current Step" := '';
            Rec.Modify(true);
            LockMgt.ForceReleaseLockForRunRequest(Rec."Entry No.");
            exit;
        end;

        FailureText := GetLastErrorText();

        // Auto-retry on tag boundaries: every dispatcher codeunit in this portfolio already
        // breaks its own work into upgrade-tag-gated sub-steps (see the class comment above), so
        // re-invoking the same codeunit after a transient failure (lock contention, a permission
        // context glitch under TaskScheduler, a genuine timeout mid-phase) resumes at whatever
        // sub-step granularity that codeunit's own tags already provide - it doesn't redo
        // anything that already set its tag before this attempt died. For Category/Portfolio/
        // RecountAll scopes, "Checkpoint Key" (saved by Executor as each extension/concept
        // finishes) resumes past whatever already finished too, so a retry doesn't restart the
        // whole scope from its first extension. Same exponential-backoff shape as Bellon Migr.
        // Failure Handler's own retry (2/4/8/16/30 min), capped at 5 attempts before giving up.
        // Lock is deliberately NOT released here - this is a continuation of the same logical run,
        // not a new one, so it must keep holding the lock across the retry.
        if (Rec."Attempt No." < MaxAttempts()) and TaskScheduler.CanCreateTask() then begin
            Rec."Attempt No." += 1;
            Rec.Status := Rec.Status::Scheduled;
            Rec."Result Summary" := CopyStr(
                StrSubstNo('Attempt %1 failed, retrying: %2', Rec."Attempt No." - 1, FailureText),
                1, MaxStrLen(Rec."Result Summary"));
            Rec.Modify(true);
            Rec."Task Id" := TaskScheduler.CreateTask(
                Codeunit::"DXR MCC Background Runner", 0, true, CompanyName(),
                CurrentDateTime() + RetryDelay(Rec."Attempt No."), Rec.RecordId());
            Rec.Modify(true);
            exit;
        end;

        Rec.Status := Rec.Status::Failed;
        Rec."Result Summary" := CopyStr(FailureText, 1, MaxStrLen(Rec."Result Summary"));
        Rec."Completed At" := CurrentDateTime();
        Rec.Modify(true);
        LockMgt.ForceReleaseLockForRunRequest(Rec."Entry No.");
    end;

    local procedure MaxAttempts(): Integer
    begin
        exit(5);
    end;

    local procedure RetryDelay(AttemptNo: Integer): Duration
    var
        DelayMinutes: Integer;
    begin
        DelayMinutes := 1;
        while (DelayMinutes < 30) and (AttemptNo > 1) do begin
            DelayMinutes *= 2;
            AttemptNo -= 1;
        end;
        if DelayMinutes > 30 then
            DelayMinutes := 30;
        exit(DelayMinutes * 60 * 1000);
    end;

    [TryFunction]
    local procedure TryRunScope(var Rec: Record "DXR MCC Run Request"; var ResultSummary: Text[250])
    var
        Concept: Record "DXR MCC Concept";
        Executor: Codeunit "DXR MCC Executor";
        Completed: Integer;
        Gaps: Integer;
        Errors: Integer;
        BlockedSkipped: Integer;
        RecountedNo: Integer;
    begin
        case Rec.Scope of
            Rec.Scope::Concept:
                begin
                    if Concept.Get(Rec."Concept Entry No.") then begin
                        Executor.RunConcept(Concept, Rec."Entry No.");
                        ResultSummary := CopyStr(StrSubstNo('Concept "%1": %2.', Concept.Description, Format(Concept.Status)), 1, MaxStrLen(ResultSummary));
                    end else
                        ResultSummary := 'Concept no longer exists.';
                end;
            Rec.Scope::Extension:
                begin
                    Executor.RunExtension(Rec."Extension Code", Completed, Gaps, Errors, BlockedSkipped, Rec."Entry No.");
                    ResultSummary := CopyStr(StrSubstNo(
                        'Extension %1: %2 completed, %3 completed with gaps, %4 failed, %5 skipped (blocked).',
                        Rec."Extension Code", Completed, Gaps, Errors, BlockedSkipped), 1, MaxStrLen(ResultSummary));
                end;
            Rec.Scope::Portfolio:
                begin
                    Executor.RunPortfolio(Completed, Gaps, Errors, BlockedSkipped, Rec."Entry No.");
                    ResultSummary := CopyStr(StrSubstNo(
                        'Portfolio: %1 completed, %2 completed with gaps, %3 failed, %4 skipped (blocked).',
                        Completed, Gaps, Errors, BlockedSkipped), 1, MaxStrLen(ResultSummary));
                end;
            Rec.Scope::Category:
                begin
                    Executor.RunCategory(Rec.Category, Completed, Gaps, Errors, BlockedSkipped, Rec."Entry No.", CopyStr(Rec."Checkpoint Key", 1, 20));
                    ResultSummary := CopyStr(StrSubstNo(
                        'Category %1: %2 completed, %3 completed with gaps, %4 failed, %5 skipped (blocked).',
                        Format(Rec.Category), Completed, Gaps, Errors, BlockedSkipped), 1, MaxStrLen(ResultSummary));
                end;
            Rec.Scope::RecountAll:
                begin
                    RecountedNo := Executor.RecountAllConcepts(Rec."Entry No.");
                    ResultSummary := CopyStr(StrSubstNo('%1 concept(s) recounted.', RecountedNo), 1, MaxStrLen(ResultSummary));
                end;
        end;
    end;
}
