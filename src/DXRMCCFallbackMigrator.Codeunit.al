codeunit 60015 "DXR MCC Fallback Migrator"
{
    // Answers "if the extension's own dispatcher errors, can MCC do the migration itself without
    // recompiling that extension?" - yes, but only for the one shape of migration that's generic
    // enough to run without knowing anything about the target extension's specific business logic:
    // a legacy-table -> new-table row restore, where "Legacy Table ID"/"New Table ID" are already
    // tracked per DXR MCC Concept. Copies every compatible Normal-class field that exists on both
    // sides by FIELD NAME and TYPE, never by field number. This prevents a reused field ID from
    // writing a legacy value into an unrelated destination field. The copy is a true
    // RECONCILIATION rather than an all-or-nothing
    // "only when the target table is still completely empty" copy: a row whose primary key already
    // exists in the target is skipped, never overwritten (TryInsertOrSkip below), so this can run
    // repeatedly and safely close whatever gap remains without ever touching a row already there.
    // (2026-08-23: relaxed from the original empty-target-only gate, which was CONFIRMED to be the
    // root cause of gaps that never closed - a single already-migrated or manually-entered row
    // permanently blocked restoring every OTHER missing row in that same table.)
    //
    // Deliberately NOT generic for field-only concepts (Legacy Table ID = New Table ID = 0, e.g.
    // Base Controls' "Customer: Mandatory Order No./... field restore (3 fields)"): there's no way
    // to know WHICH fields without per-concept metadata this session was told to keep out of MCC's
    // schema (that's exactly the "touch every extension" cost the user chose to avoid). Those are
    // tracked as "Not Row-Based" (see DXR MCC Counter) and stay dependent on the owning extension's
    // own dispatcher - see field-id-collision-remediation.md's per-extension follow-up list.
    //
    // Parent-table-before-child ordering (2026-08-22, requested review): this fallback only ever
    // restores ONE table per call, so it never partially overwrites a row a TableRelation-
    // referencing concept depends on. Cross-table ordering is handled one layer up, by DXR MCC
    // Executor/Registry: Category (Setup always runs before Master/Accounting or Historic) plus
    // each extension's "Order No." dependency tier (e.g. Retail Controls depends on Base Controls,
    // Order No. 10 vs 0) already sequences "referenced setup table" before "table whose field points
    // at it" at the granularity MCC tracks. None of these copy loops call Validate() - they assign
    // FieldRef.Value directly - so even in the rare case a referenced row hasn't landed yet, the
    // copy itself never fails; the field just doesn't resolve to a caption until its parent table's
    // own concept finishes, same run.

    /// <summary>
    /// Attempts a generic table-pair reconciliation restore. Returns true only if it actually
    /// copied at least one missing row. Returns false for "can't attempt this at all" (either table
    /// ID doesn't exist on this environment) or "attempted but nothing was missing" (source empty,
    /// or every source row already exists in the target by primary key) - both are reported via
    /// ResultText, not treated as an error by the caller.
    /// </summary>
    procedure TryRestoreTablePair(LegacyTableId: Integer; NewTableId: Integer; var RowsCopied: Integer; var ResultText: Text): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        RowsCopied := 0;

        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, LegacyTableId) then begin
            ResultText := StrSubstNo('Fallback not possible: legacy table %1 does not exist on this environment.', LegacyTableId);
            exit(false);
        end;
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, NewTableId) then begin
            ResultText := StrSubstNo('Fallback not possible: new table %1 does not exist on this environment.', NewTableId);
            exit(false);
        end;

        if not CopyMissingRows(LegacyTableId, NewTableId, RowsCopied) then begin
            ResultText := 'Fallback: nothing copied (source table is empty, or every source row already exists in the target by primary key).';
            exit(false);
        end;

        ResultText := StrSubstNo('Fallback reconciliation via MCC generic table-pair copy: %1 row(s) restored.', RowsCopied);
        exit(true);
    end;

    /// <summary>
    /// Row-by-row RECONCILIATION copy (renamed/rewritten 2026-08-23 from the old
    /// CopyTableIfTargetEmpty, which refused to copy anything at all if the target table had even
    /// ONE row - a single already-migrated row, or one genuine user-entered row, permanently
    /// blocked restoring every OTHER missing row in that same table forever. CONFIRMED root cause
    /// of persistent "old table has data, new table doesn't" gaps for every table-pair concept
    /// relying on this fallback. Safe without the empty-target gate because TryInsertOrSkip below
    /// already skips (never overwrites) any source row whose primary key collides with an existing
    /// target row - the gate was redundant defense against a case the per-row skip already handles.
    /// </summary>
    local procedure CopyMissingRows(OldTableId: Integer; NewTableId: Integer; var RowsCopied: Integer): Boolean
    var
        OldRecRef: RecordRef;
        NewRecRef: RecordRef;
        OldFieldRef: FieldRef;
        NewFieldRef: FieldRef;
        FieldIdx: Integer;
    begin
        OldRecRef.Open(OldTableId);
        if not OldRecRef.FindSet() then begin
            OldRecRef.Close();
            exit(false);
        end;

        // NewRecRef opened ONCE before the loop, not per-iteration: calling RecordRef.Open() again
        // on a variable that's already open throws "The record is already open" - confirmed live
        // (2026-08-22, "Attempt 2 failed, retrying: The record is already open" on Run All Setup)
        // as soon as a legacy table had more than 1 row, since the 2nd iteration tried to reopen
        // the same handle the 1st iteration never closed.
        NewRecRef.Open(NewTableId);
        repeat
            NewRecRef.Init();
            for FieldIdx := 1 to OldRecRef.FieldCount() do begin
                OldFieldRef := OldRecRef.FieldIndex(FieldIdx);
                // FieldClass::Normal on BOTH sides excludes FlowFields (Class = FlowField) -
                // FlowFields are calculated, never stored, and RecordRef can't write to them; the
                // one thing that makes a FlowField show the right value is its underlying source
                // fields already being migrated, which this same loop does for every Normal field
                // on the row, so no separate "migrate the FlowField's source first" step is needed.
                if (OldFieldRef.Number() < 2000000000) and
                   (OldFieldRef.Class() = FieldClass::Normal) and
                   NewRecRef.FieldExist(OldFieldRef.Name())
                then begin
                    NewFieldRef := NewRecRef.Field(OldFieldRef.Name());
                    // Skip when the source value equals NewFieldRef's still-untouched Init()
                    // default (blank Text/Code, 0, false, 0D...) - comparing by Format() keeps
                    // this type-agnostic. Target row is always freshly Init()'d here, so this is a
                    // no-op on the result (blank would've matched the default anyway); it exists so
                    // a blank source field is never mistaken, in a future re-run against a
                    // partially-populated row, for a real migrated value.
                    if (NewFieldRef.Class() = FieldClass::Normal) and
                       (OldFieldRef.Type() = NewFieldRef.Type()) and
                       (Format(OldFieldRef.Value()) <> Format(NewFieldRef.Value()))
                    then
                        NewFieldRef.Value := OldFieldRef.Value();
                end;
            end;
            // 2026-08-22 (user-reported: "The record in table DXR_API Dgi Setup already exists" -
            // this exact loop, unguarded Insert(false), crashed the whole run instead of skipping
            // one colliding row). TryInsertOrSkip never overwrites an existing target row (that
            // would risk clobbering real data written by something else in the meantime) - it just
            // skips the colliding source row and keeps going. Since 2026-08-23 this is the ONLY
            // dedup mechanism (the old upfront "target must be completely empty" gate is gone) -
            // every row, whether the target started empty or already had some rows, goes through
            // this same insert-or-skip-on-collision path.
            if TryInsertOrSkip(NewRecRef) then
                RowsCopied += 1;
        until OldRecRef.Next() = 0;
        NewRecRef.Close();
        OldRecRef.Close();
        exit(RowsCopied > 0);
    end;

    [TryFunction]
    local procedure TryInsertOrSkip(var RecRef: RecordRef)
    begin
        RecRef.Insert(false);
    end;
}
