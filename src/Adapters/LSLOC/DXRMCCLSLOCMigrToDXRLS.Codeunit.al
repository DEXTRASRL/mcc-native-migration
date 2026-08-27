#if not ESCUDEA and not BCDX
codeunit 60162 "DXR MCC LSLOC Migr ToDXRLS"
{
    // Native local migration - ported verbatim from LS Central DR Localization's own
    // "DXR_LS TableExt Fields Upgrade" (54510) + "DXR_LS Legacy Tables Upgrade" (54511), both
    // Access = Internal, bundled together here under one Upgrade Tag exactly as the sibling's own
    // Dispatcher does ('LS_TO_DXR_LS' phase: TableExtFieldsUpgrade.Execute() then
    // LegacyTablesUpgrade.Execute(), same tag for both).
    Permissions =
        tabledata "Gen. Journal Line" = M,
        tabledata Item = M,
        tabledata "LSC Hospitality Type" = M,
        tabledata "LSC Label Functions" = M,
        tabledata "LSC POS Print Setup Header" = M,
        tabledata "LSC POS Terminal" = M,
        tabledata "LSC POS Transaction" = M,
        tabledata "LSC Sales Type" = M,
        tabledata "LSC Store" = M,
        tabledata "LSC Store Inventory Line" = M,
        tabledata "LSC Transaction Header" = M,
        tabledata Field = R,
        tabledata "LSDX POS Setup" = R,
        tabledata "DXR_LS POS Setup" = RIMD,
        tabledata "LSDXTender Types Relation" = R,
        tabledata "DXR_LS Tender Types Relation" = RIMD,
        tabledata "LSDX OPOS Print Setup" = R,
        tabledata "DXR_LS OPOS Print Setup" = RIMD,
        tabledata "LSDX POS 607 Diagnostic" = R,
        tabledata "DXR_LS POS 607 Diagnostic" = RIMD,
        tabledata "LSDX LS NCF Process Reg." = R,
        tabledata "DXR_LS NCF Process Reg." = RIMD;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LS-MIGRATION-20260623') then
            exit;

        TableExtFieldsExecute();
        LegacyTablesExecute();

        UpgradeTag.SetUpgradeTag('DXR-LS-MIGRATION-20260623');
    end;

    procedure RunPOSSetup()
    begin
        CopyLSDXPOSSetupToDXR();
    end;

    procedure RunSetupFields()
    begin
        CopyLSCHospitalityTypeFields();
        CopyLSCLabelFunctionsFields();
        CopyLSCPOSPrintSetupHeaderFields();
        CopyLSCPOSTerminalFields();
        CopyLSCSalesTypeFields();
        CopyLSCStoreFields();
        MigrateSameTableEnumFields();
    end;

    procedure RunHospitalityTypeFields()
    begin
        CopyLSCHospitalityTypeFields();
    end;

    procedure RunLabelFunctionsFields()
    begin
        CopyLSCLabelFunctionsFields();
    end;

    procedure RunPOSPrintSetupHeaderFields()
    begin
        CopyLSCPOSPrintSetupHeaderFields();
    end;

    procedure RunPOSTerminalFields()
    begin
        CopyLSCPOSTerminalFields();
        MigratePOSTerminalEnumFields();
    end;

    procedure RunSalesTypeFields()
    begin
        CopyLSCSalesTypeFields();
    end;

    procedure RunStoreFields()
    begin
        CopyLSCStoreFields();
    end;

    procedure RunSetupRelations()
    begin
        CopyLSDXTenderTypesRelationToDXR();
        CopyLSDXOPOSPrintSetupToDXR();
    end;

    procedure RunMasterFields()
    begin
        CopyItemFields();
    end;

    procedure RunAccountingFields()
    begin
        CopyGenJournalLineFields();
        CopyLSCStoreInventoryLineFields();
    end;

    procedure RunOtherFields()
    begin
        CopyPOSTransactionOtherFields();
        CopyTransactionHeaderOtherFields();
    end;

    procedure RunHistoricTables()
    begin
        CopyStandaloneTable(Database::"LSDX POS 607 Diagnostic", Database::"DXR_LS POS 607 Diagnostic");
        CopyStandaloneTable(Database::"LSDX LS NCF Process Reg.", Database::"DXR_LS NCF Process Reg.");
    end;

    // ===== "DXR_LS TableExt Fields Upgrade" (54510) =====

    local procedure TableExtFieldsExecute()
    begin
        CopyGenJournalLineFields(); // seq2, MA
        CopyItemFields(); // seq5, MA
        CopyLSCHospitalityTypeFields(); // seq6, SETUP
        CopyLSCLabelFunctionsFields(); // seq7, SETUP
        CopyLSCPOSPrintSetupHeaderFields(); // seq8, SETUP
        CopyLSCPOSTerminalFields(); // seq9, SETUP (2 ranges)
        CopyPOSTransactionOtherFields(); // seq10, OTHER (2 ranges)
        CopyLSCSalesTypeFields(); // seq11, SETUP
        CopyLSCStoreFields(); // seq12, SETUP
        CopyLSCStoreInventoryLineFields(); // seq13, MA
        CopyTransactionHeaderOtherFields(); // seq14, OTHER (3 ranges)

        MigrateSameTableEnumFields(); // already typed (no RecordRef/FieldRef) - untouched
    end;

    // ===== In-scope SETUP same-table field-range restores (LSLOC-TOLOC seq6/7/8/9/11/12) =====
    // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
    // Field pairs confirmed against the real compiled symbols (LSLOC's own old/new TableExts) -
    // every source field below is ObsoleteState = Pending (not Removed), so it is still readable.

    local procedure CopyLSCHospitalityTypeFields()
    var
        Rec: Record "LSC Hospitality Type";
    begin
        if Rec.FindSet() then
            repeat
                if (Rec."Void line after Bill Prin_DXR" <> Rec."LSDX Void line after Bill Prin") or
                   (Rec."Void Tran. after Bill Prnt_DXR" <> Rec."LSDXVoid Tran. after Bill Prnt")
                then begin
                    Rec."Void line after Bill Prin_DXR" := Rec."LSDX Void line after Bill Prin";
                    Rec."Void Tran. after Bill Prnt_DXR" := Rec."LSDXVoid Tran. after Bill Prnt";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyLSCLabelFunctionsFields()
    var
        Rec: Record "LSC Label Functions";
    begin
        if Rec.FindSet() then
            repeat
                if Rec."Function Description_DXR" <> Rec."LSDX Function Description" then begin
                    Rec."Function Description_DXR" := Rec."LSDX Function Description";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyLSCPOSPrintSetupHeaderFields()
    var
        Rec: Record "LSC POS Print Setup Header";
    begin
        if Rec.FindSet() then
            repeat
                if Rec."Print Voucher Loc._DXR" <> Rec."LSDX Print Voucher Loc." then begin
                    Rec."Print Voucher Loc._DXR" := Rec."LSDX Print Voucher Loc.";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyLSCPOSTerminalFields()
    var
        Rec: Record "LSC POS Terminal";
    begin
        if Rec.FindSet(true) then
            repeat
                if (Rec."No. Serie NCF Gubern._DXR" <> Rec."LSDXNo. Serie NCF Gubern.") or
                   (Rec."No. Serie NCF Reg. Esp._DXR" <> Rec."LSDXNo. Serie NCF Reg. Esp.") or
                   (Rec."No. Serie NCF Cred. Fiscal_DXR" <> Rec."LSDXNo. Serie NCF Cred. Fiscal") or
                   (Rec."Ext. Cmd. NCF Cr. Fiscal_DXR" <> Rec."LSDXExt. Cmd. NCF Cr. Fiscal") or
                   (Rec."External Cmd. NCF Guvern_DXR" <> Rec."LSDXExternal Cmd. NCF Guvern") or
                   (Rec."Ext. Cmd. NCF Reg. Esp._DXR" <> Rec."LSDXExt. Cmd. NCF Reg. Esp.") or
                   (Rec."No. Serie NCF Cons. Final_DXR" <> Rec."LSDXNo. Serie NCF Cons. Final") or
                   (Rec."Ext. Cmd. NCF Cons. Final_DXR" <> Rec."LSDXExt. Cmd. NCF Cons. Final") or
                   (Rec."NCF Nota de Credito_DXR" <> Rec."LSDXNCF Nota de Credito") or
                   (Rec."NCF Credito U. Final_DXR" <> Rec."LSDXNCF Credito U. Final") or
                   (Rec."NCF Credito Gubernamental_DXR" <> Rec."LSDXNCF Credito Gubernamental") or
                   (Rec."NCF Credito Reg Especiales_DXR" <> Rec."LSDXNCF Credito Reg Especiales") or
                   (Rec."Ext. Cmd. Nota de Credito_DXR" <> Rec."LSDXExt. Cmd. Nota de Credito")
                then begin
                    Rec."No. Serie NCF Gubern._DXR" := Rec."LSDXNo. Serie NCF Gubern.";
                    Rec."No. Serie NCF Reg. Esp._DXR" := Rec."LSDXNo. Serie NCF Reg. Esp.";
                    Rec."No. Serie NCF Cred. Fiscal_DXR" := Rec."LSDXNo. Serie NCF Cred. Fiscal";
                    Rec."Ext. Cmd. NCF Cr. Fiscal_DXR" := Rec."LSDXExt. Cmd. NCF Cr. Fiscal";
                    Rec."External Cmd. NCF Guvern_DXR" := Rec."LSDXExternal Cmd. NCF Guvern";
                    Rec."Ext. Cmd. NCF Reg. Esp._DXR" := Rec."LSDXExt. Cmd. NCF Reg. Esp.";
                    Rec."No. Serie NCF Cons. Final_DXR" := Rec."LSDXNo. Serie NCF Cons. Final";
                    Rec."Ext. Cmd. NCF Cons. Final_DXR" := Rec."LSDXExt. Cmd. NCF Cons. Final";
                    Rec."NCF Nota de Credito_DXR" := Rec."LSDXNCF Nota de Credito";
                    Rec."NCF Credito U. Final_DXR" := Rec."LSDXNCF Credito U. Final";
                    Rec."NCF Credito Gubernamental_DXR" := Rec."LSDXNCF Credito Gubernamental";
                    Rec."NCF Credito Reg Especiales_DXR" := Rec."LSDXNCF Credito Reg Especiales";
                    Rec."Ext. Cmd. Nota de Credito_DXR" := Rec."LSDXExt. Cmd. Nota de Credito";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyLSCSalesTypeFields()
    var
        Rec: Record "LSC Sales Type";
    begin
        if Rec.FindSet(true) then
            repeat
                if (Rec."Exento ITBIS_DXR" <> Rec."LSDX Exento ITBIS") or
                   (Rec."POS VAT Exento_DXR" <> Rec."LSDX POS VAT Exento")
                then begin
                    Rec."Exento ITBIS_DXR" := Rec."LSDX Exento ITBIS";
                    Rec."POS VAT Exento_DXR" := Rec."LSDX POS VAT Exento";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyLSCStoreFields()
    var
        Rec: Record "LSC Store";
    begin
        if Rec.FindSet(true) then
            repeat
                if (Rec."Cod. Cliente Contado_DXR" <> Rec."LSDX Cod. Cliente Contado") or
                   (Rec."No. Serie 3er. Party Item_DXR" <> Rec."LSDX No. Serie 3er. Party Item") or
                   (Rec."No. Serie NCF Unico_DXR" <> Rec."LSDX No. Serie NCF Unico") or
                   (Rec."No. Serie NCF Gubern._DXR" <> Rec."LSDX No. Serie NCF Gubern.") or
                   (Rec."No. Serie NCF Reg. Esp._DXR" <> Rec."LSDX No. Serie NCF Reg. Esp.") or
                   (Rec."No. Serie NCF Cr. Fiscal_DXR" <> Rec."LSDX No. Serie NCF Cr. Fiscal") or
                   (Rec."No. Serie NCF Cons. Final_DXR" <> Rec."LSDX No. Serie NCF Cons. Final") or
                   (Rec."Address 3_DXR" <> Rec."LSDX Address 3") or
                   (Rec."Utiliza NCF Unico_DXR" <> Rec."LSDX Utiliza NCF Unico")
                then begin
                    Rec."Cod. Cliente Contado_DXR" := Rec."LSDX Cod. Cliente Contado";
                    Rec."No. Serie 3er. Party Item_DXR" := Rec."LSDX No. Serie 3er. Party Item";
                    Rec."No. Serie NCF Unico_DXR" := Rec."LSDX No. Serie NCF Unico";
                    Rec."No. Serie NCF Gubern._DXR" := Rec."LSDX No. Serie NCF Gubern.";
                    Rec."No. Serie NCF Reg. Esp._DXR" := Rec."LSDX No. Serie NCF Reg. Esp.";
                    Rec."No. Serie NCF Cr. Fiscal_DXR" := Rec."LSDX No. Serie NCF Cr. Fiscal";
                    Rec."No. Serie NCF Cons. Final_DXR" := Rec."LSDX No. Serie NCF Cons. Final";
                    Rec."Address 3_DXR" := Rec."LSDX Address 3";
                    Rec."Utiliza NCF Unico_DXR" := Rec."LSDX Utiliza NCF Unico";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    // ===== In-scope MA same-table field-range restores (LSLOC-TOLOC seq2/5/13) =====
    // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
    // Field pairs confirmed against the real compiled symbols (LSLOC's own old/new TableExts) -
    // every source field below is ObsoleteState = Pending (not Removed), so it is still readable.

    local procedure CopyGenJournalLineFields()
    var
        Rec: Record "Gen. Journal Line";
    begin
        if Rec.FindSet(true) then
            repeat
                if Rec."No. Ticket_DXR" <> Rec."LSDX No. Ticket" then begin
                    Rec."No. Ticket_DXR" := Rec."LSDX No. Ticket";
                    Rec.Modify(false);
                    Commit();
                end;
            until Rec.Next() = 0;
    end;

    local procedure CopyItemFields()
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        Rec: Record Item;
        RecRef: RecordRef;
    begin
        if Rec.FindSet(true) then
            repeat
                RecRef.GetTable(Rec);
                if MasterFieldResolver.CopyFirstPopulatedField(RecRef, 'Factor_DXR', 'Factor') then
                    RecordChanged := true;
                PersistChangedRecord(RecRef);
            until Rec.Next() = 0;
        Commit();
        RowsSinceCommit := 0;
    end;

    local procedure CopyLSCStoreInventoryLineFields()
    var
        Rec: Record "LSC Store Inventory Line";
        RowsSinceLineCommit: Integer;
    begin
        if Rec.FindSet(true) then
            repeat
                if Rec."Recalculate Time_DXR" <> Rec."DX Recalculate Time" then begin
                    Rec."Recalculate Time_DXR" := Rec."DX Recalculate Time";
                    Rec.Modify(false);
                end;

                RowsSinceLineCommit += 1;
                if RowsSinceLineCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceLineCommit := 0;
                end;
            until Rec.Next() = 0;
        Commit();
    end;

    // ===== In-scope OTHER same-table field-range restores (LSLOC-TOLOC seq10/14) =====
    // Was previously RecordRef.Field(<literal field number>) over a numeric range - converted to
    // explicit name-based pairs (via the shared MCC Master Field Resolver) so it no longer depends
    // on the source/target fields staying at consecutive field numbers. Pairs confirmed against the
    // real compiled symbols (LS Central DR Localization's own "LSDX POS Transaction"/"LSDXTransaction
    // Header" (old) and "DXR_LS POS Transaction"/"DXR_LS Transaction Header" (new) tableextensions);
    // the two Enum fields on each table (Tipo Doc. Fiscal/Tipo Identificacion) are intentionally
    // excluded here - they are handled by MigratePOSTransactionEnumFields/
    // MigrateTransactionHeaderEnumFields, which convert between the distinct LSDX/DXR_LS enum types.
    local procedure CopyPOSTransactionOtherFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC POS Transaction");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'RNC/Cedula_DXR', 'LSDX RNC/Cedula');
                CopyFieldIfExists(RecRef, 'No. Serie NCF_DXR', 'LSDX No. Serie NCF');
                CopyFieldIfExists(RecRef, 'Razon Social_DXR', 'LSDX Razon Social');
                CopyFieldIfExists(RecRef, 'VAT Amount_DXR', 'LSDX VAT Amount');
                CopyFieldIfExists(RecRef, 'Nombre Cliente_DXR', 'LSDX Nombre Cliente');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure CopyTransactionHeaderOtherFields()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"LSC Transaction Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 'Tipo NCF_DXR', 'LSDXTipo NCF');
                CopyFieldIfExists(RecRef, 'NCF_DXR', 'LSDX NCF');
                CopyFieldIfExists(RecRef, 'NCF Afectado_DXR', 'LSDX NCF Afectado');
                CopyFieldIfExists(RecRef, 'Nombre_DXR', 'LSDX Nombre');
                CopyFieldIfExists(RecRef, 'RNC/Cedula_DXR', 'LSDX RNC/Cedula');
                CopyFieldIfExists(RecRef, 'NCF Unico_DXR', 'LSDX NCF Unico');
                CopyFieldIfExists(RecRef, 'NCF No Serie_DXR', 'LSDX NCF No Serie');
                CopyFieldIfExists(RecRef, 'NCF Unico Devolucion_DXR', 'LSDX NCF Unico Devolucion');
                CopyFieldIfExists(RecRef, 'No. Serie NCF_DXR', 'LSDX No. Serie NCF');
                CopyFieldIfExists(RecRef, 'Razon Social_DXR', 'LSDX Razon Social');
                CopyFieldIfExists(RecRef, 'Monto Propina_DXR', 'LSDX Monto Propina');
                CopyFieldIfExists(RecRef, 'No. Ticket_DXR', 'LSDX No. Ticket');
                CopyFieldIfExists(RecRef, 'Fecha Expiracion NCF_DXR', 'LSDX Fecha Expiracion NCF');
                CopyFieldIfExists(RecRef, 'Fiscal Printed_DXR', 'LSDX Fiscal Printed');
                CopyFieldIfExists(RecRef, 'Location Code_DXR', 'LSDX Location Code');
                PersistChangedRecord(RecRef);
            until RecRef.Next() = 0;
        FinishTable(RecRef);
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
    begin
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

    local procedure MigrateSameTableEnumFields()
    begin
        MigratePOSTerminalEnumFields();
        MigratePOSTransactionEnumFields();
        MigrateTransactionHeaderEnumFields();
    end;

    local procedure MigratePOSTerminalEnumFields()
    var
        POSTerminal: Record "LSC POS Terminal";
    begin
        if POSTerminal.FindSet(true) then
            repeat
                POSTerminal."Ext. POS Type_DXR" := Enum::"DXR_LS POS Type".FromInteger(POSTerminal."LSDXExt. POS Type".AsInteger());
                POSTerminal.Modify(false);
            until POSTerminal.Next() = 0;
    end;

    local procedure MigratePOSTransactionEnumFields()
    var
        POSTransaction: Record "LSC POS Transaction";
    begin
        if POSTransaction.FindSet(true) then
            repeat
                POSTransaction."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(POSTransaction."LSDX Tipo Doc. Fiscal".AsInteger());
                POSTransaction."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(POSTransaction."LSDX Tipo Identificacion".AsInteger());
                POSTransaction.Modify(false);
            until POSTransaction.Next() = 0;
    end;

    local procedure MigrateTransactionHeaderEnumFields()
    var
        TransactionHeader: Record "LSC Transaction Header";
    begin
        if TransactionHeader.FindSet(true) then
            repeat
                TransactionHeader."Tipo Doc. Fiscal_DXR" := Enum::"DXR_LS Fiscal Doc. Type".FromInteger(TransactionHeader."LSDX Tipo Doc. Fiscal".AsInteger());
                TransactionHeader."Tipo Identificacion_DXR" := Enum::"DXR_LS Fiscal Identity Type".FromInteger(TransactionHeader."LSDX Tipo Identificacion".AsInteger());
                TransactionHeader.Modify(false);
            until TransactionHeader.Next() = 0;
    end;

    // ===== "DXR_LS Legacy Tables Upgrade" (54511) =====

    local procedure LegacyTablesExecute()
    begin
        CopyLSDXPOSSetupToDXR(); // seq4, SETUP
        CopyLSDXTenderTypesRelationToDXR(); // seq21, SETUP
        CopyLSDXOPOSPrintSetupToDXR(); // seq22, SETUP
        CopyStandaloneTable(Database::"LSDX POS 607 Diagnostic", Database::"DXR_LS POS 607 Diagnostic"); // seq23, HIST - out of scope
        CopyStandaloneTable(Database::"LSDX LS NCF Process Reg.", Database::"DXR_LS NCF Process Reg."); // seq24, HIST - out of scope
    end;

    // ===== In-scope SETUP standalone legacy-table restores (LSLOC-TOLOC seq4/21/22) =====
    // Direct typed field assignment, one line per field - no RecordRef/FieldRef, no TransferFields.
    // Both source and target tables are LSLOC's own (or standard LSC-relation) tables, confirmed
    // NOT Access = Internal (no Access property on any of the six table objects). Field-by-field
    // mapping confirmed 1:1 by field number against the real compiled symbols (source field N ->
    // target field N, target name suffixed _DXR).

    local procedure CopyLSDXPOSSetupToDXR()
    var
        Source: Record "LSDX POS Setup";
        Target: Record "DXR_LS POS Setup";
        TargetExists: Boolean;
    begin
        if Source.FindSet() then
            repeat
                TargetExists := Target.Get(Source."Key");
                if not TargetExists then begin
                    Target.Init();
                    Target."Key_DXR" := Source."Key";
                end;
                Target."Withhold VAT Refund_DXR" := Source."Withhold VAT Refund";
                Target."VAT Bus. Posting Group_DXR" := Source."VAT Bus. Posting Group";
                Target."VAT Prod. Posting Group_DXR" := Source."VAT Prod. Posting Group";
                Target."Days Limit_DXR" := Source."Days Limit";
                Target."Sales Type_DXR" := Source."Sales Type";
                Target."Ventas Monto 0_DXR" := Source."Ventas Monto 0";
                Target."Infocode NC Manual_DXR" := Source."Infocode NC Manual";
                Target."NCManual_DXR" := Source.NCManual;
                Target."Validate Suspended Trans. POS_DXR" := Source."Validate Suspended Trans. POS";
                Target."Use POS Localization_DXR" := Source."Use POS Localization";
                Target."POS in USD_DXR" := Source."POS in USD";
                Target."Not Allow Print Z with Trans._DXR" := Source."Not Allow Print Z with Trans.";
                Target."Enable Automatic Replication_DXR" := Source."Enable Automatic Replication";
                Target."Show Qty. Tags on POS_DXR" := Source."Show Qty. Tags on POS";
                Target."Show Currency Conv. in ticket_DXR" := Source."Show Currency Conv. in ticket";
                Target."Show DX Copy Header_DXR" := Source."Show DX Copy Header";
                Target."Increase Company Name Header_DXR" := Source."Increase Company Name Header";
                Target."Customer NCF PRIO_DXR" := Source."Customer NCF PRIO";
                Target."Require RNC Fiscal Credit_DXR" := Source."Require RNC Fiscal Credit";
                Target."Block Blank Lines in Trans._DXR" := Source."Block Blank Lines in Trans.";
                Target."Validate Empty Customer Name_DXR" := Source."Validate Empty Customer Name";
                Target."Validate 607 Fields_DXR" := Source."Validate 607 Fields";
                Target."Encode QR Ampersand_DXR" := Source."Encode QR Ampersand";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    local procedure CopyLSDXTenderTypesRelationToDXR()
    var
        Source: Record "LSDXTender Types Relation";
        Target: Record "DXR_LS Tender Types Relation";
        TargetExists: Boolean;
    begin
        if Source.FindSet() then
            repeat
                TargetExists := Target.Get(Source.Code, Source."Tender Type Code");
                if not TargetExists then begin
                    Target.Init();
                    Target."Code_DXR" := Source.Code;
                    Target."Tender Type Code_DXR" := Source."Tender Type Code";
                end;
                Target.Description_DXR := Source.Description;
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    local procedure CopyLSDXOPOSPrintSetupToDXR()
    var
        Source: Record "LSDX OPOS Print Setup";
        Target: Record "DXR_LS OPOS Print Setup";
        TargetExists: Boolean;
    begin
        if Source.FindSet() then
            repeat
                TargetExists := Target.Get(Source."Key");
                if not TargetExists then begin
                    Target.Init();
                    Target."Key_DXR" := Source."Key";
                end;
                Target."Print NCF_DXR" := Source."Print NCF";
                Target."Print Company Name_DXR" := Source."Print Company Name";
                Target."Print Employee and Trans_DXR" := Source."Print Employee and Trans";
                Target."Print Cashier_DXR" := Source."Print Cashier";
                Target."Print Site Name_DXR" := Source."Print Site Name";
                Target."LineBreakInRNC_DXR" := Source."LineBreakInRNC";
                Target."Print Transaction Time_DXR" := Source."Print Transaction Time";
                Target."LineBreakCustomerName_DXR" := Source."LineBreakCustomerName";
                Target."Print Qty Footer_DXR" := Source."Print Qty Footer";
                Target."Print Staff Sales Person_DXR" := Source."Print Staff Sales Person";
                Target."Staff Sales Person Label_DXR" := Source."Staff Sales Person Label";
                if TargetExists then
                    Target.Modify(false)
                else
                    Target.Insert(false);
            until Source.Next() = 0;
    end;

    local procedure CopyStandaloneTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRef: RecordRef;
        TargetRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourceFieldRef: FieldRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        TargetExists: Boolean;
        AllKeyFieldsMapped: Boolean;
        BatchCount: Integer;
    begin
        SourceRef.Open(SourceTableId);
        TargetRef.Open(TargetTableId);
        SourceKeyRef := SourceRef.KeyIndex(1);

        if SourceRef.FindSet(false) then
            repeat
                TargetRef.Reset();
                AllKeyFieldsMapped := true;
                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
                    if TargetRef.FieldExist(SourcePkFieldRef.Name) then begin
                        TargetPkFieldRef := TargetRef.Field(SourcePkFieldRef.Name);
                        if SourcePkFieldRef.Type = TargetPkFieldRef.Type then
                            TargetPkFieldRef.SetRange(SourcePkFieldRef.Value)
                        else
                            AllKeyFieldsMapped := false;
                    end else
                        AllKeyFieldsMapped := false;
                end;

                TargetExists := AllKeyFieldsMapped and TargetRef.FindFirst();

                if not AllKeyFieldsMapped then begin
                    TargetRef.Close();
                    SourceRef.Close();
                    exit;
                end;
                if not TargetExists then
                    TargetRef.Init();

                for FieldIndex := 1 to SourceRef.FieldCount() do begin
                    SourceFieldRef := SourceRef.FieldIndex(FieldIndex);
                    if (SourceFieldRef.Number < 2000000000) and
                       (SourceFieldRef.Class = FieldClass::Normal) and
                       TargetRef.FieldExist(SourceFieldRef.Name)
                    then begin
                        TargetPkFieldRef := TargetRef.Field(SourceFieldRef.Name);
                        if (TargetPkFieldRef.Class = FieldClass::Normal) and
                           (SourceFieldRef.Type = TargetPkFieldRef.Type)
                        then
                            TargetPkFieldRef.Value := SourceFieldRef.Value;
                    end;
                end;

                if TargetExists then
                    TargetRef.Modify(false)
                else
                    TargetRef.Insert(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SourceRef.Next() = 0;

        TargetRef.Close();
        SourceRef.Close();
    end;

    var
        RecordChanged: Boolean;
        RowsSinceCommit: Integer;
}

#endif
