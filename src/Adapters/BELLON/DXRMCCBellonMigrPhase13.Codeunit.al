/*
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
    Permissions =
        tabledata "Item Charge Assignment (Purch)" = RM,
        tabledata Vendor = RM,
        tabledata "DXR_NCF Setup" = RM;

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
    begin
        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 52787);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        RecRef.Open(52132);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 52787);
                CopyFieldIfExists(RecRef, 50008, 52789);
                CopyFieldIfExists(RecRef, 50010, 52791);
                CopyFieldIfExists(RecRef, 50011, 52792);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

    end;

    procedure RunMaster()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::Vendor);
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50018, 57113);
                CopyFieldIfExists(RecRef, 50019, 57114);
                CopyFieldIfExists(RecRef, 50020, 57115);
                CopyFieldIfExists(RecRef, 50021, 57116);
                CopyFieldIfExists(RecRef, 50022, 57117);
                CopyFieldIfExists(RecRef, 50023, 57118);
                CopyFieldIfExists(RecRef, 50024, 57119);
                CopyFieldIfExists(RecRef, 50025, 57120);
                CopyFieldIfExists(RecRef, 50028, 57121);
                CopyFieldIfExists(RecRef, 50029, 57122);
                CopyFieldIfExists(RecRef, 50030, 57123);
                CopyFieldIfExists(RecRef, 50031, 57124);
                CopyFieldIfExists(RecRef, 50032, 57125);
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure MigrateMissingOldToDxrBridgeFields(var UpgradeTag: Codeunit "Upgrade Tag")
    var
        RecRef: RecordRef;
        NCFSetup: Record "DXR_NCF Setup";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BellonP13OldGapCompleted') then
            exit;

        RecRef.Open(Database::"Item Charge Assignment (Purch)");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50001, 52787); // Monto Cargo Liq._Old -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        RecRef.Open(52132); // DXR_Cash Journal Receipt List
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50006, 52787); // Documento Registrado_Old -> _DXR
                CopyFieldIfExists(RecRef, 50008, 52789); // Fecha Vencimiento_Old -> _DXR
                CopyFieldIfExists(RecRef, 50010, 52791); // IsRecaudo_Old -> _DXR
                CopyFieldIfExists(RecRef, 50011, 52792); // No. Authorizacion_Old -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

        // DXR_NCF Setup (52179) is Access = Internal in DR-Localization, but DR-Localization now
        // grants MCC's own app ID internalsVisibleTo directly, so it is declared as a typed Record
        // directly here. Copies "DXR_NCF Setup"'s own intermediate bridge fields into its live
        // "_DXR" fields (a prior migration pass wired the ObsoleteState=Pending source fields into
        // these "_Old" fields but never wired the final leg): "Grupo Contable BS_Old" (50003) ->
        // "Grupo Contable BS_DXR" (52787), "Legal Tip %_Old" (50004) -> "Legal Tip %_DXR" (52788).
        // Preserves the exact FindSet(true)/repeat.../Modify(false) loop shape of the original
        // procedure for minimal risk, even though "DXR_NCF Setup" is a singleton (single-row)
        // table. Zero RecordRef/FieldRef/TransferFields.
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
        RecRef.Open(Database::"Vendor");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50018, 57113); // BE Tipo Servicio -> Tipo Servicio_DXR
                CopyFieldIfExists(RecRef, 50019, 57114); // BE Clasificación ABC -> Clasificación ABC_DXR
                CopyFieldIfExists(RecRef, 50020, 57115); // BE Enc. Cobros Nombre -> Enc. Cobros Nombre_DXR
                CopyFieldIfExists(RecRef, 50021, 57116); // BE Enc. Cobros email -> Enc. Cobros Email_DXR.
                CopyFieldIfExists(RecRef, 50022, 57117); // BE Enc. Cobros celular -> Enc. Cobros celular_DXR
                CopyFieldIfExists(RecRef, 50023, 57118); // BE Enc. Cobros Cumpleaños -> Enc. Cobros Cumpleaños_DXR
                CopyFieldIfExists(RecRef, 50024, 57119); // BE Frecuencia de Pago -> Frecuencia de Pago_DXR
                CopyFieldIfExists(RecRef, 50025, 57120); // BE Límite de Crédito -> Límite de Crédito_DXR
                CopyFieldIfExists(RecRef, 50028, 57121); // BE Municipio -> Municipio_DXR
                CopyFieldIfExists(RecRef, 50029, 57122); // BE Provincia -> Provincia_DXR
                CopyFieldIfExists(RecRef, 50030, 57123); // BE Despachador Email -> Despachador Email_DX.R
                CopyFieldIfExists(RecRef, 50031, 57124); // BE Proveedor Cilindros -> Proveedor Cilindros_DXR
                CopyFieldIfExists(RecRef, 50032, 57125); // BE Gestor_CXP_ID -> Gestor_CXP_ID_DXR.
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

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

*/
