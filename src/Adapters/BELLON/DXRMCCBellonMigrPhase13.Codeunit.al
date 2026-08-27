#if not ESCUDEA and not BCDX
codeunit 60157 "DXR MCC Bellon Migr Phase13"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 13 OldGap" (56130), fully self-contained. Originally UNTRACKED BY MCC'S REGISTRY (no
    // BELLON-Pn concept row referenced this phase, and none of the 11 old MCC delegation adapters
    // (60056-60066) ever called it either, since each one called a specific sibling phase
    // codeunit directly, never the sibling's own Dispatcher). This was a genuine, real gap in this
    // MCC extension's coverage of Bellon Customization, predating this native-migration pivot -
    // not something this port invented. Registry row BELLON-P13 seq272 (Setup category) now
    // references this codeunit, covering the "DXR_NCF Setup" block below; the other 3 blocks
    // (Item Charge Assignment (Purch), DXR_Cash Journal Receipt List, Vendor) still have no
    // Setup-category registry row of their own.
    //
    // Real content (found via a 2026-08-22 portfolio-wide "missing migration" audit): Phase 2's
    // own field-copy pass correctly copies each ObsoleteState=Pending source field into its "_Old"
    // bridge field for 3 tables, but the final "_Old" -> "_DXR" leg that actually reaches the live
    // field was never wired. Also covers a second, separately-discovered gap on Vendor: 13 fields
    // where the legacy source is copied to an "_Old" field by Phase 2, but no IdRestore bridge was
    // ever declared for these 13 (only 7 of the 20 legacy-sourced fields have a real "_Old" field
    // reachable by Phase 7's Vendor procedure) - these 13 have their final _DXR field declared
    // directly with no intermediate, so this copies straight from the legacy source.
    // "DXR_Cash Journal Receipt List" (52132) and "DXR_NCF Setup" (52179) are Access = Internal in
    // DR-Localization (AL0161 on any typed/named reference, including a Permissions entry).
    // "DXR_Cash Journal Receipt List" is still accessed purely via RecordRef by numeric table ID,
    // matching the established pattern for every other sibling's Access = Internal object in this
    // portfolio (see e.g. "DXR MCC FE Migr Phase7"). "DXR_NCF Setup" is now declared as a typed
    // Record directly here (see the "DXR_NCF Setup" block below) - DR-Localization grants MCC's own
    // app ID internalsVisibleTo directly, so BELLON's "DXR_BE MCC Migr Bridge" (56132) bridge
    // codeunit is no longer needed for this table (left in place, unused).
    // Fixed 2026-08-27 (two gaps in this block):
    //   * RunAccounting()/MigrateMissingOldToDxrBridgeFields() open table 52132 via RecordRef and
    //     Modify(false) it, but "DXR_Cash Journal Receipt List" had NO entry at all. The 60000
    //     "DXR MCC" permissionset grants no third-party tabledata, so the background
    //     (TaskScheduler) run would fail with "Required permission ... Modify". Declared by NAME,
    //     the same way "DXR MCC Bellon Migr Phase7" already declares it.
    //   * "DXR_NCF Setup" was "RM", but RunSetup() calls Insert(false) when Get() misses - that
    //     needs I as well, so it is now RIM.
    Permissions =
        tabledata "Item Charge Assignment (Purch)" = RM,
        tabledata Vendor = RM,
        tabledata "DXR_Cash Journal Receipt List" = RM,
        tabledata "DXR_NCF Setup" = RIM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        MigrateMissingOldToDxrBridgeFields(UpgradeTag);
    end;

    procedure RunSetup()
    var
        NCFSetup: Record "DXR_NCF Setup";
    begin
        if not NCFSetup.Get() then begin
            NCFSetup.Init();
            NCFSetup."Primary Key" := '';
            NCFSetup.Insert(false);
        end;
        NCFSetup."Grupo Contable BS_DXR" := NCFSetup."Grupo Contable BS_Old";
        NCFSetup."Legal Tip %_DXR" := NCFSetup."Legal Tip %_Old";
        NCFSetup.Modify(false);
    end;

    procedure RunAccounting()
    var
        RecRef: RecordRef;
        RowsSinceCommit: Integer;
    begin
        // Fixed 2026-08-27: neither loop below had any Commit, so both tables ran inside a single
        // unbounded transaction. Same 500-row batching the sibling phases already use; the copies
        // are unconditional and idempotent, so a partial run is safe to retry.
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 52787);
                RecRef.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        Commit();
        RowsSinceCommit := 0;

        RecRef.Open(52132);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 52787);
                CopyFieldIfExists(RecRef, 50008, 52789);
                CopyFieldIfExists(RecRef, 50010, 52791);
                CopyFieldIfExists(RecRef, 50011, 52792);
                RecRef.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        Commit();
    end;

    procedure RunMaster()
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        RecRef: RecordRef;
        Modified: Boolean;
        RowsSinceCommit: Integer;
    begin
        RecRef.Open(Database::Vendor);
        if RecRef.FindSet(true) then
            repeat
                Modified := false;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Tipo Servicio_DXR', 'BE Tipo Servicio') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Clasificación ABC_DXR', 'BE Clasificación ABC') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Nombre_DXR', 'BE Enc. Cobros Nombre') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Email_DXR.', 'BE Enc. Cobros email') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros celular_DXR', 'BE Enc. Cobros celular') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Cumpleaños_DXR', 'BE Enc. Cobros Cumpleaños') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Frecuencia de Pago_DXR', 'BE Frecuencia de Pago') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Límite de Crédito_DXR', 'BE Límite de Crédito') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Municipio_DXR', 'BE Municipio') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Provincia_DXR', 'BE Provincia') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Despachador Email_DX.R', 'BE Despachador Email') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Proveedor Cilindros_DXR', 'BE Proveedor Cilindros') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Gestor_CXP_ID_DXR.', 'BE Gestor_CXP_ID') or Modified;
                if Modified then begin
                    RecRef.Modify(false);

                    // Fixed 2026-08-27: this Vendor loop had no Commit at all, so the whole table
                    // ran inside a single unbounded transaction. Counter advances per MODIFIED row
                    // (the resolver is skip-if-target-already-populated, so most rows write
                    // nothing); mirrors the identical loop in MigrateMissingOldToDxrBridgeFields.
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure MigrateMissingOldToDxrBridgeFields(var UpgradeTag: Codeunit "Upgrade Tag")
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        RecRef: RecordRef;
        NCFSetup: Record "DXR_NCF Setup";
        Modified: Boolean;
        RowsSinceCommit: Integer;
        VendorRowsSinceCommit: Integer;
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BellonP13OldGapCompleted') then
            exit;

        // Fixed 2026-08-27: neither of the two loops below had any Commit, so both tables ran
        // inside a single unbounded transaction (only the Vendor loop further down was batched).
        // Same 500-row batching; the copies are unconditional and idempotent, so a partial run is
        // safe to retry - the UpgradeTag is still only set once the whole procedure completes.
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 52787); // Monto Cargo Liq._Old -> _DXR
                RecRef.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        Commit();
        RowsSinceCommit := 0;

        RecRef.Open(52132); // DXR_Cash Journal Receipt List
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 52787); // Documento Registrado_Old -> _DXR
                CopyFieldIfExists(RecRef, 50008, 52789); // Fecha Vencimiento_Old -> _DXR
                CopyFieldIfExists(RecRef, 50010, 52791); // IsRecaudo_Old -> _DXR
                CopyFieldIfExists(RecRef, 50011, 52792); // No. Authorizacion_Old -> _DXR
                RecRef.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        Commit();
        RowsSinceCommit := 0;

        // DXR_NCF Setup (52179) is Access = Internal in DR-Localization, but DR-Localization now
        // grants MCC's own app ID internalsVisibleTo directly, so it is declared as a typed Record
        // directly here. Copies "DXR_NCF Setup"'s own intermediate bridge fields into its live
        // "_DXR" fields (a prior migration pass wired the ObsoleteState=Pending source fields into
        // these "_Old" fields but never wired the final leg): "Grupo Contable BS_Old" (50003) ->
        // "Grupo Contable BS_DXR" (52787), "Legal Tip %_Old" (50004) -> "Legal Tip %_DXR" (52788).
        // Preserves the exact FindSet(true)/repeat.../Modify(false) loop shape of the original
        // procedure for minimal risk, even though "DXR_NCF Setup" is a singleton (single-row)
        // table. Zero RecordRef/FieldRef/TransferFields.
        // Fixed 2026-08-27: FindSet(true) with no SetLoadFields made the server join every
        // tableextension companion table per row. SetLoadFields limits the read to exactly the
        // four fields this loop touches (the primary key is always loaded).
        NCFSetup.SetLoadFields("Grupo Contable BS_DXR", "Grupo Contable BS_Old", "Legal Tip %_DXR", "Legal Tip %_Old");
        if NCFSetup.FindSet(true) then
            repeat
                NCFSetup."Grupo Contable BS_DXR" := NCFSetup."Grupo Contable BS_Old";
                NCFSetup."Legal Tip %_DXR" := NCFSetup."Legal Tip %_Old";
                NCFSetup.Modify(false);
            until NCFSetup.Next() = 0;

        // Vendor.TableExt.al has 13 fields (50018-50025, 50028-50032) where the legacy source is
        // copied to an "_Old" field by Phase 2, but no IdRestore bridge was ever declared for
        // these 13 - only 7 of the 20 source fields have a real "_Old" field (50034-50037/50046/
        // 50047/50053), reachable by Phase 7's Vendor procedure. These 13 have their final _DXR
        // field declared directly (57113-57125) with no intermediate at all, so this copies
        // straight from the legacy source to the final field.
        // Name-based resolution via the shared resolver (same technique as this codeunit's own
        // RunMaster(), which targets the exact same 13 Vendor fields) instead of the raw numeric
        // CopyFieldIfExists(OldFieldNo, NewFieldNo) pattern used elsewhere in this file.
        RecRef.Open(Database::"Vendor");
        if RecRef.FindSet(true) then
            repeat
                Modified := false;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Tipo Servicio_DXR', 'BE Tipo Servicio') or Modified; // 50018 -> 57113
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Clasificación ABC_DXR', 'BE Clasificación ABC') or Modified; // 50019 -> 57114
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Nombre_DXR', 'BE Enc. Cobros Nombre') or Modified; // 50020 -> 57115
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Email_DXR.', 'BE Enc. Cobros email') or Modified; // 50021 -> 57116
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros celular_DXR', 'BE Enc. Cobros celular') or Modified; // 50022 -> 57117
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Enc. Cobros Cumpleaños_DXR', 'BE Enc. Cobros Cumpleaños') or Modified; // 50023 -> 57118
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Frecuencia de Pago_DXR', 'BE Frecuencia de Pago') or Modified; // 50024 -> 57119
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Límite de Crédito_DXR', 'BE Límite de Crédito') or Modified; // 50025 -> 57120
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Municipio_DXR', 'BE Municipio') or Modified; // 50028 -> 57121
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Provincia_DXR', 'BE Provincia') or Modified; // 50029 -> 57122
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Despachador Email_DX.R', 'BE Despachador Email') or Modified; // 50030 -> 57123
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Proveedor Cilindros_DXR', 'BE Proveedor Cilindros') or Modified; // 50031 -> 57124
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Gestor_CXP_ID_DXR.', 'BE Gestor_CXP_ID') or Modified; // 50032 -> 57125
                // Fixed 2026-08-27: the commit counter used to advance per SCANNED row; it now
                // advances per MODIFIED row, so a re-run that has nothing left to copy (the
                // resolver is skip-if-target-already-populated) performs zero writes and zero
                // commits instead of one commit per 500 rows.
                if Modified then begin
                    RecRef.Modify(false);

                    VendorRowsSinceCommit += 1;
                    if VendorRowsSinceCommit >= 500 then begin
                        Commit();
                        VendorRowsSinceCommit := 0;
                    end;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        if VendorRowsSinceCommit > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag('DXR-BellonP13OldGapCompleted');
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

#endif
