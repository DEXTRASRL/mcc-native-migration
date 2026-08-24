codeunit 60130 "DXR MCC DESLS Migr Phase1"
{
    // Native local migration - ported verbatim from Despacho LS's own "DXR_Desp LS Migr Phase 1"
    // (53924, Access = Internal): 21 fields duplicated across 14 tableextensions (legacy field ->
    // new "_DXR"-suffixed field). 10 of the 14 read the old field from the TRUE legacy Despacho
    // Base table (via a generic RecordRef primary-key match, since the old field isn't present on
    // the active table anymore) - the other 4 (LS Central's own native Staff/RetailUser/
    // RetailProductGroup/UserSetup tables) were never split into a legacy/active pair and read the
    // old field directly.
    Permissions =
        tabledata "DXR-DE Dispatch Line" = R,
        tabledata "DXR_Dispatch Line" = RIMD,
        tabledata "DXR-DE Dispatch Setup" = R,
        tabledata "DXR_Dispatch Setup" = RIMD,
        tabledata "DXR-DE Log Reimpresiones Cond" = R,
        tabledata "DXR_Log Reimpresiones Cond" = RIMD,
        tabledata "DXR-DE Pickup Historic" = R,
        tabledata "DXR_Pickup Historic" = RIMD,
        tabledata "DXR-DE Pickup List" = R,
        tabledata "DXR_Pickup List" = RIMD,
        tabledata "DXR-DE Posted Transport Line" = R,
        tabledata "DXR_Posted Transport Line" = RIMD,
        tabledata "DXR-DE Transport Header" = R,
        tabledata "DXR_Transport Header" = RIMD,
        tabledata "DXR-DE Shipment Header" = R,
        tabledata "DXR_Shipment Header" = RIMD,
        tabledata "DXR-DE Transport Line" = R,
        tabledata "DXR_Transport Line" = RIMD,
        tabledata "DXR-DE Transport Log's" = R,
        tabledata "DXR_Transport Log's" = RIMD,
        tabledata "LSC Staff" = RM,
        tabledata "LSC Retail User" = RM,
        tabledata "LSC Retail Product Group" = RM,
        tabledata "User Setup" = RM;

    trigger OnRun()
    begin
        MigrateTable_DispatchLine();
        MigrateTable_DispatchSetup();
        MigrateTable_LogReimpresionesCond();
        MigrateTable_Staff();
        MigrateTable_RetailUser();
        MigrateTable_PickupHistoric();
        MigrateTable_PickupList();
        MigrateTable_PostedTransportLine();
        MigrateTable_RetailProductGroup();
        MigrateTable_TransportHeader();
        MigrateTable_ShipmentHeader();
        MigrateTable_TransportLine();
        MigrateTable_TransportLogs();
        MigrateTable_UserSetup();
    end;

    // For each row of the true legacy table (LegacyTableId), finds the matching row on the active
    // table (NewRecRef's table, already positioned on a row via FindSet/Next) by copying the
    // active row's own primary key field values onto a legacy RecordRef and calling Get() -
    // primary key fields are native, low-numbered fields unaffected by the DXR_/_DXR field
    // normalization, so this works regardless of each table's specific business key layout.
    // Returns true (with LegacyRecRef positioned on the match) only if found.
    local procedure FindMatchingLegacyRow(LegacyTableId: Integer; var NewRecRef: RecordRef; var LegacyRecRef: RecordRef): Boolean
    var
        NewKeyRef: KeyRef;
        NewFieldRef: FieldRef;
        LegacyFieldRef: FieldRef;
        FieldNo: Integer;
        i: Integer;
    begin
        LegacyRecRef.Open(LegacyTableId);
        NewKeyRef := NewRecRef.KeyIndex(1);
        for i := 1 to NewKeyRef.FieldCount() do begin
            NewFieldRef := NewKeyRef.FieldIndex(i);
            FieldNo := NewFieldRef.Number();
            if not LegacyRecRef.FieldExist(FieldNo) then
                exit(false);
            LegacyFieldRef := LegacyRecRef.Field(FieldNo);
            LegacyFieldRef.Value := NewFieldRef.Value();
        end;
        exit(LegacyRecRef.Find());
    end;

    local procedure MigrateTable_DispatchLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        DispatchLineRec: Record "DXR_Dispatch Line";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        StoreNoFld, DocRefFld : FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHLINE-28.3') then
            exit;

        if DispatchLineRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(DispatchLineRec);
                if FindMatchingLegacyRow(50808, NewRecRef, LegacyRecRef) then begin
                    // 50804 "DXR-DE Store No." -> Store No._DXR, 50805 "DXR-DE Document Reference" -> Document Reference_DXR
                    StoreNoFld := LegacyRecRef.Field(50804);
                    DocRefFld := LegacyRecRef.Field(50805);
                    DispatchLineRec."Store No._DXR" := StoreNoFld.Value();
                    DispatchLineRec."Document Reference_DXR" := DocRefFld.Value();
                    DispatchLineRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until DispatchLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHLINE-28.3');
    end;

    local procedure MigrateTable_DispatchSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        DispatchSetupRec: Record "DXR_Dispatch Setup";
        LegacyDispatchSetupRec: Record "DXR-DE Dispatch Setup";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHSETUP-28.3') then
            exit;

        if DispatchSetupRec.FindSet(true) then
            repeat
                if LegacyDispatchSetupRec.Get(DispatchSetupRec."Key") then begin
                    // 50840 "DXR-DE Enable Manual Gen. Doc." -> Enable Manual Gen. Doc._DXR
                    if DispatchSetupRec."Enable Manual Gen. Doc._DXR" <> LegacyDispatchSetupRec."DXR-DE Enable Manual Gen. Doc." then begin
                        DispatchSetupRec."Enable Manual Gen. Doc._DXR" := LegacyDispatchSetupRec."DXR-DE Enable Manual Gen. Doc.";
                        DispatchSetupRec.Modify(false);
                    end;
                end;
            until DispatchSetupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHSETUP-28.3');
    end;

    local procedure MigrateTable_LogReimpresionesCond()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LogReimpresionesCondRec: Record "DXR_Log Reimpresiones Cond";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-LOGREIMPRESIONESCOND-28.3') then
            exit;

        if LogReimpresionesCondRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(LogReimpresionesCondRec);
                if FindMatchingLegacyRow(50830, NewRecRef, LegacyRecRef) then begin
                    // 50806 "DXR-DE Staff ID" -> Staff ID_DXR
                    Fld := LegacyRecRef.Field(50806);
                    LogReimpresionesCondRec."Staff ID_DXR" := Fld.Value();
                    LogReimpresionesCondRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until LogReimpresionesCondRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-LOGREIMPRESIONESCOND-28.3');
    end;

    local procedure MigrateTable_Staff()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        StaffRec: Record "LSC Staff";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-STAFF-28.3') then
            exit;

        if StaffRec.FindSet(true) then
            repeat
                StaffRec."Reprint Shipments_DXR" := StaffRec."DXR-DE Reprint Shipments";
                StaffRec."Reprint invoices_DXR" := StaffRec."DXR-DE Reprint invoices";
                StaffRec."Del Dispatch Document_DXR" := StaffRec."DXR-DE Del Dispatch Document";
                StaffRec.Modify(false);
            until StaffRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-STAFF-28.3');
    end;

    local procedure MigrateTable_RetailUser()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetailUserRec: Record "LSC Retail User";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILUSER-28.3') then
            exit;

        if RetailUserRec.FindSet(true) then
            repeat
                RetailUserRec."Almacen Despacho_DXR" := RetailUserRec."DXR-DE Almacen Despacho";
                RetailUserRec.Modify(false);
            until RetailUserRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILUSER-28.3');
    end;

    local procedure MigrateTable_PickupHistoric()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PickupHistoricRec: Record "DXR_Pickup Historic";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPHISTORIC-28.3') then
            exit;

        if PickupHistoricRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(PickupHistoricRec);
                if FindMatchingLegacyRow(50833, NewRecRef, LegacyRecRef) then begin
                    // 50802 "DXR-DE Store No." -> Store No._DXR
                    Fld := LegacyRecRef.Field(50802);
                    PickupHistoricRec."Store No._DXR" := Fld.Value();
                    PickupHistoricRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until PickupHistoricRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPHISTORIC-28.3');
    end;

    local procedure MigrateTable_PickupList()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PickupListRec: Record "DXR_Pickup List";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPLIST-28.3') then
            exit;

        if PickupListRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(PickupListRec);
                if FindMatchingLegacyRow(50834, NewRecRef, LegacyRecRef) then begin
                    // 50800 "DXR-DE Store No." -> Store No._DXR
                    Fld := LegacyRecRef.Field(50800);
                    PickupListRec."Store No._DXR" := Fld.Value();
                    PickupListRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until PickupListRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPLIST-28.3');
    end;

    local procedure MigrateTable_PostedTransportLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostedTransportLineRec: Record "DXR_Posted Transport Line";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        StoreFld, DocRefFld : FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-POSTEDTRANSPORTLINE-28.3') then
            exit;

        if PostedTransportLineRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(PostedTransportLineRec);
                if FindMatchingLegacyRow(50816, NewRecRef, LegacyRecRef) then begin
                    // 50803 "DXR-DE Store" -> Store_DXR, 50804 "DXR-DE Document Reference" -> Document Reference_DXR
                    StoreFld := LegacyRecRef.Field(50803);
                    DocRefFld := LegacyRecRef.Field(50804);
                    PostedTransportLineRec."Store_DXR" := StoreFld.Value();
                    PostedTransportLineRec."Document Reference_DXR" := DocRefFld.Value();
                    PostedTransportLineRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until PostedTransportLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-POSTEDTRANSPORTLINE-28.3');
    end;

    local procedure MigrateTable_RetailProductGroup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetailProductGroupRec: Record "LSC Retail Product Group";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILPRODUCTGROUP-28.3') then
            exit;

        if RetailProductGroupRec.FindSet(true) then
            repeat
                RetailProductGroupRec."Comision_Cobro_DXR" := RetailProductGroupRec."DXR-DE Comision_Cobro";
                RetailProductGroupRec.Modify(false);
            until RetailProductGroupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILPRODUCTGROUP-28.3');
    end;

    local procedure MigrateTable_TransportHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportHeaderRec: Record "DXR_Transport Header";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTHEADER-28.3') then
            exit;

        if TransportHeaderRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(TransportHeaderRec);
                if FindMatchingLegacyRow(50801, NewRecRef, LegacyRecRef) then begin
                    // 50801 "DXR-DE Store" -> Store_DXR
                    Fld := LegacyRecRef.Field(50801);
                    TransportHeaderRec."Store_DXR" := Fld.Value();
                    TransportHeaderRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until TransportHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTHEADER-28.3');
    end;

    local procedure MigrateTable_ShipmentHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ShipmentHeaderRec: Record "DXR_Shipment Header";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-SHIPMENTHEADER-28.3') then
            exit;

        if ShipmentHeaderRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(ShipmentHeaderRec);
                if FindMatchingLegacyRow(50813, NewRecRef, LegacyRecRef) then begin
                    // 50807 "DXR-DE Store No." -> Store No._DXR
                    Fld := LegacyRecRef.Field(50807);
                    ShipmentHeaderRec."Store No._DXR" := Fld.Value();
                    ShipmentHeaderRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until ShipmentHeaderRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-SHIPMENTHEADER-28.3');
    end;

    local procedure MigrateTable_TransportLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportLineRec: Record "DXR_Transport Line";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        StoreNoFld, DocRefFld : FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLINE-28.3') then
            exit;

        if TransportLineRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(TransportLineRec);
                if FindMatchingLegacyRow(50806, NewRecRef, LegacyRecRef) then begin
                    // 50805 "DXR-DE Store No." -> Store No._DXR, 50806 "DXR-DE Document Reference" -> Document Reference_DXR
                    StoreNoFld := LegacyRecRef.Field(50805);
                    DocRefFld := LegacyRecRef.Field(50806);
                    TransportLineRec."Store No._DXR" := StoreNoFld.Value();
                    TransportLineRec."Document Reference_DXR" := DocRefFld.Value();
                    TransportLineRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until TransportLineRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLINE-28.3');
    end;

    local procedure MigrateTable_TransportLogs()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportLogsRec: Record "DXR_Transport Log's";
        NewRecRef: RecordRef;
        LegacyRecRef: RecordRef;
        Fld: FieldRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLOGS-28.3') then
            exit;

        if TransportLogsRec.FindSet(true) then
            repeat
                NewRecRef.GetTable(TransportLogsRec);
                if FindMatchingLegacyRow(50812, NewRecRef, LegacyRecRef) then begin
                    // 50800 "DXR-DE Document Reference" -> Document Reference_DXR
                    Fld := LegacyRecRef.Field(50800);
                    TransportLogsRec."Document Reference_DXR" := Fld.Value();
                    TransportLogsRec.Modify(false);
                end;
                LegacyRecRef.Close();
            until TransportLogsRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLOGS-28.3');
    end;

    local procedure MigrateTable_UserSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetupRec: Record "User Setup";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-USERSETUP-28.3') then
            exit;

        if UserSetupRec.FindSet(true) then
            repeat
                UserSetupRec."Grupo Precios Tope_DXR" := UserSetupRec."DXR-DE Grupo Precios Tope";
                UserSetupRec."Supervisor_DXR" := UserSetupRec."DXR-DE Supervisor";
                UserSetupRec.Modify(false);
            until UserSetupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-USERSETUP-28.3');
    end;
}
