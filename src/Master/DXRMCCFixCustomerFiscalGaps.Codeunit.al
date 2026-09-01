codeunit 60457 "DXR MCC Fix Customer Fiscal"
{
    // One-time repair for Customer fiscal fields left incomplete by earlier migration passes.
    // Two gap patterns found in migrated data, both fixed by re-copying "NCF Type"
    // ("Tipo NCF_DXR", 51812) from its legacy shadow field "DxTipo NCF" (54100 - business-
    // confirmed source of truth, holds real values e.g. "ECF31"):
    // (found 2026-08-31) "Uses NCF" inactive with "NCF Type" blank at the same time, which
    // "DXR MCC Master Customer".ApplyDRLOC() no longer re-copies because a boolean already
    // carrying an explicit false does not look "blank" once "NCF Type" is checked on its own.
    // (found 2026-09-01) "Uses NCF" correctly active (true) but "NCF Type" still blank - same
    // underlying gap, just with Uses NCF already set correctly by an earlier pass, so the fix is
    // now unconditional on Uses NCF's value: any blank "Tipo NCF_DXR" with a non-blank "DxTipo
    // NCF" gets repaired regardless of "Utiliza NCF_DXR".
    // Also separately backfills "Tipo Identificacion_DXR" and "VAT Registration No." when still
    // blank. "VAT Registration No." has no Dx* shadow field on Customer (verified via repo-wide
    // grep) - rows still blank after this run are only reported, not auto-fixed, since there is
    // no confirmed source to pull from.
    Permissions = tabledata Customer = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(FixTag()) then
            exit;
        RepairCustomers();
        UpgradeTag.SetUpgradeTag(FixTag());
    end;

    local procedure FixTag(): Code[250]
    begin
        exit('DXR-MCC-FIX-CUSTOMER-FISCAL-GAPS-20260901');
    end;

    local procedure RepairCustomers()
    var
        Customer: Record Customer;
        CustomerToUpdate: Record Customer;
        RowsSinceCommit: Integer;
        UnresolvedVATRegNo: Integer;
    begin
        Customer.SetLoadFields(
            "No.", "Tipo NCF_DXR", "DxTipo NCF", "Utiliza NCF_DXR", "DxUtiliza NCF",
            "Tipo Identificacion_DXR", "DXTipo Identificacion", "VAT Registration No.");
        if not Customer.FindSet(false) then
            exit;
        repeat
            if RowNeedsRepair(Customer) then
                if CustomerToUpdate.Get(Customer."No.") then
                    if RepairRow(CustomerToUpdate) then begin
                        CustomerToUpdate.Modify(false);
                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
            if Customer."VAT Registration No." = '' then
                UnresolvedVATRegNo += 1;
        until Customer.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();

        if UnresolvedVATRegNo > 0 then
            Message(
                'Fiscal data repair complete. %1 customer(s) still have a blank VAT Registration No. and were not changed - no Dx* staging value exists on Customer to source it from; these need a manual or per-adapter follow-up.',
                UnresolvedVATRegNo);
    end;

    local procedure RowNeedsRepair(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
    begin
        exit(
            (not Customer."Utiliza NCF_DXR" and (Customer."DxUtiliza NCF" <> Customer."Utiliza NCF_DXR")) or
            ((Customer."Tipo NCF_DXR" = Blank."Tipo NCF_DXR") and (Customer."DxTipo NCF" <> Blank."Tipo NCF_DXR")) or
            (Customer."Tipo Identificacion_DXR" = Blank."Tipo Identificacion_DXR"));
    end;

    local procedure RepairRow(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if not Customer."Utiliza NCF_DXR" and (Customer."DxUtiliza NCF" <> Customer."Utiliza NCF_DXR") then begin
            Customer."Utiliza NCF_DXR" := Customer."DxUtiliza NCF";
            Changed := true;
        end;

        // Unconditional on "Utiliza NCF_DXR"'s value - covers both the Uses NCF=false gap above
        // and the Uses NCF=true-but-NCF-Type-still-blank gap found 2026-09-01.
        if (Customer."Tipo NCF_DXR" = Blank."Tipo NCF_DXR") and (Customer."DxTipo NCF" <> Blank."Tipo NCF_DXR") then begin
            Customer."Tipo NCF_DXR" := Customer."DxTipo NCF";
            Changed := true;
        end;

        if Customer."Tipo Identificacion_DXR" = Blank."Tipo Identificacion_DXR" then
            if Customer."DXTipo Identificacion" <> Customer."Tipo Identificacion_DXR" then begin
                Customer."Tipo Identificacion_DXR" := Customer."DXTipo Identificacion";
                Changed := true;
            end;

        exit(Changed);
    end;
}
