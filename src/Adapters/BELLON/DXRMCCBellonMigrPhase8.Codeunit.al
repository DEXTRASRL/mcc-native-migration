codeunit 60152 "DXR MCC Bellon Migr Phase8"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 8 Contact" (56125) -> "Bellon Upgrade Process".MigrateContactIdRestore283(). Restores
    // the 19 "_BE_DXR" fields of Contact.TableExt.al (deliberately excluded from Phase 7 - a
    // later, verified session disproved the original premise that these fields collided with
    // active Customer/Vendor fields; see the real source's own extensive verification comment for
    // the full evidence trail) at their true original ID (50079-50097) with an "_Old" suffix, to
    // their current "_DXR" ID (52787-52805). 6 of the 19 are FlowField/FlowFilter (no physical
    // column) and are excluded from the copy; the other 13 are copied.
    Permissions =
        tabledata Contact = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-ContactIdRestore283') then
            exit;

        MigrateTableExt_ContactIdRestore();

        UpgradeTag.SetUpgradeTag('DXR-ContactIdRestore283');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    var
        CandidateField: FieldRef;
        SourceField: FieldRef;
        TargetField: FieldRef;
        FieldIndex: Integer;
        SourceFound: Boolean;
        TargetFound: Boolean;
    begin
        // Resolve the published identities once through metadata, then copy by the resolved field
        // names. This avoids direct Field(ID) dereferencing and validates the physical types.
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            CandidateField := RecRef.FieldIndex(FieldIndex);
            if CandidateField.Number() = OldFieldNo then begin
                SourceField := CandidateField;
                SourceFound := true;
            end;
            if CandidateField.Number() = NewFieldNo then begin
                TargetField := CandidateField;
                TargetFound := true;
            end;
        end;
        if not SourceFound or not TargetFound then
            exit;
        if (SourceField.Class() <> FieldClass::Normal) or
           (TargetField.Class() <> FieldClass::Normal) or
           (SourceField.Type() <> TargetField.Type())
        then
            exit;

        SourceField := RecRef.Field(SourceField.Name());
        TargetField := RecRef.Field(TargetField.Name());
        TargetField.Value := SourceField.Value();
    end;

    local procedure MigrateTableExt_ContactIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Contact);
        if RecRef.FindSet(true) then
            repeat
                // 52787 (Next To-do Date_DXR) is a FlowField - no physical data to copy.
                // 52788 (To-do Entry Exists_DXR) is a FlowField - no physical data to copy.
                // 52789 (To-do Status Filter_DXR) is a FlowFilter - no physical data to copy.
                // 52790 (To-do Closed Filter_DXR) is a FlowFilter - no physical data to copy.
                CopyFieldIfExists(RecRef, 50083, 52791); // Next Order Selection_Old
                CopyFieldIfExists(RecRef, 50084, 52792); // Next Order Restaurant_Old
                CopyFieldIfExists(RecRef, 50085, 52793); // Next Order Date_Old
                CopyFieldIfExists(RecRef, 50086, 52794); // Next Order Time_Old
                CopyFieldIfExists(RecRef, 50087, 52795); // Next Delivery Tender_Old
                CopyFieldIfExists(RecRef, 50088, 52796); // Recall Order_Old
                CopyFieldIfExists(RecRef, 50089, 52797); // Next Ord Rest Temp_Old
                CopyFieldIfExists(RecRef, 50090, 52798); // Date Created_Old
                // 52799 (No. of Open Orders_DXR) is a FlowField - no physical data to copy.
                // 52800 (No. of Posted Orders_DXR) is a FlowField - no physical data to copy.
                CopyFieldIfExists(RecRef, 50093, 52801); // Pre-Ord Print DateTime_Old
                CopyFieldIfExists(RecRef, 50094, 52802); // Next Est Prod Time_Old
                CopyFieldIfExists(RecRef, 50095, 52803); // External No._Old
                CopyFieldIfExists(RecRef, 50096, 52804); // Last Date/Time Modified_Old
                CopyFieldIfExists(RecRef, 50097, 52805); // Customer Template Code_Old
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
