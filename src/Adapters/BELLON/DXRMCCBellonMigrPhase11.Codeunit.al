codeunit 60155 "DXR MCC Bellon Migr Phase11"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 11 NCF" (56128) -> "Bellon Upgrade Process".MigrateAllNcfRenameRestore(). Fixes a real,
    // live production "field/table removal not permitted" publish failure in the NCF/EF area (6
    // items total in the real source's own root-cause comment, but only 4 of them have distinct
    // migration CODE - the other 2, "Config. NCF Ventas"/"Config. NCF Ventas STD" table restores,
    // were ALREADY wired via MigrateLegacyTableData(50032/50033, ...) inside Phase 2's
    // MigrateAllNormalizedTables; this phase's own contribution for those two was purely a field-
    // NAME correction on the legacy shell table's own schema declaration, not new migration code -
    // so there is nothing further to port here for them; see this MCC extension's registry
    // repointing for how those two BELLON-P11 concept rows map to the Phase 2 codeunit instead):
    //   1) Config. NCF Compras: field 52120031 was renamed in-place without preserving the old AL
    //      identifier (container ID/name never changed) - fixed by adding a new field (52120034)
    //      carrying the missing name, synced from 52120031.
    //   2) SalesHeaderOrderListFromBo: same shape - field 54100 renamed, container unchanged -
    //      fixed the same way (new field 54101).
    //   3) BE NCF Setup (tableextension 53455, extends "DXR_NCF Setup"): container was renumbered
    //      with no legacy shell at all - bridges from the legacy "DXNCF Setup" table (restored by
    //      Base App DR Localization) into the current fields.
    //   4) BE Listado Recibo de Ingreso (tableextension, extends "DXR_Cash Journal Receipt List"):
    //      same shape as #3, bridges from "DXCash Journal Receipt List".
    //
    // "DXR_NCF Setup" (52179) and "DXR_Cash Journal Receipt List" (52132) are Access = Internal in
    // DR-Localization (AL0161 on any typed/named reference, including a Permissions entry).
    // "DXR_Cash Journal Receipt List" is still accessed purely via RecordRef by numeric table ID,
    // matching the established pattern for every other sibling's Access = Internal object in this
    // portfolio (see e.g. "DXR MCC FE Migr Phase7"). "DXR_NCF Setup" is instead reached through the
    // typed "DXR_BE MCC Migr Bridge" (56132) thin wrapper in BELLON's own package (see
    // MigrateNCFSetupOldCrossTable() below), which DOES have the internalsVisibleTo grant.
    Permissions =
        tabledata "Config. NCF Compras" = RM,
        tabledata SalesHeaderOrderListFromBo = RM,
        tabledata "DXCash Journal Receipt List" = R;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-NcfRenameRestore283') then
            exit;

        MigrateConfigNCFComprasFieldRename();
        MigrateSalesHeaderOrderListFromBoFieldRename();
        MigrateNCFSetupOldCrossTable();
        MigrateListadoRecibodeIngresoOldCrossTable();

        UpgradeTag.SetUpgradeTag('DXR-NcfRenameRestore283');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;

    local procedure MigrateConfigNCFComprasFieldRename()
    var
        ConfigNCFCompras: Record "Config. NCF Compras";
    begin
        if ConfigNCFCompras.FindSet(true) then
            repeat
                ConfigNCFCompras."EF Alternal No. Series" := ConfigNCFCompras."Alternal No. Series_DXR";
                ConfigNCFCompras.Modify(false);
            until ConfigNCFCompras.Next() = 0;
    end;

    local procedure MigrateSalesHeaderOrderListFromBoFieldRename()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::SalesHeaderOrderListFromBo);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 54100, 54101);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateNCFSetupOldCrossTable()
    var
        BellonMCCMigrBridge: Codeunit "DXR_BE MCC Migr Bridge";
    begin
        // Both are singleton Setup tables (single "Primary Key" row). "DXR_NCF Setup" is Access =
        // Internal, so it cannot be declared as a typed Record here (MCC's own package has no
        // internalsVisibleTo grant from DR-Localization - only "Bellon Customization" does). This
        // now calls a thin typed bridge procedure added to BELLON's own package for this task -
        // "DXR_BE MCC Migr Bridge" (56132).RunLegacyCrossTableSync_NCFSetup() - which lives inside
        // a package that DOES have the internalsVisibleTo grant and can declare "DXR_NCF Setup" as
        // a typed Record directly. Mirrors the same pattern already used by
        // MigrateTableExt_DXNCFSetupFields() in "DXR MCC Bellon Migr Phase2". Zero RecordRef/
        // FieldRef in this procedure.
        BellonMCCMigrBridge.RunLegacyCrossTableSync_NCFSetup();
    end;

    local procedure MigrateListadoRecibodeIngresoOldCrossTable()
    var
        OldRef: RecordRef;
        NewRef: RecordRef;
        OldKeyRef: KeyRef;
        OldPkFieldRef: FieldRef;
        NewPkFieldRef: FieldRef;
        KeyFieldIndex: Integer;
        AllKeyFieldsMapped: Boolean;
    begin
        // "DXR_Cash Journal Receipt List" is Access = Internal, so the new side is opened by
        // numeric table ID (52132) via RecordRef; the old (legacy) side is opened by RecordRef too
        // so KeyIndex() is available (only RecordRef exposes it, not a typed Record variable).
        // Joined on "Document No." (the old table's own primary key) by matching field NUMBER
        // across both tables - table renumbering in this portfolio preserves field numbers, only
        // the table ID changes (same assumption the generic MigrateLegacyTableData engine relies
        // on everywhere else in this migration).
        OldRef.Open(Database::"DXCash Journal Receipt List");
        NewRef.Open(52132); // DXR_Cash Journal Receipt List

        OldKeyRef := OldRef.KeyIndex(1);

        if OldRef.FindSet() then
            repeat
                NewRef.Reset();
                AllKeyFieldsMapped := true;
                for KeyFieldIndex := 1 to OldKeyRef.FieldCount() do begin
                    OldPkFieldRef := OldKeyRef.FieldIndex(KeyFieldIndex);
                    if NewRef.FieldExist(OldPkFieldRef.Number) then begin
                        NewPkFieldRef := NewRef.Field(OldPkFieldRef.Number);
                        NewPkFieldRef.SetRange(OldPkFieldRef.Value);
                    end else
                        AllKeyFieldsMapped := false;
                end;

                if AllKeyFieldsMapped then
                    if NewRef.FindFirst() then begin
                        // Fields 50001 (Cobrador) / 50002 (Gestor) on the old side are FlowFields -
                        // no physical data to copy; their _DXR equivalents (52788/52790) are
                        // FlowFields too.
                        CopyFieldValueIfExists(OldRef, NewRef, 50000, 52787); // Documento Registrado -> _DXR
                        CopyFieldValueIfExists(OldRef, NewRef, 50005, 52789); // Fecha Vencimiento -> _DXR
                        CopyFieldValueIfExists(OldRef, NewRef, 50003, 52791); // IsRecaudo -> _DXR
                        CopyFieldValueIfExists(OldRef, NewRef, 50004, 52792); // No. Authorizacion -> _DXR
                        NewRef.Modify(false);
                    end;
            until OldRef.Next() = 0;

        NewRef.Close();
        OldRef.Close();
    end;

    local procedure CopyFieldValueIfExists(SourceRef: RecordRef; var TargetRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
    begin
        if not SourceRef.FieldExist(SourceFieldNo) then
            exit;
        if not TargetRef.FieldExist(TargetFieldNo) then
            exit;
        TargetRef.Field(TargetFieldNo).Value := SourceRef.Field(SourceFieldNo).Value;
    end;
}
