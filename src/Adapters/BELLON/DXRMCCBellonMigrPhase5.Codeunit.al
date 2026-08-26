/*
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
                CopyFieldIfTargetEmpty(RecRef, 'Dirección Representante_BE_DXR', 'Dirección Representante_DXR'); // Dirección Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Sector Representante_BE_DXR', 'Sector Representante_DXR'); // Sector Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Cédula Representante_BE_DXR', 'Cédula Representante_DXR'); // Cédula Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Cumpl Representante_BE_DXR', 'Cumpl Representante_DXR'); // Cumpl Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Celular Representante_BE_DXR', 'Celular Representante_DXR'); // Celular Representante_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'E-Mail Representante_BE_DXR', 'E-Mail Representante_DXR.'); // E-Mail Representante_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Código Cobrador_BE_DXR', 'Código Cobrador_DXR'); // Código Cobrador_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Requiere OC_BE_DXR', 'Requiere OC_DXR'); // Requiere OC_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Tipo de Cliente_BE_DXR', 'Tipo de Cliente_DXR'); // Tipo de Cliente_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Frecuencia Visita_BE_DXR', 'Frecuencia Visita_DXR'); // Frecuencia Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Secuencia Visita_BE_DXR', 'Secuencia Visita_DXR'); // Secuencia Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Días Visita_BE_DXR', 'Días Visita_DXR'); // Días Visita_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Carnet DGII_BE_DXR', 'Carnet DGII_DXR'); // Carnet DGII_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Cobrar Interés_BE_DXR', 'Cobrar Interés_DXR'); // Cobrar Interés_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, '% Interés_BE_DXR', '% Interés_DXR'); // % Interés_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Carnet Exención ITBIS_BE_DXR', 'Carnet Exención ITBIS_DXR'); // Carnet Exención ITBIS_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Vencimiento Carnet_BE_DXR', 'Vencimiento Carnet_DXR'); // Vencimiento Carnet_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Compras Nombre_BE_DXR', 'Enc. Compras Nombre_DXR'); // Enc. Compras Nombre_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Compras email_BE_DXR', 'Enc. Compras Email_DXR.'); // Enc. Compras email_BE_DXR -> Email_DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Compras celular_BE_DXR', 'Enc. Compras celular_DXR'); // Enc. Compras celular_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Compras Cumpleaños_BE_DXR', 'Enc. Compras Cumpleaños_DXR'); // Enc. Compras Cumpleaños_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Pagos Nombre_BE_DXR', 'Enc. Pagos Nombre_DXR'); // Enc. Pagos Nombre_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Pagos email_BE_DXR', 'Enc. Pagos Email_DXR.'); // Enc. Pagos email_BE_DXR -> Email_DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Pagos celular_BE_DXR', 'Enc. Pagos celular_DXR'); // Enc. Pagos celular_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Pagos Cumpleaños_BE_DXR', 'Enc. Pagos Cumpleaños_DXR'); // Enc. Pagos Cumpleaños_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Frecuencia de Pago_BE_DXR', 'Frecuencia de Pago_DXR'); // Frecuencia de Pago_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Apartado Postal_BE_DXR', 'Apartado Postal_DXR'); // Apartado Postal_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Sector_BE_DXR', 'Sector_DXR'); // Sector_BE_DXR -> Sector_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Municipio_BE_DXR', 'Municipio_DXR'); // Municipio_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Provincia_BE_DXR', 'Provincia_DXR'); // Provincia_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Comision_Tipo_ID_BE_DXR', 'Comision_Tipo_ID_DXR.'); // Comision_Tipo_ID_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Deuda Pico_BE_DXR', 'Deuda Pico_DXR'); // Deuda Pico_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Fecha Deuda Pico_BE_DXR', 'Fecha Deuda Pico_DXR'); // Fecha Deuda Pico_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Gestor_ID_BE_DXR', 'Gestor_ID_DXR.'); // Gestor_ID_BE_DXR -> Gestor_ID_DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Fecha envio edo cuenta_BE_DXR', 'Fecha envio edo cuenta_DXR'); // Fecha envio edo cuenta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Invoice Expiration Days_BE_DXR', 'Invoice Expiration Days_DXR'); // Invoice Expiration Days_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Enc. Recepcion Email_BE_DXR', 'Enc. Recepcion Email_DXR.'); // Enc. Recepcion Email_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 'StoreId_BE_DXR', 'StoreID_DXR.'); // StoreId_BE_DXR -> StoreID_DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Tipo Segmento_BE_DXR', 'Tipo Segmento_DXR'); // Tipo Segmento_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Monto Deposito Cilindr_BE_DXR', 'Monto Deposito Cilindr_DXR'); // Monto Deposito Cilindr_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Cant asig - Cilindros_BE_DXR', 'Cant asig - Cilindros_DXR'); // Cant asig - Cilindros_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Cliente Cilindros_BE_DXR', 'Cliente Cilindros_DXR'); // Cliente Cilindros_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Fecha Exp Reg Merc_BE_DXR', 'Fecha Exp Reg Merc_DXR'); // Fecha Exp Reg Merc_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'B2C Customer_BE_DXR', 'B2C Customer_DXR'); // B2C Customer_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Last Date/Time Modified_BE_DXR', 'Last Date/Time Modified_DXR'); // Last Date/Time Modified_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Req Fecha Reg Merc_BE_DXR', 'Req Fecha Reg Merc_DXR'); // Req Fecha Reg Merc_BE_DXR -> _DXR
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
                CopyFieldIfTargetEmpty(RecRef, 'Modelo_BE_DXR', 'Modelo_DXR'); // Modelo_BE_DXR -> Modelo_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Marca_BE_DXR', 'Marca_DXR'); // Marca_BE_DXR -> Marca_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Se Detalla_BE_DXR', 'Se Detalla_DXR'); // Se Detalla_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Producido_BE_DXR', 'Producido_DXR'); // Producido_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Carga % Tarjeta_BE_DXR', 'Carga % Tarjeta_DXR'); // Carga % Tarjeta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Consignación_BE_DXR', 'Consignación_DXR'); // Consignación_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Internal Use_BE_DXR', 'Internal Use_DXR'); // Internal Use_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Acepta Decimales_BE_DXR', 'Acepta Decimales_DXR'); // Acepta Decimales_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Exhibición_BE_DXR', 'Exhibición_DXR'); // Exhibición_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Precio Sugerido_BE_DXR', 'Precio Sugerido_DXR'); // Precio Sugerido_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Kit_BE_DXR', 'Kit_DXR'); // Kit_BE_DXR -> Kit_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Empaque_BE_DXR', 'Empaque_DXR'); // Empaque_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Empaque Maestro_BE_DXR', 'Empaque Maestro_DXR'); // Empaque Maestro_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Venta por Mayor_BE_DXR', 'Venta por Mayor_DXR'); // Venta por Mayor_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, '% Comisión Venta_BE_DXR', '% Comisión Venta_DXR'); // % Comisión Venta_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, '% Comisión Cobro_BE_DXR', '% Comisión Cobro_DXR'); // % Comisión Cobro_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Márgen Plaza_BE_DXR', 'Márgen Plaza_DXR'); // Márgen Plaza_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Márgen Importación_BE_DXR', 'Márgen Importación_DXR'); // Márgen Importación_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Descripcion Bellon_BE_DXR', 'Descripcion_Bellon_DXR'); // Descripcion Bellon_BE_DXR -> Descripcion_Bellon_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Costo Liquidacion_BE_DXR', 'Costo Liquidacion_DXR'); // Costo Liquidacion_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Comision_Tipo_ID_BE_DXR', 'Comision_Tipo_ID_DXR.'); // Comision_Tipo_ID_BE_DXR -> _DXR.
                CopyFieldIfTargetEmpty(RecRef, 'Ultimo Costo Bellon_BE_DXR', 'Ultimo Costo Bellon_DXR'); // Ultimo Costo Bellon_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Costo Unitario Bellon_BE_DXR', 'Costo Unitario Bellon_DXR'); // Costo Unitario Bellon_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'SANA Info Adicionales_BE_DXR', 'SANA Info Adicionales_DXR'); // SANA Info Adicionales_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Sales Group_BE_DXR', 'Sales Group_DXR'); // Sales Group_BE_DXR -> Sales Group_DXR
                CopyFieldIfTargetEmpty(RecRef, 'Sales SubGroup_BE_DXR', 'Sales SubGroup_DXR'); // Sales SubGroup_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Sales Dept Code_BE_DXR', 'Sales Dept Code_DXR'); // Sales Dept Code_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Codigo Producto Aduana_BE_DXR', 'Codigo Producto Aduana_DXR'); // Codigo Producto Aduana_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'ExclFromDiscountCoupons_BE_DXR', 'ExclFromDiscountCoupons_DXR'); // ExclFromDiscountCoupons_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'ExclFromFreeShipCoupons_BE_DXR', 'ExclFromFreeShipCoupons_DXR'); // ExclFromFreeShipCoupons_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Disponible para Ventas_BE_DXR', 'Disponible para Ventas_DXR'); // Disponible para Ventas_BE_DXR -> _DXR
                // 52818 (Buyer Group Code_DXR) / 52819 (Inventory2_DXR) son FlowFields -- sin dato fisico que copiar.
                CopyFieldIfTargetEmpty(RecRef, 'Item Status_BE_DXR', 'Item Status_DXR'); // Item Status_BE_DXR -> _DXR
                CopyFieldIfTargetEmpty(RecRef, 'Control Existencia_BE_DXR', 'Control Existencia_DXR'); // Control Existencia_BE_DXR -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    // "Never-overwrite" merge policy: copies source name -> target name only if the source field
    // holds a real value AND the destination field is empty. If the destination already has a
    // value (a manual post-publish edit, a prior partial retry of this phase, or another phase),
    // it is never overwritten. Idempotent by construction.
    local procedure CopyFieldIfTargetEmpty(var RecRef: RecordRef; SourceFieldName: Text; TargetFieldName: Text)
    var
        SourceField: FieldRef;
        TargetField: FieldRef;
    begin
        if not RecRef.FieldExist(SourceFieldName) or not RecRef.FieldExist(TargetFieldName) then
            exit;
        SourceField := RecRef.Field(SourceFieldName);
        TargetField := RecRef.Field(TargetFieldName);
        if (SourceField.Class() <> FieldClass::Normal) or
           (TargetField.Class() <> FieldClass::Normal) or
           (SourceField.Type() <> TargetField.Type())
        then
            exit;

        if IsFieldRefEmpty(SourceField) then
            exit;
        if not IsFieldRefEmpty(TargetField) then
            exit;

        TargetField.Value := SourceField.Value();
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

*/
