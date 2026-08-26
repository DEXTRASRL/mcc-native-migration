// #if not ESCUDEA and not BCDX
// codeunit 60122 "DXR MCC PCM Migr Phase2"
// {
//     // Native local migration - ported verbatim from Price Controls Mgt.'s own
//     // "DXR_Migr. Phase 2 Master Data".Run(). Per-phase granularity, matching the extension's own
//     // pre-existing adapter-per-phase structure (2 field-restore concepts bundled here, same as the
//     // deleted delegation adapter). Step-level Upgrade Tags reuse the sibling's own exact tag
//     // strings (hardcoded literally here - "DXR_Upgrade Tags" is Access=Internal on PCM's side, so
//     // the tag values are copied rather than called) to avoid redundant work if PCM's own background
//     // scheduler is still independently active. Retry-on-transient-lock semantics reuse PCM's own
//     // public "DXR_Migr. Retry Mgt." codeunit directly.
//     Permissions =
//         tabledata Customer = RM,
//         tabledata "LSC Store Price Group" = RM;

//     trigger OnRun()
//     begin
//         RunSetup();
//         RunMaster();
//     end;

//     procedure RunSetup()
//     begin
//         MigrateStorePriceGroupFields();
//     end;

//     procedure RunMaster()
//     begin
//         MigrateCustomerFields();
//     end;

//     local procedure MigrateCustomerFields()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//         RetryMgt: Codeunit 54617;
//         Customer: Record Customer;
//         AttemptNo: Integer;
//     begin
//         if UpgradeTag.HasUpgradeTag(CustomerFieldsMigratedTag()) then
//             exit;

//         Customer.SetFilter("PRC Store", '<>%1', '');
//         if Customer.FindSet(true) then
//             repeat
//                 if Customer."PRC Store_DXR" = '' then begin
//                     Customer."PRC Store_DXR" := Customer."PRC Store";
//                     AttemptNo := 0;
//                     while not TryModifyCustomer(Customer) do begin
//                         AttemptNo += 1;
//                         if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
//                             Error(GetLastErrorText());
//                     end;
//                 end;
//             until Customer.Next() = 0;

//         UpgradeTag.SetUpgradeTag(CustomerFieldsMigratedTag());
//     end;

//     [TryFunction]
//     local procedure TryModifyCustomer(var Customer: Record Customer)
//     begin
//         Customer.Modify(false);
//     end;

//     local procedure MigrateStorePriceGroupFields()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//         RetryMgt: Codeunit 54617;
//         StorePriceGroup: Record "LSC Store Price Group";
//         Modified: Boolean;
//         AttemptNo: Integer;
//     begin
//         if UpgradeTag.HasUpgradeTag(StorePriceGroupFieldsMigratedTag()) then
//             exit;

//         if StorePriceGroup.FindSet(true) then
//             repeat
//                 Modified := false;

//                 if StorePriceGroup."PRC Precio Fijado" and not StorePriceGroup."PRC Precio Fijado_DXR" then begin
//                     StorePriceGroup."PRC Precio Fijado_DXR" := true;
//                     Modified := true;
//                 end;

//                 if StorePriceGroup."PRC Excluir Store Prices" and not StorePriceGroup."PRC ExclStorePrc_DXR" then begin
//                     StorePriceGroup."PRC ExclStorePrc_DXR" := true;
//                     Modified := true;
//                 end;

//                 if StorePriceGroup."PRC Excluir Cust. Prices" and not StorePriceGroup."PRC ExclCustPrc_DXR" then begin
//                     StorePriceGroup."PRC ExclCustPrc_DXR" := true;
//                     Modified := true;
//                 end;

//                 if Modified then begin
//                     AttemptNo := 0;
//                     while not TryModifyStorePriceGroup(StorePriceGroup) do begin
//                         AttemptNo += 1;
//                         if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
//                             Error(GetLastErrorText());
//                     end;
//                 end;
//             until StorePriceGroup.Next() = 0;

//         UpgradeTag.SetUpgradeTag(StorePriceGroupFieldsMigratedTag());
//     end;

//     [TryFunction]
//     local procedure TryModifyStorePriceGroup(var StorePriceGroup: Record "LSC Store Price Group")
//     begin
//         StorePriceGroup.Modify(false);
//     end;

//     local procedure CustomerFieldsMigratedTag(): Code[250]
//     begin
//         exit('DXR-CustomerFieldsMigrated-28.3.0.0');
//     end;

//     local procedure StorePriceGroupFieldsMigratedTag(): Code[250]
//     begin
//         exit('DXR-StorePriceGroupFieldsMigrated-28.3.0.0');
//     end;
// }

// #endif
