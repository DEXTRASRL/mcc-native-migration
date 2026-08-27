codeunit 60137 "DXR MCC FE Migr Phase8"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 8 Master".OnRun() (Access = Internal). Field-to-field copies on 5 master
    // tables (Currency, Item [batched], Post Code, Unit of Measure, VAT Posting Setup) - all
    // public/standard BC tables. The sibling's own StatusMgt/checkpoint-resume bookkeeping is not
    // ported (MCC's own registry tracks progress); Item is still processed in Commit-batches of
    // 100 to avoid one giant uncommitted transaction, matching the source's own batch size.
    //
    // Converted 2026-08-24 (Task A.4-FE, resumed): the 4 in-scope registry concepts (seq2 Currency,
    // seq308 Post Code, seq309 Unit of Measure, seq310 VAT Posting Setup) were routed through a
    // generic RecordRef/FieldRef "CopySameTableFields" helper. Every field pair was already fully
    // known (see the FieldMap literals the old code built) - only the copy mechanism was untyped.
    // Converted to direct typed field assignment, zero RecordRef/FieldRef. Field pairs confirmed
    // against real tableextension source in
    // "C:\Users\rpena\OneDrive - Dextra\Desktop\BELLON\Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\TableExts\":
    //   - Currency: "EF Currency Type" (55501, Code[3]) -> "Currency Type_DXR" (52333, Code[3])
    //     (EFCurrency.TableExt.al:10,36). No shadow "_Old" field exists for this table - confirmed
    //     "Currency Type_DXR" is the sole non-obsolete replacement field.
    //   - Post Code: "EF Township Code" (55501, Code[6]) -> "Township Code_DXR" (52333, Code[6]);
    //     "EF County Code" (55502, Code[6]) -> "County Code_DXR" (52334, Code[6])
    //     (EFPostCode.TableExt.al:10,35,75,103). "EF County Description"/"EF Township Description"
    //     (55503/55504 -> 52335/52336) are FlowFields on both sides (CalcFormula lookups into
    //     "EF Township"/"DXR_Township") - correctly excluded from the copy, same as the prior code.
    //   - Unit of Measure: "EF UOM Type" (55505, Code[2]) -> "UOM Type_DXR" (52333, Code[2])
    //     (EFUnitOfMeasure.TableExt.al:11,23).
    //   - VAT Posting Setup: "EF Tax Indicator" (55503, Enum "EF Invoice Tax Indicator Type") ->
    //     "Tax Indicator_DXR" (52333, Enum "DXR_Inv. Tax Indicator Type")
    //     (EFVATPostingSetup.TableExt.al:11,23). The two enums are structurally identical (same
    //     ordinals/value names 0-4: No Facturable/ITBIS 1/ITBIS 2/ITBIS 3/Exento(E) - confirmed by
    //     reading both enum sources), so the AsInteger()/FromInteger() round-trip below is safe,
    //     same technique already used by "DXR_EF MCC Migr Bridge" for Phase7's Payment Type enum.
    //
    // Item's field copies ("EF Applies for ISC"/"EF Tax Type", both confirmed against
    // EFItem.TableExt.al in FE's own repo) are converted to direct typed field assignment below,
    // same as the 4 in-scope master tables - zero RecordRef/FieldRef remaining in this codeunit.
    Permissions =
        tabledata Currency = RM,
        tabledata Item = RM,
        tabledata "Post Code" = RM,
        tabledata "Unit of Measure" = RM,
        tabledata "VAT Posting Setup" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625') then
            exit;

        MigrateMasterTableExtensionFields();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE2-MASTER-FIELDS-20260625');
    end;

    procedure RunSetup()
    begin
        CopyCurrencyFields();
        CopyPostCodeFields();
        CopyUnitOfMeasureFields();
        CopyVATPostingSetupFields();
    end;

    procedure RunMaster()
    begin
        CopyItemFieldsInBatches();
    end;

    local procedure MigrateMasterTableExtensionFields()
    begin
        CopyCurrencyFields();
        CopyPostCodeFields();
        CopyUnitOfMeasureFields();
        CopyVATPostingSetupFields();
        CopyItemFieldsInBatches();
    end;

    local procedure CopyCurrencyFields()
    var
        Currency: Record Currency;
        Blank: Record Currency;
    begin
        // Fixed 2026-08-27 (A1): added SetLoadFields (exactly the 2 fields this loop reads/writes; PK
        // fields are always loaded) so the scan stops joining the companion table of every Currency
        // tableextension in this portfolio once per row.
        Currency.SetLoadFields("Currency Type_DXR", "EF Currency Type");
        if Currency.FindSet(true) then
            repeat
                // Fixed 2026-08-27 (never-overwrite): unconditional copy - a re-run of this migration
                // (e.g. per-table upgrade tags with a company already migrated) would blindly
                // overwrite an already-populated _DXR value.
                if Currency."Currency Type_DXR" = Blank."Currency Type_DXR" then
                    Currency."Currency Type_DXR" := Currency."EF Currency Type";
                Currency.Modify(false);
            until Currency.Next() = 0;
    end;

    local procedure CopyPostCodeFields()
    var
        PostCode: Record "Post Code";
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A1/A4): added SetLoadFields (exactly the 4 fields read/written) and a
        // bounded Commit - "Post Code" is a full country postal catalogue (tens of thousands of rows
        // in a DR install), so this used to run as one single unbounded transaction.
        PostCode.SetLoadFields("Township Code_DXR", "EF Township Code", "County Code_DXR", "EF County Code");
        if PostCode.FindSet(true) then
            repeat
                PostCode."Township Code_DXR" := PostCode."EF Township Code";
                PostCode."County Code_DXR" := PostCode."EF County Code";
                PostCode.Modify(false);

                BatchCount += 1;
                if BatchCount >= 500 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until PostCode.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    local procedure CopyUnitOfMeasureFields()
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // Fixed 2026-08-27 (A1): added SetLoadFields (exactly the 2 fields read/written).
        UnitOfMeasure.SetLoadFields("UOM Type_DXR", "EF UOM Type");
        if UnitOfMeasure.FindSet(true) then
            repeat
                UnitOfMeasure."UOM Type_DXR" := UnitOfMeasure."EF UOM Type";
                UnitOfMeasure.Modify(false);
            until UnitOfMeasure.Next() = 0;
    end;

    local procedure CopyVATPostingSetupFields()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Fixed 2026-08-27 (A1): added SetLoadFields (exactly the 2 fields read/written).
        VATPostingSetup.SetLoadFields("Tax Indicator_DXR", "EF Tax Indicator");
        if VATPostingSetup.FindSet(true) then
            repeat
                VATPostingSetup."Tax Indicator_DXR" :=
                    Enum::"DXR_Inv. Tax Indicator Type".FromInteger(VATPostingSetup."EF Tax Indicator".AsInteger());
                VATPostingSetup.Modify(false);
            until VATPostingSetup.Next() = 0;
    end;

    // "EF Applies for ISC" (55501, Boolean) -> "Applies for ISC_DXR" (52333, Boolean);
    // "EF Tax Type" (55502, Code[3]) -> "Tax Type_DXR" (52334, Code[3])
    // (EFItem.TableExt.al:10,19,31,44). Batched in Commit-groups of ProductBatchSize() (100),
    // matching the source's own Item batch size (see class header comment).
    local procedure CopyItemFieldsInBatches()
    var
        Item: Record Item;
        ItemToUpdate: Record Item;
        Blank: Record Item;
        BatchCount: Integer;
    begin
        // Fixed 2026-08-27 (A1): this scanned the WHOLE Item table with FindSet(true), i.e. an UPDLOCK
        // on every item held for the entire run, while only the minority of rows whose values differ
        // actually change; and with no SetLoadFields every Item tableextension companion table in this
        // portfolio was joined in per row. Now: SetLoadFields (PK + the 4 fields touched) +
        // FindSet(false) (no UPDLOCK), and the row is re-read with Get() and locked only when it really
        // needs the copy. The commit counter advances per MODIFIED row instead of per scanned row.
        // Same fields, same guard condition, same result.
        Item.SetLoadFields("No.", "Applies for ISC_DXR", "EF Applies for ISC", "Tax Type_DXR", "EF Tax Type");
        if Item.FindSet(false) then
            repeat
                if (Item."Applies for ISC_DXR" <> Item."EF Applies for ISC") or
                   (Item."Tax Type_DXR" <> Item."EF Tax Type")
                then
                    if ItemToUpdate.Get(Item."No.") then begin
                        // Fixed 2026-08-27 (never-overwrite): unconditional copy - a re-run of this
                        // migration (e.g. per-table upgrade tags with a company already migrated)
                        // would blindly overwrite an already-populated _DXR value.
                        if ItemToUpdate."Applies for ISC_DXR" = Blank."Applies for ISC_DXR" then
                            ItemToUpdate."Applies for ISC_DXR" := ItemToUpdate."EF Applies for ISC";
                        if ItemToUpdate."Tax Type_DXR" = Blank."Tax Type_DXR" then
                            ItemToUpdate."Tax Type_DXR" := ItemToUpdate."EF Tax Type";
                        ItemToUpdate.Modify(false);

                        BatchCount += 1;
                        if BatchCount >= ProductBatchSize() then begin
                            Commit();
                            BatchCount := 0;
                        end;
                    end;
            until Item.Next() = 0;
        if BatchCount > 0 then
            Commit();
    end;

    local procedure ProductBatchSize(): Integer
    begin
        exit(100);
    end;
}
