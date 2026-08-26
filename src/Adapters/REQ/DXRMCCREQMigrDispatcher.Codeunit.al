// =============================================================================================
// PROPOSED REGISTRY ENTRIES (for a human to add to src/DXRMCCRegistryLoader.Codeunit.al -
// NOT added there by this task). Order No. 1020 per task instructions. Dispatcher IDs point at
// the category workers in DXRMCCREQCategoryWorkers.Codeunit.al (60651-60654), matching how every
// other adapter registers per-category codeunits rather than the shared Migr Dispatcher (60650)
// itself.
//
//   InsExt('REQ', 'Requisitions', '4805fd15-75a5-46a2-952f-39c1c4eab821', 1020,
//       'Draft adapter added 2026-08-26. Own native upgrade framework (56173-56180) exists on
//       the Requisitions side but is Access = Internal and not in app.json''s
//       internalsVisibleTo, so this adapter re-implements the 7 old/new table pairs and 2
//       TableExtension field pairs directly. Pending human review before enabling.');
//
//   InsConcept('REQ', 'REQ-P1', 1, 'Requsiciones Setup legacy table restore (56156 -> 56163)', 60651, 56156, 56163, 'SETUP');
//   InsConcept('REQ', 'REQ-P1', 2, 'User Setup approval-flag field restore (5 fields, incl. Responsibility Center)', 60652, 0, 0, 'MASTER');
//   InsConcept('REQ', 'REQ-P1', 3, 'Proveedores Requisiciones legacy table restore (56150 -> 56157)', 60653, 56150, 56157, 'OTHER');
//   InsConcept('REQ', 'REQ-P1', 4, 'Requisiciones Header legacy table restore (56151 -> 56158)', 60653, 56151, 56158, 'OTHER');
//   InsConcept('REQ', 'REQ-P1', 5, 'Requisiciones Lines legacy table restore (56153 -> 56160)', 60653, 56153, 56160, 'OTHER');
//   InsConcept('REQ', 'REQ-P1', 6, 'Quotation legacy table restore (56155 -> 56162)', 60653, 56155, 56162, 'OTHER');
//   InsConcept('REQ', 'REQ-P1', 7, 'Purchase Header Req. No. field restore', 60653, 0, 0, 'OTHER');
//   InsConcept('REQ', 'REQ-P1', 8, 'Req. Header Hist legacy table restore (56152 -> 56159)', 60654, 56152, 56159, 'HIST');
//   InsConcept('REQ', 'REQ-P1', 9, 'Req.LinesHistory legacy table restore (56154 -> 56161)', 60654, 56154, 56161, 'HIST');
//
// NOTE: do not pass 'MA' as CategoryCode for this extension - NormalizeLegacyCategory() in
// DXRMCCRegistryLoader.Codeunit.al only rewrites 'MA' via a per-ExtCode allow-list
// (IsLegacyMasterConcept); 'REQ' is not in that list, so any 'MA' row would silently normalize to
// 'ACCOUNTING' instead of 'MASTER'. Explicit 'SETUP'/'MASTER'/'OTHER'/'HIST' above avoid that trap.
// =============================================================================================

