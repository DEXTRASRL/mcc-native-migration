codeunit 60143 "DXR MCC FE Migr Untrk Repairs"
{
    // Native local migration - ported verbatim from steps the sibling's own "DXR_Migr. Dispatcher"
    // (52537/39003254, RunAllPendingPhases) runs BETWEEN Phase 10 and Phase 11, each with its own
    // tag, "always evaluated" (not gated on any FE-Pn phase tag) - and which have NO corresponding
    // MCC registry row at all (no old delegation adapter pointed at them either; they only ever ran
    // as an undocumented side effect of the old FE-P7..P13 adapters' Codeunit.Run() chain reaching
    // the shared Dispatcher). Bundled into this one dedicated codeunit rather than folded into an
    // existing Phase codeunit, since none of the 57 tracked FE-Pn registry rows correspond to this
    // work - same category of gap as Despacho Base's untracked Phase 1 (see commit 1d3db2e), just
    // with no natural existing concept group to attach to here.
    //
    // Ported here:
    //   1. EnsurePermissionSetsAssignedToAllUsersIfNeeded() - assigns 'DXR_Permissions' to all
    //      users (fixed app ID, see below).
    //   2. EFUpgradeCode.RunLegacyEFUpgrades() (codeunit "DXR_Upgrade Code", Access = Internal) -
    //      5 sub-steps, each independently tag-gated, all reachable via typed/RecordRef access to
    //      public tables (DXR_Form Type/Formas de Pago/Paginacion/SubTotales Informativos/Log
    //      Message, Sales/Purchase Invoice/CrMemo headers).
    //
    // Deliberately NOT ported: EnsureLegacyRejectionRepairIfNeeded() (calls
    // "DXR_EF Legacy Reject Bg Rnner".RepairStaleValidationRejections(), which itself calls
    // "DXR_Soap Document" - both Access = Internal, and unlike every other Access = Internal
    // object touched in this portfolio-wide conversion, this one cannot be reached via RecordRef:
    // it needs specific NAMED PROCEDURES (SOAP/XML ATEB-response classification logic -
    // IsATEBDuplicateResponseDocument/IsATEBAmbiguousExceptionResponseDocument/
    // IsDefiniteValidationRejectionResponse), not table/field access, and FE's app.json does not
    // grant MCC internalsVisibleTo. Reimplementing that Dominican e-NCF/ATEB validation-rejection
    // classification logic natively in MCC would risk silently getting real tax-compliance rules
    // wrong; the safer call was to leave this one repair step out of scope rather than guess.
    // Impact if skipped: NCF Send Reservations that were incorrectly left "Blocks Send" by a since-
    // fixed 2026-08-22 bug (see the sibling codeunit's own header comment) stay blocked until FE's
    // own background Dispatcher (or a future MCC pass with internalsVisibleTo granted) repairs
    // them - a functional inconvenience, not a data-loss or data-corruption risk, and the sibling
    // repair procedure is documented as naturally idempotent, so running it later is always safe.
    Permissions =
        tabledata User = R,
        tabledata "Access Control" = RIM,
        tabledata "DXR_Form Type" = RIM,
        tabledata "DXR_Formas de Pago" = R,
        tabledata "DXR_Paginacion" = RIMD,
        tabledata "DXR_SubTotales Informativos" = RIMD,
        tabledata "DXR_Log Message" = RIMD,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Cr. Memo Hdr." = RM;

    trigger OnRun()
    begin
        EnsurePermissionSetsAssignedToAllUsersIfNeeded();
        RunLegacyEFUpgrades();
    end;

    local procedure EnsurePermissionSetsAssignedToAllUsersIfNeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-ASSIGN-PERMISSIONSETS-ALL-USERS-20260807') then
            exit;

        AssignPermissionSetsToAllUsers();

        UpgradeTag.SetUpgradeTag('DXR-EF-ASSIGN-PERMISSIONSETS-ALL-USERS-20260807');
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded Facturacion Electronica's real app ID (from its own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        if not UserRec.FindSet() then
            exit;
        repeat
            AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_Permissions', FEAppId());
        until UserRec.Next() = 0;
    end;

    local procedure AssignPermissionSetToUser(UserSecurityId: Guid; PermissionSetId: Code[20]; AppId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", PermissionSetId);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetRange("App ID", AppId);
        AccessControl.SetRange("Company Name", CompanyName());
        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := PermissionSetId;
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := AppId;
        AccessControl."Company Name" := CompanyName();
        AccessControl.Insert(true);
    end;

    local procedure FEAppId(): Guid
    begin
        exit('4ccf94f0-8e86-437f-99fc-a4eeda4a5122');
    end;

    local procedure RunLegacyEFUpgrades()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // Both steps below are effective no-ops in the current source (their loop bodies are
        // entirely commented out except for the FindSet/Next scaffolding) - preserved as literal
        // no-ops here, matching the CURRENT observable behavior exactly, so the tags still get set
        // (a future real implementation on FE's side would need a fresh tag anyway).
        if not UpgradeTag.HasUpgradeTag('DX-Historical606_Upgrade-06-12-2024-2-1') then
            UpgradeTag.SetUpgradeTag('DX-Historical606_Upgrade-06-12-2024-2-1');

        if not UpgradeTag.HasUpgradeTag('DX-CheckQrBarCodeValue_Upgrade-24-06-2024-3-2') then
            UpgradeTag.SetUpgradeTag('DX-CheckQrBarCodeValue_Upgrade-24-06-2024-3-2');

        if not UpgradeTag.HasUpgradeTag('T20250508.0003') then begin
            FormasDePago_Upgrade();
            UpgradeTag.SetUpgradeTag('T20250508.0003');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-EFPaginacionDataCleanup-19-02-2026-1-0') then begin
            EFPaginacionDataCleanup_Upgrade();
            UpgradeTag.SetUpgradeTag('DX-EFPaginacionDataCleanup-19-02-2026-1-0');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-EFSubtotalesDataCleanup-19-02-2026-1-0') then begin
            EFSubtotalesDataCleanup_Upgrade();
            UpgradeTag.SetUpgradeTag('DX-EFSubtotalesDataCleanup-19-02-2026-1-0');
        end;

        if not UpgradeTag.HasUpgradeTag('DXR-EF-Localization-Contingency-20260710') then begin
            MigrateContingencyToLocalization();
            UpgradeTag.SetUpgradeTag('DXR-EF-Localization-Contingency-20260710');
        end;
    end;

    local procedure FormasDePago_Upgrade()
    var
        FormasDePago: Record "DXR_Formas de Pago";
        EFFormType: Record "DXR_Form Type";
        LineNo: Integer;
    begin
        LineNo := 10000;
        if FormasDePago.FindSet() then
            repeat
                EFFormType.Init();
                EFFormType.FormaPago := FormasDePago.FormaPago;
                EFFormType.MontoPago := FormasDePago.MontoPago;
                EFFormType.DocumentNo := FormasDePago.DocumentNo;
                EFFormType."Line No." := LineNo;

                EFFormType.Insert();
                LineNo += 10000;
            until FormasDePago.Next() = 0;
    end;

    local procedure EFPaginacionDataCleanup_Upgrade()
    var
        EFPaginacion: Record "DXR_Paginacion";
        ExistingDefaultPage: Record "DXR_Paginacion";
        EFLogMessage: Record "DXR_Log Message";
        DeletedInvalidCount: Integer;
        NormalizedCount: Integer;
        SummaryText: Text[200];
    begin
        EFPaginacion.Reset();
        EFPaginacion.SetRange(DocumentNo, '');
        DeletedInvalidCount += EFPaginacion.Count();
        if not EFPaginacion.IsEmpty() then
            EFPaginacion.DeleteAll(false);

        EFPaginacion.Reset();
        EFPaginacion.SetRange(PaginaNo, '');
        EFPaginacion.SetFilter(DocumentNo, '<>%1', '');
        while EFPaginacion.FindFirst() do begin
            if ExistingDefaultPage.Get(EFPaginacion.DocumentNo, EFPaginacion.GetDefaultPageNo()) then begin
                EFPaginacion.Delete(false);
                DeletedInvalidCount += 1;
            end else begin
                EFPaginacion.Rename(EFPaginacion.DocumentNo, EFPaginacion.GetDefaultPageNo());
                NormalizedCount += 1;
            end;
        end;

        SummaryText := CopyStr(
            StrSubstNo('EF Paginacion cleanup: deleted=%1, normalized=%2', DeletedInvalidCount, NormalizedCount),
            1,
            MaxStrLen(SummaryText));

        if EFLogMessage.Get('UPGPAG', 'INFO') then begin
            EFLogMessage."Error Message" := SummaryText;
            EFLogMessage.Modify(true);
        end else begin
            EFLogMessage.Init();
            EFLogMessage.Code := 'UPGPAG';
            EFLogMessage.Status := 'INFO';
            EFLogMessage."Error Message" := SummaryText;
            EFLogMessage.Insert(true);
        end;
    end;

    local procedure EFSubtotalesDataCleanup_Upgrade()
    var
        EFSubTotalesInformativos: Record "DXR_SubTotales Informativos";
        ExistingDefaultSubtotal: Record "DXR_SubTotales Informativos";
        EFLogMessage: Record "DXR_Log Message";
        DeletedInvalidCount: Integer;
        NormalizedCount: Integer;
        SummaryText: Text[200];
    begin
        EFSubTotalesInformativos.Reset();
        EFSubTotalesInformativos.SetRange(DocumentNo, '');
        DeletedInvalidCount += EFSubTotalesInformativos.Count();
        if not EFSubTotalesInformativos.IsEmpty() then
            EFSubTotalesInformativos.DeleteAll(false);

        EFSubTotalesInformativos.Reset();
        EFSubTotalesInformativos.SetRange(NumeroSubTotal, 0);
        EFSubTotalesInformativos.SetFilter(DocumentNo, '<>%1', '');
        while EFSubTotalesInformativos.FindFirst() do begin
            if ExistingDefaultSubtotal.Get(EFSubTotalesInformativos.DocumentNo, EFSubTotalesInformativos.GetDefaultSubtotalNo()) then begin
                EFSubTotalesInformativos.Delete(false);
                DeletedInvalidCount += 1;
            end else begin
                EFSubTotalesInformativos.Rename(EFSubTotalesInformativos.DocumentNo, EFSubTotalesInformativos.GetDefaultSubtotalNo());
                NormalizedCount += 1;
            end;
        end;

        SummaryText := CopyStr(
            StrSubstNo('EF SubTotales cleanup: deleted=%1, normalized=%2', DeletedInvalidCount, NormalizedCount),
            1,
            MaxStrLen(SummaryText));

        if EFLogMessage.Get('UPGSUB', 'INFO') then begin
            EFLogMessage."Error Message" := SummaryText;
            EFLogMessage.Modify(true);
        end else begin
            EFLogMessage.Init();
            EFLogMessage.Code := 'UPGSUB';
            EFLogMessage.Status := 'INFO';
            EFLogMessage."Error Message" := SummaryText;
            EFLogMessage.Insert(true);
        end;
    end;

    local procedure MigrateContingencyToLocalization()
    begin
        MigrateSalesInvoiceContingency();
        MigrateSalesCreditMemoContingency();
        MigratePurchaseInvoiceContingency();
        MigratePurchaseCreditMemoContingency();
    end;

    local procedure MigrateSalesInvoiceContingency()
    var
        Header: Record "Sales Invoice Header";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if Header.FindSet(true) then
            repeat
                Modified := false;
                if (Header."Alternate NCF V2_DXR" = '') and (Header."Alternal NCF_DXR" <> '') then begin
                    Header."Alternate NCF V2_DXR" := Header."Alternal NCF_DXR";
                    Modified := true;
                end;
                if (Header."Alternate No. Series_DXR_V2" = '') and (Header."Alternal No. Series_DXR" <> '') then begin
                    Header."Alternate No. Series_DXR_V2" := Header."Alternal No. Series_DXR";
                    Modified := true;
                end;
                if not Header."Has NCF Contingency_DXR_V2" and Header."Has Contingencies_DXR" then begin
                    Header."Has NCF Contingency_DXR_V2" := true;
                    Modified := true;
                end;
                if Modified then
                    Header.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Header.Next() = 0;
    end;

    local procedure MigrateSalesCreditMemoContingency()
    var
        Header: Record "Sales Cr.Memo Header";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if Header.FindSet(true) then
            repeat
                Modified := false;
                if (Header."Alternate NCF_DXR_V2" = '') and (Header."Alternal NCF_DXR" <> '') then begin
                    Header."Alternate NCF_DXR_V2" := Header."Alternal NCF_DXR";
                    Modified := true;
                end;
                if (Header."Alternate No. Series_DXR_V2" = '') and (Header."Alternal No. Series_DXR" <> '') then begin
                    Header."Alternate No. Series_DXR_V2" := Header."Alternal No. Series_DXR";
                    Modified := true;
                end;
                if not Header."Has NCF Contingency_DXR_V2" and Header."Has Contingencies_DXR" then begin
                    Header."Has NCF Contingency_DXR_V2" := true;
                    Modified := true;
                end;
                if Modified then
                    Header.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Header.Next() = 0;
    end;

    local procedure MigratePurchaseInvoiceContingency()
    var
        Header: Record "Purch. Inv. Header";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if Header.FindSet(true) then
            repeat
                Modified := false;
                if (Header."Alternate NCF_DXR" = '') and (Header."Alternal NCF_DXR" <> '') then begin
                    Header."Alternate NCF_DXR" := Header."Alternal NCF_DXR";
                    Modified := true;
                end;
                if (Header."Alternate No. Series_DXR" = '') and (Header."Alternal No. Series_DXR" <> '') then begin
                    Header."Alternate No. Series_DXR" := Header."Alternal No. Series_DXR";
                    Modified := true;
                end;
                if not Header."Has NCF Contingency_DXR" and Header."Has Contingencies_DXR" then begin
                    Header."Has NCF Contingency_DXR" := true;
                    Modified := true;
                end;
                if Modified then
                    Header.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Header.Next() = 0;
    end;

    local procedure MigratePurchaseCreditMemoContingency()
    var
        Header: Record "Purch. Cr. Memo Hdr.";
        Modified: Boolean;
        BatchCount: Integer;
    begin
        if Header.FindSet(true) then
            repeat
                Modified := false;
                if (Header."Alternate NCF_DXR" = '') and (Header."Alternal NCF_DXR" <> '') then begin
                    Header."Alternate NCF_DXR" := Header."Alternal NCF_DXR";
                    Modified := true;
                end;
                if (Header."Alternate No. Series_DXR" = '') and (Header."Alternal No. Series_DXR" <> '') then begin
                    Header."Alternate No. Series_DXR" := Header."Alternal No. Series_DXR";
                    Modified := true;
                end;
                if not Header."Has NCF Contingency_DXR" and Header."Has Contingencies_DXR" then begin
                    Header."Has NCF Contingency_DXR" := true;
                    Modified := true;
                end;
                if Modified then
                    Header.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Header.Next() = 0;
    end;
}
