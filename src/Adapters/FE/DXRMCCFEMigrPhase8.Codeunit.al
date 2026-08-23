codeunit 60137 "DXR MCC FE Migr Phase8"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 8 Master".OnRun() (Access = Internal). Field-to-field copies on 5 master
    // tables (Currency, Item [batched], Post Code, Unit of Measure, VAT Posting Setup) - all
    // public/standard BC tables. The sibling's own StatusMgt/checkpoint-resume bookkeeping is not
    // ported (MCC's own registry tracks progress); Item is still processed in Commit-batches of
    // 100 to avoid one giant uncommitted transaction, matching the source's own batch size.
    Permissions =
        tabledata Currency = RM,
        tabledata Item = RM,
        tabledata "Post Code" = RM,
        tabledata "Unit of Measure" = RM,
        tabledata "VAT Posting Setup" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625') then
            exit;

        MigrateMasterTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625');
    end;

    local procedure MigrateMasterTableExtensionFields()
    var
        FieldMap: Dictionary of [Integer, Integer];
    begin
        // Currency: "EF Currency Type" -> "Currency Type_DXR"
        FieldMap.Add(55501, 52333);
        CopySameTableFields(Database::Currency, FieldMap);
        Clear(FieldMap);

        // Item: "EF Applies for ISC", "EF Tax Type"
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55502, 52334);
        CopyItemFieldsInBatches(FieldMap);
        Clear(FieldMap);

        // Post Code: skip FlowFields "EF County Description" and "EF Township Description"
        FieldMap.Add(55502, 52334);
        FieldMap.Add(55501, 52333);
        CopySameTableFields(Database::"Post Code", FieldMap);
        Clear(FieldMap);

        // Unit of Measure
        FieldMap.Add(55505, 52333);
        CopySameTableFields(Database::"Unit of Measure", FieldMap);
        Clear(FieldMap);

        // VAT Posting Setup
        FieldMap.Add(55503, 52333);
        CopySameTableFields(Database::"VAT Posting Setup", FieldMap);
        Clear(FieldMap);
    end;

    local procedure CopySameTableFields(TableId: Integer; FieldMap: Dictionary of [Integer, Integer])
    var
        RecRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        SourceFieldNo: Integer;
        TargetFieldNo: Integer;
        FieldNos: List of [Integer];
        Modified: Boolean;
    begin
        if FieldMap.Count() = 0 then
            exit;

        RecRef.Open(TableId);

        if RecRef.FindSet() then
            repeat
                Modified := false;
                FieldNos := FieldMap.Keys();

                foreach SourceFieldNo in FieldNos do begin
                    TargetFieldNo := FieldMap.Get(SourceFieldNo);

                    if RecRef.FieldExist(SourceFieldNo) and RecRef.FieldExist(TargetFieldNo) then begin
                        SourceFieldRef := RecRef.Field(SourceFieldNo);
                        TargetFieldRef := RecRef.Field(TargetFieldNo);

                        if TargetFieldRef.Class = FieldClass::Normal then begin
                            TargetFieldRef.Value := SourceFieldRef.Value;
                            Modified := true;
                        end;
                    end;
                end;

                if Modified then
                    RecRef.Modify(false);
            until RecRef.Next() = 0;

        RecRef.Close();
    end;

    local procedure CopyItemFieldsInBatches(FieldMap: Dictionary of [Integer, Integer])
    var
        Item: Record Item;
        BatchCount: Integer;
    begin
        if Item.FindSet(false) then
            repeat
                CopyItemFieldValues(Item, FieldMap);
                BatchCount += 1;

                if BatchCount >= ProductBatchSize() then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Item.Next() = 0;
    end;

    local procedure CopyItemFieldValues(var Item: Record Item; FieldMap: Dictionary of [Integer, Integer])
    var
        ItemRef: RecordRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        SourceFieldNo: Integer;
        TargetFieldNo: Integer;
        FieldNos: List of [Integer];
        Modified: Boolean;
    begin
        ItemRef.GetTable(Item);
        FieldNos := FieldMap.Keys();
        foreach SourceFieldNo in FieldNos do begin
            TargetFieldNo := FieldMap.Get(SourceFieldNo);
            if ItemRef.FieldExist(SourceFieldNo) and ItemRef.FieldExist(TargetFieldNo) then begin
                SourceFieldRef := ItemRef.Field(SourceFieldNo);
                TargetFieldRef := ItemRef.Field(TargetFieldNo);
                if (TargetFieldRef.Class = FieldClass::Normal) and
                   (Format(TargetFieldRef.Value) <> Format(SourceFieldRef.Value))
                then begin
                    TargetFieldRef.Value := SourceFieldRef.Value;
                    Modified := true;
                end;
            end;
        end;

        if Modified then begin
            ItemRef.Modify(false);
            ItemRef.SetTable(Item);
        end;
    end;

    local procedure ProductBatchSize(): Integer
    begin
        exit(100);
    end;
}
