// #if not ESCUDEA and not BCDX
// codeunit 60155 "DXR MCC Bellon Migr Phase11"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 11 NCF" (56128) -> "Bellon Upgrade Process".MigrateAllNcfRenameRestore(). Fixes a real,
//     // live production "field/table removal not permitted" publish failure in the NCF/EF area (6
//     // items total in the real source's own root-cause comment, but only 4 of them have distinct
//     // migration CODE - the other 2, "Config. NCF Ventas"/"Config. NCF Ventas STD" table restores,
//     // were ALREADY wired via MigrateLegacyTableData(50032/50033, ...) inside Phase 2's
//     // MigrateAllNormalizedTables; this phase's own contribution for those two was purely a field-
//     // NAME correction on the legacy shell table's own schema declaration, not new migration code -
//     // so there is nothing further to port here for them; see this MCC extension's registry
//     // repointing for how those two BELLON-P11 concept rows map to the Phase 2 codeunit instead):
//     //   1) Config. NCF Compras: field 52120031 was renamed in-place without preserving the old AL
//     //      identifier (container ID/name never changed) - fixed by adding a new field (52120034)
//     //      carrying the missing name, synced from 52120031.
//     //   2) SalesHeaderOrderListFromBo: same shape - field 54100 renamed, container unchanged -
//     //      fixed the same way (new field 54101).
//     //   3) BE NCF Setup (tableextension 53455, extends "DXR_NCF Setup"): container was renumbered
//     //      with no legacy shell at all - bridges from the legacy "DXNCF Setup" table (restored by
//     //      Base App DR Localization) into the current fields.
//     //   4) BE Listado Recibo de Ingreso (tableextension, extends "DXR_Cash Journal Receipt List"):
//     //      same shape as #3, bridges from "DXCash Journal Receipt List".
//     //
//     // "DXR_NCF Setup" (52179) and "DXR_Cash Journal Receipt List" (52132) are Access = Internal in
//     // DR-Localization (AL0161 on any typed/named reference, including a Permissions entry).
//     // "DXR_Cash Journal Receipt List" is still accessed purely via RecordRef by numeric table ID,
//     // matching the established pattern for every other sibling's Access = Internal object in this
//     // portfolio (see e.g. "DXR MCC FE Migr Phase7"). "DXR_NCF Setup" is now declared as a typed
//     // Record directly here (see MigrateNCFSetupOldCrossTable() below) - DR-Localization grants
//     // MCC's own app ID internalsVisibleTo directly, so BELLON's "DXR_BE MCC Migr Bridge" (56132)
//     // bridge codeunit is no longer needed for this table (left in place, unused).
//     Permissions =
//         tabledata "Config. NCF Compras" = RM,
//         tabledata SalesHeaderOrderListFromBo = RM,
//         tabledata "DXCash Journal Receipt List" = R,
//         tabledata "DXNCF Setup" = R,
//         tabledata "DXR_NCF Setup" = RIM;

//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-NcfRenameRestore283') then
//             exit;

//         MigrateConfigNCFComprasFieldRename();
//         MigrateSalesHeaderOrderListFromBoFieldRename();
//         MigrateNCFSetupOldCrossTable();
//         MigrateListadoRecibodeIngresoOldCrossTable();

//         UpgradeTag.SetUpgradeTag('DXR-NcfRenameRestore283');
//     end;

//     procedure RunSetup()
//     begin
//         MigrateConfigNCFComprasFieldRename();
//         MigrateNCFSetupOldCrossTable();
//     end;

//     procedure RunAccounting()
//     begin
//         MigrateSalesHeaderOrderListFromBoFieldRename();
//         MigrateListadoRecibodeIngresoOldCrossTable();
//     end;

//     procedure RunMaster()
//     begin
//     end;

//     local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
//     var
//         CandidateField: FieldRef;
//         SourceField: FieldRef;
//         TargetField: FieldRef;
//         FieldIndex: Integer;
//         SourceFound: Boolean;
//         TargetFound: Boolean;
//     begin
//         // Resolve the published identities once through metadata, then copy by the resolved field
//         // names. This avoids direct Field(ID) dereferencing and validates the physical types.
//         for FieldIndex := 1 to RecRef.FieldCount() do begin
//             CandidateField := RecRef.FieldIndex(FieldIndex);
//             if CandidateField.Number() = OldFieldNo then begin
//                 SourceField := CandidateField;
//                 SourceFound := true;
//             end;
//             if CandidateField.Number() = NewFieldNo then begin
//                 TargetField := CandidateField;
//                 TargetFound := true;
//             end;
//         end;
//         if not SourceFound or not TargetFound then
//             exit;
//         if (SourceField.Class() <> FieldClass::Normal) or
//            (TargetField.Class() <> FieldClass::Normal) or
//            (SourceField.Type() <> TargetField.Type())
//         then
//             exit;

//         SourceField := RecRef.Field(SourceField.Name());
//         TargetField := RecRef.Field(TargetField.Name());
//         TargetField.Value := SourceField.Value();
//     end;

