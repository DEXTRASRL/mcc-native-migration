codeunit 60108 "DXR MCC RBPD Migr History"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateHistory(). Wired from TWO registry rows
    // (RBPD-P2 seq4 "History Header" and seq11 "History Details") since Header+Details is
    // an atomic linked-ID-remap pair that cannot be split: the Header's AutoIncrement
    // primary key is reassigned on Insert into the new table, so each Detail row's
    // "idheader" foreign key must be captured and remapped via the old-id -> new-id
    // dictionary built while inserting Headers, in the same pass.
    Permissions = tabledata "DXR-IB IbankingHistoryHeader" = R,
                  tabledata "DXR_IbankingHistoryHeader" = RIM,
                  tabledata "DXR-IB IbankingHistoryDetails" = R,
                  tabledata "DXR_IbankingHistoryDetails" = RIM;

    trigger OnRun()
    var
        OldHeader: Record "DXR-IB IbankingHistoryHeader";
        NewHeader: Record "DXR_IbankingHistoryHeader";
        OldDetail: Record "DXR-IB IbankingHistoryDetails";
        NewDetail: Record "DXR_IbankingHistoryDetails";
        OldToNewHeaderId: Dictionary of [BigInteger, BigInteger];
        NewHeaderId: BigInteger;
    begin
        // Headers: capture old id -> new id mapping (AutoIncrement is reassigned on Insert).
        if OldHeader.FindSet() then
            repeat
                NewHeader.Init();
                NewHeader.TransferFields(OldHeader, false); // do not copy the AutoIncrement PK
                if NewHeader.Insert(true) then
                    OldToNewHeaderId.Add(OldHeader."id DXR-IB", NewHeader."id DXR-IB");
            until OldHeader.Next() = 0;

        // Details: copy and remap "idheader DXR-IB" to the new header id.
        if OldDetail.FindSet() then
            repeat
                if OldToNewHeaderId.ContainsKey(OldDetail."idheader DXR-IB") then begin
                    NewHeaderId := OldToNewHeaderId.Get(OldDetail."idheader DXR-IB");
                    NewDetail.Init();
                    NewDetail.TransferFields(OldDetail, false); // do not copy the AutoIncrement PK
                    NewDetail."idheader DXR-IB" := NewHeaderId;
                    NewDetail.Insert(true);
                end;
            until OldDetail.Next() = 0;
    end;
}
