codeunit 60139 "DXR MCC FE Migr Phase10"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 10 Sales".OnRun() (Access = Internal). Field-to-field copies on 6 sales
    // document tables - all public/standard BC tables.
    Permissions =
        tabledata "Sales Cr.Memo Header" = RM,
        tabledata "Sales Cr.Memo Line" = RM,
        tabledata "Sales Header" = RM,
        tabledata "Sales Invoice Header" = RM,
        tabledata "Sales Invoice Line" = RM,
        tabledata "Sales Line" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625') then
            exit;

        MigrateSalesTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE4-SALES-FIELDS-20260625');
    end;

    local procedure MigrateSalesTableExtensionFields()
    var
        FieldMap: Dictionary of [Integer, Integer];
    begin
        // Sales Cr.Memo Header
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
        CopySameTableFields(Database::"Sales Cr.Memo Header", FieldMap);
        Clear(FieldMap);

        // Sales Cr.Memo Line
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52334);
        // 55504 "EF Applies for Withholding" -> 52335 "Applies Withholding_DXR" added 2026-08-22
        // (portfolio-wide "missing migration" audit).
        FieldMap.Add(55504, 52335);
        FieldMap.Add(55505, 52336);
        CopySameTableFields(Database::"Sales Cr.Memo Line", FieldMap);
        Clear(FieldMap);

        // Sales Header: NCF Mod. Reason_DXR lives at 52335 (moved from 52334 to resolve a
        // TransferFields collision with Sales Invoice Header/Sales Cr.Memo Header field 52334).
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52335);
        CopySameTableFields(Database::"Sales Header", FieldMap);
        Clear(FieldMap);

        // Sales Invoice Header
        FieldMap.Add(55514, 52343);
        FieldMap.Add(55508, 52338);
        FieldMap.Add(55507, 52337);
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52335);
        FieldMap.Add(55516, 52345);
        FieldMap.Add(55511, 52341);
        FieldMap.Add(55509, 52339);
        FieldMap.Add(55519, 52348);
        FieldMap.Add(55518, 52347);
        FieldMap.Add(55515, 52344);
        FieldMap.Add(55517, 52346);
        FieldMap.Add(55510, 52340);
        FieldMap.Add(55502, 52334);
        FieldMap.Add(55506, 52336);
        FieldMap.Add(55513, 52342);
        CopySameTableFields(Database::"Sales Invoice Header", FieldMap);
        Clear(FieldMap);

        // Sales Invoice Line
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52334);
        // 55504 -> 52335 added 2026-08-22, same reason as Sales Cr.Memo Line above.
        FieldMap.Add(55504, 52335);
        FieldMap.Add(55505, 52336);
        CopySameTableFields(Database::"Sales Invoice Line", FieldMap);
        Clear(FieldMap);

        // Sales Line
        FieldMap.Add(55501, 52333);
        FieldMap.Add(55503, 52334);
        // 55504 -> 52335 added 2026-08-22, same reason as Sales Cr.Memo Line above.
        FieldMap.Add(55504, 52335);
        FieldMap.Add(55505, 52336);
        CopySameTableFields(Database::"Sales Line", FieldMap);
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
