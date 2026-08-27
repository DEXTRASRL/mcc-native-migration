#if not ESCUDEA and not BCDX
codeunit 60158 "DXR MCC Bellon Migr Phase14"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 14 XCollFix" (56131), fully self-contained. UNTRACKED BY MCC'S REGISTRY - same
    // situation as Phase 13 (see that codeunit's header comment for the full reasoning): no
    // BELLON-Pn concept row references this phase, and none of the 11 old MCC delegation adapters
    // ever called it. A genuine, real gap in this MCC extension's coverage, predating this pivot.
    //
    // Real content: a full field-by-field TRANSFERFIELDS type audit (triggered by a real
    // production crash on Customer Card -> CustCont-Update) found 52 fields on native BC tables
    // (Contact, Transfer Header, Sales Header, Purchase Line - Bellon numbers custom fields on
    // native tables independently per table, without coordinating against sibling tables BC syncs
    // via RecordRef.TRANSFERFIELDS) reusing the same physical field ID across tables with
    // different types. All 52 were relocated to a fresh 58000-58121 band; of those, 18 were
    // confirmed still live on deploy with real stored data - this phase bridges those 18 before
    // the originals are marked ObsoleteState = Removed. The remaining 34 (confirmed absent from
    // deploy) were marked Removed directly with no bridge needed.
    Permissions =
        tabledata Contact = RM,
        tabledata "Transfer Header" = RM,
        tabledata "Sales Header" = RM,
        tabledata "Purchase Line" = RM;

    trigger OnRun()
    begin
        RunMaster();
        RunAccounting();
    end;

    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BellonP14MasterNameFallbackCompleted-20260826') then
            exit;

        MigrateContactCollisionBridge();

        UpgradeTag.SetUpgradeTag('DXR-BellonP14MasterNameFallbackCompleted-20260826');
    end;

    procedure RunAccounting()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BellonP14XCollFixAccountingCompleted') then
            exit;

        MigrateTransferHeaderCollisionBridge();
        MigrateSalesHeaderCollisionBridge();
        MigratePurchaseLineCollisionBridge();

        UpgradeTag.SetUpgradeTag('DXR-BellonP14XCollFixAccountingCompleted');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        // Field numbers remain in the published schema to keep BC's RecordRef mechanisms (Field(),
        // FieldExist()) compatible, but migration lookup itself is entirely name based - same
        // resolver as Phase3/Phase7 (DXR MCC Master Field Resolver) and this codeunit's own
        // MigrateContactCollisionBridge() below, skip-if-target-already-populated. Names recovered
        // from each table's own tableextension source (src/Extentions/tables/*.TableExt.al in the
        // Bellon Customization app).
        if MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldName) then
            RecordChanged := true;
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

    // Bridges the 13 physical Contact fields confirmed live on deploy (50060-50078 range) to
    // their fresh 58000+ ID before "Next Order Selection" (50064, the exact field from the
    // reported crash) and its 12 siblings are marked ObsoleteState = Removed. FlowFields/
    // FlowFilters in the same collision set are excluded - no physical column to bridge.
    local procedure MigrateContactCollisionBridge()
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        RecRef: RecordRef;
        Modified: Boolean;
    begin
        RecRef.Open(Database::Contact);
        if RecRef.FindSet(true) then
            repeat
                Modified := false;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Selection_DXR.', 'Next Order Selection|Next Order Selection_Old|Next Order Selection_Old_DXR|Next Order Selection_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Restaurant_DXR.', 'Next Order Restaurant|Next Order Restaurant_Old|Next Order Rest_Old_DXR|Next Order Restaurant_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Date_DXR.', 'Next Order Date|Next Order Date_Old|Next Order Date_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Order Time_DXR.', 'Next Order Time|Next Order Time_Old|Next Order Time_Old_DXR|Next Order Time_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Delivery Tender_DXR.', 'Next Delivery Tender|Next Delivery Tender_Old|Next Delivery Tender_Old_DXR|Next Delivery Tender_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Recall Order_DXR.', 'Recall Order|Recall Order_Old|Recall Order_Old_DXR|Recall Order_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Ord Rest Temp_DXR.', 'Next Order Rest. Temporary|Next Ord Rest Temp_Old|Next Ord Rest Temp_Old_DXR|Next Ord Rest Temp_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Date Created_DXR.', 'Date Created|Date Created_Old|Date Created_Old_DXR|Date Created_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Pre-Order Print DT_DXR', 'Pre-Order Print DateTime|Pre-Ord Print DateTime_Old|Pre-Ord Print DT_Old_DXR|Pre-Ord Print DateTime_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Next Est Prod Time_DXR.', 'Next Estimated Prod. Time|Next Est Prod Time_Old|Next Est Prod Time_Old_DXR|Next Est Prod Time_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'External No._DXR.', 'External No.|External No._Old|External No._Old_DXR|External No._DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Last Date/Time Modified_DXR.', 'Last Date/Time Modified|Last Date/Time Modified_Old|Last Date/Time Mod_Old_DXR|Last Date/Time Modified_DXR') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Cust Template Code_DXR', 'Customer Template Code|Customer Template Code_Old|Cust Template Code_Old_DXR|Customer Template Code_DXR') or Modified;
                RecordChanged := Modified;
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    // Bridges the 3 physical Transfer Header fields confirmed live on deploy (50008-50010,
    // colliding against Transfer Shipment Header/Transfer Receipt Header via
    // CopyFromTransferHeader) to their fresh 58100+ ID.
    local procedure MigrateTransferHeaderCollisionBridge()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Original Trans. Date_DXRV2', 'Original Trans. Date');
                CopyFieldIfExists(RecRef, 'Tipo Request_DXR2.', 'Tipo Request');
                CopyFieldIfExists(RecRef, 'Transfer Status_DXR2.', 'Transfer Status');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    // Bridges the 1 physical Sales Header field confirmed live on deploy (50019
    // "PriceReleaseControlFlag", colliding against Sales Cr.Memo Header) to its fresh 58110 ID.
    local procedure MigrateSalesHeaderCollisionBridge()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Sales Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'PriceReleaseControlFlag_DXR.', 'PriceReleaseControlFlag');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    // Bridges the 1 physical Purchase Line field confirmed live on deploy (50018 "Transito",
    // colliding against Purch. Inv. Line) to its fresh 58121 ID.
    local procedure MigratePurchaseLineCollisionBridge()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Purchase Line");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Transito_DXR.', 'Transito');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
