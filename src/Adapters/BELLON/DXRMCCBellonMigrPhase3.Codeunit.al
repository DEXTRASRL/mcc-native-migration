// #if not ESCUDEA and not BCDX
// codeunit 60147 "DXR MCC Bellon Migr Phase3"
// {
//     // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
//     // Phase 3 Dedup" (56120). The real source calls two procedures on "Bellon Upgrade Process"
//     // (59221) in this order:
//     //   1) MigrateAllSalesPurchOldGenBridge() - CONFIRMED NO-OP in the current source (both ends
//     //      of this bridge were later marked ObsoleteState = Removed once git history confirmed
//     //      migration/v28.3 never merged to deploy/production, so neither side ever held live
//     //      tenant data; the 14 per-table bridge procedures are kept in source, unused, as
//     //      documentation only). Not ported here - nothing to run.
//     //   2) MigrateAllSalesPurchFieldIdDedup() - ACTIVE. Reassigns 100 tableextension fields across
//     //      the 14 Sales/Purchase Header family tables that Phase 2's own naming-normalization step
//     //      left colliding on the same field ID (52787+) across sibling tables linked by BC's
//     //      native RecordRef.TRANSFERFIELDS (Sales-Post/Purch-Post/ArchiveManagement copy Header ->
//     //      posted/archived document by field NUMBER, not name) - a real "must have the same type"
//     //      crash fix. Each table gets its own exclusive ID range (57200-57469).
//     Permissions =
//         tabledata "Sales Header" = RM,
//         tabledata "Sales Invoice Header" = RM,
//         tabledata "Sales Cr.Memo Header" = RM,
//         tabledata "Sales Shipment Header" = RM,
//         tabledata "Sales Line" = RM,
//         tabledata "Sales Invoice Line" = RM,
//         tabledata "Sales Header Archive" = RM,
//         tabledata "Sales Line Archive" = RM,
//         tabledata "Purchase Header" = RM,
//         tabledata "Purch. Inv. Header" = RM,
//         tabledata "Purch. Rcpt. Header" = RM,
//         tabledata "Purchase Header Archive" = RM,
//         tabledata "Purchase Line" = RM,
//         tabledata "Purch. Rcpt. Line" = RM;

//     trigger OnRun()
//     var
//         UpgradeTag: Codeunit "Upgrade Tag";
//     begin
//         if UpgradeTag.HasUpgradeTag('DXR-SalesPurchIdDedup283') or
//            UpgradeTag.HasUpgradeTag('DXR-SalesPurchIdDedup283.')
//         then
//             exit;

//         MigrateAllSalesPurchFieldIdDedup();

//         UpgradeTag.SetUpgradeTag('DXR-SalesPurchIdDedup283.');
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
//         if Format(TargetField) = Format(SourceField) then
//             exit;

//         TargetField.Value := SourceField.Value();
//         RecordChanged := true;
//     end;

//     local procedure PersistChangedRecord(var RecRef: RecordRef)
//     begin
//         if RecordChanged then
//             RecRef.Modify(false);
//         Clear(RecordChanged);

//         RowsSinceCommit += 1;
//         if RowsSinceCommit >= BatchSize() then begin
//             Commit();
//             RowsSinceCommit := 0;
//         end;
//     end;

//     local procedure FinishTable(var RecRef: RecordRef)
//     begin
//         RecRef.Close();
//         Commit();
//         RowsSinceCommit := 0;
//         Clear(RecordChanged);
//     end;

//     local procedure BatchSize(): Integer
//     begin
//         exit(500);
//     end;

//     local procedure MigrateAllSalesPurchFieldIdDedup()
//     begin
//         MigrateTableExt_SalesHeaderIdDedup();
//         MigrateTableExt_SalesInvoiceHeaderIdDedup();
//         MigrateTableExt_SalesCrMemoHeaderIdDedup();
//         MigrateTableExt_SalesShipmentHeaderIdDedup();
//         MigrateTableExt_SalesLineIdDedup();
//         MigrateTableExt_SalesInvoiceLineIdDedup();
//         MigrateTableExt_SalesHeaderArchiveIdDedup();
//         MigrateTableExt_SalesLineArchiveIdDedup();
//         MigrateTableExt_PurchaseHeaderIdDedup();
//         MigrateTableExt_PurchInvHeaderIdDedup();
//         MigrateTableExt_PurchRcptHeaderIdDedup();
//         MigrateTableExt_PurchaseHeaderArchiveIdDedup();
//         MigrateTableExt_PurchaseLineIdDedup();
//         MigrateTableExt_PurchRcptLineIdDedup();
//     end;

