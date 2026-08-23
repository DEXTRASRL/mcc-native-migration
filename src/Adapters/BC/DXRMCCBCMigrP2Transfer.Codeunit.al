codeunit 60096 "DXR MCC BC Migr P2 Transfer"
{
    // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 2".
    // CopyTransferControlsSetup() - see "DXR MCC BC Migr P2 Warehouse" for the full rationale.
    Permissions = tabledata "DXR_Transfer Ctrl Setup Old2" = R,
                  tabledata "DXR_Transfer Controls Setup" = RIM;

    trigger OnRun()
    var
        OldSetup: Record "DXR_Transfer Ctrl Setup Old2";
        NewSetup: Record "DXR_Transfer Controls Setup";
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
