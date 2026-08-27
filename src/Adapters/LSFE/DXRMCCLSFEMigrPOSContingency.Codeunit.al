#if not BCDX
codeunit 60145 "DXR MCC LSFE Migr POS Cont."
{
    // Native local migration - ported verbatim from LS Facturacion Electronica's own
    // "DXR_LSFE Migr. POS Contingency" (52590) -> "DXR_LSFE Upgrade".UpgradeLegacyFieldsToDXR() +
    // "DXR_LSFE Upgrade".UpgradePOSContingencyAuthority() (both internal procedure calls on a
    // typed Subtype = Upgrade codeunit variable - never .Run()/OnRun, same pre-existing pattern
    // the deleted delegation adapter itself already used and documented as safe). Both real
    // methods call MigrateTransactions() internally with no procedure-local Upgrade Tag guard of
    // its own (only each OUTER method has a tag) - preserved verbatim, including the resulting
    // double-invocation of MigrateTransactions() when both outer tags are unset in the same run:
    // harmless since every field copy inside it is itself an "only if blank" guard, and this
    // matches the exact behavior the deleted delegation adapter already had (it called both real
    // methods in the same order every time it ran).
    //
    // Extended 2026-08-27 (retroactive repair - RepairLegacyTransactionFieldsIfNeeded below).
    // The ported UpgradeLegacyFieldsToDXR()/UpgradePOSContingencyAuthority() above reproduce the
    // real "DXR_LSFE Upgrade" verbatim, INCLUDING a gap in it: MigrateTransactions() only carries
    // forward 6 of the 14 fields that the "LSEF LSC Transaction Header" tableextension (field IDs
    // 55600-55613, every one ObsoleteState = Pending) renumbered into "DXR_LEF LSC Trans. Header"
    // (52554-52570), and nothing anywhere migrates "LSEF LSC Trans. Sales Entry" (55600-55603) into
    // "DXR_LEF LSC Trans Sales Entry" (52554-52557) at all. Verified field by field against
    // Dextra_facturacion-electronica-ls_28.5.0.4.app - the exact dependency symbol package this
    // project compiles against - in src\Base\old\TableExts.old\ (sources) vs src\Base\TableExts\
    // (destinations).
    // This is not cosmetic. LSFE's own DXR_LSFERetailEvents.Codeunit.al decides whether a
    // transaction still needs to be stamped/sent by testing "Security Code_DXR" and
    // "Stamped Date/Time_DXR" for blank, so historical transactions that WERE already stamped come
    // back as pending-to-send once their value is stranded on the un-migrated 55xxx field.
    // Both existing tags ('DXR-LSFE-FIELD-MIGRATION-20260820' and
    // 'LSEF-POS-CONTINGENCY-AUTHORITY-27.2') are already set in production, so neither can be
    // reused to ship this correction - a company that already ran them would skip it forever. The
    // repair is therefore a SIBLING step with its own new tag, evaluated on every run regardless of
    // how far that company got before (the retroactive-repair pattern this portfolio already uses).
    Permissions =
        tabledata "LSC Transaction Header" = RM,
        tabledata "LSC Trans. Sales Entry" = RM,
        tabledata "LSC POS Terminal" = RM,
        tabledata "EF Administration Setup" = R,
        tabledata "DXR_Administration Setup" = RIMD,
        tabledata "LSDXTender Types Relation" = R,
        tabledata "DXR_LS Tender Types Relation" = RIMD,
        tabledata "EF Process Request" = R,
        tabledata "DXR_Process Request" = RM,
        tabledata "EF Resend Document Queue" = R,
        tabledata "DXR_Resend Document Queue" = RM;

    trigger OnRun()
    begin
        UpgradeLegacyFieldsToDXR();
        UpgradePOSContingencyAuthority();
        RepairLegacyTransactionFieldsIfNeeded();
    end;

    local procedure UpgradeLegacyFieldsToDXR()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-LSFE-FIELD-MIGRATION-20260820') then
            exit;

        MigrateTransactions();
        MigrateAdministrationSetup();
        MigrateTenderTypeRelations();
        MigrateProcessRequests();
        MigrateResendDocumentQueue();

        UpgradeTag.SetUpgradeTag('DXR-LSFE-FIELD-MIGRATION-20260820');
    end;

    local procedure UpgradePOSContingencyAuthority()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('LSEF-POS-CONTINGENCY-AUTHORITY-27.2') then
            exit;

        MigrateTransactions();
        MigrateTerminals();

        UpgradeTag.SetUpgradeTag('LSEF-POS-CONTINGENCY-AUTHORITY-27.2');
    end;

    local procedure MigrateTransactions()
    var
        TransactionHeader: Record "LSC Transaction Header";
        Changed: Boolean;
        RowsSinceCommit: Integer;
    begin
        if TransactionHeader.FindSet(true) then
            repeat
                Changed := false;
                if (TransactionHeader."DGII Message_DXR" = '') and (TransactionHeader."EF DGII Message" <> '') then begin
                    TransactionHeader."DGII Message_DXR" := TransactionHeader."EF DGII Message";
                    Changed := true;
                end;
                if (TransactionHeader."Status_DXR".AsInteger() = 0) and (TransactionHeader."EF Status".AsInteger() <> 0) then begin
                    TransactionHeader."Status_DXR" := TransactionHeader."EF Status";
                    Changed := true;
                end;
                // Carry forward values left on the pre-renumbering fields (tableextension
                // "LSEF LSC Transaction Header", field IDs 55600-55613, ObsoleteState = Pending)
                // before falling through to the newer "_DXR" chain below.
                CopyIfBlank(TransactionHeader."Alternal NCF_DXR", TransactionHeader."LSEF Alternal NCF", Changed);
                CopyIfBlank(TransactionHeader."Alt NCF Srl No._DXR", TransactionHeader."LSEF Alternal NCF Serial No.", Changed);
                if (not TransactionHeader."Has Contingencies_DXR") and TransactionHeader."LSEF Has Contingencies" then begin
                    TransactionHeader."Has Contingencies_DXR" := true;
                    Changed := true;
                end;

                if (TransactionHeader."Alternate NCF_DXR" = '') and (TransactionHeader."Alternal NCF_DXR" <> '') then begin
                    TransactionHeader."Alternate NCF_DXR" := TransactionHeader."Alternal NCF_DXR";
                    Changed := true;
                end;
                if (TransactionHeader."Alternate No. Series_DXR" = '') and (TransactionHeader."Alt NCF Srl No._DXR" <> '') then begin
                    TransactionHeader."Alternate No. Series_DXR" := TransactionHeader."Alt NCF Srl No._DXR";
                    Changed := true;
                end;
                if (not TransactionHeader."Has NCF Contingency_DXR") and TransactionHeader."Has Contingencies_DXR" then begin
                    TransactionHeader."Has NCF Contingency_DXR" := true;
                    Changed := true;
                end;
                if Changed then
                    TransactionHeader.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= BatchSize() then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until TransactionHeader.Next() = 0;
        Commit();
    end;

    local procedure MigrateAdministrationSetup()
    var
        LegacySetup: Record "EF Administration Setup";
        TargetSetup: Record "DXR_Administration Setup";
        Changed: Boolean;
    begin
        if not LegacySetup.FindSet() then
            exit;
        repeat
            if not TargetSetup.Get(LegacySetup."Primary Key") then begin
                TargetSetup.Init();
                TargetSetup."Primary Key" := LegacySetup."Primary Key";
                TargetSetup.Insert(false);
            end;

            Changed := false;
            CopyTrueIfFalse(TargetSetup."Use Elec. Svc POS_DXR", LegacySetup."LSEF Use Elec. Service On POS", Changed);
            CopyTrueIfFalse(TargetSetup."Send Req From POS_DXR", LegacySetup."LSEF Send Request From POS", Changed);
            CopyIntegerIfZero(TargetSetup."Barcode Width_DXR", LegacySetup."LSEF Barcode Width", Changed);
            CopyIntegerIfZero(TargetSetup."Barcode Height_DXR", LegacySetup."LSEF Barcode Height", Changed);
            CopyTrueIfFalse(TargetSetup."Print QR Code_DXR", LegacySetup."LSEF Print QR Code", Changed);
            CopyIntegerIfZero(TargetSetup."Def. NC Mod. Type_DXR", LegacySetup."LSEF Def. NC Modification Type", Changed);
            CopyTrueIfFalse(TargetSetup."Block None ETrans Post_DXR", LegacySetup."Block None E-Trans. Posting", Changed);
            CopyTrueIfFalse(TargetSetup."Print Blank Lines_DXR", LegacySetup."Print Blank Lines", Changed);
            CopyIntegerIfZero(TargetSetup."Def Pt NC ModType_DXR", LegacySetup."LSEF Def. Part. NC Mod. Type", Changed);
            CopyTrueIfFalse(TargetSetup."Allow Zero Amt Ln_DXR", LegacySetup."LSEF Allow Zero Amount Lines", Changed);
            if TargetSetup."Validate Aff. Doc_DXR" and not LegacySetup."LSEF Validate Affected Doc" then begin
                TargetSetup."Validate Aff. Doc_DXR" := false;
                Changed := true;
            end;
            CopyTrueIfFalse(TargetSetup."Vat Indicator Header_DXR", LegacySetup."Vat Indicator Header", Changed);
            if Changed then
                TargetSetup.Modify(false);
        until LegacySetup.Next() = 0;
    end;

    local procedure MigrateTenderTypeRelations()
    var
        LegacyRelation: Record "LSDXTender Types Relation";
        TargetRelation: Record "DXR_LS Tender Types Relation";
        Changed: Boolean;
    begin
        if not LegacyRelation.FindSet() then
            exit;
        repeat
            if not TargetRelation.Get(LegacyRelation.Code, LegacyRelation."Tender Type Code") then begin
                TargetRelation.Init();
                TargetRelation.Code_DXR := LegacyRelation.Code;
                TargetRelation."Tender Type Code_DXR" := LegacyRelation."Tender Type Code";
                TargetRelation.Description_DXR := LegacyRelation.Description;
                TargetRelation.Insert(false);
            end;

            Changed := false;
            if (TargetRelation."Payment Type_DXR".AsInteger() = 0) and (LegacyRelation."LSEF Payment Type".AsInteger() <> 0) then begin
                TargetRelation."Payment Type_DXR" := Enum::"DXR_Payment Type".FromInteger(LegacyRelation."LSEF Payment Type".AsInteger());
                Changed := true;
            end;
            if (TargetRelation."Payment Type Form_DXR" = '') and (LegacyRelation."LSEF Payment Type Form" <> '') then begin
                TargetRelation."Payment Type Form_DXR" := LegacyRelation."LSEF Payment Type Form";
                Changed := true;
            end;
            if Changed then
                TargetRelation.Modify(false);
        until LegacyRelation.Next() = 0;
    end;

    local procedure MigrateProcessRequests()
    var
        LegacyRequest: Record "EF Process Request";
        TargetRequest: Record "DXR_Process Request";
        Changed: Boolean;
    begin
        if not LegacyRequest.FindSet() then
            exit;
        repeat
            if TargetRequest.Get(LegacyRequest."Document No.", LegacyRequest."EFC Track ID") then begin
                Changed := false;
                if (TargetRequest."Store No._DXR" = '') and (LegacyRequest."LSEF Store No." <> '') then begin
                    TargetRequest."Store No._DXR" := LegacyRequest."LSEF Store No.";
                    Changed := true;
                end;
                if (TargetRequest."POS Terminal No._DXR" = '') and (LegacyRequest."LSEF POS Terminal No." <> '') then begin
                    TargetRequest."POS Terminal No._DXR" := LegacyRequest."LSEF POS Terminal No.";
                    Changed := true;
                end;
                CopyTrueIfFalse(TargetRequest.Sent_DXR, LegacyRequest."LSEF Sent", Changed);
                if (TargetRequest.Replicated_DXR = 0D) and (LegacyRequest."LSEF Replicated" <> 0D) then begin
                    TargetRequest.Replicated_DXR := LegacyRequest."LSEF Replicated";
                    Changed := true;
                end;
                CopyIntegerIfZero(TargetRequest."Replication Cntr_DXR", LegacyRequest."LSEF Replication Counter", Changed);
                if (TargetRequest.Date_DXR = 0D) and (LegacyRequest."LSEF Date" <> 0D) then begin
                    TargetRequest.Date_DXR := LegacyRequest."LSEF Date";
                    Changed := true;
                end;
                if Changed then
                    TargetRequest.Modify(false);
            end;
        until LegacyRequest.Next() = 0;
    end;

    local procedure MigrateResendDocumentQueue()
    var
        LegacyQueue: Record "EF Resend Document Queue";
        TargetQueue: Record "DXR_Resend Document Queue";
        Changed: Boolean;
    begin
        if not LegacyQueue.FindSet() then
            exit;
        repeat
            if TargetQueue.Get(LegacyQueue."Document No.") then begin
                Changed := false;
                if (TargetQueue."Aff. POS Rcpt No._DXR" = '') and (LegacyQueue."LSEF Affected POS Receipt No." <> '') then begin
                    TargetQueue."Aff. POS Rcpt No._DXR" := LegacyQueue."LSEF Affected POS Receipt No.";
                    Changed := true;
                end;
                if (TargetQueue."Affected NCF_DXR" = '') and (LegacyQueue."LSEF Affected NCF" <> '') then begin
                    TargetQueue."Affected NCF_DXR" := LegacyQueue."LSEF Affected NCF";
                    Changed := true;
                end;
                if Changed then
                    TargetQueue.Modify(false);
            end;
        until LegacyQueue.Next() = 0;
    end;

    local procedure MigrateTerminals()
    var
        POSTerminal: Record "LSC POS Terminal";
        Changed: Boolean;
    begin
        if POSTerminal.FindSet(true) then
            repeat
                Changed := false;
                // Carry forward values left on the pre-renumbering fields (tableextension
                // "LSEF LSC POS Terminal", field IDs 55600-55604, ObsoleteState = Pending)
                // before falling through to the newer "_DXR" chain below.
                CopyIfBlank(POSTerminal."Alt NCF SrlNo CRF_DXR", POSTerminal."LSEF Alternal NCF SerialNo CRF", Changed);
                CopyIfBlank(POSTerminal."Alt NCF SrlNo CF_DXR", POSTerminal."LSEF Alternal NCF SerialNo CF", Changed);
                CopyIfBlank(POSTerminal."Alt NCF SrlNo ESP_DXR", POSTerminal."LSEF Alternal NCF SerialNo ESP", Changed);
                CopyIfBlank(POSTerminal."Alt NCF SrlNo GUB_DXR", POSTerminal."LSEF Alternal NCF SerialNo GUB", Changed);
                CopyIfBlank(POSTerminal."Alt NCF SrlNo NC_DXR", POSTerminal."LSEF Alternal NCF SerialNo NC", Changed);

                CopyIfBlank(POSTerminal."Alt. NCF Fiscal Credit_DXR", POSTerminal."Alt NCF SrlNo CRF_DXR", Changed);
                CopyIfBlank(POSTerminal."Alt. NCF Final Consumer_DXR", POSTerminal."Alt NCF SrlNo CF_DXR", Changed);
                CopyIfBlank(POSTerminal."Alt. NCF Credit Note_DXR", POSTerminal."Alt NCF SrlNo NC_DXR", Changed);
                CopyIfBlank(POSTerminal."Alt. NCF Governmental_DXR", POSTerminal."Alt NCF SrlNo GUB_DXR", Changed);
                CopyIfBlank(POSTerminal."Alt. NCF Reg. Special_DXR", POSTerminal."Alt NCF SrlNo ESP_DXR", Changed);
                if Changed then
                    POSTerminal.Modify(false);
            until POSTerminal.Next() = 0;
    end;

    /// <summary>
    /// Retroactive repair for the 8 "LSEF LSC Transaction Header" fields and the 4
    /// "LSEF LSC Trans. Sales Entry" fields that the ported upgrade never carried forward. Own tag,
    /// evaluated unconditionally - see this codeunit's header for why neither existing tag could be
    /// reused. Every copy is "only if the destination is still blank", so this is idempotent and can
    /// never overwrite a value the real upgrade (or a user) already put there.
    /// </summary>
    local procedure RepairLegacyTransactionFieldsIfNeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(LegacyTransactionFieldsRepairTag()) then
            exit;

        RepairTransactionHeaderFields();
        RepairTransSalesEntryFields();

        UpgradeTag.SetUpgradeTag(LegacyTransactionFieldsRepairTag());
    end;

    local procedure LegacyTransactionFieldsRepairTag(): Code[250]
    begin
        exit('DXR-MCC-LSFE-LEGACY-TRANS-FIELDS-REPAIR-20260827');
    end;

    local procedure RepairTransactionHeaderFields()
    var
        TransactionHeader: Record "LSC Transaction Header";
        InStr: InStream;
        OutStr: OutStream;
        Changed: Boolean;
        RowsSinceCommit: Integer;
    begin
        if not TransactionHeader.FindSet(true) then
            exit;
        repeat
            Changed := false;

            // The two fields LSFE's own retail events read to decide "already stamped?".
            if (TransactionHeader."Security Code_DXR" = '') and (TransactionHeader."LSEF Security Code" <> '') then begin
                TransactionHeader."Security Code_DXR" := TransactionHeader."LSEF Security Code";
                Changed := true;
            end;
            if (TransactionHeader."Stamped Date/Time_DXR" = '') and (TransactionHeader."LSEF Stamped Date/Time" <> '') then begin
                TransactionHeader."Stamped Date/Time_DXR" := TransactionHeader."LSEF Stamped Date/Time";
                Changed := true;
            end;

            if (TransactionHeader."RequestedDateTime_DXR" = 0DT) and (TransactionHeader."LSEF Requested DateTime" <> 0DT) then begin
                TransactionHeader."RequestedDateTime_DXR" := TransactionHeader."LSEF Requested DateTime";
                Changed := true;
            end;
            if (TransactionHeader."NCF Mod. Reason_DXR" = 0) and (TransactionHeader."LSEF NCF Modification Reason" <> 0) then begin
                TransactionHeader."NCF Mod. Reason_DXR" := TransactionHeader."LSEF NCF Modification Reason";
                Changed := true;
            end;
            if (not TransactionHeader."Applies for ISC_DXR") and TransactionHeader."LSEF Applies for ISC" then begin
                TransactionHeader."Applies for ISC_DXR" := true;
                Changed := true;
            end;

            // Source and destination are different enum types, so the value crosses by ordinal -
            // same technique MigrateTenderTypeRelations() already uses in this codeunit.
            if (TransactionHeader."e-NCF Type_DXR".AsInteger() = 0) and
               (TransactionHeader."LSEF e-NCF Type".AsInteger() <> 0)
            then begin
                TransactionHeader."e-NCF Type_DXR" :=
                    Enum::"DXR_ecfType Basic".FromInteger(TransactionHeader."LSEF e-NCF Type".AsInteger());
                Changed := true;
            end;

            // 55610/55612/55613 are the FIRST hop of a two-hop chain (55xxx -> 5256x -> final
            // _DXR). MigrateTransactions() above only ever performed the second hop, so a value
            // still sitting on the 55xxx field never arrived. Copied straight to the final
            // destination here: the intermediate is itself ObsoleteState = Pending, so writing it
            // would only move the problem one field along.
            // NOT migrated here: 55610 LSEfQRImageOld (Media) -> QRImage_DXR. The QR image is
            // regenerable presentation data, and the equivalent Media copy was deliberately removed
            // from MigrateTransactions() above, so re-introducing it here would contradict that.
            // The two BLOBs further down are kept on purpose - a signature value and the encoded
            // fiscal barcode are not presentation data, they are the fiscal evidence of the stamp.
            if (TransactionHeader."DGII Message_DXR" = '') and (TransactionHeader."LSEF DGII Message" <> '') then begin
                TransactionHeader."DGII Message_DXR" := TransactionHeader."LSEF DGII Message";
                Changed := true;
            end;
            if (TransactionHeader."Status_DXR".AsInteger() = 0) and (TransactionHeader."LSEF Status".AsInteger() <> 0) then begin
                TransactionHeader."Status_DXR" :=
                    Enum::"DXR_Approval Status Type".FromInteger(TransactionHeader."LSEF Status".AsInteger());
                Changed := true;
            end;

            // BLOB fields have no ":=" operator in AL - CalcFields first, then move the bytes with
            // CreateInStream/CreateOutStream/CopyStream (the documented way).
            TransactionHeader.CalcFields("Signature Value_DXR", "LSEF Signature Value", "Encoded Barcode_DXR", "LSEF Encoded Barcode");
            if (TransactionHeader."Signature Value_DXR".Length() = 0) and
               (TransactionHeader."LSEF Signature Value".Length() > 0)
            then begin
                TransactionHeader."LSEF Signature Value".CreateInStream(InStr);
                TransactionHeader."Signature Value_DXR".CreateOutStream(OutStr);
                CopyStream(OutStr, InStr);
                Changed := true;
            end;
            if (TransactionHeader."Encoded Barcode_DXR".Length() = 0) and
               (TransactionHeader."LSEF Encoded Barcode".Length() > 0)
            then begin
                TransactionHeader."LSEF Encoded Barcode".CreateInStream(InStr);
                TransactionHeader."Encoded Barcode_DXR".CreateOutStream(OutStr);
                CopyStream(OutStr, InStr);
                Changed := true;
            end;

            if Changed then
                TransactionHeader.Modify(false);
            RowsSinceCommit += 1;
            if RowsSinceCommit >= BatchSize() then begin
                Commit();
                RowsSinceCommit := 0;
            end;
        until TransactionHeader.Next() = 0;
        Commit();
    end;

    /// <summary>
    /// "LSEF LSC Trans. Sales Entry" (55600-55603) -> "DXR_LEF LSC Trans Sales Entry" (52554-52557).
    /// This table had ZERO migration coverage anywhere - not in LSFE's own upgrade, not in MCC.
    /// </summary>
    local procedure RepairTransSalesEntryFields()
    var
        TransSalesEntry: Record "LSC Trans. Sales Entry";
        Changed: Boolean;
        RowsSinceCommit: Integer;
    begin
        if not TransSalesEntry.FindSet(true) then
            exit;
        repeat
            Changed := false;

            if (not TransSalesEntry."Applies for ISC_DXR") and TransSalesEntry."LSEF Applies for ISC" then begin
                TransSalesEntry."Applies for ISC_DXR" := true;
                Changed := true;
            end;
            if (not TransSalesEntry."Appl. Withholding_DXR") and TransSalesEntry."LSEF Applies for Withholding" then begin
                TransSalesEntry."Appl. Withholding_DXR" := true;
                Changed := true;
            end;
            if (TransSalesEntry."UOM Type_DXR" = '') and (TransSalesEntry."LSEF UOM Type" <> '') then begin
                TransSalesEntry."UOM Type_DXR" := TransSalesEntry."LSEF UOM Type";
                Changed := true;
            end;
            if (TransSalesEntry."Tax Indicator_DXR".AsInteger() = 0) and
               (TransSalesEntry."LSEF Tax Indicator".AsInteger() <> 0)
            then begin
                TransSalesEntry."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(TransSalesEntry."LSEF Tax Indicator".AsInteger());
                Changed := true;
            end;

            if Changed then
                TransSalesEntry.Modify(false);
            RowsSinceCommit += 1;
            if RowsSinceCommit >= BatchSize() then begin
                Commit();
                RowsSinceCommit := 0;
            end;
        until TransSalesEntry.Next() = 0;
        Commit();
    end;

    local procedure CopyIfBlank(var Target: Code[20]; Source: Code[20]; var Changed: Boolean)
    begin
        if (Target = '') and (Source <> '') then begin
            Target := Source;
            Changed := true;
        end;
    end;

    local procedure CopyTrueIfFalse(var Target: Boolean; Source: Boolean; var Changed: Boolean)
    begin
        if (not Target) and Source then begin
            Target := true;
            Changed := true;
        end;
    end;

    local procedure CopyIntegerIfZero(var Target: Integer; Source: Integer; var Changed: Boolean)
    begin
        if (Target = 0) and (Source <> 0) then begin
            Target := Source;
            Changed := true;
        end;
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
