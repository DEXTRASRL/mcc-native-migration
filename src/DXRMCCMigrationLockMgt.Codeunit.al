codeunit 60016 "DXR MCC Migration Lock Mgt."
{
    // Ported from DR-Localization's "DXR_Migration Lock Mgt." (52252 / 39003261) - same
    // coordinator-company mutex, same Expires At auto-release so a session that dies mid-run
    // (killed task, server restart) can't leave the lock stuck forever. Prevents exactly the
    // scenario the user flagged: scheduling the same scope twice (e.g. clicking "Run All Setup"
    // again while the first run is still going) would otherwise let two TaskScheduler sessions
    // invoke overlapping dispatcher chains against the same tables at once - real deadlock risk,
    // not just wasted work.
    Access = Internal;
    Permissions =
        tabledata "DXR MCC Migration Lock" = RIMD,
        tabledata Company = R;

    internal procedure TryAcquireLock(RequestingCompany: Text; LockedBy: Code[50]; LockDuration: Duration; RunRequestEntryNo: Integer): Boolean
    var
        MigrationLock: Record "DXR MCC Migration Lock";
    begin
        PrepareCoordinatorLockRecord(MigrationLock);
        MigrationLock.LockTable();

        if MigrationLock.Get(GlobalLockRowKey(), GetGlobalMigrationLockCode()) then begin
            if MigrationLock."Expires At" > CurrentDateTime() then
                exit(false);

            MigrationLock."Locked By" := LockedBy;
            MigrationLock."Locked For Company" := CopyStr(NormalizeCompanyName(RequestingCompany), 1, MaxStrLen(MigrationLock."Locked For Company"));
            MigrationLock."Locked At" := CurrentDateTime();
            MigrationLock."Expires At" := CurrentDateTime() + LockDuration;
            MigrationLock."Run Request Entry No." := RunRequestEntryNo;
            MigrationLock.Modify(false);
            exit(true);
        end;

        MigrationLock.Init();
        MigrationLock."Company Name" := GlobalLockRowKey();
        MigrationLock."Lock Code" := GetGlobalMigrationLockCode();
        MigrationLock."Locked By" := LockedBy;
        MigrationLock."Locked For Company" := CopyStr(NormalizeCompanyName(RequestingCompany), 1, MaxStrLen(MigrationLock."Locked For Company"));
        MigrationLock."Locked At" := CurrentDateTime();
        MigrationLock."Expires At" := CurrentDateTime() + LockDuration;
        MigrationLock."Run Request Entry No." := RunRequestEntryNo;
        MigrationLock.Insert(false);

        exit(true);
    end;

    internal procedure ReleaseLock(RequestingCompany: Text; LockedBy: Code[50])
    var
        MigrationLock: Record "DXR MCC Migration Lock";
    begin
        PrepareCoordinatorLockRecord(MigrationLock);

        if not MigrationLock.Get(GlobalLockRowKey(), GetGlobalMigrationLockCode()) then
            exit;

        if MigrationLock."Locked By" <> LockedBy then
            exit;

        if MigrationLock."Locked For Company" <> CopyStr(NormalizeCompanyName(RequestingCompany), 1, MaxStrLen(MigrationLock."Locked For Company")) then
            exit;

        MigrationLock.Delete(false);
    end;

    /// <summary>Force-releases the lock regardless of owner - used by the Cancel action and by a Run Request that failed/was cancelled, so a dead lock never blocks the next run forever even before Expires At.</summary>
    internal procedure ForceReleaseLockForRunRequest(RunRequestEntryNo: Integer)
    var
        MigrationLock: Record "DXR MCC Migration Lock";
    begin
        PrepareCoordinatorLockRecord(MigrationLock);

        if not MigrationLock.Get(GlobalLockRowKey(), GetGlobalMigrationLockCode()) then
            exit;

        if MigrationLock."Run Request Entry No." <> RunRequestEntryNo then
            exit;

        MigrationLock.Delete(false);
    end;

    /// <summary>Keeps the global mutex alive while its owning Run Request is still producing heartbeats.</summary>
    internal procedure RenewLockForRunRequest(RunRequestEntryNo: Integer; LockDuration: Duration): Boolean
    var
        MigrationLock: Record "DXR MCC Migration Lock";
    begin
        PrepareCoordinatorLockRecord(MigrationLock);
        MigrationLock.LockTable();

        if not MigrationLock.Get(GlobalLockRowKey(), GetGlobalMigrationLockCode()) then
            exit(false);
        if MigrationLock."Run Request Entry No." <> RunRequestEntryNo then
            exit(false);

        MigrationLock."Expires At" := CurrentDateTime() + LockDuration;
        MigrationLock.Modify(false);
        exit(true);
    end;

    internal procedure GetActiveMigrationLock(var LockedForCompany: Text; var LockedBy: Code[50]; var LockedAt: DateTime; var ExpiresAt: DateTime): Boolean
    var
        MigrationLock: Record "DXR MCC Migration Lock";
    begin
        PrepareCoordinatorLockRecord(MigrationLock);
        if not MigrationLock.Get(GlobalLockRowKey(), GetGlobalMigrationLockCode()) then
            exit(false);

        if MigrationLock."Expires At" <= CurrentDateTime() then
            exit(false);

        LockedForCompany := MigrationLock."Locked For Company";
        LockedBy := MigrationLock."Locked By";
        LockedAt := MigrationLock."Locked At";
        ExpiresAt := MigrationLock."Expires At";
        exit(true);
    end;

    local procedure GetGlobalMigrationLockCode(): Code[50]
    begin
        exit('DXR-MCC-MIGRATION-GLOBAL.');
    end;

    local procedure GetCoordinatorCompany(): Text
    var
        Company: Record Company;
    begin
        Company.SetCurrentKey(Name);
        if Company.FindFirst() then
            exit(Company.Name);

        exit(CompanyName());
    end;

    local procedure GlobalLockRowKey(): Code[30]
    begin
        exit('$GLOBAL$');
    end;

    local procedure PrepareCoordinatorLockRecord(var MigrationLock: Record "DXR MCC Migration Lock")
    var
        CoordinatorCompany: Text;
    begin
        CoordinatorCompany := GetCoordinatorCompany();
        MigrationLock.Reset();

        if CoordinatorCompany <> CompanyName() then
            MigrationLock.ChangeCompany(CoordinatorCompany);
    end;

    local procedure NormalizeCompanyName(CompanyNameToLock: Text): Text
    begin
        if CompanyNameToLock = '' then
            exit(CompanyName());

        exit(CompanyNameToLock);
    end;
}
