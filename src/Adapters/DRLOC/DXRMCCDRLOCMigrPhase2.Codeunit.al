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
        tabledata "VAT Product Posting Group" = RM;

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
}
