#if not ESCUDEA and not BCDX
codeunit 60147 "DXR MCC Bellon Migr Phase3"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 3 Dedup" (56120). The real source calls two procedures on "Bellon Upgrade Process"
    // (59221) in this order:
    //   1) MigrateAllSalesPurchOldGenBridge() - CONFIRMED NO-OP in the current source (both ends
    //      of this bridge were later marked ObsoleteState = Removed once git history confirmed
    //      migration/v28.3 never merged to deploy/production, so neither side ever held live
    //      tenant data; the 14 per-table bridge procedures are kept in source, unused, as
    //      documentation only). Not ported here - nothing to run.
    //   2) MigrateAllSalesPurchFieldIdDedup() - ACTIVE. Reassigns 100 tableextension fields across
    //      the 14 Sales/Purchase Header family tables that Phase 2's own naming-normalization step
    //      left colliding on the same field ID (52787+) across sibling tables linked by BC's
    //      native RecordRef.TRANSFERFIELDS (Sales-Post/Purch-Post/ArchiveManagement copy Header ->
    //      posted/archived document by field NUMBER, not name) - a real "must have the same type"
    //      crash fix. Each table gets its own exclusive ID range (57200-57469).
    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "Sales Shipment Header" = RM,
        tabledata "Sales Line" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Header Archive" = RM,
        tabledata "Sales Line Archive" = RM,
        tabledata "Purchase Header" = RM,
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Rcpt. Header" = RM,
        tabledata "Purchase Header Archive" = RM,
        tabledata "Purchase Line" = RM,
        tabledata "Purch. Rcpt. Line" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-SalesPurchIdDedup283-NAME-FALLBACK-20260826') then
            exit;

        MigrateAllSalesPurchFieldIdDedup();

        UpgradeTag.SetUpgradeTag('DXR-SalesPurchIdDedup283-NAME-FALLBACK-20260826');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        // Field numbers remain in the published schema to keep BC's TransferFields compatibility,
        // but migration lookup itself is entirely name based. The maintained name is preferred;
        // old bridge aliases are only used when it is blank or unavailable.
        if MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldCandidates(TargetFieldName)) then
            RecordChanged := true;
    end;

    local procedure SourceFieldCandidates(TargetFieldName: Text): Text
    var
        BaseFieldName: Text;
        DxrSuffixPosition: Integer;
    begin
        DxrSuffixPosition := StrPos(TargetFieldName, '_DXR');
        if DxrSuffixPosition = 0 then
            exit(TargetFieldName);

        BaseFieldName := DelStr(TargetFieldName, DxrSuffixPosition, StrLen('_DXR'));
        if CopyStr(BaseFieldName, StrLen(BaseFieldName), 1) = '.' then
            BaseFieldName := CopyStr(BaseFieldName, 1, StrLen(BaseFieldName) - 1);

        exit(BaseFieldName + '|' + BaseFieldName + '_Old2|' + BaseFieldName + '_Old|' + BaseFieldName + '_BE_DXR');
    end;

    local procedure PersistChangedRecord(var RecRef: RecordRef)
    begin
        if RecordChanged then
            RecRef.Modify(false);
        Clear(RecordChanged);

        RowsSinceCommit += 1;
        if RowsSinceCommit >= BatchSize() then begin
            Commit();
            RowsSinceCommit := 0;
        end;
    end;

    local procedure FinishTable(var RecRef: RecordRef)
    begin
        RecRef.Close();
        Commit();
        RowsSinceCommit := 0;
        Clear(RecordChanged);
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure MigrateAllSalesPurchFieldIdDedup()
    begin
        MigrateTableExt_SalesHeaderIdDedup();
        MigrateTableExt_SalesInvoiceHeaderIdDedup();
        MigrateTableExt_SalesCrMemoHeaderIdDedup();
        MigrateTableExt_SalesShipmentHeaderIdDedup();
        MigrateTableExt_SalesLineIdDedup();
        MigrateTableExt_SalesInvoiceLineIdDedup();
        MigrateTableExt_SalesHeaderArchiveIdDedup();
        MigrateTableExt_SalesLineArchiveIdDedup();
        MigrateTableExt_PurchaseHeaderIdDedup();
        MigrateTableExt_PurchInvHeaderIdDedup();
        MigrateTableExt_PurchRcptHeaderIdDedup();
        MigrateTableExt_PurchaseHeaderArchiveIdDedup();
        MigrateTableExt_PurchaseLineIdDedup();
        MigrateTableExt_PurchRcptLineIdDedup();
    end;

    local procedure MigrateTableExt_SalesHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Discount_ByLS_DXR');
                CopyFieldIfExists(RecRef, 'DiscountApplied_LS_DXR');
                CopyFieldIfExists(RecRef, 'Offer No._DXR');
                CopyFieldIfExists(RecRef, 'Shipment_DXR.');
                CopyFieldIfExists(RecRef, 'Aprobacion Inmediata_DXR');
                CopyFieldIfExists(RecRef, 'Tipo Venta_DXR');
                CopyFieldIfExists(RecRef, 'CreatedBy_DXR');
                // 57207 (Tipo Segmento_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'AzulOrderID_DXR.');
                CopyFieldIfExists(RecRef, 'ExternalPaymentStatus_DXR');
                CopyFieldIfExists(RecRef, 'MontoPreaprobadoAZUL_DXR');
                CopyFieldIfExists(RecRef, 'Email Enviado Gerentes_DXR');
                CopyFieldIfExists(RecRef, 'Sent Pickup_DXR.');
                CopyFieldIfExists(RecRef, 'PriceReleaseControlFlag_DXR');
                // 57214 (Gestor_ID_DXR.) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Reference Address BE_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesInvoiceHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Invoice Header");
        if RecRef.FindSet(true) then
            repeat
                // 57230 (PaID_DXR.) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Tipo_DXR');
                CopyFieldIfExists(RecRef, 'Discount_ByLS_DXR');
                CopyFieldIfExists(RecRef, 'DiscountApplied_LS_DXR');
                CopyFieldIfExists(RecRef, 'Offer No._DXR');
                CopyFieldIfExists(RecRef, 'Comision_Tipo_ID_DXR.');
                CopyFieldIfExists(RecRef, 'Shipment_DXR.');
                CopyFieldIfExists(RecRef, 'Tipo Venta_DXR');
                // 57238 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Addl Currency Code_DXR');
                CopyFieldIfExists(RecRef, 'Banco Central Cur Fctr_DXR');
                CopyFieldIfExists(RecRef, 'Date Created_DXR');
                CopyFieldIfExists(RecRef, 'SetAplicarFechaPago_DXR');
                CopyFieldIfExists(RecRef, 'PaymentDate_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesCrMemoHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Cr.Memo Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Discount_ByLS_DXR');
                CopyFieldIfExists(RecRef, 'DiscountApplied_LS_DXR');
                CopyFieldIfExists(RecRef, 'Offer No._DXR');
                CopyFieldIfExists(RecRef, 'Shipment_DXR.');
                // 57264 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesShipmentHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Shipment Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Tipo NCF Cliente_DXR');
                CopyFieldIfExists(RecRef, 'No. Series NCF Fact._DXR');
                CopyFieldIfExists(RecRef, 'No. Series NCF Cr._DXR');
                CopyFieldIfExists(RecRef, 'NCF_DXR');
                CopyFieldIfExists(RecRef, 'Shipment_DXR.');
                // 57285 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesLineIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Autorizador_DXR');
                CopyFieldIfExists(RecRef, 'Barcode_DXR');
                CopyFieldIfExists(RecRef, 'Procesada POS_DXR');
                CopyFieldIfExists(RecRef, 'Discount_ByLS_DXR');
                CopyFieldIfExists(RecRef, 'Periodic Discount%_DXR.');
                CopyFieldIfExists(RecRef, 'Line Copied From Inv_DXR');
                // 57306 (StoreNoHeader_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Precio Referencia_DXR');
                CopyFieldIfExists(RecRef, 'Empaque_DXR');
                CopyFieldIfExists(RecRef, 'Empaque Maestro_DXR');
                CopyFieldIfExists(RecRef, 'Referencias_DXR');
                CopyFieldIfExists(RecRef, 'Referencia_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesInvoiceLineIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Invoice Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Item Tracking No._DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesHeaderArchiveIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Header Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Store No._DXR');
                // 57341 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_SalesLineArchiveIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Line Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Autorizador_DXR');
                CopyFieldIfExists(RecRef, 'Barcode_DXR');
                CopyFieldIfExists(RecRef, 'Procesada POS_DXR');
                CopyFieldIfExists(RecRef, 'Discount_ByLS_DXR');
                CopyFieldIfExists(RecRef, 'Periodic Discount%_DXR.');
                CopyFieldIfExists(RecRef, 'Line Copied From Inv_DXR');
                CopyFieldIfExists(RecRef, 'StoreNoHeader_DXR');
                CopyFieldIfExists(RecRef, 'Precio Referencia_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchaseHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purchase Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Fecha Est Lleg Bln_DXR');
                CopyFieldIfExists(RecRef, 'Factor %_DXR');
                CopyFieldIfExists(RecRef, 'Markup %_DXR');
                CopyFieldIfExists(RecRef, 'Priority_DXR');
                CopyFieldIfExists(RecRef, 'FechaEstEntregaSuplidor_DXR');
                CopyFieldIfExists(RecRef, 'Envio Compras ID_DXR.');
                // 57376 (Envio Compras_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Fecha Registro 2_DXR');
                // 57378 (Transito Internacional_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Batch No. Repl._DXR');
                CopyFieldIfExists(RecRef, 'Templeate No Repl._DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchInvHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Inv. Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Priority_DXR');
                // 57401 (Envio Compras_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Fecha Registro 2_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchRcptHeaderIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Rcpt. Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'No. Series NCF Fact._DXR');
                CopyFieldIfExists(RecRef, 'No. Series NCF Ab._DXR');
                CopyFieldIfExists(RecRef, 'NCF_DXR');
                CopyFieldIfExists(RecRef, 'Utiliza NCF Externo_DXR');
                CopyFieldIfExists(RecRef, 'Cod. Retencion ITBIS_DXR');
                CopyFieldIfExists(RecRef, 'Cod. Retencion ISR_DXR');
                CopyFieldIfExists(RecRef, 'Cod. Categoria NCF_DXR');
                CopyFieldIfExists(RecRef, 'Multiples Cat. NCF_DXR');
                CopyFieldIfExists(RecRef, 'Correccion Int._DXR');
                CopyFieldIfExists(RecRef, 'Tipo NCF Provedor_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchaseHeaderArchiveIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purchase Header Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Fecha Est Lleg Bln_DXR');
                CopyFieldIfExists(RecRef, 'FechaEstEntregaSuplidor_DXR');
                CopyFieldIfExists(RecRef, 'Envio Compras ID_DXR.');
                // 57433 (Envio Compras_DXR) is a FlowField - no physical data to copy.
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchaseLineIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purchase Line");
        if RecRef.FindSet(true) then
            repeat
                // 57440 (Country/Region Org Code_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Almacen Destino_DXR');
                CopyFieldIfExists(RecRef, 'Transito_DXR');
                CopyFieldIfExists(RecRef, 'Unit Cost has Changed_DXR');
                CopyFieldIfExists(RecRef, 'Batch No. Repl._DXR');
                CopyFieldIfExists(RecRef, 'Templeate No Repl._DXR');
                CopyFieldIfExists(RecRef, 'Line No. Repl._DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_PurchRcptLineIdDedup()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Rcpt. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Almacen Destino_DXR');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
