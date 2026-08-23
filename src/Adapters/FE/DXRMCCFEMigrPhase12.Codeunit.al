codeunit 60141 "DXR MCC FE Migr Phase12"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 12 History".OnRun() (Access = Internal). "EF Payload Text Chunk" (55703)
    // and "EF ATEB Send Registry" (55610) are both Access = Internal on FE's side - accessed here
    // purely via RecordRef by numeric table ID. Each includes an enum re-mapping step
    // (Enum::"DXR_..." .FromInteger(SourceValue.AsInteger())) since the legacy tables use their
    // own "EF ..." enum types.
    Permissions =
        tabledata "DXR_Payload Text Chunk" = RIMD,
        tabledata "DXR_ATEB Send Registry" = RIMD;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-EF-TASKSCHEDULER-V6-PHASE6-HISTORICAL-TABLES-20260720') then
            exit;

        MigratePayloadTextChunks();
        MigrateSendRegistry();

        UpgradeTag.SetUpgradeTag('DXR-EF-TASKSCHEDULER-V6-PHASE6-HISTORICAL-TABLES-20260720');
    end;

    local procedure MigratePayloadTextChunks()
    var
        Target: Record "DXR_Payload Text Chunk";
        SourceRef: RecordRef;
        PayloadSourceFld, DocumentNoFld, NCFFld, TrackIDFld, PayloadKindFld : FieldRef;
        LineNoFld, TextChunkFld, ContentHashFld, CreatedDateTimeFld, IsBase64Fld : FieldRef;
    begin
        SourceRef.Open(55703); // EF Payload Text Chunk
        if SourceRef.FindSet(false) then
            repeat
                PayloadSourceFld := SourceRef.Field(1);
                DocumentNoFld := SourceRef.Field(2);
                NCFFld := SourceRef.Field(3);
                TrackIDFld := SourceRef.Field(4);
                PayloadKindFld := SourceRef.Field(5);
                LineNoFld := SourceRef.Field(6);
                TextChunkFld := SourceRef.Field(7);
                ContentHashFld := SourceRef.Field(8);
                CreatedDateTimeFld := SourceRef.Field(9);
                IsBase64Fld := SourceRef.Field(10);

                Target.Init();
                Target."Payload Source" := Enum::"DXR_Payload Source".FromInteger(GetVariantAsInteger(PayloadSourceFld.Value()));
                Target."Document No." := DocumentNoFld.Value();
                Target.NCF := NCFFld.Value();
                Target."Track ID" := TrackIDFld.Value();
                Target."Payload Kind" := Enum::"DXR_Payload Kind".FromInteger(GetVariantAsInteger(PayloadKindFld.Value()));
                Target."Line No." := LineNoFld.Value();
                Target."Text Chunk" := TextChunkFld.Value();
                Target."Content Hash" := ContentHashFld.Value();
                Target."Created DateTime" := CreatedDateTimeFld.Value();
                Target."Is Base64" := IsBase64Fld.Value();
                if not Target.Insert(false) then
                    Target.Modify(false);
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;

    local procedure MigrateSendRegistry()
    var
        Target: Record "DXR_ATEB Send Registry";
        SourceRef: RecordRef;
        ProviderFld, ProviderCompanyIDFld, NCFFld, PayloadTypeFld, DocumentNoFld : FieldRef;
        SourceTypeFld, StatusFld, ProviderServiceURLFld, ReservedDateTimeFld, LastAttemptDateTimeFld : FieldRef;
        SentDateTimeFld, TrackIDFld, SecurityCodeFld, ResponseStatusFld, ProviderInternalDocNoFld : FieldRef;
        LastMessageFld, RetryCountFld, SessionIDFld, EventSourceFld, IsResendFld : FieldRef;
    begin
        SourceRef.Open(55610); // EF ATEB Send Registry
        if SourceRef.FindSet(false) then
            repeat
                ProviderFld := SourceRef.Field(1);
                ProviderCompanyIDFld := SourceRef.Field(2);
                NCFFld := SourceRef.Field(3);
                PayloadTypeFld := SourceRef.Field(4);
                DocumentNoFld := SourceRef.Field(5);
                SourceTypeFld := SourceRef.Field(6);
                StatusFld := SourceRef.Field(7);
                ProviderServiceURLFld := SourceRef.Field(8);
                ReservedDateTimeFld := SourceRef.Field(9);
                LastAttemptDateTimeFld := SourceRef.Field(10);
                SentDateTimeFld := SourceRef.Field(11);
                TrackIDFld := SourceRef.Field(12);
                SecurityCodeFld := SourceRef.Field(13);
                ResponseStatusFld := SourceRef.Field(14);
                ProviderInternalDocNoFld := SourceRef.Field(15);
                LastMessageFld := SourceRef.Field(16);
                RetryCountFld := SourceRef.Field(17);
                SessionIDFld := SourceRef.Field(18);
                EventSourceFld := SourceRef.Field(19);
                IsResendFld := SourceRef.Field(20);

                Target.Init();
                Target.Provider := Enum::"DXR_Service Provider".FromInteger(GetVariantAsInteger(ProviderFld.Value()));
                Target."Provider Company ID" := ProviderCompanyIDFld.Value();
                Target.NCF := NCFFld.Value();
                Target."Payload Type" := Enum::"DXR_Send Payload Type".FromInteger(GetVariantAsInteger(PayloadTypeFld.Value()));
                Target."Document No." := DocumentNoFld.Value();
                Target."Source Type" := SourceTypeFld.Value();
                Target.Status := Enum::"DXR_Send Registry Status".FromInteger(GetVariantAsInteger(StatusFld.Value()));
                Target."Provider Service URL" := ProviderServiceURLFld.Value();
                Target."Reserved DateTime" := ReservedDateTimeFld.Value();
                Target."Last Attempt DateTime" := LastAttemptDateTimeFld.Value();
                Target."Sent DateTime" := SentDateTimeFld.Value();
                Target."Track ID" := TrackIDFld.Value();
                Target."Security Code" := SecurityCodeFld.Value();
                Target."Response Status" := ResponseStatusFld.Value();
                Target."Provider Internal Doc. No." := ProviderInternalDocNoFld.Value();
                Target."Last Message" := LastMessageFld.Value();
                Target."Retry Count" := RetryCountFld.Value();
                Target."Session ID" := SessionIDFld.Value();
                Target."Event Source" := EventSourceFld.Value();
                Target."Is Resend" := IsResendFld.Value();
                if not Target.Insert(false) then
                    Target.Modify(false);
            until SourceRef.Next() = 0;
        SourceRef.Close();
    end;

    local procedure GetVariantAsInteger(Value: Variant): Integer
    var
        Result: Integer;
    begin
        Result := Value;
        exit(Result);
    end;
}
