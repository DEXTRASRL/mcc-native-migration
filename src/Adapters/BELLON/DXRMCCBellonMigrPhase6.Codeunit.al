// codeunit 60150 "DXR MCC Bellon Migr Phase6"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 6 Table ID" (56123) -> "Bellon Upgrade Process".MigrateAllRenumberedDXRTables(). A
//     // later commit renumbered 114 custom DXR_ tables directly in-place (edited the ID literal on
//     // the same table declaration, e.g. table 59231 "DXR_Agente" -> table 53301 "DXR_Agente"),
//     // instead of the safe preserve-old/add-new pattern already established elsewhere in this same
//     // repo. The 114 tables were restored at their original 59xxx IDs (ObsoleteState = Pending,
//     // AL name suffixed " Old2" to disambiguate from the active 53xxx table of the same base name)
//     // so publish does not attempt to remove them; this phase copies every row across.
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-TableIdRenumberRestore283') then
//             exit;

//         MigrateAllRenumberedDXRTables();

//         UpgradeTag.SetUpgradeTag('DXR-TableIdRenumberRestore283');
//     end;

//     procedure RunSetup()
//     begin
//         MigrateAGRSetupOld2Table(); // DXR_AGR Setup Old2 (59233) -> DXR_AGR Setup (53303) - native
//         MigrateAjusteInventarioConfigOld2Table(); // DXR_Ajuste Inventario Con Old2 (59234) -> DXR_Ajuste Inventario Config (53304) - native
//         MigrateAreaDeTrabajoOld2Table(); // DXR_Area de Trabajo Old2 (59236) -> DXR_Area de Trabajo (53306) - native
//         MigrateCategoriaServiciosOld2Table(); // DXR_Categoria Servicios Old2 (59243) -> DXR_Categoria Servicios (53313) - native
//         MigrateCilindrosSetupOld2Table(); // DXR_Cilindros - Setup Old2 (59245) -> DXR_Cilindros - Setup (53315) - native
//         MigrateConfExtractoBancarioOld2Table(); // DXR_Conf. Extracto Bancar Old2 (59248) -> DXR_Conf. Extracto Bancario (53318) - native
//         MigrateConfigNCFVentasOld2Table(); // DXR_Config. NCF Ventas Old2 (59249) -> DXR_Config. NCF Ventas (53319) - native
//         MigrateConfigNCFVentasSTDOld2Table(); // DXR_Config. NCF Ventas ST Old2 (59250) -> DXR_Config. NCF Ventas STD (53320) - native
//         MigrateConfigPolizasOld2Table(); // DXR_Config. Polizas Old2 (59251) -> DXR_Config. Polizas (53321) - native
//         MigrateConfiguracionCBOld2Table(); // DXR_Configuracion CB Old2 (59252) -> DXR_Configuracion CB (53322) - native
//         MigrateConfiguracionDiscrepanciasOld2Table(); // DXR_Config - Discr Old2 (59253) -> DXR_Config - Discr (53323) - native
//         MigrateConfiguracionEncuestasPOSOld2Table(); // DXR_Config Encuestas - PO Old2 (59254) -> DXR_Config Encuestas - POS (53324) - native
//         MigrateConfiguracionesRequisicionOld2Table(); // DXR_Config Req Old2 (59255) -> DXR_Config Req (53325) - native
//         MigrateConfiguracionMedalliaOld2Table(); // DXR_Configuracion - MEDAL Old2 (59256) -> DXR_Configuracion - MEDALLIA (53326) - native
//         MigrateConfPagosEcommerceAzulOld2Table(); // DXR_Conf. Pagos Ecommerce Old2 (59257) -> DXR_Conf. Pagos Ecommerce Azul (53327) - native
//         MigrateControlProcesosPorAlmacenOld2Table(); // DXR_Control Proc por Alma Old2 (59258) -> DXR_Control Proc por Almacen (53328) - native
//         MigrateDrawSetupOld2Table(); // DXR_Draw Setup Old2 (59262) -> DXR_Draw Setup (53332) - native
//         MigrateEmailSourceTemplateRelationOld2Table(); // DXR_Email Source Tmpl Rel Old2 (59263) -> DXR_Email Source Tmpl Rel (53333) - native
//         MigrateEPagosSetupOld2Table(); // DXR_EPagos Setup Old2 (59266) -> DXR_EPagos Setup (53336) - native
//         MigrateExcludeFilterJournalOld2Table(); // DXR_Exclude Filter Journal Old2 (59267) -> DXR_Exclude Filter Journal (53337) - native
//         MigrateExcluirTerminosItemSearchOld2Table(); // DXR_Excluir Term - ItemSearch Old2 (59268) -> DXR_Excluir Term - ItemSearch (53338) - native
//         MigrateFileStructureOld2Table(); // DXR_File Structure Old2 (59269) -> DXR_File Structure (53339) - native
//         MigrateFormaDePagoOld2Table(); // DXR_Forma de Pago Old2 (59270) -> DXR_Forma de Pago (53340) - native
//         MigrateInventoryMasksOld2Table(); // DXR_Inventory Masks Old2 (59288) -> DXR_Inventory Masks (53358) - native
//         MigrateMarcasOld2Table(); // DXR_Marcas Old2 (59301) -> DXR_Marcas (53371) - native
//         MigrateMemberManagementSetupOld2Table(); // DXR_Member Management Setup Old2 (59302) -> DXR_Member Management Setup (53372) - native
//         MigrateMotivoCierreDiscrepanciasOld2Table(); // DXR_Motivo Cierre - Discr Old2 (59303) -> DXR_Motivo Cierre - Discr (53373) - native
//         MigrateMotivoDiscrepanciaOld2Table(); // DXR_Motivo Discrepancia Old2 (59304) -> DXR_Motivo Discrepancia (53374) - native
//         MigrateProfesionOld2Table(); // DXR_Profesion Old2 (59315) -> DXR_Profesion (53385) - native
//         MigratePromotionSetupOld2Table(); // DXR_Promotion Setup Old2 (59316) -> DXR_Promotion Setup (53386) - native
//         MigrateProvinciaOld2Table(); // DXR_Provincia Old2 (59318) -> DXR_Provincia (53388) - native
//         MigrateSalesDeptOld2Table(); // DXR_Sales Dept Old2 (59322) -> DXR_Sales Dept (53392) - native
//         MigrateSalesGroupsOld2Table(); // DXR_Sales Groups Old2 (59323) -> DXR_Sales Groups (53393) - native
//         MigrateSalesSubGroupsOld2Table(); // DXR_Sales SubGroups Old2 (59324) -> DXR_Sales SubGroups (53394) - native
//         MigrateStdPOSDASCOMPaymtEqvOld2Table(); // DXR_Std POS DASCOM Paymt Old2 (59326) -> DXR_Std POS DASCOM Paymt Eqv (53396) - native
//         MigrateStandardPOSGenCommentsOld2Table(); // DXR_Standard POS Gen. Com Old2 (59327) -> DXR_Standard POS Gen. Comments (53397) - native
//         MigrateStandardPOSUsersOld2Table(); // DXR_Standard POS Users Old2 (59328) -> DXR_Standard POS Users (53398) - native
//         MigrateSummaryReconSetupOld2Table(); // DXR_Summary Recon Setup Old2 (59330) -> DXR_Summary Recon Setup (53400) - native
//         MigrateTasasBCOld2Table(); // DXR_Tasas BC Old2 (59331) -> DXR_Tasas BC (53401) - native
//         MigrateTipoDeContenedorOld2Table(); // DXR_Tipo de Contenedor Old2 (59334) -> DXR_Tipo de Contenedor (53404) - native
//         MigrateTipoGasOld2Table(); // DXR_Tipo Gas Old2 (59335) -> DXR_Tipo Gas (53405) - native
//         MigrateTiposOAgentesOld2Table(); // DXR_Tipos o Agentes Old2 (59336) -> DXR_Tipos o Agentes (53406) - native
//         MigrateTratadosArancelariosOld2Table(); // DXR_Tratados Arancelarios Old2 (59338) -> DXR_Tratados Arancelarios (53408) - native
//         MigrateUserApproverByBuyerGroupOld2Table(); // DXR_UserApproverByBuyerGr Old2 (59339) -> DXR_UserApproverByBuyerGroup (53409) - native
//         MigrateUserByBuyerGroupOld2Table(); // DXR_UserByBuyerGroup Old2 (59340) -> DXR_UserByBuyerGroup (53410) - native
//         MigrateVATBusSettingsOld2Table(); // DXR_VAT Bus. Settings Old2 (59344) -> DXR_VAT Bus. Settings (53414) - native
//     end;

//     procedure RunMaster()
//     begin
//         MigrateLegacyTableData(59238, 53308); // DXR_Bank restored at true original ID
//         MigrateLegacyTableData(59239, 53309); // DXR_Bank Relation restored at true original ID
//         MigrateLegacyTableData(59244, 53314); // DXR_Cilindros restored at true original ID
//         MigrateLegacyTableData(59272, 53342); // DXR_Grupo Venta restored at true original ID
//         MigrateLegacyTableData(59289, 53359); // DXR_Item HTML restored at true original ID
//         MigrateLegacyTableData(59290, 53360); // DXR_Item Image View restored at true original ID
//         MigrateLegacyTableData(59291, 53361); // DXR_ItemNo Desliquidacion restored at true original ID
//         MigrateLegacyTableData(59306, 53376); // DXR_Order Item Status restored at true original ID
//         MigrateLegacyTableData(59317, 53387); // DXR_Promotion Tickets Relation restored at true original ID
//         MigrateLegacyTableData(59342, 53412); // DXR_UserPromo Apps restored at true original ID
//     end;

