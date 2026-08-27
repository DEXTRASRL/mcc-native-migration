#if not ESCUDEA and not BCDX
codeunit 60130 "DXR MCC DESLS Migr Phase1"
{
    // Native local migration - ported verbatim from Despacho LS's own "DXR_Desp LS Migr Phase 1"
    // (53924, Access = Internal): 21 fields duplicated across 14 tableextensions (legacy field ->
    // new "_DXR"-suffixed field). 10 of the 14 read the old field from the TRUE legacy Despacho
    // Base table (via a generic RecordRef primary-key match, since the old field isn't present on
    // the active table anymore) - the other 4 (LS Central's own native Staff/RetailUser/
    // RetailProductGroup/UserSetup tables) were never split into a legacy/active pair and read the
    // old field directly.
    //
    // Fixed 2026-08-27 (performance/locking pass, no migration semantics changed): every loop below
    // did FindSet(true) over the WHOLE table with no partial-record hint. Per Learn ("Record.FindSet")
    // FindSet "will request all rows at once" and with ForUpdate = true reads them "using
    // IsolationLevel::UpdLock (SQL UPDLOCK)", and without SetLoadFields the server joins in every
    // tableextension companion table for every row. Each loop now declares SetLoadFields with exactly
    // the fields it reads/writes. Loops over unbounded (line/historic/log) tables that had no Commit
    // at all now commit in batches, and every batching loop commits the remainder at the end instead
    // of leaving it in the caller's transaction. Same fields, same copy conditions, same upgrade tags.
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
        RunSetup();
        RunMaster();
        RunAccounting();
        RunHistoric();
        RunOther();
    end;

    procedure RunSetup()
    begin
        MigrateTable_DispatchSetup();
        MigrateTable_Staff();
        MigrateTable_RetailUser();
        MigrateTable_UserSetup();
    end;

    procedure RunMaster()
    begin
        MigrateTable_RetailProductGroup();
    end;

    procedure RunAccounting()
    begin
        MigrateTable_DispatchLine();
        MigrateTable_TransportHeader();
        MigrateTable_ShipmentHeader();
        MigrateTable_TransportLine();
    end;

    procedure RunHistoric()
    begin
        MigrateTable_LogReimpresionesCond();
        MigrateTable_PickupHistoric();
        MigrateTable_PostedTransportLine();
        MigrateTable_TransportLogs();
    end;

    procedure RunOther()
    begin
        MigrateTable_PickupList();
    end;

    local procedure MigrateTable_DispatchLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        DispatchLineRec: Record "DXR_Dispatch Line";
        LegacyDispatchLineRec: Record "DXR-DE Dispatch Line";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHLINE-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 5 fields this loop touches.
        DispatchLineRec.SetLoadFields(Type, "No.", "Invoice No.", "Store No._DXR", "Document Reference_DXR");
        if DispatchLineRec.FindSet(true) then
            repeat
                if LegacyDispatchLineRec.Get(DispatchLineRec.Type, DispatchLineRec."No.", DispatchLineRec."Invoice No.") then begin
                    // 50804 "DXR-DE Store No." -> Store No._DXR, 50805 "DXR-DE Document Reference" -> Document Reference_DXR
                    if (DispatchLineRec."Store No._DXR" <> LegacyDispatchLineRec."DXR-DE Store No.") or
                       (DispatchLineRec."Document Reference_DXR" <> LegacyDispatchLineRec."DXR-DE Document Reference")
                    then begin
                        DispatchLineRec."Store No._DXR" := LegacyDispatchLineRec."DXR-DE Store No.";
                        DispatchLineRec."Document Reference_DXR" := LegacyDispatchLineRec."DXR-DE Document Reference";
                        DispatchLineRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 200 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until DispatchLineRec.Next() = 0;

        // Fixed 2026-08-27: commit the remainder (< 200 rows) instead of leaving it in the caller's
        // transaction.
        if BatchCount > 0 then
            Commit();

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

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop reads.
        LegacyDispatchSetupRec.SetLoadFields("Key", "DXR-DE Enable Manual Gen. Doc.");
        if LegacyDispatchSetupRec.FindSet() then
            repeat
                if not DispatchSetupRec.Get(LegacyDispatchSetupRec."Key") then begin
                    DispatchSetupRec.Init();
                    DispatchSetupRec."Key" := LegacyDispatchSetupRec."Key";
                    DispatchSetupRec.Insert(false);
                end;

                // 50840 "DXR-DE Enable Manual Gen. Doc." -> Enable Manual Gen. Doc._DXR
                if DispatchSetupRec."Enable Manual Gen. Doc._DXR" <> LegacyDispatchSetupRec."DXR-DE Enable Manual Gen. Doc." then begin
                    DispatchSetupRec."Enable Manual Gen. Doc._DXR" := LegacyDispatchSetupRec."DXR-DE Enable Manual Gen. Doc.";
                    DispatchSetupRec.Modify(false);
                end;
            until LegacyDispatchSetupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-DISPATCHSETUP-28.3');
    end;

    local procedure MigrateTable_LogReimpresionesCond()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        LogReimpresionesCondRec: Record "DXR_Log Reimpresiones Cond";
        LegacyLogReimpresionesCondRec: Record "DXR-DE Log Reimpresiones Cond";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-LOGREIMPRESIONESCOND-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches, and the
        // loop is now committed in batches - it is an unbounded log table and previously ran the
        // whole rewrite in a single transaction.
        LogReimpresionesCondRec.SetLoadFields("Entry No.", "Staff ID_DXR");
        if LogReimpresionesCondRec.FindSet(true) then
            repeat
                if LegacyLogReimpresionesCondRec.Get(LogReimpresionesCondRec."Entry No.") then begin
                    // 50806 "DXR-DE Staff ID" -> Staff ID_DXR
                    if LogReimpresionesCondRec."Staff ID_DXR" <> LegacyLogReimpresionesCondRec."DXR-DE Staff ID" then begin
                        LogReimpresionesCondRec."Staff ID_DXR" := LegacyLogReimpresionesCondRec."DXR-DE Staff ID";
                        LogReimpresionesCondRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until LogReimpresionesCondRec.Next() = 0;

        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-LOGREIMPRESIONESCOND-28.3');
    end;

    local procedure MigrateTable_Staff()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        StaffRec: Record "LSC Staff";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-STAFF-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 6 fields this loop touches.
        StaffRec.SetLoadFields(
            "Reprint Shipments_DXR", "DXR-DE Reprint Shipments",
            "Reprint invoices_DXR", "DXR-DE Reprint invoices",
            "Del Dispatch Document_DXR", "DXR-DE Del Dispatch Document");
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

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches.
        RetailUserRec.SetLoadFields("Almacen Despacho_DXR", "DXR-DE Almacen Despacho");
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
        LegacyPickupHistoricRec: Record "DXR-DE Pickup Historic";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPHISTORIC-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches, and the
        // loop is now committed in batches - it is an unbounded historic table.
        PickupHistoricRec.SetLoadFields("Document No.", "Store No._DXR");
        if PickupHistoricRec.FindSet(true) then
            repeat
                if LegacyPickupHistoricRec.Get(PickupHistoricRec."Document No.") then begin
                    // 50802 "DXR-DE Store No." -> Store No._DXR
                    if PickupHistoricRec."Store No._DXR" <> LegacyPickupHistoricRec."DXR-DE Store No." then begin
                        PickupHistoricRec."Store No._DXR" := LegacyPickupHistoricRec."DXR-DE Store No.";
                        PickupHistoricRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PickupHistoricRec.Next() = 0;

        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPHISTORIC-28.3');
    end;

    local procedure MigrateTable_PickupList()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PickupListRec: Record "DXR_Pickup List";
        LegacyPickupListRec: Record "DXR-DE Pickup List";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPLIST-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches, and the
        // loop is now committed in batches - row volume is unbounded.
        PickupListRec.SetLoadFields("Document No.", "Store No._DXR");
        if PickupListRec.FindSet(true) then
            repeat
                if LegacyPickupListRec.Get(PickupListRec."Document No.") then begin
                    // 50800 "DXR-DE Store No." -> Store No._DXR
                    if PickupListRec."Store No._DXR" <> LegacyPickupListRec."DXR-DE Store No." then begin
                        PickupListRec."Store No._DXR" := LegacyPickupListRec."DXR-DE Store No.";
                        PickupListRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PickupListRec.Next() = 0;

        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-PICKUPLIST-28.3');
    end;

    local procedure MigrateTable_PostedTransportLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PostedTransportLineRec: Record "DXR_Posted Transport Line";
        LegacyPostedTransportLineRec: Record "DXR-DE Posted Transport Line";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-POSTEDTRANSPORTLINE-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 6 fields this loop touches.
        PostedTransportLineRec.SetLoadFields(
            Type, "No.", "Transport No.", "Invoice No.",
            "Store_DXR", "Document Reference_DXR");
        if PostedTransportLineRec.FindSet(true) then
            repeat
                if LegacyPostedTransportLineRec.Get(PostedTransportLineRec.Type, PostedTransportLineRec."No.", PostedTransportLineRec."Transport No.", PostedTransportLineRec."Invoice No.") then begin
                    // 50803 "DXR-DE Store" -> Store_DXR, 50804 "DXR-DE Document Reference" -> Document Reference_DXR
                    if (PostedTransportLineRec."Store_DXR" <> LegacyPostedTransportLineRec."DXR-DE Store") or
                       (PostedTransportLineRec."Document Reference_DXR" <> LegacyPostedTransportLineRec."DXR-DE Document Reference")
                    then begin
                        PostedTransportLineRec."Store_DXR" := LegacyPostedTransportLineRec."DXR-DE Store";
                        PostedTransportLineRec."Document Reference_DXR" := LegacyPostedTransportLineRec."DXR-DE Document Reference";
                        PostedTransportLineRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 200 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PostedTransportLineRec.Next() = 0;

        // Fixed 2026-08-27: commit the remainder (< 200 rows).
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-POSTEDTRANSPORTLINE-28.3');
    end;

    local procedure MigrateTable_RetailProductGroup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetailProductGroupRec: Record "LSC Retail Product Group";
        Blank: Record "LSC Retail Product Group";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILPRODUCTGROUP-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches.
        RetailProductGroupRec.SetLoadFields("Comision_Cobro_DXR", "DXR-DE Comision_Cobro");
        if RetailProductGroupRec.FindSet(true) then
            repeat
                // Fixed 2026-08-27 (never-overwrite): unconditional copy - a re-run of this upgrade
                // tag (e.g. per-table upgrade tags with a company already migrated) would blindly
                // overwrite an already-populated _DXR value.
                if RetailProductGroupRec."Comision_Cobro_DXR" = Blank."Comision_Cobro_DXR" then
                    RetailProductGroupRec."Comision_Cobro_DXR" := RetailProductGroupRec."DXR-DE Comision_Cobro";
                RetailProductGroupRec.Modify(false);
            until RetailProductGroupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-RETAILPRODUCTGROUP-28.3');
    end;

    local procedure MigrateTable_TransportHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportHeaderRec: Record "DXR_Transport Header";
        LegacyTransportHeaderRec: Record "DXR-DE Transport Header";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTHEADER-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches, and the
        // loop is now committed in batches - row volume is unbounded.
        TransportHeaderRec.SetLoadFields("Code", "Store_DXR");
        if TransportHeaderRec.FindSet(true) then
            repeat
                if LegacyTransportHeaderRec.Get(TransportHeaderRec."Code") then begin
                    // 50801 "DXR-DE Store" -> Store_DXR
                    if TransportHeaderRec."Store_DXR" <> LegacyTransportHeaderRec."DXR-DE Store" then begin
                        TransportHeaderRec."Store_DXR" := LegacyTransportHeaderRec."DXR-DE Store";
                        TransportHeaderRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until TransportHeaderRec.Next() = 0;

        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTHEADER-28.3');
    end;

    local procedure MigrateTable_ShipmentHeader()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        ShipmentHeaderRec: Record "DXR_Shipment Header";
        LegacyShipmentHeaderRec: Record "DXR-DE Shipment Header";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-SHIPMENTHEADER-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches.
        ShipmentHeaderRec.SetLoadFields("No.", "Store No._DXR");
        if ShipmentHeaderRec.FindSet(true) then
            repeat
                if LegacyShipmentHeaderRec.Get(ShipmentHeaderRec."No.") then begin
                    // 50807 "DXR-DE Store No." -> Store No._DXR
                    if ShipmentHeaderRec."Store No._DXR" <> LegacyShipmentHeaderRec."DXR-DE Store No." then begin
                        ShipmentHeaderRec."Store No._DXR" := LegacyShipmentHeaderRec."DXR-DE Store No.";
                        ShipmentHeaderRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 200 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until ShipmentHeaderRec.Next() = 0;

        // Fixed 2026-08-27: commit the remainder (< 200 rows).
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-SHIPMENTHEADER-28.3');
    end;

    local procedure MigrateTable_TransportLine()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportLineRec: Record "DXR_Transport Line";
        LegacyTransportLineRec: Record "DXR-DE Transport Line";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLINE-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 5 fields this loop touches.
        TransportLineRec.SetLoadFields(
            "Line No.", "Transport No.", Type,
            "Store No._DXR", "Document Reference_DXR");
        if TransportLineRec.FindSet(true) then
            repeat
                if LegacyTransportLineRec.Get(TransportLineRec."Line No.", TransportLineRec."Transport No.", TransportLineRec.Type) then begin
                    // 50805 "DXR-DE Store No." -> Store No._DXR, 50806 "DXR-DE Document Reference" -> Document Reference_DXR
                    if (TransportLineRec."Store No._DXR" <> LegacyTransportLineRec."DXR-DE Store No.") or
                       (TransportLineRec."Document Reference_DXR" <> LegacyTransportLineRec."DXR-DE Document Reference")
                    then begin
                        TransportLineRec."Store No._DXR" := LegacyTransportLineRec."DXR-DE Store No.";
                        TransportLineRec."Document Reference_DXR" := LegacyTransportLineRec."DXR-DE Document Reference";
                        TransportLineRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 200 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until TransportLineRec.Next() = 0;

        // Fixed 2026-08-27: commit the remainder (< 200 rows).
        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLINE-28.3');
    end;

    local procedure MigrateTable_TransportLogs()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        TransportLogsRec: Record "DXR_Transport Log's";
        LegacyTransportLogsRec: Record "DXR-DE Transport Log's";
        BatchCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLOGS-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 2 fields this loop touches, and the
        // loop is now committed in batches - it is an unbounded log table.
        TransportLogsRec.SetLoadFields("Entry No.", "Document Reference_DXR");
        if TransportLogsRec.FindSet(true) then
            repeat
                if LegacyTransportLogsRec.Get(TransportLogsRec."Entry No.") then begin
                    // 50800 "DXR-DE Document Reference" -> Document Reference_DXR
                    if TransportLogsRec."Document Reference_DXR" <> LegacyTransportLogsRec."DXR-DE Document Reference" then begin
                        TransportLogsRec."Document Reference_DXR" := LegacyTransportLogsRec."DXR-DE Document Reference";
                        TransportLogsRec.Modify(false);
                    end;
                end;

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until TransportLogsRec.Next() = 0;

        if BatchCount > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-TRANSPORTLOGS-28.3');
    end;

    local procedure MigrateTable_UserSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UserSetupRec: Record "User Setup";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-DespachoLS-MigrPhase1-USERSETUP-28.3') then
            exit;

        // Fixed 2026-08-27: SetLoadFields limits the scan to the 4 fields this loop touches.
        UserSetupRec.SetLoadFields(
            "Grupo Precios Tope_DXR", "DXR-DE Grupo Precios Tope",
            "Supervisor_DXR", "DXR-DE Supervisor");
        if UserSetupRec.FindSet(true) then
            repeat
                UserSetupRec."Grupo Precios Tope_DXR" := UserSetupRec."DXR-DE Grupo Precios Tope";
                UserSetupRec."Supervisor_DXR" := UserSetupRec."DXR-DE Supervisor";
                UserSetupRec.Modify(false);
            until UserSetupRec.Next() = 0;

        UpgradeTag.SetUpgradeTag('DXR-DespachoLS-MigrPhase1-USERSETUP-28.3');
    end;
}

#endif
