#if not ESCUDEA and not BCDX
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
        RunAccounting();
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
    end;

    procedure RunAccounting()
    begin
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

    local procedure BatchSize(): Integer
    begin
        exit(500);
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
        RowCounter: Integer;
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
        if OldHistory.FindSet(false) then
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

                RowCounter += 1;
                if RowCounter >= BatchSize() then begin
                    Commit();
                    RowCounter := 0;
                end;
            until OldHistory.Next() = 0;
        Commit();

        UpgradeTag.SetUpgradeTag(Step2Tag());
    end;

    local procedure MigrateApprovalEntryFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ApprovalEntry: Record "Approval Entry";
        ApprovalEntryToUpdate: Record "Approval Entry";
        Modified: Boolean;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step3Tag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) over the WHOLE Approval Entry table took an UPDLOCK on every
        // row for the entire run while only a minority need a copy. Now SetLoadFields (PK + the 6
        // fields touched) + FindSet(false) (no UPDLOCK), the row is re-read with Get() and locked only
        // when it really needs a change, and the commit counter advances per MODIFIED row.
        ApprovalEntry.SetLoadFields(
            "Entry No.",
            "Workflow Code", "Workflow Code_DXR",
            "Workflow Instance ID", "Workflow Instance ID_DXR",
            "Posting Date", "Posting Date_DXR");
        if ApprovalEntry.FindSet(false) then begin
            repeat
                Modified :=
                    ((ApprovalEntry."Workflow Code" <> '') and (ApprovalEntry."Workflow Code_DXR" = '')) or
                    ((not IsNullGuid(ApprovalEntry."Workflow Instance ID")) and IsNullGuid(ApprovalEntry."Workflow Instance ID_DXR")) or
                    ((ApprovalEntry."Posting Date" <> 0D) and (ApprovalEntry."Posting Date_DXR" = 0D));

                if Modified then
                    if ApprovalEntryToUpdate.Get(ApprovalEntry."Entry No.") then begin
                        if (ApprovalEntryToUpdate."Workflow Code" <> '') and (ApprovalEntryToUpdate."Workflow Code_DXR" = '') then
                            ApprovalEntryToUpdate."Workflow Code_DXR" := ApprovalEntryToUpdate."Workflow Code";
                        if (not IsNullGuid(ApprovalEntryToUpdate."Workflow Instance ID")) and IsNullGuid(ApprovalEntryToUpdate."Workflow Instance ID_DXR") then
                            ApprovalEntryToUpdate."Workflow Instance ID_DXR" := ApprovalEntryToUpdate."Workflow Instance ID";
                        if (ApprovalEntryToUpdate."Posting Date" <> 0D) and (ApprovalEntryToUpdate."Posting Date_DXR" = 0D) then
                            ApprovalEntryToUpdate."Posting Date_DXR" := ApprovalEntryToUpdate."Posting Date";

                        ApprovalEntryToUpdate.Modify(false);

                        RowCounter += 1;
                        if RowCounter >= BatchSize() then begin
                            Commit();
                            RowCounter := 0;
                        end;
                    end;
            until ApprovalEntry.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(Step3Tag());
    end;

    local procedure MigrateCustomerFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Customer: Record Customer;
        CustomerToUpdate: Record Customer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step4Tag()) then
            exit;

        // Fixed 2026-08-27: same fix as "DXR MCC BC Migr P3 Customer" - FindSet(true) took an UPDLOCK
        // on every customer with a "PRC Store" for the whole run, including those already filled.
        // SetLoadFields limits the read to the 3 fields touched (Customer carries many tableextensions
        // in this portfolio), FindSet(false) drops the lock, and the row is re-read with Get() and
        // locked only when it really needs the copy. Commit counter per MODIFIED row.
        Customer.SetLoadFields("No.", "PRC Store", "PRC Store_DXR");
        Customer.SetFilter("PRC Store", '<>%1', '');
        if Customer.FindSet(false) then begin
            repeat
                if Customer."PRC Store_DXR" = '' then
                    if CustomerToUpdate.Get(Customer."No.") then
                        if CustomerToUpdate."PRC Store_DXR" = '' then begin
                            CustomerToUpdate."PRC Store_DXR" := CustomerToUpdate."PRC Store";
                            CustomerToUpdate.Modify(false);

                            RowCounter += 1;
                            if RowCounter >= BatchSize() then begin
                                Commit();
                                RowCounter := 0;
                            end;
                        end;
            until Customer.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(Step4Tag());
    end;

    local procedure MigrateStorePriceGroupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        StorePriceGroup: Record "LSC Store Price Group";
        StorePriceGroupToUpdate: Record "LSC Store Price Group";
        Modified: Boolean;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step5Tag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) over the WHOLE LSC Store Price Group table took an UPDLOCK
        // on every row for the entire run even though only rows with a legacy flag set change. Now:
        // SetLoadFields (PK + the 6 fields touched), FindSet(false) without the lock, and the row is
        // re-read with Get() and locked only when it really needs a change; commit per MODIFIED row.
        StorePriceGroup.SetLoadFields(
            Store, "Price Group Code",
            "PRC Precio Fijado", "PRC Precio Fijado_DXR",
            "PRC Excluir Store Prices", "PRC ExclStorePrc_DXR",
            "PRC Excluir Cust. Prices", "PRC ExclCustPrc_DXR");
        if StorePriceGroup.FindSet(false) then begin
            repeat
                Modified :=
                    (StorePriceGroup."PRC Precio Fijado" and not StorePriceGroup."PRC Precio Fijado_DXR") or
                    (StorePriceGroup."PRC Excluir Store Prices" and not StorePriceGroup."PRC ExclStorePrc_DXR") or
                    (StorePriceGroup."PRC Excluir Cust. Prices" and not StorePriceGroup."PRC ExclCustPrc_DXR");

                if Modified then
                    if StorePriceGroupToUpdate.Get(StorePriceGroup.Store, StorePriceGroup."Price Group Code") then begin
                        if StorePriceGroupToUpdate."PRC Precio Fijado" and not StorePriceGroupToUpdate."PRC Precio Fijado_DXR" then
                            StorePriceGroupToUpdate."PRC Precio Fijado_DXR" := true;
                        if StorePriceGroupToUpdate."PRC Excluir Store Prices" and not StorePriceGroupToUpdate."PRC ExclStorePrc_DXR" then
                            StorePriceGroupToUpdate."PRC ExclStorePrc_DXR" := true;
                        if StorePriceGroupToUpdate."PRC Excluir Cust. Prices" and not StorePriceGroupToUpdate."PRC ExclCustPrc_DXR" then
                            StorePriceGroupToUpdate."PRC ExclCustPrc_DXR" := true;

                        StorePriceGroupToUpdate.Modify(false);

                        RowCounter += 1;
                        if RowCounter >= BatchSize() then begin
                            Commit();
                            RowCounter := 0;
                        end;
                    end;
            until StorePriceGroup.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(Step5Tag());
    end;

    local procedure MigrateWorkflowFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Workflow: Record Workflow;
        WorkflowToUpdate: Record Workflow;
        Modified: Boolean;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step6Tag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) took an UPDLOCK on every Workflow row for the whole run.
        // SetLoadFields (PK + the 4 fields touched) + FindSet(false) reads without the lock, and the
        // row is re-read with Get() and locked only when it really needs a change; commit per
        // MODIFIED row.
        Workflow.SetLoadFields(
            "Code",
            "PRC Approval Type", "DXR_Approval Type",
            "PRC Approval Type_DXR_Old", "PRC Approval Type_DXR");
        if Workflow.FindSet(false) then begin
            repeat
                Modified :=
                    ((Workflow."PRC Approval Type" <> Workflow."PRC Approval Type"::All) and
                     (Workflow."DXR_Approval Type" = Workflow."DXR_Approval Type"::All)) or
                    ((Workflow."PRC Approval Type_DXR_Old" <> Workflow."PRC Approval Type_DXR_Old"::All) and
                     (Workflow."PRC Approval Type_DXR" = Workflow."PRC Approval Type_DXR"::All));

                if Modified then
                    if WorkflowToUpdate.Get(Workflow."Code") then begin
                        if (WorkflowToUpdate."PRC Approval Type" <> WorkflowToUpdate."PRC Approval Type"::All) and
                           (WorkflowToUpdate."DXR_Approval Type" = WorkflowToUpdate."DXR_Approval Type"::All)
                        then
                            WorkflowToUpdate."DXR_Approval Type" := WorkflowToUpdate."PRC Approval Type";

                        if (WorkflowToUpdate."PRC Approval Type_DXR_Old" <> WorkflowToUpdate."PRC Approval Type_DXR_Old"::All) and
                           (WorkflowToUpdate."PRC Approval Type_DXR" = WorkflowToUpdate."PRC Approval Type_DXR"::All)
                        then
                            WorkflowToUpdate."PRC Approval Type_DXR" := WorkflowToUpdate."PRC Approval Type_DXR_Old";

                        WorkflowToUpdate.Modify(false);

                        RowCounter += 1;
                        if RowCounter >= BatchSize() then begin
                            Commit();
                            RowCounter := 0;
                        end;
                    end;
            until Workflow.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(Step6Tag());
    end;

    local procedure MigrateSalesHeaderSnapshotFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesHeader: Record "Sales Header";
        SalesHeaderToUpdate: Record "Sales Header";
        Modified: Boolean;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step7Tag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) took an UPDLOCK on every snapshot-enabled sales document for
        // the whole run, blocking normal document activity, while only the rows still missing a _DXR
        // value need a write. Now: SetLoadFields (PK + exactly the fields touched - Sales Header
        // carries many tableextensions in this portfolio), FindSet(false) without the lock, and the
        // row is re-read with Get() and locked only when it really needs a change; commit per
        // MODIFIED row. Same filter, same fields, same fill-only-if-blank guards.
        SalesHeader.SetLoadFields(
            "Document Type", "No.",
            "PRC Snapshot Enabled", "PRC Snapshot Enabled_DXR",
            "PRC Source Quote No.", "PRC Src Quote No._DXR",
            "PRC Snapshot Timestamp", "PRC Snap Timestamp_DXR",
            "PRC Snapshot Line Count", "PRC Snap Line Count_DXR",
            "PRC Team Code", "PRC Team Code_DXR",
            "PRC Team Name", "PRC Team Name_DXR",
            "PRC Snapshot Quote Doc Date", "PRC Snap Quote DocDt_DXR",
            "PRC Snapshot Quote Post Date", "PRC Snap Quote PostDt_DXR",
            "PRC Snap MakeOrder WorkDate", "PRC Snap MkOrd WD_DXR",
            "PRC Snap MakeOrder Today", "PRC Snap MkOrd Today_DXR");
        SalesHeader.SetRange("PRC Snapshot Enabled", true);
        if SalesHeader.FindSet(false) then begin
            repeat
                Modified :=
                    (not SalesHeader."PRC Snapshot Enabled_DXR") or
                    ((SalesHeader."PRC Source Quote No." <> '') and (SalesHeader."PRC Src Quote No._DXR" = '')) or
                    ((SalesHeader."PRC Snapshot Timestamp" <> 0DT) and (SalesHeader."PRC Snap Timestamp_DXR" = 0DT)) or
                    ((SalesHeader."PRC Snapshot Line Count" <> 0) and (SalesHeader."PRC Snap Line Count_DXR" = 0)) or
                    ((SalesHeader."PRC Team Code" <> '') and (SalesHeader."PRC Team Code_DXR" = '')) or
                    ((SalesHeader."PRC Team Name" <> '') and (SalesHeader."PRC Team Name_DXR" = '')) or
                    ((SalesHeader."PRC Snapshot Quote Doc Date" <> 0D) and (SalesHeader."PRC Snap Quote DocDt_DXR" = 0D)) or
                    ((SalesHeader."PRC Snapshot Quote Post Date" <> 0D) and (SalesHeader."PRC Snap Quote PostDt_DXR" = 0D)) or
                    ((SalesHeader."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesHeader."PRC Snap MkOrd WD_DXR" = 0D)) or
                    ((SalesHeader."PRC Snap MakeOrder Today" <> 0D) and (SalesHeader."PRC Snap MkOrd Today_DXR" = 0D));

                if Modified then
                    if SalesHeaderToUpdate.Get(SalesHeader."Document Type", SalesHeader."No.") then begin
                        if not SalesHeaderToUpdate."PRC Snapshot Enabled_DXR" then
                            SalesHeaderToUpdate."PRC Snapshot Enabled_DXR" := SalesHeaderToUpdate."PRC Snapshot Enabled";
                        if (SalesHeaderToUpdate."PRC Source Quote No." <> '') and (SalesHeaderToUpdate."PRC Src Quote No._DXR" = '') then
                            SalesHeaderToUpdate."PRC Src Quote No._DXR" := SalesHeaderToUpdate."PRC Source Quote No.";
                        if (SalesHeaderToUpdate."PRC Snapshot Timestamp" <> 0DT) and (SalesHeaderToUpdate."PRC Snap Timestamp_DXR" = 0DT) then
                            SalesHeaderToUpdate."PRC Snap Timestamp_DXR" := SalesHeaderToUpdate."PRC Snapshot Timestamp";
                        if (SalesHeaderToUpdate."PRC Snapshot Line Count" <> 0) and (SalesHeaderToUpdate."PRC Snap Line Count_DXR" = 0) then
                            SalesHeaderToUpdate."PRC Snap Line Count_DXR" := SalesHeaderToUpdate."PRC Snapshot Line Count";
                        if (SalesHeaderToUpdate."PRC Team Code" <> '') and (SalesHeaderToUpdate."PRC Team Code_DXR" = '') then
                            SalesHeaderToUpdate."PRC Team Code_DXR" := SalesHeaderToUpdate."PRC Team Code";
                        if (SalesHeaderToUpdate."PRC Team Name" <> '') and (SalesHeaderToUpdate."PRC Team Name_DXR" = '') then
                            SalesHeaderToUpdate."PRC Team Name_DXR" := SalesHeaderToUpdate."PRC Team Name";
                        if (SalesHeaderToUpdate."PRC Snapshot Quote Doc Date" <> 0D) and (SalesHeaderToUpdate."PRC Snap Quote DocDt_DXR" = 0D) then
                            SalesHeaderToUpdate."PRC Snap Quote DocDt_DXR" := SalesHeaderToUpdate."PRC Snapshot Quote Doc Date";
                        if (SalesHeaderToUpdate."PRC Snapshot Quote Post Date" <> 0D) and (SalesHeaderToUpdate."PRC Snap Quote PostDt_DXR" = 0D) then
                            SalesHeaderToUpdate."PRC Snap Quote PostDt_DXR" := SalesHeaderToUpdate."PRC Snapshot Quote Post Date";
                        if (SalesHeaderToUpdate."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesHeaderToUpdate."PRC Snap MkOrd WD_DXR" = 0D) then
                            SalesHeaderToUpdate."PRC Snap MkOrd WD_DXR" := SalesHeaderToUpdate."PRC Snap MakeOrder WorkDate";
                        if (SalesHeaderToUpdate."PRC Snap MakeOrder Today" <> 0D) and (SalesHeaderToUpdate."PRC Snap MkOrd Today_DXR" = 0D) then
                            SalesHeaderToUpdate."PRC Snap MkOrd Today_DXR" := SalesHeaderToUpdate."PRC Snap MakeOrder Today";

                        SalesHeaderToUpdate.Modify(false);

                        RowCounter += 1;
                        if RowCounter >= BatchSize() then begin
                            Commit();
                            RowCounter := 0;
                        end;
                    end;
            until SalesHeader.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(Step7Tag());
    end;

    local procedure MigrateSalesLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesLine: Record "Sales Line";
        SalesLineToUpdate: Record "Sales Line";
        Modified: Boolean;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(Step8Tag()) then
            exit;

        // Fixed 2026-08-27: this was the worst offender of the phase - FindSet(true) over the WHOLE
        // Sales Line table took an UPDLOCK on every open sales line for the entire run, blocking all
        // normal sales activity, while only lines with a legacy value still to copy need a write.
        // Now: SetLoadFields with exactly the fields touched (Sales Line is the widest table here and
        // carries many tableextensions - without a partial record every companion table was joined per
        // row), FindSet(false) without the lock, and the row is re-read with Get() and locked only
        // when it really needs a change; commit counter per MODIFIED row. Same fields, same guards.
        SalesLine.SetLoadFields(
            "Document Type", "Document No.", "Line No.",
            "Precio Menor A PrecioFijado", "PrecMenorFijado_DXR",
            "PRC Exempt Price", "PRC Exempt Price_DXR",
            "PRC Store From Customer", "PRC StoreFrmCust_DXR",
            "PRC Line Style", "PRC Line Style_DXR",
            "PRC Requires Price Approval", "PRC ReqPrcAppr_DXR",
            "PRC Customer Price Applied", "PRC CustPrcAppl_DXR",
            "PRC Store Price Applied", "PRC StorePrcAppl_DXR",
            "PRC LSC Original Unit Price", "PRC LSC OrigUP_DXR",
            "PRC LSC Price Manual Change", "PRC LSC Price Man Chg_DXR",
            "PRC LSC Disc Manual Change", "PRC LSC Disc Man Chg_DXR",
            "PRC Approval Reason", "PRC Approval Reason_DXR",
            "PRC VAT Exempt", "PRC VAT Exempt_DXR",
            "PRC Original Item No.", "PRC Orig Item No._DXR",
            "PRC Original Quantity", "PRC Orig Quantity_DXR",
            "PRC Original Unit Price", "PRC Orig Unit Price_DXR",
            "PRC Original Amount Incl VAT", "PRC Orig AmtInclVAT_DXR",
            "PRC Original VAT Percent", "PRC Orig VAT Pct_DXR",
            "PRC Snapshot Customer Price", "PRC Snap Cust Price_DXR",
            "PRC Snapshot Store Price", "PRC Snap Store Price_DXR",
            "PRC Snapshot Line Approved", "PRC Snap Line Appr_DXR",
            "PRC Source Quote No.", "PRC Src Quote No._DXR",
            "PRC Snapshot Timestamp", "PRC Snap Timestamp_DXR",
            "PRC Snapshot Line Count", "PRC Snap Line Count_DXR",
            "PRC Snapshot Quote Doc Date", "PRC Snap QuoteDocDt_DXR",
            "PRC Snapshot Quote Post Date", "PRC Snap QuotePostDt_DXR",
            "PRC Snap MakeOrder WorkDate", "PRC Snap MkOrd WD_DXR",
            "PRC Snap MakeOrder Today", "PRC Snap MkOrdToday_DXR",
            "PRC Original Net Amount", "PRC Orig Net Amt_DXR",
            "PRC Original Line Disc. %", "PRC Orig LinDisc %_DXR",
            "PRC Original Line Disc. Amt", "PRC Orig LinDisc Amt_DXR",
            "PRC Snapshot VAT Exempt", "PRC Snap VAT Exempt_DXR",
            "PRC Snapshot Exempt Price", "PRC Snap ExemptPrc_DXR");
        if SalesLine.FindSet(false) then
            repeat
                // Fixed 2026-08-27 (2/2, corregido tras revision adversarial): la version anterior
                // evaluaba los guards sobre la copia SIN bloqueo y despues copiaba los 32 campos _DXR
                // de ese snapshot a la fila bloqueada, a ciegas. Eso es una perdida de actualizacion:
                // si otra sesion escribia cualquiera de esos 32 campos entre la lectura sin lock y el
                // Get(), su valor se revertia al snapshot viejo - y quitar el UPDLOCK asume
                // precisamente que hay actividad de ventas concurrente. Ahora los MISMOS guards se
                // reevaluan sobre la fila releida bajo bloqueo (ApplySalesLineMigration se llama dos
                // veces: una para detectar sobre la copia libre, otra para aplicar sobre la bloqueada),
                // asi que solo se escribe lo que sigue haciendo falta en la fila real.
                if ApplySalesLineMigration(SalesLine) then
                    if SalesLineToUpdate.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.") then
                        if ApplySalesLineMigration(SalesLineToUpdate) then begin
                            SalesLineToUpdate.Modify(false);

                            RowCounter += 1;
                            if RowCounter >= BatchSize() then begin
                                Commit();
                                RowCounter := 0;
                            end;
                        end;
            until SalesLine.Next() = 0;

        if RowCounter > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(Step8Tag());
    end;

    /// <summary>
    /// Aplica los guards de migracion de "Sales Line" sobre el registro recibido y devuelve true si
    /// cambio algo. Se llama DOS veces por fila: sobre la copia leida sin bloqueo (para detectar si
    /// la fila necesita trabajo, sin bloquear nada) y sobre la misma fila releida bajo bloqueo con
    /// Get() (para aplicar). Extraido 2026-08-27 para que ambas evaluaciones usen literalmente la
    /// misma logica y no pueda divergir una copia del snapshot.
    /// </summary>
    local procedure ApplySalesLineMigration(var SalesLine: Record "Sales Line"): Boolean
    var
        Modified: Boolean;
    begin

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
        exit(Modified);
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

#endif