//     procedure RunAccounting()
//     begin
//         MigrateLegacyTableData(59237, 53307);
//         MigrateLegacyTableData(59242, 53312);
//         MigrateLegacyTableData(59259, 53329);
//         MigrateLegacyTableData(59261, 53331);
//         MigrateLegacyTableData(59264, 53334);
//         MigrateLegacyTableData(59265, 53335);
//         MigrateLegacyTableData(59285, 53355);
//         MigrateLegacyTableData(59286, 53356);
//         MigrateLegacyTableData(59292, 53362);
//         MigrateLegacyTableData(59294, 53364);
//         MigrateLegacyTableData(59305, 53375);
//         MigrateLegacyTableData(59308, 53378);
//         MigrateLegacyTableData(59309, 53379);
//         MigrateLegacyTableData(59310, 53380);
//         MigrateLegacyTableData(59311, 53381);
//         MigrateLegacyTableData(59312, 53382);
//         MigrateLegacyTableData(59313, 53383);
//         MigrateLegacyTableData(59319, 53389);
//         MigrateLegacyTableData(59320, 53390);
//         MigrateLegacyTableData(59321, 53391);
//         MigrateLegacyTableData(59329, 53399);
//         MigrateLegacyTableData(59332, 53402);
//         MigrateLegacyTableData(59333, 53403);
//         MigrateLegacyTableData(59343, 53413);
//     end;

//     procedure RunHistoric()
//     begin
//         MigrateLegacyTableData(59232, 53302); // DXR_AGR Log restored at true original ID
//         MigrateLegacyTableData(59271, 53341); // DXR_HisCargaMasivaBenefBPD restored at true original ID
//         MigrateLegacyTableData(59273, 53343); // DXR_HisLinCargaMasivaBenefBPD restored at true original ID
//         MigrateLegacyTableData(59274, 53344); // DXR_Hist. Beneficiarios BPD restored at true original ID
//         MigrateLegacyTableData(59275, 53345); // DXR_Hist. Cabecera Discr restored at true original ID
//         MigrateLegacyTableData(59276, 53346); // DXR_Hist. de Ganadores restored at true original ID
//         MigrateLegacyTableData(59277, 53347); // DXR_Hist. Int Consump. Header restored at true original ID
//         MigrateLegacyTableData(59278, 53348); // DXR_Hist. Int Consump. Line restored at true original ID
//         MigrateLegacyTableData(59279, 53349); // DXR_Hist. Linea Discrepancia restored at true original ID
//         MigrateLegacyTableData(59280, 53350); // DXR_Historico Enc Requisicion restored at true original ID
//         MigrateLegacyTableData(59281, 53351); // DXR_Historico - Extr Bancario restored at true original ID
//         MigrateLegacyTableData(59282, 53352); // DXR_Historico Requisicion Line restored at true original ID
//         MigrateLegacyTableData(59283, 53353); // DXR_Hist Pre-Requisicion restored at true original ID
//         MigrateLegacyTableData(59284, 53354); // DXR_Hist Pre-Requisicion Line restored at true original ID
//         MigrateLegacyTableData(59287, 53357); // DXR_Internal Consumption Log restored at true original ID
//         MigrateLegacyTableData(59296, 53366); // DXR_Log - Bank Statement restored at true original ID
//         MigrateLegacyTableData(59297, 53367); // DXR_Log Email restored at true original ID
//         MigrateLegacyTableData(59298, 53368); // DXR_Log Transaccion Azul restored at true original ID
//         MigrateLegacyTableData(59299, 53369); // DXR_Log Transaccion Medallia restored at true original ID
//         MigrateLegacyTableData(59300, 53370); // DXR_Log Transfer error restored at true original ID
//         MigrateLegacyTableData(59307, 53377); // DXR_Posted Jnl Promo Tickets restored at true original ID
//         MigrateLegacyTableData(59314, 53384); // DXR_Printing Invoice Log restored at true original ID
//         MigrateLegacyTableData(59325, 53395); // DXR_Send Email Log restored at true original ID
//         MigrateLegacyTableData(59337, 53407); // DXR_Trans. Archive Line restored at true original ID
//         MigrateLegacyTableData(59341, 53411); // DXR_UserLogs restored at true original ID
//         MigrateLegacyTableData(59345, 53415); // DXR_Printing Invoice Log BO restored at true original ID
//     end;

//     procedure RunOther()
//     begin
//         MigrateLegacyTableData(59231, 53301); // DXR_Agente restored at true original ID
//         MigrateLegacyTableData(59235, 53305); // DXR_Archivo - Discrepancias restored at true original ID
//         MigrateLegacyTableData(59240, 53310); // DXR_Black List Promotion restored at true original ID
//         MigrateLegacyTableData(59241, 53311); // DXR_Cabecera Discrepancia restored at true original ID
//         MigrateLegacyTableData(59247, 53317); // DXR_Comentario - Discrepancias restored at true original ID (59246/Codigos de Auditoria has no Old2 counterpart - confirmed skip)
//         MigrateLegacyTableData(59260, 53330); // DXR_Departamento - Discr restored at true original ID
//         MigrateLegacyTableData(59293, 53363); // DXR_Linea Discrepancia restored at true original ID
//         MigrateLegacyTableData(59295, 53365); // DXR_LineRQBuffer restored at true original ID
//     end;

//     // Copies every row of a legacy table (OldTableId) to its DXR_ clone (NewTableId) by field
//     // NUMBER (both tables share identical field IDs/types - the restored Old2 clone preserves the
//     // full schema unmodified), Class=Normal only on both sides. Idempotent per table: if the
//     // destination already has rows, does nothing.
//     local procedure MigrateLegacyTableData(OldTableId: Integer; NewTableId: Integer)
//     var
//         OldRecRef: RecordRef;
//         NewRecRef: RecordRef;
//         OldFieldRef: FieldRef;
//         NewFieldRef: FieldRef;
//         FieldIdx: Integer;
//         BatchCount: Integer;
//         TargetWasEmpty: Boolean;
//     begin
//         NewRecRef.Open(NewTableId);
//         TargetWasEmpty := NewRecRef.IsEmpty();
//         NewRecRef.Close();

//         OldRecRef.Open(OldTableId);
//         if OldRecRef.FindSet(false) then
//             repeat
//                 NewRecRef.Open(NewTableId);
//                 NewRecRef.Init();
//                 for FieldIdx := 1 to OldRecRef.FieldCount() do begin
//                     OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
//                     if (OldFieldRef.Number() < 2000000000) and
//                        (OldFieldRef.Class() = FieldClass::Normal) and
//                        NewRecRef.FieldExist(OldFieldRef.Name())
//                     then begin
//                         NewFieldRef := NewRecRef.Field(OldFieldRef.Name());
//                         if (NewFieldRef.Class() = FieldClass::Normal) and
//                            (OldFieldRef.Type() = NewFieldRef.Type())
//                         then
//                             NewFieldRef.Value := OldFieldRef.Value();
//                     end;
//                 end;
//                 if TargetWasEmpty then begin
//                     NewRecRef.Insert(false);
//                     BatchCount += 1;
//                 end else
//                     if TryInsertRecordRef(NewRecRef) then
//                         BatchCount += 1;
//                 // 2026-08-25 fix: same missing-Close bug as Phase2's identical helper (see its
//                 // own comment) - NewRecRef.Open() inside this loop without a per-iteration Close()
//                 // threw "The record is already open." on the 2nd+ row of any multi-row "Old2"
//                 // table still served by this shared helper, aborting the whole OnRun().
//                 NewRecRef.Close();
//                 if BatchCount >= 500 then begin
//                     Commit();
//                     BatchCount := 0;
//                 end;
//             until OldRecRef.Next() = 0;
//         OldRecRef.Close();
//         if BatchCount > 0 then
//             Commit();
//     end;

//     [TryFunction]
//     local procedure TryInsertRecordRef(var TargetRecRef: RecordRef)
//     begin
//         TargetRecRef.Insert(false);
//     end;

//     // ===== 16 SETUP-category "Old2" whole-table restores converted to native typed logic =====
//     // Task A.4 Batch 4: zero RecordRef/FieldRef, zero TransferFields - every field assigned
//     // explicitly. Replaces 16 of the MigrateLegacyTableData(...) calls above (still used by ~98
//     // other, out-of-scope "Old2" tables in MigrateAllRenumberedDXRTables()) and eliminates, for
//     // these 16 tables specifically, the same real production bug in MigrateLegacyTableData
//     // documented for Phase2/Phase6's own generic helper (NewRecRef.Open inside the repeat/until
//     // loop without closing between iterations, throwing "The record is already open." from the
//     // 2nd+ row of any multi-row table). Each of these 16 tables' final destination (53xxx) is the
//     // SAME table a sibling BELLON-P2 concept (already converted in DXRMCCBellonMigrPhase2's own
//     // Task A.4 Batches 1-3, reviewed clean) already writes to from a DIFFERENT legacy source
//     // (50xxx). Both procedures do a Get()-before-Insert() against the same destination table -
//     // intentional and idempotent, not a conflict. Field lists and primary keys verified
//     // independently against this batch's real Tables.old2\*.Table.al (Old2 legacy) and
//     // Tables\*.Table.al (DXR_ new) sources - field-for-field identical on both sides for all 16
//     // tables in this batch (each Old2 table is a byte-for-byte schema restore of its DXR_ clone at
//     // the pre-renumbering ID), no renamed/shadow fields found.

