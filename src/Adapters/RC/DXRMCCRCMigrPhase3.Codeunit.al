#if not ESCUDEA and not BCDX
codeunit 60133 "DXR MCC RC Migr Phase3"
{
    // Native local migration - ported verbatim from Retail Controls' own "DXR_Migr Phase3 ID
    // Collision" (56502/56503, Access = Internal) - see "DXR MCC RC Migr Phase1" for the outer-tag
    // rationale. Fixes a cross-table field-ID collision: the "_DXR" fields added in Phase1/Phase2
    // originally reused IDs 54675-54677 across 6 tableextensions in this repo; the active field
    // now lives at a collision-free ID (56531-56538), and the pre-collision-fix ID was preserved
    // (duplicated+Obsolete, renamed "..._Old"/"..._DXR_Old") so this phase can copy real data left
    // there by an older, collision-affected deploy - but ONLY when that old field is non-blank
    // (Phase1/Phase2 already write the true value straight into the current field in the very same
    // dispatcher pass; an unconditional copy here would wipe that out for a first-time deploy where
    // the old-ID field is simply untouched/default).
    Permissions =
        tabledata "Sales Header" = RIM,
        tabledata "Purchase Header" = RIM,
        tabledata "Sales Invoice Header" = RIM,
        tabledata "LSC POS Func. Profile" = RIM,
        tabledata "DXR_Sales Controls Setup" = RIM,
        tabledata "DXR_Purchase Controls Setup" = RIM;

    var
        BatchSize: Integer;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-RC-PHASE3-IDCOLLISION-RETROACTIVE-20260820') then
            exit;

        BatchSize := 500;
        CopySalesHeaderField();
        CopySalesInvoiceHeaderField();
        CopyPurchaseHeaderField();
        CopyLSCPOSFuncProfileFields();
        CopySalesControlsSetupFields();
        CopyPurchaseControlsSetupFields();

        UpgradeTag.SetUpgradeTag('DXR-RC-PHASE3-IDCOLLISION-RETROACTIVE-20260820');
    end;

    local procedure CopySalesHeaderField()
    var
        SalesHeader: Record "Sales Header";
        Processed: Integer;
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1). "Sales Header" carries many tableextensions
        // across this portfolio; without a partial-record hint every companion table was joined per
        // row. Only these two fields are read/written here.
        SalesHeader.SetLoadFields("POS Special Order_DXR", "POS Special Order_DXR_Old");
        if not SalesHeader.FindSet(true) then
            exit;
        repeat
            if SalesHeader."POS Special Order_DXR_Old" then
                SalesHeader."POS Special Order_DXR" := SalesHeader."POS Special Order_DXR_Old";
            SalesHeader.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until SalesHeader.Next() = 0;
        // Fixed 2026-08-27: commit the trailing partial batch (A4) - previously the last <500 rows
        // stayed inside the caller's transaction.
        if Processed mod BatchSize <> 0 then
            Commit();
    end;

    local procedure CopySalesInvoiceHeaderField()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        Processed: Integer;
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1) - see CopySalesHeaderField above; only these
        // two fields are read/written here.
        SalesInvHeader.SetLoadFields("POS Special Order_DXR", "POS Special Order_DXR_Old");
        if not SalesInvHeader.FindSet(true) then
            exit;
        repeat
            if SalesInvHeader."POS Special Order_DXR_Old" then
                SalesInvHeader."POS Special Order_DXR" := SalesInvHeader."POS Special Order_DXR_Old";
            SalesInvHeader.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until SalesInvHeader.Next() = 0;
        // Fixed 2026-08-27: commit the trailing partial batch (A4).
        if Processed mod BatchSize <> 0 then
            Commit();
    end;

    local procedure CopyPurchaseHeaderField()
    var
        PurchHeader: Record "Purchase Header";
        Processed: Integer;
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1) - see CopySalesHeaderField above; only these
        // two fields are read/written here.
        PurchHeader.SetLoadFields(Toggle_DXR, Toggle_DXR_Old);
        if not PurchHeader.FindSet(true) then
            exit;
        repeat
            if PurchHeader.Toggle_DXR_Old then
                PurchHeader.Toggle_DXR := PurchHeader.Toggle_DXR_Old;
            PurchHeader.Modify();
            Processed += 1;
            if Processed mod BatchSize = 0 then
                Commit();
        until PurchHeader.Next() = 0;
        // Fixed 2026-08-27: commit the trailing partial batch (A4).
        if Processed mod BatchSize <> 0 then
            Commit();
    end;

    // No Commit() batching: "LSC POS Func. Profile" is a small master/setup table (a handful of
    // functional POS profiles per environment, not a per-transaction table), matching the real
    // source's own pattern - unlike the 3 document-header procedures above, which iterate
    // transactional tables that can hold thousands of rows.
    local procedure CopyLSCPOSFuncProfileFields()
    var
        FuncProfile: Record "LSC POS Func. Profile";
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1) - "LSC POS Func. Profile" is a wide LS Central
        // table carrying several tableextensions; only these four fields are read/written here.
        FuncProfile.SetLoadFields(
            "TS POS Special Order_DXR", "TS POS Special Order_DXR_Old",
            "PSO Distribution Location_DXR", "PSO Distribution Location_Old");
        if not FuncProfile.FindSet(true) then
            exit;
        repeat
            if FuncProfile."TS POS Special Order_DXR_Old" then
                FuncProfile."TS POS Special Order_DXR" := FuncProfile."TS POS Special Order_DXR_Old";
            if FuncProfile."PSO Distribution Location_Old" <> '' then
                FuncProfile."PSO Distribution Location_DXR" := FuncProfile."PSO Distribution Location_Old";
            FuncProfile.Modify();
        until FuncProfile.Next() = 0;
    end;

    // No Commit() batching: "DXR_Sales Controls Setup" is a singleton setup table (accessed
    // elsewhere in RC via Setup.Get() with no key), so it holds at most a handful of rows.
    local procedure CopySalesControlsSetupFields()
    var
        Setup: Record "DXR_Sales Controls Setup";
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1) - only these six fields are read/written.
        Setup.SetLoadFields(
            "Special POS Order_DXR", "Special POS Order_DXR_Old",
            "Non Decimal Qty on Lines_DXR", "Non Decimal Qty on Lines_Old",
            "Mand Return Reason Code_DXR", "Mand Return Reason Code_Old");
        if not Setup.FindSet(true) then
            exit;
        repeat
            if Setup."Special POS Order_DXR_Old" then
                Setup."Special POS Order_DXR" := Setup."Special POS Order_DXR_Old";
            if Setup."Non Decimal Qty on Lines_Old" then
                Setup."Non Decimal Qty on Lines_DXR" := Setup."Non Decimal Qty on Lines_Old";
            if Setup."Mand Return Reason Code_Old" then
                Setup."Mand Return Reason Code_DXR" := Setup."Mand Return Reason Code_Old";
            Setup.Modify();
        until Setup.Next() = 0;
    end;

    // No Commit() batching: "DXR_Purchase Controls Setup" is a singleton setup table, same as
    // "DXR_Sales Controls Setup" above.
    local procedure CopyPurchaseControlsSetupFields()
    var
        Setup: Record "DXR_Purchase Controls Setup";
    begin
        // Fixed 2026-08-27: added SetLoadFields (A1) - only these two fields are read/written.
        Setup.SetLoadFields("BarCode Length_DXR", "BarCode Length_DXR_Old");
        if not Setup.FindSet(true) then
            exit;
        repeat
            if Setup."BarCode Length_DXR_Old" <> 0 then
                Setup."BarCode Length_DXR" := Setup."BarCode Length_DXR_Old";
            Setup.Modify();
        until Setup.Next() = 0;
    end;
}

#endif
