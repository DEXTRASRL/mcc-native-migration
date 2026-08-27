#if not ESCUDEA and not BCDX
codeunit 60070 "DXR MCC SD Migr Customer"
{
    // Native local migration (2026-08-23, per user directive to stop delegating via .Run() and
    // instead have MCC perform the actual field copy itself): ported from Special Dispatch's own
    // "DXR_SD_Migr_Phase1_FieldDup".CopyCustomerSpecialDispatch(), which used generic
    // RecordRef/FieldRef reflection over field numbers 59000/54747. Written here as typed Record
    // field access instead - the field names ("Special Dispatch DXR"/"Special Dispatch_DXR") are
    // real, compiled fields on Special Dispatch's own "DXR_Customer Ext" (59000) table extension,
    // visible here because Special Dispatch is a real app.json dependency of MCC.
    Permissions = tabledata Customer = RM;

    // Fixed 2026-08-27 (Task 3, motor por tabla): el cuerpo de este trigger se movio a
    // "DXR MCC Master Customer" (60450).ApplySD() - ese codeunit hace un solo recorrido de
    // Customer para los 6 bloques que si migraron (BELLON, BC, DESB, DRLOC, PCM, SD) en vez de
    // uno por extension. No-op deliberado, no se borra: RunPortfolio/RunConcept siguen invocando
    // este codeunit por su ID (60070) via Codeunit.Run.
    trigger OnRun()
    begin
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;
}

#endif