//     // seq158: DXR_AGR Setup Old2 (59233) -> DXR_AGR Setup (53303). PK = "Primary Key".
//     local procedure MigrateAGRSetupOld2Table()
//     var
//         Legacy: Record "DXR_AGR Setup Old2";
//         New: Record "DXR_AGR Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Primary Key") then begin
//                     New.Init();
//                     New."Primary Key" := Legacy."Primary Key";
//                     New."SQL Server" := Legacy."SQL Server";
//                     New."SQL User ID" := Legacy."SQL User ID";
//                     New."SQL Password" := Legacy."SQL Password";
//                     New."SQL Database" := Legacy."SQL Database";
//                     New."SQL Connection Timeout" := Legacy."SQL Connection Timeout";
//                     New."Enable Log Cleanup" := Legacy."Enable Log Cleanup";
//                     New."Keep History for" := Legacy."Keep History for";
//                     New."Last Cleanup" := Legacy."Last Cleanup";
//                     New."Req. Worksh. Template Name" := Legacy."Req. Worksh. Template Name";
//                     New."Req. Worksh. Jrnl. Batch Name" := Legacy."Req. Worksh. Jrnl. Batch Name";
//                     New."Plan. Worksh. Template Name" := Legacy."Plan. Worksh. Template Name";
//                     New."Plan. Worksh. Jrnl. Batch Name" := Legacy."Plan. Worksh. Jrnl. Batch Name";
//                     New.ProdOrderChoice := Legacy.ProdOrderChoice;
//                     New.PurchOrderChoice := Legacy.PurchOrderChoice;
//                     New.TransOrderChoice := Legacy.TransOrderChoice;
//                     New.AsmOrderChoice := Legacy.AsmOrderChoice;
//                     New."Auto Refresh Production Order" := Legacy."Auto Refresh Production Order";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq159: DXR_Ajuste Inventario Con Old2 (59234) -> DXR_Ajuste Inventario Config (53304).
//     // PK = ("Item Padre", "Item Padre UM").
//     local procedure MigrateAjusteInventarioConfigOld2Table()
//     var
//         Legacy: Record "DXR_Ajuste Inventario Con Old2";
//         New: Record "DXR_Ajuste Inventario Config";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Item Padre", Legacy."Item Padre UM") then begin
//                     New.Init();
//                     New."Item Padre" := Legacy."Item Padre";
//                     New."Item Padre UM" := Legacy."Item Padre UM";
//                     New."Item Hijo" := Legacy."Item Hijo";
//                     New."Item Hijo UM" := Legacy."Item Hijo UM";
//                     New."Cant. x UM Padre" := Legacy."Cant. x UM Padre";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq161: DXR_Area de Trabajo Old2 (59236) -> DXR_Area de Trabajo (53306). PK = "Code".
//     local procedure MigrateAreaDeTrabajoOld2Table()
//     var
//         Legacy: Record "DXR_Area de Trabajo Old2";
//         New: Record "DXR_Area de Trabajo";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Estado := Legacy.Estado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq168: DXR_Categoria Servicios Old2 (59243) -> DXR_Categoria Servicios (53313).
//     // PK = "ID Services".
//     local procedure MigrateCategoriaServiciosOld2Table()
//     var
//         Legacy: Record "DXR_Categoria Servicios Old2";
//         New: Record "DXR_Categoria Servicios";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."ID Services") then begin
//                     New.Init();
//                     New."ID Services" := Legacy."ID Services";
//                     New."Type Services" := Legacy."Type Services";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq170: DXR_Cilindros - Setup Old2 (59245) -> DXR_Cilindros - Setup (53315). PK = "Key".
//     local procedure MigrateCilindrosSetupOld2Table()
//     var
//         Legacy: Record "DXR_Cilindros - Setup Old2";
//         New: Record "DXR_Cilindros - Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New."Key" := Legacy."Key";
//                     New."Cilindros No. Series" := Legacy."Cilindros No. Series";
//                     New."Mov. Cilindros No. Series" := Legacy."Mov. Cilindros No. Series";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq172: DXR_Conf. Extracto Bancar Old2 (59248) -> DXR_Conf. Extracto Bancario (53318).
//     // PK = "Key".
//     local procedure MigrateConfExtractoBancarioOld2Table()
//     var
//         Legacy: Record "DXR_Conf. Extracto Bancar Old2";
//         New: Record "DXR_Conf. Extracto Bancario";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New."Key" := Legacy."Key";
//                     New.Active := Legacy.Active;
//                     New."Folder Patch" := Legacy."Folder Patch";
//                     New."Days Run" := Legacy."Days Run";
//                     New."Date Tolerance" := Legacy."Date Tolerance";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq173: DXR_Config. NCF Ventas Old2 (59249) -> DXR_Config. NCF Ventas (53319).
//     // PK = "Código".
//     local procedure MigrateConfigNCFVentasOld2Table()
//     var
//         Legacy: Record "DXR_Config. NCF Ventas Old2";
//         New: Record "DXR_Config. NCF Ventas";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Código") then begin
//                     New.Init();
//                     New."Código" := Legacy."Código";
//                     New."Descripción" := Legacy."Descripción";
//                     New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
//                     New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
//                     New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
//                     New."Tipo NCF" := Legacy."Tipo NCF";
//                     New."Alternal No. Series_DXR" := Legacy."Alternal No. Series_DXR";
//                     New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq174: DXR_Config. NCF Ventas ST Old2 (59250) -> DXR_Config. NCF Ventas STD (53320).
//     // PK = ("Código", "Terminal No.").
//     local procedure MigrateConfigNCFVentasSTDOld2Table()
//     var
//         Legacy: Record "DXR_Config. NCF Ventas ST Old2";
//         New: Record "DXR_Config. NCF Ventas STD";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Código", Legacy."Terminal No.") then begin
//                     New.Init();
//                     New."Código" := Legacy."Código";
//                     New."Descripción" := Legacy."Descripción";
//                     New."No. Serie NCF Fact." := Legacy."No. Serie NCF Fact.";
//                     New."No. Serie NCF NCR" := Legacy."No. Serie NCF NCR";
//                     New."Tipo Doc. Fiscal" := Legacy."Tipo Doc. Fiscal";
//                     New."Store No." := Legacy."Store No.";
//                     New."Terminal No." := Legacy."Terminal No.";
//                     New."Tipo NCF" := Legacy."Tipo NCF";
//                     New."Alternal No. Series_DXR" := Legacy."Alternal No. Series_DXR";
//                     New."EF Alternal No. Series NC" := Legacy."EF Alternal No. Series NC";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq175: DXR_Config. Polizas Old2 (59251) -> DXR_Config. Polizas (53321).
//     // PK = ("Fecha Desde", "Fecha Hasta", "Monto Minimo", "Monto Maximo").
//     local procedure MigrateConfigPolizasOld2Table()
//     var
//         Legacy: Record "DXR_Config. Polizas Old2";
//         New: Record "DXR_Config. Polizas";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Fecha Desde", Legacy."Fecha Hasta", Legacy."Monto Minimo", Legacy."Monto Maximo") then begin
//                     New.Init();
//                     New."Fecha Desde" := Legacy."Fecha Desde";
//                     New."Fecha Hasta" := Legacy."Fecha Hasta";
//                     New."Monto Minimo" := Legacy."Monto Minimo";
//                     New."Monto Maximo" := Legacy."Monto Maximo";
//                     New."Cantidad Cilindros" := Legacy."Cantidad Cilindros";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq176: DXR_Configuracion CB Old2 (59252) -> DXR_Configuracion CB (53322).
//     // PK = (Bloque, "Reason Codes Filter", Orden).
//     local procedure MigrateConfiguracionCBOld2Table()
//     var
//         Legacy: Record "DXR_Configuracion CB Old2";
//         New: Record "DXR_Configuracion CB";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Bloque, Legacy."Reason Codes Filter", Legacy.Orden) then begin
//                     New.Init();
//                     New.Bloque := Legacy.Bloque;
//                     New.Orden := Legacy.Orden;
//                     New."Descripcion Renglon" := Legacy."Descripcion Renglon";
//                     New."Reason Codes Filter" := Legacy."Reason Codes Filter";
//                     New.Orientacion := Legacy.Orientacion;
//                     New.Transito := Legacy.Transito;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq177: DXR_Config - Discr Old2 (59253) -> DXR_Config - Discr (53323). PK = "key".
//     local procedure MigrateConfiguracionDiscrepanciasOld2Table()
//     var
//         Legacy: Record "DXR_Config - Discr";
//         New: Record "DXR_Config - Discr";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."key") then begin
//                     New.Init();
//                     New."key" := Legacy."key";
//                     New."URL - Archivos Temporal" := Legacy."URL - Archivos Temporal";
//                     New."URL  - Archivos Registrados" := Legacy."URL  - Archivos Registrados";
//                     New."URL - Archivos Eliminados" := Legacy."URL - Archivos Eliminados";
//                     New."No. Serie Discrepancia" := Legacy."No. Serie Discrepancia";
//                     New."No. Serie Discrep. Registrada" := Legacy."No. Serie Discrep. Registrada";
//                     New.AutoPost := Legacy.AutoPost;
//                     New."Max Cantidad Dias retrocede" := Legacy."Max Cantidad Dias retrocede";
//                     New."URL Lectura - Archivos Temp." := Legacy."URL Lectura - Archivos Temp.";
//                     New."URL Lectura - Archivos Regis." := Legacy."URL Lectura - Archivos Regis.";
//                     New."URL Lectura - Archivos Elimin." := Legacy."URL Lectura - Archivos Elimin.";
//                     New."Reg Prod. in Discre." := Legacy."Reg Prod. in Discre.";
//                     New."Control Disc. sin Attch" := Legacy."Control Disc. sin Attch";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq178: DXR_Config Encuestas - PO Old2 (59254) -> DXR_Config Encuestas - POS (53324).
//     // PK = ("Store No.", "Pos Terminal No.", "Transacction No.").
//     local procedure MigrateConfiguracionEncuestasPOSOld2Table()
//     var
//         Legacy: Record "DXR_Config Encuestas - PO Old2";
//         New: Record "DXR_Config Encuestas - POS";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Store No.", Legacy."Pos Terminal No.", Legacy."Transacction No.") then begin
//                     New.Init();
//                     New."Store No." := Legacy."Store No.";
//                     New."Pos Terminal No." := Legacy."Pos Terminal No.";
//                     New."Transacction No." := Legacy."Transacction No.";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq179: DXR_Config Req Old2 (59255) -> DXR_Config Req (53325). PK = "Key" (AutoIncrement on
//     // both sides). Same field, same AutoIncrement attribute, already precedent-set by the sibling
//     // BELLON-P2 procedure MigrateConfiguracionesRequisicionTable() (Configuraciones Requisicion
//     // 50038 -> DXR_Config Req 53325, reviewed clean) - explicit non-zero legacy values are honored
//     // by AutoIncrement (it only auto-assigns when the field is 0), so the value is copied directly
//     // like every other field, consistent with that established sibling pattern.
//     local procedure MigrateConfiguracionesRequisicionOld2Table()
//     var
//         Legacy: Record "DXR_Config Req Old2";
//         New: Record "DXR_Config Req";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New."Key" := Legacy."Key";
//                     New."No. Serie Pre-Req" := Legacy."No. Serie Pre-Req";
//                     New."No Serie Req" := Legacy."No Serie Req";
//                     New."No Serie Pre-Req No Stock" := Legacy."No Serie Pre-Req No Stock";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq180: DXR_Configuracion - MEDAL Old2 (59256) -> DXR_Configuracion - MEDALLIA (53326).
//     // PK = "Key".
//     local procedure MigrateConfiguracionMedalliaOld2Table()
//     var
//         Legacy: Record "DXR_Configuracion - MEDAL Old2";
//         New: Record "DXR_Configuracion - MEDALLIA";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New."Key" := Legacy."Key";
//                     New."Log Request" := Legacy."Log Request";
//                     New."Log Response" := Legacy."Log Response";
//                     New.MedalliaURL := Legacy.MedalliaURL;
//                     New.UserCredentials := Legacy.UserCredentials;
//                     New.PasswordCredentials := Legacy.PasswordCredentials;
//                     New."Pedido Ventas" := Legacy."Pedido Ventas";
//                     New.Transportacion := Legacy.Transportacion;
//                     New."Facturas POS" := Legacy."Facturas POS";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq181: DXR_Conf. Pagos Ecommerce Old2 (59257) -> DXR_Conf. Pagos Ecommerce Azul (53327).
//     // PK = "Key".
//     local procedure MigrateConfPagosEcommerceAzulOld2Table()
//     var
//         Legacy: Record "DXR_Conf. Pagos Ecommerce Old2";
//         New: Record "DXR_Conf. Pagos Ecommerce Azul";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New.MerchantID := Legacy.MerchantID;
//                     New.MerchantName := Legacy.MerchantName;
//                     New.MerchantType := Legacy.MerchantType;
//                     New.CurrencyCode := Legacy.CurrencyCode;
//                     New.ApprovedURL := Legacy.ApprovedURL;
//                     New.DeclinedURL := Legacy.DeclinedURL;
//                     New.CancelURL := Legacy.CancelURL;
//                     New.LogoURL := Legacy.LogoURL;
//                     New.ProductImageURL := Legacy.ProductImageURL;
//                     New.DesignV2 := Legacy.DesignV2;
//                     New.Locale := Legacy.Locale;
//                     New.AuthKey := Legacy.AuthKey;
//                     New.PaymentPageUrl := Legacy.PaymentPageUrl;
//                     New."Key" := Legacy."Key";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq182: DXR_Control Proc por Alma Old2 (59258) -> DXR_Control Proc por Almacen (53328).
//     // PK = "Location Code".
//     local procedure MigrateControlProcesosPorAlmacenOld2Table()
//     var
//         Legacy: Record "DXR_Control Proc por Alma Old2";
//         New: Record "DXR_Control Proc por Almacen";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Location Code") then begin
//                     New.Init();
//                     New."Location Code" := Legacy."Location Code";
//                     New.Ventas := Legacy.Ventas;
//                     New.Compras := Legacy.Compras;
//                     New.Ajustes := Legacy.Ajustes;
//                     New.Ensamblados := Legacy.Ensamblados;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // ===== 16 more SETUP-category "Old2" whole-table restores converted to native typed logic =====
//     // Task A.4 Batch 5: zero RecordRef/FieldRef, zero TransferFields - every field assigned
//     // explicitly. Replaces 16 more of the MigrateLegacyTableData(...) calls above (still used by
//     // out-of-scope tables in MigrateAllRenumberedDXRTables()), same rationale as Batch 4 above
//     // (eliminates the "The record is already open." bug for these 16 tables specifically). Each of
//     // these 16 tables' final destination (53xxx) is the SAME table a sibling BELLON-P2 concept
//     // (already converted in DXRMCCBellonMigrPhase2's own Task A.4 Batches 1-3, reviewed clean)
//     // already writes to from a DIFFERENT legacy source (50xxx). Both procedures do a
//     // Get()-before-Insert() against the same destination table - intentional and idempotent, not a
//     // conflict. Field lists and primary keys verified independently against this batch's real
//     // Tables.old2\*.Table.al (Old2 legacy) and Tables\*.Table.al (DXR_ new) sources - field-for-field
//     // identical on both sides for all 16 tables in this batch, no renamed/shadow fields found (cross
//     // checked against the sibling BELLON-P2 procedures for the same 16 destination tables too).

