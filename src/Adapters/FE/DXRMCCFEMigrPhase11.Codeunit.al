codeunit 60140 "DXR MCC FE Migr Phase11"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 11 Tables".OnRun() (Access = Internal). 30 plain standalone-table restores
    // + 3 with custom merge logic (Archived Sent Request scoring-merge, Codigos Item/Currency Type
    // key-based upsert).
    //
    // Converted 2026-08-24 (Task A.4-FE, resumed): the 12 in-scope registry concepts (FE-P11
    // seq5/276/280/281/284/287/288/289/299/300/301/302) were routed through a generic
    // numeric-table-ID RecordRef/FieldRef helper (CopyStandaloneTable) or, for Currency Type
    // (seq276), a RecordRef source with typed target. Confirmed both the legacy "EF ..." tables
    // AND the new "DXR_..." tables live in Facturacion Electronica's OWN package (all
    // Access = Internal there - e.g. EFCurrencyType.Table.al:7 and Base\Tables\EFCurrencyType.
    // Table.al:7) and that FE grants MCC internalsVisibleTo (confirmed: MCC's app id
    // a5b9bf50-7945-4455-8df4-3be9c7431a7b is listed in
    // "Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\app.json"'s
    // internalsVisibleTo array) - unlike Phase7's DR-Localization-owned tables, no thin-wrapper
    // bridge codeunit is needed here: MCC can declare Record "EF ..."/"DXR_..." directly. Every
    // field pair below is confirmed against real source under
    // "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\old\Tables.old\"
    // (legacy) and "...\Base\Tables\" (new) - field numbers/names are identical on both sides for
    // all 12 pairs except Township (field names renamed, same field numbers - see
    // CopyTownshipFields) and 2 enum fields on Administration Setup (Provider, DXR_Voxel Mode -
    // structurally identical enums, confirmed by reading both enum sources, safe for
    // AsInteger()/FromInteger() round-trip). No "_Old"/"_Old2" shadow-field traps found for any of
    // the 12 in-scope tables - each "DXR_..." target confirmed as the sole non-obsolete
    // replacement.
    //
    // seq276 (EF Currency Type, "custom key-based merge" per the registry's own description):
    // investigated before rewriting - the original CopyCurrencyType() already implemented a
    // proper key-based upsert (Get-by-Id, Modify if found else Init+Insert), not a generic
    // TransferFields/field-blast. That semantics is preserved exactly in CopyCurrencyTypeFields()
    // below - only the RecordRef/FieldRef source access was replaced with a typed
    // Record "EF Currency Type".
    //
    // The remaining 18 CopyStandaloneTable(...) calls (EF Archived E Documents, Bulk Credit Memo
    // Entry/Log, Bulk NCF Import Entry, Descuentos O Recargos, Det. Bienes o Servicios, Encabezado,
    // Imp. Adicionales Encab./DBS, Informacion Referencia, Log Message, Process Request, Receipt
    // Acknowledgement, Resend Document Queue/Job Log, Response Documents, Subcantidad,
    // SubDescuento, SubRecargo, SubTotales Informativos) plus MigrateArchivedSentRequest() and
    // MigrateCodigosItem() have NO corresponding MCC registry row (confirmed by cross-checking
    // every CopyStandaloneTable/custom-merge call against the 12 FE-P11 registry rows) - out of
    // scope, left exactly as before (still generic RecordRef/FieldRef by numeric table ID),
    // matching this plan's established precedent (Phase7's "Applies Withholding_DXR" fill,
    // Phase8's Item fields) of leaving out-of-scope in-file code untouched.
    // Fixed 2026-08-27 (A3): the "EF ..." source tables that CopyStandaloneTable()/
    // MigrateArchivedSentRequest()/MigrateCodigosItem() open by numeric table ID through
    // RecordRef.Open() were missing from this block entirely - only the 12 typed ones were listed.
    // Permissionset 60000 "DXR MCC" grants no tabledata on foreign tables, so this property is the
    // only runtime access this codeunit has, and these phases run in the background under
    // TaskScheduler: every RecordRef.Open(555xx) read below would have failed with a missing-Read-
    // permission error. Added at R only - all of them are read-only sources (the targets already had
    // their RIMD entries).
    Permissions =
        tabledata "EF Administration Setup" = R,
        tabledata "EF Archived E Documents" = R,
        tabledata "EF Archived Sent Request" = R,
        tabledata "EF Bulk Credit Memo Entry" = R,
        tabledata "EF Bulk Credit Memo Log" = R,
        tabledata "EF Bulk NCF Import Entry" = R,
        tabledata "EF Codigos Item" = R,
        tabledata "EF Currency Type" = R,
        tabledata "EF Descuentos O Recargos" = R,
        tabledata "EF Detalle Bienes o Servicios" = R,
        tabledata "EF Encabezado" = R,
        tabledata "EF Imp. Adicionales - Encab." = R,
        tabledata "EF Impuestos Adicionales - DBS" = R,
        tabledata "EF Informacion Referencia" = R,
        tabledata "EF Log Message" = R,
        tabledata "EF Process Request" = R,
        tabledata "EF Receipt Acknowledgement" = R,
        tabledata "EF Resend Document Queue" = R,
        tabledata "EF Resend Job Log" = R,
        tabledata "EF Response Documents" = R,
        tabledata "EF Subcantidad" = R,
        tabledata "EF SubDescuento" = R,
        tabledata "EF SubRecargo" = R,
        tabledata "EF SubTotales Informativos" = R,
        tabledata "EF Formas de Pago" = R,
        tabledata "EF Form Type" = R,
        tabledata "EF Income Validation Type" = R,
        tabledata "EF Modification Code Type" = R,
        tabledata "EF Paginacion" = R,
        tabledata "EF Payment Type Form" = R,
        tabledata "EF Tax Coding Type" = R,
        tabledata "EF Telefono Emisor" = R,
        tabledata "EF Township" = R,
        tabledata "EF Unit of Measure Type" = R,
        tabledata "DXR_Administration Setup" = RIMD,
        tabledata "DXR_Archived E Documents" = RIMD,
        tabledata "DXR_Archived Sent Request" = RIMD,
        tabledata "DXR_Bulk Credit Memo Entry" = RIMD,
        tabledata "DXR_Bulk Credit Memo Log" = RIMD,
        tabledata "DXR_Bulk NCF Import Entry" = RIMD,
        tabledata "DXR_Codigos Item" = RIMD,
        tabledata "DXR_Currency Type" = RIMD,
        tabledata "DXR_Descuentos O Recargos" = RIMD,
        tabledata "DXR_Det. Bienes o Servicios" = RIMD,
        tabledata "DXR_Encabezado" = RIMD,
        tabledata "DXR_Formas de Pago" = RIMD,
        tabledata "DXR_Form Type" = RIMD,
        tabledata "DXR_Imp. Adicionales Encab." = RIMD,
        tabledata "DXR_Imp. Adicionales - DBS" = RIMD,
        tabledata "DXR_Income Validation Type" = RIMD,
        tabledata "DXR_Informacion Referencia" = RIMD,
        tabledata "DXR_Log Message" = RIMD,
        tabledata "DXR_Modification Code Type" = RIMD,
        tabledata "DXR_Paginacion" = RIMD,
        tabledata "DXR_Payment Type Form" = RIMD,
        tabledata "DXR_Process Request" = RIMD,
        tabledata "DXR_Receipt Acknowledgement" = RIMD,
        tabledata "DXR_Resend Document Queue" = RIMD,
        tabledata "DXR_Resend Job Log" = RIMD,
        tabledata "DXR_Response Documents" = RIMD,
        tabledata "DXR_Subcantidad" = RIMD,
        tabledata "DXR_SubDescuento" = RIMD,
        tabledata "DXR_SubRecargo" = RIMD,
        tabledata "DXR_SubTotales Informativos" = RIMD,
        tabledata "DXR_Tax Coding Type" = RIMD,
        tabledata "DXR_Telefono Emisor" = RIMD,
        tabledata "DXR_Township" = RIMD,
        tabledata "DXR_Unit of Measure Type" = RIMD;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625') then
            exit;

        MigrateStandaloneTables();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625');
    end;

    procedure RunSetup()
    begin
        CopyAdministrationSetupFields();
        CopyCurrencyTypeFields();
        CopyFormasDePagoFields();
        CopyFormTypeFields();
        CopyIncomeValidationTypeFields();
        CopyModificationCodeTypeFields();
        CopyPaginacionFields();
        CopyPaymentTypeFormFields();
        CopyTaxCodingTypeFields();
        CopyTelefonoEmisorFields();
        CopyTownshipFields();
        CopyUnitOfMeasureTypeFields();
    end;

    procedure RunMaster()
    begin
        MigrateCodigosItem();
    end;

    procedure RunAccounting()
    begin
        CopyStandaloneTable(55532, Database::"DXR_Bulk Credit Memo Entry");
        CopyStandaloneTable(55575, Database::"DXR_Bulk NCF Import Entry");
        CopyStandaloneTable(55506, Database::"DXR_Descuentos O Recargos");
        CopyStandaloneTable(55507, Database::"DXR_Det. Bienes o Servicios");
        CopyStandaloneTable(55508, Database::"DXR_Encabezado");
        CopyStandaloneTable(55510, Database::"DXR_Imp. Adicionales Encab.");
        CopyStandaloneTable(55511, Database::"DXR_Imp. Adicionales - DBS");
        CopyStandaloneTable(55513, Database::"DXR_Informacion Referencia");
        CopyStandaloneTable(55518, Database::"DXR_Process Request");
        CopyStandaloneTable(55531, Database::"DXR_Resend Document Queue");
        CopyStandaloneTable(55520, Database::"DXR_Response Documents");
        CopyStandaloneTable(55521, Database::"DXR_Subcantidad");
        CopyStandaloneTable(55522, Database::"DXR_SubDescuento");
        CopyStandaloneTable(55523, Database::"DXR_SubRecargo");
        CopyStandaloneTable(55524, Database::"DXR_SubTotales Informativos");
    end;

    procedure RunHistoric()
    begin
        CopyStandaloneTable(55502, Database::"DXR_Archived E Documents");
        MigrateArchivedSentRequest();
        CopyStandaloneTable(55533, Database::"DXR_Bulk Credit Memo Log");
        CopyStandaloneTable(55514, Database::"DXR_Log Message");
        CopyStandaloneTable(55519, Database::"DXR_Receipt Acknowledgement");
        CopyStandaloneTable(55530, Database::"DXR_Resend Job Log");
    end;

    local procedure MigrateStandaloneTables()
    begin
        CopyAdministrationSetupFields(); // seq5: EF Administration Setup (55501) -> DXR_Administration Setup (52468)
        CopyStandaloneTable(55502, Database::"DXR_Archived E Documents"); // EF Archived E Documents - out of scope
        MigrateArchivedSentRequest(); // EF Archived Sent Request (55503) -> DXR_Archived Sent Request - out of scope
        CopyStandaloneTable(55532, Database::"DXR_Bulk Credit Memo Entry"); // EF Bulk Credit Memo Entry - out of scope
        CopyStandaloneTable(55533, Database::"DXR_Bulk Credit Memo Log"); // EF Bulk Credit Memo Log - out of scope
        CopyStandaloneTable(55575, Database::"DXR_Bulk NCF Import Entry"); // EF Bulk NCF Import Entry - out of scope
        MigrateCodigosItem(); // EF Codigos Item (55504) -> DXR_Codigos Item - out of scope
        CopyCurrencyTypeFields(); // seq276: EF Currency Type (55505) -> DXR_Currency Type (52480), custom key-based merge
        CopyStandaloneTable(55506, Database::"DXR_Descuentos O Recargos"); // EF Descuentos O Recargos - out of scope
        CopyStandaloneTable(55507, Database::"DXR_Det. Bienes o Servicios"); // EF Detalle Bienes o Servicios - out of scope
        CopyStandaloneTable(55508, Database::"DXR_Encabezado"); // EF Encabezado - out of scope
        CopyFormasDePagoFields(); // seq280: EF Formas de Pago (55509) -> DXR_Formas de Pago (52485)
        CopyFormTypeFields(); // seq281: EF Form Type (55529) -> DXR_Form Type (52484)
        CopyStandaloneTable(55510, Database::"DXR_Imp. Adicionales Encab."); // EF Imp. Adicionales - Encab. - out of scope
        CopyStandaloneTable(55511, Database::"DXR_Imp. Adicionales - DBS"); // EF Impuestos Adicionales - DBS - out of scope
        CopyIncomeValidationTypeFields(); // seq284: EF Income Validation Type (55512) -> DXR_Income Validation Type (52488)
        CopyStandaloneTable(55513, Database::"DXR_Informacion Referencia"); // EF Informacion Referencia - out of scope
        CopyStandaloneTable(55514, Database::"DXR_Log Message"); // EF Log Message - out of scope
        CopyModificationCodeTypeFields(); // seq287: EF Modification Code Type (55515) -> DXR_Modification Code Type (52491)
        CopyPaginacionFields(); // seq288: EF Paginacion (55516) -> DXR_Paginacion (52492)
        CopyPaymentTypeFormFields(); // seq289: EF Payment Type Form (55517) -> DXR_Payment Type Form (52493)
        CopyStandaloneTable(55518, Database::"DXR_Process Request"); // EF Process Request - out of scope
        CopyStandaloneTable(55519, Database::"DXR_Receipt Acknowledgement"); // EF Receipt Acknowledgement - out of scope
        CopyStandaloneTable(55531, Database::"DXR_Resend Document Queue"); // EF Resend Document Queue - out of scope
        CopyStandaloneTable(55530, Database::"DXR_Resend Job Log"); // EF Resend Job Log - out of scope
        CopyStandaloneTable(55520, Database::"DXR_Response Documents"); // EF Response Documents - out of scope
        CopyStandaloneTable(55521, Database::"DXR_Subcantidad"); // EF Subcantidad - out of scope
        CopyStandaloneTable(55522, Database::"DXR_SubDescuento"); // EF SubDescuento - out of scope
        CopyStandaloneTable(55523, Database::"DXR_SubRecargo"); // EF SubRecargo - out of scope
        CopyStandaloneTable(55524, Database::"DXR_SubTotales Informativos"); // EF SubTotales Informativos - out of scope
        CopyTaxCodingTypeFields(); // seq299: EF Tax Coding Type (55525) -> DXR_Tax Coding Type (52505)
        CopyTelefonoEmisorFields(); // seq300: EF Telefono Emisor (55526) -> DXR_Telefono Emisor (52506)
        CopyTownshipFields(); // seq301: EF Township (55527) -> DXR_Township (52507)
        CopyUnitOfMeasureTypeFields(); // seq302: EF Unit of Measure Type (55528) -> DXR_Unit of Measure Type (52508)
    end;

    // seq5: EF Administration Setup (55501) -> DXR_Administration Setup (52468). 68 fields, 1:1
    // field numbers/names except field 16 "Provider" (enum type renamed EF Service Provider ->
    // DXR_Service Provider, identical ordinals 0=Ateb/1=Voxel/2=Rodaltech) and field 28 (name+enum
    // type renamed "EF Voxel Mode" -> "DXR_Voxel Mode", identical ordinals 0=None/1=Offline/
    // 2=Online). PK = "Primary Key".
    local procedure CopyAdministrationSetupFields()
    var
        Legacy: Record "EF Administration Setup";
        New: Record "DXR_Administration Setup";
        IsNewRecord: Boolean;
    begin
        if Legacy.FindSet() then
            repeat
                IsNewRecord := not New.Get(Legacy."Primary Key");
                if IsNewRecord then begin
                    New.Init();
                    New."Primary Key" := Legacy."Primary Key";
                end;
                New."Use Electronic Service" := Legacy."Use Electronic Service";
                New."Company ID" := Legacy."Company ID";
                New."User Name" := Legacy."User Name";
                New."URL Endpoint" := Legacy."URL Endpoint";
                New."User Password" := Legacy."User Password";
                New."Uses Internal 606" := Legacy."Uses Internal 606";
                New."Download Logs Exceptions" := Legacy."Download Logs Exceptions";
                New."Downloads Requests" := Legacy."Downloads Requests";
                New."Downloads Response" := Legacy."Downloads Response";
                New."Company ID Final Consumer" := Legacy."Company ID Final Consumer";
                New."Send File as XML" := Legacy."Send File as XML";
                New."DGII URL" := Legacy."DGII URL";
                New."DGII URL Final Consumer" := Legacy."DGII URL Final Consumer";
                New."Send file as DGII Format" := Legacy."Send file as DGII Format";
                New.Provider := Enum::"DXR_Service Provider".FromInteger(Legacy.Provider.AsInteger());
                New."URL de Envio (VOXEL)" := Legacy."URL de Envio (VOXEL)";
                New."URL de Consulta (VOXEL)" := Legacy."URL de Consulta (VOXEL)";
                New."Tiempo de Espera" := Legacy."Tiempo de Espera";
                New."Username(Voxel)" := Legacy."Username(Voxel)";
                New."Password(Voxel)" := Legacy."Password(Voxel)";
                New."Update Since" := Legacy."Update Since";
                New."Block None E-Document Posting" := Legacy."Block None E-Document Posting";
                New."Offline Signer URL Test(Voxel)" := Legacy."Offline Signer URL Test(Voxel)";
                New."Offline Signer URL Send(Voxel)" := Legacy."Offline Signer URL Send(Voxel)";
                New.PosID := Legacy.PosID;
                New.StoreId := Legacy.StoreId;
                New."DXR_Voxel Mode" := Enum::"DXR_Voxel Mode".FromInteger(Legacy."EF Voxel Mode".AsInteger());
                New."Validate VAT on Tax Ind." := Legacy."Validate VAT on Tax Ind.";
                New."Validate Tax Ind. Required" := Legacy."Validate Tax Ind. Required";
                New."Validate VAT % Match Ind." := Legacy."Validate VAT % Match Ind.";
                New."Validate Header Mand. Fields" := Legacy."Validate Header Mand. Fields";
                New."Validate Email Required" := Legacy."Validate Email Required";
                New."Send Buyer Email Blank" := Legacy."Send Buyer Email Blank";
                New."Send Municipality Blank" := Legacy."Send Municipality Blank";
                New."Send Buyer Phone Blank" := Legacy."Send Buyer Phone Blank";
                New."Validate Emisor Municipality" := Legacy."Validate Emisor Municipality";
                New."Validate Buyer Address" := Legacy."Validate Buyer Address";
                New."Validate Payment Terms" := Legacy."Validate Payment Terms";
                New."Validate Payment Method" := Legacy."Validate Payment Method";
                New."Send Emisor Municipality Blank" := Legacy."Send Emisor Municipality Blank";
                New."Send Buyer Address Blank" := Legacy."Send Buyer Address Blank";
                New."Update NCF Afectado on Replace" := Legacy."Update NCF Afectado on Replace";
                New."Mass NCF Assignment Enabled" := Legacy."Mass NCF Assignment Enabled";
                New."Mass Resend Enabled" := Legacy."Mass Resend Enabled";
                New."Enable Indicator Override" := Legacy."Enable Indicator Override";
                New."Rodaltech URL Endpoint" := Legacy."Rodaltech URL Endpoint";
                New."Rodaltech User Name" := Legacy."Rodaltech User Name";
                New."Rodaltech User Password" := Legacy."Rodaltech User Password";
                New."Rodaltech Company ID" := Legacy."Rodaltech Company ID";
                New."Rodaltech Company ID Final" := Legacy."Rodaltech Company ID Final";
                New."Send Payment Terms Blank" := Legacy."Send Payment Terms Blank";
                New."Enable Date Override" := Legacy."Enable Date Override";
                New."Skip SubTotales Informativos" := Legacy."Skip SubTotales Informativos";
                New."Max Diagnostic Payload Chars" := Legacy."Max Diagnostic Payload Chars";
                New."Diagnostic Retention Days" := Legacy."Diagnostic Retention Days";
                New."Enable Integration Telemetry" := Legacy."Enable Integration Telemetry";
                New."Enable XML Sending Module" := Legacy."Enable XML Sending Module";
                New."Blank E32 Email Below Limit" := Legacy."Blank E32 Email Below Limit";
                New."Auto Reconcile Unknown Sends" := Legacy."Auto Reconcile Unknown Sends";
                New."Reconciliation Retry Minutes" := Legacy."Reconciliation Retry Minutes";
                New."Reconciliation Max Attempts" := Legacy."Reconciliation Max Attempts";
                New."Required Not Found Confirms" := Legacy."Required Not Found Confirms";
                New."Allow Manual Reconciliation" := Legacy."Allow Manual Reconciliation";
                New."ATEB Immediate Reconciliation" := Legacy."ATEB Immediate Reconciliation";
                New."ATEB Immediate Query Attempts" := Legacy."ATEB Immediate Query Attempts";
                New."Recover Original NCF Conflict" := Legacy."Recover Original NCF Conflict";
                New."Allow Alternate NCF Fallback" := Legacy."Allow Alternate NCF Fallback";
                if IsNewRecord then
                    New.Insert(false)
                else
                    New.Modify(false);
            until Legacy.Next() = 0;
    end;

    // seq276: EF Currency Type (55505) -> DXR_Currency Type (52480). "Custom key-based merge" per
    // the registry description - preserves the original CopyCurrencyType()'s exact semantics
    // (Get-by-Id upsert: Modify if the target row already exists, else Init+Insert), only the
    // source access is now typed instead of RecordRef/FieldRef.
    local procedure CopyCurrencyTypeFields()
    var
        Legacy: Record "EF Currency Type";
        New: Record "DXR_Currency Type";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq280: EF Formas de Pago (55509) -> DXR_Formas de Pago (52485). PK = (DocumentNo, FormaPago).
    local procedure CopyFormasDePagoFields()
    var
        Legacy: Record "EF Formas de Pago";
        New: Record "DXR_Formas de Pago";
        IsNewRecord: Boolean;
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A4): "EF Formas de Pago" holds one row per payment form per document, so
        // this loop is of unbounded volume and used to run as one single uncommitted transaction.
        // Bounded Commit every 100 upserted rows (plus the remainder), the same batch size
        // CopyStandaloneTable() in this codeunit already uses for the same category of table.
        if Legacy.FindSet() then
            repeat
                IsNewRecord := not New.Get(Legacy.DocumentNo, Legacy.FormaPago);
                if IsNewRecord then begin
                    New.Init();
                    New.DocumentNo := Legacy.DocumentNo;
                    New.FormaPago := Legacy.FormaPago;
                end;
                New.MontoPago := Legacy.MontoPago;
                New."Line No." := Legacy."Line No.";
                New.isPosTrans := Legacy.isPosTrans;
                if IsNewRecord then
                    New.Insert(false)
                else
                    New.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Legacy.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    // seq281: EF Form Type (55529) -> DXR_Form Type (52484). PK = (DocumentNo, FormaPago, "Line No.").
    local procedure CopyFormTypeFields()
    var
        Legacy: Record "EF Form Type";
        New: Record "DXR_Form Type";
        IsNewRecord: Boolean;
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A4): one row per payment-form line per document - same unbounded-volume
        // reason and same bounded Commit as CopyFormasDePagoFields above.
        if Legacy.FindSet() then
            repeat
                IsNewRecord := not New.Get(Legacy.DocumentNo, Legacy.FormaPago, Legacy."Line No.");
                if IsNewRecord then begin
                    New.Init();
                    New.DocumentNo := Legacy.DocumentNo;
                    New.FormaPago := Legacy.FormaPago;
                    New."Line No." := Legacy."Line No.";
                end;
                New.MontoPago := Legacy.MontoPago;
                New.isPosTrans := Legacy.isPosTrans;
                if IsNewRecord then
                    New.Insert(false)
                else
                    New.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Legacy.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    // seq284: EF Income Validation Type (55512) -> DXR_Income Validation Type (52488). PK = Id.
    local procedure CopyIncomeValidationTypeFields()
    var
        Legacy: Record "EF Income Validation Type";
        New: Record "DXR_Income Validation Type";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq287: EF Modification Code Type (55515) -> DXR_Modification Code Type (52491). PK = Id.
    local procedure CopyModificationCodeTypeFields()
    var
        Legacy: Record "EF Modification Code Type";
        New: Record "DXR_Modification Code Type";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq288: EF Paginacion (55516) -> DXR_Paginacion (52492). PK = (DocumentNo, PaginaNo). Field
    // numbering has a confirmed gap at 13 on both sides (no field 13 exists) - not a shadow field,
    // just an unused number, matches source exactly.
    local procedure CopyPaginacionFields()
    var
        Legacy: Record "EF Paginacion";
        New: Record "DXR_Paginacion";
        IsNewRecord: Boolean;
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A4): one row per printed page per document - same unbounded-volume reason
        // and same bounded Commit as CopyFormasDePagoFields above.
        if Legacy.FindSet() then
            repeat
                IsNewRecord := not New.Get(Legacy.DocumentNo, Legacy.PaginaNo);
                if IsNewRecord then begin
                    New.Init();
                    New.DocumentNo := Legacy.DocumentNo;
                    New.PaginaNo := Legacy.PaginaNo;
                end;
                New.NoLineaDesde := Legacy.NoLineaDesde;
                New.NoLineaHasta := Legacy.NoLineaHasta;
                New.SubtotalMontoGravadoPagina := Legacy.SubtotalMontoGravadoPagina;
                New.SubtotalMontoGravado1Pagina := Legacy.SubtotalMontoGravado1Pagina;
                New.SubtotalMontoGravado2Pagina := Legacy.SubtotalMontoGravado2Pagina;
                New.SubtotalMontoGravado3Pagina := Legacy.SubtotalMontoGravado3Pagina;
                New.SubtotalExentoPagina := Legacy.SubtotalExentoPagina;
                New.SubtotalItbisPagina := Legacy.SubtotalItbisPagina;
                New.SubtotalItbis1Pagina := Legacy.SubtotalItbis1Pagina;
                New.SubtotalItbis2Pagina := Legacy.SubtotalItbis2Pagina;
                New.SubtotalItbis3Pagina := Legacy.SubtotalItbis3Pagina;
                New."Subto. Imp. Selec. Cons EspPag" := Legacy."Subto. Imp. Selec. Cons EspPag";
                New.SubtotalOtrosImpuesto := Legacy.SubtotalOtrosImpuesto;
                New.MontoSubtotalPagina := Legacy.MontoSubtotalPagina;
                New."Subto. Monto no Fact. Pag" := Legacy."Subto. Monto no Fact. Pag";
                if IsNewRecord then
                    New.Insert(false)
                else
                    New.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Legacy.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    // seq289: EF Payment Type Form (55517) -> DXR_Payment Type Form (52493). PK = Id.
    local procedure CopyPaymentTypeFormFields()
    var
        Legacy: Record "EF Payment Type Form";
        New: Record "DXR_Payment Type Form";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq299: EF Tax Coding Type (55525) -> DXR_Tax Coding Type (52505). PK = Id.
    local procedure CopyTaxCodingTypeFields()
    var
        Legacy: Record "EF Tax Coding Type";
        New: Record "DXR_Tax Coding Type";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // seq300: EF Telefono Emisor (55526) -> DXR_Telefono Emisor (52506). PK = (DocumentNo, TelefonoEmisor).
    local procedure CopyTelefonoEmisorFields()
    var
        Legacy: Record "EF Telefono Emisor";
        New: Record "DXR_Telefono Emisor";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A4): one row per emitter phone per document - same unbounded-volume reason
        // and same bounded Commit as CopyFormasDePagoFields above. The counter advances per INSERTED
        // row only, since rows that already exist on the target are left untouched.
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.DocumentNo, Legacy.TelefonoEmisor) then begin
                    New.Init();
                    New.DocumentNo := Legacy.DocumentNo;
                    New.TelefonoEmisor := Legacy.TelefonoEmisor;
                    New.Insert(false);

                    BatchCount += 1;
                    if BatchCount >= 100 then begin
                        Commit();
                        BatchCount := 0;
                    end;
                end;
            until Legacy.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    // seq301: EF Township (55527) -> DXR_Township (52507). Field NAMES renamed on the target
    // ("EF Township Code" -> "Township Code_DXR", "EF Township Description" ->
    // "Township Description_DXR", "EF County Code" -> "County Code_DXR", "EF County Description"
    // -> "County Description_DXR"), field numbers unchanged (1/2/3/4) - confirmed via
    // EFTownship.Table.al (legacy) vs Base\Tables\EFTownship.Table.al (new). PK legacy =
    // ("EF Township Code", "EF County Code") -> new PK = ("Township Code_DXR", "County Code_DXR").
    local procedure CopyTownshipFields()
    var
        Legacy: Record "EF Township";
        New: Record "DXR_Township";
        IsNewRecord: Boolean;
    begin
        if Legacy.FindSet() then
            repeat
                IsNewRecord := not New.Get(Legacy."EF Township Code", Legacy."EF County Code");
                if IsNewRecord then begin
                    New.Init();
                    New."Township Code_DXR" := Legacy."EF Township Code";
                    New."County Code_DXR" := Legacy."EF County Code";
                end;
                New."Township Description_DXR" := Legacy."EF Township Description";
                New."County Description_DXR" := Legacy."EF County Description";
                if IsNewRecord then
                    New.Insert(false)
                else
                    New.Modify(false);
            until Legacy.Next() = 0;
    end;

    // seq302: EF Unit of Measure Type (55528) -> DXR_Unit of Measure Type (52508). PK = Id.
    local procedure CopyUnitOfMeasureTypeFields()
    var
        Legacy: Record "EF Unit of Measure Type";
        New: Record "DXR_Unit of Measure Type";
    begin
        if Legacy.FindSet() then
            repeat
                if New.Get(Legacy.Id) then begin
                    New.Description := Legacy.Description;
                    New.Modify(false);
                end else begin
                    New.Init();
                    New.Id := Legacy.Id;
                    New.Description := Legacy.Description;
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    // Generic standalone-table reconciliation used by the remaining FE-P11 table pairs. Tables
    // are opened by object ID, but primary keys and stored values are matched by exact field name
    // and type; field IDs are never used to infer cross-table identity.
    local procedure CopyStandaloneTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        TargetExists: Boolean;
        AllKeyFieldsMapped: Boolean;
        BatchCount: Integer;
    begin
        SourceRecordRef.Open(SourceTableId);
        TargetRecordRef.Open(TargetTableId);

        SourceKeyRef := SourceRecordRef.KeyIndex(1);

        if SourceRecordRef.FindSet(false) then
            repeat
                TargetRecordRef.Reset();
                AllKeyFieldsMapped := true;

                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
                    if TargetRecordRef.FieldExist(SourcePkFieldRef.Name) then begin
                        TargetPkFieldRef := TargetRecordRef.Field(SourcePkFieldRef.Name);
                        if SourcePkFieldRef.Type = TargetPkFieldRef.Type then
                            TargetPkFieldRef.SetRange(SourcePkFieldRef.Value)
                        else
                            AllKeyFieldsMapped := false;
                    end else
                        AllKeyFieldsMapped := false;
                end;

                TargetExists := AllKeyFieldsMapped and TargetRecordRef.FindFirst();

                if not AllKeyFieldsMapped then begin
                    TargetRecordRef.Close();
                    SourceRecordRef.Close();
                    exit;
                end;

                if TargetExists then begin
                    for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
                        SourceFieldRef := SourceRecordRef.FieldIndex(FieldIndex);

                        if (SourceFieldRef.Number < 2000000000) and
                           (SourceFieldRef.Class = FieldClass::Normal) and
                           TargetRecordRef.FieldExist(SourceFieldRef.Name)
                        then begin
                            TargetFieldRef := TargetRecordRef.Field(SourceFieldRef.Name);

                            if (TargetFieldRef.Class = FieldClass::Normal) and
                               (SourceFieldRef.Type = TargetFieldRef.Type)
                            then
                                TargetFieldRef.Value := SourceFieldRef.Value;
                        end;
                    end;

                    TargetRecordRef.Modify(false);
                end else begin
                    TargetRecordRef.Init();

                    for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
                        SourceFieldRef := SourceRecordRef.FieldIndex(FieldIndex);

                        if (SourceFieldRef.Number < 2000000000) and
                           (SourceFieldRef.Class = FieldClass::Normal) and
                           TargetRecordRef.FieldExist(SourceFieldRef.Name)
                        then begin
                            TargetFieldRef := TargetRecordRef.Field(SourceFieldRef.Name);

                            if (TargetFieldRef.Class = FieldClass::Normal) and
                               (SourceFieldRef.Type = TargetFieldRef.Type)
                            then
                                TargetFieldRef.Value := SourceFieldRef.Value;
                        end;
                    end;

                    TargetRecordRef.Insert(false);
                end;

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SourceRecordRef.Next() = 0;

        TargetRecordRef.Close();
        SourceRecordRef.Close();
    end;

    local procedure MigrateArchivedSentRequest()
    var
        TargetArchivedSentRequest: Record "DXR_Archived Sent Request";
        SourceRef: RecordRef;
        DocumentNoFld, DocumentSourceTypeFld, ENCFFld, PostingDateFld, DocumentStatusFld, CodeFld : FieldRef;
        EFCTrackIDFld, EFCTypeFld, SourceCodeTypeFld, RequestTypeFld, SecurityCodeFld : FieldRef;
        StampedDateFld, SignedDateFld, XMLFileFld, ProviderFld : FieldRef;
        BatchCount: Integer;
    begin
        SourceRef.Open(55503); // EF Archived Sent Request
        if SourceRef.FindSet(false) then
            repeat
                DocumentNoFld := ResolveField(SourceRef, 'Document No.');
                DocumentSourceTypeFld := ResolveField(SourceRef, 'Document Source Type');

                if TargetArchivedSentRequest.Get(DocumentNoFld.Value(), DocumentSourceTypeFld.Value()) then begin
                    if ShouldReplaceArchivedSentRequest(SourceRef, TargetArchivedSentRequest) then begin
                        TargetArchivedSentRequest.Delete(false);
                        InsertArchivedSentRequest(SourceRef);
                    end;
                end else
                    InsertArchivedSentRequest(SourceRef);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;

    local procedure InsertArchivedSentRequest(var SourceRef: RecordRef)
    var
        TargetArchivedSentRequest: Record "DXR_Archived Sent Request";
        TargetRef: RecordRef;
        DocumentNoFld, DocumentSourceTypeFld, ENCFFld, PostingDateFld, DocumentStatusFld, CodeFld : FieldRef;
        EFCTrackIDFld, EFCTypeFld, SourceCodeTypeFld, RequestTypeFld, SecurityCodeFld : FieldRef;
        StampedDateFld, SignedDateFld, XMLFileFld, TargetXMLFileFld : FieldRef;
    begin
        DocumentNoFld := ResolveField(SourceRef, 'Document No.');
        DocumentSourceTypeFld := ResolveField(SourceRef, 'Document Source Type');
        ENCFFld := ResolveField(SourceRef, 'e-NCF');
        PostingDateFld := ResolveField(SourceRef, 'Posting Date');
        DocumentStatusFld := ResolveField(SourceRef, 'Document Status');
        CodeFld := ResolveField(SourceRef, 'Code');
        EFCTrackIDFld := ResolveField(SourceRef, 'EFC Track ID');
        EFCTypeFld := ResolveField(SourceRef, 'EFC Type');
        SourceCodeTypeFld := ResolveField(SourceRef, 'EF Source Code Type');
        RequestTypeFld := ResolveField(SourceRef, 'EF Request Type');
        SecurityCodeFld := ResolveField(SourceRef, 'Security Code');
        StampedDateFld := ResolveField(SourceRef, 'Stamped Date');
        SignedDateFld := ResolveField(SourceRef, 'Signed Date');
        XMLFileFld := ResolveField(SourceRef, 'XML File');

        TargetArchivedSentRequest.Init();
        TargetArchivedSentRequest."Document No." := DocumentNoFld.Value();
        TargetArchivedSentRequest."Document Source Type" := DocumentSourceTypeFld.Value();
        TargetArchivedSentRequest."e-NCF" := ENCFFld.Value();
        TargetArchivedSentRequest."Posting Date" := PostingDateFld.Value();
        TargetArchivedSentRequest."Document Status" := DocumentStatusFld.Value();
        TargetArchivedSentRequest.Code := CodeFld.Value();
        TargetArchivedSentRequest."EFC Track ID" := EFCTrackIDFld.Value();
        TargetArchivedSentRequest."EFC Type" := Enum::"DXR_ecfType Basic".FromInteger(GetVariantAsInteger(EFCTypeFld.Value()));
        TargetArchivedSentRequest."DXR_Source Code Type" := Enum::"DXR_Source Code Type".FromInteger(GetVariantAsInteger(SourceCodeTypeFld.Value()));
        TargetArchivedSentRequest."EF Request Type" := Enum::"DXR_Request Status Type".FromInteger(GetVariantAsInteger(RequestTypeFld.Value()));
        TargetArchivedSentRequest."Security Code" := SecurityCodeFld.Value();
        TargetArchivedSentRequest."Stamped Date" := StampedDateFld.Value();
        TargetArchivedSentRequest."Signed Date" := SignedDateFld.Value();
        TargetArchivedSentRequest.Insert(false);

        // BLOB fields copy via plain FieldRef.Value assignment (same mechanism
        // CopyStandaloneTable already uses for every field, BLOBs included) rather than explicit
        // stream APIs, which this AL/compiler version does not expose on FieldRef.
        TargetRef.GetTable(TargetArchivedSentRequest);
        TargetXMLFileFld := ResolveField(TargetRef, 'XML File');
        TargetXMLFileFld.Value := XMLFileFld.Value;
        TargetRef.Modify(false);
    end;

    local procedure HasBlobValue(var SourceRef: RecordRef; BlobFieldName: Text): Boolean
    var
        BlobFld: FieldRef;
    begin
        BlobFld := ResolveField(SourceRef, BlobFieldName);
        exit(BlobFld.Length() > 0);
    end;

    // Name-based FieldRef resolution (never bare numeric field IDs) via the shared
    // "DXR MCC Master Field Resolver" codeunit's metadata loop - same mechanism
    // CopyStandaloneTable() already uses through TargetRecordRef.FieldExist/.Field(Name).
    // Errors loudly instead of silently binding to a differently-numbered field if the
    // expected field name is missing (e.g. renamed/removed upstream).
    local procedure ResolveField(var RecRef: RecordRef; FieldName: Text): FieldRef
    var
        MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
        ResolvedField: FieldRef;
    begin
        if not MasterFieldResolver.TryResolveFieldByName(RecRef, FieldName, ResolvedField) then
            Error('Field "%1" was not found on table %2 while migrating FE Phase 11 data.', FieldName, RecRef.Number());
        exit(ResolvedField);
    end;

    local procedure GetVariantAsInteger(Value: Variant): Integer
    var
        Result: Integer;
    begin
        Result := Value;
        exit(Result);
    end;

    local procedure ShouldReplaceArchivedSentRequest(var SourceRef: RecordRef; var TargetArchivedSentRequest: Record "DXR_Archived Sent Request"): Boolean
    var
        SourceScore: Integer;
        TargetScore: Integer;
        StampedDateFld, PostingDateFld : FieldRef;
        SourceStampedDate: Date;
        SourcePostingDate: Date;
    begin
        SourceScore := GetArchivedSentRequestScore(SourceRef);
        TargetScore := GetArchivedSentRequestScoreTarget(TargetArchivedSentRequest);
        if SourceScore <> TargetScore then
            exit(SourceScore > TargetScore);

        StampedDateFld := ResolveField(SourceRef, 'Stamped Date');
        SourceStampedDate := StampedDateFld.Value();
        if SourceStampedDate <> TargetArchivedSentRequest."Stamped Date" then
            exit(SourceStampedDate > TargetArchivedSentRequest."Stamped Date");

        PostingDateFld := ResolveField(SourceRef, 'Posting Date');
        SourcePostingDate := PostingDateFld.Value();
        exit(SourcePostingDate > TargetArchivedSentRequest."Posting Date");
    end;

    local procedure GetArchivedSentRequestScore(var SourceRef: RecordRef): Integer
    var
        SecurityCodeFld, EFCTrackIDFld, SignedDateFld : FieldRef;
        StampedDateFld: FieldRef;
        SecurityCode: Text;
        EFCTrackID: Text;
        SignedDate: Text;
        StampedDate: Date;
        Score: Integer;
    begin
        SecurityCodeFld := ResolveField(SourceRef, 'Security Code');
        EFCTrackIDFld := ResolveField(SourceRef, 'EFC Track ID');
        SignedDateFld := ResolveField(SourceRef, 'Signed Date');
        StampedDateFld := ResolveField(SourceRef, 'Stamped Date');

        SecurityCode := SecurityCodeFld.Value();
        EFCTrackID := EFCTrackIDFld.Value();
        SignedDate := SignedDateFld.Value();
        StampedDate := StampedDateFld.Value();

        if SecurityCode <> '' then
            Score += 1;
        if EFCTrackID <> '' then
            Score += 1;
        if SignedDate <> '' then
            Score += 1;
        if StampedDate <> 0D then
            Score += 1;
        if HasBlobValue(SourceRef, 'XML File') then
            Score += 1;

        exit(Score);
    end;

    local procedure GetArchivedSentRequestScoreTarget(var ArchivedSentRequest: Record "DXR_Archived Sent Request"): Integer
    var
        Score: Integer;
    begin
        ArchivedSentRequest.CalcFields("XML File");

        if ArchivedSentRequest."Security Code" <> '' then
            Score += 1;
        if ArchivedSentRequest."EFC Track ID" <> '' then
            Score += 1;
        if ArchivedSentRequest."Signed Date" <> '' then
            Score += 1;
        if ArchivedSentRequest."Stamped Date" <> 0D then
            Score += 1;
        if ArchivedSentRequest."XML File".HasValue() then
            Score += 1;

        exit(Score);
    end;

    local procedure MigrateCodigosItem()
    var
        TargetCodigosItem: Record "DXR_Codigos Item";
        SourceRef: RecordRef;
        TipoCodigoFld, CodigoItemFld, DocumentNoFld, DocumentLineNoFld : FieldRef;
    begin
        TargetCodigosItem.DeleteAll(false);

        SourceRef.Open(55504); // EF Codigos Item
        if SourceRef.FindSet() then
            repeat
                DocumentNoFld := ResolveField(SourceRef, 'DocumentNo');
                DocumentLineNoFld := ResolveField(SourceRef, 'DocumentLineNo');

                if not TargetCodigosItem.Get(DocumentNoFld.Value(), DocumentLineNoFld.Value()) then begin
                    TipoCodigoFld := ResolveField(SourceRef, 'TipoCodigo');
                    CodigoItemFld := ResolveField(SourceRef, 'CodigoItem');

                    TargetCodigosItem.Init();
                    TargetCodigosItem.DocumentNo := DocumentNoFld.Value();
                    TargetCodigosItem.DocumentLineNo := DocumentLineNoFld.Value();
                    TargetCodigosItem.TipoCodigo := TipoCodigoFld.Value();
                    TargetCodigosItem.CodigoItem := CodigoItemFld.Value();
                    TargetCodigosItem.Insert(false);
                end;
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;
}