//     local procedure MigrateTableExt_SalesHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52788, 57200);
//                 CopyFieldIfExists(RecRef, 52789, 57201);
//                 CopyFieldIfExists(RecRef, 52790, 57202);
//                 CopyFieldIfExists(RecRef, 52791, 57203);
//                 CopyFieldIfExists(RecRef, 52792, 57204);
//                 CopyFieldIfExists(RecRef, 52793, 57205);
//                 CopyFieldIfExists(RecRef, 52794, 57206);
//                 // 57207 (Tipo Segmento_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52796, 57208);
//                 CopyFieldIfExists(RecRef, 52797, 57209);
//                 CopyFieldIfExists(RecRef, 52798, 57210);
//                 CopyFieldIfExists(RecRef, 52799, 57211);
//                 CopyFieldIfExists(RecRef, 52800, 57212);
//                 CopyFieldIfExists(RecRef, 52801, 57213);
//                 // 57214 (Gestor_ID_DXR.) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52803, 57215);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesInvoiceHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Invoice Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 // 57230 (PaID_DXR.) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52788, 57231);
//                 CopyFieldIfExists(RecRef, 52789, 57232);
//                 CopyFieldIfExists(RecRef, 52790, 57233);
//                 CopyFieldIfExists(RecRef, 52791, 57234);
//                 CopyFieldIfExists(RecRef, 52792, 57235);
//                 CopyFieldIfExists(RecRef, 52793, 57236);
//                 CopyFieldIfExists(RecRef, 52794, 57237);
//                 // 57238 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52796, 57239);
//                 CopyFieldIfExists(RecRef, 52797, 57240);
//                 CopyFieldIfExists(RecRef, 52798, 57241);
//                 CopyFieldIfExists(RecRef, 52799, 57242);
//                 CopyFieldIfExists(RecRef, 52800, 57243);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesCrMemoHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Cr.Memo Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57260);
//                 CopyFieldIfExists(RecRef, 52788, 57261);
//                 CopyFieldIfExists(RecRef, 52789, 57262);
//                 CopyFieldIfExists(RecRef, 52790, 57263);
//                 // 57264 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesShipmentHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Shipment Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57280);
//                 CopyFieldIfExists(RecRef, 52788, 57281);
//                 CopyFieldIfExists(RecRef, 52789, 57282);
//                 CopyFieldIfExists(RecRef, 52790, 57283);
//                 CopyFieldIfExists(RecRef, 52791, 57284);
//                 // 57285 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesLineIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57300);
//                 CopyFieldIfExists(RecRef, 52788, 57301);
//                 CopyFieldIfExists(RecRef, 52789, 57302);
//                 CopyFieldIfExists(RecRef, 52790, 57303);
//                 CopyFieldIfExists(RecRef, 52791, 57304);
//                 CopyFieldIfExists(RecRef, 52792, 57305);
//                 // 57306 (StoreNoHeader_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52794, 57307);
//                 CopyFieldIfExists(RecRef, 52795, 57308);
//                 CopyFieldIfExists(RecRef, 52796, 57309);
//                 CopyFieldIfExists(RecRef, 52797, 57310);
//                 CopyFieldIfExists(RecRef, 52798, 57311);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesInvoiceLineIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Invoice Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57330);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesHeaderArchiveIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Header Archive");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57340);
//                 // 57341 (Cust Salesperson Code_DXR.) is a FlowField - no physical data to copy.
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_SalesLineArchiveIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Sales Line Archive");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57350);
//                 CopyFieldIfExists(RecRef, 52788, 57351);
//                 CopyFieldIfExists(RecRef, 52789, 57352);
//                 CopyFieldIfExists(RecRef, 52790, 57353);
//                 CopyFieldIfExists(RecRef, 52791, 57354);
//                 CopyFieldIfExists(RecRef, 52792, 57355);
//                 CopyFieldIfExists(RecRef, 52793, 57356);
//                 CopyFieldIfExists(RecRef, 52794, 57357);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchaseHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purchase Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57370);
//                 CopyFieldIfExists(RecRef, 52788, 57371);
//                 CopyFieldIfExists(RecRef, 52789, 57372);
//                 CopyFieldIfExists(RecRef, 52790, 57373);
//                 CopyFieldIfExists(RecRef, 52791, 57374);
//                 CopyFieldIfExists(RecRef, 52792, 57375);
//                 // 57376 (Envio Compras_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52794, 57377);
//                 // 57378 (Transito Internacional_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52796, 57379);
//                 CopyFieldIfExists(RecRef, 52797, 57380);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchInvHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Inv. Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57400);
//                 // 57401 (Envio Compras_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52789, 57402);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchRcptHeaderIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Rcpt. Header");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57410);
//                 CopyFieldIfExists(RecRef, 52788, 57411);
//                 CopyFieldIfExists(RecRef, 52789, 57412);
//                 CopyFieldIfExists(RecRef, 52790, 57413);
//                 CopyFieldIfExists(RecRef, 52791, 57414);
//                 CopyFieldIfExists(RecRef, 52792, 57415);
//                 CopyFieldIfExists(RecRef, 52793, 57416);
//                 CopyFieldIfExists(RecRef, 52794, 57417);
//                 CopyFieldIfExists(RecRef, 52795, 57418);
//                 CopyFieldIfExists(RecRef, 52796, 57419);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchaseHeaderArchiveIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purchase Header Archive");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57430);
//                 CopyFieldIfExists(RecRef, 52788, 57431);
//                 CopyFieldIfExists(RecRef, 52789, 57432);
//                 // 57433 (Envio Compras_DXR) is a FlowField - no physical data to copy.
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchaseLineIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purchase Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 // 57440 (Country/Region Org Code_DXR) is a FlowField - no physical data to copy.
//                 CopyFieldIfExists(RecRef, 52788, 57441);
//                 CopyFieldIfExists(RecRef, 52789, 57442);
//                 CopyFieldIfExists(RecRef, 52790, 57443);
//                 CopyFieldIfExists(RecRef, 52791, 57444);
//                 CopyFieldIfExists(RecRef, 52792, 57445);
//                 CopyFieldIfExists(RecRef, 52793, 57446);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     local procedure MigrateTableExt_PurchRcptLineIdDedup()
//     var
//         RecRef: RecordRef;
//     begin
//         RecRef.Open(Database::"Purch. Rcpt. Line");
//         if RecRef.FindSet(true) then
//             repeat
//                 CopyFieldIfExists(RecRef, 52787, 57460);
//                 PersistChangedRecord(RecRef);
//             until RecRef.Next() = 0;
//         FinishTable(RecRef);
//     end;

//     var
//         RecordChanged: Boolean;
//         RowsSinceCommit: Integer;
// }

// #endif