// =============================================================================================
// DRAFT ADAPTER - "Requisitions" (App ID 4805fd15-75a5-46a2-952f-39c1c4eab821), Adapter code REQ.
// Entire file body is wrapped in a comment block, matching src/Adapters/TU's convention for a
// not-yet-enabled/compiled draft awaiting human review. Do NOT remove the /* */ wrapper without
// a reviewer confirming table/field names, category assignments and Upgrade Tag strings below.
//
// SOURCE: extracted from the compiled package .alpackages/Dextra_Requisitions_28.3.0.1.app's own
// SymbolReference.json (no source .al files for this extension are present in this repo). All
// table/field IDs, names and types below were read directly from that symbol table.
//
// WHAT WAS FOUND (old -> new renumbered table pairs, matching the "DXTB..." / "DX..." old-name
// vs "DXR_..." new-name convention used across this extension - there is no "_Old"/"_Old2"
// suffix generation here, unlike TU/VP):
//   56150 "DXTB Proveedores Requisiciones" -> 56157 "DXR_Proveedores Requisiciones"
//   56151 "DXTB Requisiciones Header"      -> 56158 "DXR_Requisiciones Header"
//   56152 "DX Req. Header Hist"            -> 56159 "DXR_Req. Header Hist"
//   56153 "DXTB Requisiciones Lines"       -> 56160 "DXR_Requisiciones Lines"
//   56154 "DXTBReq.LinesHistory"           -> 56161 "DXR_Req.LinesHistory"
//   56155 "DXTB Quotation"                 -> 56162 "DXR_Quotation"
//   56156 "DXTB Requsiciones Setup"        -> 56163 "DXR_Requsiciones Setup"
// All 14 tables have Access = <blank> (public) in the symbol table - no internalsVisibleTo gap
// for these; no app.json change needed on the table side.
//
// Plus two TableExtensions on core BC tables, each renaming an old field to a "_DXR"-suffixed
// new field (both old and new columns coexist on the same core table row - no separate legacy
// table to read from):
//   Purchase Header (18): "Req. No." (50150, Code[50]) -> "Req. No._DXR" (50151, Code[50])
//   User Setup (91):
//     "Approve Requisitions" (50150, Boolean)              -> "Approve Requisitions_DXR" (50155)
//     "Quotation Process Requisitions" (50151, Boolean)    -> "Quotation Process Req_DXR" (50156)
//     "Comparative Analysis Req" (50152, Boolean)          -> "Comparative Analysis Req_DXR" (50157)
//     "CLOSED Requisitions" (50153, Boolean)                -> "CLOSED Requisitions_DXR" (50158)
//     "Responsibility Center" (50154, Code[10])             -> "Responsibility Center_DXR" (50159)
//
// IMPORTANT - this extension already ships its OWN native migration framework (mirrors exactly
// what TU has): codeunit 56173 "DXR_Req Migr Dispatcher" (Subtype = Upgrade, so it self-runs on
// BC's per-tenant extension upgrade) orchestrates 56174-56177 "DXR_Req Migr Phase 1..4", plus
// 56178 "DXR_Req Migr Scheduler", 56179 "DXR_Req Migr Retry Mgt", 56180 "DXR_Req Migr Tags", all
// of which are Access = Internal. Table 56164 "DXR_Req Migr Status" (also Access = Internal,
// tracks Company/Phase/Progress/Result/Errors/Attempts) is that framework's own status log - it
// is NOT one of the old/new data pairs above and is not migrated by this adapter.
//
// TODO(app.json): "Requisitions" (4805fd15-75a5-46a2-952f-39c1c4eab821) is NOT in app.json's
// internalsVisibleTo (currently only "Facturacion Electronica" and "Base App DR Localization").
// That is why this dispatcher does NOT call into 56173-56180 directly and instead re-implements
// the same field-for-field copies below using only typed Records against PUBLIC tables (the 7
// pairs above, plus Purchase Header/User Setup which are core BC tables, always public) - exactly
// TU's own resolution when its equivalent internal codeunits were unreachable. If a reviewer
// later decides MCC should defer to Requisitions' own upgrade codeunits instead of duplicating
// their logic, add this app's ID to internalsVisibleTo and widen Access on 56174-56180 on the
// Requisitions side (do not widen Access from MCC's side).
//
// VERIFIED against the app's own symbol table (2026-08-26):
// - "Status" on 56151/56158 and 56152/56159 uses two DISTINCT Enum types across old/new
//   (DXStatusRequesicion 56151, ObsoleteState=Pending -> DXR_StatusRequesicion 56153), but with
//   an identical 9-value list at identical ordinals (New=0 .. Return=8) - migrated below via
//   "DXR_StatusRequesicion".FromInteger(Old.Status.AsInteger()), not a direct assignment.
// - "Type Item" on 56153/56154/56155 and 56160/56161/56162 uses the SAME base-app Enum
//   ("Purchase Line Type", ModuleId 437dbf0e-84ff-417a-965d-ed2bb9650972, Id 39) on both old and
//   new sides - a direct assignment is correct as-is, no conversion needed.
// =============================================================================================