//     // seq186: DXR_Draw Setup Old2 (59262) -> DXR_Draw Setup (53332). PK = "Entry No." (AutoIncrement
//     // on both sides). Same field, same AutoIncrement attribute, already precedent-set by the sibling
//     // BELLON-P2 procedure MigrateDrawSetupTable() (Draw Setup 50052 -> DXR_Draw Setup 53332, reviewed
//     // clean) - explicit non-zero legacy values are honored by AutoIncrement (it only auto-assigns
//     // when the field is 0), so the value is copied directly like every other field, consistent with
//     // that established sibling pattern. Field "Ready" (6) is a FlowField (CalcFormula) on both sides
//     // - not copied, calculated on read.
//     local procedure MigrateDrawSetupOld2Table()
//     var
//         Legacy: Record "DXR_Draw Setup Old2";
//         New: Record "DXR_Draw Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Entry No.") then begin
//                     New.Init();
//                     New.Promotions := Legacy.Promotions;
//                     New."Draw Date" := Legacy."Draw Date";
//                     New.Description := Legacy.Description;
//                     New."Winning customer" := Legacy."Winning customer";
//                     New."Winning Ticket" := Legacy."Winning Ticket";
//                     New."Entry No." := Legacy."Entry No.";
//                     New.Done := Legacy.Done;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq187: DXR_Email Source Tmpl Rel Old2 (59263) -> DXR_Email Source Tmpl Rel (53333).
//     // PK = ("Email Template ID", "Email Source Table ID", "Field Email No."). Field
//     // "Field Email Name" (5) is a FlowField (CalcFormula) on both sides - not copied.
//     local procedure MigrateEmailSourceTemplateRelationOld2Table()
//     var
//         Legacy: Record "DXR_Email Source Tmpl Rel Old2";
//         New: Record "DXR_Email Source Tmpl Rel";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Email Template ID", Legacy."Email Source Table ID", Legacy."Field Email No.") then begin
//                     New.Init();
//                     New."Email Template ID" := Legacy."Email Template ID";
//                     New."Email Source Table ID" := Legacy."Email Source Table ID";
//                     New."Email Source Table Name" := Legacy."Email Source Table Name";
//                     New."Field Email No." := Legacy."Field Email No.";
//                     New.CC := Legacy.CC;
//                     New."Requerir Correo" := Legacy."Requerir Correo";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq190: DXR_EPagos Setup Old2 (59266) -> DXR_EPagos Setup (53336). PK = "Primary Key".
//     local procedure MigrateEPagosSetupOld2Table()
//     var
//         Legacy: Record "DXR_EPagos Setup Old2";
//         New: Record "DXR_EPagos Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Primary Key") then begin
//                     New.Init();
//                     New."Primary Key" := Legacy."Primary Key";
//                     New."Journal Template Name" := Legacy."Journal Template Name";
//                     New."Journal Batch Name" := Legacy."Journal Batch Name";
//                     New."Epago WS url" := Legacy."Epago WS url";
//                     New.User := Legacy.User;
//                     New.Password := Legacy.Password;
//                     New."No Series" := Legacy."No Series";
//                     New."Use Upproval" := Legacy."Use Upproval";
//                     New.UserBPD := Legacy.UserBPD;
//                     New.PassBPD := Legacy.PassBPD;
//                     New.PathCert := Legacy.PathCert;
//                     New.passCert := Legacy.passCert;
//                     New.NoLote := Legacy.NoLote;
//                     New."Url Login" := Legacy."Url Login";
//                     New."Url Send Data" := Legacy."Url Send Data";
//                     New."Url Status Global" := Legacy."Url Status Global";
//                     New.Url := Legacy.Url;
//                     New."Payment Method Code" := Legacy."Payment Method Code";
//                     New."No Series Journal" := Legacy."No Series Journal";
//                     New."VendorPay No. Series" := Legacy."VendorPay No. Series";
//                     New."CreditTo No. Series" := Legacy."CreditTo No. Series";
//                     New.ShowJson := Legacy.ShowJson;
//                     New."Deny Multi Currency" := Legacy."Deny Multi Currency";
//                     New."Use StartSession" := Legacy."Use StartSession";
//                     New."Registrar Movs. Consolidados" := Legacy."Registrar Movs. Consolidados";
//                     New."Registro Automatico" := Legacy."Registro Automatico";
//                     New."Use Limit ACH" := Legacy."Use Limit ACH";
//                     New."Amount Limit ACH" := Legacy."Amount Limit ACH";
//                     New.DaysTo := Legacy.DaysTo;
//                     New.DaysFrom := Legacy.DaysFrom;
//                     New.NextDay := Legacy.NextDay;
//                     New."Use Status LOG" := Legacy."Use Status LOG";
//                     New."Max Days  Allow Payment" := Legacy."Max Days  Allow Payment";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq191: DXR_Exclude Filter Journal Old2 (59267) -> DXR_Exclude Filter Journal (53337).
//     // PK = ("Journal Template", "Journal Batch"). Legacy AL object name truncated to
//     // "DXR_Exclude Filter Journa Old2" (30-char limit) - confirmed via Tables.old2\ExcludeFilterJournal.Table.al line 1.
//     local procedure MigrateExcludeFilterJournalOld2Table()
//     var
//         Legacy: Record "DXR_Exclude Filter Journa Old2";
//         New: Record "DXR_Exclude Filter Journal";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Journal Template", Legacy."Journal Batch") then begin
//                     New.Init();
//                     New."Journal Template" := Legacy."Journal Template";
//                     New."Journal Batch" := Legacy."Journal Batch";
//                     New.Excluir := Legacy.Excluir;
//                     New.Type := Legacy.Type;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq192: DXR_Excluir Term - ItemSearch Old2 (59268) -> DXR_Excluir Term - ItemSearch (53338).
//     // PK = Termino. Legacy AL object name truncated to "DXR_Excluir Term - ItemSe Old2"
//     // (30-char limit) - confirmed via Tables.old2\ExcluirTerminosItemSearch.Table.al line 1.
//     local procedure MigrateExcluirTerminosItemSearchOld2Table()
//     var
//         Legacy: Record "DXR_Excluir Term - ItemSe Old2";
//         New: Record "DXR_Excluir Term - ItemSearch";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Termino) then begin
//                     New.Init();
//                     New.Termino := Legacy.Termino;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq193: DXR_File Structure Old2 (59269) -> DXR_File Structure (53339). PK = (Bank, "Field No").
//     local procedure MigrateFileStructureOld2Table()
//     var
//         Legacy: Record "DXR_File Structure Old2";
//         New: Record "DXR_File Structure";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Bank, Legacy."Field No") then begin
//                     New.Init();
//                     New."Field No" := Legacy."Field No";
//                     New."Field Name" := Legacy."Field Name";
//                     New."Length Field" := Legacy."Length Field";
//                     New."From Field" := Legacy."From Field";
//                     New.Bank := Legacy.Bank;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq194: DXR_Forma de Pago Old2 (59270) -> DXR_Forma de Pago (53340). PK = "Code".
//     local procedure MigrateFormaDePagoOld2Table()
//     var
//         Legacy: Record "DXR_Forma de Pago Old2";
//         New: Record "DXR_Forma de Pago";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Description := Legacy.Description;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq212: DXR_Inventory Masks Old2 (59288) -> DXR_Inventory Masks (53358). PK = "Seq. No.".
//     local procedure MigrateInventoryMasksOld2Table()
//     var
//         Legacy: Record "DXR_Inventory Masks Old2";
//         New: Record "DXR_Inventory Masks";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Seq. No.") then begin
//                     New.Init();
//                     New.Templates := Legacy.Templates;
//                     New."Handheld User" := Legacy."Handheld User";
//                     New."Store No." := Legacy."Store No.";
//                     New."Entry Type" := Legacy."Entry Type";
//                     New."Reason Code" := Legacy."Reason Code";
//                     New.Unit := Legacy.Unit;
//                     New."Vendor No." := Legacy."Vendor No.";
//                     New.Description := Legacy.Description;
//                     New."Journal Type" := Legacy."Journal Type";
//                     New.Printing := Legacy.Printing;
//                     New.Posting := Legacy.Posting;
//                     New."Type of Entering" := Legacy."Type of Entering";
//                     New."Shortcut Dimension 2 Code" := Legacy."Shortcut Dimension 2 Code";
//                     New."New Store Code" := Legacy."New Store Code";
//                     New."Source Code" := Legacy."Source Code";
//                     New."Seq. No." := Legacy."Seq. No.";
//                     New."Product Strict" := Legacy."Product Strict";
//                     New.Accepted := Legacy.Accepted;
//                     New.Location := Legacy.Location;
//                     New."New Location" := Legacy."New Location";
//                     New.Batch := Legacy.Batch;
//                     New."Use Variants" := Legacy."Use Variants";
//                     New."Shortcut Dimension 1 Code" := Legacy."Shortcut Dimension 1 Code";
//                     New."Pre-Process" := Legacy."Pre-Process";
//                     New."Pre-Process Object ID" := Legacy."Pre-Process Object ID";
//                     New."Close Process" := Legacy."Close Process";
//                     New."Close Process Object ID" := Legacy."Close Process Object ID";
//                     New."Confirm Codeunit" := Legacy."Confirm Codeunit";
//                     New."Report Object ID" := Legacy."Report Object ID";
//                     New."Product Group Filter" := Legacy."Product Group Filter";
//                     New."Inv. Posting Gr. Filter" := Legacy."Inv. Posting Gr. Filter";
//                     New."Use Area" := Legacy."Use Area";
//                     New."Handheld Type" := Legacy."Handheld Type";
//                     New."Blocked for RF" := Legacy."Blocked for RF";
//                     New."Leading Behavior" := Legacy."Leading Behavior";
//                     New."Needs to Be in Distribution" := Legacy."Needs to Be in Distribution";
//                     New."Needs to Be in Worksheet" := Legacy."Needs to Be in Worksheet";
//                     New."Needs to Be Ordered by Hand" := Legacy."Needs to Be Ordered by Hand";
//                     New."Needs to Be Ordered at Store" := Legacy."Needs to Be Ordered at Store";
//                     New."Search for Item by" := Legacy."Search for Item by";
//                     New."Quantity Method" := Legacy."Quantity Method";
//                     New."Order Date Type" := Legacy."Order Date Type";
//                     New."Order Date Calculation" := Legacy."Order Date Calculation";
//                     New."End Date Type" := Legacy."End Date Type";
//                     New."End Date Calculation" := Legacy."End Date Calculation";
//                     New."Change Vendor in Line" := Legacy."Change Vendor in Line";
//                     New."Change UOM in Line" := Legacy."Change UOM in Line";
//                     New."Item Check" := Legacy."Item Check";
//                     New."Quick-default Quantity" := Legacy."Quick-default Quantity";
//                     New."Inv. Adjust. Group" := Legacy."Inv. Adjust. Group";
//                     New."Vendor to Use in Returns" := Legacy."Vendor to Use in Returns";
//                     New."Return Reason Code" := Legacy."Return Reason Code";
//                     New."Item Journal Doc No." := Legacy."Item Journal Doc No.";
//                     New.Status := Legacy.Status;
//                     New."Use Batch Posting" := Legacy."Use Batch Posting";
//                     New."Order Status" := Legacy."Order Status";
//                     New."Standalone Store Action" := Legacy."Standalone Store Action";
//                     New."Document Group" := Legacy."Document Group";
//                     New.ID := Legacy.ID;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq225: DXR_Marcas Old2 (59301) -> DXR_Marcas (53371). PK = ID.
//     local procedure MigrateMarcasOld2Table()
//     var
//         Legacy: Record "DXR_Marcas Old2";
//         New: Record "DXR_Marcas";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.ID) then begin
//                     New.Init();
//                     New.ID := Legacy.ID;
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Comision_Venta := Legacy.Comision_Venta;
//                     New.Comision_Cobro := Legacy.Comision_Cobro;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq226: DXR_Member Management Setup Old2 (59302) -> DXR_Member Management Setup (53372).
//     // PK = "Code". Legacy AL object name truncated to "DXR_Member Management Set Old2"
//     // (30-char limit) - confirmed via Tables.old2\MemberManagementSetup.Table.al line 1.
//     local procedure MigrateMemberManagementSetupOld2Table()
//     var
//         Legacy: Record "DXR_Member Management Set Old2";
//         New: Record "DXR_Member Management Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New."Campaign No. Series" := Legacy."Campaign No. Series";
//                     New."Discount Tracking No. Series" := Legacy."Discount Tracking No. Series";
//                     New."Member Point Offer No. Series" := Legacy."Member Point Offer No. Series";
//                     New."Missing  Attribute Handling" := Legacy."Missing  Attribute Handling";
//                     New."Reason Blocking By Attribute" := Legacy."Reason Blocking By Attribute";
//                     New."Reason Codes Devices" := Legacy."Reason Codes Devices";
//                     New."Amount Type for Point Calc." := Legacy."Amount Type for Point Calc.";
//                     New."Mobile Default Club Code" := Legacy."Mobile Default Club Code";
//                     New."Mobile Card No. Series" := Legacy."Mobile Card No. Series";
//                     New."Min. Point Balance" := Legacy."Min. Point Balance";
//                     New."Min. Point Qty. in Redemption" := Legacy."Min. Point Qty. in Redemption";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq227: DXR_Motivo Cierre - Discr Old2 (59303) -> DXR_Motivo Cierre - Discr (53373).
//     // PK = "Code".
//     local procedure MigrateMotivoCierreDiscrepanciasOld2Table()
//     var
//         Legacy: Record "DXR_Motivo Cierre - Discr Old2";
//         New: Record "DXR_Motivo Cierre - Discr";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Anular := Legacy.Anular;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq228: DXR_Motivo Discrepancia Old2 (59304) -> DXR_Motivo Discrepancia (53374). PK = "Code".
//     local procedure MigrateMotivoDiscrepanciaOld2Table()
//     var
//         Legacy: Record "DXR_Motivo Discrepancia Old2";
//         New: Record "DXR_Motivo Discrepancia";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Description := Legacy.Description;
//                     New.Habilitado := Legacy.Habilitado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq239: DXR_Profesion Old2 (59315) -> DXR_Profesion (53385). PK = "Code".
//     local procedure MigrateProfesionOld2Table()
//     var
//         Legacy: Record "DXR_Profesion Old2";
//         New: Record "DXR_Profesion";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Estado := Legacy.Estado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq240: DXR_Promotion Setup Old2 (59316) -> DXR_Promotion Setup (53386). PK = "Key".
//     local procedure MigratePromotionSetupOld2Table()
//     var
//         Legacy: Record "DXR_Promotion Setup Old2";
//         New: Record "DXR_Promotion Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Key") then begin
//                     New.Init();
//                     New."Key" := Legacy."Key";
//                     New."Promotion Active" := Legacy."Promotion Active";
//                     New."No Series Tickets" := Legacy."No Series Tickets";
//                     New."No Series Promotions" := Legacy."No Series Promotions";
//                     New."Journal Template Name" := Legacy."Journal Template Name";
//                     New."Journal Batch Name" := Legacy."Journal Batch Name";
//                     New."Registro Automatico" := Legacy."Registro Automatico";
//                     New.InfocedePOS := Legacy.InfocedePOS;
//                     New.InfocedePOSRnc := Legacy.InfocedePOSRnc;
//                     New.InfocedePOStlf := Legacy.InfocedePOStlf;
//                     New."Max Point Change" := Legacy."Max Point Change";
//                     New."Min Point Change" := Legacy."Min Point Change";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq242: DXR_Provincia Old2 (59318) -> DXR_Provincia (53388). PK = "Code".
//     local procedure MigrateProvinciaOld2Table()
//     var
//         Legacy: Record "DXR_Provincia Old2";
//         New: Record "DXR_Provincia";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Name := Legacy.Name;
//                     New."Cod. BPD" := Legacy."Cod. BPD";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq246: DXR_Sales Dept Old2 (59322) -> DXR_Sales Dept (53392). PK = "Code".
//     local procedure MigrateSalesDeptOld2Table()
//     var
//         Legacy: Record "DXR_Sales Dept Old2";
//         New: Record "DXR_Sales Dept";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Description := Legacy.Description;
//                     New."Visible in Webshop" := Legacy."Visible in Webshop";
//                     New."Sort No." := Legacy."Sort No.";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // ===== 14 FINAL SETUP-category "Old2" whole-table restores converted to native typed logic =====
//     // Task A.4 Batch 6 (FINAL batch): zero RecordRef/FieldRef, zero TransferFields - every field
//     // assigned explicitly. Replaces the last 14 of the MigrateLegacyTableData(...) calls in
//     // Setup scope (the helper remains in use below for ~71 other, out-of-scope non-Setup "Old2"
//     // tables in MigrateAllRenumberedDXRTables() - not removed, not dead). Completes BELLON-P6's
//     // entire Setup sweep. Each of these 14 tables' final destination (53xxx) is the SAME table a
//     // sibling BELLON-P2 concept (already converted in DXRMCCBellonMigrPhase2's own Task A.4
//     // Batches 1-3, reviewed clean) already writes to from a DIFFERENT legacy source (50xxx). Both
//     // procedures do a Get()-before-Insert() against the same destination table - intentional and
//     // idempotent, not a conflict. Field lists and primary keys verified independently against this
//     // batch's real Tables.old2\*.Table.al (Old2 legacy) and Tables\*.Table.al (DXR_ new) sources -
//     // field-for-field identical on both sides for all 14 tables in this batch, no renamed/shadow
//     // fields found (cross checked against the sibling BELLON-P2 procedures for the same 14
//     // destination tables too). No AutoIncrement PKs, no BLOB fields in this batch.

