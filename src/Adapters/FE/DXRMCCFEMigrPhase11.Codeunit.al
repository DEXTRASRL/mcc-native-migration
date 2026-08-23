codeunit 60140 "DXR MCC FE Migr Phase11"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 11 Tables".OnRun() (Access = Internal). 30 plain standalone-table restores
    // + 3 with custom merge logic (Archived Sent Request scoring-merge, Codigos Item/Currency Type
    // key-based upsert). Nearly every "EF ..." source table here is itself Access = Internal on
    // FE's side, so every source access in this codeunit goes through RecordRef by numeric table
    // ID (never by name) - the "DXR_..." targets are all public, so those stay typed Records where
    // that's simpler (the 3 custom procedures) or numeric IDs (the 30 plain CopyStandaloneTable
    // calls, matching the source's own generic RecordRef-based implementation exactly).
    Permissions =
        tabledata "DXR_Administration Setup" = RIMD,
        tabledata "DXR_Archived E Documents" = RIMD,
        tabledata "DXR_Archived Sent Request" = RIMD,
        tabledata "DXR_Bulk Credit Memo Entry" = RIMD,
        tabledata "DXR_Bulk Credit Memo Log" = RIMD,
        tabledata "DXR_Bulk NCF Import Entry" = RIMD,
        tabledata "DXR_Codigos Item" = RIMD,
        tabledata "DXR_Currency Type" = RIMD,
        tabledata "DXR_Descuentos O Recargos" = RIMD,
        tabledata "DXR_Det. Bienes o Servicios" = RIMD,
        tabledata "DXR_Encabezado" = RIMD,
        tabledata "DXR_Formas de Pago" = RIMD,
        tabledata "DXR_Form Type" = RIMD,
        tabledata "DXR_Imp. Adicionales Encab." = RIMD,
        tabledata "DXR_Imp. Adicionales - DBS" = RIMD,
        tabledata "DXR_Income Validation Type" = RIMD,
        tabledata "DXR_Informacion Referencia" = RIMD,
        tabledata "DXR_Log Message" = RIMD,
        tabledata "DXR_Modification Code Type" = RIMD,
        tabledata "DXR_Paginacion" = RIMD,
        tabledata "DXR_Payment Type Form" = RIMD,
        tabledata "DXR_Process Request" = RIMD,
        tabledata "DXR_Receipt Acknowledgement" = RIMD,
        tabledata "DXR_Resend Document Queue" = RIMD,
        tabledata "DXR_Resend Job Log" = RIMD,
        tabledata "DXR_Response Documents" = RIMD,
        tabledata "DXR_Subcantidad" = RIMD,
        tabledata "DXR_SubDescuento" = RIMD,
        tabledata "DXR_SubRecargo" = RIMD,
        tabledata "DXR_SubTotales Informativos" = RIMD,
        tabledata "DXR_Tax Coding Type" = RIMD,
        tabledata "DXR_Telefono Emisor" = RIMD,
        tabledata "DXR_Township" = RIMD,
        tabledata "DXR_Unit of Measure Type" = RIMD;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625') then
            exit;

        MigrateStandaloneTables();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V5-PHASE5-STANDALONE-TABLES-20260625');
    end;

    local procedure MigrateStandaloneTables()
    begin
        CopyStandaloneTable(55501, Database::"DXR_Administration Setup"); // EF Administration Setup
        CopyStandaloneTable(55502, Database::"DXR_Archived E Documents"); // EF Archived E Documents
        MigrateArchivedSentRequest(); // EF Archived Sent Request (55503) -> DXR_Archived Sent Request
        CopyStandaloneTable(55532, Database::"DXR_Bulk Credit Memo Entry"); // EF Bulk Credit Memo Entry
        CopyStandaloneTable(55533, Database::"DXR_Bulk Credit Memo Log"); // EF Bulk Credit Memo Log
        CopyStandaloneTable(55575, Database::"DXR_Bulk NCF Import Entry"); // EF Bulk NCF Import Entry
        MigrateCodigosItem(); // EF Codigos Item (55504) -> DXR_Codigos Item
        CopyCurrencyType(); // EF Currency Type (55505) -> DXR_Currency Type
        CopyStandaloneTable(55506, Database::"DXR_Descuentos O Recargos"); // EF Descuentos O Recargos
        CopyStandaloneTable(55507, Database::"DXR_Det. Bienes o Servicios"); // EF Detalle Bienes o Servicios
        CopyStandaloneTable(55508, Database::"DXR_Encabezado"); // EF Encabezado
        CopyStandaloneTable(55509, Database::"DXR_Formas de Pago"); // EF Formas de Pago
        CopyStandaloneTable(55529, Database::"DXR_Form Type"); // EF Form Type
        CopyStandaloneTable(55510, Database::"DXR_Imp. Adicionales Encab."); // EF Imp. Adicionales - Encab.
        CopyStandaloneTable(55511, Database::"DXR_Imp. Adicionales - DBS"); // EF Impuestos Adicionales - DBS
        CopyStandaloneTable(55512, Database::"DXR_Income Validation Type"); // EF Income Validation Type
        CopyStandaloneTable(55513, Database::"DXR_Informacion Referencia"); // EF Informacion Referencia
        CopyStandaloneTable(55514, Database::"DXR_Log Message"); // EF Log Message
        CopyStandaloneTable(55515, Database::"DXR_Modification Code Type"); // EF Modification Code Type
        CopyStandaloneTable(55516, Database::"DXR_Paginacion"); // EF Paginacion
        CopyStandaloneTable(55517, Database::"DXR_Payment Type Form"); // EF Payment Type Form
        CopyStandaloneTable(55518, Database::"DXR_Process Request"); // EF Process Request
        CopyStandaloneTable(55519, Database::"DXR_Receipt Acknowledgement"); // EF Receipt Acknowledgement
        CopyStandaloneTable(55531, Database::"DXR_Resend Document Queue"); // EF Resend Document Queue
        CopyStandaloneTable(55530, Database::"DXR_Resend Job Log"); // EF Resend Job Log
        CopyStandaloneTable(55520, Database::"DXR_Response Documents"); // EF Response Documents
        CopyStandaloneTable(55521, Database::"DXR_Subcantidad"); // EF Subcantidad
        CopyStandaloneTable(55522, Database::"DXR_SubDescuento"); // EF SubDescuento
        CopyStandaloneTable(55523, Database::"DXR_SubRecargo"); // EF SubRecargo
        CopyStandaloneTable(55524, Database::"DXR_SubTotales Informativos"); // EF SubTotales Informativos
        CopyStandaloneTable(55525, Database::"DXR_Tax Coding Type"); // EF Tax Coding Type
        CopyStandaloneTable(55526, Database::"DXR_Telefono Emisor"); // EF Telefono Emisor
        CopyStandaloneTable(55527, Database::"DXR_Township"); // EF Township
        CopyStandaloneTable(55528, Database::"DXR_Unit of Measure Type"); // EF Unit of Measure Type
    end;

    local procedure CopyCurrencyType()
    var
        TargetCurrencyType: Record "DXR_Currency Type";
        SourceRef: RecordRef;
        IdFld: FieldRef;
        DescriptionFld: FieldRef;
    begin
        SourceRef.Open(55505); // EF Currency Type
        if SourceRef.FindSet() then
            repeat
                IdFld := SourceRef.Field(1); // Id
                DescriptionFld := SourceRef.Field(2); // Description

                TargetCurrencyType.Reset();
                TargetCurrencyType.SetRange(Id, IdFld.Value());

                if TargetCurrencyType.FindFirst() then begin
                    TargetCurrencyType.Description := DescriptionFld.Value();
                    TargetCurrencyType.Modify(false);
                end else begin
                    TargetCurrencyType.Init();
                    TargetCurrencyType.Id := IdFld.Value();
                    TargetCurrencyType.Description := DescriptionFld.Value();
                    TargetCurrencyType.Insert(false);
                end;
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;

    local procedure CopyStandaloneTable(SourceTableId: Integer; TargetTableId: Integer)
    var
        SourceRecordRef: RecordRef;
        TargetRecordRef: RecordRef;
        SourceKeyRef: KeyRef;
        SourceFieldRef: FieldRef;
        TargetFieldRef: FieldRef;
        SourcePkFieldRef: FieldRef;
        TargetPkFieldRef: FieldRef;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        TargetExists: Boolean;
    begin
        SourceRecordRef.Open(SourceTableId);
        TargetRecordRef.Open(TargetTableId);

        SourceKeyRef := SourceRecordRef.KeyIndex(1);

        if SourceRecordRef.FindSet() then
            repeat
                TargetRecordRef.Reset();

                for KeyFieldIndex := 1 to SourceKeyRef.FieldCount() do begin
                    SourcePkFieldRef := SourceKeyRef.FieldIndex(KeyFieldIndex);
                    TargetPkFieldRef := TargetRecordRef.Field(SourcePkFieldRef.Number);
                    TargetPkFieldRef.SetRange(SourcePkFieldRef.Value);
                end;

                TargetExists := TargetRecordRef.FindFirst();

                if TargetExists then begin
                    for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
                        SourceFieldRef := SourceRecordRef.FieldIndex(FieldIndex);

                        if TargetRecordRef.FieldExist(SourceFieldRef.Number) then begin
                            TargetFieldRef := TargetRecordRef.Field(SourceFieldRef.Number);

                            if TargetFieldRef.Class = FieldClass::Normal then
                                TargetFieldRef.Value := SourceFieldRef.Value;
                        end;
                    end;

                    TargetRecordRef.Modify(false);
                end else begin
                    TargetRecordRef.Init();

                    for FieldIndex := 1 to SourceRecordRef.FieldCount() do begin
                        SourceFieldRef := SourceRecordRef.FieldIndex(FieldIndex);

                        if TargetRecordRef.FieldExist(SourceFieldRef.Number) then begin
                            TargetFieldRef := TargetRecordRef.Field(SourceFieldRef.Number);

                            if TargetFieldRef.Class = FieldClass::Normal then
                                TargetFieldRef.Value := SourceFieldRef.Value;
                        end;
                    end;

                    TargetRecordRef.Insert(false);
                end;
            until SourceRecordRef.Next() = 0;

        TargetRecordRef.Close();
        SourceRecordRef.Close();
    end;

    local procedure MigrateArchivedSentRequest()
    var
        TargetArchivedSentRequest: Record "DXR_Archived Sent Request";
        SourceRef: RecordRef;
        DocumentNoFld, DocumentSourceTypeFld, ENCFFld, PostingDateFld, DocumentStatusFld, CodeFld : FieldRef;
        EFCTrackIDFld, EFCTypeFld, SourceCodeTypeFld, RequestTypeFld, SecurityCodeFld : FieldRef;
        StampedDateFld, SignedDateFld, XMLFileFld, ProviderFld : FieldRef;
    begin
        TargetArchivedSentRequest.DeleteAll(false);

        SourceRef.Open(55503); // EF Archived Sent Request
        if SourceRef.FindSet() then
            repeat
                DocumentNoFld := SourceRef.Field(1);
                DocumentSourceTypeFld := SourceRef.Field(2);

                if TargetArchivedSentRequest.Get(DocumentNoFld.Value(), DocumentSourceTypeFld.Value()) then begin
                    if ShouldReplaceArchivedSentRequest(SourceRef, TargetArchivedSentRequest) then begin
                        TargetArchivedSentRequest.Delete(false);
                        InsertArchivedSentRequest(SourceRef);
                    end;
                end else
                    InsertArchivedSentRequest(SourceRef);
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;

    local procedure InsertArchivedSentRequest(var SourceRef: RecordRef)
    var
        TargetArchivedSentRequest: Record "DXR_Archived Sent Request";
        TargetRef: RecordRef;
        DocumentNoFld, DocumentSourceTypeFld, ENCFFld, PostingDateFld, DocumentStatusFld, CodeFld : FieldRef;
        EFCTrackIDFld, EFCTypeFld, SourceCodeTypeFld, RequestTypeFld, SecurityCodeFld : FieldRef;
        StampedDateFld, SignedDateFld, XMLFileFld, TargetXMLFileFld : FieldRef;
    begin
        DocumentNoFld := SourceRef.Field(1);
        DocumentSourceTypeFld := SourceRef.Field(2);
        ENCFFld := SourceRef.Field(3);
        PostingDateFld := SourceRef.Field(4);
        DocumentStatusFld := SourceRef.Field(5);
        CodeFld := SourceRef.Field(6);
        EFCTrackIDFld := SourceRef.Field(7);
        EFCTypeFld := SourceRef.Field(8);
        SourceCodeTypeFld := SourceRef.Field(9);
        RequestTypeFld := SourceRef.Field(10);
        SecurityCodeFld := SourceRef.Field(11);
        StampedDateFld := SourceRef.Field(12);
        SignedDateFld := SourceRef.Field(13);
        XMLFileFld := SourceRef.Field(14);

        TargetArchivedSentRequest.Init();
        TargetArchivedSentRequest."Document No." := DocumentNoFld.Value();
        TargetArchivedSentRequest."Document Source Type" := DocumentSourceTypeFld.Value();
        TargetArchivedSentRequest."e-NCF" := ENCFFld.Value();
        TargetArchivedSentRequest."Posting Date" := PostingDateFld.Value();
        TargetArchivedSentRequest."Document Status" := DocumentStatusFld.Value();
        TargetArchivedSentRequest.Code := CodeFld.Value();
        TargetArchivedSentRequest."EFC Track ID" := EFCTrackIDFld.Value();
        TargetArchivedSentRequest."EFC Type" := Enum::"DXR_ecfType Basic".FromInteger(GetVariantAsInteger(EFCTypeFld.Value()));
        TargetArchivedSentRequest."DXR_Source Code Type" := Enum::"DXR_Source Code Type".FromInteger(GetVariantAsInteger(SourceCodeTypeFld.Value()));
        TargetArchivedSentRequest."EF Request Type" := Enum::"DXR_Request Status Type".FromInteger(GetVariantAsInteger(RequestTypeFld.Value()));
        TargetArchivedSentRequest."Security Code" := SecurityCodeFld.Value();
        TargetArchivedSentRequest."Stamped Date" := StampedDateFld.Value();
        TargetArchivedSentRequest."Signed Date" := SignedDateFld.Value();
        TargetArchivedSentRequest.Insert(false);

        // BLOB fields copy via plain FieldRef.Value assignment (same mechanism
        // CopyStandaloneTable already uses for every field, BLOBs included) rather than explicit
        // stream APIs, which this AL/compiler version does not expose on FieldRef.
        TargetRef.GetTable(TargetArchivedSentRequest);
        TargetXMLFileFld := TargetRef.Field(14);
        TargetXMLFileFld.Value := XMLFileFld.Value;
        TargetRef.Modify(false);
    end;

    local procedure HasBlobValue(var SourceRef: RecordRef; BlobFieldNo: Integer): Boolean
    var
        BlobFld: FieldRef;
    begin
        BlobFld := SourceRef.Field(BlobFieldNo);
        exit(BlobFld.Length() > 0);
    end;

    local procedure GetVariantAsInteger(Value: Variant): Integer
    var
        Result: Integer;
    begin
        Result := Value;
        exit(Result);
    end;

    local procedure ShouldReplaceArchivedSentRequest(var SourceRef: RecordRef; var TargetArchivedSentRequest: Record "DXR_Archived Sent Request"): Boolean
    var
        SourceScore: Integer;
        TargetScore: Integer;
        StampedDateFld, PostingDateFld : FieldRef;
        SourceStampedDate: Date;
        SourcePostingDate: Date;
    begin
        SourceScore := GetArchivedSentRequestScore(SourceRef);
        TargetScore := GetArchivedSentRequestScoreTarget(TargetArchivedSentRequest);
        if SourceScore <> TargetScore then
            exit(SourceScore > TargetScore);

        StampedDateFld := SourceRef.Field(12);
        SourceStampedDate := StampedDateFld.Value();
        if SourceStampedDate <> TargetArchivedSentRequest."Stamped Date" then
            exit(SourceStampedDate > TargetArchivedSentRequest."Stamped Date");

        PostingDateFld := SourceRef.Field(4);
        SourcePostingDate := PostingDateFld.Value();
        exit(SourcePostingDate > TargetArchivedSentRequest."Posting Date");
    end;

    local procedure GetArchivedSentRequestScore(var SourceRef: RecordRef): Integer
    var
        SecurityCodeFld, EFCTrackIDFld, SignedDateFld : FieldRef;
        StampedDateFld: FieldRef;
        SecurityCode: Text;
        EFCTrackID: Text;
        SignedDate: Text;
        StampedDate: Date;
        Score: Integer;
    begin
        SecurityCodeFld := SourceRef.Field(11);
        EFCTrackIDFld := SourceRef.Field(7);
        SignedDateFld := SourceRef.Field(13);
        StampedDateFld := SourceRef.Field(12);

        SecurityCode := SecurityCodeFld.Value();
        EFCTrackID := EFCTrackIDFld.Value();
        SignedDate := SignedDateFld.Value();
        StampedDate := StampedDateFld.Value();

        if SecurityCode <> '' then
            Score += 1;
        if EFCTrackID <> '' then
            Score += 1;
        if SignedDate <> '' then
            Score += 1;
        if StampedDate <> 0D then
            Score += 1;
        if HasBlobValue(SourceRef, 14) then
            Score += 1;

        exit(Score);
    end;

    local procedure GetArchivedSentRequestScoreTarget(var ArchivedSentRequest: Record "DXR_Archived Sent Request"): Integer
    var
        Score: Integer;
    begin
        ArchivedSentRequest.CalcFields("XML File");

        if ArchivedSentRequest."Security Code" <> '' then
            Score += 1;
        if ArchivedSentRequest."EFC Track ID" <> '' then
            Score += 1;
        if ArchivedSentRequest."Signed Date" <> '' then
            Score += 1;
        if ArchivedSentRequest."Stamped Date" <> 0D then
            Score += 1;
        if ArchivedSentRequest."XML File".HasValue() then
            Score += 1;

        exit(Score);
    end;

    local procedure MigrateCodigosItem()
    var
        TargetCodigosItem: Record "DXR_Codigos Item";
        SourceRef: RecordRef;
        TipoCodigoFld, CodigoItemFld, DocumentNoFld, DocumentLineNoFld : FieldRef;
    begin
        TargetCodigosItem.DeleteAll(false);

        SourceRef.Open(55504); // EF Codigos Item
        if SourceRef.FindSet() then
            repeat
                DocumentNoFld := SourceRef.Field(300);
                DocumentLineNoFld := SourceRef.Field(301);

                if not TargetCodigosItem.Get(DocumentNoFld.Value(), DocumentLineNoFld.Value()) then begin
                    TipoCodigoFld := SourceRef.Field(1);
                    CodigoItemFld := SourceRef.Field(2);

                    TargetCodigosItem.Init();
                    TargetCodigosItem.DocumentNo := DocumentNoFld.Value();
                    TargetCodigosItem.DocumentLineNo := DocumentLineNoFld.Value();
                    TargetCodigosItem.TipoCodigo := TipoCodigoFld.Value();
                    TargetCodigosItem.CodigoItem := CodigoItemFld.Value();
                    TargetCodigosItem.Insert(false);
                end;
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;
}
