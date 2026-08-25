codeunit 60011 "DXR MCC Executor"
{
    // Progress dialog (added 2026-08-22 per explicit user request - "porque no creamos un modal
    // en el running para mostrar cuales tablas setup de cuentas esta migrando"): since Run
    // actions now execute immediately in the caller's own session instead of a background task,
    // there's no separate place to watch progress live - this dialog is that visual. Each entry
    // point below (RunExtension/RunExtensionCategory/RunConcept) opens its own dialog only once
    // it knows it has at least one non-blocked concept to run (so extensions/categories with
    // nothing to do never flash an empty dialog), updates it once per concept right before
    // running that concept's dispatcher, and closes it before returning. RunCategory calling
    // RunExtensionCategory in a loop means the dialog closes and reopens once per extension - a
    // deliberate, visible "now on extension X" transition, not a bug.
    local procedure OpenProgress(ScopeLabel: Text; TotalConcepts: Integer)
    begin
        ProgressWindow.Open('Migrando...\Alcance:         #1##########################################\Extensión:       #2##########\Estado:          #3####################################################\Detalle:         #4####################################################\Progreso:        #5###### / #6######');
        ProgressWindow.Update(1, CopyStr(ScopeLabel, 1, 250));
        TotalProgressCount := TotalConcepts;
        CurrentProgressCount := 0;
    end;

    // Called once when a NEW (not-yet-run) dispatcher codeunit is about to be invoked - shows how
    // many concept rows share it BEFORE the blocking Codeunit.Run() call, so a dispatcher that
    // covers many tables in one go (e.g. DRLOC-P2's Bootstrap phase, 18 concepts, one call) reads
    // clearly as "this may take a while, it's not just the first table shown" instead of looking
    // frozen on whichever concept happened to be first - confirmed live 2026-08-22 (user watched
    // the dialog appear "stuck" on "Company Information fields" while ~18 tables actually ran
    // behind that label).
    local procedure UpdateProgressStarting(ExtensionCode: Code[20]; DispatcherDescription: Text; SharedByCount: Integer)
    begin
        ProgressWindow.Update(2, ExtensionCode);
        if SharedByCount > 1 then
            ProgressWindow.Update(3, StrSubstNo('Ejecutando (%1 tablas/campos en este paso, puede tardar)...', SharedByCount))
        else
            ProgressWindow.Update(3, 'Ejecutando...');
        ProgressWindow.Update(4, CopyStr(DispatcherDescription, 1, 250));
        ProgressWindow.Update(5, CurrentProgressCount);
        ProgressWindow.Update(6, TotalProgressCount);
    end;

    // Called once per concept in the verification pass (AFTER the dispatcher already ran) - this
    // is the real, per-table proof of completion the user asked for ("como sabemos que de verdad
    // completo cada tabla?"): actual counted Old/Migrated/Gap numbers from Counter.CountConcept,
    // not just "the dispatcher didn't error." Fast per iteration (a row count, not a migration),
    // so this part of the dialog genuinely progresses one table at a time.
    local procedure UpdateProgressVerified(ExtensionCode: Code[20]; ConceptDescription: Text; Status: Option; OldCount: Integer; MigratedCount: Integer; Gap: Integer)
    var
        Concept: Record "DXR MCC Concept";
    begin
        CurrentProgressCount += 1;
        ProgressWindow.Update(2, ExtensionCode);
        ProgressWindow.Update(3, StrSubstNo('Verificado: %1', Format(Status)));
        if Status = Concept.Status::"Not Row-Based" then
            ProgressWindow.Update(4, CopyStr(ConceptDescription, 1, 250))
        else
            ProgressWindow.Update(4, CopyStr(StrSubstNo('%1 (Old: %2, Migrated: %3, Gap: %4)', ConceptDescription, OldCount, MigratedCount, Gap), 1, 250));
        ProgressWindow.Update(5, CurrentProgressCount);
        ProgressWindow.Update(6, TotalProgressCount);
    end;

    local procedure CloseProgress()
    begin
        ProgressWindow.Close();
    end;

    procedure RunExtension(ExtensionCode: Code[20]; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer)
    begin
        RunExtension(ExtensionCode, CompletedCount, GapCount, ErrorCount, BlockedCount, 0);
    end;

    /// <summary>RunRequestEntryNo-aware overload - tags every Run Log entry this call produces so "DXR MCC Run Requests" can filter straight to just this run's errors instead of only showing an aggregate count.</summary>
    procedure RunExtension(ExtensionCode: Code[20]; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer)
    var
        Concept: Record "DXR MCC Concept";
        DispatcherErrors: Dictionary of [Integer, Text];
        DispatcherDurations: Dictionary of [Integer, Integer];
        DispatcherShareCount: Dictionary of [Integer, Integer];
        ErrorText: Text;
        DurationMs: Integer;
        ShareCount: Integer;
    begin
        Concept.SetRange("Extension Code", ExtensionCode);
        Concept.SetRange(Blocked, true);
        BlockedCount += Concept.Count();

        Concept.SetRange(Blocked, false);
        Concept.SetCurrentKey("Extension Code", "Sequence No.");
        if not Concept.FindSet() then
            exit;

        OpenProgress(StrSubstNo('Extensión: %1', ExtensionCode), Concept.Count());

        // Pre-pass: count how many concepts share each dispatcher, so the "starting" message
        // below can say "N tablas" instead of the misleading single first-concept label.
        repeat
            if DispatcherShareCount.Get(Concept."Dispatcher Codeunit ID", ShareCount) then
                DispatcherShareCount.Set(Concept."Dispatcher Codeunit ID", ShareCount + 1)
            else
                DispatcherShareCount.Add(Concept."Dispatcher Codeunit ID", 1);
        until Concept.Next() = 0;

        Concept.FindSet();
        repeat
            if not DispatcherErrors.ContainsKey(Concept."Dispatcher Codeunit ID") then begin
                if IsDispatcherAlreadyDone(Concept."Dispatcher Codeunit ID") then begin
                    DispatcherErrors.Add(Concept."Dispatcher Codeunit ID", '');
                    DispatcherDurations.Add(Concept."Dispatcher Codeunit ID", 0);
                end else begin
                    DispatcherShareCount.Get(Concept."Dispatcher Codeunit ID", ShareCount);
                    UpdateProgressStarting(Concept."Extension Code", Concept.Description, ShareCount);
                    LogConceptsStarting(Concept."Dispatcher Codeunit ID", RunRequestEntryNo);
                    RunDispatcher(Concept."Dispatcher Codeunit ID", ErrorText, DurationMs);
                    DispatcherErrors.Add(Concept."Dispatcher Codeunit ID", ErrorText);
                    DispatcherDurations.Add(Concept."Dispatcher Codeunit ID", DurationMs);
                end;
            end;
        until Concept.Next() = 0;

        Concept.FindSet();
        repeat
            DispatcherErrors.Get(Concept."Dispatcher Codeunit ID", ErrorText);
            DispatcherDurations.Get(Concept."Dispatcher Codeunit ID", DurationMs);
            LogAndCount(Concept, ErrorText, DurationMs, RunRequestEntryNo);
            UpdateProgressVerified(Concept."Extension Code", Concept.Description, Concept.Status, Concept."Old Record Count", Concept."Migrated Record Count", Concept.Gap);
            case Concept.Status of
                Concept.Status::Completed:
                    CompletedCount += 1;
                Concept.Status::"Completed With Gaps":
                    GapCount += 1;
                Concept.Status::Error:
                    ErrorCount += 1;
            end;
        until Concept.Next() = 0;
        CloseProgress();
        Commit();
    end;

    procedure RunConcept(var Concept: Record "DXR MCC Concept")
    begin
        RunConcept(Concept, 0);
    end;

    /// <summary>RunRequestEntryNo-aware overload - same reasoning as RunExtension's.</summary>
    procedure RunConcept(var Concept: Record "DXR MCC Concept"; RunRequestEntryNo: Integer)
    var
        ErrorText: Text;
        DurationMs: Integer;
    begin
        if Concept.Blocked then
            exit;
        OpenProgress('Concepto individual', 1);
        UpdateProgressStarting(Concept."Extension Code", Concept.Description, 1);
        LogConceptsStarting(Concept."Dispatcher Codeunit ID", RunRequestEntryNo);
        RunDispatcher(Concept."Dispatcher Codeunit ID", ErrorText, DurationMs);
        LogAndCount(Concept, ErrorText, DurationMs, RunRequestEntryNo);
        UpdateProgressVerified(Concept."Extension Code", Concept.Description, Concept.Status, Concept."Old Record Count", Concept."Migrated Record Count", Concept.Gap);
        CloseProgress();
    end;

    /// <summary>
    /// Runs every non-blocked concept across the whole portfolio in 4 category passes - Setup,
    /// then Master/Accounting, then Historic, then Other - each pass itself iterating extensions
    /// in dependency order (Order No.) exactly like RunExtension does within a pass. Setup goes
    /// first, unconditionally, across every dependent module before any other category starts:
    /// master/transactional/historic data on any extension can reference that same extension's
    /// (or an upstream extension's) setup/config rows, so those need to exist first everywhere,
    /// not just within one extension's own sequence. This replaced the earlier pure per-extension-
    /// then-sequence order (still exactly what RunExtension/RunCategory do *within* one extension
    /// or one category) once the portfolio has more than one extension whose Setup concepts are
    /// sequenced after another extension's non-Setup ones under the old single pass.
    /// </summary>
    procedure RunPortfolio(var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer)
    begin
        RunPortfolio(CompletedCount, GapCount, ErrorCount, BlockedCount, 0);
    end;

    /// <summary>
    /// RunRequestEntryNo-aware overload: resumes from Checkpoint Key ("CategoryOrdinal:" once a
    /// category fully finishes), the last category pass that finished before a prior attempt
    /// failed/timed out, instead of restarting Setup from its very first extension every retry.
    /// Checked for Cancel Requested between every category pass and (inside RunCategory) between
    /// every extension.
    /// </summary>
    procedure RunPortfolio(var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer)
    var
        Concept: Record "DXR MCC Concept";
        RunRequest: Record "DXR MCC Run Request";
        StartCategoryOrdinal: Integer;
        CategoryOrdinal: Integer;
        ColonPos: Integer;
    begin
        StartCategoryOrdinal := 0;
        if (RunRequestEntryNo <> 0) and RunRequest.Get(RunRequestEntryNo) and (RunRequest."Checkpoint Key" <> '') then begin
            ColonPos := StrPos(RunRequest."Checkpoint Key", ':');
            if ColonPos > 1 then
                if not Evaluate(StartCategoryOrdinal, CopyStr(RunRequest."Checkpoint Key", 1, ColonPos - 1)) then
                    StartCategoryOrdinal := 0;
        end;

        for CategoryOrdinal := StartCategoryOrdinal to 3 do begin
            if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('Portafolio: iniciando categoría %1/4', CategoryOrdinal + 1)) then begin
                MarkRunRequestCancelled(RunRequestEntryNo);
                exit;
            end;
            case CategoryOrdinal of
                0:
                    RunCategory(Concept.Category::Setup, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, PortfolioResumeExtCode(RunRequestEntryNo, CategoryOrdinal));
                1:
                    RunCategory(Concept.Category::"Master/Accounting", CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, PortfolioResumeExtCode(RunRequestEntryNo, CategoryOrdinal));
                2:
                    RunCategory(Concept.Category::Historic, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, PortfolioResumeExtCode(RunRequestEntryNo, CategoryOrdinal));
                3:
                    RunCategory(Concept.Category::Other, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, PortfolioResumeExtCode(RunRequestEntryNo, CategoryOrdinal));
            end;
            SaveCheckpoint(RunRequestEntryNo, StrSubstNo('%1:', CategoryOrdinal + 1), CategoryOrdinal + 1);
        end;
    end;

    /// <summary>Only the resuming category (the one named in the checkpoint) skips its already-done extensions - every later category pass always starts from its own first extension.</summary>
    local procedure PortfolioResumeExtCode(RunRequestEntryNo: Integer; CategoryOrdinal: Integer): Code[20]
    var
        RunRequest: Record "DXR MCC Run Request";
        CheckpointOrdinal: Integer;
        ColonPos: Integer;
    begin
        if RunRequestEntryNo = 0 then
            exit('');
        if not RunRequest.Get(RunRequestEntryNo) then
            exit('');
        if RunRequest."Checkpoint Key" = '' then
            exit('');

        ColonPos := StrPos(RunRequest."Checkpoint Key", ':');
        if ColonPos = 0 then
            exit('');
        if not Evaluate(CheckpointOrdinal, CopyStr(RunRequest."Checkpoint Key", 1, ColonPos - 1)) then
            exit('');
        if CheckpointOrdinal <> CategoryOrdinal then
            exit('');

        exit(CopyStr(RunRequest."Checkpoint Key", ColonPos + 1));
    end;

    /// <summary>
    /// Runs every non-blocked concept of one Category across the whole portfolio, in extension
    /// dependency order (Order No.), then by that extension's own Sequence No. within the
    /// category - same dedup-by-dispatcher-codeunit and same LogAndCount/fallback path as
    /// RunExtension, just filtered to one category and spanning every extension instead of one.
    /// </summary>
    procedure RunCategory(Category: Option Setup,"Master/Accounting",Historic,Other; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer)
    begin
        RunCategory(Category, CompletedCount, GapCount, ErrorCount, BlockedCount, 0, '');
    end;

    /// <summary>
    /// RunRequestEntryNo-aware overload. ResumeAfterExtCode (from Checkpoint Key, empty on a fresh
    /// run) skips every extension up to and including that one - the extensions before it are
    /// assumed already done from a prior attempt, since Checkpoint Key is only ever set AFTER an
    /// extension's own RunExtensionCategory call returns.
    /// </summary>
    procedure RunCategory(Category: Option Setup,"Master/Accounting",Historic,Other; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer; ResumeAfterExtCode: Code[20])
    var
        Extension: Record "DXR MCC Extension";
        PastCheckpoint: Boolean;
        ProcessedNo: Integer;
    begin
        // Safety: if the checkpointed extension no longer exists (registry changed between
        // attempts), don't silently skip the entire category by never finding it to resume past -
        // treat as a fresh start instead. Checked (and the record variable reset via FindSet
        // below) BEFORE the real iteration starts, so this Get() can't disturb the repeat/Next()
        // cursor position.
        if (ResumeAfterExtCode <> '') and not Extension.Get(ResumeAfterExtCode) then
            ResumeAfterExtCode := '';

        Extension.SetCurrentKey("Order No.");
        if not Extension.FindSet() then
            exit;

        PastCheckpoint := (ResumeAfterExtCode = '');
        repeat
            if not PastCheckpoint then begin
                if Extension.Code = ResumeAfterExtCode then
                    PastCheckpoint := true;
                // Skip this one either way - it's the checkpointed extension itself (already done)
                // or one before it in Order No. sequence (implied already done).
            end else begin
                if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('Categoría %1: ejecutando extensión %2', Format(Category), Extension.Code)) then begin
                    MarkRunRequestCancelled(RunRequestEntryNo);
                    exit;
                end;
                RunExtensionCategory(Extension.Code, Category, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo);
                ProcessedNo += 1;
                SaveCheckpoint(RunRequestEntryNo, CopyStr(Extension.Code, 1, 250), ProcessedNo);
            end;
        until Extension.Next() = 0;
    end;

    local procedure RunExtensionCategory(ExtensionCode: Code[20]; Category: Option Setup,"Master/Accounting",Historic,Other; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer)
    var
        Concept: Record "DXR MCC Concept";
        DispatcherErrors: Dictionary of [Integer, Text];
        DispatcherDurations: Dictionary of [Integer, Integer];
        ErrorText: Text;
        DurationMs: Integer;
    begin
        Concept.SetRange("Extension Code", ExtensionCode);
        Concept.SetRange(Category, Category);
        Concept.SetRange(Blocked, true);
        BlockedCount += Concept.Count();

        Concept.SetRange(Blocked, false);
        Concept.SetCurrentKey("Extension Code", "Sequence No.");
        if not Concept.FindSet() then
            exit;

        // No progress Dialog here (2026-08-22, removed): RunCategory/RunPortfolio - the only
        // callers of this procedure - now always run as a background task (Dialog.Open() has no
        // client to show it to in a TaskScheduler session and would fail there). Progress for
        // these scopes is DXR MCC Run Requests ("Current Step"/"Checkpoint Key"/"Processed Count",
        // updated by RunCategory around this call) and Run Log, not a live modal - see RunExtension
        // for the synchronous, dialog-driven equivalent used by the still-immediate "Run Extension"/
        // "Run Concept" actions.
        //
        // 2026-08-22: "Current Step" now updates per CONCEPT here too (not just once per extension,
        // from RunCategory's own call) - shows the actual TABLE name being migrated right now (e.g.
        // "Catálogo de cuentas"), resolved from Legacy/New Table ID, so a slow step is visibly
        // explained instead of just looking stuck on the extension name.
        repeat
            if not DispatcherErrors.ContainsKey(Concept."Dispatcher Codeunit ID") then begin
                if IsDispatcherAlreadyDone(Concept."Dispatcher Codeunit ID") then begin
                    CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: %2 ya completado, omitido', ExtensionCode, ResolveConceptTableName(Concept)));
                    DispatcherErrors.Add(Concept."Dispatcher Codeunit ID", '');
                    DispatcherDurations.Add(Concept."Dispatcher Codeunit ID", 0);
                end else begin
                    CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: migrando %2', ExtensionCode, ResolveConceptTableName(Concept)));
                    LogConceptsStarting(Concept."Dispatcher Codeunit ID", RunRequestEntryNo);
                    RunDispatcher(Concept."Dispatcher Codeunit ID", ErrorText, DurationMs);
                    DispatcherErrors.Add(Concept."Dispatcher Codeunit ID", ErrorText);
                    DispatcherDurations.Add(Concept."Dispatcher Codeunit ID", DurationMs);
                end;
            end;
        until Concept.Next() = 0;

        Concept.FindSet();
        repeat
            DispatcherErrors.Get(Concept."Dispatcher Codeunit ID", ErrorText);
            DispatcherDurations.Get(Concept."Dispatcher Codeunit ID", DurationMs);
            LogAndCount(Concept, ErrorText, DurationMs, RunRequestEntryNo);
            CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: verificado %2 (%3)', ExtensionCode, ResolveConceptTableName(Concept), Format(Concept.Status)));
            case Concept.Status of
                Concept.Status::Completed:
                    CompletedCount += 1;
                Concept.Status::"Completed With Gaps":
                    GapCount += 1;
                Concept.Status::Error:
                    ErrorCount += 1;
            end;
        until Concept.Next() = 0;
        Commit();
    end;

    /// <summary>
    /// Human-readable "what table is this" for the live Current Step text - prefers the New Table
    /// ID's real caption (the active table an operator would recognize, e.g. "Catálogo de cuentas"
    /// for G/L Account), falls back to the Legacy Table ID's caption, falls back to the concept's
    /// own Description for field-only concepts (Legacy/New Table ID both 0, nothing to resolve).
    /// </summary>
    /// <summary>
    /// Requested 2026-08-22: "una manera de skipear las que ya tenemos completada". A dispatcher
    /// only needs to run once - if EVERY non-blocked concept sharing it is already Completed/
    /// Completed With Gaps/Completed (Fallback) from a prior run, re-invoking it again just re-does
    /// idempotent work for no benefit (some dispatchers, like DESB's 39-table Worker, are genuinely
    /// slow). Deliberately per-DISPATCHER, not per-concept: a dispatcher is all-or-nothing (see the
    /// Category header comment on ScheduleCategory), so it's only truly "done" when every concept
    /// it feeds is done - if even one of its concepts is still Pending/Error/Not Counted, the
    /// dispatcher must still run. Checked against ALL non-blocked concepts for this dispatcher
    /// portfolio-wide (not just the current scope's filtered subset), since the dispatcher's own
    /// work isn't scoped to one category/extension pass either. Concept.Status = "Completed With
    /// Gaps" still counts as "done" here - the gap is a data-completeness fact recount will keep
    /// re-surfacing, not something re-invoking the SAME dispatcher again would fix (its own
    /// idempotent guards already skip whatever it already wrote).
    /// </summary>
    local procedure IsDispatcherAlreadyDone(DispatcherCodeunitId: Integer): Boolean
    var
        Concept: Record "DXR MCC Concept";
    begin
        if DispatcherCodeunitId = 0 then
            exit(false);

        // "Completed With Gaps" is deliberately NOT treated as done (2026-08-23 fix, root-cause
        // confirmed): a dispatcher that leaves a gap on one run must get a real chance to run
        // again on every subsequent Run Extension/Category/Portfolio, not be skipped forever just
        // because its status happens to start with "Completed". Its own idempotency guard
        // (Upgrade Tag, per-row Insert-or-skip, etc. - see DXR MCC Upgrade Tag Mgt's header
        // comment) is what makes repeat calls safe/cheap; MCC re-invoking it is never itself the
        // risk. Before this fix, a gap left on the FIRST run was permanent - no amount of clicking
        // Run again ever tried the dispatcher a second time.
        Concept.SetRange("Dispatcher Codeunit ID", DispatcherCodeunitId);
        Concept.SetRange(Blocked, false);
        Concept.SetFilter(Status, '<>%1&<>%2', Concept.Status::Completed, Concept.Status::"Completed (Fallback)");
        exit(Concept.IsEmpty());
    end;

    local procedure ResolveConceptTableName(var Concept: Record "DXR MCC Concept"): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if Concept."New Table ID" <> 0 then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Concept."New Table ID") then
                exit(AllObjWithCaption."Object Caption");

        if Concept."Legacy Table ID" <> 0 then
            if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, Concept."Legacy Table ID") then
                exit(AllObjWithCaption."Object Caption");

        exit(Concept.Description);
    end;

    /// <summary>Resolves ONE specific table ID's real caption (blank if 0 or not found/published here) - the building block ResolveConceptTableName's "prefer new, fall back to legacy" logic sits on top of, exposed separately so Legacy/New can be shown side by side in Run Log instead of collapsed into one preferred name.</summary>
    local procedure ResolveTableNameById(TableId: Integer): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if TableId = 0 then
            exit('');
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableId) then
            exit(CopyStr(AllObjWithCaption."Object Caption", 1, 250));
        exit('');
    end;

    /// <summary>
    /// Runs a Concept-scoped run immediately, in the caller's own transaction (2026-08-22: changed
    /// from TaskScheduler-based scheduling per explicit user request - "que sea una tarea que se
    /// ejecute inmediato... al momento de pulsar el boton", instant feedback on the button click
    /// mattered more than avoiding a client wait). Still writes a "DXR MCC Run Request" audit row
    /// so Run Requests/Run Log stay the one consistent place to look for the outcome.
    /// </summary>
    procedure ScheduleConcept(var Concept: Record "DXR MCC Concept")
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Concept, '', Concept."Entry No.");
        // InitRunRequest's own Insert(true) opens a write transaction; the dispatcher chain below
        // ends in Codeunit.Run() with its return value used, which isn't allowed while one is
        // open ("Codeunit.Run is allowed in write transactions only if the return value is not
        // used" - confirmed live, this exact call stack, 2026-08-22). Commit closes it first.
        Commit();
        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            exit;
        end;
        RunConceptSynchronouslyIntoRequest(RunRequest, Concept);
        ReleaseGlobalLock(RunRequest);
    end;

    /// <summary>Same pattern as ScheduleConcept, for an Extension-scoped run (all its non-blocked concepts).</summary>
    procedure ScheduleExtension(ExtensionCode: Code[20])
    var
        RunRequest: Record "DXR MCC Run Request";
        Completed: Integer;
        Gaps: Integer;
        Errors: Integer;
        BlockedSkipped: Integer;
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Extension, ExtensionCode, 0);
        // Same write-transaction fix as ScheduleConcept above.
        Commit();
        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            exit;
        end;
        RunExtension(ExtensionCode, Completed, Gaps, Errors, BlockedSkipped, RunRequest."Entry No.");
        CompleteRunRequestSynchronously(RunRequest, StrSubstNo(
            'Extension %1: %2 completed, %3 completed with gaps, %4 failed, %5 skipped (blocked).',
            ExtensionCode, Completed, Gaps, Errors, BlockedSkipped));
        ReleaseGlobalLock(RunRequest);
    end;

    /// <summary>
    /// Category-scoped run - back to a background task (2026-08-22, reversing the same-day
    /// earlier change to run inline). A Category filter only trims which CONCEPTS get logged -
    /// the underlying dispatcher codeunit for each one is all-or-nothing (e.g. Despacho Base's
    /// Worker migrates all 39 of its tables in one call, whether the triggering concept was 1 of
    /// its 11 Setup rows or not - there's no way to ask a dispatcher to do only its Setup-tagged
    /// subset). So "Run All Setup" doesn't do "the Setup rows' work" - it does EVERY dispatcher's
    /// FULL workload for every extension that has at least one Setup concept, which today is
    /// nearly all of them. That's real, unavoidable per-row FindSet/repeat work across many real
    /// tables (some large), all inside one interactive request - confirmed to cause the same
    /// server-side timeout as Recount All ("Something went wrong", no AL call stack).
    /// </summary>
    procedure ScheduleCategory(Category: Option Setup,"Master/Accounting",Historic,Other)
    var
        RunRequest: Record "DXR MCC Run Request";
        Completed: Integer;
        Gaps: Integer;
        Errors: Integer;
        BlockedSkipped: Integer;
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Category, '', 0);
        RunRequest.Category := Category;
        RunRequest.Modify(true);
        Commit();
        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            exit;
        end;
        if TaskScheduler.CanCreateTask() then begin
            RunRequest."Task Id" := TaskScheduler.CreateTask(Codeunit::"DXR MCC Background Runner", 0, true, CompanyName(), CurrentDateTime(), RunRequest.RecordId());
            RunRequest.Modify(true);
            // Lock released by DXR MCC Background Runner when the task finishes (any outcome).
        end else begin
            RunCategory(Category, Completed, Gaps, Errors, BlockedSkipped, RunRequest."Entry No.", '');
            CompleteRunRequestSynchronously(RunRequest, StrSubstNo(
                'Category %1: %2 completed, %3 completed with gaps, %4 failed, %5 skipped (blocked).',
                Format(Category), Completed, Gaps, Errors, BlockedSkipped));
            ReleaseGlobalLock(RunRequest);
        end;
    end;

    /// <summary>Same pattern as ScheduleConcept, for a full-portfolio run (every registered extension).</summary>
    procedure SchedulePortfolio()
    var
        RunRequest: Record "DXR MCC Run Request";
        Completed: Integer;
        Gaps: Integer;
        Errors: Integer;
        BlockedSkipped: Integer;
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Portfolio, '', 0);
        Commit();
        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            exit;
        end;
        // Back to a background task (2026-08-22) - the whole portfolio, every category, is the
        // single largest amount of work any Schedule* procedure can trigger. Same reasoning as
        // ScheduleCategory above, at maximum scope.
        if TaskScheduler.CanCreateTask() then begin
            RunRequest."Task Id" := TaskScheduler.CreateTask(Codeunit::"DXR MCC Background Runner", 0, true, CompanyName(), CurrentDateTime(), RunRequest.RecordId());
            RunRequest.Modify(true);
        end else begin
            RunPortfolio(Completed, Gaps, Errors, BlockedSkipped, RunRequest."Entry No.");
            CompleteRunRequestSynchronously(RunRequest, StrSubstNo(
                'Portfolio: %1 completed, %2 completed with gaps, %3 failed, %4 skipped (blocked).',
                Completed, Gaps, Errors, BlockedSkipped));
            ReleaseGlobalLock(RunRequest);
        end;
    end;

    /// <summary>
    /// Recount All ALWAYS goes to a background task (2026-08-22) - unlike every other Schedule*
    /// procedure above, which run immediately per explicit user request. Recounting opens/counts
    /// up to ~1200 tables (2 per concept x ~600+ concepts) - a read-only diagnostic refresh, not a
    /// migration the operator is waiting to see finish, so there's no reason to force it into one
    /// interactive request the way "run this migration now" reasonably is. Doing so caused a
    /// server-side timeout ("Something went wrong", no AL call stack - confirmed not a Codeunit.Run
    /// or write-transaction restriction, just too much wall-clock time in one request) on a real
    /// QA tenant. Falls back to synchronous only if TaskScheduler genuinely can't create a task at
    /// all (same rare-sandbox fallback every other Schedule* procedure used before 2026-08-22).
    /// </summary>
    procedure ScheduleRecountAll()
    var
        RunRequest: Record "DXR MCC Run Request";
        RecountedNo: Integer;
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::RecountAll, '', 0);
        Commit();
        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            exit;
        end;
        if TaskScheduler.CanCreateTask() then begin
            RunRequest."Task Id" := TaskScheduler.CreateTask(Codeunit::"DXR MCC Background Runner", 0, true, CompanyName(), CurrentDateTime(), RunRequest.RecordId());
            RunRequest.Modify(true);
        end else begin
            RecountedNo := RecountAllConcepts(RunRequest."Entry No.");
            CompleteRunRequestSynchronously(RunRequest, StrSubstNo('%1 concept(s) recounted.', RecountedNo));
            ReleaseGlobalLock(RunRequest);
        end;
    end;

    /// <summary>The actual recount loop, shared by the background runner and the rare synchronous fallback above. No Dialog here - background tasks have no UI to show one to.</summary>
    procedure RecountAllConcepts(): Integer
    begin
        exit(RecountAllConcepts(0));
    end;

    /// <summary>RunRequestEntryNo-aware overload: resumes past the last-recounted Entry No. (Checkpoint Key) and checks Cancel Requested every 20 concepts, same cadence as its existing Commit().</summary>
    procedure RecountAllConcepts(RunRequestEntryNo: Integer): Integer
    var
        Concept: Record "DXR MCC Concept";
        RunRequest: Record "DXR MCC Run Request";
        Counter: Codeunit "DXR MCC Counter";
        RecountedNo: Integer;
        ResumeAfterEntryNo: Integer;
    begin
        if (RunRequestEntryNo <> 0) and RunRequest.Get(RunRequestEntryNo) and (RunRequest."Checkpoint Key" <> '') then
            Evaluate(ResumeAfterEntryNo, RunRequest."Checkpoint Key");

        if ResumeAfterEntryNo <> 0 then
            Concept.SetFilter("Entry No.", '>%1', ResumeAfterEntryNo);
        if not Concept.FindSet(true) then
            exit(0);
        repeat
            Counter.CountConcept(Concept);
            RecountedNo += 1;
            if RecountedNo mod 20 = 0 then begin
                if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('Recount All: %1 conceptos procesados', RecountedNo)) then begin
                    MarkRunRequestCancelled(RunRequestEntryNo);
                    exit(RecountedNo);
                end;
                SaveCheckpoint(RunRequestEntryNo, Format(Concept."Entry No."), RecountedNo);
                Commit();
            end;
        until Concept.Next() = 0;
        exit(RecountedNo);
    end;

    local procedure InitRunRequest(var RunRequest: Record "DXR MCC Run Request"; Scope: Option; ExtensionCode: Code[20]; ConceptEntryNo: Integer)
    begin
        RunRequest.Init();
        RunRequest.Scope := Scope;
        RunRequest."Extension Code" := ExtensionCode;
        RunRequest."Concept Entry No." := ConceptEntryNo;
        RunRequest."Attempt No." := 1;
        RunRequest.Status := RunRequest.Status::Scheduled;
        RunRequest."Scheduled At" := CurrentDateTime();
        RunRequest."Requested By" := CopyStr(UserId(), 1, MaxStrLen(RunRequest."Requested By"));
        RunRequest.Insert(true);
    end;

    local procedure RunConceptSynchronouslyIntoRequest(var RunRequest: Record "DXR MCC Run Request"; var Concept: Record "DXR MCC Concept")
    begin
        RunConcept(Concept, RunRequest."Entry No.");
        CompleteRunRequestSynchronously(RunRequest, StrSubstNo('Concept "%1": %2.', Concept.Description, Format(Concept.Status)));
    end;

    local procedure CompleteRunRequestSynchronously(var RunRequest: Record "DXR MCC Run Request"; ResultSummary: Text[250])
    begin
        // Re-fetch: a scope with cancel-checking (Category/Portfolio, via RunCategory/RunPortfolio)
        // may already have set Status = Cancelled mid-call (MarkRunRequestCancelled) - never
        // overwrite that back to Completed just because the outer procedure ran to its own end.
        if RunRequest.Find() and (RunRequest.Status = RunRequest.Status::Cancelled) then
            exit;

        RunRequest.Status := RunRequest.Status::Completed;
        RunRequest."Completed At" := CurrentDateTime();
        RunRequest."Result Summary" := ResultSummary;
        RunRequest.Modify(true);
    end;

    local procedure RunDispatcher(DispatcherCodeunitId: Integer; var ErrorText: Text; var DurationMs: Integer)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        StartTime: DateTime;
    begin
        ErrorText := '';
        DurationMs := 0;
        if DispatcherCodeunitId = 0 then
            exit;

        // Platform hard-blocks Codeunit.Run() on any Subtype = Upgrade codeunit outside its own
        // schema-sync process. CONFIRMED 2026-08-22 (live crash, codeunit 54779 "DXR_SD_Migr_Phase
        // _Dispatcher") that this is NOT a catchable Codeunit.Run() failure - the platform aborts
        // before Codeunit.Run's own try-semantics even apply, the same way the write-transaction
        // restriction does. The rewrite further below (matching on GetLastErrorText()) is dead code
        // for this reason and left only as a second line of defense in case some other invocation
        // path DOES surface it as a normal failure - the real fix is never attempting the call at
        // all. List below verified by directly reading every "Subtype = Upgrade;" declaration
        // across the whole portfolio (C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON) on 2026-08-22
        // - not guessed. Add to it whenever a new Upgrade-subtype codeunit is found, rather than
        // relying on the runtime catch below.
        if IsKnownUpgradeCodeunit(DispatcherCodeunitId) then begin
            ErrorText := StrSubstNo(
                'Codeunit %1 is Subtype = Upgrade - Business Central refuses to run it via Codeunit.Run() from any code, including MCC and TaskScheduler, outside the platform''s own publish/schema-sync process. This concept can only run through that extension''s own manual re-entry point (e.g. a "Run Migration Now"/"Run Dispatcher Now" action on its own status page) or automatically on next publish - mark it Blocked here with this reason rather than retrying.',
                DispatcherCodeunitId);
            exit;
        end;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, DispatcherCodeunitId) then begin
            ErrorText := StrSubstNo(
                'Codeunit %1 is not installed on this environment. The extension that owns it may not be published/updated here yet - publish it, then Reload Registry and try again.',
                DispatcherCodeunitId);
            exit;
        end;

        StartTime := CurrentDateTime();
        if not Codeunit.Run(DispatcherCodeunitId) then
            ErrorText := GetLastErrorText();
        DurationMs := CurrentDateTime() - StartTime;
        ClearLastError();

        // Second line of defense only - see the comment above IsKnownUpgradeCodeunit's call site.
        if ErrorText.Contains('cannot be invoked outside the schema synchronization process') then
            ErrorText := StrSubstNo(
                'Codeunit %1 is Subtype = Upgrade - Business Central refuses to run it via Codeunit.Run() from any code, including MCC and TaskScheduler, outside the platform''s own publish/schema-sync process. This concept can only run through that extension''s own manual re-entry point (e.g. a "Run Migration Now"/"Run Dispatcher Now" action on its own status page) or automatically on next publish - mark it Blocked here with this reason rather than retrying.',
                DispatcherCodeunitId);
    end;

    /// <summary>
    /// Every codeunit in the whole Dextra BC portfolio (C:\Users\rpena\OneDrive - Dextra\Desktop\
    /// BELLON) confirmed 2026-08-22 to have "Subtype = Upgrade;" on its own declaration (not a
    /// comment mentioning another codeunit) - found via a portfolio-wide grep for the literal
    /// property, then verified per file. Only the ones a Concept row could plausibly ever be
    /// pointed at are worth checking here; kept as the full confirmed list anyway so a future
    /// registry addition is covered without re-auditing. Codeunit IDs only - onprem/SaaS variants
    /// of the same codeunit share the AL object name but not necessarily the ID, so both are
    /// listed where the source declares both.
    /// REMOVED 2026-08-23: 54779 (DXR_SD_Migr_Phase_Dispatcher, SD) - taken out of this list because
    /// it no longer declares Subtype = Upgrade. Fixed at the source in Special Dispatch's own
    /// separate repo (not this one), commit edfdc91: Subtype = Upgrade and the now-illegal empty
    /// OnUpgradePerCompany trigger were both removed, and all real migration work (Phase 3
    /// permission-set assignment, then Phase 1, then Phase 2) was moved into the dispatcher's own
    /// OnRun. MCC's DXR MCC Registry Loader was repointed to DispatcherCodeunitId = 54779 for all 10
    /// SD concepts in the same fix round - leaving 54779 in this list would have kept every SD
    /// concept permanently Blocked with a stale "Subtype = Upgrade" error despite the registry now
    /// being correct, since this guard runs before Codeunit.Run() is ever attempted.
    /// </summary>
    local procedure IsKnownUpgradeCodeunit(CodeunitId: Integer): Boolean
    begin
        exit(CodeunitId in [
            52248, 36003045,  // DXR_Field ID Alignment Upg. (DRLOC)
            52189, 36003049,  // DXR_Internal Closure Migration (DRLOC)
            51962, 36002776,  // DXR_Loc Upgrade Process (DRLOC)
            52255, 36003047,  // DXR_Vend. Withhold Migr Repair (DRLOC)
            53669,            // DXR_Despacho Migr Dispatcher (DESB)
            59221,            // Bellon Upgrade Process (BELLON)
            53562,            // DXR_POS Upgrade Process (BELLONPOS)
            52587, 36003121,  // DXR_LSFE Upgrade (LSFE)
            53600,            // DXR_Transunion Upgrade (TU)
            54856,            // DXR_BC Migr Dispatcher (BC)
            54662,            // DXR_Recaudo Migr Dispatcher (RBPD)
            54599,            // DXR_Upgrade (PCM)
            54742, 54743,     // DXR_Upgrade Mgt (RC)
            54534,            // DXR_Mail Migr Dispatcher (Mail_API, not currently MCC-tracked)
            53923,            // DXR_Desp LS Migr Dispatcher (DESLS) - NOT the same as 53924 Phase 1
            54445, 36003619,  // DXR_LS Upgrade Code Mgt (LSLOC)
            52773,            // DXR_VP TXT Upgrade (VP TXT, not currently MCC-tracked)
            52743,            // DXR_VP API Upgrade (VendorPay API, not currently MCC-tracked)
            52667, 52120396,  // DXR_VP Upgrade (VP core)
            53648, 52119593,  // DXR_Prontopago Migr Upgrade (a separate DPP workspace, not DescuentoProntoPago-OLD)
            54283              // DPP Upgrade Manager (DescuentoProntoPago-OLD)
        ]);
    end;

    local procedure LogAndCount(var Concept: Record "DXR MCC Concept"; ErrorText: Text; DurationMs: Integer; RunRequestEntryNo: Integer)
    var
        Counter: Codeunit "DXR MCC Counter";
        RunLog: Record "DXR MCC Run Log";
        FallbackMigrator: Codeunit "DXR MCC Fallback Migrator";
        FallbackRowsCopied: Integer;
        FallbackResultText: Text;
        UsedFallback: Boolean;
        TableOpenFailed: Boolean;
        NotRowBased: Boolean;
        HasGap: Boolean;
    begin
        // Count FIRST (2026-08-23 fix). The old order counted AFTER deciding whether to run the
        // fallback, so the fallback could only ever react to ErrorText<>''/Dispatcher=0 - never to
        // a genuine row-count gap left by a dispatcher that ran WITHOUT erroring (e.g. its own
        // Upgrade Tag guard already fired on an earlier partial run and silently no-op'd the rest -
        // see DXR MCC Upgrade Tag Mgt's header comment). That was the real reason gaps never closed
        // on repeat runs even after the owning extension's dispatcher itself got "fixed."
        Counter.CountConcept(Concept);

        // Counter.CountConcept already decided these two terminal states - the fallthrough status
        // logic below must never stomp back over either one:
        //  - Error: Legacy and/or New Table ID couldn't even be opened on this environment (wrong/
        //    renumbered ID, extension not published here yet) - nothing to reconcile.
        //  - "Not Row-Based": a field-only concept (Legacy Table ID = New Table ID = 0) - MCC has no
        //    row-count signal for these at all.
        // CONFIRMED BUG (2026-08-23): the old code unconditionally fell through to
        // Concept.Status := Completed for BOTH of these regardless of what Counter just set - so
        // every field-only concept in the registry (the exact per-field _DXR migrations the
        // operator checks on the page) was reported "Completed" after its very first run with ZERO
        // real verification, and a table pair whose table couldn't even be opened was also reported
        // "Completed". IsDispatcherAlreadyDone then skipped re-invoking either dispatcher on every
        // later run, freezing whatever partial (or zero) field/row copy had happened forever.
        TableOpenFailed := Concept.Status = Concept.Status::Error;
        NotRowBased := Concept.Status = Concept.Status::"Not Row-Based";

        HasGap := (not TableOpenFailed) and (not NotRowBased) and
            (Concept."Legacy Table ID" <> 0) and (Concept."New Table ID" <> 0) and
            (Concept."Legacy Table ID" <> Concept."New Table ID") and
            (Concept."Migrated Record Count" < Concept."Old Record Count");

        // Fallback now also fires on a plain leftover gap (HasGap), not just ErrorText<>''/
        // Dispatcher=0 as before - MCC's own generic RecordRef reconciliation (see DXR MCC Fallback
        // Migrator) is the one gap-closing path that doesn't depend on the owning extension's
        // dispatcher ever being fixed, recompiled, or having its Upgrade Tag manually cleared.
        if (not TableOpenFailed) and (not NotRowBased) and
           (HasGap or (ErrorText <> '') or (Concept."Dispatcher Codeunit ID" = 0)) and
           (Concept."Legacy Table ID" <> 0) and (Concept."New Table ID" <> 0)
        then
            if FallbackMigrator.TryRestoreTablePair(Concept."Legacy Table ID", Concept."New Table ID", FallbackRowsCopied, FallbackResultText) then begin
                UsedFallback := true;
                ErrorText := '';
                Counter.CountConcept(Concept); // refresh Old/Migrated/Gap - fallback may have closed some/all of it
                HasGap := (Concept."Legacy Table ID" <> Concept."New Table ID") and (Concept."Legacy Table ID" <> 0) and
                    (Concept."Migrated Record Count" < Concept."Old Record Count");
            end;

        RunLog.Init();
        RunLog."Concept Entry No." := Concept."Entry No.";
        RunLog."Run Request Entry No." := RunRequestEntryNo;
        RunLog."Extension Code" := Concept."Extension Code";
        RunLog."Phase Code" := Concept."Phase Code";
        RunLog."Table Name" := CopyStr(ResolveConceptTableName(Concept), 1, 250);
        RunLog."Legacy Table Name" := ResolveTableNameById(Concept."Legacy Table ID");
        RunLog."New Table Name" := ResolveTableNameById(Concept."New Table ID");
        RunLog."Company Name" := CopyStr(CompanyName(), 1, 30);
        RunLog."Run DateTime" := CurrentDateTime();
        RunLog."Old Record Count" := Concept."Old Record Count";
        RunLog."Migrated Record Count" := Concept."Migrated Record Count";
        RunLog."Duration (ms)" := DurationMs;
        RunLog."User ID" := CopyStr(UserId(), 1, 50);

        if UsedFallback then begin
            RunLog.Status := RunLog.Status::Completed;
            RunLog."Error Message" := CopyStr(FallbackResultText, 1, MaxStrLen(RunLog."Error Message"));
            Concept.Status := Concept.Status::"Completed (Fallback)";
        end else
            if TableOpenFailed then begin
                // Preserve Counter's own Error - do not let this fall through to Completed.
                RunLog.Status := RunLog.Status::Error;
                RunLog."Error Message" := CopyStr('Legacy y/o New Table ID no se pudo abrir en este entorno (tabla no publicada o ID incorrecto/renumerado) - ver DXR MCC Counter.', 1, MaxStrLen(RunLog."Error Message"));
                Concept.Status := Concept.Status::Error;
            end else
            if ErrorText <> '' then begin
                RunLog.Status := RunLog.Status::Error;
                RunLog."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RunLog."Error Message"));
                Concept.Status := Concept.Status::Error;
            end else
            if NotRowBased then begin
                // Leave Concept.Status = "Not Row-Based" exactly as Counter set it - not
                // verifiable, and never a false "Completed". RunLog has no matching option (it's a
                // run-history log, not the concept's own truth field) - log as Completed since the
                // dispatcher (if any) ran without erroring.
                RunLog.Status := RunLog.Status::Completed;
            end else
            if HasGap then begin
                Concept.Status := Concept.Status::"Completed With Gaps";
                RunLog.Status := RunLog.Status::"Completed With Gaps";
            end else begin
                Concept.Status := Concept.Status::Completed;
                RunLog.Status := RunLog.Status::Completed;
            end;

        Concept."Last Run DateTime" := CurrentDateTime();
        Concept.Modify(true);
        RunLog.Insert(true);
    end;

    /// <summary>
    /// 2026-08-25 (reported: "veo como la localización pasa de tablas y no logea... tampoco logea
    /// cuando debe de logear todo" - a dispatcher covering many concepts in one Codeunit.Run() call
    /// produced ZERO Run Log rows until the WHOLE call returned, so a long-running or hung
    /// dispatcher left every table/bootstrap step it covers completely invisible in the log while
    /// it was actually in progress - LogAndCount only ever wrote the terminal outcome, after the
    /// fact). Writes one "Running" Run Log row per concept sharing this dispatcher BEFORE
    /// Codeunit.Run() is called, so every table/bootstrap this dispatcher is about to touch shows up
    /// in the log immediately, in real time, not just once (or never, if it hangs) at the end.
    /// LogAndCount still writes its own separate terminal row afterward (Completed/Error/etc.) -
    /// this is deliberately a SEPARATE row, not an update-in-place, so the log preserves the real
    /// timeline (started at X, finished/failed at Y) as an audit trail, consistent with every other
    /// Run Log row being an immutable historical entry rather than a mutable "current status" cell.
    /// </summary>
    local procedure LogConceptsStarting(DispatcherCodeunitId: Integer; RunRequestEntryNo: Integer)
    var
        Concept: Record "DXR MCC Concept";
        RunLog: Record "DXR MCC Run Log";
    begin
        if DispatcherCodeunitId = 0 then
            exit;

        Concept.SetRange("Dispatcher Codeunit ID", DispatcherCodeunitId);
        Concept.SetRange(Blocked, false);
        if not Concept.FindSet() then
            exit;

        repeat
            RunLog.Init();
            RunLog."Concept Entry No." := Concept."Entry No.";
            RunLog."Run Request Entry No." := RunRequestEntryNo;
            RunLog."Extension Code" := Concept."Extension Code";
            RunLog."Phase Code" := Concept."Phase Code";
            RunLog."Table Name" := CopyStr(ResolveConceptTableName(Concept), 1, 250);
            RunLog."Legacy Table Name" := ResolveTableNameById(Concept."Legacy Table ID");
            RunLog."New Table Name" := ResolveTableNameById(Concept."New Table ID");
            RunLog."Company Name" := CopyStr(CompanyName(), 1, 30);
            RunLog."Run DateTime" := CurrentDateTime();
            RunLog.Status := RunLog.Status::Running;
            RunLog."User ID" := CopyStr(UserId(), 1, 50);
            RunLog.Insert(true);
        until Concept.Next() = 0;
        Commit();
    end;

    /// <summary>
    /// Global cross-company lock (same pattern as DR-Localization's "DXR_Migration Lock Mgt.") -
    /// refuses to schedule a second run while one is already active anywhere in the tenant. Called
    /// from every Schedule* procedure before it does anything else. LockDuration is generous (3
    /// hours - longer than DESB's own Worker timeout of 1 hour, with headroom for Portfolio's 4
    /// sequential category passes) so the lock still self-expires and never permanently blocks
    /// future runs even if a session dies without releasing it.
    /// </summary>
    local procedure TryAcquireGlobalLock(var RunRequest: Record "DXR MCC Run Request"): Boolean
    var
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
    begin
        ReconcileStaleRunningRequests();
        exit(LockMgt.TryAcquireLock(CompanyName(), CopyStr(UserId(), 1, 50), 3 * 60 * 60 * 1000, RunRequest."Entry No."));
    end;

    /// <summary>
    /// Self-heals a Category/Portfolio/RecountAll Run Request stuck showing Status = Running with
    /// no real background task behind it anymore (platform-killed session, server restart, or the
    /// task genuinely exceeding its TaskScheduler timeout) - see "Last Heartbeat" on DXR MCC Run
    /// Request for the full root-cause writeup. Threshold is 4 hours: comfortably longer than
    /// TryAcquireGlobalLock's own 3-hour lock duration, so a request that's still genuinely running
    /// (heartbeat updates every extension boundary, well under an hour apart even for the slowest
    /// known dispatcher) is never mistaken for dead. Called from TryAcquireGlobalLock (before every
    /// new Schedule* attempt) and from the Run Requests page (OnOpenPage) so the operator sees
    /// correct status without having to trigger a new run first.
    /// </summary>
    internal procedure ReconcileStaleRunningRequests()
    var
        RunRequest: Record "DXR MCC Run Request";
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
        StaleBefore: DateTime;
    begin
        StaleBefore := CurrentDateTime() - StaleRunningThresholdMs();
        RunRequest.SetRange(Status, RunRequest.Status::Running);
        RunRequest.SetFilter("Last Heartbeat", '<%1|%2', StaleBefore, 0DT);
        if not RunRequest.FindSet(true) then
            exit;
        repeat
            // 2026-08-25: also cancel the stored Task Id via the official TaskScheduler API (guarded
            // by TaskExists, since a task that already started - the normal case for a row that
            // reached Status=Running at all - won't exist in the queue anymore, making this a safe
            // no-op then). Covers the rare edge case where a task was created and this row was
            // stamped Running, but the underlying scheduled entry hadn't actually been consumed yet
            // (e.g. TaskScheduler capacity delay) - without this, that entry could still fire later
            // and start real migration work concurrently with whatever picks up the freed lock next,
            // exactly the overlapping-dispatcher-chain risk "DXR MCC Migration Lock Mgt." exists to
            // prevent. Does NOT and cannot forcibly stop a session that is genuinely, actively
            // running - AL has no API for that (confirmed against Microsoft's own Task Scheduler
            // docs); this self-heal only fixes MCC's own bookkeeping/lock for that case, same as
            // before this change.
            if not IsNullGuid(RunRequest."Task Id") then
                if TaskScheduler.TaskExists(RunRequest."Task Id") then
                    TaskScheduler.CancelTask(RunRequest."Task Id");

            RunRequest.Status := RunRequest.Status::Failed;
            RunRequest."Completed At" := CurrentDateTime();
            RunRequest."Result Summary" := CopyStr(StrSubstNo(
                'Marcado como Failed automáticamente: sin heartbeat desde %1 (probablemente la sesión en background fue terminada por la plataforma - timeout de TaskScheduler, reinicio de servidor, etc.). Revise DXR MCC Run Log para ver hasta dónde llegó.',
                RunRequest."Last Heartbeat"), 1, MaxStrLen(RunRequest."Result Summary"));
            RunRequest.Modify(true);
            LockMgt.ForceReleaseLockForRunRequest(RunRequest."Entry No.");
        until RunRequest.Next() = 0;
        Commit();
    end;

    local procedure StaleRunningThresholdMs(): BigInteger
    begin
        exit(4 * 60 * 60 * 1000);
    end;

    local procedure ReleaseGlobalLock(var RunRequest: Record "DXR MCC Run Request")
    var
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
    begin
        LockMgt.ForceReleaseLockForRunRequest(RunRequest."Entry No.");
    end;

    /// <summary>Refuses to schedule/run because another request already holds the lock - marks this request Failed immediately rather than queuing behind it silently.</summary>
    local procedure FailRunRequestLockBusy(var RunRequest: Record "DXR MCC Run Request")
    var
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
        LockedForCompany: Text;
        LockedBy: Code[50];
        LockedAt: DateTime;
        ExpiresAt: DateTime;
        Message: Text[250];
    begin
        if LockMgt.GetActiveMigrationLock(LockedForCompany, LockedBy, LockedAt, ExpiresAt) then
            Message := CopyStr(StrSubstNo('No se programó: ya hay una migración en curso (iniciada por %1 a las %2, compañía %3, expira %4 si no libera antes).', LockedBy, LockedAt, LockedForCompany, ExpiresAt), 1, 250)
        else
            Message := 'No se programó: no se pudo adquirir el lock de migración (intente de nuevo).';

        RunRequest.Status := RunRequest.Status::Failed;
        RunRequest."Result Summary" := Message;
        RunRequest."Completed At" := CurrentDateTime();
        RunRequest.Modify(true);
    end;

    /// <summary>
    /// Cooperative cancel check + live "Current Step" update, called between extension iterations
    /// in RunCategory/RunExtensionCategory/RunPortfolio. RunRequestEntryNo = 0 means "no request to
    /// track" (kept for callers that never had one before this feature existed) - always a no-op
    /// then. Returns false (caller must stop) only when Cancel Requested is set.
    /// </summary>
    local procedure CheckCancelAndUpdateStep(RunRequestEntryNo: Integer; StepText: Text): Boolean
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        if RunRequestEntryNo = 0 then
            exit(true);
        if not RunRequest.Get(RunRequestEntryNo) then
            exit(true);
        if RunRequest."Cancel Requested" then
            exit(false);

        RunRequest."Current Step" := CopyStr(StepText, 1, 250);
        RunRequest."Last Heartbeat" := CurrentDateTime();
        RunRequest.Modify(true);
        Commit();
        exit(true);
    end;

    local procedure SaveCheckpoint(RunRequestEntryNo: Integer; CheckpointKey: Text[250]; ProcessedCount: Integer)
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        if RunRequestEntryNo = 0 then
            exit;
        if not RunRequest.Get(RunRequestEntryNo) then
            exit;

        RunRequest."Checkpoint Key" := CheckpointKey;
        RunRequest."Processed Count" := ProcessedCount;
        RunRequest.Modify(true);
        Commit();
    end;

    local procedure MarkRunRequestCancelled(RunRequestEntryNo: Integer)
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        if RunRequestEntryNo = 0 then
            exit;
        if not RunRequest.Get(RunRequestEntryNo) then
            exit;

        RunRequest.Status := RunRequest.Status::Cancelled;
        RunRequest."Completed At" := CurrentDateTime();
        RunRequest."Current Step" := '';
        RunRequest."Result Summary" := 'Cancelado por el usuario.';
        RunRequest.Modify(true);
    end;

    var
        ProgressWindow: Dialog;
        TotalProgressCount: Integer;
        CurrentProgressCount: Integer;
}
