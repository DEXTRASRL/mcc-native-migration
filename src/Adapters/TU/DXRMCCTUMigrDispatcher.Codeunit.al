#if not ESCUDEA and not BCDX
codeunit 60126 "DXR MCC TU Migr Dispatcher"
{
    // Native local migration - ported verbatim from TransUnion's own
    // "DXR_TU Migr Dispatcher".OnRun() (codeunit 53605, Access = Internal, so this bundles all 5
    // of its tag-gated steps behind one codeunit, matching the deleted delegation adapter's
    // single .Run() call - the registry's 3 TU-P1 rows already shared that one adapter).
    // Step-level Upgrade Tags reuse the sibling's own exact tag string literals (hardcoded here
    // since "DXR_TU Upgrade Tag Mgt." is Access = Internal on TU's side).
    Permissions =
        tabledata "Transunion Setup" = R,
        tabledata "Transunion Header" = R,
        tabledata "DXR_Transunion Header Old2" = R,
        tabledata "DXR_Transunion Setup" = RIM,
        tabledata "DXR_Transunion Header" = RIM,
        tabledata Customer = RM,
        tabledata "Cust. Ledger Entry" = RM,
        tabledata User = R,
        tabledata "Access Control" = RIM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunAccounting();
    end;

    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(SetupTableMigrationTag()) then begin
            MigrateLegacySetup();
            UpgradeTag.SetUpgradeTag(SetupTableMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(Gen2SetupMigrationTag()) then begin
            MigrateGen2LegacySetup();
            UpgradeTag.SetUpgradeTag(Gen2SetupMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(UserPermissionSetsAssignedTag()) then begin
            AssignPermissionSetsToAllUsers();
            UpgradeTag.SetUpgradeTag(UserPermissionSetsAssignedTag());
        end;
    end;

    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(MasterOriginalFieldsMigrationTag()) then begin
            MigrateOriginalCustomerFields();
            UpgradeTag.SetUpgradeTag(MasterOriginalFieldsMigrationTag());
        end;
    end;

    procedure RunAccounting()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(HeaderTableMigrationTag()) then begin
            MigrateLegacyHeaders();
            UpgradeTag.SetUpgradeTag(HeaderTableMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(LedgerFieldMigrationTag()) then begin
            MigrateLegacyCustLedgerEntryFields();
            UpgradeTag.SetUpgradeTag(LedgerFieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(Gen2HeaderMigrationTag()) then begin
            MigrateGen2LegacyHeaders();
            UpgradeTag.SetUpgradeTag(Gen2HeaderMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(Gen2LedgerFieldMigrationTag()) then begin
            MigrateGen2LegacyCustLedgerEntryFields();
            UpgradeTag.SetUpgradeTag(Gen2LedgerFieldMigrationTag());
        end;
    end;

    // Direct typed field assignment, no TransferFields - "Transunion Setup" (57300) ->
    // "DXR_Transunion Setup" (53601) and "Transunion Header" (57301) -> "DXR_Transunion Header"
    // (53602) are field-for-field identical (same IDs/names/types on both sides, confirmed against
    // TU's own real table sources). "Mensajes" (field 13 on the Header pair) is a FlowField and is
    // excluded, matching TransferFields' own behavior.
    /// <summary>
    /// Fixed 2026-08-27 (CONFIRMED silent module shutdown): this was INSERT-ONLY - if the
    /// destination row already existed, Get() succeeded and the three legacy values were never
    /// copied, yet RunSetup() still set SetupTableMigrationTag() so it was never retried.
    /// That path is not hypothetical, it ships inside TransUnion itself: page 53598
    /// "DXR_Transunion Setup" is UsageCategory = Administration (any user can open it) and its
    /// OnOpenPage does `if not Rec.Get() then begin Rec.Init(); Rec.Insert(); end`, creating a row
    /// with Code = '' and everything else at default. And that blank-code row IS the operative one:
    /// TransUnion's own IsModuleActive() calls Setup.Get() with no argument.
    /// So on any tenant where someone had ever opened that page, migration left Active = false and
    /// the TransUnion module silently switched off with no error anywhere.
    /// Now an upsert: an existing row gets the legacy values filled in. Fill-only-if-still-default,
    /// so a value an operator already configured post-publish is never overwritten - the same
    /// never-overwrite policy used across this portfolio's master migrations.
    /// </summary>
    local procedure MigrateLegacySetup()
    var
        OldSetup: Record "Transunion Setup";
        NewSetup: Record "DXR_Transunion Setup";
        Blank: Record "DXR_Transunion Setup";
        Changed: Boolean;
    begin
        if OldSetup.FindSet() then
            repeat
                if not NewSetup.Get(OldSetup.Code) then begin
                    NewSetup.Init();
                    NewSetup."Code" := OldSetup."Code";
                    NewSetup.Active := OldSetup.Active;
                    NewSetup."Directorio Archivo Transunion" := OldSetup."Directorio Archivo Transunion";
                    NewSetup."Limite Credito %" := OldSetup."Limite Credito %";
                    NewSetup.Insert(false);
                end else begin
                    Changed := false;
                    if (NewSetup.Active = Blank.Active) and (OldSetup.Active <> Blank.Active) then begin
                        NewSetup.Active := OldSetup.Active;
                        Changed := true;
                    end;
                    if (NewSetup."Directorio Archivo Transunion" = Blank."Directorio Archivo Transunion") and
                       (OldSetup."Directorio Archivo Transunion" <> Blank."Directorio Archivo Transunion")
                    then begin
                        NewSetup."Directorio Archivo Transunion" := OldSetup."Directorio Archivo Transunion";
                        Changed := true;
                    end;
                    if (NewSetup."Limite Credito %" = Blank."Limite Credito %") and
                       (OldSetup."Limite Credito %" <> Blank."Limite Credito %")
                    then begin
                        NewSetup."Limite Credito %" := OldSetup."Limite Credito %";
                        Changed := true;
                    end;
                    if Changed then
                        NewSetup.Modify(false);
                end;
            until OldSetup.Next() = 0;
    end;

    local procedure MigrateLegacyHeaders()
    var
        OldHeader: Record "Transunion Header";
        NewHeader: Record "DXR_Transunion Header";
        RowsSinceCommit: Integer;
    begin
        if OldHeader.FindSet() then
            repeat
                if not NewHeader.Get(OldHeader."Tipo Documento", OldHeader."No. Documento", OldHeader."No. Linea") then begin
                    NewHeader.Init();
                    NewHeader."Tipo Documento" := OldHeader."Tipo Documento";
                    NewHeader."No. Documento" := OldHeader."No. Documento";
                    NewHeader."Tipo Identificacion" := OldHeader."Tipo Identificacion";
                    NewHeader."Cod. Identificacion" := OldHeader."Cod. Identificacion";
                    NewHeader."Cod. Cliente" := OldHeader."Cod. Cliente";
                    NewHeader."Nombre Cliente" := OldHeader."Nombre Cliente";
                    NewHeader.NCF := OldHeader.NCF;
                    NewHeader."NCF Modificado" := OldHeader."NCF Modificado";
                    NewHeader."Fecha Factura" := OldHeader."Fecha Factura";
                    NewHeader."Monto en Atraso" := OldHeader."Monto en Atraso";
                    NewHeader."Monto Facturado" := OldHeader."Monto Facturado";
                    NewHeader."No. Linea" := OldHeader."No. Linea";
                    NewHeader."Estado Reg." := OldHeader."Estado Reg.";
                    NewHeader."Monto Ult. Pago" := OldHeader."Monto Ult. Pago";
                    NewHeader."Vencido 1-30" := OldHeader."Vencido 1-30";
                    NewHeader."Vencido 31-60" := OldHeader."Vencido 31-60";
                    NewHeader."Vencido 61-90" := OldHeader."Vencido 61-90";
                    NewHeader."Vencido 91-120" := OldHeader."Vencido 91-120";
                    NewHeader."Vencido 121-150" := OldHeader."Vencido 121-150";
                    NewHeader."Vencido 151-180" := OldHeader."Vencido 151-180";
                    NewHeader."Vencido 181" := OldHeader."Vencido 181";
                    NewHeader."Fecha Vencimiento" := OldHeader."Fecha Vencimiento";
                    NewHeader."Entry No." := OldHeader."Entry No.";
                    NewHeader.DayLeft := OldHeader.DayLeft;
                    NewHeader."Fecha Ult. Pago" := OldHeader."Fecha Ult. Pago";
                    NewHeader.Store := OldHeader.Store;
                    NewHeader."Total Vencido 1-30" := OldHeader."Total Vencido 1-30";
                    NewHeader."Total Vencido 31-60" := OldHeader."Total Vencido 31-60";
                    NewHeader."Total Vencido 61-90" := OldHeader."Total Vencido 61-90";
                    NewHeader."Total Vencido 91-120" := OldHeader."Total Vencido 91-120";
                    NewHeader."Total Vencido 121-150" := OldHeader."Total Vencido 121-150";
                    NewHeader."Total Vencido 151-180" := OldHeader."Total Vencido 151-180";
                    NewHeader."Total Vencido 181" := OldHeader."Total Vencido 181";
                    NewHeader.Insert(false);
                end;
                RowsSinceCommit += 1;
                if RowsSinceCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until OldHeader.Next() = 0;
        Commit();
    end;

    /// <summary>
    /// Fixed 2026-08-27 (concept TU-P1 "Customer duplicated field restore" observed taking minutes
    /// on the Bellon company). The loop used to hold a typed Customer record AND call
    /// RecRef.GetTable(Customer) once per row. That is verbatim the pattern Microsoft documents as
    /// bad ("AL database methods and performance on SQL Server" -> Insert, Modify, Delete and
    /// LockTable): "Cloning a record before a Modify or Delete operation issues an extra SQL
    /// statement, since the SQL SELECT query is restarted every time the table is cloned. A record
    /// is cloned [...] when using a RecordRef", and the article's own "bad code" sample is exactly
    /// `RecRef.GetTable(MyTable)` inside a FindSet loop. On a retail-sized Customer table that is one
    /// extra SQL round trip for every single customer, on top of the full-table UPDLOCK that
    /// FindSet(true) already takes.
    /// The replacement is the article's own prescribed form: open the RecordRef directly on the
    /// table and iterate THAT, so the record is never cloned. Same fields, same resolver, same
    /// only-if-populated semantics - purely the documented performance fix.
    /// </summary>
    local procedure MigrateOriginalCustomerFields()
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        RecRef: RecordRef;
        Modified: Boolean;
        RowsSinceCommit: Integer;
    begin
        RecRef.Open(Database::Customer);
        if RecRef.FindSet(true) then
            repeat
                Modified := false;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Data Crédito VIP_DXR', 'TU - Data Crédito VIP|Data Crédito VIP_Old') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Forma Crédito_DXR', 'TU - Forma Crédito|Forma Crédito_Old') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Cuenta Abogado_DXR', 'TU - Cuenta Abogado|Cuenta Abogado_Old') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Incobrable_DXR', 'TU - Incobrable|Incobrable_Old') or Modified;
                Modified := MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Teléfono 2_DXR', 'TU - Teléfono 2|Teléfono 2_Old') or Modified;
                if Modified then begin
                    RecRef.Modify(false);
                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= BatchSize() then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
            until RecRef.Next() = 0;
        RecRef.Close();
        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure MigrateLegacyCustLedgerEntryFields()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryToUpdate: Record "Cust. Ledger Entry";
        Changed: Boolean;
        RowsSinceCommit: Integer;
    begin
        // Added 2026-08-27: partial records. "Cust. Ledger Entry" is normally the largest table in
        // the database and carries many tableextensions across this portfolio, each of which is a
        // companion table the server would otherwise join in for every single row. Learn recommends
        // partial records "especially when looping through several records or when table extensions
        // are defined on the table". Only these ten fields are ever read or written here.
        // Fixed 2026-08-27 (A1): el escaneo pasa a FindSet(false). Con FindSet(true) el servidor lee
        // TODA la tabla con IsolationLevel::UpdLock (SQL UPDLOCK) y mantiene ese lock durante toda la
        // corrida, incluso sobre la mayoria de filas que no cambian. Ahora la fila se re-lee con
        // Get("Entry No.") y se bloquea solo cuando realmente hay que copiar algo, y el contador de
        // Commit avanza por fila MODIFICADA en vez de por fila leida.
        CustLedgerEntry.SetLoadFields(
            "Entry No.",
            "Data Crédito VIP_DXR", "TU - Data Crédito VIP",
            "Forma Crédito_DXR", "TU - Forma Crédito",
            "Cuenta Abogado_DXR", "TU - Cuenta Abogado",
            "Incobrable_DXR", "TU - Incobrable",
            "Teléfono 2_DXR", "TU - Teléfono 2");
        if CustLedgerEntry.FindSet(false) then
            repeat
                if LegacyEntryNeedsMigration(CustLedgerEntry) then
                    if EntryToUpdate.Get(CustLedgerEntry."Entry No.") then begin
                        Changed := false;
                        if EntryToUpdate."Data Crédito VIP_DXR" <> EntryToUpdate."TU - Data Crédito VIP" then begin
                            EntryToUpdate."Data Crédito VIP_DXR" := EntryToUpdate."TU - Data Crédito VIP";
                            Changed := true;
                        end;
                        if EntryToUpdate."Forma Crédito_DXR" <> EntryToUpdate."TU - Forma Crédito" then begin
                            EntryToUpdate."Forma Crédito_DXR" := EntryToUpdate."TU - Forma Crédito";
                            Changed := true;
                        end;
                        if EntryToUpdate."Cuenta Abogado_DXR" <> EntryToUpdate."TU - Cuenta Abogado" then begin
                            EntryToUpdate."Cuenta Abogado_DXR" := EntryToUpdate."TU - Cuenta Abogado";
                            Changed := true;
                        end;
                        if EntryToUpdate."Incobrable_DXR" <> EntryToUpdate."TU - Incobrable" then begin
                            EntryToUpdate."Incobrable_DXR" := EntryToUpdate."TU - Incobrable";
                            Changed := true;
                        end;
                        if EntryToUpdate."Teléfono 2_DXR" <> EntryToUpdate."TU - Teléfono 2" then begin
                            EntryToUpdate."Teléfono 2_DXR" := EntryToUpdate."TU - Teléfono 2";
                            Changed := true;
                        end;
                        if Changed then begin
                            EntryToUpdate.Modify(false);
                            RowsSinceCommit += 1;
                            if RowsSinceCommit >= BatchSize() then begin
                                Commit();
                                RowsSinceCommit := 0;
                            end;
                        end;
                    end;
            until CustLedgerEntry.Next() = 0;
        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure LegacyEntryNeedsMigration(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        exit(
            (CustLedgerEntry."Data Crédito VIP_DXR" <> CustLedgerEntry."TU - Data Crédito VIP") or
            (CustLedgerEntry."Forma Crédito_DXR" <> CustLedgerEntry."TU - Forma Crédito") or
            (CustLedgerEntry."Cuenta Abogado_DXR" <> CustLedgerEntry."TU - Cuenta Abogado") or
            (CustLedgerEntry."Incobrable_DXR" <> CustLedgerEntry."TU - Incobrable") or
            (CustLedgerEntry."Teléfono 2_DXR" <> CustLedgerEntry."TU - Teléfono 2"));
    end;

    // Table 57305 "DXR_Transunion Header Old2" is Access = Internal on TU's side, and TU's own
    // app.json grants "internalsVisibleTo" to MCC's app ID (a5b9bf50-7945-4455-8df4-3be9c7431a7b) -
    // so it is accessed here as a typed Record, no RecordRef/FieldRef. It shares an identical field
    // list (IDs/names/types) with its renumbered replacement 53602, confirmed against TU's own real
    // table source. "Mensajes" (field 13) is a FlowField and is excluded, matching TransferFields'
    // own behavior. Category = MA (TU-P1 seq2) - this was left as RecordRef pending its own task
    // during Task A.4's narrower Setup-phase sweep; this task closes that out.
    //
    // Setup (57304 "DXR_Transunion Setup Old2" -> 53601, Category = SETUP, TU-P1 seq1) migrates
    // via a typed call into TU's own new public codeunit "DXR_TU Setup Gen2 Migration" (53607,
    // added 2026-08-24 to TU's repository specifically for this) - zero RecordRef/FieldRef. TU's
    // own migration-namespace codeunits (DXR_TU Migr Dispatcher 53605, etc.) stay Access = Internal
    // as-is; only a brand-new, narrowly-scoped codeunit was added on TU's side to give MCC a typed
    // entry point, per Task A.4's controller ruling (do not widen Access on any EXISTING TU object).
    local procedure MigrateGen2LegacySetup()
    var
        TUSetupGen2Migration: Codeunit "DXR_TU Setup Gen2 Migration";
    begin
        TUSetupGen2Migration.MigrateGen2Setup();
    end;

    local procedure MigrateGen2LegacyHeaders()
    var
        OldHeader: Record "DXR_Transunion Header Old2";
        NewHeader: Record "DXR_Transunion Header";
        RowsSinceCommit: Integer;
    begin
        if OldHeader.FindSet() then
            repeat
                if not NewHeader.Get(OldHeader."Tipo Documento", OldHeader."No. Documento", OldHeader."No. Linea") then begin
                    NewHeader.Init();
                    NewHeader."Tipo Documento" := OldHeader."Tipo Documento";
                    NewHeader."No. Documento" := OldHeader."No. Documento";
                    NewHeader."Tipo Identificacion" := OldHeader."Tipo Identificacion";
                    NewHeader."Cod. Identificacion" := OldHeader."Cod. Identificacion";
                    NewHeader."Cod. Cliente" := OldHeader."Cod. Cliente";
                    NewHeader."Nombre Cliente" := OldHeader."Nombre Cliente";
                    NewHeader.NCF := OldHeader.NCF;
                    NewHeader."NCF Modificado" := OldHeader."NCF Modificado";
                    NewHeader."Fecha Factura" := OldHeader."Fecha Factura";
                    NewHeader."Monto en Atraso" := OldHeader."Monto en Atraso";
                    NewHeader."Monto Facturado" := OldHeader."Monto Facturado";
                    NewHeader."No. Linea" := OldHeader."No. Linea";
                    NewHeader."Estado Reg." := OldHeader."Estado Reg.";
                    NewHeader."Monto Ult. Pago" := OldHeader."Monto Ult. Pago";
                    NewHeader."Vencido 1-30" := OldHeader."Vencido 1-30";
                    NewHeader."Vencido 31-60" := OldHeader."Vencido 31-60";
                    NewHeader."Vencido 61-90" := OldHeader."Vencido 61-90";
                    NewHeader."Vencido 91-120" := OldHeader."Vencido 91-120";
                    NewHeader."Vencido 121-150" := OldHeader."Vencido 121-150";
                    NewHeader."Vencido 151-180" := OldHeader."Vencido 151-180";
                    NewHeader."Vencido 181" := OldHeader."Vencido 181";
                    NewHeader."Fecha Vencimiento" := OldHeader."Fecha Vencimiento";
                    NewHeader."Entry No." := OldHeader."Entry No.";
                    NewHeader.DayLeft := OldHeader.DayLeft;
                    NewHeader."Fecha Ult. Pago" := OldHeader."Fecha Ult. Pago";
                    NewHeader.Store := OldHeader.Store;
                    NewHeader."Total Vencido 1-30" := OldHeader."Total Vencido 1-30";
                    NewHeader."Total Vencido 31-60" := OldHeader."Total Vencido 31-60";
                    NewHeader."Total Vencido 61-90" := OldHeader."Total Vencido 61-90";
                    NewHeader."Total Vencido 91-120" := OldHeader."Total Vencido 91-120";
                    NewHeader."Total Vencido 121-150" := OldHeader."Total Vencido 121-150";
                    NewHeader."Total Vencido 151-180" := OldHeader."Total Vencido 151-180";
                    NewHeader."Total Vencido 181" := OldHeader."Total Vencido 181";
                    NewHeader.Insert(false);
                end;
                RowsSinceCommit += 1;
                if RowsSinceCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until OldHeader.Next() = 0;
        Commit();
    end;

    local procedure MigrateGen2LegacyCustLedgerEntryFields()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        EntryToUpdate: Record "Cust. Ledger Entry";
        Changed: Boolean;
        RowsSinceCommit: Integer;
    begin
        // Added 2026-08-27: partial records, same rationale as MigrateLegacyCustLedgerEntryFields.
        // Fixed 2026-08-27 (A1): escaneo sin UPDLOCK (FindSet(false)) + re-lectura con
        // Get("Entry No.") solo en las filas que de verdad cambian, misma razon que el gemelo Gen0.
        CustLedgerEntry.SetLoadFields(
            "Entry No.",
            "Data Crédito VIP_DXR", "Data Crédito VIP_Old",
            "Forma Crédito_DXR", "Forma Crédito_Old",
            "Cuenta Abogado_DXR", "Cuenta Abogado_Old",
            "Incobrable_DXR", "Incobrable_Old",
            "Teléfono 2_DXR", "Teléfono 2_Old");
        if CustLedgerEntry.FindSet(false) then
            repeat
                if Gen2EntryNeedsMigration(CustLedgerEntry) then
                    if EntryToUpdate.Get(CustLedgerEntry."Entry No.") then begin
                        Changed := false;
                        if EntryToUpdate."Data Crédito VIP_DXR" <> EntryToUpdate."Data Crédito VIP_Old" then begin
                            EntryToUpdate."Data Crédito VIP_DXR" := EntryToUpdate."Data Crédito VIP_Old";
                            Changed := true;
                        end;
                        if EntryToUpdate."Forma Crédito_DXR" <> EntryToUpdate."Forma Crédito_Old" then begin
                            EntryToUpdate."Forma Crédito_DXR" := EntryToUpdate."Forma Crédito_Old";
                            Changed := true;
                        end;
                        if EntryToUpdate."Cuenta Abogado_DXR" <> EntryToUpdate."Cuenta Abogado_Old" then begin
                            EntryToUpdate."Cuenta Abogado_DXR" := EntryToUpdate."Cuenta Abogado_Old";
                            Changed := true;
                        end;
                        if EntryToUpdate."Incobrable_DXR" <> EntryToUpdate."Incobrable_Old" then begin
                            EntryToUpdate."Incobrable_DXR" := EntryToUpdate."Incobrable_Old";
                            Changed := true;
                        end;
                        if EntryToUpdate."Teléfono 2_DXR" <> EntryToUpdate."Teléfono 2_Old" then begin
                            EntryToUpdate."Teléfono 2_DXR" := EntryToUpdate."Teléfono 2_Old";
                            Changed := true;
                        end;
                        if Changed then begin
                            EntryToUpdate.Modify(false);
                            RowsSinceCommit += 1;
                            if RowsSinceCommit >= BatchSize() then begin
                                Commit();
                                RowsSinceCommit := 0;
                            end;
                        end;
                    end;
            until CustLedgerEntry.Next() = 0;
        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure Gen2EntryNeedsMigration(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        exit(
            (CustLedgerEntry."Data Crédito VIP_DXR" <> CustLedgerEntry."Data Crédito VIP_Old") or
            (CustLedgerEntry."Forma Crédito_DXR" <> CustLedgerEntry."Forma Crédito_Old") or
            (CustLedgerEntry."Cuenta Abogado_DXR" <> CustLedgerEntry."Cuenta Abogado_Old") or
            (CustLedgerEntry."Incobrable_DXR" <> CustLedgerEntry."Incobrable_Old") or
            (CustLedgerEntry."Teléfono 2_DXR" <> CustLedgerEntry."Teléfono 2_Old"));
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded TU's real app ID (from TransUnion's own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
        // Fixed 2026-08-27 (A1, partial records): el bucle solo usa "User Security ID".
        UserRec.SetLoadFields("User Security ID");
        if not UserRec.FindSet() then
            exit;

        repeat
            AssignPermissionSetToUser(UserRec."User Security ID", 'DXR_Transunion', TUAppId());
        until UserRec.Next() = 0;
    end;

    local procedure AssignPermissionSetToUser(UserSecurityId: Guid; PermissionSetId: Code[20]; AppId: Guid)
    var
        AccessControl: Record "Access Control";
    begin
        AccessControl.SetRange("User Security ID", UserSecurityId);
        AccessControl.SetRange("Role ID", PermissionSetId);
        AccessControl.SetRange(Scope, AccessControl.Scope::System);
        AccessControl.SetRange("App ID", AppId);
        AccessControl.SetRange("Company Name", CompanyName());
        if not AccessControl.IsEmpty() then
            exit;

        AccessControl.Init();
        AccessControl."User Security ID" := UserSecurityId;
        AccessControl."Role ID" := PermissionSetId;
        AccessControl.Scope := AccessControl.Scope::System;
        AccessControl."App ID" := AppId;
        AccessControl."Company Name" := CompanyName();
        AccessControl.Insert(true);
    end;

    local procedure TUAppId(): Guid
    begin
        exit('7c42bd17-42ea-4c0a-b6db-e7034ad57faf');
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure TableMigrationTag(): Code[250]
    begin
        exit('DXR-TU-01-TableMigration28.3-20260731');
    end;

    local procedure SetupTableMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-SETUP-GEN0-20260825.');
    end;

    local procedure HeaderTableMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-MA-HEADER-GEN0-20260825.');
    end;

    local procedure FieldMigrationTag(): Code[250]
    begin
        exit('DXR-TU-02-FieldMigration28.3-20260731');
    end;

    local procedure MasterOriginalFieldsMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-MASTER-NAME-FALLBACK-20260826.');
    end;

    local procedure LedgerFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-ACCOUNTING-CLE-GEN0-20260825.');
    end;

    local procedure UserPermissionSetsAssignedTag(): Code[250]
    begin
        exit('DXR-TU-03-UserPermissionSetsAssigned28.3-20260817');
    end;

    local procedure Gen2TableMigrationTag(): Code[250]
    begin
        exit('DXR-TU-04-Gen2TableMigration28.3-20260820');
    end;

    local procedure Gen2SetupMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-SETUP-GEN2-20260825.');
    end;

    local procedure Gen2HeaderMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-MA-HEADER-GEN2-20260825.');
    end;

    local procedure Gen2FieldMigrationTag(): Code[250]
    begin
        exit('DXR-TU-05-Gen2FieldMigration28.3-20260820');
    end;

    local procedure Gen2LedgerFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-TU-ACCOUNTING-CLE-GEN2-20260825.');
    end;
}

#endif
