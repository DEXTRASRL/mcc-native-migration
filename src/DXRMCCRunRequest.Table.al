table 60003 "DXR MCC Run Request"
{
    // Backs the unified asynchronous execution model: every "Run" action on the MCC pages
    // schedules one of these via TaskScheduler instead of calling Executor.RunConcept/
    // RunExtension/RunPortfolio synchronously from a page action. A page action running a full
    // dispatcher chain (BELLON alone chains 7 phase codeunits, each a full-table RecordRef scan)
    // in the same interactive transaction is exactly the freeze/timeout the underlying extensions'
    // own dispatchers were built to avoid by running via TaskScheduler in the first place — MCC
    // was reintroducing that problem by calling Codeunit.Run() directly from a button click.
    Caption = 'Migration Control Center Run Request';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Scope"; Option)
        {
            Caption = 'Scope';
            // RecountAll appended 2026-08-22: "Recount All" used to run inline from the page
            // action (a read-only counting loop, no dispatcher involved, so the write-transaction/
            // Subtype=Upgrade platform restrictions never applied to it) - but with ~600+ concepts
            // now in the registry, opening and counting up to ~1200 tables synchronously in one
            // web client request exceeded the platform's own request timeout on a real QA tenant
            // ("Something went wrong" with no AL call stack - a server-side timeout, not a
            // catchable AL error). Moved to the same background-task model as every Run action,
            // for the same reason those were moved there originally (see this table's own header
            // comment) - not something a Commit()/TryFunction fix could address, since the
            // problem was total wall-clock time, not a transaction or exception.
            OptionMembers = Concept,Extension,Portfolio,Category,RecountAll;
            DataClassification = SystemMetadata;
        }
        field(3; "Extension Code"; Code[20])
        {
            Caption = 'Extension Code';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Extension".Code;
        }
        field(4; "Concept Entry No."; Integer)
        {
            Caption = 'Concept Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Concept"."Entry No.";
        }
        field(5; "Status"; Option)
        {
            Caption = 'Status';
            // Cancelled appended 2026-08-22 (Cancel action) - must go last, same reasoning as
            // RecountAll on the Scope field below: existing stored numeric values must not shift.
            OptionMembers = Scheduled,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; "Scheduled At"; DateTime)
        {
            Caption = 'Scheduled At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Task Id"; Guid)
        {
            Caption = 'Task Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(9; "Result Summary"; Text[250])
        {
            Caption = 'Result Summary';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Requested By"; Code[50])
        {
            Caption = 'Requested By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(11; "Attempt No."; Integer)
        {
            Caption = 'Attempt No.';
            DataClassification = SystemMetadata;
            Editable = false;
            // Mirrors Bellon Migr. Failure Handler's own retry pattern (exponential backoff,
            // same tag-boundary resumption every dispatcher codeunit already provides via its
            // own internal upgrade tags - a retry doesn't redo sub-steps that already completed
            // and set their own tag before this attempt failed). Failed does not mean "given up
            // forever" until "Attempt No." reaches the runner's max attempts.
        }
        field(12; "Category"; Option)
        {
            Caption = 'Category';
            // Published ordinals 0..3 are immutable. New requests use the appended values.
            OptionMembers = Setup,"Master/Accounting",Historic,Other,Master,Accounting;
            DataClassification = SystemMetadata;
            Editable = false;
            // Only meaningful when Scope = Category (see DXR MCC Executor.ScheduleCategory /
            // RunCategory) - the same option list as "DXR MCC Concept".Category, kept as its own
            // field rather than a FlowField since a Category-scoped run has no single Concept or
            // Extension row to calculate it from.
        }
        field(13; "Cancel Requested"; Boolean)
        {
            Caption = 'Cancel Requested';
            DataClassification = SystemMetadata;
            // Set by the "Cancel" action (DXR MCC Run Requests page). Checked between extension/
            // category-pass iterations in DXR MCC Executor's RunCategory/RunPortfolio/RunExtension
            // loops - a dispatcher already mid-Codeunit.Run() can't be interrupted (that's a single
            // atomic platform call), so cancellation takes effect at the next safe boundary, not
            // instantly. That's the same granularity the existing table-level checkpointing
            // already works at (see "Checkpoint Key" below), so nothing already-committed is lost.
        }
        field(14; "Checkpoint Key"; Text[250])
        {
            Caption = 'Checkpoint Key';
            DataClassification = SystemMetadata;
            Editable = false;
            // Extension-boundary resume point for Category/Portfolio/RecountAll scopes: the last
            // extension Code (and, for Portfolio, which of the 5 category passes) that finished
            // before a failure/timeout/cancel. On retry (the Background Runner's existing
            // exponential-backoff attempt loop), the run resumes filtering Extension."Order No."
            // strictly after this checkpoint instead of restarting the whole scope from its first
            // extension - mirrors DR-Localization's own "DXR_Internal Migr. Status".SaveCheckpoint/
            // GetCheckpoint pattern (Checkpoint Key + Processed Count), just at the granularity MCC
            // actually controls (which extension ran last), since the per-table row loops inside
            // each extension's own dispatcher codeunit aren't MCC's code to checkpoint mid-loop.
        }
        field(15; "Processed Count"; Integer)
        {
            Caption = 'Processed Count';
            DataClassification = SystemMetadata;
            Editable = false;
            // How many extensions (Category/Portfolio) or concepts (RecountAll) this request has
            // already gotten through - shown next to "Checkpoint Key" so a long-running request's
            // progress is visible without opening Run Log.
        }
        field(16; "Notified"; Boolean)
        {
            Caption = 'Notified';
            DataClassification = SystemMetadata;
            // Set the first time the requesting user has been shown the one-time "migration
            // completed" notification on their Role Center (see DXR MCC Completion Notify.Codeunit
            // .al) - never shown twice for the same request, per explicit request.
        }
        field(17; "Current Step"; Text[250])
        {
            Caption = 'Current Step';
            DataClassification = SystemMetadata;
            Editable = false;
            // Live "what is it doing right now" text, updated (and Committed) as a Category/
            // Portfolio/RecountAll request progresses extension-by-extension - shown directly on
            // DXR MCC Run Requests so the operator doesn't have to guess or open a different page
            // while a background run is in progress. Visible on manual page Refresh (BC list pages
            // don't auto-push updates), same as every other field on a Running row.
        }
        field(18; "Last Heartbeat"; DateTime)
        {
            Caption = 'Last Heartbeat';
            DataClassification = SystemMetadata;
            Editable = false;
            // Added 2026-08-22 (reported: "se queda enganchado... el estado queda en Running
            // indefinidamente"). Root cause confirmed via Microsoft Learn: BC SaaS's
            // TaskScheduler.CreateTask defaults to a 12-hour session timeout when none is passed
            // explicitly (MCC's CreateTask calls never set one), and Background Runner's own
            // pre-existing comment already documented that a task killed by the platform itself
            // (server restart, resource pressure, or genuinely exceeding that timeout) leaves the
            // row stuck showing Running forever - there was never a way to tell "still working" from
            // "died silently". Stamped every time Current Step updates (Executor.
            // CheckCancelAndUpdateStep) and once when the task starts (Background Runner.OnRun), so
            // a stale value means no progress was made for that long, not just "a slow single
            // dispatcher call". See DXR MCC Executor.ReconcileStaleRunningRequests.
        }
        field(19; "Started At"; DateTime)
        {
            Caption = 'Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Setup Started At"; DateTime)
        {
            Caption = 'Setup Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Setup Completed At"; DateTime)
        {
            Caption = 'Setup Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(22; "Setup Duration"; Duration)
        {
            Caption = 'Setup Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(23; "Setup Phase Status"; Option)
        {
            Caption = 'Setup Phase Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(24; "Master/Accounting Started At"; DateTime)
        {
            Caption = 'Master/Accounting Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(25; "Master/Accounting Completed At"; DateTime)
        {
            Caption = 'Master/Accounting Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(26; "Master/Accounting Duration"; Duration)
        {
            Caption = 'Master/Accounting Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(27; "Master/Accounting Status"; Option)
        {
            Caption = 'Master/Accounting Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(28; "Historic Started At"; DateTime)
        {
            Caption = 'Historic Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(29; "Historic Completed At"; DateTime)
        {
            Caption = 'Historic Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(30; "Historic Duration"; Duration)
        {
            Caption = 'Historic Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(31; "Historic Phase Status"; Option)
        {
            Caption = 'Historic Phase Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(32; "Other Started At"; DateTime)
        {
            Caption = 'Other Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(33; "Other Completed At"; DateTime)
        {
            Caption = 'Other Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(34; "Other Duration"; Duration)
        {
            Caption = 'Other Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(35; "Other Phase Status"; Option)
        {
            Caption = 'Other Phase Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(36; "Master Started At"; DateTime)
        {
            Caption = 'Master Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(37; "Master Completed At"; DateTime)
        {
            Caption = 'Master Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(38; "Master Duration"; Duration)
        {
            Caption = 'Master Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(39; "Master Phase Status"; Option)
        {
            Caption = 'Master Phase Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(40; "Accounting Started At"; DateTime)
        {
            Caption = 'Accounting Started At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(41; "Accounting Completed At"; DateTime)
        {
            Caption = 'Accounting Completed At';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(42; "Accounting Duration"; Duration)
        {
            Caption = 'Accounting Duration';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(43; "Accounting Phase Status"; Option)
        {
            Caption = 'Accounting Phase Status';
            OptionMembers = Pending,Running,Completed,Failed,Cancelled;
            DataClassification = SystemMetadata;
            Editable = false;
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Recent; "Scheduled At")
        {
        }
    }
}
