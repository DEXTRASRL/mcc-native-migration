// #if not ESCUDEA and not BCDX
// codeunit 60153 "DXR MCC Bellon Migr Phase9"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 9 TransferH" (56126) -> "Bellon Upgrade Process".MigrateTransferHeaderIdRestore283().
//     // Restores the 2 "_BE_DXR" fields of TransferHeader.TableExt.al ("Tipo Request"/"Transfer
//     // Status", 50011/50012 -> 52787/52788) left out of Phase 7. NOTE (per the real source's own
//     // header comment, superseded 2026-08-23): the ID collision this phase originally deferred as
//     // "Release 2" work (52787/52788 also used by Transfer Shipment/Receipt Header's "Order User
//     // ID_DXR."/"Order Date Created_DXR.", linked via BC's native CopyFromTransferHeader) was
//     // subsequently resolved by "Bellon Migr. Phase 14 XCollFix" relocating Transfer Header's side
//     // to 58100-58102. This phase's own bridge (50011/50012 -> 52787/52788) still runs first and is
//     // still required - Phase 14 bridges FROM 52787/52788 (this phase's target) TO 58100+.
//     Permissions =
//         tabledata "Transfer Header" = RM;
// 
//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-TransferHeaderIdRestore283') then
//             exit;
// 
//         MigrateTableExt_TransferHeaderIdRestore();
// 
//         UpgradeTag.SetUpgradeTag('DXR-TransferHeaderIdRestore283');
//     end;
// 
//     local procedure CopyFieldIfExists(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldName: Text)
//     var
//         MasterFieldResolver: Codeunit "DXR MCC Master Field Resolver";
//     begin
//         // Field numbers remain in the published schema to keep BC's RecordRef mechanisms (Field(),
//         // FieldExist()) compatible, but migration lookup itself is entirely name based - same
//         // resolver as Phase3/Phase7 (DXR MCC Master Field Resolver), skip-if-target-already-
//         // populated. Names recovered from this table's own tableextension source
//         // (src/Extentions/tables/TransferHeader.TableExt.al in the Bellon Customization app).
//         if MasterFieldResolver.CopyFirstPopulatedField(RecRef, TargetFieldName, SourceFieldName) then
//             RecordChanged := true;
//     end;
// 
//     local procedure PersistChangedRecord(var RecRef: RecordRef)
//     begin
//         if RecordChanged then
//             RecRef.Modify(false);
//         Clear(RecordChanged);
// 
//         RowsSinceCommit += 1;
//         if RowsSinceCommit >= BatchSize() then begin
//             Commit();
//             RowsSinceCommit := 0;
//         end;
//     end;
// 
//     local procedure FinishTable(var RecRef: RecordRef)
//     begin
//         RecRef.Close();
//         Commit();
//         RowsSinceCommit := 0;
//         Clear(RecordChanged);
//     end;
// 
//     local procedure BatchSize(): Integer
//     begin
//         exit(500);
//     end;
// 
//     local procedure MigrateTableExt_TransferHeaderIdRestore()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Transfer Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 'Tipo Request_DXR', 'Tipo Request_Old');
//                 CopyFieldIfExists(RecRef, 'Transfer Status_DXR', 'Transfer Status_Old');
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;
// 
//     var
//         RecordChanged: Boolean;
//         RowsSinceCommit: Integer;
// }
// 
// #endif
// 
