codeunit 60165 "DXR MCC DRLOC Migr Phase2"
{
    // Native local migration - ported verbatim (typed, no RecordRef/FieldRef/TransferFields) from
    // DR-Localization own "DXR_Internal Closure Migration" codeunit
    // (src\Base\Codeunits\Uprade\DXR_Internal_Closure_Migration_Upgrade_Clean.al), which currently
    // only runs from DR-Localization own background TaskScheduler dispatcher. This codeunit lets
    // MCC run the same 13 field-copy procedures itself, without depending on DR-Localization own
    // dispatcher. DR-Localization own internalsVisibleTo already grants MCC app ID, so every table
    // below (both the legacy "Dx"/"DX"-prefixed side and the "_DXR"-suffixed target side) is
    // declared as a typed Record directly, matching the pattern already proven by
    // "DXR MCC Adapt DRLOC PmtMethod" (60164).
    //
    // Registry rows (DXRMCCRegistryLoader.Codeunit.al, DRLOC-P2 seq9/10/11) are repointed from the
    // generic forwarding adapter (60069, "DXR MCC Adapt DRLOC Dispatch") to this codeunit as part
    // of the same change that adds this file.
    //
    // Shadow-field check (2026-08-24): every destination field in all 13 ported procedures was
    // independently verified against DR-Localization real tableextension sources
    // (DXR_CustomerExt.TableExt.al, DXR_VendorExt.TableExt.Al, DXR_BankAccountExt.TableExt.al,
    // DXR_CompanyInformationExt.TableExt.al, DXR_CustomerTempl.TableExt.al,
    // DXR_UserSetupExt.TableExt.al, DXR_NoSeriesLineExt.TableExt.al, DXR_GenJournalTemplate.TableExt.al,
    // DXR_GenJournalBatchExt.TableExt.Al, DXR_WorkflowStepArgument.TableExt.al,
    // DXR_VATProductPostingGroupTablExt.TableExt.al) - full field-by-field coverage on Customer and
    // Vendor per this task elevated master-data rigor requirement. All "_DXR" fields confirmed to
    // be the true, non-obsoleted final target (no ObsoleteState); all legacy "Dx"/"DX" source fields
    // confirmed ObsoleteState = Pending (still readable, safe migration source).
    //
    // One real bug found and fixed while porting (not a shadow-field issue - the target field is
    // correct, but the source own procedure never copies it): DR-Localization real
    // MigrateFields_Customer() checks "Apply Cust Withhold_DXR" against
    // "DX Apply Customer Withholding" in its dirty-check condition (added 2026-08-22 per that
    // procedure own comment) but never actually assigns the field in the following if-block - the
    // 20th condition has no matching 20th assignment. Both fields are confirmed real, non-FlowField
    // Enum fields on Customer (field 51831 for the target "_DXR" field): the target enum is
    // "DXR_ApplyCustomerWithholding" (52201, current, not obsolete) and the legacy source enum is
    // "DXApplyCustomerWithholding" (54203, ObsoleteState = Pending). This port adds the missing
    // assignment so the ported version actually does what the dirty-check condition promises;
    // DR-Localization own source is left unmodified (out of scope - this MCC repo only).
    //
    // "GLAccount" (part of seq11) is a deliberate no-op, matching DR-Localization own source: both
    // "DXNCF" and "NCF_DXR" on G/L Account are ObsoleteState = Removed (confirmed against
    // DXR_GLAccountExt.TableExt.al) - nothing left to migrate for that table via this procedure.
    // (G/L Account still-active "DXNCF Categories" -> "NCFCategories_DXR" field is a different,
    // already-tracked registry row, DRLOC-P2 seq105 - out of scope here.)
    //
    // Upgrade Tag reuse (2026-08-24, review fix): every one of the 13 procedures below is gated by
    // DR-Localization's OWN real per-procedure completion tag, copied verbatim (as literals, not a
    // runtime call into DRLOC's codeunit) from DXR_UpgradeTagMgt.Codeunit.al
    // (UpgradeTagInternalClosureFields<X>() for each table) - same rationale and pattern already
    // documented in DXRMCCBellonMigrPhase2.Codeunit.al's own header: reusing the sibling's own exact
    // tag strings means a tenant that already ran this migration via the old bridge path (registry
    // rows seq9/10/11 previously pointed at codeunit 60069, which called into DRLOC's own real
    // dispatcher, codeunit 52208) is correctly recognized as already done and this codeunit's first
    // run after cutover skips the redundant FindSet(true) scan on every table, instead of treating
    // every tenant as if none of this had ever run. Not a data-integrity risk either way (each
    // procedure's own dirty-check before Modify makes a redundant scan safe), but avoiding it matters
    // more for later DRLOC batches that touch Ledger Entry-scale tables. The Customer tag
    // (...-CUSTOMER-20260522-V2) is DRLOC's own already-bumped V2 tag, which happens to exist
    // specifically because DRLOC's own team found the same "Apply Cust Withhold_DXR" gap documented
    // above and bumped the tag to force a re-run - reusing it here is exactly correct, not a
    // coincidence. All 13 tags below were confirmed to exist as real procedures in
    // DXR_UpgradeTagMgt.Codeunit.al; none needed to be invented.
    Permissions =
        tabledata "Company Information" = RM,
        tabledata "Bank Account" = RM,
        tabledata Customer = RM,
        tabledata "Customer Templ." = RM,
        tabledata Vendor = RM,
        tabledata "User Setup" = RM,
        tabledata "No. Series Line" = RM,
        tabledata "Gen. Journal Template" = RM,
        tabledata "Gen. Journal Batch" = RM,
        tabledata "Workflow Step Argument" = RM,
        tabledata "VAT Product Posting Group" = RM,
        tabledata "DXFiscal Receipt Types" = R,
        tabledata "DXR_Fiscal Receipt Types" = RIM,
        tabledata "DXNCF Categories" = R,
        tabledata "NCFCategories_DXR" = RIM,
        tabledata "DXNCF Setup" = R,
        tabledata "DXR_NCF Setup" = RIM,
        tabledata "DXNCF Purchase Setup" = R,
        tabledata "DXR_NCF Purchase Setup" = RIM,
        tabledata "DXNCF Sales Setup" = R,
        tabledata "DXR_NCF Sales Setup" = RIM,
        tabledata "DXNAV_POS_Customer" = R,
        tabledata "DXR_NAV_POS_Customer" = RIM,
        tabledata "DXExtract Cards" = R,
        tabledata "DXR_Extract Cards" = RIM,
        tabledata "DXGubernamentales(623)" = R,
        tabledata "DXR_Gubernamentales(623)" = RIM,
        tabledata Item = RM,
        tabledata "General Posting Setup" = R,
        tabledata "G/L Account" = R;

    trigger OnRun()
    begin
        // No concept-level Upgrade Tag gating here (deliberately) - each of the 13 individual
        // procedures below is already gated by its own real DR-Localization completion tag (see
        // codeunit-level comment), so an outer tag here would be redundant at best and, if this
        // codeunit ever needed to re-run one single table's procedure in isolation (e.g. a future
        // hotfix), an outer tag would incorrectly skip the whole group after the first successful run.
        BootstrapCompanyInformationFields();
        BootstrapBankAccountCustomerVendorFields();
        BootstrapGLUserSetupJournalFields();
        BootstrapNCFSetupTables();
        BootstrapItemNCFCategoryBackfill();
        BootstrapNAVPOSCustomerTable();
        BootstrapExtractCardsTable();
        BootstrapGubernamentales623Table();
    end;

    // ===== seq9: Bootstrap: CompanyInformation fields =====
    // Ported from MigrateFields_CompanyInformation_Bulk() (~line 1619) and
    // MigrateFields_CompanyInformation_SpecialConversions() (~line 1636).

    local procedure BootstrapCompanyInformationFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-BULK-20260522') then begin
            MigrateCompanyInformationBulk();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-BULK-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-SPECIALCONVERSIONS-20260522') then begin
            MigrateCompanyInformationSpecialConversions();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-COMPANYINFORMATION-SPECIALCONVERSIONS-20260522');
        end;
    end;

    // "Company Information" is a single-record table (no key) - Get() with no arguments, exactly
    // as the real source does.
    local procedure MigrateCompanyInformationBulk()
    var
        CompanyInformationRec: Record "Company Information";
    begin
        if not CompanyInformationRec.Get() then
            exit;

        if (CompanyInformationRec."Tax Management_DXR" <> CompanyInformationRec."DxTax Management") or
           (CompanyInformationRec."Position_DXR" <> CompanyInformationRec."DxPosition") then begin
            CompanyInformationRec."Tax Management_DXR" := CompanyInformationRec."DxTax Management";
            CompanyInformationRec."Position_DXR" := CompanyInformationRec."DxPosition";
            CompanyInformationRec.Modify(false);
        end;
    end;

    // BLOB fields - CalcFields required first on the legacy side. Both "DxSignature Picture"/
    // "DxEntity Logo" and their "_DXR" counterparts live on the SAME table ("Company Information"),
    // so a direct typed assignment between BLOB fields of one Record variable is used, exactly as
    // DR-Localization own real source does.
    local procedure MigrateCompanyInformationSpecialConversions()
    var
        CompanyInformationRec: Record "Company Information";
    begin
        if CompanyInformationRec.FindSet(true) then
            repeat
                CompanyInformationRec.CalcFields("DxSignature Picture", "DxEntity Logo");
                CompanyInformationRec."Signature Picture_DXR" := CompanyInformationRec."DxSignature Picture";
                CompanyInformationRec."Entity Logo_DXR" := CompanyInformationRec."DxEntity Logo";
                CompanyInformationRec.Modify(false);
            until CompanyInformationRec.Next() = 0;
    end;

    // ===== seq10: Bootstrap: BankAccount/Customer/Vendor fields =====
    // Ported from MigrateFields_BankAccount() (~line 603), MigrateFields_Customer() (~line 1680),
    // MigrateFields_CustomerTempl() (~line 1736) and MigrateFields_Vendor() (~line 2399, real body
    // of the RunMigrateFields_Vendor() wrapper at ~line 927).

    local procedure BootstrapBankAccountCustomerVendorFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNT-20260522') then begin
            MigrateBankAccountFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-BANKACCOUNT-20260522');
        end;

        // "-V2" tag - DR-Localization's own real tag, already bumped by DRLOC's team when they added
        // "Apply Cust Withhold_DXR" to this procedure's dirty-check condition (see codeunit-level
        // comment). Reusing it here (not the superseded V1 tag) is required for tenants who ran the
        // migration under DRLOC's real dispatcher after that bump to be correctly recognized as done.
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMER-20260522-V2') then begin
            MigrateCustomerFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMER-20260522-V2');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMERTEMPL-20260522') then begin
            MigrateCustomerTemplFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-CUSTOMERTEMPL-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDOR-20260522') then begin
            MigrateVendorFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VENDOR-20260522');
        end;
    end;

    local procedure MigrateBankAccountFields()
    var
        BankAccountRec: Record "Bank Account";
    begin
        if BankAccountRec.FindSet(true) then
            repeat
                if (BankAccountRec."Cod. Proveedor Bco._DXR" <> BankAccountRec."DxCod. Proveedor Bco.") or
                   (BankAccountRec."Cargar Estados CSV_DXR" <> BankAccountRec."DxCargar Estados CSV") then begin
                    BankAccountRec."Cod. Proveedor Bco._DXR" := BankAccountRec."DxCod. Proveedor Bco.";
                    BankAccountRec."Cargar Estados CSV_DXR" := BankAccountRec."DxCargar Estados CSV";
                    BankAccountRec.Modify(false);
                end;
            until BankAccountRec.Next() = 0;
    end;

    // Master data - full field-by-field shadow-field verification performed against real
    // DXR_CustomerExt.TableExt.al (all 20 fields confirmed real, non-obsolete, non-FlowField).
    //
    // BUG FIX vs. real source (see codeunit-level comment): DR-Localization own
    // MigrateFields_Customer() checks "Apply Cust Withhold_DXR" in its dirty-check condition but
    // never assigns it. Added the missing assignment here so the ported version is actually
    // correct.
    local procedure MigrateCustomerFields()
    var
        CustomerRec: Record Customer;
    begin
        if CustomerRec.FindSet(true) then
            repeat
                if (CustomerRec."Tipo NCF_DXR" <> CustomerRec."DxTipo NCF") or
                   (CustomerRec."Utiliza NCF_DXR" <> CustomerRec."DxUtiliza NCF") or
                   (CustomerRec."Tipo Identificacion_DXR" <> CustomerRec."DXTipo Identificacion") or
                   (CustomerRec."Razon Social_DXR" <> CustomerRec."DxRazon Social") or
                   (CustomerRec."Nombre Comercial_DXR" <> CustomerRec."DxNombre Comercial") or
                   (CustomerRec."Tipo Negocio_DXR" <> CustomerRec."DxTipo Negocio") or
                   (CustomerRec."Fecha Constitucion_DXR" <> CustomerRec."DxFecha Constitucion") or
                   (CustomerRec."Estatus_DXR" <> CustomerRec."DxEstatus") or
                   (CustomerRec."Fecha Act. DGII_DXR" <> CustomerRec."DxFecha Act. DGII") or
                   (CustomerRec."Tax Identification Type_DXR" <> CustomerRec."DxTax Identification Type") or
                   (CustomerRec."Proveedor Tarjeta Cr._DXR" <> CustomerRec."DxProveedor Tarjeta Cr.") or
                   (CustomerRec."International Customer_DXR" <> CustomerRec."DX International Customer") or
                   (CustomerRec."Uses Withholding_DXR" <> CustomerRec."DX Uses Withholding") or
                   (CustomerRec."Bank Commission_DXR" <> CustomerRec."DX Bank Commission") or
                   (CustomerRec."Cod. Retencion ITBIS_DXR" <> CustomerRec."DXCod. Retencion ITBIS") or
                   (CustomerRec."Cod. Retencion ISR_DXR" <> CustomerRec."DXCod. Retencion ISR") or
                   (CustomerRec."Bank Commission Account_DXR" <> CustomerRec."DX Bank Commission Account") or
                   (CustomerRec."Def ITBIS Withhold_DXR" <> CustomerRec."DXDefault ITBIS Withholding") or
                   (CustomerRec."Default ISR Withholding_DXR" <> CustomerRec."DXDefault ISR Withholding") or
                   (CustomerRec."Apply Cust Withhold_DXR" <> CustomerRec."DX Apply Customer Withholding") then begin
                    CustomerRec."Tipo NCF_DXR" := CustomerRec."DxTipo NCF";
                    CustomerRec."Utiliza NCF_DXR" := CustomerRec."DxUtiliza NCF";
                    CustomerRec."Tipo Identificacion_DXR" := CustomerRec."DXTipo Identificacion";
                    CustomerRec."Razon Social_DXR" := CustomerRec."DxRazon Social";
                    CustomerRec."Nombre Comercial_DXR" := CustomerRec."DxNombre Comercial";
                    CustomerRec."Tipo Negocio_DXR" := CustomerRec."DxTipo Negocio";
                    CustomerRec."Fecha Constitucion_DXR" := CustomerRec."DxFecha Constitucion";
                    CustomerRec."Estatus_DXR" := CustomerRec."DxEstatus";
                    CustomerRec."Fecha Act. DGII_DXR" := CustomerRec."DxFecha Act. DGII";
                    CustomerRec."Tax Identification Type_DXR" := CustomerRec."DxTax Identification Type";
                    CustomerRec."Proveedor Tarjeta Cr._DXR" := CustomerRec."DxProveedor Tarjeta Cr.";
                    CustomerRec."International Customer_DXR" := CustomerRec."DX International Customer";
                    CustomerRec."Uses Withholding_DXR" := CustomerRec."DX Uses Withholding";
                    CustomerRec."Bank Commission_DXR" := CustomerRec."DX Bank Commission";
                    CustomerRec."Cod. Retencion ITBIS_DXR" := CustomerRec."DXCod. Retencion ITBIS";
                    CustomerRec."Cod. Retencion ISR_DXR" := CustomerRec."DXCod. Retencion ISR";
                    CustomerRec."Bank Commission Account_DXR" := CustomerRec."DX Bank Commission Account";
                    CustomerRec."Def ITBIS Withhold_DXR" := CustomerRec."DXDefault ITBIS Withholding";
                    CustomerRec."Default ISR Withholding_DXR" := CustomerRec."DXDefault ISR Withholding";
                    // Explicit conversion required - "Apply Cust Withhold_DXR" (52201) and
                    // "DX Apply Customer Withholding" (54203) are two distinct Enum objects (the
                    // latter Obsolete = Pending, replaced by the former), even though their value
                    // sets are numerically identical (0=" ", 1="On Payment", 2="On Invoice" on both -
                    // confirmed against DXR_ApplyCustomerWithholding.Enum.al and
                    // DXApplyCustomerWithholding.Enum.al). AL does not implicitly convert between
                    // different Enum types on assignment (AL0122), so FromInteger/AsInteger is used.
                    CustomerRec."Apply Cust Withhold_DXR" :=
                        "Apply Cust Withhold_DXR".FromInteger(CustomerRec."DX Apply Customer Withholding".AsInteger());
                    CustomerRec.Modify(false);
                end;
            until CustomerRec.Next() = 0;
    end;

    local procedure MigrateCustomerTemplFields()
    var
        CustomerTemplRec: Record "Customer Templ.";
    begin
        if CustomerTemplRec.FindSet(true) then
            repeat
                if (CustomerTemplRec."Tipo NCF_DXR" <> CustomerTemplRec."DxTipo NCF") or
                   (CustomerTemplRec."Utiliza NCF_DXR" <> CustomerTemplRec."DxUtiliza NCF") then begin
                    CustomerTemplRec."Tipo NCF_DXR" := CustomerTemplRec."DxTipo NCF";
                    CustomerTemplRec."Utiliza NCF_DXR" := CustomerTemplRec."DxUtiliza NCF";
                    CustomerTemplRec.Modify(false);
                end;
            until CustomerTemplRec.Next() = 0;
    end;

    // Master data - full field-by-field shadow-field verification performed against real
    // DXR_VendorExt.TableExt.Al (all 20 fields confirmed real, non-obsolete, non-FlowField).
    local procedure MigrateVendorFields()
    var
        VendorRec: Record Vendor;
    begin
        if VendorRec.FindSet(true) then
            repeat
                if (VendorRec."NCF Interno Proveedor_DXR" <> VendorRec."DXNCF Interno Proveedor") or
                   (VendorRec."Utiliza NCF Externo_DXR" <> VendorRec."DXUtiliza NCF Externo") or
                   (VendorRec."Tipo Identificacion_DXR" <> VendorRec."DXTipo Identificacion") or
                   (VendorRec."Razon Social_DXR" <> VendorRec."DXRazon Social") or
                   (VendorRec."Nombre Comercial_DXR" <> VendorRec."DXNombre Comercial") or
                   (VendorRec."Tipo Negocio_DXR" <> VendorRec."DXTipo Negocio") or
                   (VendorRec."Fecha Constitucion_DXR" <> VendorRec."DXFecha Constitucion") or
                   (VendorRec."Estatus_DXR" <> VendorRec."DXEstatus") or
                   (VendorRec."Fecha Act. DGII_DXR" <> VendorRec."DXFecha Act. DGII") or
                   (VendorRec."Tax Identificaction Type_DXR" <> VendorRec."DXTax Identificaction Type") or
                   (VendorRec."Cod. Retencion ITBIS_DXR" <> VendorRec."DXCod. Retencion ITBIS") or
                   (VendorRec."Cod. Retencion ISR_DXR" <> VendorRec."DXCod. Retencion ISR") or
                   (VendorRec."Proveedor Internacional_DXR" <> VendorRec."DXProveedor Internacional") or
                   (VendorRec."Utiliza Retencion_DXR" <> VendorRec."DXUtiliza Retencion") or
                   (VendorRec."Uses Sel Amount Tip_DXR" <> VendorRec."DXUses Selective Amount Tip") or
                   (VendorRec."Uses Legal Tip_DXR" <> VendorRec."DXUses Legal Tip") or
                   (VendorRec."Uses Other Fees Tip_DXR" <> VendorRec."DXUses Other Fees Tip") or
                   (VendorRec."Parte Relacionada_DXR" <> VendorRec."DxParte Relacionada") or
                   (VendorRec."Reporta 609_DXR" <> VendorRec."DXReporta 609") or
                   (VendorRec."Addtl Currency Code_DXR" <> VendorRec."DX Additional Currency Code") then begin
                    VendorRec."NCF Interno Proveedor_DXR" := VendorRec."DXNCF Interno Proveedor";
                    VendorRec."Utiliza NCF Externo_DXR" := VendorRec."DXUtiliza NCF Externo";
                    VendorRec."Tipo Identificacion_DXR" := VendorRec."DXTipo Identificacion";
                    VendorRec."Razon Social_DXR" := VendorRec."DXRazon Social";
                    VendorRec."Nombre Comercial_DXR" := VendorRec."DXNombre Comercial";
                    VendorRec."Tipo Negocio_DXR" := VendorRec."DXTipo Negocio";
                    VendorRec."Fecha Constitucion_DXR" := VendorRec."DXFecha Constitucion";
                    VendorRec."Estatus_DXR" := VendorRec."DXEstatus";
                    VendorRec."Fecha Act. DGII_DXR" := VendorRec."DXFecha Act. DGII";
                    VendorRec."Tax Identificaction Type_DXR" := VendorRec."DXTax Identificaction Type";
                    VendorRec."Cod. Retencion ITBIS_DXR" := VendorRec."DXCod. Retencion ITBIS";
                    VendorRec."Cod. Retencion ISR_DXR" := VendorRec."DXCod. Retencion ISR";
                    VendorRec."Proveedor Internacional_DXR" := VendorRec."DXProveedor Internacional";
                    VendorRec."Utiliza Retencion_DXR" := VendorRec."DXUtiliza Retencion";
                    VendorRec."Uses Sel Amount Tip_DXR" := VendorRec."DXUses Selective Amount Tip";
                    VendorRec."Uses Legal Tip_DXR" := VendorRec."DXUses Legal Tip";
                    VendorRec."Uses Other Fees Tip_DXR" := VendorRec."DXUses Other Fees Tip";
                    VendorRec."Parte Relacionada_DXR" := VendorRec."DxParte Relacionada";
                    VendorRec."Reporta 609_DXR" := VendorRec."DXReporta 609";
                    VendorRec."Addtl Currency Code_DXR" := VendorRec."DX Additional Currency Code";
                    VendorRec.Modify(false);
                end;
            until VendorRec.Next() = 0;
    end;

    // ===== seq11: Bootstrap: GL/UserSetup/Journal fields =====
    // Ported from MigrateFields_GLAccount() (~line 1753), MigrateFields_UserSetup() (~line 2384),
    // MigrateFields_NoSeriesLine() (~line 1920), MigrateFields_GenJournalTemplate() (~line 1878),
    // MigrateFields_GenJournalBatch() (~line 1798), MigrateFields_WorkflowStepArgument()
    // (~line 2495), MigrateFields_VATProductPostingGroup() (~line 3984).

    local procedure BootstrapGLUserSetupJournalFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // GLAccount is a no-op (see codeunit-level comment) but is still gated by its own real tag
        // for consistency with the other 12 procedures and with DR-Localization's own dispatcher.
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLACCOUNT-20260522') then begin
            MigrateGLAccountFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GLACCOUNT-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-USERSETUP-20260522') then begin
            MigrateUserSetupFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-USERSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-NOSERIESLINE-20260522') then begin
            MigrateNoSeriesLineFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-NOSERIESLINE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALTEMPLATE-20260522') then begin
            MigrateGenJournalTemplateFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALTEMPLATE-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALBATCH-20260522') then begin
            MigrateGenJournalBatchFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-GENJOURNALBATCH-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-WORKFLOWSTEPARGUMENT-20260522') then begin
            MigrateWorkflowStepArgumentFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-WORKFLOWSTEPARGUMENT-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VATPRODUCTPOSTINGGROUP-20260522') then begin
            MigrateVATProductPostingGroupFields();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-FIELDS-VATPRODUCTPOSTINGGROUP-20260522');
        end;
    end;

    // Deliberate no-op - see codeunit-level comment. Both "DXNCF" and "NCF_DXR" on G/L Account are
    // ObsoleteState = Removed (confirmed against DXR_GLAccountExt.TableExt.al); nothing to migrate.
    local procedure MigrateGLAccountFields()
    begin
    end;

    local procedure MigrateUserSetupFields()
    var
        UserSetupRec: Record "User Setup";
    begin
        if UserSetupRec.FindSet(true) then
            repeat
                if UserSetupRec."Entrega Cheques_DXR" <> UserSetupRec."DXEntrega Cheques" then begin
                    UserSetupRec."Entrega Cheques_DXR" := UserSetupRec."DXEntrega Cheques";
                    UserSetupRec.Modify(false);
                end;
            until UserSetupRec.Next() = 0;
    end;

    local procedure MigrateNoSeriesLineFields()
    var
        NoSeriesLineRec: Record "No. Series Line";
    begin
        if NoSeriesLineRec.FindSet(true) then
            repeat
                if NoSeriesLineRec."Fecha Expiracion NCF_DXR" <> NoSeriesLineRec."DXFecha Expiracion NCF" then begin
                    NoSeriesLineRec."Fecha Expiracion NCF_DXR" := NoSeriesLineRec."DXFecha Expiracion NCF";
                    NoSeriesLineRec.Modify(false);
                end;
            until NoSeriesLineRec.Next() = 0;
    end;

    local procedure MigrateGenJournalTemplateFields()
    var
        GenJournalTemplateRec: Record "Gen. Journal Template";
    begin
        if GenJournalTemplateRec.FindSet(true) then
            repeat
                if GenJournalTemplateRec."Cash Recpt. Report ID_DXR" <> GenJournalTemplateRec."Cash Recpt. Report ID" then begin
                    GenJournalTemplateRec."Cash Recpt. Report ID_DXR" := GenJournalTemplateRec."Cash Recpt. Report ID";
                    GenJournalTemplateRec.Modify(false);
                end;
            until GenJournalTemplateRec.Next() = 0;
    end;

    local procedure MigrateGenJournalBatchFields()
    var
        GenJournalBatchRec: Record "Gen. Journal Batch";
    begin
        if GenJournalBatchRec.FindSet(true) then
            repeat
                if (GenJournalBatchRec."Recibo Ingreso_DXR" <> GenJournalBatchRec."DXRecibo Ingreso") or
                   (GenJournalBatchRec."Diario de cheques_DXR" <> GenJournalBatchRec."DXDiario de cheques") then begin
                    GenJournalBatchRec."Recibo Ingreso_DXR" := GenJournalBatchRec."DXRecibo Ingreso";
                    GenJournalBatchRec."Diario de cheques_DXR" := GenJournalBatchRec."DXDiario de cheques";
                    GenJournalBatchRec.Modify(false);
                end;
            until GenJournalBatchRec.Next() = 0;
    end;

    local procedure MigrateWorkflowStepArgumentFields()
    var
        WorkflowStepArgumentRec: Record "Workflow Step Argument";
    begin
        if WorkflowStepArgumentRec.FindSet(true) then
            repeat
                if WorkflowStepArgumentRec."Due Invoice Option_DXR" <> WorkflowStepArgumentRec."DX Due Invoice Option" then begin
                    WorkflowStepArgumentRec."Due Invoice Option_DXR" := WorkflowStepArgumentRec."DX Due Invoice Option";
                    WorkflowStepArgumentRec.Modify(false);
                end;
            until WorkflowStepArgumentRec.Next() = 0;
    end;

    local procedure MigrateVATProductPostingGroupFields()
    var
        VATProductPostingGroupRec: Record "VAT Product Posting Group";
    begin
        if VATProductPostingGroupRec.FindSet(true) then
            repeat
                if (VATProductPostingGroupRec."Taken To Cost_DXR" <> VATProductPostingGroupRec."DX Taken To Cost") or
                   (VATProductPostingGroupRec."Proportionality_DXR" <> VATProductPostingGroupRec."DX Proportionality") then begin
                    VATProductPostingGroupRec."Taken To Cost_DXR" := VATProductPostingGroupRec."DX Taken To Cost";
                    VATProductPostingGroupRec."Proportionality_DXR" := VATProductPostingGroupRec."DX Proportionality";
                    VATProductPostingGroupRec.Modify(false);
                end;
            until VATProductPostingGroupRec.Next() = 0;
    end;

    // ===== seq12: Bootstrap: NCF Setup tables =====
    // Ported from MigrateTable_FiscalReceiptTypes() (~line 3258), MigrateTable_NCFCategories()
    // (~line 3532), MigrateTable_NCFSetup() (~line 3581), MigrateTable_NCFPurchaseSetup()
    // (~line 3550) and MigrateTable_NCFSalesSetup() (~line 3568), all in
    // DXR_Internal_Closure_Migration_Upgrade_Clean.al. All 5 are whole-table CLONES in DR-
    // Localization own source (unlike Batch 1's field-group procedures) and DR-Localization own
    // code uses NewRec.TransferFields(OldRec, true) for every one of them - each is expanded below
    // into explicit, per-field typed assignment (TransferFields is banned plan-wide in this MCC
    // project). Bundled under one registry concept (seq12, same bundling pattern as seq9/10/11),
    // but each of the 5 sub-procedures still gates on its OWN real DR-Localization completion tag
    // (UpgradeTagInternalClosureTable<X>() in DXR_UpgradeTagMgt.Codeunit.al), same convention as
    // Batch 1's per-procedure tag reuse.
    //
    // NCF Setup investigation (2026-08-24, this task - required before writing MigrateNCFSetupTable
    // below): "DXR_NCF Setup" (52179) already has THREE independent, pre-existing migration
    // mechanisms in this MCC repo (all confirmed via source):
    //   1) DXRMCCBellonMigrPhase2.Codeunit.al MigrateTableExt_DXNCFSetupFields() - same-table
    //      bridge, copies "Grupo Contable BS"/"Legal Tip %" into "Grupo Contable BS_DXR"/
    //      "Legal Tip %_DXR" (all four fields live on "DXR_NCF Setup" itself).
    //   2) DXRMCCBellonMigrPhase11.Codeunit.al MigrateNCFSetupOldCrossTable() - cross-table bridge,
    //      copies the SAME two target fields, but reads the source values off the LEGACY "DXNCF
    //      Setup" table instead ("Grupo Contable BS"/"Legal Tip %" on the old table).
    //   3) DXRMCCBellonMigrPhase13.Codeunit.al - intermediate "_Old" bridge, copies
    //      "Grupo Contable BS_Old"/"Legal Tip %_Old" (also on "DXR_NCF Setup" itself) into the same
    //      two "_DXR" targets.
    // All three existing mechanisms exclusively target "Grupo Contable BS_DXR"/"Legal Tip %_DXR" -
    // two fields that do NOT exist anywhere in DR-Localization's own repo (confirmed by grepping
    // DR-Localization's full source tree for both names: zero matches in either
    // Tables.old/DXNCFSetup.Table.al or Base/Tables/DXR_NCFSetup.Table.al). They are purely
    // BELLON-added tableextension fields layered on top of DR-Localization's "DXNCF Setup"/
    // "DXR_NCF Setup". MigrateNCFSetupTable() below instead ports DR-Localization's OWN ~73
    // base-table fields (the real schema DR-Localization itself declares on both tables) - a
    // completely disjoint field set from all three existing mechanisms; it never reads or writes
    // "Grupo Contable BS_DXR"/"Legal Tip %_DXR"/either "_Old" or legacy-tableextension counterpart.
    // This confirms MigrateNCFSetupTable() is a genuine 4th, independent/complementary mechanism
    // for this same physical table pair, matching this plan's established "multiple independent
    // fill-gap mechanisms for messy tenant history" precedent for this exact table - it is ported
    // here unmerged/unmodified, per this task's instructions (do NOT merge/simplify/skip it).
    //
    // Two fields on "DXNCF Setup"/"DXR_NCF Setup" are ObsoleteState = Removed on BOTH the old and
    // new side ("Prepayment Acct. Credit Card", "Use Additional Currency" - confirmed against both
    // real table sources) - referencing a Removed field is a compile error (AL0499), so both are
    // deliberately excluded entirely from MigrateNCFSetupTable() below; every other field (including
    // several marked ObsoleteState = Pending on one or both sides, which remain both readable and
    // writable - e.g. "Allow NCF 32 in Consumer 607", "CR Customer Withholding",
    // "EnableCustomerWithholdings", "EnableBankCommission", "Bank Commission Account") is copied,
    // matching DR-Localization's own TransferFields(OldRec, true) behavior (Pending is not a
    // migration blocker, only Removed is).
    local procedure BootstrapNCFSetupTables()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-FISCALRECEIPTTYPES-20260522') then begin
            MigrateFiscalReceiptTypesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-FISCALRECEIPTTYPES-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFCATEGORIES-20260522') then begin
            MigrateNCFCategoriesTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFCATEGORIES-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSETUP-20260522') then begin
            MigrateNCFSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFPURCHASESETUP-20260522') then begin
            MigrateNCFPurchaseSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFPURCHASESETUP-20260522');
        end;

        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSALESSETUP-20260522') then begin
            MigrateNCFSalesSetupTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NCFSALESSETUP-20260522');
        end;
    end;

    local procedure MigrateFiscalReceiptTypesTable()
    var
        FiscalReceiptTypesOld: Record "DXFiscal Receipt Types";
        FiscalReceiptTypesNew: Record "DXR_Fiscal Receipt Types";
    begin
        if FiscalReceiptTypesOld.IsEmpty() then
            exit;
        if FiscalReceiptTypesOld.FindSet() then
            repeat
                FiscalReceiptTypesNew."Code" := FiscalReceiptTypesOld."Code";
                FiscalReceiptTypesNew.Description := FiscalReceiptTypesOld.Description;
                FiscalReceiptTypesNew."Comprobante Electronico" := FiscalReceiptTypesOld."Comprobante Electronico";
                if not FiscalReceiptTypesNew.Insert(false) then
                    FiscalReceiptTypesNew.Modify(false);
            until FiscalReceiptTypesOld.Next() = 0;
    end;

    local procedure MigrateNCFCategoriesTable()
    var
        NCFCategoriesOld: Record "DXNCF Categories";
        NCFCategoriesNew: Record "NCFCategories_DXR";
    begin
        if NCFCategoriesOld.IsEmpty() then
            exit;
        if NCFCategoriesOld.FindSet() then
            repeat
                NCFCategoriesNew."DXCodigo" := NCFCategoriesOld."DXCodigo";
                NCFCategoriesNew."DXDescripcion" := NCFCategoriesOld."DXDescripcion";
                if not NCFCategoriesNew.Insert(false) then
                    NCFCategoriesNew.Modify(false);
            until NCFCategoriesOld.Next() = 0;
    end;

    // ~73-field whole-table clone (see codeunit-level "NCF Setup investigation" comment above for
    // the field-count/Removed-field rationale). Field order below matches the real table
    // declaration order in Base/Tables/DXR_NCFSetup.Table.al / Tables.old/DXNCFSetup.Table.al.
    local procedure MigrateNCFSetupTable()
    var
        NCFSetupOld: Record "DXNCF Setup";
        NCFSetupNew: Record "DXR_NCF Setup";
    begin
        if NCFSetupOld.IsEmpty() then
            exit;
        if NCFSetupOld.FindSet() then
            repeat
                NCFSetupNew."Primary Key" := NCFSetupOld."Primary Key";
                NCFSetupNew."Control Dígitos NCF" := NCFSetupOld."Control Dígitos NCF";
                NCFSetupNew."Funcionalidad NCF" := NCFSetupOld."Funcionalidad NCF";
                NCFSetupNew."N/C Ventas ITBIS +30 dias" := NCFSetupOld."N/C Ventas ITBIS +30 dias";
                NCFSetupNew."Directorio Archivo ITBIS (607)" := NCFSetupOld."Directorio Archivo ITBIS (607)";
                NCFSetupNew."Libro Diario Cargos Banc." := NCFSetupOld."Libro Diario Cargos Banc.";
                NCFSetupNew."Seccion Diario Cargos Banc." := NCFSetupOld."Seccion Diario Cargos Banc.";
                NCFSetupNew."No. Series Cargo Banc." := NCFSetupOld."No. Series Cargo Banc.";
                NCFSetupNew."Codigo Audit. Cargos Banc." := NCFSetupOld."Codigo Audit. Cargos Banc.";
                NCFSetupNew."Cta. Gastos Cargos Banc." := NCFSetupOld."Cta. Gastos Cargos Banc.";
                NCFSetupNew."Cta. Gastos Cargos Tarjetas Cr" := NCFSetupOld."Cta. Gastos Cargos Tarjetas Cr";
                NCFSetupNew."Cta. ITBIS Cargos Tarjetas Cr" := NCFSetupOld."Cta. ITBIS Cargos Tarjetas Cr";
                NCFSetupNew."Libro Diario Cargos Tarj. Cr." := NCFSetupOld."Libro Diario Cargos Tarj. Cr.";
                NCFSetupNew."Seccion Diario Cargos Tarj. Cr" := NCFSetupOld."Seccion Diario Cargos Tarj. Cr";
                NCFSetupNew."No. Series Cargos Tarj. Cr." := NCFSetupOld."No. Series Cargos Tarj. Cr.";
                NCFSetupNew."Codigo Audit. Cargos Tarj. Cr." := NCFSetupOld."Codigo Audit. Cargos Tarj. Cr.";
                NCFSetupNew."No. Series Ret. Gubernamental" := NCFSetupOld."No. Series Ret. Gubernamental";
                NCFSetupNew."Cta. Ret. Gubernamental" := NCFSetupOld."Cta. Ret. Gubernamental";
                NCFSetupNew."Cod. Audit. Ret. Gubernamental" := NCFSetupOld."Cod. Audit. Ret. Gubernamental";
                NCFSetupNew."Libro Diario Ret. Gub." := NCFSetupOld."Libro Diario Ret. Gub.";
                NCFSetupNew."Seccion Diario Ret. Gub." := NCFSetupOld."Seccion Diario Ret. Gub.";
                NCFSetupNew."Directorio Archivo ITBIS (606)" := NCFSetupOld."Directorio Archivo ITBIS (606)";
                NCFSetupNew."Fecha Cierre" := NCFSetupOld."Fecha Cierre";
                NCFSetupNew."Directorio Ret. Guber623" := NCFSetupOld."Directorio Ret. Guber623";
                NCFSetupNew."Directorio Pagos Supl. Inter." := NCFSetupOld."Directorio Pagos Supl. Inter.";
                NCFSetupNew."Cod. Audit. Pagos Supl. inter." := NCFSetupOld."Cod. Audit. Pagos Supl. inter.";
                NCFSetupNew."RNC Oblig. en Proveedores" := NCFSetupOld."RNC Oblig. en Proveedores";
                NCFSetupNew."RNC Oblig. en Clientes" := NCFSetupOld."RNC Oblig. en Clientes";
                NCFSetupNew."Cat. NCF Oblig. en Cuentas" := NCFSetupOld."Cat. NCF Oblig. en Cuentas";
                NCFSetupNew."No. Serie Regist. Cargo Banc." := NCFSetupOld."No. Serie Regist. Cargo Banc.";
                NCFSetupNew."No. Serie Regist. C. Tarj. Cr." := NCFSetupOld."No. Serie Regist. C. Tarj. Cr.";
                NCFSetupNew."Libro Diario Ret. Proveedor" := NCFSetupOld."Libro Diario Ret. Proveedor";
                NCFSetupNew."Seccion Diario Ret. Proveedor" := NCFSetupOld."Seccion Diario Ret. Proveedor";
                NCFSetupNew."No. Serie Ret. Proveedor" := NCFSetupOld."No. Serie Ret. Proveedor";
                NCFSetupNew."No. Serie Regist. Ret. Gub." := NCFSetupOld."No. Serie Regist. Ret. Gub.";
                NCFSetupNew."Libro Diario Productos" := NCFSetupOld."Libro Diario Productos";
                NCFSetupNew."Seccion Diario Productos" := NCFSetupOld."Seccion Diario Productos";
                NCFSetupNew."Codigo Almacen Diario" := NCFSetupOld."Codigo Almacen Diario";
                NCFSetupNew."NCF Ventas" := NCFSetupOld."NCF Ventas";
                NCFSetupNew."Recibo de Ingreso" := NCFSetupOld."Recibo de Ingreso";
                NCFSetupNew."NCF Punto de Venta" := NCFSetupOld."NCF Punto de Venta";
                NCFSetupNew."Cargos Bancario" := NCFSetupOld."Cargos Bancario";
                NCFSetupNew.Cheques := NCFSetupOld.Cheques;
                NCFSetupNew."Cargos Tarjetas de Credito" := NCFSetupOld."Cargos Tarjetas de Credito";
                NCFSetupNew."Retenciones Gubernamentales" := NCFSetupOld."Retenciones Gubernamentales";
                NCFSetupNew."NCF Compras" := NCFSetupOld."NCF Compras";
                NCFSetupNew."Impresora Fiscal" := NCFSetupOld."Impresora Fiscal";
                NCFSetupNew."Block posting in zero prices" := NCFSetupOld."Block posting in zero prices";
                NCFSetupNew."Impedir Precio Cero POS" := NCFSetupOld."Impedir Precio Cero POS";
                NCFSetupNew."Exempt group" := NCFSetupOld."Exempt group";
                NCFSetupNew."Exempt Product group" := NCFSetupOld."Exempt Product group";
                NCFSetupNew."Keep Original VAT Reg. No." := NCFSetupOld."Keep Original VAT Reg. No.";
                // "Tax Rule" and "Grupo Contable Prop." are plain (non-Enum) Option fields on both
                // tables, with identical OptionMembers/order on each side - AL permits direct
                // cross-record Option field assignment (unlike Enum, Option is not nominally typed).
                NCFSetupNew."Tax Rule" := NCFSetupOld."Tax Rule";
                NCFSetupNew."Max Amount without RNC/Cedula" := NCFSetupOld."Max Amount without RNC/Cedula";
                // ObsoleteState = Pending on both sides (still readable/writable) - copied per
                // TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."Allow NCF 32 in Consumer 607" := NCFSetupOld."Allow NCF 32 in Consumer 607";
                NCFSetupNew."Fiscal Controls" := NCFSetupOld."Fiscal Controls";
                NCFSetupNew."POS Transactions in 607" := NCFSetupOld."POS Transactions in 607";
                NCFSetupNew."Grupo Contable Prop." := NCFSetupOld."Grupo Contable Prop.";
                NCFSetupNew."Funcionalidad e-CF" := NCFSetupOld."Funcionalidad e-CF";
                NCFSetupNew."Digitos e-CF" := NCFSetupOld."Digitos e-CF";
                NCFSetupNew."Use Localization DR" := NCFSetupOld."Use Localization DR";
                NCFSetupNew."NCF Debit Note" := NCFSetupOld."NCF Debit Note";
                NCFSetupNew."No. Serie NDB" := NCFSetupOld."No. Serie NDB";
                NCFSetupNew."Libro Diario Ret. Customer" := NCFSetupOld."Libro Diario Ret. Customer";
                NCFSetupNew."Seccion Diario Ret. Customer" := NCFSetupOld."Seccion Diario Ret. Customer";
                NCFSetupNew."No. Serie Ret. Customer" := NCFSetupOld."No. Serie Ret. Customer";
                NCFSetupNew."Other Feeds Percentage" := NCFSetupOld."Other Feeds Percentage";
                // "Prepayment Acct. Credit Card" (36002767/36002768) is skipped deliberately -
                // ObsoleteState = Removed on BOTH old and new tables (referencing it is AL0499).
                NCFSetupNew."Loan Acct. Credit Card" := NCFSetupOld."Loan Acct. Credit Card";
                // "Use Additional Currency" (36002769) is skipped deliberately - ObsoleteState =
                // Removed on BOTH old and new tables (referencing it is AL0499).
                NCFSetupNew."Directorio Archivo (609)" := NCFSetupOld."Directorio Archivo (609)";
                NCFSetupNew."Allow Diff. Margen Legal Tip" := NCFSetupOld."Allow Diff. Margen Legal Tip";
                NCFSetupNew."Check Cust.A.NCF Ledg. Entries" := NCFSetupOld."Check Cust.A.NCF Ledg. Entries";
                NCFSetupNew."VAT Bus. ITBIS For Advance" := NCFSetupOld."VAT Bus. ITBIS For Advance";
                NCFSetupNew.PrintNCFindCheck := NCFSetupOld.PrintNCFindCheck;
                NCFSetupNew."Fixed Asset NCF" := NCFSetupOld."Fixed Asset NCF";
                NCFSetupNew."VAT Bus. ITBIS Taken To Cost" := NCFSetupOld."VAT Bus. ITBIS Taken To Cost";
                NCFSetupNew."Uses Electronic Invoice" := NCFSetupOld."Uses Electronic Invoice";
                NCFSetupNew."Purchase NCF Debit Note" := NCFSetupOld."Purchase NCF Debit Note";
                NCFSetupNew."Purchase No. Series NDP" := NCFSetupOld."Purchase No. Series NDP";
                NCFSetupNew."Report 606 on vend header DXR" := NCFSetupOld."Report 606 on vend header DXR";
                NCFSetupNew."Show Withholdings Info" := NCFSetupOld."Show Withholdings Info";
                NCFSetupNew."Show Additional Amounts" := NCFSetupOld."Show Additional Amounts";
                NCFSetupNew."Show Cust. Withholding Fields" := NCFSetupOld."Show Cust. Withholding Fields";
                NCFSetupNew."Show Settled Amount" := NCFSetupOld."Show Settled Amount";
                // ObsoleteState = Pending on both sides (still readable/writable) - copied per
                // TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."EnableCustomerWithholdings" := NCFSetupOld."EnableCustomerWithholdings";
                NCFSetupNew."EnableBankCommission" := NCFSetupOld."EnableBankCommission";
                NCFSetupNew."Bank Commission Account" := NCFSetupOld."Bank Commission Account";
                NCFSetupNew."Allow Edit Taxes in Cr. Memo" := NCFSetupOld."Allow Edit Taxes in Cr. Memo";
                NCFSetupNew."Enable Customer Withholdings" := NCFSetupOld."Enable Customer Withholdings";
                // ObsoleteState = Pending on the NEW side only (still readable/writable) - copied
                // per TransferFields(OldRec, true) parity; see codeunit-level comment.
                NCFSetupNew."CR Customer Withholding" := NCFSetupOld."CR Customer Withholding";
                NCFSetupNew."Enable CR Bank Commission" := NCFSetupOld."Enable CR Bank Commission";
                NCFSetupNew."Bank Fee G/L Account" := NCFSetupOld."Bank Fee G/L Account";
                NCFSetupNew."No. Serie Cash Receipt Doc" := NCFSetupOld."No. Serie Cash Receipt Doc";
                if not NCFSetupNew.Insert(false) then
                    NCFSetupNew.Modify(false);
            until NCFSetupOld.Next() = 0;
    end;

    local procedure MigrateNCFPurchaseSetupTable()
    var
        NCFPurchaseSetupOld: Record "DXNCF Purchase Setup";
        NCFPurchaseSetupNew: Record "DXR_NCF Purchase Setup";
    begin
        if NCFPurchaseSetupOld.IsEmpty() then
            exit;
        if NCFPurchaseSetupOld.FindSet() then
            repeat
                NCFPurchaseSetupNew."DXCodigo" := NCFPurchaseSetupOld."DXCodigo";
                NCFPurchaseSetupNew."DXDescripcion" := NCFPurchaseSetupOld."DXDescripcion";
                NCFPurchaseSetupNew."No. Serie NCF Fact." := NCFPurchaseSetupOld."No. Serie NCF Fact.";
                NCFPurchaseSetupNew."No. Serie NCF Abono" := NCFPurchaseSetupOld."No. Serie NCF Abono";
                NCFPurchaseSetupNew."Tipo NCF" := NCFPurchaseSetupOld."Tipo NCF";
                NCFPurchaseSetupNew."DXAuto ECF34 Internal Cr. Memo" := NCFPurchaseSetupOld."DXAuto ECF34 Internal Cr. Memo";
                if not NCFPurchaseSetupNew.Insert(false) then
                    NCFPurchaseSetupNew.Modify(false);
            until NCFPurchaseSetupOld.Next() = 0;
    end;

    // Real source has no IsEmpty() guard for this one table (unlike its 4 siblings above/below) -
    // ported exactly as-is (FindSet() on an empty table simply returns false, so behavior is
    // identical either way; kept faithful to source rather than "improving" it).
    local procedure MigrateNCFSalesSetupTable()
    var
        NCFSalesSetupOld: Record "DXNCF Sales Setup";
        NCFSalesSetupNew: Record "DXR_NCF Sales Setup";
    begin
        if NCFSalesSetupOld.FindSet() then
            repeat
                NCFSalesSetupNew."Codigo" := NCFSalesSetupOld."Codigo";
                NCFSalesSetupNew."Descripcion" := NCFSalesSetupOld."Descripcion";
                NCFSalesSetupNew."No. Serie NCF Fact." := NCFSalesSetupOld."No. Serie NCF Fact.";
                NCFSalesSetupNew."No. Serie NCF NCR" := NCFSalesSetupOld."No. Serie NCF NCR";
                // Explicit conversion required - "Tipo Doc. Fiscal" is a different Enum object on
                // each table ("DXR_Fiscal Doc. Type" vs. legacy "DX Fiscal Doc. Type"), even though
                // both enums share the identical 11-value set (0..10, same names/order in the same
                // order - confirmed against Base/Enums/DXR_FiscalDocType.enum.al and
                // Base/Enums.old/DXFiscalDocType.enum.al). AL does not implicitly convert between
                // different Enum types on assignment (AL0122), so FromInteger/AsInteger is used
                // (same pattern as Batch 1's Customer "Apply Cust Withhold_DXR" conversion).
                NCFSalesSetupNew."Tipo Doc. Fiscal" :=
                    Enum::"DXR_Fiscal Doc. Type".FromInteger(NCFSalesSetupOld."Tipo Doc. Fiscal".AsInteger());
                NCFSalesSetupNew."Tipo NCF" := NCFSalesSetupOld."Tipo NCF";
                if not NCFSalesSetupNew.Insert(false) then
                    NCFSalesSetupNew.Modify(false);
            until NCFSalesSetupOld.Next() = 0;
    end;

    // ===== seq14: Item NCF Category backfill (V27 data) =====
    // Ported from TryRunItemNCFCategoryBackfill() / MigrateItemNCFCategoryInBatches()
    // (DXR_Migr_Phase_2_Fiscal.Codeunit.al, ~line 289 / ~line 403). The real source runs inside a
    // checkpoint/batch-commit loop (StatusMgt.GetCheckpoint/SaveCheckpoint/ClearCheckpoint,
    // Commit() every ProductBatchSize() rows) purely for TaskScheduler-background resilience on
    // very large Item tables; that checkpoint/commit infrastructure is DR-Localization-internal
    // plumbing, not migrated business logic, so it is intentionally not ported here - a single
    // unbroken FindSet loop is used instead, matching this file's established simpler convention
    // (same simplification already implicit in every other procedure in this codeunit, none of
    // which replicate DR-Localization's own TaskScheduler/checkpoint machinery either).
    // TryGetItemNcfCategory() (DXR_LocalizationFiscalMgt.Codeunit.al, ~line 1559) is inlined below
    // as TryGetItemNcfCategoryLocal() rather than calling into DR-Localization's own codeunit, for
    // the same "typed, self-contained" reason as every other procedure in this file. The real
    // caller always passes a blank GenBusPostingGroup argument (see MigrateItemNCFCategoryInBatches
    // calling TryGetItemNcfCategory(Item, '', NCFCategory)), so the GenBusPostingGroup parameter and
    // its associated filter branch (never exercised for this specific call site) are omitted here.
    local procedure BootstrapItemNCFCategoryBackfill()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DXR-T20260716-BackfillItemNCFCategory') then begin
            MigrateItemNCFCategoryBackfill();
            UpgradeTag.SetUpgradeTag('DXR-T20260716-BackfillItemNCFCategory');
        end;
    end;

    local procedure MigrateItemNCFCategoryBackfill()
    var
        Item: Record Item;
        NCFCategory: Code[20];
    begin
        if Item.FindSet(true) then
            repeat
                if TryGetItemNcfCategoryLocal(Item, NCFCategory) and (Item."NCF Category_DXR" <> NCFCategory) then begin
                    Item."NCF Category_DXR" := NCFCategory;
                    Item.Modify(false);
                end;
            until Item.Next() = 0;
    end;

    local procedure TryGetItemNcfCategoryLocal(Item: Record Item; var NCFCategory: Code[20]): Boolean
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        Clear(NCFCategory);
        if Item."Gen. Prod. Posting Group" = '' then
            exit(false);

        GeneralPostingSetup.SetRange("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        if GeneralPostingSetup.FindSet() then
            repeat
                if GLAccount.Get(GeneralPostingSetup."Purch. Account") and (GLAccount."NCFCategories_DXR" <> '') then begin
                    NCFCategory := GLAccount."NCFCategories_DXR";
                    exit(true);
                end;
            until GeneralPostingSetup.Next() = 0;

        exit(false);
    end;

    // ===== seq16: NAV POS Customer legacy table restore (54128 -> 52175) =====
    // Ported from MigrateTable_NAVPOSCustomer() (~line 3490). Whole-table clone in DR-Localization
    // own source, using NewRec.TransferFields(OldRec, true) - expanded below into explicit,
    // per-field typed assignment (TransferFields is banned plan-wide in this MCC project). Real
    // source also has a fast-path branch using "DXR_Background Data Transfer"
    // (AddFieldValue/CopyRows) when the new table is still empty; that branch is intentionally NOT
    // ported (Global Constraint: zero-RecordRef/zero-FieldRef/zero-TransferFields plan-wide -
    // DataTransfer's AddFieldValue/CopyRows operate on the same field-number-matching mechanism
    // internally). The always-manual typed loop below (the real source's OWN fallback branch, used
    // when the new table already has data) is used unconditionally instead - functionally
    // equivalent, just without the bulk-copy performance optimization for a first-time run against
    // an empty target on a very large legacy table.
    local procedure BootstrapNAVPOSCustomerTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NAVPOSCUSTOMER-20260522') then begin
            MigrateNAVPOSCustomerTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-NAVPOSCUSTOMER-20260522');
        end;
    end;

    local procedure MigrateNAVPOSCustomerTable()
    var
        NAVPOSCustomerOld: Record "DXNAV_POS_Customer";
        NAVPOSCustomerNew: Record "DXR_NAV_POS_Customer";
    begin
        if NAVPOSCustomerOld.IsEmpty() then
            exit;
        if NAVPOSCustomerOld.FindSet() then
            repeat
                NAVPOSCustomerNew.No := NAVPOSCustomerOld.No;
                NAVPOSCustomerNew.CodCliePOS := NAVPOSCustomerOld.CodCliePOS;
                NAVPOSCustomerNew.Name := NAVPOSCustomerOld.Name;
                NAVPOSCustomerNew.Address := NAVPOSCustomerOld.Address;
                NAVPOSCustomerNew.City := NAVPOSCustomerOld.City;
                NAVPOSCustomerNew.PhoneNo := NAVPOSCustomerOld.PhoneNo;
                NAVPOSCustomerNew.BalanceDue := NAVPOSCustomerOld.BalanceDue;
                NAVPOSCustomerNew.CreditLimit := NAVPOSCustomerOld.CreditLimit;
                NAVPOSCustomerNew.Document := NAVPOSCustomerOld.Document;
                NAVPOSCustomerNew.PaymentTermsCode := NAVPOSCustomerOld.PaymentTermsCode;
                NAVPOSCustomerNew.CustomerPostingGroup := NAVPOSCustomerOld.CustomerPostingGroup;
                NAVPOSCustomerNew.ForCheckBankCode := NAVPOSCustomerOld.ForCheckBankCode;
                NAVPOSCustomerNew.ForCheckBankAccountNo := NAVPOSCustomerOld.ForCheckBankAccountNo;
                NAVPOSCustomerNew.ForCheckLimit := NAVPOSCustomerOld.ForCheckLimit;
                NAVPOSCustomerNew.ForCheckStatus := NAVPOSCustomerOld.ForCheckStatus;
                NAVPOSCustomerNew.CorpClientCode := NAVPOSCustomerOld.CorpClientCode;
                NAVPOSCustomerNew.CorpBalance := NAVPOSCustomerOld.CorpBalance;
                NAVPOSCustomerNew.PayrollNo := NAVPOSCustomerOld.PayrollNo;
                NAVPOSCustomerNew.PayrollPostingDate := NAVPOSCustomerOld.PayrollPostingDate;
                if not NAVPOSCustomerNew.Insert(false) then
                    NAVPOSCustomerNew.Modify(false);
            until NAVPOSCustomerOld.Next() = 0;
    end;

    // ===== seq17: Extract Cards legacy table restore (54120 -> 52160) =====
    // Ported from MigrateTable_ExtractCards() (~line 3222). Same shape/reasoning as
    // MigrateNAVPOSCustomerTable() above (whole-table clone, TransferFields expanded per-field,
    // DataTransfer fast-path branch intentionally not ported).
    local procedure BootstrapExtractCardsTable()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-EXTRACTCARDS-20260522') then begin
            MigrateExtractCardsTable();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-EXTRACTCARDS-20260522');
        end;
    end;

    local procedure MigrateExtractCardsTable()
    var
        ExtractCardsOld: Record "DXExtract Cards";
        ExtractCardsNew: Record "DXR_Extract Cards";
    begin
        if ExtractCardsOld.IsEmpty() then
            exit;
        if ExtractCardsOld.FindSet() then
            repeat
                ExtractCardsNew."Cuenta Banco" := ExtractCardsOld."Cuenta Banco";
                ExtractCardsNew."Fecha Posteo" := ExtractCardsOld."Fecha Posteo";
                ExtractCardsNew."No Referencia" := ExtractCardsOld."No Referencia";
                ExtractCardsNew."Monto Transaccion" := ExtractCardsOld."Monto Transaccion";
                ExtractCardsNew.Credito := ExtractCardsOld.Credito;
                ExtractCardsNew.Debito := ExtractCardsOld.Debito;
                ExtractCardsNew.Peaje := ExtractCardsOld.Peaje;
                ExtractCardsNew.Descripcion := ExtractCardsOld.Descripcion;
                ExtractCardsNew."No. Afiliado" := ExtractCardsOld."No. Afiliado";
                ExtractCardsNew.NCF := ExtractCardsOld.NCF;
                ExtractCardsNew."Ind Peaje" := ExtractCardsOld."Ind Peaje";
                ExtractCardsNew."No. Lote" := ExtractCardsOld."No. Lote";
                ExtractCardsNew.Estacion := ExtractCardsOld.Estacion;
                if not ExtractCardsNew.Insert(false) then
                    ExtractCardsNew.Modify(false);
            until ExtractCardsOld.Next() = 0;
    end;

    // ===== seq18: Gubernamentales(623) legacy table restore (54155 -> 52220) =====
    // Ported from MigrateTable_Gubernamentales623() (~line 3294). Whole-table clone, TransferFields
    // expanded per-field. Real source has no IsEmpty() guard for this one table either (same as
    // MigrateNCFSalesSetupTable() above) - ported exactly as-is.
    local procedure BootstrapGubernamentales623Table()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-GUBERNAMENTALES623-20260522') then begin
            MigrateGubernamentales623Table();
            UpgradeTag.SetUpgradeTag('DX-INTERNAL-CLOSURE-TABLE-GUBERNAMENTALES623-20260522');
        end;
    end;

    local procedure MigrateGubernamentales623Table()
    var
        Gubernamentales623Old: Record "DXGubernamentales(623)";
        Gubernamentales623New: Record "DXR_Gubernamentales(623)";
    begin
        if Gubernamentales623Old.FindSet() then
            repeat
                Gubernamentales623New."No." := Gubernamentales623Old."No.";
                Gubernamentales623New."No. Linea" := Gubernamentales623Old."No. Linea";
                Gubernamentales623New."Cod. Cliente" := Gubernamentales623Old."Cod. Cliente";
                Gubernamentales623New."Nombre Cliente" := Gubernamentales623Old."Nombre Cliente";
                Gubernamentales623New.RNC := Gubernamentales623Old.RNC;
                Gubernamentales623New."Fecha Registro" := Gubernamentales623Old."Fecha Registro";
                Gubernamentales623New."Fecha Retencion" := Gubernamentales623Old."Fecha Retencion";
                Gubernamentales623New."No. Referencia" := Gubernamentales623Old."No. Referencia";
                // Explicit conversion required - different Enum objects (DXR_TipoReferencia623 vs.
                // legacy DXTipoReferencia623), identical 3-value set (0=" ", 1=Transferencia,
                // 2=Cheque - confirmed against Base/Enums/DXR_TipoReferencia623.Enum.al and
                // Base/Enums.old/DXTipoReferencia623.Enum.al).
                Gubernamentales623New."Tipo Referencia" :=
                    Enum::"DXR_TipoReferencia623".FromInteger(Gubernamentales623Old."Tipo Referencia".AsInteger());
                Gubernamentales623New."Valor Retencion" := Gubernamentales623Old."Valor Retencion";
                Gubernamentales623New."Nombre Banco" := Gubernamentales623Old."Nombre Banco";
                Gubernamentales623New.Periodo := Gubernamentales623Old.Periodo;
                if not Gubernamentales623New.Insert(false) then
                    Gubernamentales623New.Modify(false);
            until Gubernamentales623Old.Next() = 0;
    end;
}
