/*
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
        tabledata "DXR_Internal Migr Status Old2" = R,
        tabledata "DXR_Internal Migr Status" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820') then
            exit;

        RunSetup();
        RunHistoric();

        UpgradeTag.SetUpgradeTag('DXR-RC-PHASE5-TABLEIDCOLLISION-RETROACTIVE-20260820');
    end;

    procedure RunSetup()
    begin
        CopyLYTControlsSetup();
        CopyPosControlsSetup();
    end;

    procedure RunHistoric()
    begin
        CopyInternalMigrStatus();
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

    // "DXR_Internal Migr Status Old2" (56543) is Access = Internal on RC's side; RC grants MCC
    // internalsVisibleTo, so it's referenced here as a typed Record like every other Access =
    // Internal table elsewhere in this codeunit/campaign. Both tables' Status field are the SAME
    // Option definition (OptionMembers "Pending,In Progress,Completed,Failed", identical order on
    // both sides - verified against RC's own DXRInternalMigrStatusOld2.Table.al /
    // DXRInternalMigrStatus.Table.al), so a direct typed assignment is value-safe (no FromInteger()/
    // AsInteger() conversion needed - that pattern is only required when the two sides use distinct
    // Enum objects, which is not the case here). No blank-row guard in the real source for this
    // table (unlike the two Setup tables above) - preserved as unconditional, matching source.
    local procedure CopyInternalMigrStatus()
    var
        OldStatus: Record "DXR_Internal Migr Status Old2";
        NewStatus: Record "DXR_Internal Migr Status";
    begin
        if not OldStatus.FindSet() then
            exit;
        repeat
            if not NewStatus.Get(OldStatus."Company Name", OldStatus."Phase No.") then begin
                NewStatus.Init();
                NewStatus."Company Name" := OldStatus."Company Name";
                NewStatus."Phase No." := OldStatus."Phase No.";
                NewStatus.Insert();
            end;
            NewStatus."Phase Name" := OldStatus."Phase Name";
            NewStatus.Status := OldStatus.Status;
            NewStatus."Started At" := OldStatus."Started At";
            NewStatus."Completed At" := OldStatus."Completed At";
            NewStatus."Error Message" := OldStatus."Error Message";
            NewStatus.Attempts := OldStatus.Attempts;
            NewStatus.Modify();
        until OldStatus.Next() = 0;
    end;
}

*/
