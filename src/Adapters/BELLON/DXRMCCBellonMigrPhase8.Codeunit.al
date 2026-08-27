#if not ESCUDEA and not BCDX
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

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        // Field numbers remain in the published schema to keep BC's RecordRef mechanisms (Field(),
        // FieldExist()) compatible, but migration lookup itself is entirely name based - same
        // resolver as Phase3/Phase7 (DXR MCC Master Field Resolver), skip-if-target-already-
        // populated. Names recovered from this table's own tableextension source
        // (src/Extentions/tables/Contact.TableExt.al in the Bellon Customization app).
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

    local procedure MigrateTableExt_ContactIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Contact);
        if RecRef.FindSet(true) then
            repeat
                // Next To-do Date_DXR, To-do Entry Exists_DXR, To-do Status Filter_DXR and To-do
                // Closed Filter_DXR (52787-52790) are FlowField/FlowFilter - no physical data to copy.
                CopyFieldIfExists(RecRef, 'Next Order Selection_DXR', 'Next Order Selection_Old');
                CopyFieldIfExists(RecRef, 'Next Order Restaurant_DXR', 'Next Order Restaurant_Old');
                CopyFieldIfExists(RecRef, 'Next Order Date_DXR', 'Next Order Date_Old');
                CopyFieldIfExists(RecRef, 'Next Order Time_DXR', 'Next Order Time_Old');
                CopyFieldIfExists(RecRef, 'Next Delivery Tender_DXR', 'Next Delivery Tender_Old');
                CopyFieldIfExists(RecRef, 'Recall Order_DXR', 'Recall Order_Old');
                CopyFieldIfExists(RecRef, 'Next Ord Rest Temp_DXR', 'Next Ord Rest Temp_Old');
                CopyFieldIfExists(RecRef, 'Date Created_DXR', 'Date Created_Old');
                // No. of Open Orders_DXR and No. of Posted Orders_DXR (52799/52800) are FlowFields -
                // no physical data to copy.
                CopyFieldIfExists(RecRef, 'Pre-Ord Print DateTime_DXR', 'Pre-Ord Print DateTime_Old');
                CopyFieldIfExists(RecRef, 'Next Est Prod Time_DXR', 'Next Est Prod Time_Old');
                CopyFieldIfExists(RecRef, 'External No._DXR', 'External No._Old');
                CopyFieldIfExists(RecRef, 'Last Date/Time Modified_DXR', 'Last Date/Time Modified_Old');
                CopyFieldIfExists(RecRef, 'Customer Template Code_DXR', 'Customer Template Code_Old');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
