codeunit 60457 "DXR MCC Fix Customer Fiscal"
{
    // One-time repair for Customer fiscal fields left incomplete by earlier migration passes
    // (found 2026-08-31 while reviewing migrated data): some rows show "Uses NCF" inactive with
    // "NCF Type" blank at the same time, which "DXR MCC Master Customer".ApplyDRLOC() no longer
    // re-copies because a boolean already carrying an explicit false does not look "blank" once
    // "NCF Type" is checked on its own. This codeunit re-applies the same Dx*/DXR* staging fields
    // (source of truth confirmed with the business) whenever that specific inconsistent combo is
    // found, and separately backfills "Tipo Identificacion_DXR" and "VAT Registration No." when
    // still blank. "VAT Registration No." has no Dx* shadow field on Customer (verified via repo-
    // wide grep) - rows still blank after this run are only reported, not auto-fixed, since there is
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
        exit('DXR-MCC-FIX-CUSTOMER-FISCAL-GAPS-20260831');
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
            (not Customer."Utiliza NCF_DXR" and (Customer."Tipo NCF_DXR" = Blank."Tipo NCF_DXR")) or
            (Customer."Tipo Identificacion_DXR" = Blank."Tipo Identificacion_DXR"));
    end;

    local procedure RepairRow(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if not Customer."Utiliza NCF_DXR" and (Customer."Tipo NCF_DXR" = Blank."Tipo NCF_DXR") then
            if (Customer."DxUtiliza NCF" <> Customer."Utiliza NCF_DXR") or
               (Customer."DxTipo NCF" <> Customer."Tipo NCF_DXR")
            then begin
                Customer."Utiliza NCF_DXR" := Customer."DxUtiliza NCF";
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
