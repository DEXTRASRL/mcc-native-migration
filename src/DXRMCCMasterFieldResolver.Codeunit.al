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

            if TryResolveFieldByName(RecRef, CandidateName, SourceField) and
               (SourceField.Class() = FieldClass::Normal) and
               (SourceField.Type() = TargetField.Type()) and
               HasValue(SourceField)
            then begin
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
