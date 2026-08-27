codeunit 60142 "DXR MCC FE Migr Phase13"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 13 NCF Cleanup".OnRun() (Access = Internal). Clears the legacy NCF
    // Afectado fields on posted Sales Invoice Header rows that are neither e33 (Comprobante de
    // Compra) nor a debit note - all fields are on the standard "Sales Invoice Header" table.
    Permissions =
        tabledata "Sales Invoice Header" = RM;

#pragma warning disable AL0432
    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V7-PHASE7-NCF-AFFECTED-CLEANUP-20260720') then
            exit;

        ClearInvalidNCFAffectedValues();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V7-PHASE7-NCF-AFFECTED-CLEANUP-20260720');
    end;

    local procedure ClearInvalidNCFAffectedValues()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BatchCount: Integer;
    begin
        SalesInvoiceHeader.SetFilter("NCF_DXR Afectado_DXR", '<>%1', '');
        if SalesInvoiceHeader.FindSet(true) then
            repeat
                ClearInvalidNCFAffectedValue(SalesInvoiceHeader);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceHeader.Next() = 0;

        BatchCount := 0;
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("DXNCF Afectado", '<>%1', '');
        if SalesInvoiceHeader.FindSet(true) then
            repeat
                ClearInvalidNCFAffectedValue(SalesInvoiceHeader);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure ClearInvalidNCFAffectedValue(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        if IsE33OrDebitNote(SalesInvoiceHeader) then
            exit;

        Clear(SalesInvoiceHeader."NCF_DXR Afectado_DXR");
        Clear(SalesInvoiceHeader."DXNCF Afectado");
        SalesInvoiceHeader.Modify(false);
    end;

    local procedure IsE33OrDebitNote(SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        EffectiveNCF: Code[20];
    begin
        EffectiveNCF := SalesInvoiceHeader.NCF_DXR;
        if EffectiveNCF = '' then
            EffectiveNCF := SalesInvoiceHeader.DXNCF;

        exit(
            SalesInvoiceHeader."Is Debit Note_DXR" or
            SalesInvoiceHeader."DX Is Debit Note" or
            (CopyStr(EffectiveNCF, 2, 2) = '33') or
            (CopyStr(EffectiveNCF, 2, 2) = '13'));
    end;
#pragma warning restore AL0432
}
