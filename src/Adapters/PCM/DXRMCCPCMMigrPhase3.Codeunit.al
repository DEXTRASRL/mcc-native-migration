#if not ESCUDEA and not BCDX
codeunit 60123 "DXR MCC PCM Migr Phase3"
{
    // Native local migration - ported verbatim from Price Controls Mgt.'s own
    // "DXR_Migr. Phase 3 Approval".Run() - see "DXR MCC PCM Migr Phase2" for the full rationale.
    Permissions =
        tabledata "Approval Entry" = RM,
        tabledata Workflow = RM;

    trigger OnRun()
    begin
        RunSetup();
        RunOther();
    end;

    procedure RunSetup()
    begin
        MigrateWorkflowFields();
    end;

    procedure RunOther()
    begin
        MigrateApprovalEntryFields();
    end;

    local procedure MigrateApprovalEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        ApprovalEntry: Record "Approval Entry";
        Modified: Boolean;
        AttemptNo: Integer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(ApprovalEntryFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields (only the 6 fields this loop reads/writes; the primary
        // key is always loaded) so the server stops joining every Approval Entry tableextension
        // companion table per row, and added a bounded Commit - this loop over a potentially large
        // entry table previously ran entirely inside one unbounded transaction.
        ApprovalEntry.SetLoadFields(
            "Workflow Code", "Workflow Code_DXR",
            "Workflow Instance ID", "Workflow Instance ID_DXR",
            "Posting Date", "Posting Date_DXR");
        ApprovalEntry.SetFilter("Workflow Code", '<>%1', '');
        if ApprovalEntry.FindSet() then begin
            repeat
                Modified := false;

                if ApprovalEntry."Workflow Code_DXR" = '' then begin
                    ApprovalEntry."Workflow Code_DXR" := ApprovalEntry."Workflow Code";
                    Modified := true;
                end;

                if IsNullGuid(ApprovalEntry."Workflow Instance ID_DXR") and not IsNullGuid(ApprovalEntry."Workflow Instance ID") then begin
                    ApprovalEntry."Workflow Instance ID_DXR" := ApprovalEntry."Workflow Instance ID";
                    Modified := true;
                end;

                if (ApprovalEntry."Posting Date_DXR" = 0D) and (ApprovalEntry."Posting Date" <> 0D) then begin
                    ApprovalEntry."Posting Date_DXR" := ApprovalEntry."Posting Date";
                    Modified := true;
                end;

                if Modified then begin
                    AttemptNo := 0;
                    while not TryModifyApprovalEntry(ApprovalEntry) do begin
                        AttemptNo += 1;
                        if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                            Error(GetLastErrorText());
                    end;

                    // Only reached once the retry-on-lock loop above has fully resolved, never
                    // mid-retry; counter advances per MODIFIED row.
                    RowCounter += 1;
                    if RowCounter >= BatchSize() then begin
                        Commit();
                        RowCounter := 0;
                    end;
                end;
            until ApprovalEntry.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(ApprovalEntryFieldsMigratedTag());
    end;

    [TryFunction]
    local procedure TryModifyApprovalEntry(var ApprovalEntry: Record "Approval Entry")
    begin
        ApprovalEntry.Modify(false);
    end;

    local procedure MigrateWorkflowFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        Workflow: Record Workflow;
        AttemptNo: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(WorkflowFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields (only the 2 fields this loop reads/writes; the primary
        // key is always loaded) so the server stops joining every Workflow tableextension companion
        // table per row.
        Workflow.SetLoadFields("PRC Approval Type_DXR", "DXR_Approval Type");
        if Workflow.FindSet() then
            repeat
                if (Workflow."PRC Approval Type_DXR" = Workflow."PRC Approval Type_DXR"::All) and
                   (Workflow."DXR_Approval Type" <> Workflow."DXR_Approval Type"::All)
                then begin
                    Workflow."PRC Approval Type_DXR" := Workflow."DXR_Approval Type";
                    AttemptNo := 0;
                    while not TryModifyWorkflow(Workflow) do begin
                        AttemptNo += 1;
                        if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                            Error(GetLastErrorText());
                    end;
                end;
            until Workflow.Next() = 0;

        UpgradeTag.SetUpgradeTag(WorkflowFieldsMigratedTag());
    end;

    [TryFunction]
    local procedure TryModifyWorkflow(var Workflow: Record Workflow)
    begin
        Workflow.Modify(false);
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure ApprovalEntryFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-ApprovalEntryFieldsMigrated-28.3.0.0');
    end;

    local procedure WorkflowFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-WorkflowFieldsMigrated-28.3.0.0');
    end;
}

#endif
