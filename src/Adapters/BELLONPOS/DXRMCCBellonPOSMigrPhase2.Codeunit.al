#if not ESCUDEA and not BCDX
codeunit 60159 "DXR MCC BellonPOS Migr Phase2"
{
    // Native local migration - ported verbatim from Bellon Customization POS's own "Bellon POS
    // Migr Phase2 LegNorm" (56212) -> "DXR_POS Upgrade Process".MigrateAllTableExtensionFields() +
    // MigrateAllNormalizedTables() (both internal procedure calls on a typed Subtype = Upgrade
    // codeunit variable - never .Run()/OnRun, same pre-existing pattern the deleted delegation
    // adapter itself already used and documented as safe). No hidden/untracked phases here - the
    // sibling's own Dispatcher only runs Phase 1 (critical/inline, out of scope like every other
    // extension's Phase 1) and this Phase 2, both already fully covered by the deleted adapter.
    //
    // Fixed 2026-08-27 (missing Permissions entries): the block below covered only the tables this
    // codeunit reaches through a typed Record or a named Database::"X" RecordRef. It did NOT cover
    // the six tables MigrateLegacyTableData() opens BY NUMERIC ID (50300/50301/50302 ->
    // 53563/53564/53565), and MCC's permission set 60000 grants no tabledata for foreign tables at
    // all, so those three legacy restores could only ever fail with a TableData permission error
    // when the phase runs in the background (TaskScheduler). Sources are read-only (FindSet/Next)
    // => R; destinations are IsEmpty() + Insert, never Modify or Delete => RI, not RIMD.
    // Names resolved from Dextra_Bellon Customization POS_28.3.2.6.app's own SymbolReference.json;
    // note "POS Trans RTC. " really does carry a trailing space in its object name.
    Permissions =
        tabledata "BE DX Setup" = RM,
        tabledata "LSC Coupon Header" = RM,
        tabledata "LSC POS Trans. Line" = RM,
        tabledata "LSC POS Command" = RM,
        tabledata "LSC POS Terminal" = RM,
        tabledata "LSC POS Transaction" = RM,
        tabledata "LSC Trans. Sales Entry" = RM,
        tabledata "LSC Trans. Server Table Log" = RM,
        tabledata "POS Trans. Grouped RTC" = R,
        tabledata "POS Trans RTC. " = R,
        tabledata "POS Trans. / Invalid Items RTC" = R,
        tabledata "DXR_POS Trans. Grouped RTC" = RI,
        tabledata "DXR_POS Trans RTC." = RI,
        tabledata "DXR_POS Trans./Inv Items RTC" = RI;

    trigger OnRun()
    begin
        MigrateAllTableExtensionFields();
        MigrateAllNormalizedTables();
    end;

    procedure RunSetup()
    begin
        MigrateTableExt_BEDXSetupFields();
        MigrateTableExt_LSCPOSTerminalFields();
    end;

    procedure RunHistoric()
    begin
        MigrateTableExt_LSCTransServerTableLogFields();
        MigrateLegacyTableData(50300, 53563);
        MigrateLegacyTableData(50301, 53564);
        MigrateLegacyTableData(50302, 53565);
    end;

    procedure RunOther()
    begin
        MigrateTableExt_LSCMembershipCardFields();
        MigrateTableExt_LSCCouponHeaderFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSCommandFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_LSCTransSalesEntryFields();
    end;

    local procedure MigrateAllTableExtensionFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BELLONPOS-TABLEEXT-FIELDS-NAME-FALLBACK-20260826') then
            exit;

        MigrateTableExt_LSCMembershipCardFields();
        MigrateTableExt_BEDXSetupFields();
        MigrateTableExt_LSCCouponHeaderFields();
        MigrateTableExt_LSCPOSTransLineFields();
        MigrateTableExt_LSCPOSCommandFields();
        MigrateTableExt_LSCPOSTerminalFields();
        MigrateTableExt_LSCPOSTransactionFields();
        MigrateTableExt_LSCTransSalesEntryFields();
        MigrateTableExt_LSCTransServerTableLogFields();

        UpgradeTag.SetUpgradeTag('DXR-BELLONPOS-TABLEEXT-FIELDS-NAME-FALLBACK-20260826');
    end;

    // "LSC Membership Card": both the legacy field (50000, "Cardholder Name") and the new one
    // ("Cardholder Name_DXR", 53526) are FlowFields (Lookup to "LSC Member Contact".Name) - no
    // physical data to copy, both are calculated. Deliberate no-op, matching the real source.
    local procedure MigrateTableExt_LSCMembershipCardFields()
    begin
    end;

    // Fixed 2026-08-27: FindSet(true) took an UPDLOCK on every "BE DX Setup" row for the whole run
    // and, with no SetLoadFields, joined every tableextension companion table per row. Now reads
    // partial + unlocked and re-reads with Get() only the rows that actually need a value copied.
    local procedure MigrateTableExt_BEDXSetupFields()
    var
        Setup: Record "BE DX Setup";
        SetupToUpdate: Record "BE DX Setup";
        Modified: Boolean;
    begin
        Setup.SetLoadFields(
            "Key",
            "POS Venta Exonerada ITBIS_DXR", "POS Venta Exonerada ITBIS",
            "Filtro Pos Devolucion_DXR", "Filtro Pos Devolucion",
            "POS Devolucion Exonerada ITBIS_DXR", "POS Devolucion Exonerada ITBIS",
            "Show SalesPerson on Receipt_DXR", "Show SalesPerson on Receipt");
        if not Setup.FindSet(false) then
            exit;
        repeat
            if BEDXSetupRowNeedsMigration(Setup) then
                if SetupToUpdate.Get(Setup."Key") then begin
                    Modified := false;
                    if (SetupToUpdate."POS Venta Exonerada ITBIS_DXR" = false) and SetupToUpdate."POS Venta Exonerada ITBIS" then begin
                        SetupToUpdate."POS Venta Exonerada ITBIS_DXR" := SetupToUpdate."POS Venta Exonerada ITBIS";
                        Modified := true;
                    end;
                    if (SetupToUpdate."Filtro Pos Devolucion_DXR" = false) and SetupToUpdate."Filtro Pos Devolucion" then begin
                        SetupToUpdate."Filtro Pos Devolucion_DXR" := SetupToUpdate."Filtro Pos Devolucion";
                        Modified := true;
                    end;
                    if (SetupToUpdate."POS Devolucion Exonerada ITBIS_DXR" = false) and SetupToUpdate."POS Devolucion Exonerada ITBIS" then begin
                        SetupToUpdate."POS Devolucion Exonerada ITBIS_DXR" := SetupToUpdate."POS Devolucion Exonerada ITBIS";
                        Modified := true;
                    end;
                    if (SetupToUpdate."Show SalesPerson on Receipt_DXR" = false) and SetupToUpdate."Show SalesPerson on Receipt" then begin
                        SetupToUpdate."Show SalesPerson on Receipt_DXR" := SetupToUpdate."Show SalesPerson on Receipt";
                        Modified := true;
                    end;
                    if Modified then
                        SetupToUpdate.Modify(false);
                end;
        until Setup.Next() = 0;
    end;

    local procedure BEDXSetupRowNeedsMigration(var Setup: Record "BE DX Setup"): Boolean
    begin
        exit(
            ((Setup."POS Venta Exonerada ITBIS_DXR" = false) and Setup."POS Venta Exonerada ITBIS") or
            ((Setup."Filtro Pos Devolucion_DXR" = false) and Setup."Filtro Pos Devolucion") or
            ((Setup."POS Devolucion Exonerada ITBIS_DXR" = false) and Setup."POS Devolucion Exonerada ITBIS") or
            ((Setup."Show SalesPerson on Receipt_DXR" = false) and Setup."Show SalesPerson on Receipt"));
    end;

    local procedure MigrateTableExt_LSCCouponHeaderFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Coupon Header");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'Discount % of Total_DXR', 'Discount % of Total');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_LSCPOSTransLineFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Trans. Line");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'Order No._DXR', 'Order No.');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_LSCPOSCommandFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Command");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'ModificarLineasBackOffice_DXR', 'ModificarLineasBackOffice');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as MigrateTableExt_BEDXSetupFields() above. "LSC POS Terminal" is polled by every live POS
    // terminal, so holding an update lock over all of it for the whole run is especially bad here.
    local procedure MigrateTableExt_LSCPOSTerminalFields()
    var
        Terminal: Record "LSC POS Terminal";
        TerminalToUpdate: Record "LSC POS Terminal";
        Modified: Boolean;
    begin
        Terminal.SetLoadFields(
            "No.",
            "External Cmd. Print Z by Range_DXR", "External Cmd. Print Z by Range",
            "External Cmd. Imp. Factura_DXR", "External Cmd. Imp. Factura",
            "External Cmd. Cliente Suspe._DXR", "External Cmd. Cliente Suspe.");
        if not Terminal.FindSet(false) then
            exit;
        repeat
            if TerminalRowNeedsMigration(Terminal) then
                if TerminalToUpdate.Get(Terminal."No.") then begin
                    Modified := false;
                    if (TerminalToUpdate."External Cmd. Print Z by Range_DXR" = '') and (TerminalToUpdate."External Cmd. Print Z by Range" <> '') then begin
                        TerminalToUpdate."External Cmd. Print Z by Range_DXR" := TerminalToUpdate."External Cmd. Print Z by Range";
                        Modified := true;
                    end;
                    if (TerminalToUpdate."External Cmd. Imp. Factura_DXR" = '') and (TerminalToUpdate."External Cmd. Imp. Factura" <> '') then begin
                        TerminalToUpdate."External Cmd. Imp. Factura_DXR" := TerminalToUpdate."External Cmd. Imp. Factura";
                        Modified := true;
                    end;
                    if (TerminalToUpdate."External Cmd. Cliente Suspe._DXR" = '') and (TerminalToUpdate."External Cmd. Cliente Suspe." <> '') then begin
                        TerminalToUpdate."External Cmd. Cliente Suspe._DXR" := TerminalToUpdate."External Cmd. Cliente Suspe.";
                        Modified := true;
                    end;
                    if Modified then
                        TerminalToUpdate.Modify(false);
                end;
        until Terminal.Next() = 0;
    end;

    local procedure TerminalRowNeedsMigration(var Terminal: Record "LSC POS Terminal"): Boolean
    begin
        exit(
            ((Terminal."External Cmd. Print Z by Range_DXR" = '') and (Terminal."External Cmd. Print Z by Range" <> '')) or
            ((Terminal."External Cmd. Imp. Factura_DXR" = '') and (Terminal."External Cmd. Imp. Factura" <> '')) or
            ((Terminal."External Cmd. Cliente Suspe._DXR" = '') and (Terminal."External Cmd. Cliente Suspe." <> '')));
    end;

    local procedure MigrateTableExt_LSCPOSTransactionFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Transaction");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'Order No._DXR', 'Order No.');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_LSCTransSalesEntryFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Sales Entry");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'Qty Refunded_DXR', 'Qty Refunded');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure MigrateTableExt_LSCTransServerTableLogFields()
    var
        Modified: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Trans. Server Table Log");
        if RecRef.FindSet(true) then
            repeat
                Modified := CopyFieldIfExists(RecRef, 'Last Lookup_DXR', 'Last Lookup');
                PersistChangedRecord(RecRef, Modified);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldNames: Text): Boolean
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
        exit(MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldNames));
    end;

    local procedure PersistChangedRecord(var RecRef: RecordRef; Modified: Boolean)
    begin
        if not Modified then
            exit;

        RecRef.Modify(false);
        RowsSinceCommit += 1;
        if RowsSinceCommit >= 500 then begin
            Commit();
            RowsSinceCommit := 0;
        end;
    end;

    local procedure FinishTable(var RecRef: RecordRef)
    begin
        RecRef.Close();
        if RowsSinceCommit > 0 then
            Commit();
        RowsSinceCommit := 0;
    end;

    local procedure MigrateAllNormalizedTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-BELLONPOS-TABLES-NORM-28.3') then
            exit;

        MigrateLegacyTableData(50300, 53563);
        MigrateLegacyTableData(50301, 53564);
        MigrateLegacyTableData(50302, 53565);

        UpgradeTag.SetUpgradeTag('DXR-BELLONPOS-TABLES-NORM-28.3');
    end;

    // Generic RecordRef copy of every row from a legacy table (ObsoleteState=Pending) to its new
    // DXR_ clone. Matching is by exact field name and type; field IDs are deliberately not trusted
    // between table objects. Idempotent per table: if the destination already has rows, does not
    // copy again.
    local procedure MigrateLegacyTableData(OldTableId: Integer; NewTableId: Integer)
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
        FieldIdx: Integer;
        BatchCount: Integer;
        TargetWasEmpty: Boolean;
    begin
        NewRecRef.Open(NewTableId);
        TargetWasEmpty := NewRecRef.IsEmpty();
        NewRecRef.Close();

        OldRecRef.Open(OldTableId);
        if OldRecRef.FindSet(false) then
            repeat
                NewRecRef.Open(NewTableId);
                NewRecRef.Init();
                for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                    OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                    if (OldFieldRef.Number() < 2000000000) and
                       (OldFieldRef.Class() = FieldClass::Normal) and
                       NewRecRef.FieldExist(OldFieldRef.Name())
                    then begin
                        NewFieldRef := NewRecRef.Field(OldFieldRef.Name());
                        // Only Normal fields on both sides are copied: a FlowField/FlowFilter on
                        // the destination rejects a direct .Value assignment (runtime error), and
                        // one on the source would need CalcFields first - neither is physical data
                        // this clone needs to carry.
                        if (NewFieldRef.Class() = FieldClass::Normal) and
                           (OldFieldRef.Type() = NewFieldRef.Type())
                        then
                            NewFieldRef.Value := OldFieldRef.Value();
                    end;
                end;
                if TargetWasEmpty then begin
                    NewRecRef.Insert(false);
                    BatchCount += 1;
                end else
                    if TryInsertRecordRef(NewRecRef) then
                        BatchCount += 1;
                // 2026-08-25 fix: same missing-Close bug as BELLON's identical helper
                // (DXRMCCBellonMigrPhase2/Phase6) - NewRecRef.Open() inside this loop without a
                // per-iteration Close() threw "The record is already open." on the 2nd+ row of any
                // multi-row table still served by this shared helper, aborting the whole OnRun().
                NewRecRef.Close();
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until OldRecRef.Next() = 0;
        OldRecRef.Close();
        if BatchCount > 0 then
            Commit();
    end;

    [TryFunction]
    local procedure TryInsertRecordRef(var TargetRecRef: RecordRef)
    begin
        TargetRecRef.Insert(false);
    end;

    var
        RowsSinceCommit: Integer;
}

#endif
