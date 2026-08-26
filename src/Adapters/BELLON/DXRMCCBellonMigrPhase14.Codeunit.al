// codeunit 60158 "DXR MCC Bellon Migr Phase14"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 14 XCollFix" (56131), fully self-contained. UNTRACKED BY MCC'S REGISTRY - same
//     // situation as Phase 13 (see that codeunit's header comment for the full reasoning): no
//     // BELLON-Pn concept row references this phase, and none of the 11 old MCC delegation adapters
//     // ever called it. A genuine, real gap in this MCC extension's coverage, predating this pivot.
//     //
//     // Real content: a full field-by-field TRANSFERFIELDS type audit (triggered by a real
//     // production crash on Customer Card -> CustCont-Update) found 52 fields on native BC tables
//     // (Contact, Transfer Header, Sales Header, Purchase Line - Bellon numbers custom fields on
//     // native tables independently per table, without coordinating against sibling tables BC syncs
//     // via RecordRef.TRANSFERFIELDS) reusing the same physical field ID across tables with
//     // different types. All 52 were relocated to a fresh 58000-58121 band; of those, 18 were
//     // confirmed still live on deploy with real stored data - this phase bridges those 18 before
//     // the originals are marked ObsoleteState = Removed. The remaining 34 (confirmed absent from
//     // deploy) were marked Removed directly with no bridge needed.
//     Permissions =
//         tabledata Contact = RM,
//         tabledata "Transfer Header" = RM,
//         tabledata "Sales Header" = RM,
//         tabledata "Purchase Line" = RM;

//     trigger OnRun()
//     begin
//         RunMaster();
//         RunAccounting();
//     end;

//     procedure RunMaster()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-BellonP14XCollFixMasterCompleted') then
//             exit;

//         MigrateContactCollisionBridge();

//         UpgradeTag.SetUpgradeTag('DXR-BellonP14XCollFixMasterCompleted');
//     end;

//     procedure RunAccounting()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-BellonP14XCollFixAccountingCompleted') then
//             exit;

//         MigrateTransferHeaderCollisionBridge();
//         MigrateSalesHeaderCollisionBridge();
//         MigratePurchaseLineCollisionBridge();

//         UpgradeTag.SetUpgradeTag('DXR-BellonP14XCollFixAccountingCompleted');
//     end;

//     local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
//     var
//         CandidateField: FieldRef;
//         SourceField: FieldRef;
//         TargetField: FieldRef;
//         FieldIndex: Integer;
//         SourceFound: Boolean;
//         TargetFound: Boolean;
//     begin
//         // Resolve the published identities once through metadata, then copy by the resolved field
//         // names. This avoids direct Field(ID) dereferencing and validates the physical types.
//         for FieldIndex := 1 to RecRef.FieldCount() do begin
//             CandidateField := RecRef.FieldIndex(FieldIndex);
//             if CandidateField.Number() = OldFieldNo then begin
//                 SourceField := CandidateField;
//                 SourceFound := true;
//             end;
//             if CandidateField.Number() = NewFieldNo then begin
//                 TargetField := CandidateField;
//                 TargetFound := true;
//             end;
//         end;
//         if not SourceFound or not TargetFound then
//             exit;
//         if (SourceField.Class() <> FieldClass::Normal) or
//            (TargetField.Class() <> FieldClass::Normal) or
//            (SourceField.Type() <> TargetField.Type())
//         then
//             exit;

//         SourceField := RecRef.Field(SourceField.Name());
//         TargetField := RecRef.Field(TargetField.Name());
//         TargetField.Value := SourceField.Value();
//     end;

//     // Bridges the 13 physical Contact fields confirmed live on deploy (50060-50078 range) to
//     // their fresh 58000+ ID before "Next Order Selection" (50064, the exact field from the
//     // reported crash) and its 12 siblings are marked ObsoleteState = Removed. FlowFields/
//     // FlowFilters in the same collision set are excluded - no physical column to bridge.
//     local procedure MigrateContactCollisionBridge()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::Contact);
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50064, 58004); // Next Order Selection -> _DXR. (the reported crash field)
//                 CopyFieldIfExists(RecRef, 50065, 58005); // Next Order Restaurant -> _DXR.
//                 CopyFieldIfExists(RecRef, 50066, 58006); // Next Order Date -> _DXR.
//                 CopyFieldIfExists(RecRef, 50067, 58007); // Next Order Time -> _DXR.
//                 CopyFieldIfExists(RecRef, 50068, 58008); // Next Delivery Tender -> _DXR.
//                 CopyFieldIfExists(RecRef, 50069, 58009); // Recall Order -> _DXR.
//                 CopyFieldIfExists(RecRef, 50070, 58010); // Next Order Rest. Temporary -> _DXR.
//                 CopyFieldIfExists(RecRef, 50071, 58011); // Date Created -> _DXR.
//                 CopyFieldIfExists(RecRef, 50074, 58013); // Pre-Order Print DateTime -> _DXR.
//                 CopyFieldIfExists(RecRef, 50075, 58014); // Next Estimated Prod. Time -> _DXR.
//                 CopyFieldIfExists(RecRef, 50076, 58015); // External No. -> _DXR.
//                 CopyFieldIfExists(RecRef, 50077, 58016); // Last Date/Time Modified -> _DXR.
//                 CopyFieldIfExists(RecRef, 50078, 58017); // Customer Template Code -> _DXR.
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     // Bridges the 3 physical Transfer Header fields confirmed live on deploy (50008-50010,
//     // colliding against Transfer Shipment Header/Transfer Receipt Header via
//     // CopyFromTransferHeader) to their fresh 58100+ ID.
//     local procedure MigrateTransferHeaderCollisionBridge()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Transfer Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50008, 58100); // Original Trans. Date -> _DXR.
//                 CopyFieldIfExists(RecRef, 50009, 58101); // Tipo Request -> _DXR.
//                 CopyFieldIfExists(RecRef, 50010, 58102); // Transfer Status -> _DXR.
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     // Bridges the 1 physical Sales Header field confirmed live on deploy (50019
//     // "PriceReleaseControlFlag", colliding against Sales Cr.Memo Header) to its fresh 58110 ID.
//     local procedure MigrateSalesHeaderCollisionBridge()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50019, 58110); // PriceReleaseControlFlag -> _DXR.
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;

//     // Bridges the 1 physical Purchase Line field confirmed live on deploy (50018 "Transito",
//     // colliding against Purch. Inv. Line) to its fresh 58121 ID.
//     local procedure MigratePurchaseLineCollisionBridge()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purchase Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 50018, 58121); // Transito -> _DXR.
//                 RecRef.Modify(false);
//             until RecRef.Next() = 0;
//         RecRef.Close();
//     end;
// }
