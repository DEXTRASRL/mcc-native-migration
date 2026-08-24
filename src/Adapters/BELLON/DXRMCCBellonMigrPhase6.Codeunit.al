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

    local procedure MigrateAllRenumberedDXRTables()
    begin
        MigrateLegacyTableData(59231, 53301); // DXR_Agente restored at true original ID
        MigrateLegacyTableData(59232, 53302); // DXR_AGR Log restored at true original ID
        MigrateLegacyTableData(59233, 53303); // DXR_AGR Setup restored at true original ID
        MigrateLegacyTableData(59234, 53304); // DXR_Ajuste Inventario Config restored at true original ID
        MigrateLegacyTableData(59235, 53305); // DXR_Archivo - Discrepancias restored at true original ID
        MigrateLegacyTableData(59236, 53306); // DXR_Area de Trabajo restored at true original ID
        MigrateLegacyTableData(59237, 53307); // DXR_Bancos - Extracto Bancario restored at true original ID
        MigrateLegacyTableData(59238, 53308); // DXR_Bank restored at true original ID
        MigrateLegacyTableData(59239, 53309); // DXR_Bank Relation restored at true original ID
        MigrateLegacyTableData(59240, 53310); // DXR_Black List Promotion restored at true original ID
        MigrateLegacyTableData(59241, 53311); // DXR_Cabecera Discrepancia restored at true original ID
        MigrateLegacyTableData(59242, 53312); // DXR_Carga Masiva Benef BPD restored at true original ID
        MigrateLegacyTableData(59243, 53313); // DXR_Categoria Servicios restored at true original ID
        MigrateLegacyTableData(59244, 53314); // DXR_Cilindros restored at true original ID
        MigrateLegacyTableData(59245, 53315); // DXR_Cilindros - Setup restored at true original ID
        MigrateLegacyTableData(59247, 53317); // DXR_Comentario - Discrepancias restored at true original ID (59246/Codigos de Auditoria has no Old2 counterpart - confirmed skip)
        MigrateLegacyTableData(59248, 53318); // DXR_Conf. Extracto Bancario restored at true original ID
        MigrateLegacyTableData(59249, 53319); // DXR_Config. NCF Ventas restored at true original ID
        MigrateLegacyTableData(59250, 53320); // DXR_Config. NCF Ventas STD restored at true original ID
        MigrateLegacyTableData(59251, 53321); // DXR_Config. Polizas restored at true original ID
        MigrateLegacyTableData(59252, 53322); // DXR_Configuracion CB restored at true original ID
        MigrateLegacyTableData(59253, 53323); // DXR_Config - Discr restored at true original ID
        MigrateLegacyTableData(59254, 53324); // DXR_Config Encuestas - POS restored at true original ID
        MigrateLegacyTableData(59255, 53325); // DXR_Config Req restored at true original ID
        MigrateLegacyTableData(59256, 53326); // DXR_Configuracion - MEDALLIA restored at true original ID
        MigrateLegacyTableData(59257, 53327); // DXR_Conf. Pagos Ecommerce Azul restored at true original ID
        MigrateLegacyTableData(59258, 53328); // DXR_Control Proc por Almacen restored at true original ID
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
