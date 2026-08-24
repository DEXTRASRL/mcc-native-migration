codeunit 60149 "DXR MCC Bellon Migr Phase5"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 5 CustItem" (56122). Bridges the "_BE_DXR" fields restored on Customer.TableExt.al
    // (46 fields, IDs 50061-50106) and Item.TableExt.al (33 fields, IDs 50036-50070, excluding 2
    // FlowFields) - both renumbered AND renamed in place by a global commit with no data
    // migration - to their current "_DXR" field, with a never-overwrite merge policy (never pisa
    // un campo _DXR que ya tenga valor).
    Permissions =
        tabledata Customer = RM,
        tabledata Item = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('BELLON-CUSTITEM-OLDGEN-BRIDGE-20260820') then
            exit;

        BridgeCustomerOldGenFields();
        BridgeItemOldGenFields();

        UpgradeTag.SetUpgradeTag('BELLON-CUSTITEM-OLDGEN-BRIDGE-20260820');
    end;

    local procedure BridgeCustomerOldGenFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Customer);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfTargetEmpty(RecRef, 50061, 52788); // Dirección Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50062, 52789); // Sector Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50063, 52790); // Cédula Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50064, 57100); // Cumpl Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50065, 57101); // Celular Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50066, 57102); // E-Mail Representante_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 50067, 57103); // Código Cobrador_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50068, 57104); // Requiere OC_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50069, 57105); // Tipo de Cliente_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50070, 57106); // Frecuencia Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50071, 57107); // Secuencia Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50072, 52799); // Días Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50073, 52800); // Carnet DGII_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50074, 57108); // Cobrar Interés_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50075, 57109); // % Interés_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50076, 57110); // Carnet Exención ITBIS_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50077, 57111); // Vencimiento Carnet_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50078, 57112); // Enc. Compras Nombre_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50079, 52806); // Enc. Compras email_BE_DXR -> Email_DXR.
                CopyFieldIfTargetEmpty(RecRef, 50080, 52807); // Enc. Compras celular_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50081, 52808); // Enc. Compras Cumpleaños_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50082, 52809); // Enc. Pagos Nombre_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50083, 52810); // Enc. Pagos email_BE_DXR -> Email_DXR.
                CopyFieldIfTargetEmpty(RecRef, 50084, 52811); // Enc. Pagos celular_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50085, 52812); // Enc. Pagos Cumpleaños_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50086, 52813); // Frecuencia de Pago_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50087, 52814); // Apartado Postal_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50088, 52815); // Sector_BE_DXR -> Sector_DXR
                CopyFieldIfTargetEmpty(RecRef, 50089, 52816); // Municipio_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50090, 52817); // Provincia_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50091, 52818); // Comision_Tipo_ID_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 50092, 52819); // Deuda Pico_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50093, 52820); // Fecha Deuda Pico_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50094, 52821); // Gestor_ID_BE_DXR -> Gestor_ID_DXR.
                CopyFieldIfTargetEmpty(RecRef, 50095, 52822); // Fecha envio edo cuenta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50096, 52823); // Invoice Expiration Days_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50097, 52824); // Enc. Recepcion Email_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 50098, 52825); // StoreId_BE_DXR -> StoreID_DXR.
                CopyFieldIfTargetEmpty(RecRef, 50099, 52826); // Tipo Segmento_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50100, 52827); // Monto Deposito Cilindr_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50101, 52828); // Cant asig - Cilindros_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50102, 52829); // Cliente Cilindros_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50103, 52830); // Fecha Exp Reg Merc_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50104, 52831); // B2C Customer_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50105, 52832); // Last Date/Time Modified_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50106, 52833); // Req Fecha Reg Merc_BE_DXR -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure BridgeItemOldGenFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Item);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfTargetEmpty(RecRef, 50036, 52787); // Modelo_BE_DXR -> Modelo_DXR
                CopyFieldIfTargetEmpty(RecRef, 50037, 52788); // Marca_BE_DXR -> Marca_DXR
                CopyFieldIfTargetEmpty(RecRef, 50038, 52789); // Se Detalla_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50039, 52790); // Producido_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50040, 52791); // Carga % Tarjeta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50041, 52792); // Consignación_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50042, 52793); // Internal Use_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50043, 52794); // Acepta Decimales_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50044, 52795); // Exhibición_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50045, 52796); // Precio Sugerido_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50046, 52797); // Kit_BE_DXR -> Kit_DXR
                CopyFieldIfTargetEmpty(RecRef, 50047, 52798); // Empaque_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50048, 52799); // Empaque Maestro_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50049, 52800); // Venta por Mayor_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50050, 52801); // % Comisión Venta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50051, 52802); // % Comisión Cobro_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50052, 52803); // Márgen Plaza_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50053, 52804); // Márgen Importación_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50054, 52805); // Descripcion Bellon_BE_DXR -> Descripcion_Bellon_DXR
                CopyFieldIfTargetEmpty(RecRef, 50055, 52806); // Costo Liquidacion_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50056, 52807); // Comision_Tipo_ID_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 50057, 52808); // Ultimo Costo Bellon_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50058, 52809); // Costo Unitario Bellon_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50059, 52810); // SANA Info Adicionales_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50060, 52811); // Sales Group_BE_DXR -> Sales Group_DXR
                CopyFieldIfTargetEmpty(RecRef, 50061, 52812); // Sales SubGroup_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50062, 52813); // Sales Dept Code_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50063, 52814); // Codigo Producto Aduana_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50064, 52815); // ExclFromDiscountCoupons_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50065, 52816); // ExclFromFreeShipCoupons_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50066, 52817); // Disponible para Ventas_BE_DXR -> _DXR
                // 52818 (Buyer Group Code_DXR) / 52819 (Inventory2_DXR) son FlowFields -- sin dato fisico que copiar.
                CopyFieldIfTargetEmpty(RecRef, 50069, 52820); // Item Status_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 50070, 52821); // Control Existencia_BE_DXR -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    // "Never-overwrite" merge policy: copies OldFieldNo -> NewFieldNo only if the source field
    // holds a real value AND the destination field is empty. If the destination already has a
    // value (a manual post-publish edit, a prior partial retry of this phase, or another phase),
    // it is never overwritten. Idempotent by construction.
    local procedure CopyFieldIfTargetEmpty(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    var
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
    begin
        if not (RecRef.FieldExist(OldFieldNo) and RecRef.FieldExist(NewFieldNo)) then
            exit;

        OldFieldRef := RecRef.Field(OldFieldNo);
        NewFieldRef := RecRef.Field(NewFieldNo);

        if IsFieldRefEmpty(OldFieldRef) then
            exit;
        if not IsFieldRefEmpty(NewFieldRef) then
            exit;

        NewFieldRef.Value := OldFieldRef.Value();
    end;

    local procedure IsFieldRefEmpty(FldRef: FieldRef): Boolean
    var
        BoolVal: Boolean;
        IntVal: BigInteger;
        DecVal: Decimal;
        DateVal: Date;
        DateTimeVal: DateTime;
    begin
        case FldRef.Type of
            FieldType::Text, FieldType::Code:
                exit(Format(FldRef.Value) = '');
            FieldType::Boolean:
                begin
                    BoolVal := FldRef.Value;
                    exit(BoolVal = false);
                end;
            FieldType::Integer, FieldType::Option, FieldType::BigInteger:
                begin
                    IntVal := FldRef.Value;
                    exit(IntVal = 0);
                end;
            FieldType::Decimal:
                begin
                    DecVal := FldRef.Value;
                    exit(DecVal = 0);
                end;
            FieldType::Date:
                begin
                    DateVal := FldRef.Value;
                    exit(DateVal = 0D);
                end;
            FieldType::DateTime:
                begin
                    DateTimeVal := FldRef.Value;
                    exit(DateTimeVal = 0DT);
                end;
            else
                exit(Format(FldRef.Value) = '');
        end;
    end;
}
