codeunit 60125 "DXR MCC PCM Migr Phase5"
{
    // Native local migration - ported verbatim from Price Controls Mgt.'s own
    // "DXR_Migr. Phase 5 Id Renum".Run() - see "DXR MCC PCM Migr Phase2" for the full rationale.
    // Migrates data from the legacy 570xx objects (restored at their original IDs, ObsoleteState =
    // Pending, so publish does not attempt to remove them) into their renumbered 54xxx replacements
    // after PCM's "Renumerar objetos y campos DXR_ a rango global 51801-54999" commit. Unlike
    // Phase2-4, the real source has no retry-on-transient-lock logic here - preserved as-is.
    // Tables 54605 "DXR_Prices Ctrl Setup" and 54609 "DXR_Approval History" are Access = Internal
    // on PCM's side (restored 570xx predecessors, pending removal). Both MigratePricesCtrlSetup and
    // MigrateApprovalHistory below use the native Direct pattern (see MigratePricesCtrlSetupDirect()):
    // PCM now grants MCC internalsVisibleTo, so MCC declares the Old/New Record pairs directly and
    // does the field-by-field copy inline - zero RecordRef/FieldRef/TransferFields anywhere in this
    // codeunit - instead of calling PCM's own codeunits as a cross-app bridge.
    Permissions =
        tabledata "Approval Entry" = RM,
        tabledata Customer = RM,
        tabledata "LSC Store Price Group" = RM,
        tabledata Workflow = RM,
        tabledata "Sales Header" = RM,
        tabledata "Sales Line" = RM,
        tabledata "DXR_Prices Ctrl Setup_Old" = R,
        tabledata "DXR_Prices Ctrl Setup" = RI,
        tabledata "DXR_Approval History_Old" = R,
        tabledata "DXR_Approval History" = RI;

#pragma warning disable AL0432
    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunHistoric();
        RunOther();
    end;

    procedure RunSetup()
    begin
        MigratePricesCtrlSetup();
        MigrateStorePriceGroupFields();
        MigrateWorkflowFields();
    end;

    procedure RunMaster()
    begin
        MigrateCustomerFields();
        MigrateSalesHeaderSnapshotFields();
        MigrateSalesLineFields();
    end;

    procedure RunHistoric()
    begin
        MigrateApprovalHistory();
    end;

    procedure RunOther()
    begin
        MigrateApprovalEntryFields();
    end;

    local procedure MigratePricesCtrlSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Step1Tag()) then
            exit;

        // Native Direct pattern - PCM now grants MCC internalsVisibleTo, so MCC declares both
        // "DXR_Prices Ctrl Setup_Old" (57022, Access=Internal) and "DXR_Prices Ctrl Setup" (54605,
        // Access=Internal) directly instead of calling PCM's own codeunit 54620's
        // MigrateLegacyPricesCtrlSetupForExternalCaller() as a cross-app bridge. Replicates that
        // procedure's exact fill-semantics inline: single-row setup, only copied if the target row
        // does not already exist (by Code) - zero RecordRef/FieldRef/TransferFields, explicit
        // per-field typed assignment for all 70 fields the two tables share (verified 1:1 identical
        // field IDs/names/types between src\Base\Tables.old and src\Base\Tables versions of
        // DXRPRCPricesCtrlSetup.Table.al in PCM's own repo).
        MigratePricesCtrlSetupDirect();

        UpgradeTag.SetUpgradeTag(Step1Tag());
    end;

    local procedure MigratePricesCtrlSetupDirect()
    var
        OldSetup: Record "DXR_Prices Ctrl Setup_Old";
        NewSetup: Record "DXR_Prices Ctrl Setup";
    begin
        if not OldSetup.FindFirst() then
            exit;

        if NewSetup.Get(OldSetup.Code) then
            exit;

        NewSetup.Init();
        NewSetup.Code := OldSetup.Code;
        NewSetup."control Fijacion Precios" := OldSetup."control Fijacion Precios";
        NewSetup."control Precios Exento" := OldSetup."control Precios Exento";
        NewSetup."Exempt group" := OldSetup."Exempt group";
        NewSetup."Exempt Product group" := OldSetup."Exempt Product group";
        NewSetup."Mandatory Shipment Method" := OldSetup."Mandatory Shipment Method";
        NewSetup."PRC Enable Price Highlighting" := OldSetup."PRC Enable Price Highlighting";
        NewSetup."PRC Highlight Lower Price" := OldSetup."PRC Highlight Lower Price";
        NewSetup."PRC Highlight Price Change" := OldSetup."PRC Highlight Price Change";
        NewSetup."PRC Enable Approval Summary" := OldSetup."PRC Enable Approval Summary";
        NewSetup."Mandatory Store In Customer" := OldSetup."Mandatory Store In Customer";
        NewSetup."PRC Control Print Actions" := OldSetup."PRC Control Print Actions";
        NewSetup."PRC Control Post Actions" := OldSetup."PRC Control Post Actions";
        NewSetup."PRC Control Offer Price" := OldSetup."PRC Control Offer Price";
        NewSetup."PRC Control Offer Discount" := OldSetup."PRC Control Offer Discount";
        NewSetup."PRC Show Offer Actions" := OldSetup."PRC Show Offer Actions";
        NewSetup."PRC Control Post & Send" := OldSetup."PRC Control Post & Send";
        NewSetup."PRC Control Post & Print" := OldSetup."PRC Control Post & Print";
        NewSetup."PRC Control Make Order" := OldSetup."PRC Control Make Order";
        NewSetup."PRC Enable Price Approval Page" := OldSetup."PRC Enable Price Approval Page";
        NewSetup."PRC Show Markup Percentages" := OldSetup."PRC Show Markup Percentages";
        NewSetup."PRC Show Profit Percentages" := OldSetup."PRC Show Profit Percentages";
        NewSetup."PRC Show Profit LCY" := OldSetup."PRC Show Profit LCY";
        NewSetup."PRC Show Direct Cost" := OldSetup."PRC Show Direct Cost";
        NewSetup."PRC Highlight LSC Offers" := OldSetup."PRC Highlight LSC Offers";
        NewSetup."PRC Show Periodic Discounts" := OldSetup."PRC Show Periodic Discounts";
        NewSetup."PRC Show Promotions" := OldSetup."PRC Show Promotions";
        NewSetup."PRC Show Offer Priority" := OldSetup."PRC Show Offer Priority";
        NewSetup."PRC Show Offer Description" := OldSetup."PRC Show Offer Description";
        NewSetup."PRC Show Offer Dates" := OldSetup."PRC Show Offer Dates";
        NewSetup."PRC Show Price Group" := OldSetup."PRC Show Price Group";
        NewSetup."PRC Show Validation Period" := OldSetup."PRC Show Validation Period";
        NewSetup."PRC Show Offer Type" := OldSetup."PRC Show Offer Type";
        NewSetup."PRC Show Offer Store" := OldSetup."PRC Show Offer Store";
        NewSetup."PRC Show Offer Discount Pct" := OldSetup."PRC Show Offer Discount Pct";
        NewSetup."PRC Show Offer Price Field" := OldSetup."PRC Show Offer Price Field";
        NewSetup."SO Show Customer Prices" := OldSetup."SO Show Customer Prices";
        NewSetup."SO Show Store Prices" := OldSetup."SO Show Store Prices";
        NewSetup."SO Show Periodic Discounts" := OldSetup."SO Show Periodic Discounts";
        NewSetup."SO Show Promotions" := OldSetup."SO Show Promotions";
        NewSetup."SO Show Approval Summary" := OldSetup."SO Show Approval Summary";
        NewSetup."SQ Show Customer Prices" := OldSetup."SQ Show Customer Prices";
        NewSetup."SQ Show Store Prices" := OldSetup."SQ Show Store Prices";
        NewSetup."SQ Show Periodic Discounts" := OldSetup."SQ Show Periodic Discounts";
        NewSetup."SQ Show Promotions" := OldSetup."SQ Show Promotions";
        NewSetup."SQ Show Approval Summary" := OldSetup."SQ Show Approval Summary";
        NewSetup."RSO Show Customer Prices" := OldSetup."RSO Show Customer Prices";
        NewSetup."RSO Show Store Prices" := OldSetup."RSO Show Store Prices";
        NewSetup."RSO Show Periodic Discounts" := OldSetup."RSO Show Periodic Discounts";
        NewSetup."RSO Show Promotions" := OldSetup."RSO Show Promotions";
        NewSetup."RSO Show Approval Summary" := OldSetup."RSO Show Approval Summary";
        NewSetup."PRC Control Attach PDF" := OldSetup."PRC Control Attach PDF";
        NewSetup."PRC Control Email Actions" := OldSetup."PRC Control Email Actions";
        NewSetup."PRC Control Print Confirmation" := OldSetup."PRC Control Print Confirmation";
        NewSetup."PRC Control Post & New" := OldSetup."PRC Control Post & New";
        NewSetup."PRC Enable Approval Colors" := OldSetup."PRC Enable Approval Colors";
        NewSetup."PRC Color Line Price" := OldSetup."PRC Color Line Price";
        NewSetup."PRC Color Profit Positive" := OldSetup."PRC Color Profit Positive";
        NewSetup."PRC Color Reference Price" := OldSetup."PRC Color Reference Price";
        NewSetup."PRC Color Line Amount" := OldSetup."PRC Color Line Amount";
        NewSetup."PRC Color Item Number" := OldSetup."PRC Color Item Number";
        NewSetup."PRC Color Negative Diff" := OldSetup."PRC Color Negative Diff";
        NewSetup."PRC Color Positive Savings" := OldSetup."PRC Color Positive Savings";
        NewSetup."PRC Enable Snapshot Validation" := OldSetup."PRC Enable Snapshot Validation";
        NewSetup."PRC Cleanup Snap After Release" := OldSetup."PRC Cleanup Snap After Release";
        NewSetup."PRC Show Snapshot Info" := OldSetup."PRC Show Snapshot Info";
        NewSetup."PRC Eval Deleted Lines Range" := OldSetup."PRC Eval Deleted Lines Range";
        NewSetup."PRC Enforce Single Team" := OldSetup."PRC Enforce Single Team";
        NewSetup."PRC Require Team Assignment" := OldSetup."PRC Require Team Assignment";
        NewSetup."PRC Control Make Invoice" := OldSetup."PRC Control Make Invoice";
        NewSetup.Insert(false);
    end;

    local procedure MigrateApprovalHistory()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        OldHistory: Record "DXR_Approval History_Old";
        NewHistory: Record "DXR_Approval History";
    begin
        if UpgradeTag.HasUpgradeTag(Step2Tag()) then
            exit;

        // Native Direct pattern - PCM grants MCC internalsVisibleTo, so MCC declares both
        // "DXR_Approval History_Old" (57024, Access=Internal) and "DXR_Approval History" (54609,
        // Access=Internal) directly - zero RecordRef/FieldRef, explicit per-field typed assignment
        // for all 29 fields the two tables share (verified 1:1 identical field IDs/names/types
        // between src\Base\Tables.old and src\Base\Tables versions of DXRPRCApprovalHistory.Table.al
        // in PCM's own repo). Field 1 "Entry No." is AutoIncrement on both tables - intentionally NOT
        // copied, the new table generates its own sequence; only the descriptive fields are migrated.
        // Insert only, no Modify/upsert - Approval History is append-only audit-trail data, matching
        // the real source semantics.
        if OldHistory.FindSet() then
            repeat
                NewHistory.Init();
                NewHistory."Document Type" := OldHistory."Document Type";
                NewHistory."Document No." := OldHistory."Document No.";
                NewHistory."Source Type" := OldHistory."Source Type";
                NewHistory."Document Type Text" := OldHistory."Document Type Text";
                NewHistory."Purch. Document Type" := OldHistory."Purch. Document Type";
                NewHistory."Action Type" := OldHistory."Action Type";
                NewHistory."Action DateTime" := OldHistory."Action DateTime";
                NewHistory."User ID" := OldHistory."User ID";
                NewHistory."User Name" := OldHistory."User Name";
                NewHistory."Workflow Code" := OldHistory."Workflow Code";
                NewHistory."Approval Entry No." := OldHistory."Approval Entry No.";
                NewHistory."Workflow Description" := OldHistory."Workflow Description";
                NewHistory."Sender ID" := OldHistory."Sender ID";
                NewHistory."Sender Name" := OldHistory."Sender Name";
                NewHistory."Approver ID" := OldHistory."Approver ID";
                NewHistory."Approver Name" := OldHistory."Approver Name";
                NewHistory."Approval Code" := OldHistory."Approval Code";
                NewHistory."Sequence No." := OldHistory."Sequence No.";
                NewHistory."Delegation Date" := OldHistory."Delegation Date";
                NewHistory."Due Date" := OldHistory."Due Date";
                NewHistory."Previous Status" := OldHistory."Previous Status";
                NewHistory."New Status" := OldHistory."New Status";
                NewHistory."Previous Status Text" := OldHistory."Previous Status Text";
                NewHistory."New Status Text" := OldHistory."New Status Text";
                NewHistory."Comments" := OldHistory."Comments";
                NewHistory."Salesperson Code" := OldHistory."Salesperson Code";
                NewHistory."Customer No." := OldHistory."Customer No.";
                NewHistory."Total Amount" := OldHistory."Total Amount";
                NewHistory."Vendor No." := OldHistory."Vendor No.";
                NewHistory.Insert(false);
            until OldHistory.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step2Tag());
    end;

    local procedure MigrateApprovalEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ApprovalEntry: Record "Approval Entry";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(Step3Tag()) then
            exit;

        if ApprovalEntry.FindSet(true) then
            repeat
                Modified := false;

                if (ApprovalEntry."Workflow Code" <> '') and (ApprovalEntry."Workflow Code_DXR" = '') then begin
                    ApprovalEntry."Workflow Code_DXR" := ApprovalEntry."Workflow Code";
                    Modified := true;
                end;
                if (not IsNullGuid(ApprovalEntry."Workflow Instance ID")) and IsNullGuid(ApprovalEntry."Workflow Instance ID_DXR") then begin
                    ApprovalEntry."Workflow Instance ID_DXR" := ApprovalEntry."Workflow Instance ID";
                    Modified := true;
                end;
                if (ApprovalEntry."Posting Date" <> 0D) and (ApprovalEntry."Posting Date_DXR" = 0D) then begin
                    ApprovalEntry."Posting Date_DXR" := ApprovalEntry."Posting Date";
                    Modified := true;
                end;

                if Modified then
                    ApprovalEntry.Modify(false);
            until ApprovalEntry.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step3Tag());
    end;

    local procedure MigrateCustomerFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Customer: Record Customer;
    begin
        if UpgradeTag.HasUpgradeTag(Step4Tag()) then
            exit;

        Customer.SetFilter("PRC Store", '<>%1', '');
        if Customer.FindSet(true) then
            repeat
                if Customer."PRC Store_DXR" = '' then begin
                    Customer."PRC Store_DXR" := Customer."PRC Store";
                    Customer.Modify(false);
                end;
            until Customer.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step4Tag());
    end;

    local procedure MigrateStorePriceGroupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        StorePriceGroup: Record "LSC Store Price Group";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(Step5Tag()) then
            exit;

        if StorePriceGroup.FindSet(true) then
            repeat
                Modified := false;

                if StorePriceGroup."PRC Precio Fijado" and not StorePriceGroup."PRC Precio Fijado_DXR" then begin
                    StorePriceGroup."PRC Precio Fijado_DXR" := true;
                    Modified := true;
                end;
                if StorePriceGroup."PRC Excluir Store Prices" and not StorePriceGroup."PRC ExclStorePrc_DXR" then begin
                    StorePriceGroup."PRC ExclStorePrc_DXR" := true;
                    Modified := true;
                end;
                if StorePriceGroup."PRC Excluir Cust. Prices" and not StorePriceGroup."PRC ExclCustPrc_DXR" then begin
                    StorePriceGroup."PRC ExclCustPrc_DXR" := true;
                    Modified := true;
                end;

                if Modified then
                    StorePriceGroup.Modify(false);
            until StorePriceGroup.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step5Tag());
    end;

    local procedure MigrateWorkflowFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Workflow: Record Workflow;
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(Step6Tag()) then
            exit;

        if Workflow.FindSet(true) then
            repeat
                Modified := false;

                if (Workflow."PRC Approval Type" <> Workflow."PRC Approval Type"::All) and
                   (Workflow."DXR_Approval Type" = Workflow."DXR_Approval Type"::All)
                then begin
                    Workflow."DXR_Approval Type" := Workflow."PRC Approval Type";
                    Modified := true;
                end;

                if (Workflow."PRC Approval Type_DXR_Old" <> Workflow."PRC Approval Type_DXR_Old"::All) and
                   (Workflow."PRC Approval Type_DXR" = Workflow."PRC Approval Type_DXR"::All)
                then begin
                    Workflow."PRC Approval Type_DXR" := Workflow."PRC Approval Type_DXR_Old";
                    Modified := true;
                end;

                if Modified then
                    Workflow.Modify(false);
            until Workflow.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step6Tag());
    end;

    local procedure MigrateSalesHeaderSnapshotFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesHeader: Record "Sales Header";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(Step7Tag()) then
            exit;

        SalesHeader.SetRange("PRC Snapshot Enabled", true);
        if SalesHeader.FindSet(true) then
            repeat
                Modified := false;

                if not SalesHeader."PRC Snapshot Enabled_DXR" then begin
                    SalesHeader."PRC Snapshot Enabled_DXR" := SalesHeader."PRC Snapshot Enabled";
                    Modified := true;
                end;
                if (SalesHeader."PRC Source Quote No." <> '') and (SalesHeader."PRC Src Quote No._DXR" = '') then begin
                    SalesHeader."PRC Src Quote No._DXR" := SalesHeader."PRC Source Quote No.";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snapshot Timestamp" <> 0DT) and (SalesHeader."PRC Snap Timestamp_DXR" = 0DT) then begin
                    SalesHeader."PRC Snap Timestamp_DXR" := SalesHeader."PRC Snapshot Timestamp";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snapshot Line Count" <> 0) and (SalesHeader."PRC Snap Line Count_DXR" = 0) then begin
                    SalesHeader."PRC Snap Line Count_DXR" := SalesHeader."PRC Snapshot Line Count";
                    Modified := true;
                end;
                if (SalesHeader."PRC Team Code" <> '') and (SalesHeader."PRC Team Code_DXR" = '') then begin
                    SalesHeader."PRC Team Code_DXR" := SalesHeader."PRC Team Code";
                    Modified := true;
                end;
                if (SalesHeader."PRC Team Name" <> '') and (SalesHeader."PRC Team Name_DXR" = '') then begin
                    SalesHeader."PRC Team Name_DXR" := SalesHeader."PRC Team Name";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snapshot Quote Doc Date" <> 0D) and (SalesHeader."PRC Snap Quote DocDt_DXR" = 0D) then begin
                    SalesHeader."PRC Snap Quote DocDt_DXR" := SalesHeader."PRC Snapshot Quote Doc Date";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snapshot Quote Post Date" <> 0D) and (SalesHeader."PRC Snap Quote PostDt_DXR" = 0D) then begin
                    SalesHeader."PRC Snap Quote PostDt_DXR" := SalesHeader."PRC Snapshot Quote Post Date";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesHeader."PRC Snap MkOrd WD_DXR" = 0D) then begin
                    SalesHeader."PRC Snap MkOrd WD_DXR" := SalesHeader."PRC Snap MakeOrder WorkDate";
                    Modified := true;
                end;
                if (SalesHeader."PRC Snap MakeOrder Today" <> 0D) and (SalesHeader."PRC Snap MkOrd Today_DXR" = 0D) then begin
                    SalesHeader."PRC Snap MkOrd Today_DXR" := SalesHeader."PRC Snap MakeOrder Today";
                    Modified := true;
                end;

                if Modified then
                    SalesHeader.Modify(false);
            until SalesHeader.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step7Tag());
    end;

    local procedure MigrateSalesLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesLine: Record "Sales Line";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(Step8Tag()) then
            exit;

        if SalesLine.FindSet(true) then
            repeat
                Modified := false;

                if SalesLine."Precio Menor A PrecioFijado" and not SalesLine."PrecMenorFijado_DXR" then begin
                    SalesLine."PrecMenorFijado_DXR" := true;
                    Modified := true;
                end;
                if (SalesLine."PRC Exempt Price" <> 0) and (SalesLine."PRC Exempt Price_DXR" = 0) then begin
                    SalesLine."PRC Exempt Price_DXR" := SalesLine."PRC Exempt Price";
                    Modified := true;
                end;
                if (SalesLine."PRC Store From Customer" <> '') and (SalesLine."PRC StoreFrmCust_DXR" = '') then begin
                    SalesLine."PRC StoreFrmCust_DXR" := SalesLine."PRC Store From Customer";
                    Modified := true;
                end;
                if (SalesLine."PRC Line Style" <> '') and (SalesLine."PRC Line Style_DXR" = '') then begin
                    SalesLine."PRC Line Style_DXR" := SalesLine."PRC Line Style";
                    Modified := true;
                end;
                if SalesLine."PRC Requires Price Approval" and not SalesLine."PRC ReqPrcAppr_DXR" then begin
                    SalesLine."PRC ReqPrcAppr_DXR" := true;
                    Modified := true;
                end;
                if SalesLine."PRC Customer Price Applied" and not SalesLine."PRC CustPrcAppl_DXR" then begin
                    SalesLine."PRC CustPrcAppl_DXR" := true;
                    Modified := true;
                end;
                if SalesLine."PRC Store Price Applied" and not SalesLine."PRC StorePrcAppl_DXR" then begin
                    SalesLine."PRC StorePrcAppl_DXR" := true;
                    Modified := true;
                end;
                if (SalesLine."PRC LSC Original Unit Price" <> 0) and (SalesLine."PRC LSC OrigUP_DXR" = 0) then begin
                    SalesLine."PRC LSC OrigUP_DXR" := SalesLine."PRC LSC Original Unit Price";
                    Modified := true;
                end;
                if SalesLine."PRC LSC Price Manual Change" and not SalesLine."PRC LSC Price Man Chg_DXR" then begin
                    SalesLine."PRC LSC Price Man Chg_DXR" := true;
                    Modified := true;
                end;
                if SalesLine."PRC LSC Disc Manual Change" and not SalesLine."PRC LSC Disc Man Chg_DXR" then begin
                    SalesLine."PRC LSC Disc Man Chg_DXR" := true;
                    Modified := true;
                end;
                if (SalesLine."PRC Approval Reason" <> '') and (SalesLine."PRC Approval Reason_DXR" = '') then begin
                    SalesLine."PRC Approval Reason_DXR" := SalesLine."PRC Approval Reason";
                    Modified := true;
                end;
                if SalesLine."PRC VAT Exempt" and not SalesLine."PRC VAT Exempt_DXR" then begin
                    SalesLine."PRC VAT Exempt_DXR" := true;
                    Modified := true;
                end;

                if (SalesLine."PRC Original Item No." <> '') and (SalesLine."PRC Orig Item No._DXR" = '') then begin
                    SalesLine."PRC Orig Item No._DXR" := SalesLine."PRC Original Item No.";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Quantity" <> 0) and (SalesLine."PRC Orig Quantity_DXR" = 0) then begin
                    SalesLine."PRC Orig Quantity_DXR" := SalesLine."PRC Original Quantity";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Unit Price" <> 0) and (SalesLine."PRC Orig Unit Price_DXR" = 0) then begin
                    SalesLine."PRC Orig Unit Price_DXR" := SalesLine."PRC Original Unit Price";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Amount Incl VAT" <> 0) and (SalesLine."PRC Orig AmtInclVAT_DXR" = 0) then begin
                    SalesLine."PRC Orig AmtInclVAT_DXR" := SalesLine."PRC Original Amount Incl VAT";
                    Modified := true;
                end;
                if (SalesLine."PRC Original VAT Percent" <> 0) and (SalesLine."PRC Orig VAT Pct_DXR" = 0) then begin
                    SalesLine."PRC Orig VAT Pct_DXR" := SalesLine."PRC Original VAT Percent";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Customer Price" <> 0) and (SalesLine."PRC Snap Cust Price_DXR" = 0) then begin
                    SalesLine."PRC Snap Cust Price_DXR" := SalesLine."PRC Snapshot Customer Price";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Store Price" <> 0) and (SalesLine."PRC Snap Store Price_DXR" = 0) then begin
                    SalesLine."PRC Snap Store Price_DXR" := SalesLine."PRC Snapshot Store Price";
                    Modified := true;
                end;
                if SalesLine."PRC Snapshot Line Approved" and not SalesLine."PRC Snap Line Appr_DXR" then begin
                    SalesLine."PRC Snap Line Appr_DXR" := true;
                    Modified := true;
                end;
                if (SalesLine."PRC Source Quote No." <> '') and (SalesLine."PRC Src Quote No._DXR" = '') then begin
                    SalesLine."PRC Src Quote No._DXR" := SalesLine."PRC Source Quote No.";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Timestamp" <> 0DT) and (SalesLine."PRC Snap Timestamp_DXR" = 0DT) then begin
                    SalesLine."PRC Snap Timestamp_DXR" := SalesLine."PRC Snapshot Timestamp";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Line Count" <> 0) and (SalesLine."PRC Snap Line Count_DXR" = 0) then begin
                    SalesLine."PRC Snap Line Count_DXR" := SalesLine."PRC Snapshot Line Count";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Quote Doc Date" <> 0D) and (SalesLine."PRC Snap QuoteDocDt_DXR" = 0D) then begin
                    SalesLine."PRC Snap QuoteDocDt_DXR" := SalesLine."PRC Snapshot Quote Doc Date";
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Quote Post Date" <> 0D) and (SalesLine."PRC Snap QuotePostDt_DXR" = 0D) then begin
                    SalesLine."PRC Snap QuotePostDt_DXR" := SalesLine."PRC Snapshot Quote Post Date";
                    Modified := true;
                end;
                if (SalesLine."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesLine."PRC Snap MkOrd WD_DXR" = 0D) then begin
                    SalesLine."PRC Snap MkOrd WD_DXR" := SalesLine."PRC Snap MakeOrder WorkDate";
                    Modified := true;
                end;
                if (SalesLine."PRC Snap MakeOrder Today" <> 0D) and (SalesLine."PRC Snap MkOrdToday_DXR" = 0D) then begin
                    SalesLine."PRC Snap MkOrdToday_DXR" := SalesLine."PRC Snap MakeOrder Today";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Net Amount" <> 0) and (SalesLine."PRC Orig Net Amt_DXR" = 0) then begin
                    SalesLine."PRC Orig Net Amt_DXR" := SalesLine."PRC Original Net Amount";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Line Disc. %" <> 0) and (SalesLine."PRC Orig LinDisc %_DXR" = 0) then begin
                    SalesLine."PRC Orig LinDisc %_DXR" := SalesLine."PRC Original Line Disc. %";
                    Modified := true;
                end;
                if (SalesLine."PRC Original Line Disc. Amt" <> 0) and (SalesLine."PRC Orig LinDisc Amt_DXR" = 0) then begin
                    SalesLine."PRC Orig LinDisc Amt_DXR" := SalesLine."PRC Original Line Disc. Amt";
                    Modified := true;
                end;
                if SalesLine."PRC Snapshot VAT Exempt" and not SalesLine."PRC Snap VAT Exempt_DXR" then begin
                    SalesLine."PRC Snap VAT Exempt_DXR" := true;
                    Modified := true;
                end;
                if (SalesLine."PRC Snapshot Exempt Price" <> 0) and (SalesLine."PRC Snap ExemptPrc_DXR" = 0) then begin
                    SalesLine."PRC Snap ExemptPrc_DXR" := SalesLine."PRC Snapshot Exempt Price";
                    Modified := true;
                end;

                if Modified then
                    SalesLine.Modify(false);
            until SalesLine.Next() = 0;

        UpgradeTag.SetUpgradeTag(Step8Tag());
    end;
#pragma warning restore AL0432

    local procedure Step1Tag(): Code[250]
    begin
        exit('DXR-Phase5Step1PricesCtrlSetup-28.3.0.0');
    end;

    local procedure Step2Tag(): Code[250]
    begin
        exit('DXR-Phase5Step2ApprovalHistory-28.3.0.0');
    end;

    local procedure Step3Tag(): Code[250]
    begin
        exit('DXR-Phase5Step3ApprovalEntry-28.3.0.0');
    end;

    local procedure Step4Tag(): Code[250]
    begin
        exit('DXR-Phase5Step4Customer-28.3.0.0');
    end;

    local procedure Step5Tag(): Code[250]
    begin
        exit('DXR-Phase5Step5StorePrcGrp-28.3.0.0');
    end;

    local procedure Step6Tag(): Code[250]
    begin
        exit('DXR-Phase5Step6Workflow-28.3.0.0');
    end;

    local procedure Step7Tag(): Code[250]
    begin
        exit('DXR-Phase5Step7SalesHeader-28.3.0.0');
    end;

    local procedure Step8Tag(): Code[250]
    begin
        exit('DXR-Phase5Step8SalesLine-28.3.0.0');
    end;
}
