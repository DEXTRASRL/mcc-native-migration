codeunit 60451 "DXR MCC Master Item"
{
    // Motor por tabla - reemplaza 5 de los 6 recorridos independientes de Item (BC, BELLON, DESB,
    // DRLOC, FE) por uno solo. Ver docs/superpowers/specs/2026-08-27-master-by-table-design.md y el
    // piloto "DXR MCC Master Customer" (60450), cuya forma se replica aqui exactamente. El codigo de
    // cada bloque se MOVIO (no se duplico) desde su origen; el procedimiento origen queda como no-op
    // documentado porque otras rutas (RunMaster/RunConcept/dispatchers por extension) todavia lo
    // invocan.
    //
    // ApplyLSLOC NO se movio (mismo criterio que ApplyTU en Master Customer, ver task-3-report.md):
    // su fuente, "DXR MCC LSLOC Migr ToDXRLS".CopyItemFields() (60162), abre un RecordRef sobre
    // Database::Item e itera con RecRef.FindSet/RecRef.Next, delegando el unico campo que copia
    // ('Factor_DXR' <- 'Factor') a "DXR MCC Master Field Resolver".CopyFieldIfExists(RecRef, Target,
    // Source) - resolucion dinamica por nombre sobre un FieldRef, no una asignacion tipada
    // Item.Campo := Item.OtroCampo. Encaja en el MISMO caso que ApplyTU: el contrato del motor
    // (ApplyXXX(var Item: Record Item): Boolean) es tipado por decision de diseno (Ruling de la
    // revision de la Tarea 3); portar este bloque exigiria o bien aceptar RecordRef en la firma (rompe
    // la uniformidad de los otros 5 bloques y el patron RowNeedsWork de doble llamada sobre el mismo
    // tipo), o reescribir la logica del resolver como asignacion tipada - eso ya no es "mover el
    // codigo tal cual" sino reimplementarlo, fuera de este alcance. Ademas
    // "DXR MCC Master Field Resolver".Codeunit.al tenia cambios sin commitear ajenos a esta tarea al
    // momento de implementarla (lista de archivos "no tocar" del despacho), asi que ni siquiera seria
    // seguro tocarlo. El propio scan de LSLOC sobre Item (CopyItemFields, dentro de
    // TableExtFieldsExecute(), bajo el tag 'DXR-LS-MIGRATION-20260623') sigue corriendo por separado.
    // El ahorro de recorridos de esta tarea es de 5 scans -> 1, no de 6 -> 1.
    //
    // "DXR MCC Bellon Migr Phase5".BridgeItemOldGenFields() (60149) tampoco se movio: es OTRO bloque
    // adicional (no uno de los 6 nombrados en el brief) que bridgea el mismo par de tablas
    // (Customer+Item) via RecordRef + CopyFieldIfTargetEmpty, mismo motivo de exclusion que LSLOC.
    //
    // Particularidad de Item verificada antes de mover (brief punto 3): 'Buyer Group Code_DXR'
    // (52818) e 'Inventory2_DXR' (52819) son FlowField EN AMBOS LADOS - confirmado no solo por el
    // comentario de BridgeItemOldGenFields() (linea 123 de ese archivo) sino independientemente contra
    // el simbolo real: SymbolReference.json de "Dextra_Bellon Customization_28.3.4.20.app"
    // (TableExtensions -> "DXR_BE Item") muestra 52818 "Buyer Group Code_DXR" con
    // Properties.FieldClass = 'FlowField' (CalcFormula Lookup sobre "LSC Retail Product Group") y
    // 52819 "Inventory2_DXR" con Properties.FieldClass = 'FlowField' (CalcFormula Sum sobre "Item
    // Ledger Entry"). Ninguno de los 5 bloques movidos aqui (BC, BELLON, DESB, DRLOC, FE) los
    // referencia - no hay dato fisico que copiar, no entran a SetLoadFields ni a ninguna asignacion.
    //
    // Auditoria de upgrade tags (obligatoria por el patron fijado en la ronda 1/5 de Master Customer -
    // ver el header de 60450 para el procedimiento completo):
    //  - ApplyDESB viene de "DXR MCC DESB Migr Phase2".MigrateTable_Item(), que fijaba un tag INTERNO
    //    propio ('DXR-DespachoBase-MigrPhase1-ITEM-28.3'). Verificado con grep en todo el repo: ese
    //    literal nunca estuvo seedeado en "DXR MCC Upgrade Tag Seed"
    //    (src/DXRMCCUpgradeTagSeed.Codeunit.al) - no queda ninguna fila de dashboard huerfana.
    //  - ApplyBC ("DXR MCC BC Migr P3 Item".RowNeedsMigration()/trigger) nunca uso UpgradeTag dentro
    //    del cuerpo vaciado - nada que auditar.
    //  - ApplyBELLON ("DXR MCC Bellon Migr Phase2".MigrateTableExt_ItemFields()) tampoco fijaba tag
    //    propio - BELLON se dispatchea por case de codigo de concepto (case 'TE-ITEM':), sin tag
    //    interno por procedimiento.
    //  - ApplyDRLOC ("DXR MCC DRLOC Migr Phase2".MigrateItemNCFCategoryBackfill()) no fijaba tag
    //    propio tampoco: su guarda vive en el LLAMADOR, BootstrapItemNCFCategoryBackfill(), que sigue
    //    invocando el procedimiento (ahora no-op) y sigue fijando con normalidad su propio tag externo
    //    'DXR-T20260716-BackfillItemNCFCategory'. Ese literal SI esta seedeado (DRLOC-P2 #14,
    //    DXRMCCUpgradeTagSeed.Codeunit.al:207) pero como el guard es externo no queda huerfano - mismo
    //    caso exacto que DRLOC en Master Customer.
    //  - ApplyFE ("DXR MCC FE Migr Phase8".CopyItemFieldsInBatches()) tampoco fijaba tag propio: su
    //    tag ('DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625') vive en el trigger OnRun del
    //    codeunit contenedor, que cubre 4 tablas MAS (Currency/Post Code/Unit of Measure/VAT Posting
    //    Setup) ademas de Item y sigue corriendo y fijandose igual tras esta llamada ahora no-op. Ese
    //    literal SI esta seedeado (FE-P8 #2/307/308/309/310) y sigue vivo, sin cambio necesario.
    Permissions = tabledata Item = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(MasterTag()) then
            exit;
        MigrateItem();
        UpgradeTag.SetUpgradeTag(MasterTag());
    end;

    local procedure MasterTag(): Code[250]
    begin
        exit('DXR-MCC-MASTER-ITEM-20260827');
    end;

    local procedure MigrateItem()
    var
        Item: Record Item;
        ItemToUpdate: Record Item;
        RowsSinceCommit: Integer;
    begin
        Item.SetLoadFields("No.",
            "Payment Terms Code_DXR", "Payment Terms Code_Old", "Allow Decimals_DXR", "Allow Decimals_Old",
            "Modelo_DXR", Modelo, "Marca_DXR", Marca, "Se Detalla_DXR", "Se Detalla", "Producido_DXR",
            Producido, "Carga % Tarjeta_DXR", "Carga % Tarjeta", "Consignación_DXR", "Consignación",
            "Internal Use_DXR", "Internal Use", "Acepta Decimales_DXR", "Acepta Decimales", "Exhibición_DXR",
            "Exhibición", "Precio Sugerido_DXR", "Precio Sugerido", "Kit_DXR", Kit, "Empaque_DXR", Empaque,
            "Empaque Maestro_DXR", "Empaque Maestro", "Venta por Mayor_DXR", "Venta por Mayor",
            "% Comisión Venta_DXR", "% Comisión Venta", "% Comisión Cobro_DXR", "% Comisión Cobro",
            "Márgen Plaza_DXR", "Márgen Plaza", "Márgen Importación_DXR", "Márgen Importación",
            "Descripcion_Bellon_DXR", "Descripcion Bellon", "Costo Liquidacion_DXR", "Costo Liquidacion",
            "Comision_Tipo_ID_DXR.", Comision_Tipo_ID, "Ultimo Costo Bellon_DXR", "Ultimo Costo Bellon",
            "Costo Unitario Bellon_DXR", "Costo Unitario Bellon", "SANA Info Adicionales_DXR",
            "SANA - Info. Adicionales", "Sales Group_DXR", "Sales Group", "Sales SubGroup_DXR",
            "Sales SubGroup", "Sales Dept Code_DXR", "Sales Dept Code", "Codigo Producto Aduana_DXR",
            "Codigo Producto Aduana", "ExclFromDiscountCoupons_DXR", ExcludedFromDiscountCoupons,
            "ExclFromFreeShipCoupons_DXR", ExcludedFromFreeShipCoupons, "Disponible para Ventas_DXR",
            "Disponible para Ventas", "Item Status_DXR", "Item Status", "Control Existencia_DXR",
            "Control Existencia", "Descripcion Bellon_DXR", "DXR-DE Descripcion Bellon",
            "Gen. Prod. Posting Group", "NCF Category_DXR", "Applies for ISC_DXR", "EF Applies for ISC",
            "Tax Type_DXR", "EF Tax Type");
        if not Item.FindSet(false) then
            exit;
        repeat
            if RowNeedsWork(Item) then
                if ItemToUpdate.Get(Item."No.") then
                    if RowNeedsWork(ItemToUpdate) then begin
                        ItemToUpdate.Modify(false);
                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
        until Item.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsWork(var Item: Record Item): Boolean
    var
        Changed: Boolean;
    begin
        Changed := ApplyBELLON(Item) or Changed;
        Changed := ApplyBC(Item) or Changed;
        Changed := ApplyDESB(Item) or Changed;
        Changed := ApplyDRLOC(Item) or Changed;
        Changed := ApplyFE(Item) or Changed;
        exit(Changed);
    end;

    local procedure ApplyBELLON(var Item: Record Item): Boolean
    var
        Blank: Record Item;
        Changed: Boolean;
    begin
        if (Item."Modelo_DXR" <> Item.Modelo) or
           (Item."Marca_DXR" <> Item.Marca) or
           (Item."Se Detalla_DXR" <> Item."Se Detalla") or
           (Item."Producido_DXR" <> Item.Producido) or
           (Item."Carga % Tarjeta_DXR" <> Item."Carga % Tarjeta") or
           (Item."Consignación_DXR" <> Item."Consignación") or
           (Item."Internal Use_DXR" <> Item."Internal Use") or
           (Item."Acepta Decimales_DXR" <> Item."Acepta Decimales") or
           (Item."Exhibición_DXR" <> Item."Exhibición") or
           (Item."Precio Sugerido_DXR" <> Item."Precio Sugerido") or
           (Item."Kit_DXR" <> Item.Kit) or
           (Item."Empaque_DXR" <> Item.Empaque) or
           (Item."Empaque Maestro_DXR" <> Item."Empaque Maestro") or
           (Item."Venta por Mayor_DXR" <> Item."Venta por Mayor") or
           (Item."% Comisión Venta_DXR" <> Item."% Comisión Venta") or
           (Item."% Comisión Cobro_DXR" <> Item."% Comisión Cobro") or
           (Item."Márgen Plaza_DXR" <> Item."Márgen Plaza") or
           (Item."Márgen Importación_DXR" <> Item."Márgen Importación") or
           (Item."Descripcion_Bellon_DXR" <> Item."Descripcion Bellon") or
           (Item."Costo Liquidacion_DXR" <> Item."Costo Liquidacion") or
           (Item."Comision_Tipo_ID_DXR." <> Item.Comision_Tipo_ID) or
           (Item."Ultimo Costo Bellon_DXR" <> Item."Ultimo Costo Bellon") or
           (Item."Costo Unitario Bellon_DXR" <> Item."Costo Unitario Bellon") or
           (Item."SANA Info Adicionales_DXR" <> Item."SANA - Info. Adicionales") or
           (Item."Sales Group_DXR" <> Item."Sales Group") or
           (Item."Sales SubGroup_DXR" <> Item."Sales SubGroup") or
           (Item."Sales Dept Code_DXR" <> Item."Sales Dept Code") or
           (Item."Codigo Producto Aduana_DXR" <> Item."Codigo Producto Aduana") or
           (Item."ExclFromDiscountCoupons_DXR" <> Item.ExcludedFromDiscountCoupons) or
           (Item."ExclFromFreeShipCoupons_DXR" <> Item.ExcludedFromFreeShipCoupons) or
           (Item."Disponible para Ventas_DXR" <> Item."Disponible para Ventas") or
           (Item."Item Status_DXR" <> Item."Item Status") or
           (Item."Control Existencia_DXR" <> Item."Control Existencia")
        then begin
            if Item."Modelo_DXR" = Blank."Modelo_DXR" then begin
                Item."Modelo_DXR" := Item.Modelo;
                Changed := true;
            end;
            if Item."Marca_DXR" = Blank."Marca_DXR" then begin
                Item."Marca_DXR" := Item.Marca;
                Changed := true;
            end;
            if Item."Se Detalla_DXR" = Blank."Se Detalla_DXR" then begin
                Item."Se Detalla_DXR" := Item."Se Detalla";
                Changed := true;
            end;
            if Item."Producido_DXR" = Blank."Producido_DXR" then begin
                Item."Producido_DXR" := Item.Producido;
                Changed := true;
            end;
            if Item."Carga % Tarjeta_DXR" = Blank."Carga % Tarjeta_DXR" then begin
                Item."Carga % Tarjeta_DXR" := Item."Carga % Tarjeta";
                Changed := true;
            end;
            if Item."Consignación_DXR" = Blank."Consignación_DXR" then begin
                Item."Consignación_DXR" := Item."Consignación";
                Changed := true;
            end;
            if Item."Internal Use_DXR" = Blank."Internal Use_DXR" then begin
                Item."Internal Use_DXR" := Item."Internal Use";
                Changed := true;
            end;
            if Item."Acepta Decimales_DXR" = Blank."Acepta Decimales_DXR" then begin
                Item."Acepta Decimales_DXR" := Item."Acepta Decimales";
                Changed := true;
            end;
            if Item."Exhibición_DXR" = Blank."Exhibición_DXR" then begin
                Item."Exhibición_DXR" := Item."Exhibición";
                Changed := true;
            end;
            if Item."Precio Sugerido_DXR" = Blank."Precio Sugerido_DXR" then begin
                Item."Precio Sugerido_DXR" := Item."Precio Sugerido";
                Changed := true;
            end;
            if Item."Kit_DXR" = Blank."Kit_DXR" then begin
                Item."Kit_DXR" := Item.Kit;
                Changed := true;
            end;
            if Item."Empaque_DXR" = Blank."Empaque_DXR" then begin
                Item."Empaque_DXR" := Item.Empaque;
                Changed := true;
            end;
            if Item."Empaque Maestro_DXR" = Blank."Empaque Maestro_DXR" then begin
                Item."Empaque Maestro_DXR" := Item."Empaque Maestro";
                Changed := true;
            end;
            if Item."Venta por Mayor_DXR" = Blank."Venta por Mayor_DXR" then begin
                Item."Venta por Mayor_DXR" := Item."Venta por Mayor";
                Changed := true;
            end;
            if Item."% Comisión Venta_DXR" = Blank."% Comisión Venta_DXR" then begin
                Item."% Comisión Venta_DXR" := Item."% Comisión Venta";
                Changed := true;
            end;
            if Item."% Comisión Cobro_DXR" = Blank."% Comisión Cobro_DXR" then begin
                Item."% Comisión Cobro_DXR" := Item."% Comisión Cobro";
                Changed := true;
            end;
            if Item."Márgen Plaza_DXR" = Blank."Márgen Plaza_DXR" then begin
                Item."Márgen Plaza_DXR" := Item."Márgen Plaza";
                Changed := true;
            end;
            if Item."Márgen Importación_DXR" = Blank."Márgen Importación_DXR" then begin
                Item."Márgen Importación_DXR" := Item."Márgen Importación";
                Changed := true;
            end;
            if Item."Descripcion_Bellon_DXR" = Blank."Descripcion_Bellon_DXR" then begin
                Item."Descripcion_Bellon_DXR" := Item."Descripcion Bellon";
                Changed := true;
            end;
            if Item."Costo Liquidacion_DXR" = Blank."Costo Liquidacion_DXR" then begin
                Item."Costo Liquidacion_DXR" := Item."Costo Liquidacion";
                Changed := true;
            end;
            if Item."Comision_Tipo_ID_DXR." = Blank."Comision_Tipo_ID_DXR." then begin
                Item."Comision_Tipo_ID_DXR." := Item.Comision_Tipo_ID;
                Changed := true;
            end;
            if Item."Ultimo Costo Bellon_DXR" = Blank."Ultimo Costo Bellon_DXR" then begin
                Item."Ultimo Costo Bellon_DXR" := Item."Ultimo Costo Bellon";
                Changed := true;
            end;
            if Item."Costo Unitario Bellon_DXR" = Blank."Costo Unitario Bellon_DXR" then begin
                Item."Costo Unitario Bellon_DXR" := Item."Costo Unitario Bellon";
                Changed := true;
            end;
            if Item."SANA Info Adicionales_DXR" = Blank."SANA Info Adicionales_DXR" then begin
                Item."SANA Info Adicionales_DXR" := Item."SANA - Info. Adicionales";
                Changed := true;
            end;
            if Item."Sales Group_DXR" = Blank."Sales Group_DXR" then begin
                Item."Sales Group_DXR" := Item."Sales Group";
                Changed := true;
            end;
            if Item."Sales SubGroup_DXR" = Blank."Sales SubGroup_DXR" then begin
                Item."Sales SubGroup_DXR" := Item."Sales SubGroup";
                Changed := true;
            end;
            if Item."Sales Dept Code_DXR" = Blank."Sales Dept Code_DXR" then begin
                Item."Sales Dept Code_DXR" := Item."Sales Dept Code";
                Changed := true;
            end;
            if Item."Codigo Producto Aduana_DXR" = Blank."Codigo Producto Aduana_DXR" then begin
                Item."Codigo Producto Aduana_DXR" := Item."Codigo Producto Aduana";
                Changed := true;
            end;
            if Item."ExclFromDiscountCoupons_DXR" = Blank."ExclFromDiscountCoupons_DXR" then begin
                Item."ExclFromDiscountCoupons_DXR" := Item.ExcludedFromDiscountCoupons;
                Changed := true;
            end;
            if Item."ExclFromFreeShipCoupons_DXR" = Blank."ExclFromFreeShipCoupons_DXR" then begin
                Item."ExclFromFreeShipCoupons_DXR" := Item.ExcludedFromFreeShipCoupons;
                Changed := true;
            end;
            if Item."Disponible para Ventas_DXR" = Blank."Disponible para Ventas_DXR" then begin
                Item."Disponible para Ventas_DXR" := Item."Disponible para Ventas";
                Changed := true;
            end;
            if Item."Item Status_DXR" = Blank."Item Status_DXR" then begin
                Item."Item Status_DXR" := Item."Item Status";
                Changed := true;
            end;
            if Item."Control Existencia_DXR" = Blank."Control Existencia_DXR" then begin
                Item."Control Existencia_DXR" := Item."Control Existencia";
                Changed := true;
            end;
        end;
        exit(Changed);
    end;

    local procedure ApplyBC(var Item: Record Item): Boolean
    var
        Changed: Boolean;
    begin
        if (Item."Payment Terms Code_DXR" = '') and (Item."Payment Terms Code_Old" <> '') then begin
            Item."Payment Terms Code_DXR" := Item."Payment Terms Code_Old";
            Changed := true;
        end;
        if (not Item."Allow Decimals_DXR") and Item."Allow Decimals_Old" then begin
            Item."Allow Decimals_DXR" := true;
            Changed := true;
        end;
        exit(Changed);
    end;

    local procedure ApplyDESB(var Item: Record Item): Boolean
    var
        Blank: Record Item;
        Changed: Boolean;
    begin
        if Item."Descripcion Bellon_DXR" <> Item."DXR-DE Descripcion Bellon" then
            if Item."Descripcion Bellon_DXR" = Blank."Descripcion Bellon_DXR" then begin
                Item."Descripcion Bellon_DXR" := Item."DXR-DE Descripcion Bellon";
                Changed := true;
            end;
        exit(Changed);
    end;

    local procedure ApplyDRLOC(var Item: Record Item): Boolean
    var
        Blank: Record Item;
        NCFCategory: Code[20];
        Changed: Boolean;
    begin
        // Fuente: "DXR MCC DRLOC Migr Phase2".MigrateItemNCFCategoryBackfill(). A diferencia de los
        // demas bloques, el valor a copiar no es otro campo de Item: se calcula por lookup via
        // TryGetItemNcfCategoryLocal (Gen. Prod. Posting Group -> General Posting Setup -> G/L
        // Account), movido tal cual junto con este bloque.
        if TryGetItemNcfCategoryLocal(Item, NCFCategory) and (Item."NCF Category_DXR" <> NCFCategory) then
            if Item."NCF Category_DXR" = Blank."NCF Category_DXR" then begin
                Item."NCF Category_DXR" := NCFCategory;
                Changed := true;
            end;
        exit(Changed);
    end;

    local procedure TryGetItemNcfCategoryLocal(Item: Record Item; var NCFCategory: Code[20]): Boolean
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        Clear(NCFCategory);
        if Item."Gen. Prod. Posting Group" = '' then
            exit(false);

        GeneralPostingSetup.SetLoadFields("Purch. Account");
        GLAccount.SetLoadFields("NCFCategories_DXR");
        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                if GLAccount.Get(GeneralPostingSetup."Purch. Account") and (GLAccount."NCFCategories_DXR" <> '') then begin
                    NCFCategory := GLAccount."NCFCategories_DXR";
                    exit(true);
                end;
            until GeneralPostingSetup.Next() = 0;

        exit(false);
    end;

    local procedure ApplyFE(var Item: Record Item): Boolean
    var
        Blank: Record Item;
        Changed: Boolean;
    begin
        if (Item."Applies for ISC_DXR" <> Item."EF Applies for ISC") or
           (Item."Tax Type_DXR" <> Item."EF Tax Type")
        then begin
            if Item."Applies for ISC_DXR" = Blank."Applies for ISC_DXR" then begin
                Item."Applies for ISC_DXR" := Item."EF Applies for ISC";
                Changed := true;
            end;
            if Item."Tax Type_DXR" = Blank."Tax Type_DXR" then begin
                Item."Tax Type_DXR" := Item."EF Tax Type";
                Changed := true;
            end;
        end;
        exit(Changed);
    end;
}
