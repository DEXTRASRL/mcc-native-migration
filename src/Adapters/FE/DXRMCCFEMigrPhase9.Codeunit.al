codeunit 60138 "DXR MCC FE Migr Phase9"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 9 Purchase".OnRun() (Access = Internal). Field-to-field copies on 5
    // purchase document tables - all public/standard BC tables.
    Permissions =
        tabledata "Purch. Cr. Memo Hdr." = RM,
        tabledata "Purch. Cr. Memo Line" = RM,
        tabledata "Purch. Inv. Header" = RM,
        tabledata "Purch. Inv. Line" = RM,
        tabledata "Purchase Header" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625') then
            exit;

        MigratePurchaseTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE3-PURCHASE-FIELDS-20260625');
    end;

    local procedure MigratePurchaseTableExtensionFields()
    var
        FieldMap: Dictionary of [Integer, Integer];
    begin
        // Purch. Cr. Memo Hdr.
        FieldMap.Add(55514, 52343);
        FieldMap.Add(55508, 52338);
        FieldMap.Add(55507, 52337);
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52335);
        FieldMap.Add(55516, 52345);
        FieldMap.Add(55511, 52341);
        FieldMap.Add(55509, 52339);
        FieldMap.Add(55518, 52347);
        FieldMap.Add(55515, 52344);
        FieldMap.Add(55517, 52346);
        FieldMap.Add(55510, 52340);
        FieldMap.Add(55502, 52334);
        FieldMap.Add(55506, 52336);
        FieldMap.Add(55513, 52342);
        CopySameTableFields(Database::"Purch. Cr. Memo Hdr.", FieldMap);
        Clear(FieldMap);

        // Purch. Cr. Memo Line
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52334);
        // 55504 "EF Applies for Withholding" -> 52335 "Applies Withholding_DXR" added 2026-08-22
        // (portfolio-wide "missing migration" audit) - was missing here, silently leaving this
        // field blank on every row.
        FieldMap.Add(55504, 52335);
        FieldMap.Add(55505, 52336);
        CopySameTableFields(Database::"Purch. Cr. Memo Line", FieldMap);
        Clear(FieldMap);

        // Purch. Inv. Header
        FieldMap.Add(55515, 52343);
        FieldMap.Add(55508, 52338);
        FieldMap.Add(55507, 52337);
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52335);
        FieldMap.Add(55517, 52345);
        FieldMap.Add(55511, 52341);
        FieldMap.Add(55509, 52339);
        FieldMap.Add(55519, 52347);
        FieldMap.Add(55521, 52349);
        FieldMap.Add(55520, 52348);
        FieldMap.Add(55516, 52344);
        FieldMap.Add(55518, 52346);
        FieldMap.Add(55510, 52340);
        FieldMap.Add(55502, 52334);
        FieldMap.Add(55506, 52336);
        FieldMap.Add(55513, 52342);
        CopySameTableFields(Database::"Purch. Inv. Header", FieldMap);
        Clear(FieldMap);

        // Purch. Inv. Line
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52334);
        // 55504 -> 52335 added 2026-08-22, same reason as Purch. Cr. Memo Line above.
        FieldMap.Add(55504, 52335);
        FieldMap.Add(55505, 52336);
        CopySameTableFields(Database::"Purch. Inv. Line", FieldMap);
        Clear(FieldMap);

        // Purchase Header only carries the legacy "EF NCF Modification Reason" (55503),
        // replaced by "NCF Mod. Reason_DXR" at 52335 (moved from 52333 to resolve a
        // TransferFields collision with Purch. Inv. Header/Purch. Cr. Memo Hdr. field 52333).
        FieldMap.Add(55503, 52335);
        CopySameTableFields(Database::"Purchase Header", FieldMap);
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
}
