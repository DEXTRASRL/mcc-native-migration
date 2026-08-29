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

    // Fixed 2026-08-27 (A1): both loops used FindSet(true), i.e. an UPDLOCK on every posted sales
    // invoice matching the filter held for the whole run, even though the e33/debit-note rows are
    // skipped untouched; and with no SetLoadFields every "Sales Invoice Header" tableextension
    // companion table in this portfolio was joined in per row. Now: SetLoadFields (the 6 fields these
    // loops read/write; the filtered field is loaded anyway) + FindSet(false) (no UPDLOCK), the row is
    // re-read with Get() and locked only when it really has to be cleared, and the commit counter
    // advances per MODIFIED row instead of per scanned row. Same filters, same skip condition, same
    // fields cleared, same order.
    local procedure ClearInvalidNCFAffectedValues()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BatchCount: Integer;
    begin
        SalesInvoiceHeader.SetLoadFields(
            "No.", "NCF_DXR Afectado_DXR", "DXNCF Afectado", NCF_DXR, DXNCF, "Is Debit Note_DXR", "DX Is Debit Note");
        SalesInvoiceHeader.SetFilter("NCF_DXR Afectado_DXR", '<>%1', '');
        if SalesInvoiceHeader.FindSet(false) then
            repeat
                if ClearInvalidNCFAffectedValue(SalesInvoiceHeader) then begin
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until SalesInvoiceHeader.Next() = 0;
        if BatchCount > 0 then
            Commit();

        BatchCount := 0;
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetLoadFields(
            "No.", "NCF_DXR Afectado_DXR", "DXNCF Afectado", NCF_DXR, DXNCF, "Is Debit Note_DXR", "DX Is Debit Note");
        SalesInvoiceHeader.SetFilter("DXNCF Afectado", '<>%1', '');
        if SalesInvoiceHeader.FindSet(false) then
            repeat
                if ClearInvalidNCFAffectedValue(SalesInvoiceHeader) then begin
                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until SalesInvoiceHeader.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    /// <summary>
    /// Returns true when the row was actually cleared and modified, so the caller's commit counter
    /// advances per modified row.
    /// </summary>
    local procedure ClearInvalidNCFAffectedValue(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        SalesInvoiceHeaderToUpdate: Record "Sales Invoice Header";
    begin
        if IsE33OrDebitNote(SalesInvoiceHeader) then
            exit(false);

        if not SalesInvoiceHeaderToUpdate.Get(SalesInvoiceHeader."No.") then
            exit(false);

        Clear(SalesInvoiceHeaderToUpdate."NCF_DXR Afectado_DXR");
        Clear(SalesInvoiceHeaderToUpdate."DXNCF Afectado");
        SalesInvoiceHeaderToUpdate.Modify(false);
        exit(true);
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
