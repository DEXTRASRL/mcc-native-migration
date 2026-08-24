codeunit 60146 "DXR MCC Bellon Migr Phase2"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 2 Leg Norm" (56119), which itself only calls three procedures on "Bellon Upgrade
    // Process" (59221, Subtype = Upgrade - never .Run()/OnRun'd, only named procedures called on
    // a typed variable, same safe pattern used throughout this portfolio):
    //   1) MigrateAllNormalizedTables() - 137 legacy tables (50xxx) copied to their DXR_ clone.
    //   2) MigrateAllTableExtensionFields() - ~74 active field-copy procedures (427 fields across
    //      ~87 tableextensions were originally wired; 13 of those procedures - the whole Sales/
    //      Purchase Header family, since superseded by other phases - were retroactively removed
    //      from the active call list on 2026-08-20 and are dead code kept only as documentation
    //      in the real source; NOT ported here, matching the source's own current behavior).
    //      UNTRACKED BY MCC'S REGISTRY (no BELLON-Pn concept row references this specific group)
    //      but it DID run as a side effect every time the old delegation adapter (60056) executed
    //      - same situation as Despacho Base's Phase 1 in this same pivot - so it is preserved
    //      here rather than silently dropped.
    //   3) MigrateAllNormalizedTables_Batch2() - 4 more legacy tables, added after the main list.
    // Step-level idempotency reuses the sibling's own exact tag strings (hardcoded here since
    // "Upgrade Tag Mgt." exposes them via a typed Public codeunit already dependent-on elsewhere
    // in this portfolio, but the literals are copied directly to avoid any further cross-repo
    // coupling risk).
    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DXR-TablesNorm283') then begin
            MigrateAllNormalizedTables();
            UpgradeTag.SetUpgradeTag('DXR-TablesNorm283');
        end;

        if not UpgradeTag.HasUpgradeTag('DXR-TableExtFieldsNorm283') then begin
            MigrateAllTableExtensionFields();
            UpgradeTag.SetUpgradeTag('DXR-TableExtFieldsNorm283');
        end;

        if not UpgradeTag.HasUpgradeTag('DXR-TablesNorm283-Batch2') then begin
            MigrateAllNormalizedTables_Batch2();
            UpgradeTag.SetUpgradeTag('DXR-TablesNorm283-Batch2');
        end;
    end;

    // ===== Generic copy engines (ported verbatim from "Bellon Upgrade Process") =====

    // Copies every row of a legacy table (OldTableId) to its DXR_ clone (NewTableId) by field
    // NUMBER (both tables share identical field IDs/types), Class=Normal only on both sides.
    // Idempotent per table: if the destination already has rows, does nothing (protects against a
    // partial retry after a mid-run failure).
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

    // Copies OldFieldNo -> NewFieldNo on the current row only if both fields exist in the
    // currently published schema (defense-in-depth: several IDs hardcoded in the real source
    // point at fields relocated/removed by a later renumbering round; RecRef.Field(N) on a
    // missing N throws and aborts the whole procedure otherwise).
    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;

    // ===== 1) 137 legacy table restores =====

    local procedure MigrateAllNormalizedTables()
    begin
        MigrateLegacyTableData(50001, 53301); // Agente -> DXR_Agente
        MigrateLegacyTableData(50004, 53302); // AGR Log -> DXR_AGR Log
        MigrateAGRSetupTable(); // AGR Setup -> DXR_AGR Setup (native - fixes NewRecRef.Open-inside-loop leak, see MigrateLegacyTableData)
        MigrateAjusteInventarioConfigTable(); // Ajuste Inventario Config -> DXR_Ajuste Inventario Config (native)
        MigrateLegacyTableData(50007, 53305); // Archivo - Discrepancias -> DXR_Archivo - Discrepancias
        MigrateAreaDeTrabajoTable(); // Area de Trabajo -> DXR_Area de Trabajo (native)
        MigrateLegacyTableData(50009, 53307); // Bancos - Extracto Bancario -> DXR_Bancos - Extracto Bancario
        MigrateLegacyTableData(50010, 53308); // Bank -> DXR_Bank
        MigrateLegacyTableData(50011, 53309); // Bank Relation -> DXR_Bank Relation
        MigrateLegacyTableData(50012, 53310); // Black List Promotion -> DXR_Black List Promotion
        MigrateLegacyTableData(50013, 53311); // Cabecera Discrepancia -> DXR_Cabecera Discrepancia
        MigrateLegacyTableData(50016, 53312); // Carga Masiva Beneficiarios BPD -> DXR_Carga Masiva Benef BPD
        MigrateCategoriaServiciosTable(); // Categoria Servicios -> DXR_Categoria Servicios (native)
        MigrateLegacyTableData(50021, 53314); // Cilindros -> DXR_Cilindros
        MigrateCilindrosSetupTable(); // Cilindros - Setup -> DXR_Cilindros - Setup (native)
        MigrateCodigosDeAuditoriaTable(); // Codigos de Auditoria -> DXR_Codigos de Auditoria. (native)
        MigrateLegacyTableData(50025, 53317); // Comentario - Discrepancias -> DXR_Comentario - Discrepancias
        MigrateConfExtractoBancarioTable(); // Conf. Extracto Bancario -> DXR_Conf. Extracto Bancario (native)
        MigrateConfigNCFVentasTable(); // Config. NCF Ventas -> DXR_Config. NCF Ventas (native)
        MigrateConfigNCFVentasSTDTable(); // Config. NCF Ventas STD -> DXR_Config. NCF Ventas STD (native)
        MigrateConfigPolizasTable(); // Config. Polizas -> DXR_Config. Polizas (native)
        MigrateConfiguracionCBTable(); // Configuracion CB -> DXR_Configuracion CB (native)
        MigrateConfiguracionDiscrepanciasTable(); // Configuracion - Discrepancias -> DXR_Config - Discr (native)
        MigrateConfiguracionEncuestasPOSTable(); // Configuracion Encuestas - POS -> DXR_Config Encuestas - POS (native)
        MigrateConfiguracionesRequisicionTable(); // Configuraciones Requisicion -> DXR_Config Req (native)
        MigrateConfiguracionMedalliaTable(); // Configuracion - MEDALLIA -> DXR_Configuracion - MEDALLIA (native)
        MigrateConfPagosEcommerceAzulTable(); // Conf. Pagos Ecommerce Azul -> DXR_Conf. Pagos Ecommerce Azul (native)
        MigrateControlProcesosPorAlmacenTable(); // Control Procesos por Almacen -> DXR_Control Proc por Almacen (native)
        MigrateLegacyTableData(50043, 53329); // Conversion Costo -> DXR_Conversion Costo
        MigrateLegacyTableData(50048, 53330); // Departamento - Discrepancias -> DXR_Departamento - Discr
        MigrateLegacyTableData(50050, 53331); // Detalle - Extracto Bancario -> DXR_Detalle - Extr Bancario
        MigrateDrawSetupTable(); // Draw Setup -> DXR_Draw Setup (native)
        MigrateEmailSourceTemplateRelationTable(); // Email Source Template Relation -> DXR_Email Source Tmpl Rel (native)
        MigrateLegacyTableData(50057, 53334); // Entrega Facturas CxC - Lines -> DXR_Entrega Fact CxC - Lines
        MigrateLegacyTableData(50058, 53335); // Envio Compras -> DXR_Envio Compras
        MigrateLegacyTableData(50061, 53336); // EPagos Setup -> DXR_EPagos Setup
        MigrateLegacyTableData(50063, 53337); // Exclude Filter Journal -> DXR_Exclude Filter Journal
        MigrateLegacyTableData(50064, 53338); // Excluir Terminos  - ItemSearch -> DXR_Excluir Term - ItemSearch
        MigrateLegacyTableData(50065, 53339); // File Structure -> DXR_File Structure
        MigrateLegacyTableData(50068, 53340); // Forma de Pago -> DXR_Forma de Pago
        MigrateLegacyTableData(50071, 53341); // HisCargaMasivaBeneficiariosBPD -> DXR_HisCargaMasivaBenefBPD
        MigrateLegacyTableData(50072, 53342); // Grupo Venta -> DXR_Grupo Venta
        MigrateLegacyTableData(50073, 53343); // HisLineasCargaMasivaBenefBPD -> DXR_HisLinCargaMasivaBenefBPD
        MigrateLegacyTableData(50074, 53344); // Hist. Beneficiarios BPD -> DXR_Hist. Beneficiarios BPD
        MigrateLegacyTableData(50075, 53345); // Hist. Cabecera Discrepancia -> DXR_Hist. Cabecera Discr
        MigrateLegacyTableData(50076, 53346); // Hist. de Ganadores -> DXR_Hist. de Ganadores
        MigrateLegacyTableData(50077, 53347); // Hist. Internal Consump. Header -> DXR_Hist. Int Consump. Header
        MigrateLegacyTableData(50078, 53348); // Hist. Internal Consump. Line -> DXR_Hist. Int Consump. Line
        MigrateLegacyTableData(50079, 53349); // Hist. Linea Discrepancia -> DXR_Hist. Linea Discrepancia
        MigrateLegacyTableData(50081, 53350); // Historico Enc Requisicion -> DXR_Historico Enc Requisicion
        MigrateLegacyTableData(50082, 53351); // Historico - Extracto Bancario -> DXR_Historico - Extr Bancario
        MigrateLegacyTableData(50084, 53352); // Historico Requisicion Line -> DXR_Historico Requisicion Line
        MigrateLegacyTableData(50085, 53353); // Hist Pre-Requisicion -> DXR_Hist Pre-Requisicion
        MigrateLegacyTableData(50086, 53354); // Hist Pre-Requisicion Line -> DXR_Hist Pre-Requisicion Line
        MigrateLegacyTableData(50093, 53355); // Internal Consumption Header -> DXR_Int Consump Header
        MigrateLegacyTableData(50094, 53356); // Internal Consumption Line -> DXR_Internal Consumption Line
        MigrateLegacyTableData(50095, 53357); // Internal Consumption Log -> DXR_Internal Consumption Log
        MigrateLegacyTableData(50096, 53358); // BE Inventory Masks -> DXR_Inventory Masks
        MigrateLegacyTableData(50098, 53359); // Item HTML -> DXR_Item HTML
        MigrateLegacyTableData(50099, 53360); // Item Image View -> DXR_Item Image View
        MigrateLegacyTableData(50100, 53361); // ItemNo Desliquidacion -> DXR_ItemNo Desliquidacion
        MigrateLegacyTableData(50102, 53362); // Journal Promotion Tickets -> DXR_Journal Promotion Tickets
        MigrateLegacyTableData(50103, 53363); // Linea Discrepancia -> DXR_Linea Discrepancia
        MigrateLegacyTableData(50107, 53364); // Lineas Carga Masiva Ben. BPD -> DXR_Lin Carga Masiva Ben. BPD
        MigrateLegacyTableData(50109, 53365); // LineRQBuffer -> DXR_LineRQBuffer
        MigrateLegacyTableData(50111, 53366); // Log - Bank Statement -> DXR_Log - Bank Statement
        MigrateLegacyTableData(50112, 53367); // Log Email -> DXR_Log Email
        MigrateLegacyTableData(50115, 53368); // Log Transaccion Azul -> DXR_Log Transaccion Azul
        MigrateLegacyTableData(50116, 53369); // Log Transaccion Medallia -> DXR_Log Transaccion Medallia
        MigrateLegacyTableData(50117, 53370); // Log Transfer error -> DXR_Log Transfer error
        MigrateLegacyTableData(50118, 53371); // Marcas -> DXR_Marcas
        MigrateLegacyTableData(50119, 53372); // Member Management Setup -> DXR_Member Management Setup
        MigrateLegacyTableData(50121, 53373); // Motivo Cierre - Discrepancias -> DXR_Motivo Cierre - Discr
        MigrateLegacyTableData(50122, 53374); // Motivo Discrepancia -> DXR_Motivo Discrepancia
        MigrateLegacyTableData(50123, 53375); // Movimientos de Cilindro -> DXR_Movimientos de Cilindro
        MigrateLegacyTableData(50127, 53376); // Order Item Status -> DXR_Order Item Status
        MigrateLegacyTableData(50132, 53377); // Posted Jnl Promotion Tickets -> DXR_Posted Jnl Promo Tickets
        MigrateLegacyTableData(50135, 53378); // Pre Req LineNoStockValid -> DXR_Pre Req LineNoStockValid
        MigrateLegacyTableData(50136, 53379); // Pre Req no Stock Valid -> DXR_Pre Req no Stock Valid
        MigrateLegacyTableData(50137, 53380); // Pre-Requisicion -> DXR_Pre-Requisicion
        MigrateLegacyTableData(50138, 53381); // Pre-Requisicion Line -> DXR_Pre-Requisicion Line
        MigrateLegacyTableData(50139, 53382); // Pre-Requisicion Line No Stock -> DXR_Pre-Req Line No Stock
        MigrateLegacyTableData(50140, 53383); // Pre-Requisicion no Stock -> DXR_Pre-Requisicion no Stock
        MigrateLegacyTableData(50141, 53384); // Printing Invoice Log -> DXR_Printing Invoice Log
        MigrateLegacyTableData(50142, 53385); // Profesion -> DXR_Profesion
        MigrateLegacyTableData(50143, 53386); // Promotion Setup -> DXR_Promotion Setup
        MigrateLegacyTableData(50144, 53387); // Promotion Tickets Relation -> DXR_Promotion Tickets Relation
        MigrateLegacyTableData(50145, 53388); // Provincia -> DXR_Provincia
        MigrateLegacyTableData(50151, 53389); // Requisicion -> DXR_Requisicion
        MigrateLegacyTableData(50152, 53390); // Requisicion Comment Line -> DXR_Requisicion Comment Line
        MigrateLegacyTableData(50153, 53391); // Requisicion Line -> DXR_Requisicion Line
        MigrateLegacyTableData(50154, 53392); // Sales Dept -> DXR_Sales Dept
        MigrateLegacyTableData(50155, 53393); // Sales Groups -> DXR_Sales Groups
        MigrateLegacyTableData(50159, 53394); // Sales SubGroups -> DXR_Sales SubGroups
        MigrateLegacyTableData(50160, 53395); // Send Email Log -> DXR_Send Email Log
        MigrateLegacyTableData(50165, 53396); // Standard POS DASCOM Paymt Eqv -> DXR_Std POS DASCOM Paymt Eqv
        MigrateLegacyTableData(50168, 53397); // Standard POS Gen. Comments -> DXR_Standard POS Gen. Comments
        MigrateLegacyTableData(50172, 53398); // Standard POS Users -> DXR_Standard POS Users
        MigrateLegacyTableData(50173, 53399); // Store Statement Posting -> DXR_Store Statement Posting
        MigrateLegacyTableData(50174, 53400); // Summary Reconciliation Setup -> DXR_Summary Recon Setup
        MigrateLegacyTableData(50176, 53401); // Tasas BC -> DXR_Tasas BC
        MigrateLegacyTableData(50177, 53402); // Tickets By Offer -> DXR_Tickets By Offer
        MigrateLegacyTableData(50178, 53403); // Tickets Entry -> DXR_Tickets Entry
        MigrateLegacyTableData(50180, 53404); // Tipo de Contenedor -> DXR_Tipo de Contenedor
        MigrateLegacyTableData(50181, 53405); // Tipo Gas -> DXR_Tipo Gas
        MigrateLegacyTableData(50182, 53406); // Tipos o Agentes -> DXR_Tipos o Agentes
        MigrateLegacyTableData(50186, 53407); // Trans. Archive Line -> DXR_Trans. Archive Line
        MigrateLegacyTableData(50195, 53408); // Tratados Arancelarios -> DXR_Tratados Arancelarios
        MigrateLegacyTableData(50197, 53409); // UserApproverByBuyerGroup -> DXR_UserApproverByBuyerGroup
        MigrateLegacyTableData(50198, 53410); // UserByBuyerGroup -> DXR_UserByBuyerGroup
        MigrateLegacyTableData(50199, 53411); // UserLogs -> DXR_UserLogs
        MigrateLegacyTableData(50200, 53412); // UserPromo Apps -> DXR_UserPromo Apps
        MigrateLegacyTableData(50201, 53413); // Valoracion de Inventario -> DXR_Valoracion de Inventario
        MigrateLegacyTableData(50202, 53414); // VAT Bus. Settings -> DXR_VAT Bus. Settings
        MigrateLegacyTableData(50206, 53415); // Printing Invoice Log BO -> DXR_Printing Invoice Log BO
    end;

    // ===== 3) 4 more legacy table restores (added after the main list) =====

    local procedure MigrateAllNormalizedTables_Batch2()
    begin
        MigrateLegacyTableData(50002, 55006); // AGR Extended Item -> DXR_AGR Extended Item
        MigrateLegacyTableData(50027, 55005); // Comision_Grupo_Vendedor -> DXR_Comision_Grupo_Vendedor
        MigrateLegacyTableData(50097, 55004); // Inventory View -> DXR_Inventory View.
        MigrateLegacyTableData(50126, 55007); // Operaciones Tipo Comprobante2 -> DXR_Operaciones Tipo Comprob2
    end;

    // ===== 1b) 19 SETUP-category whole-table restores converted to native typed logic =====
    // Task A.4 Batch 1: zero RecordRef/FieldRef, zero TransferFields - every field assigned
    // explicitly. Replaces 19 of the MigrateLegacyTableData(...) calls above (still used by ~118
    // other, out-of-scope tables in MigrateAllNormalizedTables()) and eliminates, for these 19
    // tables specifically, the real production bug in MigrateLegacyTableData: it calls
    // NewRecRef.Open(NewTableId) INSIDE the repeat/until loop without ever closing it between
    // iterations, so the 2nd+ legacy row of any multi-row table throws "The record is already
    // open." Field lists and primary keys verified against Bellon_Customization's real
    // Tables.old\*.Table.al (legacy) and Tables\*.Table.al (DXR_) sources.

    // seq18: AGR Setup (50005) -> DXR_AGR Setup (53303). PK = "Primary Key".
    local procedure MigrateAGRSetupTable()
    var
        Legacy: Record "AGR Setup";
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

    // seq19: Ajuste Inventario Config (50006) -> DXR_Ajuste Inventario Config (53304).
    // PK = ("Item Padre", "Item Padre UM").
    local procedure MigrateAjusteInventarioConfigTable()
    var
        Legacy: Record "Ajuste Inventario Config";
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

    // seq21: Area de Trabajo (50008) -> DXR_Area de Trabajo (53306). PK = "Code".
    local procedure MigrateAreaDeTrabajoTable()
    var
        Legacy: Record "Area de Trabajo";
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

    // seq28: Categoria Servicios (50020) -> DXR_Categoria Servicios (53313). PK = "ID Services".
    local procedure MigrateCategoriaServiciosTable()
    var
        Legacy: Record "Categoria Servicios";
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

    // seq30: Cilindros - Setup (50022) -> DXR_Cilindros - Setup (53315). PK = "Key".
    local procedure MigrateCilindrosSetupTable()
    var
        Legacy: Record "Cilindros - Setup";
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

    // seq31: Codigos de Auditoria (50024) -> DXR_Codigos de Auditoria. (53316, trailing period is
    // part of the real object name). PK = Code.
    local procedure MigrateCodigosDeAuditoriaTable()
    var
        Legacy: Record "Codigos de Auditoria";
        New: Record "DXR_Codigos de Auditoria.";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Code) then begin
                    New.Init();
                    New.Code := Legacy.Code;
                    New.Description := Legacy.Description;
                    New."Default Location Code" := Legacy."Default Location Code";
                    New."Inventory Value Zero" := Legacy."Inventory Value Zero";
                    New."Tipo Proceso" := Legacy."Tipo Proceso";
                    New."Key" := Legacy."Key";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq33: Conf. Extracto Bancario (50029) -> DXR_Conf. Extracto Bancario (53318). PK = "Key".
    local procedure MigrateConfExtractoBancarioTable()
    var
        Legacy: Record "Conf. Extracto Bancario";
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

    // seq34: Config. NCF Ventas (50032) -> DXR_Config. NCF Ventas (53319). PK = "Código".
    // Field 52120031 renamed on the target: "EF Alternal No. Series" (legacy) ->
    // "Alternal No. Series_DXR" (new), same field number/type - confirmed via
    // Tables.old\ConfigNCFVentas.Table.al vs Tables\ConfigNCFVentas.Table.al.
    local procedure MigrateConfigNCFVentasTable()
    var
        Legacy: Record "Config. NCF Ventas";
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
                    New."Alternal No. Series_DXR" := Legacy."EF Alternal No. Series";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq35: Config. NCF Ventas STD (50033) -> DXR_Config. NCF Ventas STD (53320).
    // PK = ("Código", "Terminal No."). Same field 52120031 rename as Config. NCF Ventas above.
    local procedure MigrateConfigNCFVentasSTDTable()
    var
        Legacy: Record "Config. NCF Ventas STD";
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
                    New."Alternal No. Series_DXR" := Legacy."EF Alternal No. Series";
                    New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq36: Config. Polizas (50034) -> DXR_Config. Polizas (53321).
    // PK = ("Fecha Desde", "Fecha Hasta", "Monto Minimo", "Monto Maximo").
    local procedure MigrateConfigPolizasTable()
    var
        Legacy: Record "Config. Polizas";
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

    // seq37: Configuracion CB (50035) -> DXR_Configuracion CB (53322).
    // PK = (Bloque, "Reason Codes Filter", Orden).
    local procedure MigrateConfiguracionCBTable()
    var
        Legacy: Record "Configuracion CB";
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

    // seq38: Configuracion - Discrepancias (50036) -> DXR_Config - Discr (53323). PK = "key".
    local procedure MigrateConfiguracionDiscrepanciasTable()
    var
        Legacy: Record "Configuracion - Discrepancias";
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

    // seq39: Configuracion Encuestas - POS (50037) -> DXR_Config Encuestas - POS (53324).
    // PK = ("Store No.", "Pos Terminal No.", "Transacction No.").
    local procedure MigrateConfiguracionEncuestasPOSTable()
    var
        Legacy: Record "Configuracion Encuestas - POS";
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

    // seq40: Configuraciones Requisicion (50038) -> DXR_Config Req (53325). PK = "Key".
    local procedure MigrateConfiguracionesRequisicionTable()
    var
        Legacy: Record "Configuraciones Requisicion";
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

    // seq41: Configuracion - MEDALLIA (50039) -> DXR_Configuracion - MEDALLIA (53326). PK = "Key".
    local procedure MigrateConfiguracionMedalliaTable()
    var
        Legacy: Record "Configuracion - MEDALLIA";
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

    // seq42: Conf. Pagos Ecommerce Azul (50040) -> DXR_Conf. Pagos Ecommerce Azul (53327).
    // PK = "Key".
    local procedure MigrateConfPagosEcommerceAzulTable()
    var
        Legacy: Record "Conf. Pagos Ecommerce Azul";
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

    // seq43: Control Procesos por Almacen (50042) -> DXR_Control Proc por Almacen (53328).
    // PK = "Location Code".
    local procedure MigrateControlProcesosPorAlmacenTable()
    var
        Legacy: Record "Control Procesos por Almacen";
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

    // seq47: Draw Setup (50052) -> DXR_Draw Setup (53332). PK = "Entry No.".
    // Field "Ready" (6) is a FlowField (CalcFormula) on both sides - not copied, calculated on
    // read.
    local procedure MigrateDrawSetupTable()
    var
        Legacy: Record "Draw Setup";
        New: Record "DXR_Draw Setup";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Entry No.") then begin
                    New.Init();
                    New.Promotions := Legacy.Promotions;
                    New."Draw Date" := Legacy."Draw Date";
                    New.Description := Legacy.Description;
                    New."Winning customer" := Legacy."Winning customer";
                    New."Winning Ticket" := Legacy."Winning Ticket";
                    New."Entry No." := Legacy."Entry No.";
                    New.Done := Legacy.Done;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq48: Email Source Template Relation (50055) -> DXR_Email Source Tmpl Rel (53333).
    // PK = ("Email Template ID", "Email Source Table ID", "Field Email No."). Field
    // "Field Email Name" (5) is a FlowField (CalcFormula) on both sides - not copied.
    local procedure MigrateEmailSourceTemplateRelationTable()
    var
        Legacy: Record "Email Source Template Relation";
        New: Record "DXR_Email Source Tmpl Rel";
    begin
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy."Email Template ID", Legacy."Email Source Table ID", Legacy."Field Email No.") then begin
                    New.Init();
                    New."Email Template ID" := Legacy."Email Template ID";
                    New."Email Source Table ID" := Legacy."Email Source Table ID";
                    New."Email Source Table Name" := Legacy."Email Source Table Name";
                    New."Field Email No." := Legacy."Field Email No.";
                    New.CC := Legacy.CC;
                    New."Requerir Correo" := Legacy."Requerir Correo";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // ===== 2) ~74 active tableextension field-copy procedures (untracked-gap logic) =====
    // 13 dead procedures (the whole Sales/Purchase Header family, superseded by later phases and
    // retroactively removed from the active call list 2026-08-20) are NOT ported here - matching
    // the real source's current behavior exactly.

    local procedure MigrateAllTableExtensionFields()
    begin
        MigrateTableExt_ApprovalEntryFields();
        MigrateTableExt_AssemblyHeaderFields();
        MigrateTableExt_AssemblySetupFields();
        MigrateTableExt_VendorLedgerEntryFields();
        MigrateTableExt_BankAccReconciliationFields();
        MigrateTableExt_BankAccReconciliationLineFields();
        MigrateTableExt_BankAccountFields();
        MigrateTableExt_BankAccountLedgerEntryFields();
        MigrateTableExt_LSCBarcodesFields();
        MigrateTableExt_CheckLedgerEntryFields();
        MigrateTableExt_CompanyInformationFields();
        MigrateTableExt_ContactFields();
        MigrateTableExt_CountryRegionFields();
        MigrateTableExt_CurrencyFields();
        MigrateTableExt_CurrencyExchangeRateFields();
        MigrateTableExt_CustLedgerEntryFields();
        MigrateTableExt_CustomerFields();
        MigrateTableExt_CustomerPriceGroupFields();
        MigrateTableExt_GenJournalBatchFields();
        MigrateTableExt_GenJournalLineFields();
        MigrateTableExt_GenProductPostingGroupFields();
        MigrateTableExt_GeneralLedgerSetupFields();
        MigrateTableExt_IssuedReminderHeaderFields();
        MigrateTableExt_IssuedReminderLineFields();
        MigrateTableExt_ItemFields();
        MigrateTableExt_ItemCategoryFields();
        MigrateTableExt_ItemChargeAssignmentPurchFields();
        MigrateTableExt_ItemJournalBatchFields();
        MigrateTableExt_ItemJournalLineFields();
        MigrateTableExt_ItemLedgerEntryFields();
        MigrateTableExt_LSCItemSpecialGroupsFields();
        MigrateTableExt_DXCashJournalReceiptListFields();
        MigrateTableExt_LocationFields();
        MigrateTableExt_LSCMemberContactFields();
        MigrateTableExt_LSCMemberPointOfferFields();
        MigrateTableExt_LSCMemberPointOfferLineFields();
        MigrateTableExt_DXVendorWithholdingLedgerEntryFields();
        MigrateTableExt_DXNCFSetupFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_PaymentMethodFields();
        MigrateTableExt_LSCPeriodicDiscountFields();
        MigrateTableExt_PostedAssemblyHeaderFields();
        MigrateTableExt_LSCPostedStatementFields();
        MigrateTableExt_LSCRetailProductGroupFields();
        MigrateTableExt_PurchCommentLineFields();
        MigrateTableExt_PurchCommentLineArchiveFields();
        MigrateTableExt_PurchInvLineFields();
        MigrateTableExt_ReasonCodeFields();
        MigrateTableExt_LSCReplenJournalLinesFields();
        MigrateTableExt_LSCReplenTemplateFields();
        MigrateTableExt_LSCRetailSetupFields();
        MigrateTableExt_LSCRetailUserFields();
        MigrateTableExt_SalesPriceFields();
        MigrateTableExt_SalesPriceWorksheetFields();
        MigrateTableExt_SalesReceivablesSetupFields();
        MigrateTableExt_LSCSalesTypeFields();
        MigrateTableExt_SalespersonPurchaserFields();
        MigrateTableExt_ShiptoAddressFields();
        MigrateTableExt_LSCStatementFields();
        MigrateTableExt_LSCSTOREFields();
        MigrateTableExt_TariffNumberFields();
        MigrateTableExt_LSCTenderTypeFields();
        MigrateTableExt_LSCTransSalesEntryFields();
        MigrateTableExt_LSCTransactionHeaderFields();
        MigrateTableExt_TransferHeaderFields();
        MigrateTableExt_TransferLineFields();
        MigrateTableExt_TransferReceiptHeaderFields();
        MigrateTableExt_TransferShipmentHeaderFields();
        MigrateTableExt_UserSetupFields();
        MigrateTableExt_ValueEntryFields();
        MigrateTableExt_VendorFields();
        MigrateTableExt_WarehouseReceiptLineFields();
    end;

    local procedure MigrateTableExt_ApprovalEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Approval Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 52001, 52002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_AssemblyHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Assembly Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_AssemblySetupFields()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        // Fixed 2026-08-24: the old RecordRef version (CopyFieldIfExists(RecRef, 52000, 52001))
        // copied "Tolerance%" into "Tolerance%_Old" (field 52001), a dead shadow field - the real
        // active target "Tolerance%_DXR" (field 52787, confirmed via AssemblySetup.TableExt.al's
        // ObsoleteReason on field 52000) was NEVER populated by this codeunit despite it running
        // and reporting success. Direct typed fields close that gap.
        if AssemblySetup.Get() then
            if AssemblySetup."Tolerance%_DXR" <> AssemblySetup."Tolerance%" then begin
                AssemblySetup."Tolerance%_DXR" := AssemblySetup."Tolerance%";
                AssemblySetup.Modify();
            end;
    end;

    local procedure MigrateTableExt_VendorLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Vendor Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccReconciliationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccReconciliationLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Acc. Reconciliation Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 52000, 52001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccountFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_BankAccountLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Bank Account Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCBarcodesFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Barcodes");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CheckLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Check Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50005, 50009);
                CopyFieldIfExists(RecRef, 50006, 50010);
                CopyFieldIfExists(RecRef, 50007, 50011);
                CopyFieldIfExists(RecRef, 50008, 50012);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CompanyInformationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Company Information");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ContactFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Contact");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50060, 50079);
                CopyFieldIfExists(RecRef, 50061, 50080);
                CopyFieldIfExists(RecRef, 50062, 50081);
                CopyFieldIfExists(RecRef, 50063, 50082);
                CopyFieldIfExists(RecRef, 50064, 50083);
                CopyFieldIfExists(RecRef, 50065, 50084);
                CopyFieldIfExists(RecRef, 50066, 50085);
                CopyFieldIfExists(RecRef, 50067, 50086);
                CopyFieldIfExists(RecRef, 50068, 50087);
                CopyFieldIfExists(RecRef, 50069, 50088);
                CopyFieldIfExists(RecRef, 50070, 50089);
                CopyFieldIfExists(RecRef, 50071, 50090);
                CopyFieldIfExists(RecRef, 50072, 50091);
                CopyFieldIfExists(RecRef, 50073, 50092);
                CopyFieldIfExists(RecRef, 50074, 50093);
                CopyFieldIfExists(RecRef, 50075, 50094);
                CopyFieldIfExists(RecRef, 50076, 50095);
                CopyFieldIfExists(RecRef, 50077, 50096);
                CopyFieldIfExists(RecRef, 50078, 50097);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CountryRegionFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Country/Region");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CurrencyFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CurrencyExchangeRateFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Currency Exchange Rate");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Cust. Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50002, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustomerFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Customer");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50061);
                CopyFieldIfExists(RecRef, 50001, 50062);
                CopyFieldIfExists(RecRef, 50002, 50063);
                CopyFieldIfExists(RecRef, 50003, 50064);
                CopyFieldIfExists(RecRef, 50004, 50065);
                CopyFieldIfExists(RecRef, 50005, 50066);
                CopyFieldIfExists(RecRef, 50007, 50067);
                CopyFieldIfExists(RecRef, 50008, 50068);
                CopyFieldIfExists(RecRef, 50009, 50069);
                CopyFieldIfExists(RecRef, 50011, 50070);
                CopyFieldIfExists(RecRef, 50012, 50071);
                CopyFieldIfExists(RecRef, 50013, 50072);
                CopyFieldIfExists(RecRef, 50014, 50073);
                CopyFieldIfExists(RecRef, 50015, 50074);
                CopyFieldIfExists(RecRef, 50016, 50075);
                CopyFieldIfExists(RecRef, 50021, 50076);
                CopyFieldIfExists(RecRef, 50022, 50077);
                CopyFieldIfExists(RecRef, 50023, 50078);
                CopyFieldIfExists(RecRef, 50024, 50079);
                CopyFieldIfExists(RecRef, 50025, 50080);
                CopyFieldIfExists(RecRef, 50026, 50081);
                CopyFieldIfExists(RecRef, 50027, 50082);
                CopyFieldIfExists(RecRef, 50028, 50083);
                CopyFieldIfExists(RecRef, 50029, 50084);
                CopyFieldIfExists(RecRef, 50030, 50085);
                CopyFieldIfExists(RecRef, 50031, 50086);
                CopyFieldIfExists(RecRef, 50032, 50087);
                CopyFieldIfExists(RecRef, 50033, 50088);
                CopyFieldIfExists(RecRef, 50034, 50089);
                CopyFieldIfExists(RecRef, 50035, 50090);
                CopyFieldIfExists(RecRef, 50036, 50091);
                CopyFieldIfExists(RecRef, 50037, 50092);
                CopyFieldIfExists(RecRef, 50038, 50093);
                CopyFieldIfExists(RecRef, 50039, 50094);
                CopyFieldIfExists(RecRef, 50040, 50095);
                CopyFieldIfExists(RecRef, 50041, 50096);
                CopyFieldIfExists(RecRef, 50042, 50097);
                CopyFieldIfExists(RecRef, 50043, 50098);
                CopyFieldIfExists(RecRef, 50045, 50099);
                CopyFieldIfExists(RecRef, 50048, 50100);
                CopyFieldIfExists(RecRef, 50049, 50101);
                CopyFieldIfExists(RecRef, 50050, 50102);
                CopyFieldIfExists(RecRef, 50051, 50103);
                CopyFieldIfExists(RecRef, 50054, 50104);
                CopyFieldIfExists(RecRef, 50056, 50105);
                CopyFieldIfExists(RecRef, 50060, 50106);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_CustomerPriceGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Customer Price Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenJournalBatchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Batch");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50004);
                CopyFieldIfExists(RecRef, 50003, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenJournalLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Journal Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50055);
                CopyFieldIfExists(RecRef, 50050, 50056);
                CopyFieldIfExists(RecRef, 50051, 50057);
                CopyFieldIfExists(RecRef, 50052, 50058);
                CopyFieldIfExists(RecRef, 50013, 50059);
                CopyFieldIfExists(RecRef, 50014, 50060);
                CopyFieldIfExists(RecRef, 50015, 50061);
                CopyFieldIfExists(RecRef, 50053, 50062);
                CopyFieldIfExists(RecRef, 50054, 50063);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GenProductPostingGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Gen. Product Posting Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_GeneralLedgerSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"General Ledger Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_IssuedReminderHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Issued Reminder Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_IssuedReminderLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Issued Reminder Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50036);
                CopyFieldIfExists(RecRef, 50001, 50037);
                CopyFieldIfExists(RecRef, 50002, 50038);
                CopyFieldIfExists(RecRef, 50003, 50039);
                CopyFieldIfExists(RecRef, 50004, 50040);
                CopyFieldIfExists(RecRef, 50005, 50041);
                CopyFieldIfExists(RecRef, 50006, 50042);
                CopyFieldIfExists(RecRef, 50007, 50043);
                CopyFieldIfExists(RecRef, 50008, 50044);
                CopyFieldIfExists(RecRef, 50009, 50045);
                CopyFieldIfExists(RecRef, 50010, 50046);
                CopyFieldIfExists(RecRef, 50011, 50047);
                CopyFieldIfExists(RecRef, 50012, 50048);
                CopyFieldIfExists(RecRef, 50013, 50049);
                CopyFieldIfExists(RecRef, 50014, 50050);
                CopyFieldIfExists(RecRef, 50015, 50051);
                CopyFieldIfExists(RecRef, 50016, 50052);
                CopyFieldIfExists(RecRef, 50017, 50053);
                CopyFieldIfExists(RecRef, 50018, 50054);
                CopyFieldIfExists(RecRef, 50019, 50055);
                CopyFieldIfExists(RecRef, 50020, 50056);
                CopyFieldIfExists(RecRef, 50021, 50057);
                CopyFieldIfExists(RecRef, 50022, 50058);
                CopyFieldIfExists(RecRef, 50023, 50059);
                CopyFieldIfExists(RecRef, 50024, 50060);
                CopyFieldIfExists(RecRef, 50025, 50061);
                CopyFieldIfExists(RecRef, 50026, 50062);
                CopyFieldIfExists(RecRef, 50027, 50063);
                CopyFieldIfExists(RecRef, 50029, 50064);
                CopyFieldIfExists(RecRef, 50030, 50065);
                CopyFieldIfExists(RecRef, 50031, 50066);
                CopyFieldIfExists(RecRef, 50032, 50067);
                CopyFieldIfExists(RecRef, 50033, 50068);
                CopyFieldIfExists(RecRef, 50034, 50069);
                CopyFieldIfExists(RecRef, 50035, 50070);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemCategoryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Category");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemChargeAssignmentPurchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemJournalBatchFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Journal Batch");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemJournalLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Journal Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50003, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ItemLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Item Ledger Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50003, 50005);
                CopyFieldIfExists(RecRef, 50004, 50006);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCItemSpecialGroupsFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Item Special Groups");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXCashJournalReceiptListFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52132); // DXR_Cash Journal Receipt List (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50002, 50009);
                CopyFieldIfExists(RecRef, 50003, 50010);
                CopyFieldIfExists(RecRef, 50004, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LocationFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Location");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50002, 50008);
                CopyFieldIfExists(RecRef, 50003, 50009);
                CopyFieldIfExists(RecRef, 50004, 50010);
                CopyFieldIfExists(RecRef, 50005, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberContactFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Contact");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50006);
                CopyFieldIfExists(RecRef, 50001, 50007);
                CopyFieldIfExists(RecRef, 50002, 50008);
                CopyFieldIfExists(RecRef, 50003, 50009);
                CopyFieldIfExists(RecRef, 50004, 50010);
                CopyFieldIfExists(RecRef, 50005, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberPointOfferFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Point Offer");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50004);
                CopyFieldIfExists(RecRef, 50001, 50005);
                CopyFieldIfExists(RecRef, 50002, 50006);
                CopyFieldIfExists(RecRef, 50003, 50007);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCMemberPointOfferLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Member Point Offer Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXVendorWithholdingLedgerEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52204); // DXR_VendWithholdLedgerEntry (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_DXNCFSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(52179); // DXR_NCF Setup (Access = Internal in DR-Localization)
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50003);
                CopyFieldIfExists(RecRef, 50002, 50004);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTransLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Trans. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50001, 50009);
                CopyFieldIfExists(RecRef, 50000, 50010);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPOSTransactionFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Transaction");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50010);
                CopyFieldIfExists(RecRef, 50001, 50006);
                CopyFieldIfExists(RecRef, 50002, 50007);
                CopyFieldIfExists(RecRef, 50003, 50008);
                CopyFieldIfExists(RecRef, 50004, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PaymentMethodFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Payment Method");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50005, 50006);
                CopyFieldIfExists(RecRef, 50000, 50007);
                CopyFieldIfExists(RecRef, 50001, 50008);
                CopyFieldIfExists(RecRef, 50002, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPeriodicDiscountFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Periodic Discount");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50011);
                CopyFieldIfExists(RecRef, 50001, 50012);
                CopyFieldIfExists(RecRef, 50002, 50013);
                CopyFieldIfExists(RecRef, 50003, 50014);
                CopyFieldIfExists(RecRef, 50004, 50015);
                CopyFieldIfExists(RecRef, 50005, 50016);
                CopyFieldIfExists(RecRef, 50006, 50017);
                CopyFieldIfExists(RecRef, 50010, 50018);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PostedAssemblyHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Posted Assembly Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCPostedStatementFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Posted Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailProductGroupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Product Group");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchCommentLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchCommentLineArchiveFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Comment Line Archive");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_PurchInvLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purch. Inv. Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50017, 50018);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ReasonCodeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Reason Code");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCReplenJournalLinesFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Journal Lines");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50016, 50032);
                CopyFieldIfExists(RecRef, 50031, 50033);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCReplenTemplateFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Replen. Template");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50016, 50032);
                CopyFieldIfExists(RecRef, 50031, 50033);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50027);
                CopyFieldIfExists(RecRef, 50001, 50028);
                CopyFieldIfExists(RecRef, 50002, 50029);
                CopyFieldIfExists(RecRef, 50003, 50030);
                CopyFieldIfExists(RecRef, 50004, 50031);
                CopyFieldIfExists(RecRef, 50007, 50032);
                CopyFieldIfExists(RecRef, 50008, 50033);
                CopyFieldIfExists(RecRef, 50009, 50034);
                CopyFieldIfExists(RecRef, 50010, 50035);
                CopyFieldIfExists(RecRef, 50011, 50036);
                CopyFieldIfExists(RecRef, 50012, 50037);
                CopyFieldIfExists(RecRef, 50013, 50038);
                CopyFieldIfExists(RecRef, 50014, 50039);
                CopyFieldIfExists(RecRef, 50016, 50040);
                CopyFieldIfExists(RecRef, 50017, 50041);
                if RecRef.FieldExist(50018) then
                    RecRef.Field(50018).CalcField();
                CopyFieldIfExists(RecRef, 50018, 50042);
                CopyFieldIfExists(RecRef, 50019, 50043);
                CopyFieldIfExists(RecRef, 50020, 50044);
                CopyFieldIfExists(RecRef, 50021, 50045);
                CopyFieldIfExists(RecRef, 50022, 50046);
                CopyFieldIfExists(RecRef, 50023, 50047);
                CopyFieldIfExists(RecRef, 50024, 50048);
                CopyFieldIfExists(RecRef, 50025, 50049);
                CopyFieldIfExists(RecRef, 50026, 50050);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCRetailUserFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Retail User");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesPriceFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Price");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50053);
                CopyFieldIfExists(RecRef, 50002, 50054);
                CopyFieldIfExists(RecRef, 50003, 50055);
                CopyFieldIfExists(RecRef, 50011, 50056);
                CopyFieldIfExists(RecRef, 50052, 50057);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesPriceWorksheetFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Price Worksheet");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalesReceivablesSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales & Receivables Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCSalesTypeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Sales Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_SalespersonPurchaserFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Salesperson/Purchaser");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50004, 50007);
                CopyFieldIfExists(RecRef, 50005, 50008);
                CopyFieldIfExists(RecRef, 50006, 50009);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ShiptoAddressFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Ship-to Address");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                CopyFieldIfExists(RecRef, 50001, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCStatementFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Statement");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50001);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCSTOREFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC STORE");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50010);
                CopyFieldIfExists(RecRef, 50001, 50011);
                CopyFieldIfExists(RecRef, 50007, 50012);
                CopyFieldIfExists(RecRef, 50008, 50013);
                CopyFieldIfExists(RecRef, 50009, 50014);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TariffNumberFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Tariff Number");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50003);
                CopyFieldIfExists(RecRef, 50001, 50004);
                CopyFieldIfExists(RecRef, 50002, 50005);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTenderTypeFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Tender Type");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50007, 50008);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransSalesEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Sales Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_LSCTransactionHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Transaction Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50020, 50037);
                CopyFieldIfExists(RecRef, 50025, 50038);
                CopyFieldIfExists(RecRef, 50026, 50039);
                CopyFieldIfExists(RecRef, 50027, 50040);
                CopyFieldIfExists(RecRef, 50028, 50041);
                CopyFieldIfExists(RecRef, 50029, 50042);
                CopyFieldIfExists(RecRef, 50030, 50043);
                CopyFieldIfExists(RecRef, 50031, 50044);
                CopyFieldIfExists(RecRef, 50032, 50045);
                CopyFieldIfExists(RecRef, 50033, 50046);
                CopyFieldIfExists(RecRef, 50034, 50047);
                CopyFieldIfExists(RecRef, 50035, 50048);
                CopyFieldIfExists(RecRef, 50036, 50049);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50009, 50011);
                CopyFieldIfExists(RecRef, 50010, 50012);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferReceiptHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Receipt Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50011);
                CopyFieldIfExists(RecRef, 50007, 50012);
                CopyFieldIfExists(RecRef, 50009, 50013);
                CopyFieldIfExists(RecRef, 50010, 50014);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_TransferShipmentHeaderFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Shipment Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 50009);
                CopyFieldIfExists(RecRef, 50007, 50010);
                CopyFieldIfExists(RecRef, 50008, 50011);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_UserSetupFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"User Setup");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 50025);
                CopyFieldIfExists(RecRef, 50001, 50026);
                CopyFieldIfExists(RecRef, 50002, 50027);
                CopyFieldIfExists(RecRef, 50003, 50028);
                CopyFieldIfExists(RecRef, 50005, 50029);
                CopyFieldIfExists(RecRef, 50006, 50030);
                CopyFieldIfExists(RecRef, 50007, 50031);
                CopyFieldIfExists(RecRef, 50008, 50032);
                CopyFieldIfExists(RecRef, 50010, 50033);
                CopyFieldIfExists(RecRef, 50011, 50034);
                CopyFieldIfExists(RecRef, 50012, 50035);
                CopyFieldIfExists(RecRef, 50013, 50036);
                CopyFieldIfExists(RecRef, 50014, 50037);
                CopyFieldIfExists(RecRef, 50015, 50038);
                CopyFieldIfExists(RecRef, 50016, 50039);
                CopyFieldIfExists(RecRef, 50017, 50040);
                CopyFieldIfExists(RecRef, 50018, 50041);
                CopyFieldIfExists(RecRef, 50019, 50042);
                CopyFieldIfExists(RecRef, 50020, 50043);
                CopyFieldIfExists(RecRef, 50021, 50044);
                CopyFieldIfExists(RecRef, 50022, 50045);
                CopyFieldIfExists(RecRef, 50024, 50046);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_ValueEntryFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Value Entry");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50002, 50003);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_VendorFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Vendor");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50014, 50034);
                CopyFieldIfExists(RecRef, 50015, 50035);
                CopyFieldIfExists(RecRef, 50016, 50036);
                CopyFieldIfExists(RecRef, 50017, 50037);
                CopyFieldIfExists(RecRef, 50018, 50038);
                CopyFieldIfExists(RecRef, 50019, 50039);
                CopyFieldIfExists(RecRef, 50020, 50040);
                CopyFieldIfExists(RecRef, 50021, 50041);
                CopyFieldIfExists(RecRef, 50022, 50042);
                CopyFieldIfExists(RecRef, 50023, 50043);
                CopyFieldIfExists(RecRef, 50024, 50044);
                CopyFieldIfExists(RecRef, 50025, 50045);
                CopyFieldIfExists(RecRef, 50026, 50046);
                CopyFieldIfExists(RecRef, 50027, 50047);
                CopyFieldIfExists(RecRef, 50028, 50048);
                CopyFieldIfExists(RecRef, 50029, 50049);
                CopyFieldIfExists(RecRef, 50030, 50050);
                CopyFieldIfExists(RecRef, 50031, 50051);
                CopyFieldIfExists(RecRef, 50032, 50052);
                CopyFieldIfExists(RecRef, 50033, 50053);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateTableExt_WarehouseReceiptLineFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Warehouse Receipt Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 50002);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
