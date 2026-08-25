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
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(TableMigrationTag()) then begin
            MigrateLegacyTables();
            UpgradeTag.SetUpgradeTag(TableMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(FieldMigrationTag()) then begin
            MigrateLegacyCustomerFields();
            UpgradeTag.SetUpgradeTag(FieldMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(UserPermissionSetsAssignedTag()) then begin
            AssignPermissionSetsToAllUsers();
            UpgradeTag.SetUpgradeTag(UserPermissionSetsAssignedTag());
        end;

        // Gen2 remediation: TransUnion's own "Renumerar objetos y campos DXR_ a rango global
        // 51801-54999" commit renumbered "DXR_Transunion Setup"/"DXR_Transunion Header" (57304/
        // 57305 -> 53601/53602) and the Customer/Cust. Ledger Entry "..._DXR" fields (50205-50209
        // -> 53586-53590) directly on the live SaaS table/fields, instead of the safe
        // preserve-old/add-new pattern. The 570xx/"..._Old" shells were restored (ObsoleteState =
        // Pending) purely so publish does not attempt to remove them.
        if not UpgradeTag.HasUpgradeTag(Gen2TableMigrationTag()) then begin
            MigrateGen2LegacyTables();
            UpgradeTag.SetUpgradeTag(Gen2TableMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(Gen2FieldMigrationTag()) then begin
            MigrateGen2LegacyCustomerFields();
            UpgradeTag.SetUpgradeTag(Gen2FieldMigrationTag());
        end;
    end;

    // Direct typed field assignment, no TransferFields - "Transunion Setup" (57300) ->
    // "DXR_Transunion Setup" (53601) and "Transunion Header" (57301) -> "DXR_Transunion Header"
    // (53602) are field-for-field identical (same IDs/names/types on both sides, confirmed against
    // TU's own real table sources). "Mensajes" (field 13 on the Header pair) is a FlowField and is
    // excluded, matching TransferFields' own behavior.
    local procedure MigrateLegacyTables()
    var
        OldSetup: Record "Transunion Setup";
        NewSetup: Record "DXR_Transunion Setup";
        OldHeader: Record "Transunion Header";
        NewHeader: Record "DXR_Transunion Header";
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
                end;
            until OldSetup.Next() = 0;

        if OldHeader.FindSet() then
            repeat
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
            until OldHeader.Next() = 0;
    end;

    local procedure MigrateLegacyCustomerFields()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if Customer.FindSet(true) then
            repeat
                Customer."Data Crédito VIP_DXR" := Customer."TU - Data Crédito VIP";
                Customer."Forma Crédito_DXR" := Customer."TU - Forma Crédito";
                Customer."Cuenta Abogado_DXR" := Customer."TU - Cuenta Abogado";
                Customer."Incobrable_DXR" := Customer."TU - Incobrable";
                Customer."Teléfono 2_DXR" := Customer."TU - Teléfono 2";
                Customer.Modify(false);
            until Customer.Next() = 0;

        if CustLedgerEntry.FindSet(true) then
            repeat
                CustLedgerEntry."Data Crédito VIP_DXR" := CustLedgerEntry."TU - Data Crédito VIP";
                CustLedgerEntry."Forma Crédito_DXR" := CustLedgerEntry."TU - Forma Crédito";
                CustLedgerEntry."Cuenta Abogado_DXR" := CustLedgerEntry."TU - Cuenta Abogado";
                CustLedgerEntry."Incobrable_DXR" := CustLedgerEntry."TU - Incobrable";
                CustLedgerEntry."Teléfono 2_DXR" := CustLedgerEntry."TU - Teléfono 2";
                CustLedgerEntry.Modify(false);
            until CustLedgerEntry.Next() = 0;
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
    local procedure MigrateGen2LegacyTables()
    var
        TUSetupGen2Migration: Codeunit "DXR_TU Setup Gen2 Migration";
        OldHeader: Record "DXR_Transunion Header Old2";
        NewHeader: Record "DXR_Transunion Header";
    begin
        TUSetupGen2Migration.MigrateGen2Setup();

        if OldHeader.FindSet() then
            repeat
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
            until OldHeader.Next() = 0;
    end;

    local procedure MigrateGen2LegacyCustomerFields()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if Customer.FindSet(true) then
            repeat
                Customer."Data Crédito VIP_DXR" := Customer."Data Crédito VIP_Old";
                Customer."Forma Crédito_DXR" := Customer."Forma Crédito_Old";
                Customer."Cuenta Abogado_DXR" := Customer."Cuenta Abogado_Old";
                Customer."Incobrable_DXR" := Customer."Incobrable_Old";
                Customer."Teléfono 2_DXR" := Customer."Teléfono 2_Old";
                Customer.Modify(false);
            until Customer.Next() = 0;

        if CustLedgerEntry.FindSet(true) then
            repeat
                CustLedgerEntry."Data Crédito VIP_DXR" := CustLedgerEntry."Data Crédito VIP_Old";
                CustLedgerEntry."Forma Crédito_DXR" := CustLedgerEntry."Forma Crédito_Old";
                CustLedgerEntry."Cuenta Abogado_DXR" := CustLedgerEntry."Cuenta Abogado_Old";
                CustLedgerEntry."Incobrable_DXR" := CustLedgerEntry."Incobrable_Old";
                CustLedgerEntry."Teléfono 2_DXR" := CustLedgerEntry."Teléfono 2_Old";
                CustLedgerEntry.Modify(false);
            until CustLedgerEntry.Next() = 0;
    end;

    local procedure AssignPermissionSetsToAllUsers()
    var
        UserRec: Record User;
    begin
        // Hardcoded TU's real app ID (from TransUnion's own app.json) instead of
        // NavApp.GetCurrentModuleInfo(), which would wrongly resolve to MCC's own app ID when this
        // logic runs inside MCC.
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

    local procedure TableMigrationTag(): Code[250]
    begin
        exit('DXR-TU-01-TableMigration28.3-20260731');
    end;

    local procedure FieldMigrationTag(): Code[250]
    begin
        exit('DXR-TU-02-FieldMigration28.3-20260731');
    end;

    local procedure UserPermissionSetsAssignedTag(): Code[250]
    begin
        exit('DXR-TU-03-UserPermissionSetsAssigned28.3-20260817');
    end;

    local procedure Gen2TableMigrationTag(): Code[250]
    begin
        exit('DXR-TU-04-Gen2TableMigration28.3-20260820');
    end;

    local procedure Gen2FieldMigrationTag(): Code[250]
    begin
        exit('DXR-TU-05-Gen2FieldMigration28.3-20260820');
    end;
}
