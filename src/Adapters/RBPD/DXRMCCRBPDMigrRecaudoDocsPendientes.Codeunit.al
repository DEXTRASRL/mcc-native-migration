#if not ESCUDEA and not BCDX
codeunit 60111 "DXR MCC RBPD Migr DocsPend"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateRecaudoDocsPendientes().
    Permissions = tabledata "DXR-IB Recaudo Docs Pendientes" = R,
                  tabledata "DXR_Recaudo Docs Pendientes" = RIM;

    // Fixed 2026-08-27: the loop had no Commit at all, so a whole-table restore ran as ONE
    // unbounded transaction. Bounded to 500 INSERTED rows; safe because every insert is already
    // guarded by "if not NewRec.Get(...)", so a re-run after a partial commit skips what exists.
    trigger OnRun()
    var
        OldRec: Record "DXR-IB Recaudo Docs Pendientes";
        NewRec: Record "DXR_Recaudo Docs Pendientes";
        RowsSinceCommit: Integer;
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."id DXR-IB") then begin
                    NewRec.Init();
                    NewRec."id DXR-IB" := OldRec."id DXR-IB";
                    NewRec."Numeroreferencia DXR-IB" := OldRec."Numeroreferencia DXR-IB";
                    NewRec."Fecha DXR-IB" := OldRec."Fecha DXR-IB";
                    NewRec."Valorpagado DXR-IB" := OldRec."Valorpagado DXR-IB";
                    NewRec."Idtransaccionbanco DXR-IB" := OldRec."Idtransaccionbanco DXR-IB";
                    NewRec."Numeroautorizacion DXR-IB" := OldRec."Numeroautorizacion DXR-IB";
                    NewRec.Insert(true);

                    RowsSinceCommit += 1;
                    if RowsSinceCommit >= 500 then begin
                        Commit();
                        RowsSinceCommit := 0;
                    end;
                end;
            until OldRec.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;
}

#endif
