#if not ESCUDEA and not BCDX
codeunit 60078 "DXR MCC SD Migr LSCStore"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyLSCStorePrintHeaderDoc() (field 59000->54747 on its
    // own "DXR_Store Ext" table extension). Both fields are the same Option type with identical
    // OptionMembers order (Documentos,Usuarios), confirmed by reading both field declarations
    // directly - a plain typed assignment is safe (no re-mapping needed).
    Permissions = tabledata "LSC Store" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer" - "LSC Store" is small but is read constantly by every POS
    // terminal, so an UPDLOCK over all of it for the whole run is the worst place to take one.
    trigger OnRun()
    var
        LSCStore: Record "LSC Store";
        LSCStoreToUpdate: Record "LSC Store";
        Blank: Record "LSC Store";
    begin
        LSCStore.SetLoadFields("No.", "Print Header Doc._DXR", "PE Print Header Doc. DXR");
        if not LSCStore.FindSet(false) then
            exit;
        repeat
            if LSCStore."Print Header Doc._DXR" <> LSCStore."PE Print Header Doc. DXR" then
                if LSCStoreToUpdate.Get(LSCStore."No.") then begin
                    // Fixed 2026-08-27 (never-overwrite): the dirty-check above only avoids a no-op
                    // write - it does not stop a re-run from overwriting an already-populated _DXR
                    // value with the legacy one.
                    if LSCStoreToUpdate."Print Header Doc._DXR" = Blank."Print Header Doc._DXR" then
                        LSCStoreToUpdate."Print Header Doc._DXR" := LSCStoreToUpdate."PE Print Header Doc. DXR";
                    LSCStoreToUpdate.Modify(false);
                end;
        until LSCStore.Next() = 0;
    end;
}

#endif