//     // seq247: DXR_Sales Groups Old2 (59323) -> DXR_Sales Groups (53393). PK = "Code".
//     local procedure MigrateSalesGroupsOld2Table()
//     var
//         Legacy: Record "DXR_Sales Groups Old2";
//         New: Record "DXR_Sales Groups";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Description := Legacy.Description;
//                     New."Visible in Webshop" := Legacy."Visible in Webshop";
//                     New."Sales Dept Code" := Legacy."Sales Dept Code";
//                     New."Sort No." := Legacy."Sort No.";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq248: DXR_Sales SubGroups Old2 (59324) -> DXR_Sales SubGroups (53394). PK = "Code".
//     local procedure MigrateSalesSubGroupsOld2Table()
//     var
//         Legacy: Record "DXR_Sales SubGroups Old2";
//         New: Record "DXR_Sales SubGroups";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Description := Legacy.Description;
//                     New."Visible in Webshop" := Legacy."Visible in Webshop";
//                     New."Sort No." := Legacy."Sort No.";
//                     New."Sales Group" := Legacy."Sales Group";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq250: DXR_Std POS DASCOM Paymt Old2 (59326) -> DXR_Std POS DASCOM Paymt Eqv (53396).
//     // PK = "Payment Code". Legacy AL object name truncated to "DXR_Std POS DASCOM Paymt Old2"
//     // (30-char limit) - confirmed via Tables.old2\StandardPOSDASCOMPaymtEqv.Table.al line 1.
//     local procedure MigrateStdPOSDASCOMPaymtEqvOld2Table()
//     var
//         Legacy: Record "DXR_Std POS DASCOM Paymt Old2";
//         New: Record "DXR_Std POS DASCOM Paymt Eqv";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Payment Code") then begin
//                     New.Init();
//                     New."Payment Code" := Legacy."Payment Code";
//                     New.Description := Legacy.Description;
//                     New."DASCOM Eqv" := Legacy."DASCOM Eqv";
//                     New."User Created" := Legacy."User Created";
//                     New."Date Created" := Legacy."Date Created";
//                     New."User Last Modified" := Legacy."User Last Modified";
//                     New."Last Date Modified" := Legacy."Last Date Modified";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq251: DXR_Standard POS Gen. Com Old2 (59327) -> DXR_Standard POS Gen. Comments (53397).
//     // PK = ("Fiscal Doc. Type", "Line No."). Legacy AL object name truncated to
//     // "DXR_Standard POS Gen. Com Old2" (30-char limit) - confirmed via
//     // Tables.old2\StandardPOSGenComments.Table.al line 1.
//     local procedure MigrateStandardPOSGenCommentsOld2Table()
//     var
//         Legacy: Record "DXR_Standard POS Gen. Com Old2";
//         New: Record "DXR_Standard POS Gen. Comments";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Fiscal Doc. Type", Legacy."Line No.") then begin
//                     New.Init();
//                     New."Fiscal Doc. Type" := Legacy."Fiscal Doc. Type";
//                     New."Line No." := Legacy."Line No.";
//                     New."Text Message" := Legacy."Text Message";
//                     New."User Created" := Legacy."User Created";
//                     New."Date Created" := Legacy."Date Created";
//                     New."User Last Modified" := Legacy."User Last Modified";
//                     New."Last Date Modified" := Legacy."Last Date Modified";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq252: DXR_Standard POS Users Old2 (59328) -> DXR_Standard POS Users (53398). PK = "User Code".
//     local procedure MigrateStandardPOSUsersOld2Table()
//     var
//         Legacy: Record "DXR_Standard POS Users Old2";
//         New: Record "DXR_Standard POS Users";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."User Code") then begin
//                     New.Init();
//                     New."User Code" := Legacy."User Code";
//                     New."Standard POS Store" := Legacy."Standard POS Store";
//                     New."Standard POS Terminal" := Legacy."Standard POS Terminal";
//                     New."User Name" := Legacy."User Name";
//                     New.Inactive := Legacy.Inactive;
//                     New."User Created" := Legacy."User Created";
//                     New."Date Created" := Legacy."Date Created";
//                     New."User Last Modified" := Legacy."User Last Modified";
//                     New."Last Date Modified" := Legacy."Last Date Modified";
//                     New."Filter Reg" := Legacy."Filter Reg";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq254: DXR_Summary Recon Setup Old2 (59330) -> DXR_Summary Recon Setup (53400). PK = Serial.
//     local procedure MigrateSummaryReconSetupOld2Table()
//     var
//         Legacy: Record "DXR_Summary Recon Setup Old2";
//         New: Record "DXR_Summary Recon Setup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Serial) then begin
//                     New.Init();
//                     New.Serial := Legacy.Serial;
//                     New.Type := Legacy.Type;
//                     New."Order" := Legacy."Order";
//                     New."Type Text" := Legacy."Type Text";
//                     New.Grupo := Legacy.Grupo;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq255: DXR_Tasas BC Old2 (59331) -> DXR_Tasas BC (53401). PK = "Fecha Tasa".
//     local procedure MigrateTasasBCOld2Table()
//     var
//         Legacy: Record "DXR_Tasas BC Old2";
//         New: Record "DXR_Tasas BC";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Fecha Tasa") then begin
//                     New.Init();
//                     New."Fecha Tasa" := Legacy."Fecha Tasa";
//                     New.Tasa := Legacy.Tasa;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq258: DXR_Tipo de Contenedor Old2 (59334) -> DXR_Tipo de Contenedor (53404). PK = "Code".
//     local procedure MigrateTipoDeContenedorOld2Table()
//     var
//         Legacy: Record "DXR_Tipo de Contenedor Old2";
//         New: Record "DXR_Tipo de Contenedor";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Estado := Legacy.Estado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq259: DXR_Tipo Gas Old2 (59335) -> DXR_Tipo Gas (53405). PK = Id.
//     local procedure MigrateTipoGasOld2Table()
//     var
//         Legacy: Record "DXR_Tipo Gas Old2";
//         New: Record "DXR_Tipo Gas";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Id) then begin
//                     New.Init();
//                     New.Id := Legacy.Id;
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Estado := Legacy.Estado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq260: DXR_Tipos o Agentes Old2 (59336) -> DXR_Tipos o Agentes (53406). PK = "Code".
//     local procedure MigrateTiposOAgentesOld2Table()
//     var
//         Legacy: Record "DXR_Tipos o Agentes Old2";
//         New: Record "DXR_Tipos o Agentes";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."Code") then begin
//                     New.Init();
//                     New."Code" := Legacy."Code";
//                     New.Descripcion := Legacy.Descripcion;
//                     New.Estado := Legacy.Estado;
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq262: DXR_Tratados Arancelarios Old2 (59338) -> DXR_Tratados Arancelarios (53408).
//     // PK = (Arancel, Pais).
//     local procedure MigrateTratadosArancelariosOld2Table()
//     var
//         Legacy: Record "DXR_Tratados Arancelarios Old2";
//         New: Record "DXR_Tratados Arancelarios";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.Arancel, Legacy.Pais) then begin
//                     New.Init();
//                     New.Arancel := Legacy.Arancel;
//                     New.Pais := Legacy.Pais;
//                     New."Tasa Arancel" := Legacy."Tasa Arancel";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq263: DXR_UserApproverByBuyerGr Old2 (59339) -> DXR_UserApproverByBuyerGroup (53409).
//     // PK = (UserID, "Buyer Group"). Legacy AL object name truncated to
//     // "DXR_UserApproverByBuyerGr Old2" (30-char limit) - confirmed via
//     // Tables.old2\UserApproverByBuyerGroup.Table.al line 1.
//     local procedure MigrateUserApproverByBuyerGroupOld2Table()
//     var
//         Legacy: Record "DXR_UserApproverByBuyerGr Old2";
//         New: Record "DXR_UserApproverByBuyerGroup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.UserID, Legacy."Buyer Group") then begin
//                     New.Init();
//                     New.UserID := Legacy.UserID;
//                     New."Buyer Group" := Legacy."Buyer Group";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq264: DXR_UserByBuyerGroup Old2 (59340) -> DXR_UserByBuyerGroup (53410).
//     // PK = (UserID, "Buyer Group Code").
//     local procedure MigrateUserByBuyerGroupOld2Table()
//     var
//         Legacy: Record "DXR_UserByBuyerGroup Old2";
//         New: Record "DXR_UserByBuyerGroup";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy.UserID, Legacy."Buyer Group Code") then begin
//                     New.Init();
//                     New.UserID := Legacy.UserID;
//                     New."Buyer Group Code" := Legacy."Buyer Group Code";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     // seq268: DXR_VAT Bus. Settings Old2 (59344) -> DXR_VAT Bus. Settings (53414). PK = "code".
//     local procedure MigrateVATBusSettingsOld2Table()
//     var
//         Legacy: Record "DXR_VAT Bus. Settings Old2";
//         New: Record "DXR_VAT Bus. Settings";
//     begin
//         if Legacy.FindSet() then
//             repeat
//                 if not New.Get(Legacy."code") then begin
//                     New.Init();
//                     New."code" := Legacy."code";
//                     New."VAT Bus. Posting GRoup" := Legacy."VAT Bus. Posting GRoup";
//                     New.Usar := Legacy.Usar;
//                     New."Tipo NCF Cliente" := Legacy."Tipo NCF Cliente";
//                     New.Insert(false);
//                 end;
//             until Legacy.Next() = 0;
//     end;

