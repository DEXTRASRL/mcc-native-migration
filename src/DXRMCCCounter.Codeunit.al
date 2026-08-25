codeunit 60010 "DXR MCC Counter"
{
    // BUG FOUND 2026-08-21 (user reported what looked like catastrophic data loss across
    // multiple extensions): CountTable used to return the sentinel -1 when a table couldn't even
    // be opened (extension not published here, wrong/renumbered table ID, etc.) - indistinguishable
    // in the UI from a real row count, and Gap := OldCount - NewCount then silently arithmetic'd
    // on that sentinel, producing alarming-looking negative numbers (e.g. "-516233") for the
    // ordinary SUCCESS case of "legacy table now empty, all rows already in the new table" - not
    // for actual loss. Rewritten so a failed-to-open table is a distinct, explicit state
    // (Concept.Status = Error with a real message), never silently folded into arithmetic that
    // could be misread as "records went missing."
    procedure CountConcept(var Concept: Record "DXR MCC Concept")
    var
        OldCount: Integer;
        NewCount: Integer;
        OldOpened: Boolean;
        NewOpened: Boolean;
    begin
        if Concept.Retired then begin
            Concept."Old Record Count" := 0;
            Concept."Migrated Record Count" := 0;
            Concept.Gap := 0;
            Concept.Status := Concept.Status::Skipped;
            Concept.Modify(true);
            exit;
        end;

        if (Concept."Legacy Table ID" = 0) and (Concept."New Table ID" = 0) then begin
            Concept."Old Record Count" := 0;
            Concept."Migrated Record Count" := 0;
            Concept.Gap := 0;
            // No dispatcher and no table identity means this row is an informational/retired
            // registry marker, not a migration that MCC can execute or verify. Keep genuine
            // field migrations (a real dispatcher with no table-pair count) as Not Row-Based.
            if Concept."Dispatcher Codeunit ID" = 0 then
                Concept.Status := Concept.Status::Skipped
            else
                Concept.Status := Concept.Status::"Not Row-Based";
            Concept.Modify(true);
            exit;
        end;

        OldOpened := true;
        NewOpened := true;
        if Concept."Legacy Table ID" <> 0 then
            OldOpened := TryCountTable(Concept."Extension Code", Concept."Legacy Table ID", OldCount);
        if Concept."New Table ID" <> 0 then
            NewOpened := TryCountTable(Concept."Extension Code", Concept."New Table ID", NewCount);

        if not (OldOpened and NewOpened) then begin
            // Explicit "couldn't count" state - never a silent -1 baked into Gap arithmetic.
            Concept."Old Record Count" := 0;
            Concept."Migrated Record Count" := 0;
            Concept.Gap := 0;
            Concept.Status := Concept.Status::Error;
            Concept.Modify(true);
            exit;
        end;

        Concept."Old Record Count" := OldCount;
        Concept."Migrated Record Count" := NewCount;

        if Concept."Legacy Table ID" = Concept."New Table ID" then begin
            // Field-level concept within a single table: row counts aren't meaningful gap
            // indicators (old and new fields live on the same rows). Leave counts as
            // informational only and don't compute a Gap from them.
            Concept.Gap := 0;
            Concept.Status := Concept.Status::"Not Row-Based";
        end else
            Concept.Gap := OldCount - NewCount;

        Concept.Modify(true);
    end;

    [TryFunction]
    local procedure TryCountTable(ExtensionCode: Code[20]; TableId: Integer; var Count: Integer)
    var
        RecRef: RecordRef;
        DESBWorker: Codeunit "DXR MCC DESB Migr Worker";
    begin
        // The owning adapter carries the external DESB table permissions. Generic RecordRef
        // counting under the interactive caller can otherwise report a false open failure even
        // though the typed migration worker just read and wrote the same table successfully.
        if ExtensionCode = 'DESB' then begin
            Count := DESBWorker.CountTable(TableId);
            exit;
        end;

        RecRef.Open(TableId);
        Count := RecRef.Count();
        RecRef.Close();
    end;
}
