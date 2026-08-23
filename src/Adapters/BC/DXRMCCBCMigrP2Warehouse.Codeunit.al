codeunit 60092 "DXR MCC BC Migr P2 Warehouse"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopyWarehouseControlsSetup(): restores from the *Old2 snapshot (newer generation than
    // Phase 1's source), skipping when Old2's row is blank/default (2026-08-22 fix, preserves
    // real data Phase 1 may already have written) and overwriting the active row when Old2 has
    // real configuration - Old2 is a frozen legacy snapshot, so this stays idempotent in effect
    // even though it re-Modifies on every run.
    Permissions = tabledata "DXR_Warehouse Ctrl Setup Old2" = R,
                  tabledata "DXR_Warehouse Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Warehouse Ctrl Setup Old2";
        NewSetup: Record "DXR_Warehouse Controls Setup";
        OldRecRef: RecordRef;
    begin
        if not OldSetup.Get('') then
            exit;
        OldRecRef.GetTable(OldSetup);
        if IsSetupRowBlank(OldRecRef) then
            exit;

        if NewSetup.Get('') then begin
            NewSetup.TransferFields(OldSetup, true);
            NewSetup.Modify(false);
        end else begin
            NewSetup.TransferFields(OldSetup, true);
            NewSetup.Insert(false);
        end;
    end;

    local procedure IsSetupRowBlank(var RecRef: RecordRef): Boolean
    var
        BlankRecRef: RecordRef;
        FieldRef: FieldRef;
        BlankFieldRef: FieldRef;
        KeyRef: KeyRef;
        FieldIndex: Integer;
        KeyFieldIndex: Integer;
        IsKeyField: Boolean;
    begin
        BlankRecRef.Open(RecRef.Number);
        BlankRecRef.Init();
        KeyRef := RecRef.KeyIndex(1);

        for FieldIndex := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if FieldRef.Class <> FieldClass::Normal then
                continue;

            IsKeyField := false;
            for KeyFieldIndex := 1 to KeyRef.FieldCount do
                if KeyRef.FieldIndex(KeyFieldIndex).Number = FieldRef.Number then
                    IsKeyField := true;
            if IsKeyField then
                continue;

            BlankFieldRef := BlankRecRef.Field(FieldRef.Number);
            if Format(FieldRef.Value) <> Format(BlankFieldRef.Value) then begin
                BlankRecRef.Close();
                exit(false);
            end;
        end;

        BlankRecRef.Close();
        exit(true);
    end;
}
