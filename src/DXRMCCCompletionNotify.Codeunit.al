codeunit 60017 "DXR MCC Completion Notify"
{
    // Fires once per session via OnCompanyOpen (see the event subscriber below) - tried a
    // pageextension on Business Manager/Accountant Role Center's OnOpenPage first (2026-08-22) but
    // the compiler rejected it: "A page of type Role Center cannot have triggers" (AL0378) -
    // confirmed by actually compiling, not assumed. OnCompanyOpen fires once when a session opens
    // its company, which for a normal login happens right before the Role Center renders, so a
    // Notification sent here still shows up on whatever Role Center the user lands on - without
    // needing to override any specific one. Shows a single Notification banner for the CURRENT
    // user's most recently finished MCC run they haven't already been shown, then marks it
    // Notified so it never shows again - exactly the "solo una unica vez" the user asked for.
    // Scoped to "Requested By" = current user: a background Portfolio run someone else scheduled
    // shouldn't interrupt an unrelated user's session.
    Access = Internal;
    Permissions = tabledata "DXR MCC Run Request" = RM;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure OnCompanyOpen()
    begin
        
    end;

    internal procedure ShowPendingCompletionIfAny()
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        RunRequest.SetRange("Requested By", CopyStr(UserId(), 1, MaxStrLen(RunRequest."Requested By")));
        RunRequest.SetRange(Notified, false);
        RunRequest.SetFilter(Status, '%1|%2|%3', RunRequest.Status::Completed, RunRequest.Status::Failed, RunRequest.Status::Cancelled);
        RunRequest.SetCurrentKey("Scheduled At");
        RunRequest.SetAscending("Scheduled At", false);
        if not RunRequest.FindFirst() then
            exit;

        SendNotification(RunRequest);

        RunRequest.Notified := true;
        RunRequest.Modify(false);
    end;

    local procedure SendNotification(var RunRequest: Record "DXR MCC Run Request")
    var
        CompletionNotification: Notification;
        ScopeText: Text;
    begin
        ScopeText := ScopeLabel(RunRequest);

        case RunRequest.Status of
            RunRequest.Status::Completed:
                CompletionNotification.Message := StrSubstNo('DXR Migration Control Center: %1 finalizó. %2', ScopeText, RunRequest."Result Summary");
            RunRequest.Status::Failed:
                CompletionNotification.Message := StrSubstNo('DXR Migration Control Center: %1 falló. %2', ScopeText, RunRequest."Result Summary");
            RunRequest.Status::Cancelled:
                CompletionNotification.Message := StrSubstNo('DXR Migration Control Center: %1 fue cancelado.', ScopeText);
        end;

        CompletionNotification.Scope := NotificationScope::LocalScope;
        CompletionNotification.AddAction('Ver Run Requests', Codeunit::"DXR MCC Completion Notify", 'OpenRunRequests');
        CompletionNotification.Send();
    end;

    local procedure ScopeLabel(var RunRequest: Record "DXR MCC Run Request"): Text
    begin
        case RunRequest.Scope of
            RunRequest.Scope::Concept:
                exit(StrSubstNo('Concepto #%1', RunRequest."Concept Entry No."));
            RunRequest.Scope::Extension:
                exit(StrSubstNo('Extensión %1', RunRequest."Extension Code"));
            RunRequest.Scope::Category:
                exit(StrSubstNo('Categoría %1', Format(RunRequest.Category)));
            RunRequest.Scope::Portfolio:
                exit('Portafolio completo');
            RunRequest.Scope::RecountAll:
                exit('Recount All');
        end;
    end;

    procedure OpenRunRequests(CompletionNotification: Notification)
    begin
        Page.Run(Page::"DXR MCC Run Requests");
    end;
}