//     local procedure MigrateConfigNCFComprasFieldRename()
//     var
//         ConfigNCFCompras: Record "Config. NCF Compras";
//     begin
//         if ConfigNCFCompras.FindSet(true) then
//             repeat
//                 ConfigNCFCompras."EF Alternal No. Series" := ConfigNCFCompras."Alternal No. Series_DXR";
//                 ConfigNCFCompras.Modify(false);
//             until ConfigNCFCompras.Next() = 0;
//     end;

//     local procedure MigrateSalesHeaderOrderListFromBoFieldRename()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::SalesHeaderOrderListFromBo);
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 54100, 54101);
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     local procedure MigrateNCFSetupOldCrossTable()
//     var
//         OldSetup: Record "DXNCF Setup";
//         NewSetup: Record "DXR_NCF Setup";
//     begin
//         // Both are singleton Setup tables (single "Primary Key" row, blank key value). "DXR_NCF
//         // Setup" is Access = Internal in DR-Localization, but DR-Localization now grants MCC's own
//         // app ID internalsVisibleTo directly, so both tables are declared as typed Records directly
//         // here - no bridge codeunit needed. BELLON's "DXR_BE MCC Migr Bridge" (56132) is left in
//         // place, unused, per this task's scope. Guard matches the original RecordRef-based
//         // procedure exactly - only runs if both the old and new records exist, no additional
//         // overwrite guard beyond that (the caller's own UpgradeTag already ensures this only runs
//         // once per tenant). Zero RecordRef/FieldRef/TransferFields.
//         if not OldSetup.Get() then
//             exit;
//         if not NewSetup.Get() then begin
//             NewSetup.Init();
//             NewSetup."Primary Key" := OldSetup."Primary Key";
//             NewSetup.Insert(false);
//         end;
//         NewSetup."Grupo Contable BS_DXR" := OldSetup."Grupo Contable BS";
//         NewSetup."Legal Tip %_DXR" := OldSetup."Legal Tip %";
//         NewSetup.Modify(false);
//     end;

//     local procedure MigrateListadoRecibodeIngresoOldCrossTable()
//     var
//         OldRef: RecordRef;
//         NewRef: RecordRef;
//         OldKeyRef: KeyRef;
//         OldPkFieldRef: FieldRef;
//         NewPkFieldRef: FieldRef;
//         KeyFieldIndex: Integer;
//         AllKeyFieldsMapped: Boolean;
//     begin
//         // "DXR_Cash Journal Receipt List" is Access = Internal, so the new side is opened by
//         // numeric table ID (52132) via RecordRef; the old (legacy) side is opened by RecordRef too
//         // so KeyIndex() is available (only RecordRef exposes it, not a typed Record variable).
//         // Joined on "Document No." (the old table's own primary key) by matching field NAME and
//         // TYPE across both tables. Field IDs are not trusted across different table objects.
//         OldRef.Open(Database::"DXCash Journal Receipt List");
//         NewRef.Open(52132); // DXR_Cash Journal Receipt List

//         OldKeyRef := OldRef.KeyIndex(1);

//         if OldRef.FindSet() then
//             repeat
//                 NewRef.Reset();
//                 AllKeyFieldsMapped := true;
//                 for KeyFieldIndex := 1 to OldKeyRef.FieldCount() do begin
//                     OldPkFieldRef := OldKeyRef.FieldIndex(KeyFieldIndex);
//                     if NewRef.FieldExist(OldPkFieldRef.Name) then begin
//                         NewPkFieldRef := NewRef.Field(OldPkFieldRef.Name);
//                         if OldPkFieldRef.Type = NewPkFieldRef.Type then
//                             NewPkFieldRef.SetRange(OldPkFieldRef.Value)
//                         else
//                             AllKeyFieldsMapped := false;
//                     end else
//                         AllKeyFieldsMapped := false;
//                 end;

//                 if AllKeyFieldsMapped then
//                     if NewRef.FindFirst() then begin
//                         // Fields 50001 (Cobrador) / 50002 (Gestor) on the old side are FlowFields -
//                         // no physical data to copy; their _DXR equivalents (52788/52790) are
//                         // FlowFields too.
//                         CopyFieldValueIfExists(OldRef, NewRef, 50000, 52787); // Documento Registrado -> _DXR
//                         CopyFieldValueIfExists(OldRef, NewRef, 50005, 52789); // Fecha Vencimiento -> _DXR
//                         CopyFieldValueIfExists(OldRef, NewRef, 50003, 52791); // IsRecaudo -> _DXR
//                         CopyFieldValueIfExists(OldRef, NewRef, 50004, 52792); // No. Authorizacion -> _DXR
//                         NewRef.Modify(false);
//                     end;
//             until OldRef.Next() = 0;

//         NewRef.Close();
//         OldRef.Close();
//     end;

//     local procedure CopyFieldValueIfExists(SourceRef: RecordRef; var TargetRef: RecordRef; SourceFieldNo: Integer; TargetFieldNo: Integer)
//     begin
//         if not SourceRef.FieldExist(SourceFieldNo) then
//             exit;
//         if not TargetRef.FieldExist(TargetFieldNo) then
//             exit;
//         TargetRef.Field(TargetFieldNo).Value := SourceRef.Field(SourceFieldNo).Value;
//     end;
// }

// #endif
