codeunit 60011 "DXR MCC Executor"
{
    // Progress dialog (added 2026-08-22 per explicit user request - "porque no creamos un modal
    // en el running para mostrar cuales tablas setup de cuentas esta migrando"): since Run
    // actions now execute immediately in the caller's own session instead of a background task,
    // there's no separate place to watch progress live - this dialog is that visual. Each entry
    // point below (RunExtension/RunConcept) opens its own dialog only once
    // it knows it has at least one non-blocked concept to run (so extensions/categories with
    // nothing to do never flash an empty dialog), updates it once per dispatcher group and once
    // per concept during verification, and closes it before returning.
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
        CategoryOrdinal: Integer;
        BandOrdinal: Integer;
        TotalConcepts: Integer;
    begin
        Concept.SetRange("Extension Code", ExtensionCode);
        Concept.SetRange(Retired, false);
        Concept.SetRange(Blocked, false);
        TotalConcepts := Concept.Count();
        if TotalConcepts = 0 then
            exit;

        if RunRequestEntryNo = 0 then
            OpenProgress(StrSubstNo('Extensión: %1', ExtensionCode), TotalConcepts);

        // Keep the same dependency-safe lifecycle as RunPortfolio even for a single extension.
        // The former implementation used the first Sequence No. where a dispatcher appeared,
        // which could mix Setup, Master, Accounting and Historic work in one pass. Category-owned
        // dispatchers and their upgrade tags are now always invoked in the explicit lifecycle
        // order, with normal work before deferred/bulk work inside every phase.
        for CategoryOrdinal := 0 to 5 do
            for BandOrdinal := 0 to 1 do
                if not RunExtensionCategory(
                    ExtensionCode, CategoryFromPortfolioOrdinal(CategoryOrdinal), BandOrdinal,
                    CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, RunRequestEntryNo = 0)
                then begin
                if RunRequestEntryNo = 0 then
                    CloseProgress();
                exit;
            end;

        AssignPortfolioPermissions(RunRequestEntryNo);
        if RunRequestEntryNo = 0 then
            CloseProgress();
        Commit();
    end;

    local procedure CategoryFromPortfolioOrdinal(CategoryOrdinal: Integer): Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting
    var
        Concept: Record "DXR MCC Concept";
    begin
        case CategoryOrdinal of
            0:
                exit(Concept.Category::Setup);
            1:
                exit(Concept.Category::Master);
            2:
                exit(Concept.Category::Accounting);
            3:
                exit(Concept.Category::Historic);
            4:
                exit(Concept.Category::Other);
            5:
                exit(Concept.Category::Reporting);
        end;
        exit(Concept.Category::Other);
    end;

    procedure RunConcept(var Concept: Record "DXR MCC Concept")
    begin
        RunConcept(Concept, 0);
    end;

    /// <summary>RunRequestEntryNo-aware overload - same reasoning as RunExtension's.</summary>
    procedure RunConcept(var Concept: Record "DXR MCC Concept"; RunRequestEntryNo: Integer)
    var
        ConceptEntryNos: List of [Integer];
        CompletedCount: Integer;
        GapCount: Integer;
        ErrorCount: Integer;
        BlockedCount: Integer;
        RequestedConceptEntryNo: Integer;
    begin
        if Concept.Blocked or Concept.Retired then
            exit;

        // "Run Concept" still has to represent the dispatcher's real scope. If the selected row
        // shares a category worker, that worker will touch every row in the group; log and verify
        // all of them instead of pretending only the selected row ran.
        RequestedConceptEntryNo := Concept."Entry No.";
        CollectDispatcherConcepts(Concept."Extension Code", Concept."Dispatcher Codeunit ID", false, Concept.Category, false, 0, ConceptEntryNos);
        if RunRequestEntryNo = 0 then
            OpenProgress(StrSubstNo('Dispatcher del concepto: %1', Concept.Description), ConceptEntryNos.Count());

        RunDispatcherGroup(Concept."Extension Code", Concept."Dispatcher Codeunit ID", ConceptEntryNos, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, RunRequestEntryNo = 0);
        Concept.Get(RequestedConceptEntryNo);
        AssignPortfolioPermissions(RunRequestEntryNo);
        if RunRequestEntryNo = 0 then
            CloseProgress();
    end;

    /// <summary>
    /// Runs every non-blocked concept across the whole portfolio in 5 category passes - Setup,
    /// then Master, Accounting, Historic, and Other - each pass itself iterating extensions
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
        ErrorsBeforeCategory: Integer;
    begin
        StartCategoryOrdinal := 0;
        if (RunRequestEntryNo <> 0) and RunRequest.Get(RunRequestEntryNo) and (RunRequest."Checkpoint Key" <> '') then begin
            ColonPos := StrPos(RunRequest."Checkpoint Key", ':');
            if ColonPos > 1 then
                if not Evaluate(StartCategoryOrdinal, CopyStr(RunRequest."Checkpoint Key", 1, ColonPos - 1)) then
                    StartCategoryOrdinal := 0;
        end;

        for CategoryOrdinal := StartCategoryOrdinal to 5 do begin
            if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('Portafolio: iniciando categoría %1/6', CategoryOrdinal + 1)) then begin
                MarkRunRequestCancelled(RunRequestEntryNo);
                exit;
            end;
            StartPortfolioPhase(RunRequestEntryNo, CategoryOrdinal);
            ErrorsBeforeCategory := ErrorCount;
            case CategoryOrdinal of
                0:
                    RunCategory(Concept.Category::Setup, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
                1:
                    RunCategory(Concept.Category::Master, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
                2:
                    RunCategory(Concept.Category::Accounting, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
                3:
                    RunCategory(Concept.Category::Historic, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
                4:
                    RunCategory(Concept.Category::Other, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
                5:
                    RunCategory(Concept.Category::Reporting, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, GetCheckpointKey(RunRequestEntryNo));
            end;
            if IsRunRequestCancelled(RunRequestEntryNo) then begin
                FinishPortfolioPhase(RunRequestEntryNo, CategoryOrdinal, false, true);
                exit;
            end;
            FinishPortfolioPhase(RunRequestEntryNo, CategoryOrdinal, ErrorCount = ErrorsBeforeCategory, false);
            SaveCheckpoint(RunRequestEntryNo, StrSubstNo('%1:-1:', CategoryOrdinal + 1), CategoryOrdinal + 1);
        end;
    end;

    /// <summary>Only the resuming category (the one named in the checkpoint) skips its already-done extensions - every later category pass always starts from its own first extension.</summary>
    local procedure GetCheckpointKey(RunRequestEntryNo: Integer): Text[250]
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        if RunRequestEntryNo = 0 then
            exit('');
        if not RunRequest.Get(RunRequestEntryNo) then
            exit('');
        exit(RunRequest."Checkpoint Key");
    end;

    local procedure StartPortfolioPhase(RunRequestEntryNo: Integer; CategoryOrdinal: Integer)
    var
        RunRequest: Record "DXR MCC Run Request";
        StartedAt: DateTime;
    begin
        if (RunRequestEntryNo = 0) or not RunRequest.Get(RunRequestEntryNo) then
            exit;

        StartedAt := CurrentDateTime();
        case CategoryOrdinal of
            0:
                begin
                    if RunRequest."Setup Started At" = 0DT then
                        RunRequest."Setup Started At" := StartedAt;
                    RunRequest."Setup Completed At" := 0DT;
                    Clear(RunRequest."Setup Duration");
                    RunRequest."Setup Phase Status" := RunRequest."Setup Phase Status"::Running;
                end;
            1:
                begin
                    if RunRequest."Master Started At" = 0DT then
                        RunRequest."Master Started At" := StartedAt;
                    RunRequest."Master Completed At" := 0DT;
                    Clear(RunRequest."Master Duration");
                    RunRequest."Master Phase Status" := RunRequest."Master Phase Status"::Running;
                end;
            2:
                begin
                    if RunRequest."Accounting Started At" = 0DT then
                        RunRequest."Accounting Started At" := StartedAt;
                    RunRequest."Accounting Completed At" := 0DT;
                    Clear(RunRequest."Accounting Duration");
                    RunRequest."Accounting Phase Status" := RunRequest."Accounting Phase Status"::Running;
                end;
            3:
                begin
                    if RunRequest."Historic Started At" = 0DT then
                        RunRequest."Historic Started At" := StartedAt;
                    RunRequest."Historic Completed At" := 0DT;
                    Clear(RunRequest."Historic Duration");
                    RunRequest."Historic Phase Status" := RunRequest."Historic Phase Status"::Running;
                end;
            4:
                begin
                    if RunRequest."Other Started At" = 0DT then
                        RunRequest."Other Started At" := StartedAt;
                    RunRequest."Other Completed At" := 0DT;
                    Clear(RunRequest."Other Duration");
                    RunRequest."Other Phase Status" := RunRequest."Other Phase Status"::Running;
                end;
            5:
                begin
                    if RunRequest."Reporting Started At" = 0DT then
                        RunRequest."Reporting Started At" := StartedAt;
                    RunRequest."Reporting Completed At" := 0DT;
                    Clear(RunRequest."Reporting Duration");
                    RunRequest."Reporting Phase Status" := RunRequest."Reporting Phase Status"::Running;
                end;
        end;
        RunRequest.Modify(true);
        Commit();
    end;

    local procedure FinishPortfolioPhase(RunRequestEntryNo: Integer; CategoryOrdinal: Integer; Completed: Boolean; Cancelled: Boolean)
    var
        RunRequest: Record "DXR MCC Run Request";
        FinishedAt: DateTime;
    begin
        if (RunRequestEntryNo = 0) or not RunRequest.Get(RunRequestEntryNo) then
            exit;

        FinishedAt := CurrentDateTime();
        case CategoryOrdinal of
            0:
                begin
                    RunRequest."Setup Completed At" := FinishedAt;
                    RunRequest."Setup Duration" := FinishedAt - RunRequest."Setup Started At";
                    if Completed then
                        RunRequest."Setup Phase Status" := RunRequest."Setup Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Setup Phase Status" := RunRequest."Setup Phase Status"::Cancelled
                        else
                            RunRequest."Setup Phase Status" := RunRequest."Setup Phase Status"::Failed;
                end;
            1:
                begin
                    RunRequest."Master Completed At" := FinishedAt;
                    RunRequest."Master Duration" := FinishedAt - RunRequest."Master Started At";
                    if Completed then
                        RunRequest."Master Phase Status" := RunRequest."Master Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Master Phase Status" := RunRequest."Master Phase Status"::Cancelled
                        else
                            RunRequest."Master Phase Status" := RunRequest."Master Phase Status"::Failed;
                end;
            2:
                begin
                    RunRequest."Accounting Completed At" := FinishedAt;
                    RunRequest."Accounting Duration" := FinishedAt - RunRequest."Accounting Started At";
                    if Completed then
                        RunRequest."Accounting Phase Status" := RunRequest."Accounting Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Accounting Phase Status" := RunRequest."Accounting Phase Status"::Cancelled
                        else
                            RunRequest."Accounting Phase Status" := RunRequest."Accounting Phase Status"::Failed;
                end;
            3:
                begin
                    RunRequest."Historic Completed At" := FinishedAt;
                    RunRequest."Historic Duration" := FinishedAt - RunRequest."Historic Started At";
                    if Completed then
                        RunRequest."Historic Phase Status" := RunRequest."Historic Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Historic Phase Status" := RunRequest."Historic Phase Status"::Cancelled
                        else
                            RunRequest."Historic Phase Status" := RunRequest."Historic Phase Status"::Failed;
                end;
            4:
                begin
                    RunRequest."Other Completed At" := FinishedAt;
                    RunRequest."Other Duration" := FinishedAt - RunRequest."Other Started At";
                    if Completed then
                        RunRequest."Other Phase Status" := RunRequest."Other Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Other Phase Status" := RunRequest."Other Phase Status"::Cancelled
                        else
                            RunRequest."Other Phase Status" := RunRequest."Other Phase Status"::Failed;
                end;
            5:
                begin
                    RunRequest."Reporting Completed At" := FinishedAt;
                    RunRequest."Reporting Duration" := FinishedAt - RunRequest."Reporting Started At";
                    if Completed then
                        RunRequest."Reporting Phase Status" := RunRequest."Reporting Phase Status"::Completed
                    else
                        if Cancelled then
                            RunRequest."Reporting Phase Status" := RunRequest."Reporting Phase Status"::Cancelled
                        else
                            RunRequest."Reporting Phase Status" := RunRequest."Reporting Phase Status"::Failed;
                end;
        end;
        RunRequest.Modify(true);
        Commit();
    end;

    local procedure IsRunRequestCancelled(RunRequestEntryNo: Integer): Boolean
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        exit((RunRequestEntryNo <> 0) and RunRequest.Get(RunRequestEntryNo) and (RunRequest.Status = RunRequest.Status::Cancelled));
    end;

    internal procedure FailActivePortfolioPhase(RunRequestEntryNo: Integer)
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        if not RunRequest.Get(RunRequestEntryNo) then
            exit;
        if RunRequest.Scope <> RunRequest.Scope::Portfolio then
            exit;

        if RunRequest."Setup Phase Status" = RunRequest."Setup Phase Status"::Running then
            FinishPortfolioPhase(RunRequestEntryNo, 0, false, false)
        else
            if RunRequest."Master Phase Status" = RunRequest."Master Phase Status"::Running then
                FinishPortfolioPhase(RunRequestEntryNo, 1, false, false)
            else
                if RunRequest."Accounting Phase Status" = RunRequest."Accounting Phase Status"::Running then
                    FinishPortfolioPhase(RunRequestEntryNo, 2, false, false)
                else
                    if RunRequest."Historic Phase Status" = RunRequest."Historic Phase Status"::Running then
                        FinishPortfolioPhase(RunRequestEntryNo, 3, false, false)
                    else
                    if RunRequest."Other Phase Status" = RunRequest."Other Phase Status"::Running then
                            FinishPortfolioPhase(RunRequestEntryNo, 4, false, false)
                    else
                        if RunRequest."Reporting Phase Status" = RunRequest."Reporting Phase Status"::Running then
                            FinishPortfolioPhase(RunRequestEntryNo, 5, false, false);
    end;

    /// <summary>
    /// Runs every non-blocked concept of one Category across the whole portfolio, in extension
    /// dependency order (Order No.), then by that extension's own Sequence No. within the
    /// category - with one invocation per effective dispatcher and the same LogAndCount/fallback path as
    /// RunExtension, just filtered to one category and spanning every extension instead of one.
    /// </summary>
    procedure RunCategory(Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer)
    begin
        RunCategory(Category, CompletedCount, GapCount, ErrorCount, BlockedCount, 0, '');
    end;

    /// <summary>
    /// RunRequestEntryNo-aware overload. ResumeAfterExtCode (from Checkpoint Key, empty on a fresh
    /// run) skips every extension up to and including that one - the extensions before it are
    /// assumed already done from a prior attempt, since Checkpoint Key is only ever set AFTER an
    /// extension's own RunExtensionCategory call returns.
    /// </summary>
    procedure RunCategory(Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer; ResumeCheckpoint: Text[250])
    var
        Extension: Record "DXR MCC Extension";
        ExtensionCodes: List of [Code[20]];
        ExtensionCode: Code[20];
        PastCheckpoint: Boolean;
        ProcessedNo: Integer;
        BandOrdinal: Integer;
        ResumeBandOrdinal: Integer;
        ResumeAfterExtCode: Code[20];
    begin
        ResolveCategoryResumeCheckpoint(RunRequestEntryNo, Category, ResumeCheckpoint, ResumeBandOrdinal, ResumeAfterExtCode);
        // Safety: if the checkpointed extension no longer exists (registry changed between
        // attempts), don't silently skip the entire category by never finding it to resume past -
        // treat as a fresh start instead. Checked (and the record variable reset via FindSet
        // below) BEFORE the real iteration starts, so this Get() can't disturb the repeat/Next()
        // cursor position.
        if (ResumeAfterExtCode <> '') and not Extension.Get(ResumeAfterExtCode) then
            ResumeAfterExtCode := '';

        Extension.SetCurrentKey("Order No.", Code);
        if not Extension.FindSet() then
            exit;

        repeat
            ExtensionCodes.Add(Extension.Code);
        until Extension.Next() = 0;

        // Run the complete normal band first, across every extension, and only then the deferred/
        // bulk band. This makes DGII-RNC the tail of Setup and keeps historical heavy tables out of
        // the path of smaller work. A retry may revisit a completed band; adapter tags and row-level
        // idempotency make that safe, while bulk table checkpoints avoid repeating inserted rows.
        for BandOrdinal := 0 to 1 do begin
            if (ResumeBandOrdinal >= 0) and (BandOrdinal < ResumeBandOrdinal) then
                PastCheckpoint := false
            else
                PastCheckpoint := (ResumeBandOrdinal <> BandOrdinal) or (ResumeAfterExtCode = '');
            foreach ExtensionCode in ExtensionCodes do begin
                Extension.Get(ExtensionCode);
                if (ResumeBandOrdinal >= 0) and (BandOrdinal < ResumeBandOrdinal) then begin
                    // The complete band was checkpointed before the failed attempt.
                end else
                if not PastCheckpoint then begin
                    if Extension.Code = ResumeAfterExtCode then
                        PastCheckpoint := true;
                end else begin
                    if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('Categoría %1 (%2): ejecutando extensión %3', Format(Category), Format(BandOrdinal), Extension.Code)) then begin
                        MarkRunRequestCancelled(RunRequestEntryNo);
                        exit;
                    end;
                    if not RunExtensionCategory(Extension.Code, Category, BandOrdinal, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, false) then
                        exit;
                    ProcessedNo += 1;
                    SaveCategoryCheckpoint(RunRequestEntryNo, BandOrdinal, Extension.Code, ProcessedNo);
                end;
            end;
        end;

        AssignPortfolioPermissions(RunRequestEntryNo);
    end;

    /// <summary>
    /// Reasigna los permission sets de TODO el portafolio a todos los usuarios (ver DXR MCC
    /// Portfolio Perm. Mgt.) - punto único usado por RunCategory (cualquier categoría, no solo
    /// Setup), RunExtension y RunConcept, para que una extensión/usuario nuevo quede con permisos
    /// completos sin importar qué alcance/fase disparó la corrida. AssignAllPortfolioPermissionSets
    /// ya es idempotente (EnsureAssignment no reinserta lo que ya existe), así que repetir esta
    /// llamada en cada alcance es seguro, no solo la primera vez que corre Setup.
    /// </summary>
    local procedure AssignPortfolioPermissions(RunRequestEntryNo: Integer): Boolean
    var
        PortfolioPermissionMgt: Codeunit "DXR MCC Portfolio Perm. Mgt.";
        AssignedPermissionCount: Integer;
        ExistingPermissionCount: Integer;
        PermissionSetCount: Integer;
        PermissionUserCount: Integer;
    begin
        if not CheckCancelAndUpdateStep(RunRequestEntryNo, 'Asignando permission sets del portafolio a todos los usuarios.') then begin
            MarkRunRequestCancelled(RunRequestEntryNo);
            exit(false);
        end;
        PortfolioPermissionMgt.AssignAllPortfolioPermissionSets(
            RunRequestEntryNo, AssignedPermissionCount, ExistingPermissionCount,
            PermissionSetCount, PermissionUserCount);
        CheckCancelAndUpdateStep(
            RunRequestEntryNo,
            StrSubstNo(
                'Permisos completados (%1 nuevos, %2 existentes, %3 permission sets, %4 usuarios).',
                AssignedPermissionCount, ExistingPermissionCount, PermissionSetCount, PermissionUserCount));
        exit(true);
    end;

    local procedure ResolveCategoryResumeCheckpoint(RunRequestEntryNo: Integer; Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting; CheckpointKey: Text[250]; var ResumeBandOrdinal: Integer; var ResumeAfterExtCode: Code[20])
    var
        RunRequest: Record "DXR MCC Run Request";
        FirstSeparatorPos: Integer;
        SecondSeparatorPos: Integer;
        CheckpointCategoryOrdinal: Integer;
        RemainingCheckpoint: Text;
    begin
        ResumeBandOrdinal := -1;
        Clear(ResumeAfterExtCode);
        if (RunRequestEntryNo = 0) or (CheckpointKey = '') or not RunRequest.Get(RunRequestEntryNo) then
            exit;

        FirstSeparatorPos := StrPos(CheckpointKey, ':');
        if FirstSeparatorPos = 0 then
            exit; // Legacy extension-only checkpoint: restart safely instead of skipping the wrong band.

        if RunRequest.Scope = RunRequest.Scope::Portfolio then begin
            if not Evaluate(CheckpointCategoryOrdinal, CopyStr(CheckpointKey, 1, FirstSeparatorPos - 1)) then
                exit;
            if CheckpointCategoryOrdinal <> PortfolioOrdinalForCategory(Category) then
                exit;

            RemainingCheckpoint := CopyStr(CheckpointKey, FirstSeparatorPos + 1);
            SecondSeparatorPos := StrPos(RemainingCheckpoint, ':');
            if SecondSeparatorPos = 0 then
                exit; // Legacy portfolio checkpoint "phase:extension".
            if not Evaluate(ResumeBandOrdinal, CopyStr(RemainingCheckpoint, 1, SecondSeparatorPos - 1)) then begin
                ResumeBandOrdinal := -1;
                exit;
            end;
            ResumeAfterExtCode := CopyStr(RemainingCheckpoint, SecondSeparatorPos + 1, MaxStrLen(ResumeAfterExtCode));
        end else begin
            if not Evaluate(ResumeBandOrdinal, CopyStr(CheckpointKey, 1, FirstSeparatorPos - 1)) then begin
                ResumeBandOrdinal := -1;
                exit;
            end;
            ResumeAfterExtCode := CopyStr(CheckpointKey, FirstSeparatorPos + 1, MaxStrLen(ResumeAfterExtCode));
        end;

        if not (ResumeBandOrdinal in [0, 1]) then begin
            ResumeBandOrdinal := -1;
            Clear(ResumeAfterExtCode);
        end;
    end;

    local procedure PortfolioOrdinalForCategory(Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting): Integer
    var
        Concept: Record "DXR MCC Concept";
    begin
        case Category of
            Concept.Category::Setup:
                exit(0);
            Concept.Category::Master:
                exit(1);
            Concept.Category::Accounting:
                exit(2);
            Concept.Category::Historic:
                exit(3);
            Concept.Category::Other:
                exit(4);
            Concept.Category::Reporting:
                exit(5);
        end;
        exit(-1);
    end;

    local procedure RunExtensionCategory(ExtensionCode: Code[20]; Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting; BandOrdinal: Integer; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer; ShowProgress: Boolean): Boolean
    var
        Concept: Record "DXR MCC Concept";
        SeenDispatchers: Dictionary of [Integer, Boolean];
        DispatcherIds: List of [Integer];
        ConceptEntryNos: List of [Integer];
        DispatcherId: Integer;
    begin
        Concept.SetRange("Extension Code", ExtensionCode);
        Concept.SetRange(Category, Category);
        Concept.SetRange("Execution Band", BandOrdinal);
        Concept.SetRange(Retired, false);
        Concept.SetRange(Blocked, false);
        Concept.SetCurrentKey("Extension Code", "Sequence No.");
        if not Concept.FindSet() then
            exit(true);

        repeat
            if not SeenDispatchers.ContainsKey(Concept."Dispatcher Codeunit ID") then begin
                SeenDispatchers.Add(Concept."Dispatcher Codeunit ID", true);
                DispatcherIds.Add(Concept."Dispatcher Codeunit ID");
            end;
        until Concept.Next() = 0;

        // No progress Dialog here (2026-08-22, removed): RunCategory/RunPortfolio - the only
        // callers of this procedure - now always run as a background task (Dialog.Open() has no
        // client to show it to in a TaskScheduler session and would fail there). Progress for
        // these scopes is DXR MCC Run Requests ("Current Step"/"Checkpoint Key"/"Processed Count",
        // updated by RunCategory around this call) and Run Log, not a live modal - see RunExtension
        // for the synchronous, dialog-driven equivalent used by the still-immediate "Run Extension"/
        // "Run Concept" actions.
        //
        // A registry category may contain dozens of table rows owned by one category dispatcher.
        // Invoke that dispatcher once, log every covered row as Running before the call, and then
        // verify every row after it returns. This keeps Current Step honest and removes repeated
        // Upgrade-Tag no-op calls without weakening adapter-owned idempotency.
        foreach DispatcherId in DispatcherIds do begin
            Clear(ConceptEntryNos);
            CollectDispatcherConcepts(ExtensionCode, DispatcherId, true, Category, true, BandOrdinal, ConceptEntryNos);
            if not RunDispatcherGroup(ExtensionCode, DispatcherId, ConceptEntryNos, CompletedCount, GapCount, ErrorCount, BlockedCount, RunRequestEntryNo, ShowProgress) then
                exit(false);
        end;
        Commit();
        exit(true);
    end;

    local procedure CollectDispatcherConcepts(ExtensionCode: Code[20]; DispatcherId: Integer; FilterCategory: Boolean; Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting; FilterExecutionBand: Boolean; ExecutionBandOrdinal: Integer; var ConceptEntryNos: List of [Integer])
    var
        Concept: Record "DXR MCC Concept";
    begin
        Concept.SetRange("Extension Code", ExtensionCode);
        Concept.SetRange(Retired, false);
        Concept.SetRange(Blocked, false);
        Concept.SetRange("Dispatcher Codeunit ID", DispatcherId);
        if FilterCategory then
            Concept.SetRange(Category, Category);
        if FilterExecutionBand then
            Concept.SetRange("Execution Band", ExecutionBandOrdinal);
        Concept.SetCurrentKey("Extension Code", "Sequence No.");
        if not Concept.FindSet() then
            exit;

        repeat
            ConceptEntryNos.Add(Concept."Entry No.");
        until Concept.Next() = 0;
    end;

    local procedure RunDispatcherGroup(ExtensionCode: Code[20]; DispatcherId: Integer; ConceptEntryNos: List of [Integer]; var CompletedCount: Integer; var GapCount: Integer; var ErrorCount: Integer; var BlockedCount: Integer; RunRequestEntryNo: Integer; ShowProgress: Boolean): Boolean
    var
        Concept: Record "DXR MCC Concept";
        ErrorText: Text;
        DispatcherDescription: Text;
        DurationMs: Integer;
        ConceptEntryNo: Integer;
        RunningLogEntryNo: Integer;
        RunningLogIndex: Integer;
        SharedByCount: Integer;
        RunningLogEntryNos: List of [Integer];
    begin
        SharedByCount := ConceptEntryNos.Count();
        if SharedByCount = 0 then
            exit(true);

        ConceptEntryNos.Get(1, ConceptEntryNo);
        Concept.Get(ConceptEntryNo);
        DispatcherDescription := StrSubstNo('Dispatcher %1: %2', DispatcherId, Concept.Description);

        if not CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: iniciando dispatcher %2 (%3 conceptos) - %4', ExtensionCode, DispatcherId, SharedByCount, ResolveConceptTableName(Concept))) then begin
            MarkRunRequestCancelled(RunRequestEntryNo);
            exit(false);
        end;
        if ShowProgress then
            UpdateProgressStarting(ExtensionCode, DispatcherDescription, SharedByCount);

        // Persist every covered table/concept as Running before entering the potentially long,
        // blocking Codeunit.Run(). Never hold a FindSet cursor across these Commit boundaries.
        foreach ConceptEntryNo in ConceptEntryNos do begin
            Concept.Get(ConceptEntryNo);
            RunningLogEntryNos.Add(LogConceptStarting(Concept, RunRequestEntryNo));
        end;

        RunDispatcher(DispatcherId, ErrorText, DurationMs);
        CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: dispatcher %2 finalizado; verificando %3 conceptos', ExtensionCode, DispatcherId, SharedByCount));

        RunningLogIndex := 0;
        foreach ConceptEntryNo in ConceptEntryNos do begin
            RunningLogIndex += 1;
            RunningLogEntryNos.Get(RunningLogIndex, RunningLogEntryNo);
            Concept.Get(ConceptEntryNo);
            CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: verificando %2', ExtensionCode, ResolveConceptTableName(Concept)));
            LogAndCount(Concept, ErrorText, DurationMs, RunRequestEntryNo, RunningLogEntryNo);
            if ShowProgress then
                UpdateProgressVerified(Concept."Extension Code", Concept.Description, Concept.Status, Concept."Old Record Count", Concept."Migrated Record Count", Concept.Gap);
            CheckCancelAndUpdateStep(RunRequestEntryNo, StrSubstNo('%1: verificado %2 (%3)', ExtensionCode, ResolveConceptTableName(Concept), Format(Concept.Status)));
            case Concept.Status of
                Concept.Status::Completed:
                    CompletedCount += 1;
                Concept.Status::"Completed With Gaps":
                    GapCount += 1;
                Concept.Status::Error:
                    ErrorCount += 1;
                Concept.Status::Skipped:
                    BlockedCount += 1;
            end;
        end;
        exit(true);
    end;

    /// <summary>
    /// Human-readable "what table is this" for the live Current Step text - prefers the New Table
    /// ID's real caption (the active table an operator would recognize, e.g. "Catálogo de cuentas"
    /// for G/L Account), falls back to the Legacy Table ID's caption, falls back to the concept's
    /// own Description for field-only concepts (Legacy/New Table ID both 0, nothing to resolve).
    /// </summary>
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

    local procedure ResolveLegacyTableName(var Concept: Record "DXR MCC Concept"): Text[250]
    begin
        if Concept."Legacy Table ID" <> 0 then
            exit(ResolveTableNameById(Concept."Legacy Table ID"));
        if Concept.Retired then
            exit(CopyStr(StrSubstNo('[No aplica - concepto retirado] %1', Concept.Description), 1, 250));
        if Concept."Dispatcher Codeunit ID" <> 0 then
            exit(CopyStr(StrSubstNo('[No aplica - migración por campos] %1', Concept.Description), 1, 250));
        exit(CopyStr(StrSubstNo('[Legacy ID no definido] %1', Concept.Description), 1, 250));
    end;

    local procedure ResolveNewTableName(var Concept: Record "DXR MCC Concept"): Text[250]
    begin
        if Concept."New Table ID" <> 0 then
            exit(ResolveTableNameById(Concept."New Table ID"));
        if Concept.Retired then
            exit(CopyStr(StrSubstNo('[No aplica - concepto retirado] %1', Concept.Description), 1, 250));
        if Concept."Dispatcher Codeunit ID" <> 0 then
            exit(CopyStr(StrSubstNo('[No aplica - migración por campos] %1', Concept.Description), 1, 250));
        exit(CopyStr(StrSubstNo('[New ID no definido] %1', Concept.Description), 1, 250));
    end;

    /// <summary>Schedules one concept through the same background execution path used by every other scope.</summary>
    procedure ScheduleConcept(var Concept: Record "DXR MCC Concept")
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Concept, '', Concept."Entry No.");
        ScheduleRunRequestInBackground(RunRequest);
    end;

    /// <summary>Schedules all non-blocked concepts for one extension in the background.</summary>
    procedure ScheduleExtension(ExtensionCode: Code[20])
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Extension, ExtensionCode, 0);
        ScheduleRunRequestInBackground(RunRequest);
    end;

    /// <summary>
    /// Category-scoped runs stay in TaskScheduler because a portfolio category can legitimately
    /// scan many large tables. Registry loading resolves the original monolithic dispatchers to
    /// category workers, and RunExtensionCategory invokes each effective worker once regardless
    /// of how many table/concept rows describe its workload.
    /// </summary>
    procedure ScheduleCategory(Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting)
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Category, '', 0);
        RunRequest.Category := Category;
        RunRequest.Modify(true);
        ScheduleRunRequestInBackground(RunRequest);
    end;

    /// <summary>Same pattern as ScheduleConcept, for a full-portfolio run (every registered extension).</summary>
    procedure SchedulePortfolio()
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::Portfolio, '', 0);
        ScheduleRunRequestInBackground(RunRequest);
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
    begin
        InitRunRequest(RunRequest, RunRequest.Scope::RecountAll, '', 0);
        ScheduleRunRequestInBackground(RunRequest);
    end;

    /// <summary>The actual recount loop used by the background runner. No Dialog here because background tasks have no UI.</summary>
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
        Concept.SetRange(Retired, false);
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
        RunRequest."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(RunRequest."Company Name"));
        RunRequest.Insert(true);
        RunRequest."Company Entry No." := RunRequest."Entry No.";
        RunRequest.Modify(true);
    end;

    internal procedure SchedulePreparedRunRequest(var RunRequest: Record "DXR MCC Run Request")
    begin
        ScheduleRunRequestInBackground(RunRequest);
    end;

    local procedure ScheduleRunRequestInBackground(var RunRequest: Record "DXR MCC Run Request")
    var
        FailureText: Text;
    begin
        // Persist the request before acquiring the cross-company lock. From this point onward every
        // failure is also persisted explicitly so no row can remain Scheduled without a real task.
        Commit();

        if not TryAcquireGlobalLock(RunRequest) then begin
            FailRunRequestLockBusy(RunRequest);
            Commit();
            Error(RunRequest."Result Summary");
        end;

        if not TaskScheduler.CanCreateTask() then begin
            FailureText := 'No se pudo programar la migración: la sesión o licencia actual no permite crear tareas de TaskScheduler.';
            FailRunRequestScheduling(RunRequest, FailureText);
            Commit();
            Error(FailureText);
        end;

        ClearLastError();
        if not TryCreateBackgroundTask(RunRequest) then begin
            FailureText := GetLastErrorText();
            if FailureText = '' then
                FailureText := 'TaskScheduler no pudo crear la tarea en background.';
            FailRunRequestScheduling(RunRequest, FailureText);
            Commit();
            Error(FailureText);
        end;

        // Task Id, request and global lock become visible atomically before the task can consume
        // the RecordId. The background runner owns lock release from this point forward.
        Commit();
    end;

    [TryFunction]
    local procedure TryCreateBackgroundTask(var RunRequest: Record "DXR MCC Run Request")
    var
        TargetCompanyName: Text;
    begin
        TargetCompanyName := RunRequest."Company Name";
        if TargetCompanyName = '' then
            TargetCompanyName := CompanyName();
        RunRequest."Task Id" := TaskScheduler.CreateTask(
            Codeunit::"DXR MCC Background Runner", 0, true, TargetCompanyName, CurrentDateTime(), RunRequest.RecordId(), MigrationTaskTimeout());
        RunRequest.Modify(true);
    end;

    internal procedure MigrationTaskTimeout(): Duration
    begin
        exit(12 * 60 * 60 * 1000);
    end;

    local procedure FailRunRequestScheduling(var RunRequest: Record "DXR MCC Run Request"; FailureText: Text)
    begin
        RunRequest.Status := RunRequest.Status::Failed;
        RunRequest."Completed At" := CurrentDateTime();
        RunRequest."Result Summary" := CopyStr(FailureText, 1, MaxStrLen(RunRequest."Result Summary"));
        RunRequest.Modify(true);
        ReleaseGlobalLock(RunRequest);
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

    local procedure LogAndCount(var Concept: Record "DXR MCC Concept"; ErrorText: Text; DurationMs: Integer; RunRequestEntryNo: Integer; RunningLogEntryNo: Integer)
    var
        Counter: Codeunit "DXR MCC Counter";
        RunLog: Record "DXR MCC Run Log";
        FallbackRowsCopied: Integer;
        FallbackResultText: Text;
        UsedFallback: Boolean;
        FallbackApplied: Boolean;
        TableOpenFailed: Boolean;
        NotRowBased: Boolean;
        InformationalSkipped: Boolean;
        HasGap: Boolean;
        DispatcherWarning: Text;
        VerificationStartedAt: DateTime;
    begin
        VerificationStartedAt := CurrentDateTime();
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
        InformationalSkipped := (Concept.Status = Concept.Status::Skipped) and
            (Concept."Dispatcher Codeunit ID" = 0) and
            (Concept."Legacy Table ID" = 0) and (Concept."New Table ID" = 0);

        HasGap := (not TableOpenFailed) and (not NotRowBased) and
            (Concept."Legacy Table ID" <> 0) and (Concept."New Table ID" <> 0) and
            (Concept."Legacy Table ID" <> Concept."New Table ID") and
            (Concept."Migrated Record Count" < Concept."Old Record Count");

        // This is portfolio-wide, not DESB-specific: shared dispatchers in any extension may
        // finish one table successfully and only report a cancelled database command later. If
        // this concept's own reconciliation proves no gap, preserve the cancellation as a warning
        // instead of converting already-complete data into a false Error or launching fallback.
        if (not TableOpenFailed) and (not NotRowBased) and (not HasGap) and
           IsDatabaseCommandCancelled(ErrorText)
        then begin
            DispatcherWarning := ErrorText;
            Clear(ErrorText);
        end;

        // Fallback now also fires on a plain leftover gap (HasGap), not just ErrorText<>''/
        // Dispatcher=0 as before - MCC's own generic RecordRef reconciliation (see DXR MCC Fallback
        // Migrator) is the one gap-closing path that doesn't depend on the owning extension's
        // dispatcher ever being fixed, recompiled, or having its Upgrade Tag manually cleared.
        if (not TableOpenFailed) and (not NotRowBased) and
           (HasGap or (ErrorText <> '') or (Concept."Dispatcher Codeunit ID" = 0)) and
           (Concept."Legacy Table ID" <> 0) and (Concept."New Table ID" <> 0)
        then
            if TryRestoreConceptSafely(Concept, RunRequestEntryNo, FallbackRowsCopied, FallbackResultText, FallbackApplied) then begin
                if FallbackApplied then begin
                    UsedFallback := true;
                    ErrorText := '';
                    Counter.CountConcept(Concept); // refresh Old/Migrated/Gap - fallback may have closed some/all of it
                    HasGap := (Concept."Legacy Table ID" <> Concept."New Table ID") and (Concept."Legacy Table ID" <> 0) and
                        (Concept."Migrated Record Count" < Concept."Old Record Count");
                end;
            end else
                if GetLastErrorText() <> '' then begin
                    // A generic fallback is remediation for one concept, never a reason to abort
                    // the complete extension/category/portfolio. Preserve the dispatcher error
                    // when one already exists; otherwise surface the fallback failure on this
                    // concept and continue with the next dispatcher group.
                    FallbackResultText := GetLastErrorText();
                    if ErrorText = '' then
                        ErrorText := StrSubstNo('Fallback aislado falló: %1', FallbackResultText)
                    else
                        ErrorText := StrSubstNo('%1 Fallback aislado también falló: %2', ErrorText, FallbackResultText);
                    ClearLastError();
                end;

        if not RunLog.Get(RunningLogEntryNo) then
            RunLog.Init();
        RunLog."Concept Entry No." := Concept."Entry No.";
        RunLog."Run Request Entry No." := RunRequestEntryNo;
        RunLog."Extension Code" := Concept."Extension Code";
        RunLog."Phase Code" := Concept."Phase Code";
        RunLog."Concept Description" := CopyStr(Concept.Description, 1, MaxStrLen(RunLog."Concept Description"));
        RunLog."Legacy Table ID" := Concept."Legacy Table ID";
        RunLog."New Table ID" := Concept."New Table ID";
        RunLog."Table Name" := CopyStr(ResolveConceptTableName(Concept), 1, 250);
        RunLog."Legacy Table Name" := ResolveLegacyTableName(Concept);
        RunLog."New Table Name" := ResolveNewTableName(Concept);
        RunLog."Company Name" := CopyStr(CompanyName(), 1, 30);
        if RunLog."Run DateTime" = 0DT then
            RunLog."Run DateTime" := CurrentDateTime();
        RunLog."Old Record Count" := Concept."Old Record Count";
        RunLog."Migrated Record Count" := Concept."Migrated Record Count";
        // Include counting, bulk reconciliation, and post-verification. Previously Duration only
        // measured Codeunit.Run(), making dispatcher=0 bulk restores appear as 0 ms.
        DurationMs += CurrentDateTime() - VerificationStartedAt;
        RunLog."Duration (ms)" := DurationMs;
        RunLog."User ID" := CopyStr(UserId(), 1, 50);
        Clear(RunLog."Error Message");

        if UsedFallback then begin
            RunLog.Status := RunLog.Status::Completed;
            RunLog."Error Message" := CopyStr(FallbackResultText, 1, MaxStrLen(RunLog."Error Message"));
            Concept.Status := Concept.Status::"Completed (Fallback)";
        end else
            if TableOpenFailed then begin
                if ErrorText = '' then begin
                    // The owning dispatcher completed, but MCC's generic verification session
                    // cannot open one of the external tables. This is an unverifiable concept, not
                    // proof that migration failed. Log and continue so one missing indirect read
                    // permission cannot stop the extension or leave subsequent concepts Running.
                    RunLog.Status := RunLog.Status::Skipped;
                    RunLog."Error Message" := CopyStr(
                        'Verificación omitida: MCC no pudo abrir Legacy y/o New Table ID con los permisos de esta sesión. El dispatcher finalizó sin error; revise permisos del adaptador/extension.',
                        1, MaxStrLen(RunLog."Error Message"));
                    Concept.Status := Concept.Status::Skipped;
                end else begin
                    RunLog.Status := RunLog.Status::Error;
                    RunLog."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RunLog."Error Message"));
                    Concept.Status := Concept.Status::Error;
                end;
            end else
            if InformationalSkipped then begin
                RunLog.Status := RunLog.Status::Skipped;
                RunLog."Error Message" := CopyStr('Concepto informativo o retirado: no tiene dispatcher ni identidad de tablas; no existe trabajo runtime que ejecutar.', 1, MaxStrLen(RunLog."Error Message"));
                Concept.Status := Concept.Status::Skipped;
            end else
            if IsSkippableMissingRecordError(ErrorText) then begin
                // Optional singleton setup records are validly absent in some companies. The
                // owning dispatcher reports that absence as an error, but MCC treats it as an
                // isolated skipped concept so the remaining setup/master/historic units continue.
                RunLog.Status := RunLog.Status::Skipped;
                RunLog."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RunLog."Error Message"));
                Concept.Status := Concept.Status::Skipped;
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
                if DispatcherWarning <> '' then
                    RunLog."Error Message" := CopyStr(
                        StrSubstNo('Completado por reconciliación de conteos; el dispatcher reportó después: %1', DispatcherWarning),
                        1, MaxStrLen(RunLog."Error Message"));
            end;

        Concept."Last Run DateTime" := CurrentDateTime();
        Concept.Modify(true);
        if RunLog."Entry No." = 0 then
            RunLog.Insert(true)
        else
            RunLog.Modify(true);
    end;

    /// <summary>
    /// Cloud-safe error boundary around the generic RecordRef fallback. Business Central online
    /// permits writes inside TryFunctions but does not roll them back. The fallback is therefore
    /// required to remain idempotent and checkpointed: rows already inserted are skipped and the
    /// next execution resumes without overwriting them. Any schema/key/permission exception is
    /// converted into the current concept's Error instead of crashing the portfolio request.
    /// </summary>
    [TryFunction]
    local procedure TryRestoreConceptSafely(var Concept: Record "DXR MCC Concept"; RunRequestEntryNo: Integer; var RowsCopied: Integer; var ResultText: Text; var FallbackApplied: Boolean)
    var
        FallbackMigrator: Codeunit "DXR MCC Fallback Migrator";
    begin
        FallbackApplied := FallbackMigrator.TryRestoreConcept(Concept, RunRequestEntryNo, RowsCopied, ResultText);
    end;

    local procedure IsSkippableMissingRecordError(ErrorText: Text): Boolean
    begin
        if ErrorText = '' then
            exit(false);

        exit(
            ErrorText.Contains('does not exist. Identification fields and values:') or
            ErrorText.Contains('no existe. Campos y valores de identificación:'));
    end;

    local procedure IsDatabaseCommandCancelled(ErrorText: Text): Boolean
    var
        NormalizedError: Text;
    begin
        if ErrorText = '' then
            exit(false);

        NormalizedError := LowerCase(ErrorText);
        exit(
            ((StrPos(NormalizedError, 'database command') > 0) and
             (StrPos(NormalizedError, 'cancel') > 0)) or
            ((StrPos(NormalizedError, 'comando de base de datos') > 0) and
             (StrPos(NormalizedError, 'cancel') > 0)));
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
    /// LogAndCount updates this same row to Completed/Error/etc. after the dispatcher returns. One
    /// row therefore represents the full concept execution and cannot remain as an orphaned
    /// Running row beside a separate terminal entry.
    /// </summary>
    local procedure LogConceptStarting(var Concept: Record "DXR MCC Concept"; RunRequestEntryNo: Integer): Integer
    var
        RunLog: Record "DXR MCC Run Log";
    begin
        RunLog.Init();
        RunLog."Concept Entry No." := Concept."Entry No.";
        RunLog."Run Request Entry No." := RunRequestEntryNo;
        RunLog."Extension Code" := Concept."Extension Code";
        RunLog."Phase Code" := Concept."Phase Code";
        RunLog."Concept Description" := CopyStr(Concept.Description, 1, MaxStrLen(RunLog."Concept Description"));
        RunLog."Legacy Table ID" := Concept."Legacy Table ID";
        RunLog."New Table ID" := Concept."New Table ID";
        RunLog."Table Name" := CopyStr(ResolveConceptTableName(Concept), 1, 250);
        RunLog."Legacy Table Name" := ResolveLegacyTableName(Concept);
        RunLog."New Table Name" := ResolveNewTableName(Concept);
        RunLog."Company Name" := CopyStr(CompanyName(), 1, 30);
        RunLog."Run DateTime" := CurrentDateTime();
        RunLog.Status := RunLog.Status::Running;
        RunLog."User ID" := CopyStr(UserId(), 1, 50);
        RunLog.Insert(true);
        Commit();
        exit(RunLog."Entry No.");
    end;

    /// <summary>
    /// Global cross-company lock (same pattern as DR-Localization's "DXR_Migration Lock Mgt.") -
    /// refuses to schedule a second run while one is already active anywhere in the tenant. Its
    /// lease is longer than TaskScheduler's normal maximum execution window and is renewed at
    /// every heartbeat, so a valid long portfolio run never silently loses exclusivity.
    /// </summary>
    local procedure TryAcquireGlobalLock(var RunRequest: Record "DXR MCC Run Request"): Boolean
    var
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
    begin
        ReconcileStaleRunningRequests();
        exit(LockMgt.TryAcquireLock(RunRequestCompanyName(RunRequest), CopyStr(UserId(), 1, 50), MigrationLockDuration(), RunRequest."Entry No."));
    end;

    local procedure RunRequestCompanyName(var RunRequest: Record "DXR MCC Run Request"): Text
    begin
        if RunRequest."Company Name" <> '' then
            exit(RunRequest."Company Name");

        exit(CompanyName());
    end;

    local procedure MigrationLockDuration(): Duration
    begin
        exit(13 * 60 * 60 * 1000);
    end;

    /// <summary>
    /// Self-heals a Category/Portfolio/RecountAll Run Request stuck showing Status = Running with
    /// no real background task behind it anymore (platform-killed session, server restart, or the
    /// task genuinely exceeding its TaskScheduler timeout) - see "Last Heartbeat" on DXR MCC Run
    /// Request for the full root-cause writeup. Called from TryAcquireGlobalLock (before every new
    /// Schedule* attempt) and from the Run Requests page (OnOpenPage) so the operator sees correct
    /// status without having to trigger a new run first. The 13-hour threshold intentionally
    /// exceeds TaskScheduler's normal maximum execution window: a single blocking dispatcher
    /// cannot emit an MCC heartbeat while Codeunit.Run() is active, so a shorter threshold could
    /// falsely release the global lock while that session was still modifying business tables.
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
            FailRunningLogsForRequest(RunRequest."Entry No.", RunRequest."Result Summary");
            LockMgt.ForceReleaseLockForRunRequest(RunRequest."Entry No.");
        until RunRequest.Next() = 0;
        Commit();
    end;

    local procedure StaleRunningThresholdMs(): BigInteger
    begin
        exit(13 * 60 * 60 * 1000);
    end;

    internal procedure FailRunningLogsForRequest(RunRequestEntryNo: Integer; FailureText: Text)
    var
        RunLog: Record "DXR MCC Run Log";
    begin
        if RunRequestEntryNo = 0 then
            exit;

        RunLog.SetRange("Run Request Entry No.", RunRequestEntryNo);
        RunLog.SetRange(Status, RunLog.Status::Running);
        if not RunLog.FindSet(true) then
            exit;

        repeat
            RunLog.Status := RunLog.Status::Error;
            RunLog."Error Message" := CopyStr(FailureText, 1, MaxStrLen(RunLog."Error Message"));
            RunLog.Modify(true);
        until RunLog.Next() = 0;
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
        LockMgt: Codeunit "DXR MCC Migration Lock Mgt.";
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
        LockMgt.RenewLockForRunRequest(RunRequestEntryNo, MigrationLockDuration());
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

    local procedure SaveCategoryCheckpoint(RunRequestEntryNo: Integer; BandOrdinal: Integer; ExtensionCode: Code[20]; ProcessedCount: Integer)
    var
        RunRequest: Record "DXR MCC Run Request";
        PortfolioOrdinal: Integer;
    begin
        if (RunRequestEntryNo = 0) or not RunRequest.Get(RunRequestEntryNo) then
            exit;

        if RunRequest.Scope <> RunRequest.Scope::Portfolio then begin
            SaveCheckpoint(RunRequestEntryNo, CopyStr(StrSubstNo('%1:%2', BandOrdinal, ExtensionCode), 1, 250), ProcessedCount);
            exit;
        end;

        PortfolioOrdinal := ActivePortfolioOrdinal(RunRequest);
        SaveCheckpoint(RunRequestEntryNo, CopyStr(StrSubstNo('%1:%2:%3', PortfolioOrdinal, BandOrdinal, ExtensionCode), 1, 250), ProcessedCount);
    end;

    local procedure ActivePortfolioOrdinal(var RunRequest: Record "DXR MCC Run Request"): Integer
    begin
        if RunRequest."Setup Phase Status" = RunRequest."Setup Phase Status"::Running then exit(0);
        if RunRequest."Master Phase Status" = RunRequest."Master Phase Status"::Running then exit(1);
        if RunRequest."Accounting Phase Status" = RunRequest."Accounting Phase Status"::Running then exit(2);
        if RunRequest."Historic Phase Status" = RunRequest."Historic Phase Status"::Running then exit(3);
        if RunRequest."Other Phase Status" = RunRequest."Other Phase Status"::Running then exit(4);
        if RunRequest."Reporting Phase Status" = RunRequest."Reporting Phase Status"::Running then exit(5);
        exit(0);
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
