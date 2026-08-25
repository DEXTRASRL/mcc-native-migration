codeunit 60139 "DXR MCC FE Migr Phase10"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 10 Sales".OnRun() (Access = Internal). Field-to-field copies on 6 sales
    // document tables - all public/standard BC tables.
    //
    // Converted from the generic RecordRef/FieldRef "CopySameTableFields" helper to direct typed
    // field assignment, zero RecordRef/FieldRef. Every field pair below was independently
    // re-derived against real tableextension source in
    // "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\TableExts\"
    // (EFSalesCrMemoHeader/EFSalesCrMemoLine/EFSalesHeader/EFSalesInvoiceHeader/
    // EFSalesInvoiceLine/EFSalesLine.TableExt.al) and confirmed to match the prior FieldMap
    // literals exactly (field IDs mirror Phase9's Purchase-family tables one-for-one, except
    // Sales Invoice Header has no "Indicator Override_DXR"/"EF Indicator Override" pair - Purch.
    // Inv. Header does; correctly omitted below, matching the prior FieldMap). "Status_DXR"/
    // "Provider_DXR" use an AsInteger()/FromInteger() enum round-trip (structurally identical
    // enum pairs, confirmed by reading both sources), same technique as Phase9. Blob fields
    // ("Signature Value_DXR", "Encoded Barcode_DXR") are copied via CalcFields+direct assignment.
    // Batched in Commit-groups of 100 per table, matching this campaign's precedent for posted/
    // unposted document header/line tables of unbounded row volume.
    Permissions =
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "Sales Cr.Memo Line" = RM,
        tabledata "Sales Header" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Line" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625') then
            exit;

        MigrateSalesTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625');
    end;

    local procedure MigrateSalesTableExtensionFields()
    begin
        CopySalesCrMemoHeaderFields();
        CopySalesCrMemoLineFields();
        CopySalesHeaderFields();
        CopySalesInvoiceHeaderFields();
        CopySalesInvoiceLineFields();
        CopySalesLineFields();
    end;

    local procedure CopySalesCrMemoHeaderFields()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        BatchCount: Integer;
    begin
        if SalesCrMemoHeader.FindSet(true) then
            repeat
                SalesCrMemoHeader."Already Sent_DXR" := SalesCrMemoHeader."EF Already Sent";
                SalesCrMemoHeader."Alternal NCF_DXR" := SalesCrMemoHeader."EF Alternal NCF";
                SalesCrMemoHeader."Alternal No. Series_DXR" := SalesCrMemoHeader."EF Alternal No. Series";
                SalesCrMemoHeader."Applies for ISC_DXR" := SalesCrMemoHeader."EF Applies for ISC";
                SalesCrMemoHeader."NCF Mod. Reason_DXR" := SalesCrMemoHeader."EF NCF Modification Reason";
                SalesCrMemoHeader."DGII Message_DXR" := SalesCrMemoHeader."EF DGII Message";
                SalesCrMemoHeader."Has Contingencies_DXR" := SalesCrMemoHeader."EF Has Contingencies";
                SalesCrMemoHeader."Indicator Override_DXR" := SalesCrMemoHeader."EF Indicator Override";
                SalesCrMemoHeader."Provider_DXR" := Enum::"DXR_Service Provider".FromInteger(SalesCrMemoHeader."EF Provider".AsInteger());
                SalesCrMemoHeader."Requested DateTime_DXR" := SalesCrMemoHeader."EF Requested DateTime";
                SalesCrMemoHeader."Security Code_DXR" := SalesCrMemoHeader."EF Security Code";
                SalesCrMemoHeader."Stamped Date/Time_DXR" := SalesCrMemoHeader."EF Stamped Date/Time";
                SalesCrMemoHeader."Status_DXR" := Enum::"DXR_Approval Status Type".FromInteger(SalesCrMemoHeader."EF Status".AsInteger());

                SalesCrMemoHeader.CalcFields("EF Signature Value", "EF Encoded Barcode");
                SalesCrMemoHeader."Signature Value_DXR" := SalesCrMemoHeader."EF Signature Value";
                SalesCrMemoHeader."Encoded Barcode_DXR" := SalesCrMemoHeader."EF Encoded Barcode";

                SalesCrMemoHeader.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesCrMemoHeader.Next() = 0;
    end;

    local procedure CopySalesCrMemoLineFields()
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        BatchCount: Integer;
    begin
        if SalesCrMemoLine.FindSet(true) then
            repeat
                SalesCrMemoLine."Applies for ISC_DXR" := SalesCrMemoLine."EF Applies for ISC";
                SalesCrMemoLine."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(SalesCrMemoLine."EF Tax Indicator".AsInteger());
                // 55504 "EF Applies for Withholding" -> 52335 "Applies Withholding_DXR" added
                // 2026-08-22 (portfolio-wide "missing migration" audit).
                SalesCrMemoLine."Applies Withholding_DXR" := SalesCrMemoLine."EF Applies for Withholding";
                SalesCrMemoLine."UOM Type_DXR" := SalesCrMemoLine."EF UOM Type";
                SalesCrMemoLine.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesCrMemoLine.Next() = 0;
    end;

    // Sales Header: NCF Mod. Reason_DXR lives at 52335 (moved from 52334 to resolve a
    // TransferFields collision with Sales Invoice Header/Sales Cr.Memo Header field 52334).
    local procedure CopySalesHeaderFields()
    var
        SalesHeader: Record "Sales Header";
        BatchCount: Integer;
    begin
        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader."Applies for ISC_DXR" := SalesHeader."EF Applies for ISC";
                SalesHeader."NCF Mod. Reason_DXR" := SalesHeader."EF NCF Modification Reason";
                SalesHeader.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesHeader.Next() = 0;
    end;

    // Sales Invoice Header has no "Indicator Override_DXR"/"EF Indicator Override" field pair
    // (unlike Purch. Inv. Header in Phase9) - confirmed against EFSalesInvoiceHeader.TableExt.al,
    // correctly omitted below, matching the prior FieldMap.
    local procedure CopySalesInvoiceHeaderFields()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        BatchCount: Integer;
    begin
        if SalesInvoiceHeader.FindSet(true) then
            repeat
                SalesInvoiceHeader."Already Sent_DXR" := SalesInvoiceHeader."EF Already Sent";
                SalesInvoiceHeader."Alternal NCF_DXR" := SalesInvoiceHeader."EF Alternal NCF";
                SalesInvoiceHeader."Alternal No. Series_DXR" := SalesInvoiceHeader."EF Alternal No. Series";
                SalesInvoiceHeader."Applies for ISC_DXR" := SalesInvoiceHeader."EF Applies for ISC";
                SalesInvoiceHeader."NCF Mod. Reason_DXR" := SalesInvoiceHeader."EF NCF Modification Reason";
                SalesInvoiceHeader."DGII Message_DXR" := SalesInvoiceHeader."EF DGII Message";
                SalesInvoiceHeader."Has Contingencies_DXR" := SalesInvoiceHeader."EF Has Contingencies";
                SalesInvoiceHeader."MultiCurrency Fact_DXR" := SalesInvoiceHeader."EF MultiCurrency Fact";
                SalesInvoiceHeader."MultiCurrency_DXR" := SalesInvoiceHeader."EF MultiCurrency";
                SalesInvoiceHeader."Provider_DXR" := Enum::"DXR_Service Provider".FromInteger(SalesInvoiceHeader."EF Provider".AsInteger());
                SalesInvoiceHeader."Requested DateTime_DXR" := SalesInvoiceHeader."EF Requested DateTime";
                SalesInvoiceHeader."Security Code_DXR" := SalesInvoiceHeader."EF Security Code";
                SalesInvoiceHeader."Stamped Date/Time_DXR" := SalesInvoiceHeader."EF Stamped Date/Time";
                SalesInvoiceHeader."Status_DXR" := Enum::"DXR_Approval Status Type".FromInteger(SalesInvoiceHeader."EF Status".AsInteger());

                SalesInvoiceHeader.CalcFields("EF Signature Value", "EF Encoded Barcode");
                SalesInvoiceHeader."Signature Value_DXR" := SalesInvoiceHeader."EF Signature Value";
                SalesInvoiceHeader."Encoded Barcode_DXR" := SalesInvoiceHeader."EF Encoded Barcode";

                SalesInvoiceHeader.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceHeader.Next() = 0;
    end;

    local procedure CopySalesInvoiceLineFields()
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        BatchCount: Integer;
    begin
        if SalesInvoiceLine.FindSet(true) then
            repeat
                SalesInvoiceLine."Applies for ISC_DXR" := SalesInvoiceLine."EF Applies for ISC";
                SalesInvoiceLine."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(SalesInvoiceLine."EF Tax Indicator".AsInteger());
                // 55504 -> 52335 added 2026-08-22, same reason as Sales Cr.Memo Line above.
                SalesInvoiceLine."Applies Withholding_DXR" := SalesInvoiceLine."EF Applies for Withholding";
                SalesInvoiceLine."UOM Type_DXR" := SalesInvoiceLine."EF UOM Type";
                SalesInvoiceLine.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesInvoiceLine.Next() = 0;
    end;

    local procedure CopySalesLineFields()
    var
        SalesLine: Record "Sales Line";
        BatchCount: Integer;
    begin
        if SalesLine.FindSet(true) then
            repeat
                SalesLine."Applies for ISC_DXR" := SalesLine."EF Applies for ISC";
                SalesLine."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(SalesLine."EF Tax Indicator".AsInteger());
                // 55504 -> 52335 added 2026-08-22, same reason as Sales Cr.Memo Line above.
                SalesLine."Applies Withholding_DXR" := SalesLine."EF Applies for Withholding";
                SalesLine."UOM Type_DXR" := SalesLine."EF UOM Type";
                SalesLine.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesLine.Next() = 0;
    end;
}
