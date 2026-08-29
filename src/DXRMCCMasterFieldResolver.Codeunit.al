codeunit 60446 "DXR MCC Master Field Resolver"
{
    procedure CopyFirstPopulatedField(var RecRef: RecordRef; TargetFieldName: Text; SourceFieldNames: Text): Boolean
    var
        SourceField: FieldRef;
        TargetField: FieldRef;
        CandidateName: Text;
        RemainingNames: Text;
        SeparatorPos: Integer;
    begin
        if not TryResolveFieldByName(RecRef, TargetFieldName, TargetField) then
            exit(false);
        if TargetField.Class() <> FieldClass::Normal then
            exit(false);
        if HasValue(TargetField) then
            exit(false);

        RemainingNames := SourceFieldNames;
        while RemainingNames <> '' do begin
            SeparatorPos := StrPos(RemainingNames, '|');
            if SeparatorPos = 0 then begin
                CandidateName := RemainingNames;
                Clear(RemainingNames);
            end else begin
                CandidateName := CopyStr(RemainingNames, 1, SeparatorPos - 1);
                RemainingNames := CopyStr(RemainingNames, SeparatorPos + 1);
            end;

            // Fixed 2026-08-27 (CONFIRMED runtime crash): this was a single compound condition -
            //     if TryResolveFieldByName(...) and (SourceField.Class() = ...) and ... then
            // AL has NO short-circuiting boolean operators. Learn's "Boolean (logical) operators"
            // lists only not/and/or/xor as plain binary infix operators; there is no `&&`/`||`
            // equivalent, so BOTH sides of an `and` are always evaluated. When
            // TryResolveFieldByName returned false, SourceField had never been assigned and the
            // runtime still evaluated SourceField.Class(), throwing
            // "Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized" and aborting the
            // whole phase.
            // That is not a theoretical path: a field whose ObsoleteState is Removed does not appear
            // in RecRef.FieldIndex() at all, so every caller passing a candidate name that is now
            // Removed hit this. Observed live on BELLON-P8 "Contact field restore (19 fields)",
            // which failed after 342 ms with exactly that message - most of Contact's "_Old"
            // candidates are ObsoleteState = Removed.
            // This resolver is shared by BELLON Phase3/7/8/14, DESB, LSLOC and TU, so the crash was
            // reachable from any of them. Nested ifs are correct regardless of evaluation order:
            // SourceField is only touched after it has actually been resolved.
            if TryResolveFieldByName(RecRef, CandidateName, SourceField) then
                if SourceField.Class() = FieldClass::Normal then
                    if SourceField.Type() = TargetField.Type() then
                        if HasValue(SourceField) then begin
                            TargetField.Value := SourceField.Value;
                            exit(true);
                        end;
        end;

        exit(false);
    end;

    procedure TryResolveFieldByName(var RecRef: RecordRef; FieldName: Text; var ResolvedField: FieldRef): Boolean
    var
        CandidateField: FieldRef;
        FieldIndex: Integer;
    begin
        for FieldIndex := 1 to RecRef.FieldCount() do begin
            CandidateField := RecRef.FieldIndex(FieldIndex);
            if UpperCase(CandidateField.Name()) = UpperCase(FieldName) then begin
                ResolvedField := CandidateField;
                exit(true);
            end;
        end;

        exit(false);
    end;

    [TryFunction]
    local procedure HasValue(Field: FieldRef)
    begin
        Field.TestField();
    end;
}
