#if not ESCUDEA and not BCDX
codeunit 60122 "DXR MCC PCM Migr Phase2"
{
    // Native local migration - ported verbatim from Price Controls Mgt.'s own
    // "DXR_Migr. Phase 2 Master Data".Run(). Per-phase granularity, matching the extension's own
    // pre-existing adapter-per-phase structure (2 field-restore concepts bundled here, same as the
    // deleted delegation adapter). Step-level Upgrade Tags reuse the sibling's own exact tag
    // strings (hardcoded literally here - "DXR_Upgrade Tags" is Access=Internal on PCM's side, so
    // the tag values are copied rather than called) to avoid redundant work if PCM's own background
    // scheduler is still independently active. Retry-on-transient-lock semantics reuse PCM's own
    // public "DXR_Migr. Retry Mgt." codeunit directly.
    Permissions =
        tabledata Customer = RM,
        tabledata "LSC Store Price Group" = RM;

    trigger OnRun()
    begin
        RunSetup();
        RunMaster();
    end;

    procedure RunSetup()
    begin
        MigrateStorePriceGroupFields();
    end;

    procedure RunMaster()
    begin
        MigrateCustomerFields();
    end;

    local procedure MigrateCustomerFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        Customer: Record Customer;
        CustomerToUpdate: Record Customer;
        AttemptNo: Integer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(CustomerFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) took an UPDLOCK on every customer with a "PRC Store" for the
        // whole run, including the ones whose _DXR value is already filled (nothing to do). Same fix
        // as "DXR MCC BC Migr P3 Customer": SetLoadFields limits the read to the 3 fields touched
        // (Customer carries many tableextensions in this portfolio - without it every companion table
        // was joined per row), FindSet(false) reads without the lock, and the row is re-read with
        // Get() and locked only when it really needs the copy. Commit counter per MODIFIED row.
        Customer.SetLoadFields("No.", "PRC Store", "PRC Store_DXR");
        Customer.SetFilter("PRC Store", '<>%1', '');
        if Customer.FindSet(false) then begin
            repeat
                if Customer."PRC Store_DXR" = '' then
                    if CustomerToUpdate.Get(Customer."No.") then
                        if CustomerToUpdate."PRC Store_DXR" = '' then begin
                            CustomerToUpdate."PRC Store_DXR" := CustomerToUpdate."PRC Store";
                            AttemptNo := 0;
                            while not TryModifyCustomer(CustomerToUpdate) do begin
                                AttemptNo += 1;
                                if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                                    Error(GetLastErrorText());
                            end;

                            // Batching commit only runs after the retry-on-lock loop above has fully
                            // resolved (TryModifyCustomer succeeded, or ShouldRetry gave up and Error()
                            // already aborted the whole procedure) - never mid-retry, so it cannot
                            // mask/roll back a pending retry.
                            RowCounter += 1;
                            if RowCounter >= BatchSize() then begin
                                Commit();
                                RowCounter := 0;
                            end;
                        end;
            until Customer.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(CustomerFieldsMigratedTag());
    end;

    [TryFunction]
    local procedure TryModifyCustomer(var Customer: Record Customer)
    begin
        Customer.Modify(false);
    end;

    local procedure MigrateStorePriceGroupFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        StorePriceGroup: Record "LSC Store Price Group";
        StorePriceGroupToUpdate: Record "LSC Store Price Group";
        Modified: Boolean;
        AttemptNo: Integer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(StorePriceGroupFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: FindSet(true) over the WHOLE LSC Store Price Group table took an UPDLOCK
        // on every row for the entire run even though only the rows with a legacy flag set change.
        // Now: SetLoadFields (PK + exactly the 6 fields read/written), FindSet(false) without the
        // lock, and the row is re-read with Get() and locked only when it really needs a change; the
        // commit counter advances per MODIFIED row. Same fields, same fill-only-if-blank guards.
        StorePriceGroup.SetLoadFields(
            Store, "Price Group Code",
            "PRC Precio Fijado", "PRC Precio Fijado_DXR",
            "PRC Excluir Store Prices", "PRC ExclStorePrc_DXR",
            "PRC Excluir Cust. Prices", "PRC ExclCustPrc_DXR");
        if StorePriceGroup.FindSet(false) then begin
            repeat
                Modified :=
                    (StorePriceGroup."PRC Precio Fijado" and not StorePriceGroup."PRC Precio Fijado_DXR") or
                    (StorePriceGroup."PRC Excluir Store Prices" and not StorePriceGroup."PRC ExclStorePrc_DXR") or
                    (StorePriceGroup."PRC Excluir Cust. Prices" and not StorePriceGroup."PRC ExclCustPrc_DXR");

                if Modified then
                    if StorePriceGroupToUpdate.Get(StorePriceGroup.Store, StorePriceGroup."Price Group Code") then begin
                        if StorePriceGroupToUpdate."PRC Precio Fijado" and not StorePriceGroupToUpdate."PRC Precio Fijado_DXR" then
                            StorePriceGroupToUpdate."PRC Precio Fijado_DXR" := true;

                        if StorePriceGroupToUpdate."PRC Excluir Store Prices" and not StorePriceGroupToUpdate."PRC ExclStorePrc_DXR" then
                            StorePriceGroupToUpdate."PRC ExclStorePrc_DXR" := true;

                        if StorePriceGroupToUpdate."PRC Excluir Cust. Prices" and not StorePriceGroupToUpdate."PRC ExclCustPrc_DXR" then
                            StorePriceGroupToUpdate."PRC ExclCustPrc_DXR" := true;

                        AttemptNo := 0;
                        while not TryModifyStorePriceGroup(StorePriceGroupToUpdate) do begin
                            AttemptNo += 1;
                            if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                                Error(GetLastErrorText());
                        end;

                        // Same rationale as MigrateCustomerFields: only reached once the retry-on-lock
                        // loop above has fully resolved, never mid-retry.
                        RowCounter += 1;
                        if RowCounter >= BatchSize() then begin
                            Commit();
                            RowCounter := 0;
                        end;
                    end;
            until StorePriceGroup.Next() = 0;
            if RowCounter > 0 then
                Commit();
        end;

        UpgradeTag.SetUpgradeTag(StorePriceGroupFieldsMigratedTag());
    end;

    [TryFunction]
    local procedure TryModifyStorePriceGroup(var StorePriceGroup: Record "LSC Store Price Group")
    begin
        StorePriceGroup.Modify(false);
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    local procedure CustomerFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-CustomerFieldsMigrated-28.3.0.0');
    end;

    local procedure StorePriceGroupFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-StorePriceGroupFieldsMigrated-28.3.0.0');
    end;
}

#endif
