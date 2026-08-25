codeunit 60138 "DXR MCC FE Migr Phase9"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 9 Purchase".OnRun() (Access = Internal). Field-to-field copies on 5
    // purchase document tables - all public/standard BC tables.
    //
    // Converted from the generic RecordRef/FieldRef "CopySameTableFields" helper to direct typed
    // field assignment, zero RecordRef/FieldRef. Every field pair below was independently
    // re-derived against real tableextension source in
    // "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\TableExts\"
    // (EFPurchCrMemoHdr/EFPurchCrMemoLine/EFPurchInvHeader/EFPurchInvLine/EFPurchaseHeader.TableExt.al)
    // and confirmed to match the prior FieldMap literals exactly. "Status_DXR"/"Provider_DXR" use
    // an AsInteger()/FromInteger() enum round-trip ("EF Approval Status Type"/"DXR_Approval Status
    // Type" and "EF Service Provider"/"DXR_Service Provider" are structurally identical enums,
    // confirmed by reading both sources), same technique already used elsewhere in this campaign
    // (Phase7's Payment Type, Phase8's VAT Tax Indicator). Blob fields ("Signature Value_DXR",
    // "Encoded Barcode_DXR") are copied via CalcFields+direct assignment, matching the VP Vendor
    // Payloads campaign's precedent for typed Blob copies. Batched in Commit-groups of 100 per
    // table, matching this campaign's precedent for posted/unposted document header/line tables
    // of unbounded row volume (e.g. DRLOC's Sales Invoice Header/Line Phase4 conversion).
    Permissions =
        tabledata "Purch. Cr. Memo Hdr." = RM,
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Purchase Header" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625') then
            exit;

        MigratePurchaseTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625');
    end;

    procedure RunMaster()
    begin
    end;

    procedure RunAccounting()
    begin
        CopyPurchaseHeaderFields();
    end;

    procedure RunHistoric()
    begin
        CopyPurchCrMemoHdrFields();
        CopyPurchCrMemoLineFields();
        CopyPurchInvHeaderFields();
        CopyPurchInvLineFields();
    end;

    local procedure MigratePurchaseTableExtensionFields()
    begin
        CopyPurchCrMemoHdrFields();
        CopyPurchCrMemoLineFields();
        CopyPurchInvHeaderFields();
        CopyPurchInvLineFields();
        CopyPurchaseHeaderFields();
    end;

    local procedure CopyPurchCrMemoHdrFields()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        BatchCount: Integer;
    begin
        if PurchCrMemoHdr.FindSet(true) then
            repeat
                PurchCrMemoHdr."Already Sent_DXR" := PurchCrMemoHdr."EF Already Sent";
                PurchCrMemoHdr."Alternal NCF_DXR" := PurchCrMemoHdr."EF Alternal NCF";
                PurchCrMemoHdr."Alternal No. Series_DXR" := PurchCrMemoHdr."EF Alternal No. Series";
                PurchCrMemoHdr."Applies for ISC_DXR" := PurchCrMemoHdr."EF Applies for ISC";
                PurchCrMemoHdr."NCF Mod. Reason_DXR" := PurchCrMemoHdr."EF NCF Modification Reason";
                PurchCrMemoHdr."DGII Message_DXR" := PurchCrMemoHdr."EF DGII Message";
                PurchCrMemoHdr."Has Contingencies_DXR" := PurchCrMemoHdr."EF Has Contingencies";
                PurchCrMemoHdr."Indicator Override_DXR" := PurchCrMemoHdr."EF Indicator Override";
                PurchCrMemoHdr."Provider_DXR" := Enum::"DXR_Service Provider".FromInteger(PurchCrMemoHdr."EF Provider".AsInteger());
                PurchCrMemoHdr."Requested DateTime_DXR" := PurchCrMemoHdr."EF Requested DateTime";
                PurchCrMemoHdr."Security Code_DXR" := PurchCrMemoHdr."EF Security Code";
                PurchCrMemoHdr."Stamped Date/Time_DXR" := PurchCrMemoHdr."EF Stamped Date/Time";
                PurchCrMemoHdr."Status_DXR" := Enum::"DXR_Approval Status Type".FromInteger(PurchCrMemoHdr."EF Status".AsInteger());

                PurchCrMemoHdr.CalcFields("EF Signature Value", "EF Encoded Barcode");
                PurchCrMemoHdr."Signature Value_DXR" := PurchCrMemoHdr."EF Signature Value";
                PurchCrMemoHdr."Encoded Barcode_DXR" := PurchCrMemoHdr."EF Encoded Barcode";

                PurchCrMemoHdr.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchCrMemoHdr.Next() = 0;
    end;

    local procedure CopyPurchCrMemoLineFields()
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        BatchCount: Integer;
    begin
        if PurchCrMemoLine.FindSet(true) then
            repeat
                PurchCrMemoLine."Applies for ISC_DXR" := PurchCrMemoLine."EF Applies for ISC";
                PurchCrMemoLine."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(PurchCrMemoLine."EF Tax Indicator".AsInteger());
                // 55504 "EF Applies for Withholding" -> 52335 "Applies Withholding_DXR" added
                // 2026-08-22 (portfolio-wide "missing migration" audit) - was missing here,
                // silently leaving this field blank on every row.
                PurchCrMemoLine."Applies Withholding_DXR" := PurchCrMemoLine."EF Applies for Withholding";
                PurchCrMemoLine."UOM Type_DXR" := PurchCrMemoLine."EF UOM Type";
                PurchCrMemoLine.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchCrMemoLine.Next() = 0;
    end;

    local procedure CopyPurchInvHeaderFields()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        BatchCount: Integer;
    begin
        if PurchInvHeader.FindSet(true) then
            repeat
                PurchInvHeader."Already Sent_DXR" := PurchInvHeader."EF Already Sent";
                PurchInvHeader."Alternal NCF_DXR" := PurchInvHeader."EF Alternal NCF";
                PurchInvHeader."Alternal No. Series_DXR" := PurchInvHeader."EF Alternal No. Series";
                PurchInvHeader."Applies for ISC_DXR" := PurchInvHeader."EF Applies for ISC";
                PurchInvHeader."NCF Mod. Reason_DXR" := PurchInvHeader."EF NCF Modification Reason";
                PurchInvHeader."DGII Message_DXR" := PurchInvHeader."EF DGII Message";
                PurchInvHeader."Has Contingencies_DXR" := PurchInvHeader."EF Has Contingencies";
                PurchInvHeader."Indicator Override_DXR" := PurchInvHeader."EF Indicator Override";
                PurchInvHeader."MultiCurrency Fact_DXR" := PurchInvHeader."EF MultiCurrency Fact";
                PurchInvHeader."MultiCurrency_DXR" := PurchInvHeader."EF MultiCurrency";
                PurchInvHeader."Provider_DXR" := Enum::"DXR_Service Provider".FromInteger(PurchInvHeader."EF Provider".AsInteger());
                PurchInvHeader."Requested DateTime_DXR" := PurchInvHeader."EF Requested DateTime";
                PurchInvHeader."Security Code_DXR" := PurchInvHeader."EF Security Code";
                PurchInvHeader."Stamped Date/Time_DXR" := PurchInvHeader."EF Stamped Date/Time";
                PurchInvHeader."Status_DXR" := Enum::"DXR_Approval Status Type".FromInteger(PurchInvHeader."EF Status".AsInteger());

                PurchInvHeader.CalcFields("EF Signature Value", "EF Encoded Barcode");
                PurchInvHeader."Signature Value_DXR" := PurchInvHeader."EF Signature Value";
                PurchInvHeader."Encoded Barcode_DXR" := PurchInvHeader."EF Encoded Barcode";

                PurchInvHeader.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchInvHeader.Next() = 0;
    end;

    local procedure CopyPurchInvLineFields()
    var
        PurchInvLine: Record "Purch. Inv. Line";
        BatchCount: Integer;
    begin
        if PurchInvLine.FindSet(true) then
            repeat
                PurchInvLine."Applies for ISC_DXR" := PurchInvLine."EF Applies for ISC";
                PurchInvLine."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(PurchInvLine."EF Tax Indicator".AsInteger());
                // 55504 -> 52335 added 2026-08-22, same reason as Purch. Cr. Memo Line above.
                PurchInvLine."Applies Withholding_DXR" := PurchInvLine."EF Applies for Withholding";
                PurchInvLine."UOM Type_DXR" := PurchInvLine."EF UOM Type";
                PurchInvLine.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchInvLine.Next() = 0;
    end;

    // Purchase Header only carries the legacy "EF NCF Modification Reason" (55503), replaced by
    // "NCF Mod. Reason_DXR" at 52335 (moved from 52333 to resolve a TransferFields collision with
    // Purch. Inv. Header/Purch. Cr. Memo Hdr. field 52333).
    local procedure CopyPurchaseHeaderFields()
    var
        PurchaseHeader: Record "Purchase Header";
        BatchCount: Integer;
    begin
        if PurchaseHeader.FindSet(true) then
            repeat
                PurchaseHeader."NCF Mod. Reason_DXR" := PurchaseHeader."EF NCF Modification Reason";
                PurchaseHeader.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PurchaseHeader.Next() = 0;
    end;
}
