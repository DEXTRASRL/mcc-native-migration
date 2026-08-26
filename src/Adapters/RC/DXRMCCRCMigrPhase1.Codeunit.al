#if not ESCUDEA and not BCDX
codeunit 60131 "DXR MCC RC Migr Phase1"
{
    // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase1 Setup
    // Retro" (54734/54735, Access = Internal). The real source has no per-step Upgrade Tag of its
    // own - idempotency there comes purely from the sibling's Dispatcher's OUTER per-phase tag
    // (RunPhaseIfNeeded). Ported here with that same outer tag, reused verbatim from the sibling's
    // "DXR_Internal Migr Phase Tags" codeunit (also Access = Internal, so the literal string is
    // hardcoded rather than called).
    Permissions =
        tabledata "DXR LYT Controls Setup" = R,
        tabledata "DXR_LYT Controls Setup" = RIM,
        tabledata "DXR Pos Controls Setup" = R,
        tabledata "DXR_Pos Controls Setup" = RIM,
        tabledata "DXR_Purchase Controls Setup" = RIM,
        tabledata "DXR_Sales Controls Setup" = RIM,
        tabledata "LSC POS Func. Profile" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817') then
            exit;

        RunSetup();
        RunOther();

        UpgradeTag.SetUpgradeTag('DXR-RC-PHASE1-SETUP-RETROACTIVE-20260817');
    end;

    procedure RunSetup()
    begin
        CopyLYTControlsSetup();
        CopyPosControlsSetup();
        CopyPurchaseControlsSetupFields();
        CopySalesControlsSetupFields();
    end;

    procedure RunOther()
    begin
        CopyLSCPOSFuncProfileFields();
    end;

    local procedure CopyLYTControlsSetup()
    var
        OldSetup: Record "DXR LYT Controls Setup";
        NewSetup: Record "DXR_LYT Controls Setup";
    begin
        if not OldSetup.FindSet() then
            exit;
        repeat
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

    local procedure CopyPosControlsSetup()
    var
        OldSetup: Record "DXR Pos Controls Setup";
        NewSetup: Record "DXR_Pos Controls Setup";
    begin
        if not OldSetup.FindSet() then
            exit;
        repeat
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
            // "Restrict Zero Price Items" didn't exist on the legacy table (added later): keep
            // whatever value is already present on the new row.
            NewSetup.Modify();
        until OldSetup.Next() = 0;
    end;

    local procedure CopyPurchaseControlsSetupFields()
    var
        Setup: Record "DXR_Purchase Controls Setup";
    begin
        if not Setup.FindSet(true) then
            exit;
        repeat
            Setup."BarCode Length_DXR" := Setup."BarCode Length_DXR_Old";
            Setup.Modify();
        until Setup.Next() = 0;
    end;

    local procedure CopySalesControlsSetupFields()
    var
        Setup: Record "DXR_Sales Controls Setup";
    begin
        if not Setup.FindSet(true) then
            exit;
        repeat
            Setup."Special POS Order_DXR" := Setup."Special POS Order_DXR_Old";
            Setup."Non Decimal Qty on Lines_DXR" := Setup."Non Decimal Qty on Lines_old";
            Setup."Mand Return Reason Code_DXR" := Setup."Mand Return Reason Code_Old";
            Setup.Modify();
        until Setup.Next() = 0;
    end;

    local procedure CopyLSCPOSFuncProfileFields()
    var
        FuncProfile: Record "LSC POS Func. Profile";
    begin
        if not FuncProfile.FindSet(true) then
            exit;
        repeat
            FuncProfile."TS POS Special Order_DXR" := FuncProfile."TS POS Special Order";
            FuncProfile."PSO Distribution Location_DXR" := FuncProfile."PSO Distribution Location";
            FuncProfile.Modify();
        until FuncProfile.Next() = 0;
    end;
}

#endif