codeunit 60650 "DXR MCC REQ Migr Dispatcher"
{
    // Native local migration - re-implements Requisitions' own (Access = Internal, unreachable)
    // upgrade-phase field copies as direct typed-Record assignments. No TransferFields, no
    // RecordRef/FieldRef - every source/target table below is public.
    Permissions =
        tabledata "DXTB Proveedores Requisiciones" = R,
        tabledata "DXR_Proveedores Requisiciones" = RIM,
        tabledata "DXTB Requisiciones Header" = R,
        tabledata "DXR_Requisiciones Header" = RIM,
        tabledata "DX Req. Header Hist" = R,
        tabledata "DXR_Req. Header Hist" = RIM,
        tabledata "DXTB Requisiciones Lines" = R,
        tabledata "DXR_Requisiciones Lines" = RIM,
        tabledata "DXTBReq.LinesHistory" = R,
        tabledata "DXR_Req.LinesHistory" = RIM,
        tabledata "DXTB Quotation" = R,
        tabledata "DXR_Quotation" = RIM,
        tabledata "DXTB Requsiciones Setup" = R,
        tabledata "DXR_Requsiciones Setup" = RIM,
        tabledata "Purchase Header" = RM,
        tabledata "User Setup" = RM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
        RunOther();
        RunHistoric();
    end;

    procedure RunSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(SetupMigrationTag()) then begin
            MigrateSetup();
            UpgradeTag.SetUpgradeTag(SetupMigrationTag());
        end;
    end;

    procedure RunMaster()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(UserSetupFieldMigrationTag()) then begin
            MigrateUserSetupFields();
            UpgradeTag.SetUpgradeTag(UserSetupFieldMigrationTag());
        end;
    end;

    // "Other" bundles the active (non-history) transactional/document tables - none of Setup,
    // Master or Accounting is a clean fit for a Requisition header/line/quotation/vendor-list row,
    // matching this registry's own precedent that 'OTHER' is "the honest scope" when nothing else
    // fits (see DXRMCCRegistryLoader.Codeunit.al's BC-PERM seq19 comment).
    procedure RunOther()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(ProveedoresMigrationTag()) then begin
            MigrateProveedoresRequisiciones();
            UpgradeTag.SetUpgradeTag(ProveedoresMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(HeaderMigrationTag()) then begin
            MigrateHeader();
            UpgradeTag.SetUpgradeTag(HeaderMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(LinesMigrationTag()) then begin
            MigrateLines();
            UpgradeTag.SetUpgradeTag(LinesMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(QuotationMigrationTag()) then begin
            MigrateQuotation();
            UpgradeTag.SetUpgradeTag(QuotationMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(PurchHeaderFieldMigrationTag()) then begin
            MigratePurchaseHeaderField();
            UpgradeTag.SetUpgradeTag(PurchHeaderFieldMigrationTag());
        end;
    end;

    procedure RunHistoric()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(HeaderHistMigrationTag()) then begin
            MigrateHeaderHist();
            UpgradeTag.SetUpgradeTag(HeaderHistMigrationTag());
        end;

        if not UpgradeTag.HasUpgradeTag(LinesHistMigrationTag()) then begin
            MigrateLinesHist();
            UpgradeTag.SetUpgradeTag(LinesHistMigrationTag());
        end;
    end;

    // 56156 "DXTB Requsiciones Setup" -> 56163 "DXR_Requsiciones Setup". Field-for-field
    // identical (same IDs/names/types on both sides, confirmed against the app's own symbol
    // table). Single-instance setup table keyed on "Key" (Integer, always 0).
    local procedure MigrateSetup()
    var
        OldSetup: Record "DXTB Requsiciones Setup";
        NewSetup: Record "DXR_Requsiciones Setup";
    begin
        if OldSetup.FindSet() then
            repeat
                if not NewSetup.Get(OldSetup."Key") then begin
                    NewSetup.Init();
                    NewSetup."Key" := OldSetup."Key";
                    NewSetup."Active Requesicion GAP" := OldSetup."Active Requesicion GAP";
                    NewSetup."No. Series de Requisicion" := OldSetup."No. Series de Requisicion";
                    NewSetup."No. Series de Cotizacion" := OldSetup."No. Series de Cotizacion";
                    NewSetup."No. Series de Order" := OldSetup."No. Series de Order";
                    NewSetup.Insert(false);
                end;
            until OldSetup.Next() = 0;
    end;

    // 56150 "DXTB Proveedores Requisiciones" -> 56157 "DXR_Proveedores Requisiciones". Fields 3-5
    // ("Name"/"Telefono"/"Email") are FlowFields on both sides and are excluded, matching
    // TransferFields' own behavior.
    local procedure MigrateProveedoresRequisiciones()
    var
        OldRec: Record "DXTB Proveedores Requisiciones";
        NewRec: Record "DXR_Proveedores Requisiciones";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."RequisitionNo.", OldRec."VendorNo.") then begin
                    NewRec.Init();
                    NewRec."RequisitionNo." := OldRec."RequisitionNo.";
                    NewRec."VendorNo." := OldRec."VendorNo.";
                    NewRec.Insert(false);
                end;
            until OldRec.Next() = 0;
    end;

    // 56151 "DXTB Requisiciones Header" -> 56158 "DXR_Requisiciones Header". Field-for-field
    // identical (same IDs/names/types on both sides, confirmed against the app's own symbol
    // table) EXCEPT Status: old uses Enum "DXStatusRequesicion" (56151, ObsoleteState=Pending),
    // new uses Enum "DXR_StatusRequesicion" (56153) - two distinct Enum types, so a direct
    // assignment does not compile even though both enums carry the identical 9-value list at the
    // identical ordinals (New=0 .. Return=8, confirmed against the app's own symbol table). Convert
    // through the integer value instead. Field 18 does not exist on either side (a gap in the
    // original numbering) - nothing to migrate there.
    local procedure MigrateHeader()
    var
        OldHeader: Record "DXTB Requisiciones Header";
        NewHeader: Record "DXR_Requisiciones Header";
    begin
        if OldHeader.FindSet() then
            repeat
                if not NewHeader.Get(OldHeader."No Documento") then begin
                    NewHeader.Init();
                    NewHeader."No Documento" := OldHeader."No Documento";
                    NewHeader.Dpto := OldHeader.Dpto;
                    NewHeader."Location Code" := OldHeader."Location Code";
                    NewHeader."Creation date" := OldHeader."Creation date";
                    NewHeader."Creation Time" := OldHeader."Creation Time";
                    NewHeader."Creation User" := OldHeader."Creation User";
                    NewHeader.Status := "DXR_StatusRequesicion".FromInteger(OldHeader.Status.AsInteger());
                    NewHeader."Suggested Supplier" := OldHeader."Suggested Supplier";
                    NewHeader."Reason for the Request" := OldHeader."Reason for the Request";
                    NewHeader."Approver User" := OldHeader."Approver User";
                    NewHeader."Approver Date" := OldHeader."Approver Date";
                    NewHeader."Approval Time" := OldHeader."Approval Time";
                    NewHeader.activar := OldHeader.activar;
                    NewHeader."Shortcut Dimension 1 Code" := OldHeader."Shortcut Dimension 1 Code";
                    NewHeader."Shortcut Dimension 2 Code" := OldHeader."Shortcut Dimension 2 Code";
                    NewHeader."Requesting User" := OldHeader."Requesting User";
                    NewHeader."Requesting User Id" := OldHeader."Requesting User Id";
                    NewHeader."Release date" := OldHeader."Release date";
                    NewHeader."Release Time" := OldHeader."Release Time";
                    NewHeader."Release User" := OldHeader."Release User";
                    NewHeader.Insert(false);
                end;
            until OldHeader.Next() = 0;
    end;

    // 56152 "DX Req. Header Hist" -> 56159 "DXR_Req. Header Hist". Field-for-field identical
    // (same IDs/names/types on both sides). This is its own independent history table (not a
    // copy of the Header pair above) - "No Documento" is Code[50] here vs Code[20] on the live
    // Header, and "Approver User" is Text[100] here vs Text[50] on the live Header. Status has the
    // same old/new Enum-type split as the live Header (DXStatusRequesicion 56151 ->
    // DXR_StatusRequesicion 56153, identical 9-value ordinal list) - converted the same way.
    local procedure MigrateHeaderHist()
    var
        OldHist: Record "DX Req. Header Hist";
        NewHist: Record "DXR_Req. Header Hist";
    begin
        if OldHist.FindSet() then
            repeat
                if not NewHist.Get(OldHist."No Documento", OldHist.Codigo) then begin
                    NewHist.Init();
                    NewHist."No Documento" := OldHist."No Documento";
                    NewHist.Codigo := OldHist.Codigo;
                    NewHist."Location Code" := OldHist."Location Code";
                    NewHist."Creation date" := OldHist."Creation date";
                    NewHist."Creation Time" := OldHist."Creation Time";
                    NewHist."Creation User" := OldHist."Creation User";
                    NewHist.Status := "DXR_StatusRequesicion".FromInteger(OldHist.Status.AsInteger());
                    NewHist."Suggested Supplier" := OldHist."Suggested Supplier";
                    NewHist."Reason for the Request" := OldHist."Reason for the Request";
                    NewHist."Approver User" := OldHist."Approver User";
                    NewHist."Approver Date" := OldHist."Approver Date";
                    NewHist."Approval Time" := OldHist."Approval Time";
                    NewHist.activar := OldHist.activar;
                    NewHist.Dpto := OldHist.Dpto;
                    NewHist.UserReqID := OldHist.UserReqID;
                    NewHist."Name of the Applicant" := OldHist."Name of the Applicant";
                    NewHist."Release date" := OldHist."Release date";
                    NewHist."Release Time" := OldHist."Release Time";
                    NewHist."Release User" := OldHist."Release User";
                    NewHist."Requesting User" := OldHist."Requesting User";
                    NewHist.Insert(false);
                end;
            until OldHist.Next() = 0;
    end;

    // 56153 "DXTB Requisiciones Lines" -> 56160 "DXR_Requisiciones Lines". Field-for-field
    // identical (same IDs/names/types on both sides, confirmed against the app's own symbol
    // table).
    local procedure MigrateLines()
    var
        OldLine: Record "DXTB Requisiciones Lines";
        NewLine: Record "DXR_Requisiciones Lines";
    begin
        if OldLine.FindSet() then
            repeat
                if not NewLine.Get(OldLine."No.Documento", OldLine."No.Lines") then begin
                    NewLine.Init();
                    NewLine."No.Documento" := OldLine."No.Documento";
                    NewLine."No.Lines" := OldLine."No.Lines";
                    NewLine.ITEMNo := OldLine.ITEMNo;
                    NewLine.Description := OldLine.Description;
                    NewLine."Unidad de Medida" := OldLine."Unidad de Medida";
                    NewLine.Qty := OldLine.Qty;
                    NewLine."Qty Aprobadas" := OldLine."Qty Aprobadas";
                    NewLine."Qty Restante" := OldLine."Qty Restante";
                    NewLine.Reference := OldLine.Reference;
                    NewLine."Type Item" := OldLine."Type Item";
                    NewLine."Location Code" := OldLine."Location Code";
                    NewLine."G/L Account No." := OldLine."G/L Account No.";
                    NewLine."Unit Cost" := OldLine."Unit Cost";
                    NewLine."Shortcut Dimension 1 Code" := OldLine."Shortcut Dimension 1 Code";
                    NewLine."Shortcut Dimension 2 Code" := OldLine."Shortcut Dimension 2 Code";
                    NewLine.Insert(false);
                end;
            until OldLine.Next() = 0;
    end;

    // 56154 "DXTBReq.LinesHistory" -> 56161 "DXR_Req.LinesHistory". Field-for-field identical
    // (same IDs/names/types on both sides). Field 9 does not exist on either side (a gap in the
    // original numbering) - nothing to migrate there.
    local procedure MigrateLinesHist()
    var
        OldHist: Record "DXTBReq.LinesHistory";
        NewHist: Record "DXR_Req.LinesHistory";
    begin
        if OldHist.FindSet() then
            repeat
                if not NewHist.Get(OldHist."No.Documento", OldHist."No.") then begin
                    NewHist.Init();
                    NewHist."No.Documento" := OldHist."No.Documento";
                    NewHist."No." := OldHist."No.";
                    NewHist.ITEMNo := OldHist.ITEMNo;
                    NewHist.Description := OldHist.Description;
                    NewHist."Unidad de Medida" := OldHist."Unidad de Medida";
                    NewHist.Qty := OldHist.Qty;
                    NewHist."Qty Aprobadas" := OldHist."Qty Aprobadas";
                    NewHist."Qty Restante" := OldHist."Qty Restante";
                    NewHist."Creation date" := OldHist."Creation date";
                    NewHist."Creation Time" := OldHist."Creation Time";
                    NewHist."Creation User" := OldHist."Creation User";
                    NewHist."No.Lines" := OldHist."No.Lines";
                    NewHist."Type Item" := OldHist."Type Item";
                    NewHist."Location Code" := OldHist."Location Code";
                    NewHist.Insert(false);
                end;
            until OldHist.Next() = 0;
    end;

    // 56155 "DXTB Quotation" -> 56162 "DXR_Quotation". Field-for-field identical (same
    // IDs/names/types on both sides, confirmed against the app's own symbol table).
    local procedure MigrateQuotation()
    var
        OldQuote: Record "DXTB Quotation";
        NewQuote: Record "DXR_Quotation";
    begin
        if OldQuote.FindSet() then
            repeat
                if not NewQuote.Get(OldQuote."No. Cotizacion", OldQuote."No. Linea", OldQuote."No. Producto") then begin
                    NewQuote.Init();
                    NewQuote."No. Cotizacion" := OldQuote."No. Cotizacion";
                    NewQuote."No. Linea" := OldQuote."No. Linea";
                    NewQuote."No. Producto" := OldQuote."No. Producto";
                    NewQuote.Qty := OldQuote.Qty;
                    NewQuote."Qty Approved" := OldQuote."Qty Approved";
                    NewQuote."No Documento" := OldQuote."No Documento";
                    NewQuote.supplier := OldQuote.supplier;
                    NewQuote.Price := OldQuote.Price;
                    NewQuote."Total Price" := OldQuote."Total Price";
                    NewQuote."Type Item" := OldQuote."Type Item";
                    NewQuote."Location Code" := OldQuote."Location Code";
                    NewQuote.Insert(false);
                end;
            until OldQuote.Next() = 0;
    end;

    // TableExtension on core BC table 18 "Purchase Header": "Req. No." (50150, Code[50]) ->
    // "Req. No._DXR" (50151, Code[50]). Both columns live on the same Purchase Header row, so
    // this is a Modify, not an Insert - matching TU's own Customer/Cust. Ledger Entry field-copy
    // pattern (direct field assignment, no TransferFields).
    local procedure MigratePurchaseHeaderField()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if PurchaseHeader.FindSet(true) then
            repeat
                PurchaseHeader."Req. No._DXR" := PurchaseHeader."Req. No.";
                PurchaseHeader.Modify(false);
            until PurchaseHeader.Next() = 0;
    end;

    // TableExtension on core BC table 91 "User Setup": 5 old approval-flag fields -> 5 "_DXR"
    // new fields (4x Boolean + 1x Code[10] "Responsibility Center"). Direct field assignment, no
    // TransferFields - matching TU's own User/Customer field-copy pattern.
    local procedure MigrateUserSetupFields()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.FindSet(true) then
            repeat
                UserSetup."Approve Requisitions_DXR" := UserSetup."Approve Requisitions";
                UserSetup."Quotation Process Req_DXR" := UserSetup."Quotation Process Requisitions";
                UserSetup."Comparative Analysis Req_DXR" := UserSetup."Comparative Analysis Req";
                UserSetup."CLOSED Requisitions_DXR" := UserSetup."CLOSED Requisitions";
                UserSetup."Responsibility Center_DXR" := UserSetup."Responsibility Center";
                UserSetup.Modify(false);
            until UserSetup.Next() = 0;
    end;

    local procedure SetupMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-SETUP-20260826.');
    end;

    local procedure ProveedoresMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-PROVEEDORES-20260826.');
    end;

    local procedure HeaderMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-HEADER-20260826.');
    end;

    local procedure HeaderHistMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-HEADERHIST-20260826.');
    end;

    local procedure LinesMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-LINES-20260826.');
    end;

    local procedure LinesHistMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-LINESHIST-20260826.');
    end;

    local procedure QuotationMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-QUOTATION-20260826.');
    end;

    local procedure PurchHeaderFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-PURCHHEADERFIELD-20260826.');
    end;

    local procedure UserSetupFieldMigrationTag(): Code[250]
    begin
        exit('DXR-MCC-REQ-USERSETUPFIELD-20260826.');
    end;
}
