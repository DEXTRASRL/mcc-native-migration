codeunit 60141 "DXR MCC FE Migr Phase12"
{
    // Native local migration - ported verbatim from Facturacion Electronica's own
    // "DXR_Migr. Phase 12 History".OnRun() (Access = Internal). "EF Payload Text Chunk" (55703)
    // and "EF ATEB Send Registry" (55610), and their DXR_ targets, are all Access = Internal on
    // FE's side - but FE grants MCC's own app ID internalsVisibleTo directly (see FE's own
    // app.json), so MCC can declare typed Record variables on all 4 directly. Converted from
    // RecordRef/FieldRef positional field access to direct typed field assignment, zero
    // RecordRef/FieldRef/TransferFields. Field positions confirmed against real table source in
    // "...\Facturacion Workspace\BC-Facturacion-Electronica\Facturacion Electronica\Base\old\Tables.old\EFPayloadTextChunk.Table.al"/
    // "EFSendRegistry.Table.al" (source) and "...\Base\Tables\EFPayloadTextChunk.Table.al"/
    // "EFSendRegistry.Table.al" (target) - identical field lists/order on both sides, only the
    // enum/table names differ ("EF ..." vs "DXR_..."). Each enum re-mapping step
    // (Enum::"DXR_...".FromInteger(Source.AsInteger())) uses structurally identical enum pairs
    // ("EF Payload Source"/"DXR_Payload Source", "EF Payload Kind"/"DXR_Payload Kind",
    // "EF Service Provider"/"DXR_Service Provider", "EF Send Payload Type"/"DXR_Send Payload
    // Type", "EF Send Registry Status"/"DXR_Send Registry Status" - all confirmed by reading both
    // enum sources). "Source Type" (field 6 on both tables) is a plain Option with identical
    // OptionMembers (Sales,Purchase,POS) on both sides, so it is copied by direct assignment
    // with no enum conversion needed.
    Permissions =
        tabledata "EF Payload Text Chunk" = R,
        tabledata "EF ATEB Send Registry" = R,
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

    // "EF Payload Text Chunk" holds every historical eCF payload split into ~2048-char chunks
    // (multiple rows per document) - potentially unbounded row volume, so batched in
    // Commit-groups of 100, matching this campaign's precedent for large history/audit tables.
    local procedure MigratePayloadTextChunks()
    var
        Source: Record "EF Payload Text Chunk";
        Target: Record "DXR_Payload Text Chunk";
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                Target.Init();
                Target."Payload Source" := Enum::"DXR_Payload Source".FromInteger(Source."Payload Source".AsInteger());
                Target."Document No." := Source."Document No.";
                Target.NCF := Source.NCF;
                Target."Track ID" := Source."Track ID";
                Target."Payload Kind" := Enum::"DXR_Payload Kind".FromInteger(Source."Payload Kind".AsInteger());
                Target."Line No." := Source."Line No.";
                Target."Text Chunk" := Source."Text Chunk";
                Target."Content Hash" := Source."Content Hash";
                Target."Created DateTime" := Source."Created DateTime";
                Target."Is Base64" := Source."Is Base64";
                if not Target.Insert(false) then
                    Target.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;

    // "EF ATEB Send Registry" holds one row per historical send attempt - also potentially
    // unbounded row volume, same batching discipline as MigratePayloadTextChunks above.
    local procedure MigrateSendRegistry()
    var
        Source: Record "EF ATEB Send Registry";
        Target: Record "DXR_ATEB Send Registry";
        BatchCount: Integer;
    begin
        if Source.FindSet(false) then
            repeat
                Target.Init();
                Target.Provider := Enum::"DXR_Service Provider".FromInteger(Source.Provider.AsInteger());
                Target."Provider Company ID" := Source."Provider Company ID";
                Target.NCF := Source.NCF;
                Target."Payload Type" := Enum::"DXR_Send Payload Type".FromInteger(Source."Payload Type".AsInteger());
                Target."Document No." := Source."Document No.";
                Target."Source Type" := Source."Source Type";
                Target.Status := Enum::"DXR_Send Registry Status".FromInteger(Source.Status.AsInteger());
                Target."Provider Service URL" := Source."Provider Service URL";
                Target."Reserved DateTime" := Source."Reserved DateTime";
                Target."Last Attempt DateTime" := Source."Last Attempt DateTime";
                Target."Sent DateTime" := Source."Sent DateTime";
                Target."Track ID" := Source."Track ID";
                Target."Security Code" := Source."Security Code";
                Target."Response Status" := Source."Response Status";
                Target."Provider Internal Doc. No." := Source."Provider Internal Doc. No.";
                Target."Last Message" := Source."Last Message";
                Target."Retry Count" := Source."Retry Count";
                Target."Session ID" := Source."Session ID";
                Target."Event Source" := Source."Event Source";
                Target."Is Resend" := Source."Is Resend";
                if not Target.Insert(false) then
                    Target.Modify(false);

                BatchCount += 1;
                if BatchCount >= 100 then begin
                    Commit();
                    BatchCount := 0;
                end;
            until Source.Next() = 0;
    end;
}
