#if not ESCUDEA and not BCDX
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
                CopyFieldIfExists(RecRef, 'Fecha Est Lleg Bellon_DXR.', 'Fecha Estimada Llegada Bellon');
                CopyFieldIfExists(RecRef, 'Priority_DXR.', 'Priority');
                CopyFieldIfExists(RecRef, 'FechaEstEntregaSuplidor_DXR.', 'FechaEstimadaEntregaSuplidor');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);

        UpgradeTag.SetUpgradeTag('DXR-BellonP12PHFixCompleted');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        // Field numbers remain in the published schema to keep BC's RecordRef mechanisms (Field(),
        // FieldExist()) compatible, but migration lookup itself is entirely name based - same
        // resolver as Phase3/Phase7 (DXR MCC Master Field Resolver), skip-if-target-already-
        // populated. Names recovered from this table's own tableextension source
        // (src/Extentions/tables/PurchaseHeader.TableExt.al in the Bellon Customization app).
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

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
