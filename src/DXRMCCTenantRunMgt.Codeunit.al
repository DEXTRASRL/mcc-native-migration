codeunit 60445 "DXR MCC Tenant Run Mgt."
{
    Permissions =
        tabledata Company = R,
        tabledata "DXR MCC Run Request" = RIMD;

    procedure SchedulePortfolioForAllCompanies()
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        CreateTenantChain(RunRequest.Scope::Portfolio, RunRequest.Category::Setup);
    end;

    procedure ScheduleCategoryForAllCompanies(Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting)
    var
        RunRequest: Record "DXR MCC Run Request";
    begin
        CreateTenantChain(RunRequest.Scope::Category, Category);
    end;

    procedure ContinueTenantChain(CompletedTenantRunId: Guid; CompletedCompanySequence: Integer)
    var
        Company: Record Company;
        RunRequest: Record "DXR MCC Run Request";
        Executor: Codeunit "DXR MCC Executor";
        EmptyTaskId: Guid;
    begin
        if IsNullGuid(CompletedTenantRunId) then
            exit;

        Company.SetCurrentKey(Name);
        if not Company.FindSet() then
            exit;

        repeat
            RunRequest.Reset();
            RunRequest.ChangeCompany(Company.Name);
            RunRequest.SetRange("Tenant Run ID", CompletedTenantRunId);
            RunRequest.SetFilter("Company Sequence", '>%1', CompletedCompanySequence);
            RunRequest.SetRange("Tenant Chain", true);
            RunRequest.SetRange(Status, RunRequest.Status::Scheduled);
            RunRequest.SetRange("Task Id", EmptyTaskId);
            if RunRequest.FindFirst() then begin
                if TrySchedulePreparedRunRequest(Executor, RunRequest) then
                    exit;

                // A company that cannot be scheduled must not strand the remainder of the
                // tenant chain. Executor already records the scheduling error on this row.
                ContinueTenantChain(CompletedTenantRunId, RunRequest."Company Sequence");
                exit;
            end;
        until Company.Next() = 0;
    end;

    procedure CancelRemainingTenantChain(TenantRunId: Guid; CompletedCompanySequence: Integer)
    var
        Company: Record Company;
        RunRequest: Record "DXR MCC Run Request";
    begin
        if IsNullGuid(TenantRunId) then
            exit;

        if Company.FindSet() then
            repeat
                RunRequest.Reset();
                RunRequest.ChangeCompany(Company.Name);
                RunRequest.SetRange("Tenant Run ID", TenantRunId);
                RunRequest.SetFilter("Company Sequence", '>%1', CompletedCompanySequence);
                RunRequest.SetRange("Tenant Chain", true);
                RunRequest.SetRange(Status, RunRequest.Status::Scheduled);
                if RunRequest.FindSet(true) then
                    repeat
                        if IsNullGuid(RunRequest."Task Id") then begin
                            RunRequest.Status := RunRequest.Status::Cancelled;
                            RunRequest."Completed At" := CurrentDateTime();
                            RunRequest."Result Summary" := 'Cancelado por la cadena multi-compania.';
                            RunRequest.Modify(true);
                        end;
                    until RunRequest.Next() = 0;
            until Company.Next() = 0;
    end;

    local procedure CreateTenantChain(Scope: Option; Category: Option Setup,"Master/Accounting",Historic,Other,Master,Accounting,Reporting)
    var
        Company: Record Company;
        RunRequest: Record "DXR MCC Run Request";
        Executor: Codeunit "DXR MCC Executor";
        TenantRunId: Guid;
        CompanySequence: Integer;
        FirstCompanyName: Text[30];
        FirstEntryNo: Integer;
    begin
        TenantRunId := CreateGuid();
        Company.SetCurrentKey(Name);
        if not Company.FindSet() then
            Error('No existen companias disponibles en el tenant actual.');

        repeat
            CompanySequence += 1;
            RunRequest.Reset();
            RunRequest.ChangeCompany(Company.Name);
            RunRequest.Init();
            RunRequest.Scope := Scope;
            RunRequest.Category := Category;
            RunRequest."Attempt No." := 1;
            RunRequest.Status := RunRequest.Status::Scheduled;
            RunRequest."Scheduled At" := CurrentDateTime();
            RunRequest."Requested By" := CopyStr(UserId(), 1, MaxStrLen(RunRequest."Requested By"));
            RunRequest."Company Name" := Company.Name;
            RunRequest."Tenant Run ID" := TenantRunId;
            RunRequest."Company Sequence" := CompanySequence;
            RunRequest."Tenant Chain" := true;
            RunRequest.Insert(true);
            RunRequest."Company Entry No." := RunRequest."Entry No.";
            RunRequest.Modify(true);

            if CompanySequence = 1 then begin
                FirstCompanyName := Company.Name;
                FirstEntryNo := RunRequest."Entry No.";
            end;
        until Company.Next() = 0;

        Commit();
        RunRequest.Reset();
        RunRequest.ChangeCompany(FirstCompanyName);
        RunRequest.Get(FirstEntryNo);
        if not TrySchedulePreparedRunRequest(Executor, RunRequest) then begin
            CancelRemainingTenantChain(TenantRunId, 0);
            Error('No se pudo iniciar la cadena multi-compania: %1', GetLastErrorText());
        end;
    end;

    [TryFunction]
    local procedure TrySchedulePreparedRunRequest(var Executor: Codeunit "DXR MCC Executor"; var RunRequest: Record "DXR MCC Run Request")
    begin
        Executor.SchedulePreparedRunRequest(RunRequest);
    end;
}
