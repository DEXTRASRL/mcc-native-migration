/*
codeunit 60128 "DXR MCC DESB Migr Phase2"
{
    // Native local migration - ported verbatim from Despacho Base's own "DXR_Despacho Migr Phase
    // 2" (53908) AND "DXR_Despacho Migr Phase 1" (53670), bundled here in that exact order. The
    // sibling's own Dispatcher (RunPendingPhasesWithStatusTracking) deliberately runs Phase 2
    // BEFORE Phase 1: Phase 1's own Sales Header/Sales Line/Sales Invoice Line steps read only the
    // "_Old2"/"_Reloc" fields that Phase 2 populates from the live "DXR_"/"_DXR" fields before
    // those get marked ObsoleteState = Removed (a real TransferFields ID collision fix, see
    // SalesHeaderExt/TransferHeaderExt/SalesLineExt.TableExt.al). Running Phase 1 first would
    // propagate empty values for those specific fields. Phase 1's remaining 27 tables have no such
    // dependency, but the whole set is bundled here (not split across codeunits) precisely to keep
    // this ordering guarantee unconditional and impossible to violate via MCC's own registry
    // Sequence No. ordering - unlike the sibling's original delegation chain (Dispatcher), MCC's
    // registry has no equivalent single-call orchestration point once each phase becomes its own
    // adapter, so the safe order has to be baked into one codeunit's OnRun instead.
    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Transfer Header" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata Customer = RM,
        tabledata "Approval Entry" = RM,
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Shipment Header" = RM,
        tabledata "Transfer Shipment Header" = RM,
        tabledata "Fixed Asset" = RM,
        tabledata Item = RM,
        tabledata "Item Journal Line" = RM,
        tabledata "Item Ledger Entry" = RM,
        tabledata Location = RM,
        tabledata "Payment Method" = RM,
        tabledata "Posted Whse. Receipt Header" = RM,
        tabledata "Posted Whse. Shipment Header" = RM,
        tabledata "Purch. Rcpt. Header" = RM,
        tabledata "Purchase Header" = RM,
        tabledata "Reason Code" = RM,
        tabledata "Ship-to Address" = RM,
        tabledata "Shipment Method" = RM,
        tabledata "Transfer Receipt Header" = RM,
        tabledata "User Setup" = RM,
        tabledata "Value Entry" = RM,
        tabledata "Warehouse Receipt Header" = RM,
        tabledata "Warehouse Shipment Header" = RM;

    trigger OnRun()
    begin
        // --- Phase 2 (must run first - see header comment) ---
        MigrateSalesHeaderCollision();
        MigrateTransferHeaderCollision();
        MigrateSalesLineCollision();
        MigrateSalesInvoiceLineCollision();

        // --- Phase 1 ---
        MigrateTable_Customer();
        MigrateTable_ApprovalEntry();
        MigrateTable_SalesCrMemoHeader();
        MigrateTable_SalesInvoiceHeader();
        MigrateTable_SalesInvoiceLine();
        MigrateTable_SalesShipmentHeader();
        MigrateTable_TransferShipmentHeader();
        MigrateTable_FixedAsset();
        MigrateTable_Item();
        MigrateTable_ItemJournalLine();
        MigrateTable_ItemLedgerEntry();
        MigrateTable_Location();
        MigrateTable_PaymentMethod();
        MigrateTable_PostedWhseReceiptHeader();
        MigrateTable_PostedWhseShipmentHeader();
        MigrateTable_PurchRcptHeader();
        MigrateTable_PurchaseHeader();
        MigrateTable_ReasonCode();
        MigrateTable_SalesHeader();
        MigrateTable_SalesLine();
        MigrateTable_ShipToAddress();
        MigrateTable_ShipmentMethod();
        MigrateTable_TransferHeader();
        MigrateTable_TransferReceiptHeader();
        MigrateTable_UserSetup();
        MigrateTable_ValueEntry();
        MigrateTable_WarehouseReceiptHeader();
        MigrateTable_WarehouseShipmtHeader();
    end;

    // ===== Phase 2: TransferFields ID collision fix =====

    // Sales Header's 6 collision-source fields ("...DXR" suffix, 53664-53669) carry no
    // ObsoleteState - confirmed against DESB's current SalesHeaderExt.TableExt.al - so this
    // procedure converts cleanly to typed Record access.
    local procedure MigrateSalesHeaderCollision()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesHeaderRec: Record "Sales Header";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESHEADER-28.3-20260822') then
            exit;

        if SalesHeaderRec.FindSet(true) then
            repeat
                SalesHeaderRec."DXR_DiscountAppliedLS_Old2" := SalesHeaderRec."DiscountAppliedLS_DXR";
                SalesHeaderRec."DXR_DiscountByLS_Old2" := SalesHeaderRec."DiscountByLS_DXR";
                SalesHeaderRec."DXR_Ruta_Old2" := SalesHeaderRec."Ruta_DXR";
                SalesHeaderRec."DXR_Sent Pickup_Old2" := SalesHeaderRec."Sent Pickup_DXR";
                SalesHeaderRec."DXR_Shipment_Old2" := SalesHeaderRec."Shipment_DXR";
                SalesHeaderRec."DXR_Tipo_Old2" := SalesHeaderRec."Tipo_DXR";
                SalesHeaderRec.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SalesHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESHEADER-28.3-20260822');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    var
        CandidateField: FieldRef;
        SourceField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
        SourceFound: Boolean;
        TargetFound: Boolean;
    begin
        // Resolve the published identities once through metadata, then copy by the resolved field
        // names. This avoids direct Field(ID) dereferencing and validates the physical types.
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            CandidateField := RecRef.FieldIndex(FieldIndex);
            if CandidateField.Number() = OldFieldNo then begin
                SourceField := CandidateField;
                SourceFound := true;
            end;
            if CandidateField.Number() = NewFieldNo then begin
                TargetField := CandidateField;
                TargetFound := true;
            end;
        end;
        if not SourceFound or not TargetFound then
            exit;
        if (SourceField.Class() <> FieldClass::Normal) or
           (TargetField.Class() <> FieldClass::Normal) or
           (SourceField.Type() <> TargetField.Type())
        then
            exit;

        SourceField := RecRef.Field(SourceField.Name());
        TargetField := RecRef.Field(TargetField.Name());
        TargetField.Value := SourceField.Value();
    end;

    // Cannot be converted to typed Record access: independently verified against DESB's current
    // TransferHeaderExt.TableExt.al that ALL 14 collision-source fields on "Transfer Header"
    // (both the "DXR-DE ..." generation, now renumbered to 50800-50806, and the "..._DXR"-suffix
    // generation at 53659/53666-53671) carry ObsoleteState = Removed - AL blocks any typed field
    // reference to a Removed field at compile time (only RecordRef/FieldRef dynamic access can
    // still reach the physical column), so RecordRef is retained here out of necessity, not
    // preference. See desb-recordref-cleanup-report.md for the full field-ID audit.
    //
    // Also fixes a real data-loss bug found during that audit: 7 of these 14 OldFieldNo values
    // (the "DXR-DE ..." generation) were still hardcoded to their PRE-renumbering IDs
    // (53658/53660-53665), none of which exist on the table anymore - CopyFieldIfExists's own
    // FieldExist() guard silently no-op'd every one of those 7 copies, every run, so their live
    // data was never actually relocated to its "_Reloc" target despite TransferHeaderExt.TableExt.al's
    // own ObsoleteReason text asserting this codeunit already does so. Corrected to the fields'
    // real, current IDs (50800-50806) below.
    local procedure MigrateTransferHeaderCollision()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RecRef: RecordRef;
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase2-TRANSFERHEADER-28.3') then
            exit;

        RecRef.Open(Database::"Transfer Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50801, 53885); // DXR-DE Codigo Auditoria -> DXR_Codigo Auditoria_Reloc
                CopyFieldIfExists(RecRef, 53659, 53886); // Despachador Original_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 50800, 53887); // DXR-DE No. Despachador -> DXR_No. Despachador_Reloc
                CopyFieldIfExists(RecRef, 50803, 53888); // DXR-DE Order Date Created -> DXR_Order Date Created_Reloc
                CopyFieldIfExists(RecRef, 50802, 53889); // DXR-DE Order User Id -> DXR_Order User Id_Reloc
                CopyFieldIfExists(RecRef, 50806, 53890); // DXR-DE Original Trans. Date -> DXR_Original Trans. Date_Reloc
                CopyFieldIfExists(RecRef, 50805, 53891); // DXR-DE Original Transfer No. -> DXR_Orig Transfer No._Reloc
                CopyFieldIfExists(RecRef, 50804, 53892); // DXR-DE Despachador Original -> DXR_Despachador Original_Reloc
                CopyFieldIfExists(RecRef, 53666, 53893); // Codigo Auditoria_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 53667, 53894); // No. Despachador_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 53668, 53895); // Order Date Created_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 53669, 53896); // Order User Id_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 53670, 53897); // Original Trans. Date_DXR -> _Reloc
                CopyFieldIfExists(RecRef, 53671, 53898); // Original Transfer No._DXR -> _Reloc
                RecRef.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase2-TRANSFERHEADER-28.3');
    end;

    // Cannot be converted to typed Record access: the only collision-source field, "DXR-DE
    // DiscountByLS", carries ObsoleteState = Removed on DESB's current SalesLineExt.TableExt.al
    // (at field 50802). Also corrects the same class of stale-ID bug as MigrateTransferHeaderCollision
    // above - OldFieldNo was hardcoded to 53658 (a field that doesn't exist on "Sales Line" at all;
    // SalesLineExt.TableExt.al's own comment confirms 53658 has never meant "DiscountByLS" outside a
    // reverted WIP branch), so this copy was a permanent no-op. Corrected to field 50802.
    local procedure MigrateSalesLineCollision()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RecRef: RecordRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESLINE-28.3') then
            exit;

        RecRef.Open(Database::"Sales Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50802, 53899); // DXR-DE DiscountByLS -> DXR_DiscountByLS_Old2
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESLINE-28.3');
    end;

    // Cannot be converted to typed Record access: the only collision-source field, "DXR Package
    // Quantity", carries ObsoleteState = Removed on DESB's current DXRDESalesInvLineExt.TableExt.al
    // (at field 50800). Same stale-ID bug as above - OldFieldNo was hardcoded to 53658 (doesn't
    // exist on "Sales Invoice Line"; DXRDESalesInvLineExt.TableExt.al's own comment confirms this
    // field has never lived at 53658 outside a reverted WIP branch), so this copy was a permanent
    // no-op. Corrected to field 50800.
    local procedure MigrateSalesInvoiceLineCollision()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RecRef: RecordRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESINVLINE_COLLISION-28.3') then
            exit;

        RecRef.Open(Database::"Sales Invoice Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50800, 53900); // DXR Package Quantity -> _Old2
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase2-SALESINVLINE_COLLISION-28.3');
    end;

    // ===== Phase 1: DXR_-prefix -> _DXR-suffix field duplication (28 tables) =====

    local procedure MigrateTable_Customer()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        CustomerRec: Record Customer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-CUSTOMER-28.3') then
            exit;

        if CustomerRec.FindSet(true) then
            repeat
                CustomerRec."Clasific. Cliente ABC_DXR" := CustomerRec."DXR-DE Clasific. Cliente ABC";
                CustomerRec."Ruta_DXR" := CustomerRec."DXR-DE Ruta";
                CustomerRec.Modify(false);
            until CustomerRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-CUSTOMER-28.3');
    end;

    local procedure MigrateTable_ApprovalEntry()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ApprovalEntryRec: Record "Approval Entry";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-APPROVALENTRY-28.3') then
            exit;

        if ApprovalEntryRec.FindSet(true) then
            repeat
                ApprovalEntryRec."Aprobacion Inmediata_DXR" := ApprovalEntryRec."DXR-DE Aprobacion Inmediata";
                ApprovalEntryRec."ID_DXR" := ApprovalEntryRec."DXR-DE ID";
                ApprovalEntryRec.Modify(false);
            until ApprovalEntryRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-APPROVALENTRY-28.3');
    end;

    local procedure MigrateTable_SalesCrMemoHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesCrMemoHeaderRec: Record "Sales Cr.Memo Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESCRMEMOHDR-28.3') then
            exit;

        if SalesCrMemoHeaderRec.FindSet(true) then
            repeat
                SalesCrMemoHeaderRec."Sent Pickup_DXR" := SalesCrMemoHeaderRec."DXR-DE Sent Pickup";
                SalesCrMemoHeaderRec."Ruta_DXR" := SalesCrMemoHeaderRec."DXR-DE Ruta";
                SalesCrMemoHeaderRec.Modify(false);
            until SalesCrMemoHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESCRMEMOHDR-28.3');
    end;

    local procedure MigrateTable_SalesInvoiceHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesInvoiceHeaderRec: Record "Sales Invoice Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESINVHEADER-28.3') then
            exit;

        // Field 50807 "DXR-DE Entregada CxC" / 50810 "Entregada CxC_DXR" are both FlowFields
        // (CalcFormula Exist(...)). Their values are calculated and cannot be persisted.
        if SalesInvoiceHeaderRec.FindSet(true) then
            repeat
                SalesInvoiceHeaderRec."Sent Pickup_DXR" := SalesInvoiceHeaderRec."DXR-DE Sent Pickup";
                SalesInvoiceHeaderRec."Ruta_DXR" := SalesInvoiceHeaderRec."DXR-DE Ruta";
                SalesInvoiceHeaderRec.Modify(false);
            until SalesInvoiceHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESINVHEADER-28.3');
    end;

    local procedure MigrateTable_SalesInvoiceLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesInvoiceLineRec: Record "Sales Invoice Line";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESINVLINE-28.3') then
            exit;

        // Reads from "DXR Package Quantity_Old2" (53900), not the original "DXR Package Quantity"
        // (53658, now ObsoleteState = Removed) - relocated by Phase 2 above to resolve a
        // TransferFields collision with Sales Line's "DXR_DiscountByLS_Old" at the same field ID.
        if SalesInvoiceLineRec.FindSet(true) then
            repeat
                SalesInvoiceLineRec."Package Quantity_DXR" := SalesInvoiceLineRec."DXR Package Quantity_Old2";
                SalesInvoiceLineRec.Modify(false);
            until SalesInvoiceLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESINVLINE-28.3');
    end;

    local procedure MigrateTable_SalesShipmentHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesShipmentHeaderRec: Record "Sales Shipment Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESSHIPTHDR-28.3') then
            exit;

        // Field 50801 "DXR-DE Cust Salesperson Code" / 50806 "Cust Salesperson Code_DXR" are
        // both FlowFields (CalcFormula Lookup). Their values are calculated and cannot be persisted.
        if SalesShipmentHeaderRec.FindSet(true) then
            repeat
                SalesShipmentHeaderRec."Shipment_DXR" := SalesShipmentHeaderRec."DXR-DE Shipment";
                SalesShipmentHeaderRec.Modify(false);
            until SalesShipmentHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESSHIPTHDR-28.3');
    end;

    local procedure MigrateTable_TransferShipmentHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransferShipmentHeaderRec: Record "Transfer Shipment Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERSHPTHDR-28.3') then
            exit;

        if TransferShipmentHeaderRec.FindSet(true) then
            repeat
                TransferShipmentHeaderRec."No. Despachador_DXR" := TransferShipmentHeaderRec."DXR-DE No. Despachador";
                TransferShipmentHeaderRec."Codigo Auditoria_DXR" := TransferShipmentHeaderRec."DXR-DE Codigo Auditoria";
                TransferShipmentHeaderRec."Order User Id_DXR" := TransferShipmentHeaderRec."DXR-DE Order User Id";
                TransferShipmentHeaderRec."Order Date Created_DXR" := TransferShipmentHeaderRec."DXR-DE Order Date Created";
                TransferShipmentHeaderRec."Shipment User ID_DXR" := TransferShipmentHeaderRec."DXR-DE Shipment User ID";
                TransferShipmentHeaderRec.Modify(false);
            until TransferShipmentHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERSHPTHDR-28.3');
    end;

    local procedure MigrateTable_FixedAsset()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        FixedAssetRec: Record "Fixed Asset";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-FIXEDASSET-28.3') then
            exit;

        if FixedAssetRec.FindSet(true) then
            repeat
                FixedAssetRec."GTIN_DXR" := FixedAssetRec."DXR-DE GTIN";
                FixedAssetRec.Modify(false);
            until FixedAssetRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-FIXEDASSET-28.3');
    end;

    local procedure MigrateTable_Item()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ItemRec: Record Item;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEM-28.3') then
            exit;

        if ItemRec.FindSet(true) then
            repeat
                ItemRec."Descripcion Bellon_DXR" := ItemRec."DXR-DE Descripcion Bellon";
                ItemRec.Modify(false);
            until ItemRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEM-28.3');
    end;

    local procedure MigrateTable_ItemJournalLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ItemJournalLineRec: Record "Item Journal Line";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEMJNLLINE-28.3') then
            exit;

        if ItemJournalLineRec.FindSet(true) then
            repeat
                ItemJournalLineRec."Codigo Auditoria Ajuste_DXR" := ItemJournalLineRec."DXR-DE Codigo Auditoria Ajuste";
                ItemJournalLineRec.Modify(false);
            until ItemJournalLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEMJNLLINE-28.3');
    end;

    local procedure MigrateTable_ItemLedgerEntry()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ItemLedgerEntryRec: Record "Item Ledger Entry";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEMLEDGERENTRY-28.3') then
            exit;

        if ItemLedgerEntryRec.FindSet(true) then
            repeat
                ItemLedgerEntryRec."Codigo Auditoria_DXR" := ItemLedgerEntryRec."DXR-DE Codigo Auditoria";
                ItemLedgerEntryRec.Modify(false);
            until ItemLedgerEntryRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-ITEMLEDGERENTRY-28.3');
    end;

    local procedure MigrateTable_Location()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LocationRec: Record Location;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-LOCATION-28.3') then
            exit;

        if LocationRec.FindSet(true) then
            repeat
                LocationRec."Req. Transport_DXR" := LocationRec."DXR-DE Req. Transport";
                LocationRec.Modify(false);
            until LocationRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-LOCATION-28.3');
    end;

    local procedure MigrateTable_PaymentMethod()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PaymentMethodRec: Record "Payment Method";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-PAYMENTMETHOD-28.3') then
            exit;

        if PaymentMethodRec.FindSet(true) then
            repeat
                PaymentMethodRec."Prioridad_DXR" := PaymentMethodRec."DXR-DE Prioridad";
                PaymentMethodRec.Modify(false);
            until PaymentMethodRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-PAYMENTMETHOD-28.3');
    end;

    local procedure MigrateTable_PostedWhseReceiptHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostedWhseReceiptHeaderRec: Record "Posted Whse. Receipt Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-PTDWHSERECEIPTHDR-28.3') then
            exit;

        if PostedWhseReceiptHeaderRec.FindSet(true) then
            repeat
                PostedWhseReceiptHeaderRec."Auxiliar Recepcion_DXR" := PostedWhseReceiptHeaderRec."DXR-DE Auxiliar Recepcion";
                PostedWhseReceiptHeaderRec.Modify(false);
            until PostedWhseReceiptHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-PTDWHSERECEIPTHDR-28.3');
    end;

    local procedure MigrateTable_PostedWhseShipmentHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostedWhseShipmentHeaderRec: Record "Posted Whse. Shipment Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-PTDWHSESHIPMENTHDR-28.3') then
            exit;

        // Field 50801 "DXR-DE DespachadorName" / 50803 "DespachadorName_DXR" are both FlowFields
        // (CalcFormula Lookup). Their values are calculated and cannot be persisted.
        if PostedWhseShipmentHeaderRec.FindSet(true) then
            repeat
                PostedWhseShipmentHeaderRec."Despachador_DXR" := PostedWhseShipmentHeaderRec."DXR-DE Despachador";
                PostedWhseShipmentHeaderRec.Modify(false);
            until PostedWhseShipmentHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-PTDWHSESHIPMENTHDR-28.3');
    end;

    local procedure MigrateTable_PurchRcptHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchRcptHeaderRec: Record "Purch. Rcpt. Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-PURCHRCPTHDR-28.3') then
            exit;

        if PurchRcptHeaderRec.FindSet(true) then
            repeat
                PurchRcptHeaderRec."Auxiliar Recepcion_DXR" := PurchRcptHeaderRec."DXR-DE Auxiliar Recepcion";
                PurchRcptHeaderRec.Modify(false);
            until PurchRcptHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-PURCHRCPTHDR-28.3');
    end;

    local procedure MigrateTable_PurchaseHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PurchaseHeaderRec: Record "Purchase Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-PURCHASEHEADER-28.3') then
            exit;

        if PurchaseHeaderRec.FindSet(true) then
            repeat
                PurchaseHeaderRec."Auxiliar Recepcion_DXR" := PurchaseHeaderRec."DXR-DE Auxiliar Recepcion";
                PurchaseHeaderRec.Modify(false);
            until PurchaseHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-PURCHASEHEADER-28.3');
    end;

    local procedure MigrateTable_ReasonCode()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ReasonCodeRec: Record "Reason Code";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-REASONCODE-28.3') then
            exit;

        if ReasonCodeRec.FindSet(true) then
            repeat
                ReasonCodeRec."GroupTransport_DXR" := ReasonCodeRec."DXR-DE GroupTransport";
                ReasonCodeRec.Modify(false);
            until ReasonCodeRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-REASONCODE-28.3');
    end;

    // Sales Header's 6 source fields were renamed (not removed): "DXR_Tipo" -> "DXR_Tipo_Old2",
    // "DXR_DiscountByLS" -> "DXR_DiscountByLS_Old2", "DXR_DiscountAppliedLS" ->
    // "DXR_DiscountAppliedLS_Old2", "DXR-DE Shipment" -> "DXR_Shipment_Old2", "DXR-DE Sent Pickup"
    // -> "DXR_Sent Pickup_Old2", "DXR-DE Ruta" -> "DXR_Ruta_Old2" - same field IDs, same data, only
    // the AL name changed (these are the same _Old2 fields Phase 2 above populates).
    local procedure MigrateTable_SalesHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesHeaderRec: Record "Sales Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESHEADER-28.3') then
            exit;

        if SalesHeaderRec.FindSet(true) then
            repeat
                SalesHeaderRec."Tipo_DXR" := SalesHeaderRec."DXR_Tipo_Old2";
                SalesHeaderRec."DiscountByLS_DXR" := SalesHeaderRec."DXR_DiscountByLS_Old2";
                SalesHeaderRec."DiscountAppliedLS_DXR" := SalesHeaderRec."DXR_DiscountAppliedLS_Old2";
                SalesHeaderRec."Shipment_DXR" := SalesHeaderRec."DXR_Shipment_Old2";
                SalesHeaderRec."Sent Pickup_DXR" := SalesHeaderRec."DXR_Sent Pickup_Old2";
                SalesHeaderRec."Ruta_DXR" := SalesHeaderRec."DXR_Ruta_Old2";
                SalesHeaderRec.Modify(false);
            until SalesHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESHEADER-28.3');
    end;

    // "DXR_DiscountByLS" (53658) and "DXR_Periodic Discount%" (53659) were renamed (not removed) -
    // to "DXR_DiscountByLS_Old" and "DXR_Periodic Discount%_Old". "DXR_Total Weight"/"DXR_Total
    // Volume" were never renamed.
    local procedure MigrateTable_SalesLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        SalesLineRec: Record "Sales Line";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESLINE-28.3') then
            exit;

        // "DiscountByLS_DXR" reads from "DXR_DiscountByLS_Old2" (53899), not the original
        // "DXR_DiscountByLS_Old" (53658, now ObsoleteState = Removed) - relocated by Phase 2 above
        // to resolve a TransferFields collision with Sales Invoice Line's "DXR Package Quantity"
        // at the same field ID.
        if SalesLineRec.FindSet(true) then
            repeat
                SalesLineRec."Total Weight_DXR" := SalesLineRec."DXR-DE Total Weight";
                SalesLineRec."Total Volume_DXR" := SalesLineRec."DXR-DE Total Volume";
                SalesLineRec."DiscountByLS_DXR" := SalesLineRec."DXR_DiscountByLS_Old2";
                SalesLineRec."Periodic Discount%_DXR" := SalesLineRec."DXR-DE Periodic Discount%";
                SalesLineRec.Modify(false);
            until SalesLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SALESLINE-28.3');
    end;

    local procedure MigrateTable_ShipToAddress()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ShipToAddressRec: Record "Ship-to Address";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SHIPTOADDRESS-28.3') then
            exit;

        if ShipToAddressRec.FindSet(true) then
            repeat
                ShipToAddressRec."Latitud_DXR" := ShipToAddressRec."DXR-DE Latitud";
                ShipToAddressRec."Longitud_DXR" := ShipToAddressRec."DXR-DE Longitud";
                ShipToAddressRec.Modify(false);
            until ShipToAddressRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SHIPTOADDRESS-28.3');
    end;

    local procedure MigrateTable_ShipmentMethod()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ShipmentMethodRec: Record "Shipment Method";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-SHIPMENTMETHOD-28.3') then
            exit;

        if ShipmentMethodRec.FindSet(true) then
            repeat
                ShipmentMethodRec."Shipment Transport_DXR" := ShipmentMethodRec."DXR-DE Shipment Transport";
                ShipmentMethodRec.Modify(false);
            until ShipmentMethodRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-SHIPMENTMETHOD-28.3');
    end;

    local procedure MigrateTable_TransferHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransferHeaderRec: Record "Transfer Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERHEADER-28.3') then
            exit;

        if TransferHeaderRec.FindSet(true) then
            repeat
                TransferHeaderRec."No. Despachador_DXR_Reloc" := TransferHeaderRec."DXR_No. Despachador_Reloc";
                TransferHeaderRec."Codigo Auditoria_DXR_Reloc" := TransferHeaderRec."DXR_Codigo Auditoria_Reloc";
                TransferHeaderRec."Order User Id_DXR_Reloc" := TransferHeaderRec."DXR_Order User Id_Reloc";
                TransferHeaderRec."Order Date Created_DXR_Reloc" := TransferHeaderRec."DXR_Order Date Created_Reloc";
                TransferHeaderRec."Despachador Original_DXR_Reloc" := TransferHeaderRec."DXR_Despachador Original_Reloc";
                TransferHeaderRec."Orig Transfer No._DXR_Reloc" := TransferHeaderRec."DXR_Orig Transfer No._Reloc";
                TransferHeaderRec."Original Trans. Date_DXR_Reloc" := TransferHeaderRec."DXR_Original Trans. Date_Reloc";
                TransferHeaderRec.Modify(false);
            until TransferHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERHEADER-28.3');
    end;

    local procedure MigrateTable_TransferReceiptHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransferReceiptHeaderRec: Record "Transfer Receipt Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERRECEIPTHDR-28.3') then
            exit;

        if TransferReceiptHeaderRec.FindSet(true) then
            repeat
                TransferReceiptHeaderRec."No. Despachador_DXR" := TransferReceiptHeaderRec."DXR-DE No. Despachador";
                TransferReceiptHeaderRec."Codigo Auditoria_DXR" := TransferReceiptHeaderRec."DXR-DE Codigo Auditoria";
                TransferReceiptHeaderRec."Order User Id_DXR" := TransferReceiptHeaderRec."DXR-DE Order User Id";
                TransferReceiptHeaderRec."Order Date Created_DXR" := TransferReceiptHeaderRec."DXR-DE Order Date Created";
                TransferReceiptHeaderRec."Receipt User ID_DXR" := TransferReceiptHeaderRec."DXR-DE Receipt User ID";
                TransferReceiptHeaderRec."Pre Receive Ref. No._DXR" := TransferReceiptHeaderRec."DXR-DE Pre Receive Ref. No.";
                TransferReceiptHeaderRec.Modify(false);
            until TransferReceiptHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-TRANSFERRECEIPTHDR-28.3');
    end;

    local procedure MigrateTable_UserSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetupRec: Record "User Setup";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-USERSETUP-28.3') then
            exit;

        if UserSetupRec.FindSet(true) then
            repeat
                UserSetupRec."Create Shipments_DXR" := UserSetupRec."DXR-DE Create Shipments";
                UserSetupRec."Filtrar Cartera Cte_DXR" := UserSetupRec."DXR-DE Filtrar Cartera Cte";
                UserSetupRec.Modify(false);
            until UserSetupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-USERSETUP-28.3');
    end;

    local procedure MigrateTable_ValueEntry()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ValueEntryRec: Record "Value Entry";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-VALUEENTRY-28.3') then
            exit;

        if ValueEntryRec.FindSet(true) then
            repeat
                ValueEntryRec."Codigo Auditoria Ajuste_DXR" := ValueEntryRec."DXR-DE Codigo Auditoria Ajuste";
                ValueEntryRec.Modify(false);
            until ValueEntryRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-VALUEENTRY-28.3');
    end;

    local procedure MigrateTable_WarehouseReceiptHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        WarehouseReceiptHeaderRec: Record "Warehouse Receipt Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-WAREHOUSERECEIPTHDR-28.3') then
            exit;

        if WarehouseReceiptHeaderRec.FindSet(true) then
            repeat
                WarehouseReceiptHeaderRec."Auxiliar Recepcion_DXR" := WarehouseReceiptHeaderRec."DXR-DE Auxiliar Recepcion";
                WarehouseReceiptHeaderRec.Modify(false);
            until WarehouseReceiptHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-WAREHOUSERECEIPTHDR-28.3');
    end;

    local procedure MigrateTable_WarehouseShipmtHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        WarehouseShipmtHeaderRec: Record "Warehouse Shipment Header";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoBase-MigrPhase1-WAREHOUSESHIPMTHDR-28.3') then
            exit;

        // Field 50801 "DXR-DE DespachadorName" / 50803 "DespachadorName_DXR" are both FlowFields
        // (CalcFormula Lookup). Their values are calculated and cannot be persisted.
        if WarehouseShipmtHeaderRec.FindSet(true) then
            repeat
                WarehouseShipmtHeaderRec."Despachador_DXR" := WarehouseShipmtHeaderRec."DXR-DE Despachador";
                WarehouseShipmtHeaderRec.Modify(false);
            until WarehouseShipmtHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoBase-MigrPhase1-WAREHOUSESHIPMTHDR-28.3');
    end;
}

*/