//     local procedure MigrateAllRenumberedDXRTables()
//     begin
//         MigrateLegacyTableData(59231, 53301); // DXR_Agente restored at true original ID
//         MigrateLegacyTableData(59232, 53302); // DXR_AGR Log restored at true original ID
//         MigrateAGRSetupOld2Table(); // DXR_AGR Setup Old2 (59233) -> DXR_AGR Setup (53303) - native
//         MigrateAjusteInventarioConfigOld2Table(); // DXR_Ajuste Inventario Con Old2 (59234) -> DXR_Ajuste Inventario Config (53304) - native
//         MigrateLegacyTableData(59235, 53305); // DXR_Archivo - Discrepancias restored at true original ID
//         MigrateAreaDeTrabajoOld2Table(); // DXR_Area de Trabajo Old2 (59236) -> DXR_Area de Trabajo (53306) - native
//         MigrateLegacyTableData(59237, 53307); // DXR_Bancos - Extracto Bancario restored at true original ID
//         MigrateLegacyTableData(59238, 53308); // DXR_Bank restored at true original ID
//         MigrateLegacyTableData(59239, 53309); // DXR_Bank Relation restored at true original ID
//         MigrateLegacyTableData(59240, 53310); // DXR_Black List Promotion restored at true original ID
//         MigrateLegacyTableData(59241, 53311); // DXR_Cabecera Discrepancia restored at true original ID
//         MigrateLegacyTableData(59242, 53312); // DXR_Carga Masiva Benef BPD restored at true original ID
//         MigrateCategoriaServiciosOld2Table(); // DXR_Categoria Servicios Old2 (59243) -> DXR_Categoria Servicios (53313) - native
//         MigrateLegacyTableData(59244, 53314); // DXR_Cilindros restored at true original ID
//         MigrateCilindrosSetupOld2Table(); // DXR_Cilindros - Setup Old2 (59245) -> DXR_Cilindros - Setup (53315) - native
//         MigrateLegacyTableData(59247, 53317); // DXR_Comentario - Discrepancias restored at true original ID (59246/Codigos de Auditoria has no Old2 counterpart - confirmed skip)
//         MigrateConfExtractoBancarioOld2Table(); // DXR_Conf. Extracto Bancar Old2 (59248) -> DXR_Conf. Extracto Bancario (53318) - native
//         MigrateConfigNCFVentasOld2Table(); // DXR_Config. NCF Ventas Old2 (59249) -> DXR_Config. NCF Ventas (53319) - native
//         MigrateConfigNCFVentasSTDOld2Table(); // DXR_Config. NCF Ventas ST Old2 (59250) -> DXR_Config. NCF Ventas STD (53320) - native
//         MigrateConfigPolizasOld2Table(); // DXR_Config. Polizas Old2 (59251) -> DXR_Config. Polizas (53321) - native
//         MigrateConfiguracionCBOld2Table(); // DXR_Configuracion CB Old2 (59252) -> DXR_Configuracion CB (53322) - native
//         MigrateConfiguracionDiscrepanciasOld2Table(); // DXR_Config - Discr Old2 (59253) -> DXR_Config - Discr (53323) - native
//         MigrateConfiguracionEncuestasPOSOld2Table(); // DXR_Config Encuestas - PO Old2 (59254) -> DXR_Config Encuestas - POS (53324) - native
//         MigrateConfiguracionesRequisicionOld2Table(); // DXR_Config Req Old2 (59255) -> DXR_Config Req (53325) - native
//         MigrateConfiguracionMedalliaOld2Table(); // DXR_Configuracion - MEDAL Old2 (59256) -> DXR_Configuracion - MEDALLIA (53326) - native
//         MigrateConfPagosEcommerceAzulOld2Table(); // DXR_Conf. Pagos Ecommerce Old2 (59257) -> DXR_Conf. Pagos Ecommerce Azul (53327) - native
//         MigrateControlProcesosPorAlmacenOld2Table(); // DXR_Control Proc por Alma Old2 (59258) -> DXR_Control Proc por Almacen (53328) - native
//         MigrateLegacyTableData(59259, 53329); // DXR_Conversion Costo restored at true original ID
//         MigrateLegacyTableData(59260, 53330); // DXR_Departamento - Discr restored at true original ID
//         MigrateLegacyTableData(59261, 53331); // DXR_Detalle - Extr Bancario restored at true original ID
//         MigrateDrawSetupOld2Table(); // DXR_Draw Setup Old2 (59262) -> DXR_Draw Setup (53332) - native
//         MigrateEmailSourceTemplateRelationOld2Table(); // DXR_Email Source Tmpl Rel Old2 (59263) -> DXR_Email Source Tmpl Rel (53333) - native
//         MigrateLegacyTableData(59264, 53334); // DXR_Entrega Fact CxC - Lines restored at true original ID
//         MigrateLegacyTableData(59265, 53335); // DXR_Envio Compras restored at true original ID
//         MigrateEPagosSetupOld2Table(); // DXR_EPagos Setup Old2 (59266) -> DXR_EPagos Setup (53336) - native
//         MigrateExcludeFilterJournalOld2Table(); // DXR_Exclude Filter Journal Old2 (59267) -> DXR_Exclude Filter Journal (53337) - native
//         MigrateExcluirTerminosItemSearchOld2Table(); // DXR_Excluir Term - ItemSearch Old2 (59268) -> DXR_Excluir Term - ItemSearch (53338) - native
//         MigrateFileStructureOld2Table(); // DXR_File Structure Old2 (59269) -> DXR_File Structure (53339) - native
//         MigrateFormaDePagoOld2Table(); // DXR_Forma de Pago Old2 (59270) -> DXR_Forma de Pago (53340) - native
//         MigrateLegacyTableData(59271, 53341); // DXR_HisCargaMasivaBenefBPD restored at true original ID
//         MigrateLegacyTableData(59272, 53342); // DXR_Grupo Venta restored at true original ID
//         MigrateLegacyTableData(59273, 53343); // DXR_HisLinCargaMasivaBenefBPD restored at true original ID
//         MigrateLegacyTableData(59274, 53344); // DXR_Hist. Beneficiarios BPD restored at true original ID
//         MigrateLegacyTableData(59275, 53345); // DXR_Hist. Cabecera Discr restored at true original ID
//         MigrateLegacyTableData(59276, 53346); // DXR_Hist. de Ganadores restored at true original ID
//         MigrateLegacyTableData(59277, 53347); // DXR_Hist. Int Consump. Header restored at true original ID
//         MigrateLegacyTableData(59278, 53348); // DXR_Hist. Int Consump. Line restored at true original ID
//         MigrateLegacyTableData(59279, 53349); // DXR_Hist. Linea Discrepancia restored at true original ID
//         MigrateLegacyTableData(59280, 53350); // DXR_Historico Enc Requisicion restored at true original ID
//         MigrateLegacyTableData(59281, 53351); // DXR_Historico - Extr Bancario restored at true original ID
//         MigrateLegacyTableData(59282, 53352); // DXR_Historico Requisicion Line restored at true original ID
//         MigrateLegacyTableData(59283, 53353); // DXR_Hist Pre-Requisicion restored at true original ID
//         MigrateLegacyTableData(59284, 53354); // DXR_Hist Pre-Requisicion Line restored at true original ID
//         MigrateLegacyTableData(59285, 53355); // DXR_Int Consump Header restored at true original ID
//         MigrateLegacyTableData(59286, 53356); // DXR_Internal Consumption Line restored at true original ID
//         MigrateLegacyTableData(59287, 53357); // DXR_Internal Consumption Log restored at true original ID
//         MigrateInventoryMasksOld2Table(); // DXR_Inventory Masks Old2 (59288) -> DXR_Inventory Masks (53358) - native
//         MigrateLegacyTableData(59289, 53359); // DXR_Item HTML restored at true original ID
//         MigrateLegacyTableData(59290, 53360); // DXR_Item Image View restored at true original ID
//         MigrateLegacyTableData(59291, 53361); // DXR_ItemNo Desliquidacion restored at true original ID
//         MigrateLegacyTableData(59292, 53362); // DXR_Journal Promotion Tickets restored at true original ID
//         MigrateLegacyTableData(59293, 53363); // DXR_Linea Discrepancia restored at true original ID
//         MigrateLegacyTableData(59294, 53364); // DXR_Lin Carga Masiva Ben. BPD restored at true original ID
//         MigrateLegacyTableData(59295, 53365); // DXR_LineRQBuffer restored at true original ID
//         MigrateLegacyTableData(59296, 53366); // DXR_Log - Bank Statement restored at true original ID
//         MigrateLegacyTableData(59297, 53367); // DXR_Log Email restored at true original ID
//         MigrateLegacyTableData(59298, 53368); // DXR_Log Transaccion Azul restored at true original ID
//         MigrateLegacyTableData(59299, 53369); // DXR_Log Transaccion Medallia restored at true original ID
//         MigrateLegacyTableData(59300, 53370); // DXR_Log Transfer error restored at true original ID
//         MigrateMarcasOld2Table(); // DXR_Marcas Old2 (59301) -> DXR_Marcas (53371) - native
//         MigrateMemberManagementSetupOld2Table(); // DXR_Member Management Setup Old2 (59302) -> DXR_Member Management Setup (53372) - native
//         MigrateMotivoCierreDiscrepanciasOld2Table(); // DXR_Motivo Cierre - Discr Old2 (59303) -> DXR_Motivo Cierre - Discr (53373) - native
//         MigrateMotivoDiscrepanciaOld2Table(); // DXR_Motivo Discrepancia Old2 (59304) -> DXR_Motivo Discrepancia (53374) - native
//         MigrateLegacyTableData(59305, 53375); // DXR_Movimientos de Cilindro restored at true original ID
//         MigrateLegacyTableData(59306, 53376); // DXR_Order Item Status restored at true original ID
//         MigrateLegacyTableData(59307, 53377); // DXR_Posted Jnl Promo Tickets restored at true original ID
//         MigrateLegacyTableData(59308, 53378); // DXR_Pre Req LineNoStockValid restored at true original ID
//         MigrateLegacyTableData(59309, 53379); // DXR_Pre Req no Stock Valid restored at true original ID
//         MigrateLegacyTableData(59310, 53380); // DXR_Pre-Requisicion restored at true original ID
//         MigrateLegacyTableData(59311, 53381); // DXR_Pre-Requisicion Line restored at true original ID
//         MigrateLegacyTableData(59312, 53382); // DXR_Pre-Req Line No Stock restored at true original ID
//         MigrateLegacyTableData(59313, 53383); // DXR_Pre-Requisicion no Stock restored at true original ID
//         MigrateLegacyTableData(59314, 53384); // DXR_Printing Invoice Log restored at true original ID
//         MigrateProfesionOld2Table(); // DXR_Profesion Old2 (59315) -> DXR_Profesion (53385) - native
//         MigratePromotionSetupOld2Table(); // DXR_Promotion Setup Old2 (59316) -> DXR_Promotion Setup (53386) - native
//         MigrateLegacyTableData(59317, 53387); // DXR_Promotion Tickets Relation restored at true original ID
//         MigrateProvinciaOld2Table(); // DXR_Provincia Old2 (59318) -> DXR_Provincia (53388) - native
//         MigrateLegacyTableData(59319, 53389); // DXR_Requisicion restored at true original ID
//         MigrateLegacyTableData(59320, 53390); // DXR_Requisicion Comment Line restored at true original ID
//         MigrateLegacyTableData(59321, 53391); // DXR_Requisicion Line restored at true original ID
//         MigrateSalesDeptOld2Table(); // DXR_Sales Dept Old2 (59322) -> DXR_Sales Dept (53392) - native
//         MigrateSalesGroupsOld2Table(); // DXR_Sales Groups Old2 (59323) -> DXR_Sales Groups (53393) - native
//         MigrateSalesSubGroupsOld2Table(); // DXR_Sales SubGroups Old2 (59324) -> DXR_Sales SubGroups (53394) - native
//         MigrateLegacyTableData(59325, 53395); // DXR_Send Email Log restored at true original ID
//         MigrateStdPOSDASCOMPaymtEqvOld2Table(); // DXR_Std POS DASCOM Paymt Old2 (59326) -> DXR_Std POS DASCOM Paymt Eqv (53396) - native
//         MigrateStandardPOSGenCommentsOld2Table(); // DXR_Standard POS Gen. Com Old2 (59327) -> DXR_Standard POS Gen. Comments (53397) - native
//         MigrateStandardPOSUsersOld2Table(); // DXR_Standard POS Users Old2 (59328) -> DXR_Standard POS Users (53398) - native
//         MigrateLegacyTableData(59329, 53399); // DXR_Store Statement Posting restored at true original ID
//         MigrateSummaryReconSetupOld2Table(); // DXR_Summary Recon Setup Old2 (59330) -> DXR_Summary Recon Setup (53400) - native
//         MigrateTasasBCOld2Table(); // DXR_Tasas BC Old2 (59331) -> DXR_Tasas BC (53401) - native
//         MigrateLegacyTableData(59332, 53402); // DXR_Tickets By Offer restored at true original ID
//         MigrateLegacyTableData(59333, 53403); // DXR_Tickets Entry restored at true original ID
//         MigrateTipoDeContenedorOld2Table(); // DXR_Tipo de Contenedor Old2 (59334) -> DXR_Tipo de Contenedor (53404) - native
//         MigrateTipoGasOld2Table(); // DXR_Tipo Gas Old2 (59335) -> DXR_Tipo Gas (53405) - native
//         MigrateTiposOAgentesOld2Table(); // DXR_Tipos o Agentes Old2 (59336) -> DXR_Tipos o Agentes (53406) - native
//         MigrateLegacyTableData(59337, 53407); // DXR_Trans. Archive Line restored at true original ID
//         MigrateTratadosArancelariosOld2Table(); // DXR_Tratados Arancelarios Old2 (59338) -> DXR_Tratados Arancelarios (53408) - native
//         MigrateUserApproverByBuyerGroupOld2Table(); // DXR_UserApproverByBuyerGr Old2 (59339) -> DXR_UserApproverByBuyerGroup (53409) - native
//         MigrateUserByBuyerGroupOld2Table(); // DXR_UserByBuyerGroup Old2 (59340) -> DXR_UserByBuyerGroup (53410) - native
//         MigrateLegacyTableData(59341, 53411); // DXR_UserLogs restored at true original ID
//         MigrateLegacyTableData(59342, 53412); // DXR_UserPromo Apps restored at true original ID
//         MigrateLegacyTableData(59343, 53413); // DXR_Valoracion de Inventario restored at true original ID
//         MigrateVATBusSettingsOld2Table(); // DXR_VAT Bus. Settings Old2 (59344) -> DXR_VAT Bus. Settings (53414) - native
//         MigrateLegacyTableData(59345, 53415); // DXR_Printing Invoice Log BO restored at true original ID
//     end;
// }
