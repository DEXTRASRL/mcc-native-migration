codeunit 60135 "DXR MCC RC Migr Phase5"
{
    // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase5 Setup
    // Tables" (56508/56509, Access = Internal) - see "DXR MCC RC Migr Phase1" for the outer-tag
    // rationale. Repairs an in-place table-ID renumbering (three custom tables: "DXR_LYT Controls
    // Setup" 56529->54726, "DXR_Pos Controls Setup" 56530->54728, "DXR_Internal Migr Status"
    // 56543->54736) by copying row-by-row from a preserved Obsolete clone at the original ID
    // ("...Old2") into the active table - only when the Old2 row actually holds non-default data,
    // so an earlier phase's already-correct write in the same pass isn't overwritten with blanks.
    Permissions =
        tabledata "DXR_LYT Controls Setup Old2" = R,
        tabledata "DXR_LYT Controls Setup" = RIM,
        tabledata "DXR_Pos Controls Setup Old2" = R,
        tabledata "DXR_Pos Controls Setup" = RIM,
        tabledata "DXR_Internal Migr Status" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820') then
            exit;

        CopyLYTControlsSetup();
        CopyPosControlsSetup();
        CopyInternalMigrStatus();

        UpgradeTag.SetUpgradeTag('DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820');
    end;

    local procedure CopyLYTControlsSetup()
    var
        OldSetup: Record "DXR_LYT Controls Setup Old2";
        NewSetup: Record "DXR_LYT Controls Setup";
    begin
        if not OldSetup.FindSet() then
            exit;
        repeat
            if IsLYTOldSetupRowBlank(OldSetup) then
                continue;

            if not NewSetup.Get(OldSetup.Code) then begin
                NewSetup.Init();
                NewSetup.Code := OldSetup.Code;
                NewSetup.Insert();
            end;
            NewSetup.Active := OldSetup.Active;
            NewSetup."LYT Fiscal Closing" := OldSetup."LYT Fiscal Closing";
            NewSetup."LYT Fiscal Closing Date" := OldSetup."LYT Fiscal Closing Date";
            NewSetup."Journal Template Name" := OldSetup."Journal Template Name";
            NewSetup."Journal Batch Name" := OldSetup."Journal Batch Name";
            NewSetup.Modify();
        until OldSetup.Next() = 0;
    end;

    local procedure IsLYTOldSetupRowBlank(var OldSetup: Record "DXR_LYT Controls Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."LYT Fiscal Closing") and
            (OldSetup."LYT Fiscal Closing Date" = 0D) and
            (OldSetup."Journal Template Name" = '') and
            (OldSetup."Journal Batch Name" = ''));
    end;

    local procedure CopyPosControlsSetup()
    var
        OldSetup: Record "DXR_Pos Controls Setup Old2";
        NewSetup: Record "DXR_Pos Controls Setup";
    begin
        if not OldSetup.FindSet() then
            exit;
        repeat
            if IsPosOldSetupRowBlank(OldSetup) then
                continue;

            if not NewSetup.Get(OldSetup."CODE") then begin
                NewSetup.Init();
                NewSetup."CODE" := OldSetup."CODE";
                NewSetup.Insert();
            end;
            NewSetup.Active := OldSetup.Active;
            NewSetup."Restrict Order Modification HO" := OldSetup."Restrict Order Modification HO";
            NewSetup."Restrict Negative Qty" := OldSetup."Restrict Negative Qty";
            NewSetup."Restrict Order Deletion HO" := OldSetup."Restrict Order Deletion HO";
            NewSetup."Restrict Negative Price" := OldSetup."Restrict Negative Price";
            NewSetup."Exempt group" := OldSetup."Exempt group";
            NewSetup."Exempt Product group" := OldSetup."Exempt Product group";
            NewSetup."Require Manager on Exempt" := OldSetup."Require Manager on Exempt";
            NewSetup."Non expired exempt Card" := OldSetup."Non expired exempt Card";
            NewSetup."Restrict Zero Price Items" := OldSetup."Restrict Zero Price Items";
            NewSetup.Modify();
        until OldSetup.Next() = 0;
    end;

    local procedure IsPosOldSetupRowBlank(var OldSetup: Record "DXR_Pos Controls Setup Old2"): Boolean
    begin
        exit(
            (not OldSetup.Active) and
            (not OldSetup."Restrict Order Modification HO") and
            (not OldSetup."Restrict Negative Qty") and
            (not OldSetup."Restrict Order Deletion HO") and
            (not OldSetup."Restrict Negative Price") and
            (OldSetup."Exempt group" = '') and
            (OldSetup."Exempt Product group" = '') and
            (not OldSetup."Require Manager on Exempt") and
            (not OldSetup."Non expired exempt Card") and
            (not OldSetup."Restrict Zero Price Items"));
    end;

    // "DXR_Internal Migr Status Old2" (56543) is Access = Internal on RC's side - accessed here
    // purely via RecordRef by numeric table ID. No blank-row guard in the real source for this
    // table (unlike the two Setup tables above) - preserved as unconditional, matching source.
    local procedure CopyInternalMigrStatus()
    var
        NewStatus: Record "DXR_Internal Migr Status";
        OldRef: RecordRef;
        CompanyNameFld, PhaseNoFld, PhaseNameFld, StatusFld, StartedAtFld, CompletedAtFld, ErrorMessageFld, AttemptsFld : FieldRef;
    begin
        OldRef.Open(56543);
        if OldRef.FindSet() then
            repeat
                CompanyNameFld := OldRef.Field(1);
                PhaseNoFld := OldRef.Field(2);
                PhaseNameFld := OldRef.Field(3);
                StatusFld := OldRef.Field(4);
                StartedAtFld := OldRef.Field(5);
                CompletedAtFld := OldRef.Field(6);
                ErrorMessageFld := OldRef.Field(7);
                AttemptsFld := OldRef.Field(8);

                if not NewStatus.Get(CompanyNameFld.Value(), PhaseNoFld.Value()) then begin
                    NewStatus.Init();
                    NewStatus."Company Name" := CompanyNameFld.Value();
                    NewStatus."Phase No." := PhaseNoFld.Value();
                    NewStatus.Insert();
                end;
                NewStatus."Phase Name" := PhaseNameFld.Value();
                NewStatus.Status := StatusFld.Value();
                NewStatus."Started At" := StartedAtFld.Value();
                NewStatus."Completed At" := CompletedAtFld.Value();
                NewStatus."Error Message" := ErrorMessageFld.Value();
                NewStatus.Attempts := AttemptsFld.Value();
                NewStatus.Modify();
            until OldRef.Next() = 0;
        OldRef.Close();
    end;
}
