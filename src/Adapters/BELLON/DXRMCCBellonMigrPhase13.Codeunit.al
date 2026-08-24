codeunit 60157 "DXR MCC Bellon Migr Phase13"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 13 OldGap" (56130), fully self-contained. UNTRACKED BY MCC'S REGISTRY - no BELLON-Pn
    // concept row references this phase at all, and none of the 11 old MCC delegation adapters
    // (60056-60066) ever called it either, since each one called a specific sibling phase
    // codeunit directly, never the sibling's own Dispatcher (which is the only thing that ever
    // invoked Phase 13 in the sibling extension itself). This is a genuine, real gap in this MCC
    // extension's coverage of Bellon Customization, predating this native-migration pivot - not
    // something this port invented. See this conversion's final report for the explicit call-out;
    // no BELLON-P13 registry rows exist yet, so this codeunit currently has nothing pointing at it
    // until/unless such rows are added - a product decision for the requester, not made here.
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
    // DR-Localization (AL0161 on any typed/named reference, including a Permissions entry) - both
    // accessed purely via RecordRef by numeric table ID, matching the established pattern for every
    // other sibling's Access = Internal object in this portfolio (see e.g. "DXR MCC FE Migr Phase7").
    Permissions =
        tabledata "Item Charge Assignment (Purch)" = RM,
        tabledata Vendor = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        MigrateMissingOldToDxrBridgeFields(UpgradeTag);
    end;

    local procedure MigrateMissingOldToDxrBridgeFields(var UpgradeTag: Codeunit "Upgrade Tag")
    var
        RecRef: RecordRef;
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

        RecRef.Open(52179); // DXR_NCF Setup
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50003, 52787); // Grupo Contable BS_Old -> _DXR
                CopyFieldIfExists(RecRef, 50004, 52788); // Legal Tip %_Old -> _DXR
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();

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
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;
}
