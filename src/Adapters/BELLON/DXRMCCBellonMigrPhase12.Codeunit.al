codeunit 60156 "DXR MCC Bellon Migr Phase12"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 12 PHFix" (56129), fully self-contained (does not call "Bellon Upgrade Process").
    // Cross-extension field-ID collision fix, Purchase Header (Bellon Customization) vs Purch.
    // Rcpt. Header (Bellon Customization POS) at fields 50000/50004/50005 - both sides still-active
    // fields on deploy. Copies the current value of each colliding Purchase Header field to a
    // fresh bridge ID (57800-57802).
    //
    // NOTE on ordering (differs from this MCC extension's initial working assumption): the real
    // source's own header comment says this must run before Phase 2's MigrateTableExt_
    // PurchaseHeaderFields, which was WRITTEN to read the 57800-57802 bridge. However, verifying
    // Phase 2's actual current call list (MigrateAllTableExtensionFields) shows
    // MigrateTableExt_PurchaseHeaderFields itself was retroactively REMOVED from that call list on
    // 2026-08-20 (part of the whole Sales/Purchase Header family removal, superseded by later
    // phases) - it is dead code, never invoked, in the real source today. Since MCC's own Phase 2
    // port (see "DXR MCC Bellon Migr Phase2") correctly excludes that same dead procedure, nothing
    // in this MCC extension currently reads the bridge fields this codeunit populates - so no
    // ordering constraint between this codeunit and Phase 2 needs to be enforced here. Ported as
    // its own independent codeunit for that reason, still tracked by its own registry concept
    // (BELLON-P12) since the underlying bridge-population logic remains real and independently
    // useful (e.g. if PurchaseHeaderFields sync is ever re-enabled).
    Permissions =
        tabledata "Purchase Header" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        MigratePurchaseHeaderCollisionBridge(UpgradeTag);
    end;

    local procedure MigratePurchaseHeaderCollisionBridge(var UpgradeTag: Codeunit "Upgrade Tag")
    var
        RecRef: RecordRef;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BellonP12PHFixCompleted') then
            exit;

        RecRef.Open(Database::"Purchase Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50000, 57800); // Fecha Estimada Llegada Bellon -> _DXR.
                CopyFieldIfExists(RecRef, 50004, 57801); // Priority -> _DXR.
                CopyFieldIfExists(RecRef, 50005, 57802); // FechaEstimadaEntregaSuplidor -> _DXR.
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        UpgradeTag.SetUpgradeTag('DXR-BellonP12PHFixCompleted');
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
}
