codeunit 60150 "DXR MCC Bellon Migr Phase6"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 6 Table ID" (56123) -> "Bellon Upgrade Process".MigrateAllRenumberedDXRTables(). A
    // later commit renumbered 114 custom DXR_ tables directly in-place (edited the ID literal on
    // the same table declaration, e.g. table 59231 "DXR_Agente" -> table 53301 "DXR_Agente"),
    // instead of the safe preserve-old/add-new pattern already established elsewhere in this same
    // repo. The 114 tables were restored at their original 59xxx IDs (ObsoleteState = Pending,
    // AL name suffixed " Old2" to disambiguate from the active 53xxx table of the same base name)
    // so publish does not attempt to remove them; this phase copies every row across.
    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-TableIdRenumberRestore283') then
            exit;

        MigrateAllRenumberedDXRTables();

        UpgradeTag.SetUpgradeTag('DXR-TableIdRenumberRestore283');
    end;

    // Copies every row of a legacy table (OldTableId) to its DXR_ clone (NewTableId) by field
    // NUMBER (both tables share identical field IDs/types - the restored Old2 clone preserves the
    // full schema unmodified), Class=Normal only on both sides. Idempotent per table: if the
    // destination already has rows, does nothing.
    local procedure MigrateLegacyTableData(OldTableId: Integer; NewTableId: Integer)
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
        FieldIdx: Integer;
    begin
        NewRecRef.Open(NewTableId);
        if not NewRecRef.IsEmpty() then begin
            NewRecRef.Close();
            exit;
        end;
        NewRecRef.Close();

        OldRecRef.Open(OldTableId);
        if OldRecRef.FindSet() then
            repeat
                NewRecRef.Open(NewTableId);
                NewRecRef.Init();
                for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                    OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                    if (OldFieldRef.Class() = FieldClass::Normal) and NewRecRef.FieldExist(OldFieldRef.Number()) then begin
                        NewFieldRef := NewRecRef.Field(OldFieldRef.Number());
                        if NewFieldRef.Class() = FieldClass::Normal then
                            NewFieldRef.Value := OldFieldRef.Value();
                    end;
                end;
                NewRecRef.Insert(false);
            until OldRecRef.Next() = 0;
        OldRecRef.Close();
    end;

    // ===== 16 SETUP-category "Old2" whole-table restores converted to native typed logic =====
    // Task A.4 Batch 4: zero RecordRef/FieldRef, zero TransferFields - every field assigned
    // explicitly. Replaces 16 of the MigrateLegacyTableData(...) calls above (still used by ~98
    // other, out-of-scope "Old2" tables in MigrateAllRenumberedDXRTables()) and eliminates, for
    // these 16 tables specifically, the same real production bug in MigrateLegacyTableData
    // documented for Phase2/Phase6's own generic helper (NewRecRef.Open inside the repeat/until
    // loop without closing between iterations, throwing "The record is already open." from the
    // 2nd+ row of any multi-row table). Each of these 16 tables' final destination (53xxx) is the
    // SAME table a sibling BELLON-P2 concept (already converted in DXRMCCBellonMigrPhase2's own
    // Task A.4 Batches 1-3, reviewed clean) already writes to from a DIFFERENT legacy source
    // (50xxx). Both procedures do a Get()-before-Insert() against the same destination table -
    // intentional and idempotent, not a conflict. Field lists and primary keys verified
    // independently against this batch's real Tables.old2\*.Table.al (Old2 legacy) and
    // Tables\*.Table.al (DXR_ new) sources - field-for-field identical on both sides for all 16
    // tables in this batch (each Old2 table is a byte-for-byte schema restore of its DXR_ clone at
    // the pre-renumbering ID), no renamed/shadow fields found.

    // seq158: DXR_AGR Setup Old2 (59233) -> DXR_AGR Setup (53303). PK = "Primary Key".
    local procedure MigrateAGRSetupOld2Table()
    var
        Legacy: Record "DXR_AGR Setup Old2";
        New: Record "DXR_AGR Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Primary Key") then begin
                    New.Init();
                    New."Primary Key" := Legacy."Primary Key";
                    New."SQL Server" := Legacy."SQL Server";
                    New."SQL User ID" := Legacy."SQL User ID";
                    New."SQL Password" := Legacy."SQL Password";
                    New."SQL Database" := Legacy."SQL Database";
                    New."SQL Connection Timeout" := Legacy."SQL Connection Timeout";
                    New."Enable Log Cleanup" := Legacy."Enable Log Cleanup";
                    New."Keep History for" := Legacy."Keep History for";
                    New."Last Cleanup" := Legacy."Last Cleanup";
                    New."Req. Worksh. Template Name" := Legacy."Req. Worksh. Template Name";
                    New."Req. Worksh. Jrnl. Batch Name" := Legacy."Req. Worksh. Jrnl. Batch Name";
                    New."Plan. Worksh. Template Name" := Legacy."Plan. Worksh. Template Name";
                    New."Plan. Worksh. Jrnl. Batch Name" := Legacy."Plan. Worksh. Jrnl. Batch Name";
                    New.ProdOrderChoice := Legacy.ProdOrderChoice;
                    New.PurchOrderChoice := Legacy.PurchOrderChoice;
                    New.TransOrderChoice := Legacy.TransOrderChoice;
                    New.AsmOrderChoice := Legacy.AsmOrderChoice;
                    New."Auto Refresh Production Order" := Legacy."Auto Refresh Production Order";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq159: DXR_Ajuste Inventario Con Old2 (59234) -> DXR_Ajuste Inventario Config (53304).
    // PK = ("Item Padre", "Item Padre UM").
    local procedure MigrateAjusteInventarioConfigOld2Table()
    var
        Legacy: Record "DXR_Ajuste Inventario Con Old2";
        New: Record "DXR_Ajuste Inventario Config";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Item Padre", Legacy."Item Padre UM") then begin
                    New.Init();
                    New."Item Padre" := Legacy."Item Padre";
                    New."Item Padre UM" := Legacy."Item Padre UM";
                    New."Item Hijo" := Legacy."Item Hijo";
                    New."Item Hijo UM" := Legacy."Item Hijo UM";
                    New."Cant. x UM Padre" := Legacy."Cant. x UM Padre";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq161: DXR_Area de Trabajo Old2 (59236) -> DXR_Area de Trabajo (53306). PK = "Code".
    local procedure MigrateAreaDeTrabajoOld2Table()
    var
        Legacy: Record "DXR_Area de Trabajo Old2";
        New: Record "DXR_Area de Trabajo";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Code") then begin
                    New.Init();
                    New."Code" := Legacy."Code";
                    New.Descripcion := Legacy.Descripcion;
                    New.Estado := Legacy.Estado;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq168: DXR_Categoria Servicios Old2 (59243) -> DXR_Categoria Servicios (53313).
    // PK = "ID Services".
    local procedure MigrateCategoriaServiciosOld2Table()
    var
        Legacy: Record "DXR_Categoria Servicios Old2";
        New: Record "DXR_Categoria Servicios";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."ID Services") then begin
                    New.Init();
                    New."ID Services" := Legacy."ID Services";
                    New."Type Services" := Legacy."Type Services";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq170: DXR_Cilindros - Setup Old2 (59245) -> DXR_Cilindros - Setup (53315). PK = "Key".
    local procedure MigrateCilindrosSetupOld2Table()
    var
        Legacy: Record "DXR_Cilindros - Setup Old2";
        New: Record "DXR_Cilindros - Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."Cilindros No. Series" := Legacy."Cilindros No. Series";
                    New."Mov. Cilindros No. Series" := Legacy."Mov. Cilindros No. Series";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq172: DXR_Conf. Extracto Bancar Old2 (59248) -> DXR_Conf. Extracto Bancario (53318).
    // PK = "Key".
    local procedure MigrateConfExtractoBancarioOld2Table()
    var
        Legacy: Record "DXR_Conf. Extracto Bancar Old2";
        New: Record "DXR_Conf. Extracto Bancario";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New.Active := Legacy.Active;
                    New."Folder Patch" := Legacy."Folder Patch";
                    New."Days Run" := Legacy."Days Run";
                    New."Date Tolerance" := Legacy."Date Tolerance";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq173: DXR_Config. NCF Ventas Old2 (59249) -> DXR_Config. NCF Ventas (53319).
    // PK = "Código".
    local procedure MigrateConfigNCFVentasOld2Table()
    var
        Legacy: Record "DXR_Config. NCF Ventas Old2";
        New: Record "DXR_Config. NCF Ventas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Código") then begin
                    New.Init();
                    New."Código" := Legacy."Código";
                    New."Descripción" := Legacy."Descripción";
                    New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
                    New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
                    New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
                    New."Tipo NCF" := Legacy."Tipo NCF";
                    New."Alternal No. Series_DXR" := Legacy."Alternal No. Series_DXR";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq174: DXR_Config. NCF Ventas ST Old2 (59250) -> DXR_Config. NCF Ventas STD (53320).
    // PK = ("Código", "Terminal No.").
    local procedure MigrateConfigNCFVentasSTDOld2Table()
    var
        Legacy: Record "DXR_Config. NCF Ventas ST Old2";
        New: Record "DXR_Config. NCF Ventas STD";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Código", Legacy."Terminal No.") then begin
                    New.Init();
                    New."Código" := Legacy."Código";
                    New."Descripción" := Legacy."Descripción";
                    New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
                    New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
                    New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
                    New."Store No." := Legacy."Store No.";
                    New."Terminal No." := Legacy."Terminal No.";
                    New."Tipo NCF" := Legacy."Tipo NCF";
                    New."Alternal No. Series_DXR" := Legacy."Alternal No. Series_DXR";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq175: DXR_Config. Polizas Old2 (59251) -> DXR_Config. Polizas (53321).
    // PK = ("Fecha Desde", "Fecha Hasta", "Monto Minimo", "Monto Maximo").
    local procedure MigrateConfigPolizasOld2Table()
    var
        Legacy: Record "DXR_Config. Polizas Old2";
        New: Record "DXR_Config. Polizas";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Fecha Desde", Legacy."Fecha Hasta", Legacy."Monto Minimo", Legacy."Monto Maximo") then begin
                    New.Init();
                    New."Fecha Desde" := Legacy."Fecha Desde";
                    New."Fecha Hasta" := Legacy."Fecha Hasta";
                    New."Monto Minimo" := Legacy."Monto Minimo";
                    New."Monto Maximo" := Legacy."Monto Maximo";
                    New."Cantidad Cilindros" := Legacy."Cantidad Cilindros";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq176: DXR_Configuracion CB Old2 (59252) -> DXR_Configuracion CB (53322).
    // PK = (Bloque, "Reason Codes Filter", Orden).
    local procedure MigrateConfiguracionCBOld2Table()
    var
        Legacy: Record "DXR_Configuracion CB Old2";
        New: Record "DXR_Configuracion CB";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Bloque, Legacy."Reason Codes Filter", Legacy.Orden) then begin
                    New.Init();
                    New.Bloque := Legacy.Bloque;
                    New.Orden := Legacy.Orden;
                    New."Descripcion Renglon" := Legacy."Descripcion Renglon";
                    New."Reason Codes Filter" := Legacy."Reason Codes Filter";
                    New.Orientacion := Legacy.Orientacion;
                    New.Transito := Legacy.Transito;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq177: DXR_Config - Discr Old2 (59253) -> DXR_Config - Discr (53323). PK = "key".
    local procedure MigrateConfiguracionDiscrepanciasOld2Table()
    var
        Legacy: Record "DXR_Config - Discr Old2";
        New: Record "DXR_Config - Discr";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."key") then begin
                    New.Init();
                    New."key" := Legacy."key";
                    New."URL - Archivos Temporal" := Legacy."URL - Archivos Temporal";
                    New."URL  - Archivos Registrados" := Legacy."URL  - Archivos Registrados";
                    New."URL - Archivos Eliminados" := Legacy."URL - Archivos Eliminados";
                    New."No. Serie Discrepancia" := Legacy."No. Serie Discrepancia";
                    New."No. Serie Discrep. Registrada" := Legacy."No. Serie Discrep. Registrada";
                    New.AutoPost := Legacy.AutoPost;
                    New."Max Cantidad Dias retrocede" := Legacy."Max Cantidad Dias retrocede";
                    New."URL Lectura - Archivos Temp." := Legacy."URL Lectura - Archivos Temp.";
                    New."URL Lectura - Archivos Regis." := Legacy."URL Lectura - Archivos Regis.";
                    New."URL Lectura - Archivos Elimin." := Legacy."URL Lectura - Archivos Elimin.";
                    New."Reg Prod. in Discre." := Legacy."Reg Prod. in Discre.";
                    New."Control Disc. sin Attch" := Legacy."Control Disc. sin Attch";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq178: DXR_Config Encuestas - PO Old2 (59254) -> DXR_Config Encuestas - POS (53324).
    // PK = ("Store No.", "Pos Terminal No.", "Transacction No.").
    local procedure MigrateConfiguracionEncuestasPOSOld2Table()
    var
        Legacy: Record "DXR_Config Encuestas - PO Old2";
        New: Record "DXR_Config Encuestas - POS";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Store No.", Legacy."Pos Terminal No.", Legacy."Transacction No.") then begin
                    New.Init();
                    New."Store No." := Legacy."Store No.";
                    New."Pos Terminal No." := Legacy."Pos Terminal No.";
                    New."Transacction No." := Legacy."Transacction No.";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq179: DXR_Config Req Old2 (59255) -> DXR_Config Req (53325). PK = "Key" (AutoIncrement on
    // both sides). Same field, same AutoIncrement attribute, already precedent-set by the sibling
    // BELLON-P2 procedure MigrateConfiguracionesRequisicionTable() (Configuraciones Requisicion
    // 50038 -> DXR_Config Req 53325, reviewed clean) - explicit non-zero legacy values are honored
    // by AutoIncrement (it only auto-assigns when the field is 0), so the value is copied directly
    // like every other field, consistent with that established sibling pattern.
    local procedure MigrateConfiguracionesRequisicionOld2Table()
    var
        Legacy: Record "DXR_Config Req Old2";
        New: Record "DXR_Config Req";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."No. Serie Pre-Req" := Legacy."No. Serie Pre-Req";
                    New."No Serie Req" := Legacy."No Serie Req";
                    New."No Serie Pre-Req No Stock" := Legacy."No Serie Pre-Req No Stock";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq180: DXR_Configuracion - MEDAL Old2 (59256) -> DXR_Configuracion - MEDALLIA (53326).
    // PK = "Key".
    local procedure MigrateConfiguracionMedalliaOld2Table()
    var
        Legacy: Record "DXR_Configuracion - MEDAL Old2";
        New: Record "DXR_Configuracion - MEDALLIA";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New."Key" := Legacy."Key";
                    New."Log Request" := Legacy."Log Request";
                    New."Log Response" := Legacy."Log Response";
                    New.MedalliaURL := Legacy.MedalliaURL;
                    New.UserCredentials := Legacy.UserCredentials;
                    New.PasswordCredentials := Legacy.PasswordCredentials;
                    New."Pedido Ventas" := Legacy."Pedido Ventas";
                    New.Transportacion := Legacy.Transportacion;
                    New."Facturas POS" := Legacy."Facturas POS";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq181: DXR_Conf. Pagos Ecommerce Old2 (59257) -> DXR_Conf. Pagos Ecommerce Azul (53327).
    // PK = "Key".
    local procedure MigrateConfPagosEcommerceAzulOld2Table()
    var
        Legacy: Record "DXR_Conf. Pagos Ecommerce Old2";
        New: Record "DXR_Conf. Pagos Ecommerce Azul";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Key") then begin
                    New.Init();
                    New.MerchantID := Legacy.MerchantID;
                    New.MerchantName := Legacy.MerchantName;
                    New.MerchantType := Legacy.MerchantType;
                    New.CurrencyCode := Legacy.CurrencyCode;
                    New.ApprovedURL := Legacy.ApprovedURL;
                    New.DeclinedURL := Legacy.DeclinedURL;
                    New.CancelURL := Legacy.CancelURL;
                    New.LogoURL := Legacy.LogoURL;
                    New.ProductImageURL := Legacy.ProductImageURL;
                    New.DesignV2 := Legacy.DesignV2;
                    New.Locale := Legacy.Locale;
                    New.AuthKey := Legacy.AuthKey;
                    New.PaymentPageUrl := Legacy.PaymentPageUrl;
                    New."Key" := Legacy."Key";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq182: DXR_Control Proc por Alma Old2 (59258) -> DXR_Control Proc por Almacen (53328).
    // PK = "Location Code".
    local procedure MigrateControlProcesosPorAlmacenOld2Table()
    var
        Legacy: Record "DXR_Control Proc por Alma Old2";
        New: Record "DXR_Control Proc por Almacen";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Location Code") then begin
                    New.Init();
                    New."Location Code" := Legacy."Location Code";
                    New.Ventas := Legacy.Ventas;
                    New.Compras := Legacy.Compras;
                    New.Ajustes := Legacy.Ajustes;
                    New.Ensamblados := Legacy.Ensamblados;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    local procedure MigrateAllRenumberedDXRTables()
    begin
        MigrateLegacyTableData(59231, 53301); // DXR_Agente restored at true original ID
        MigrateLegacyTableData(59232, 53302); // DXR_AGR Log restored at true original ID
        MigrateAGRSetupOld2Table(); // DXR_AGR Setup Old2 (59233) -> DXR_AGR Setup (53303) - native
        MigrateAjusteInventarioConfigOld2Table(); // DXR_Ajuste Inventario Con Old2 (59234) -> DXR_Ajuste Inventario Config (53304) - native
        MigrateLegacyTableData(59235, 53305); // DXR_Archivo - Discrepancias restored at true original ID
        MigrateAreaDeTrabajoOld2Table(); // DXR_Area de Trabajo Old2 (59236) -> DXR_Area de Trabajo (53306) - native
        MigrateLegacyTableData(59237, 53307); // DXR_Bancos - Extracto Bancario restored at true original ID
        MigrateLegacyTableData(59238, 53308); // DXR_Bank restored at true original ID
        MigrateLegacyTableData(59239, 53309); // DXR_Bank Relation restored at true original ID
        MigrateLegacyTableData(59240, 53310); // DXR_Black List Promotion restored at true original ID
        MigrateLegacyTableData(59241, 53311); // DXR_Cabecera Discrepancia restored at true original ID
        MigrateLegacyTableData(59242, 53312); // DXR_Carga Masiva Benef BPD restored at true original ID
        MigrateCategoriaServiciosOld2Table(); // DXR_Categoria Servicios Old2 (59243) -> DXR_Categoria Servicios (53313) - native
        MigrateLegacyTableData(59244, 53314); // DXR_Cilindros restored at true original ID
        MigrateCilindrosSetupOld2Table(); // DXR_Cilindros - Setup Old2 (59245) -> DXR_Cilindros - Setup (53315) - native
        MigrateLegacyTableData(59247, 53317); // DXR_Comentario - Discrepancias restored at true original ID (59246/Codigos de Auditoria has no Old2 counterpart - confirmed skip)
        MigrateConfExtractoBancarioOld2Table(); // DXR_Conf. Extracto Bancar Old2 (59248) -> DXR_Conf. Extracto Bancario (53318) - native
        MigrateConfigNCFVentasOld2Table(); // DXR_Config. NCF Ventas Old2 (59249) -> DXR_Config. NCF Ventas (53319) - native
        MigrateConfigNCFVentasSTDOld2Table(); // DXR_Config. NCF Ventas ST Old2 (59250) -> DXR_Config. NCF Ventas STD (53320) - native
        MigrateConfigPolizasOld2Table(); // DXR_Config. Polizas Old2 (59251) -> DXR_Config. Polizas (53321) - native
        MigrateConfiguracionCBOld2Table(); // DXR_Configuracion CB Old2 (59252) -> DXR_Configuracion CB (53322) - native
        MigrateConfiguracionDiscrepanciasOld2Table(); // DXR_Config - Discr Old2 (59253) -> DXR_Config - Discr (53323) - native
        MigrateConfiguracionEncuestasPOSOld2Table(); // DXR_Config Encuestas - PO Old2 (59254) -> DXR_Config Encuestas - POS (53324) - native
        MigrateConfiguracionesRequisicionOld2Table(); // DXR_Config Req Old2 (59255) -> DXR_Config Req (53325) - native
        MigrateConfiguracionMedalliaOld2Table(); // DXR_Configuracion - MEDAL Old2 (59256) -> DXR_Configuracion - MEDALLIA (53326) - native
        MigrateConfPagosEcommerceAzulOld2Table(); // DXR_Conf. Pagos Ecommerce Old2 (59257) -> DXR_Conf. Pagos Ecommerce Azul (53327) - native
        MigrateControlProcesosPorAlmacenOld2Table(); // DXR_Control Proc por Alma Old2 (59258) -> DXR_Control Proc por Almacen (53328) - native
        MigrateLegacyTableData(59259, 53329); // DXR_Conversion Costo restored at true original ID
        MigrateLegacyTableData(59260, 53330); // DXR_Departamento - Discr restored at true original ID
        MigrateLegacyTableData(59261, 53331); // DXR_Detalle - Extr Bancario restored at true original ID
        MigrateLegacyTableData(59262, 53332); // DXR_Draw Setup restored at true original ID
        MigrateLegacyTableData(59263, 53333); // DXR_Email Source Tmpl Rel restored at true original ID
        MigrateLegacyTableData(59264, 53334); // DXR_Entrega Fact CxC - Lines restored at true original ID
        MigrateLegacyTableData(59265, 53335); // DXR_Envio Compras restored at true original ID
        MigrateLegacyTableData(59266, 53336); // DXR_EPagos Setup restored at true original ID
        MigrateLegacyTableData(59267, 53337); // DXR_Exclude Filter Journal restored at true original ID
        MigrateLegacyTableData(59268, 53338); // DXR_Excluir Term - ItemSearch restored at true original ID
        MigrateLegacyTableData(59269, 53339); // DXR_File Structure restored at true original ID
        MigrateLegacyTableData(59270, 53340); // DXR_Forma de Pago restored at true original ID
        MigrateLegacyTableData(59271, 53341); // DXR_HisCargaMasivaBenefBPD restored at true original ID
        MigrateLegacyTableData(59272, 53342); // DXR_Grupo Venta restored at true original ID
        MigrateLegacyTableData(59273, 53343); // DXR_HisLinCargaMasivaBenefBPD restored at true original ID
        MigrateLegacyTableData(59274, 53344); // DXR_Hist. Beneficiarios BPD restored at true original ID
        MigrateLegacyTableData(59275, 53345); // DXR_Hist. Cabecera Discr restored at true original ID
        MigrateLegacyTableData(59276, 53346); // DXR_Hist. de Ganadores restored at true original ID
        MigrateLegacyTableData(59277, 53347); // DXR_Hist. Int Consump. Header restored at true original ID
        MigrateLegacyTableData(59278, 53348); // DXR_Hist. Int Consump. Line restored at true original ID
        MigrateLegacyTableData(59279, 53349); // DXR_Hist. Linea Discrepancia restored at true original ID
        MigrateLegacyTableData(59280, 53350); // DXR_Historico Enc Requisicion restored at true original ID
        MigrateLegacyTableData(59281, 53351); // DXR_Historico - Extr Bancario restored at true original ID
        MigrateLegacyTableData(59282, 53352); // DXR_Historico Requisicion Line restored at true original ID
        MigrateLegacyTableData(59283, 53353); // DXR_Hist Pre-Requisicion restored at true original ID
        MigrateLegacyTableData(59284, 53354); // DXR_Hist Pre-Requisicion Line restored at true original ID
        MigrateLegacyTableData(59285, 53355); // DXR_Int Consump Header restored at true original ID
        MigrateLegacyTableData(59286, 53356); // DXR_Internal Consumption Line restored at true original ID
        MigrateLegacyTableData(59287, 53357); // DXR_Internal Consumption Log restored at true original ID
        MigrateLegacyTableData(59288, 53358); // DXR_Inventory Masks restored at true original ID
        MigrateLegacyTableData(59289, 53359); // DXR_Item HTML restored at true original ID
        MigrateLegacyTableData(59290, 53360); // DXR_Item Image View restored at true original ID
        MigrateLegacyTableData(59291, 53361); // DXR_ItemNo Desliquidacion restored at true original ID
        MigrateLegacyTableData(59292, 53362); // DXR_Journal Promotion Tickets restored at true original ID
        MigrateLegacyTableData(59293, 53363); // DXR_Linea Discrepancia restored at true original ID
        MigrateLegacyTableData(59294, 53364); // DXR_Lin Carga Masiva Ben. BPD restored at true original ID
        MigrateLegacyTableData(59295, 53365); // DXR_LineRQBuffer restored at true original ID
        MigrateLegacyTableData(59296, 53366); // DXR_Log - Bank Statement restored at true original ID
        MigrateLegacyTableData(59297, 53367); // DXR_Log Email restored at true original ID
        MigrateLegacyTableData(59298, 53368); // DXR_Log Transaccion Azul restored at true original ID
        MigrateLegacyTableData(59299, 53369); // DXR_Log Transaccion Medallia restored at true original ID
        MigrateLegacyTableData(59300, 53370); // DXR_Log Transfer error restored at true original ID
        MigrateLegacyTableData(59301, 53371); // DXR_Marcas restored at true original ID
        MigrateLegacyTableData(59302, 53372); // DXR_Member Management Setup restored at true original ID
        MigrateLegacyTableData(59303, 53373); // DXR_Motivo Cierre - Discr restored at true original ID
        MigrateLegacyTableData(59304, 53374); // DXR_Motivo Discrepancia restored at true original ID
        MigrateLegacyTableData(59305, 53375); // DXR_Movimientos de Cilindro restored at true original ID
        MigrateLegacyTableData(59306, 53376); // DXR_Order Item Status restored at true original ID
        MigrateLegacyTableData(59307, 53377); // DXR_Posted Jnl Promo Tickets restored at true original ID
        MigrateLegacyTableData(59308, 53378); // DXR_Pre Req LineNoStockValid restored at true original ID
        MigrateLegacyTableData(59309, 53379); // DXR_Pre Req no Stock Valid restored at true original ID
        MigrateLegacyTableData(59310, 53380); // DXR_Pre-Requisicion restored at true original ID
        MigrateLegacyTableData(59311, 53381); // DXR_Pre-Requisicion Line restored at true original ID
        MigrateLegacyTableData(59312, 53382); // DXR_Pre-Req Line No Stock restored at true original ID
        MigrateLegacyTableData(59313, 53383); // DXR_Pre-Requisicion no Stock restored at true original ID
        MigrateLegacyTableData(59314, 53384); // DXR_Printing Invoice Log restored at true original ID
        MigrateLegacyTableData(59315, 53385); // DXR_Profesion restored at true original ID
        MigrateLegacyTableData(59316, 53386); // DXR_Promotion Setup restored at true original ID
        MigrateLegacyTableData(59317, 53387); // DXR_Promotion Tickets Relation restored at true original ID
        MigrateLegacyTableData(59318, 53388); // DXR_Provincia restored at true original ID
        MigrateLegacyTableData(59319, 53389); // DXR_Requisicion restored at true original ID
        MigrateLegacyTableData(59320, 53390); // DXR_Requisicion Comment Line restored at true original ID
        MigrateLegacyTableData(59321, 53391); // DXR_Requisicion Line restored at true original ID
        MigrateLegacyTableData(59322, 53392); // DXR_Sales Dept restored at true original ID
        MigrateLegacyTableData(59323, 53393); // DXR_Sales Groups restored at true original ID
        MigrateLegacyTableData(59324, 53394); // DXR_Sales SubGroups restored at true original ID
        MigrateLegacyTableData(59325, 53395); // DXR_Send Email Log restored at true original ID
        MigrateLegacyTableData(59326, 53396); // DXR_Std POS DASCOM Paymt Eqv restored at true original ID
        MigrateLegacyTableData(59327, 53397); // DXR_Standard POS Gen. Comments restored at true original ID
        MigrateLegacyTableData(59328, 53398); // DXR_Standard POS Users restored at true original ID
        MigrateLegacyTableData(59329, 53399); // DXR_Store Statement Posting restored at true original ID
        MigrateLegacyTableData(59330, 53400); // DXR_Summary Recon Setup restored at true original ID
        MigrateLegacyTableData(59331, 53401); // DXR_Tasas BC restored at true original ID
        MigrateLegacyTableData(59332, 53402); // DXR_Tickets By Offer restored at true original ID
        MigrateLegacyTableData(59333, 53403); // DXR_Tickets Entry restored at true original ID
        MigrateLegacyTableData(59334, 53404); // DXR_Tipo de Contenedor restored at true original ID
        MigrateLegacyTableData(59335, 53405); // DXR_Tipo Gas restored at true original ID
        MigrateLegacyTableData(59336, 53406); // DXR_Tipos o Agentes restored at true original ID
        MigrateLegacyTableData(59337, 53407); // DXR_Trans. Archive Line restored at true original ID
        MigrateLegacyTableData(59338, 53408); // DXR_Tratados Arancelarios restored at true original ID
        MigrateLegacyTableData(59339, 53409); // DXR_UserApproverByBuyerGroup restored at true original ID
        MigrateLegacyTableData(59340, 53410); // DXR_UserByBuyerGroup restored at true original ID
        MigrateLegacyTableData(59341, 53411); // DXR_UserLogs restored at true original ID
        MigrateLegacyTableData(59342, 53412); // DXR_UserPromo Apps restored at true original ID
        MigrateLegacyTableData(59343, 53413); // DXR_Valoracion de Inventario restored at true original ID
        MigrateLegacyTableData(59344, 53414); // DXR_VAT Bus. Settings restored at true original ID
        MigrateLegacyTableData(59345, 53415); // DXR_Printing Invoice Log BO restored at true original ID
    end;
}
