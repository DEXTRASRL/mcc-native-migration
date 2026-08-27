#if not ESCUDEA and not BCDX
codeunit 60085 "DXR MCC DXP Migr Phase6"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase6_Fields"
    // - copies the 41 renumbered-generation duplicated fields (the "..._Old" renamed field ->
    // current field, same 5 LS Central tableextensions Phase 2 also touches) via direct typed
    // field assignments (DXP-P6 concepts, seq 10/39-42).
    Permissions = tabledata "LSC Infocode" = RM,
                  tabledata "LSC POS Terminal" = RM,
                  tabledata "LSC POS Trans. Line" = RM,
                  tabledata "LSC Tender Type" = RM,
                  tabledata "LSC Trans. Payment Entry" = RM;

    trigger OnRun()
    begin
        RunSetup();
        RunAccounting();
    end;

    procedure RunSetup()
    begin
        CopyInfocodeFields();
        CopyPOSTerminalFields();
        CopyTenderTypeFields();
    end;

    procedure RunMaster()
    begin
    end;

    procedure RunAccounting()
    begin
        CopyPOSTransLineFields();
        CopyTransPaymentEntryFields();
    end;

    local procedure CopyInfocodeFields()
    var
        Infocode: Record "LSC Infocode";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: added SetLoadFields (PK + exactly the 2 fields this loop reads/writes) so
        // the server stops joining every LSC Infocode tableextension companion table for every row.
        Infocode.SetLoadFields("Code", "Refund Card_DXR", "Refund Card_Old");
        if Infocode.FindSet(true) then
            repeat
                RecordChanged := false;
                if Infocode."Refund Card_DXR" <> Infocode."Refund Card_Old" then begin
                    Infocode."Refund Card_DXR" := Infocode."Refund Card_Old";
                    RecordChanged := true;
                end;
                if RecordChanged then
                    Infocode.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until Infocode.Next() = 0;
        Commit();
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
        Blank: Record "LSC POS Terminal";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: added SetLoadFields (PK + exactly the fields read/written below) so the
        // server stops joining every LSC POS Terminal tableextension companion table for every row.
        PosTerminal.SetLoadFields(
            "No.",
            "Uses VeriPhone_DXR", "Uses VeriPhone_Old",
            Puerto_DXR, Puerto_Old,
            Proveedor_DXR, Proveedor_Old,
            "Imprime Ticket_DXR", "Imprime Ticket_Old",
            "Puerto Secundario_DXR", "Puerto Secundario_Old",
            "Direccion IP Secundaria_DXR", "Direccion IP Secundaria_Old",
            "Direccion IP_DXR", "Direccion IP_Old",
            "Puerto IP_DXR", "Puerto IP_Old",
            "Numero Transaccion_DXR", "Numero Transaccion_Old",
            "Numero Terminal_DXR", "Numero Terminal_Old",
            "Merchant ID_DXR", "Merchant ID_Old",
            RutaFirma_DXR, RutaFirma_Old,
            Auth1_DXR, Auth1_Old,
            Auth2_DXR, Auth2_Old,
            IpString_DXR, IpString_Old,
            Rpuerto_DXR, Rpuerto_Old,
            LocalIpString_DXR, LocalIpString_Old,
            LPuerto_DXR, LPuerto_Old,
            "Cierre Automatico_DXR", "Cierre Automatico_Old",
            "Visanet IpString_DXR", "Visanet IpString_Old",
            "Visanet Puerto_DXR", "Visanet Puerto_Old",
            URLEndPoint_DXR, URLEndPoint_Old,
            "Use Amount In Currency_DXR", "Use Amount In Currency_Old",
            "Local Currency Symbol_DXR", "Local Currency Symbol_Old");
        if PosTerminal.FindSet(true) then
            repeat
                RecordChanged := false;
                // Fixed 2026-08-27 (never-overwrite): each guard below used to compare against the
                // "_Old" source field (<>), which only skips a no-op write - it does not stop a
                // re-run from overwriting an already-populated _DXR value with the "_Old" one. Now
                // fill-only-if-blank, same as the rest of this portfolio's tableextension migrations.
                if PosTerminal."Uses VeriPhone_DXR" = Blank."Uses VeriPhone_DXR" then begin
                    PosTerminal."Uses VeriPhone_DXR" := PosTerminal."Uses VeriPhone_Old";
                    RecordChanged := true;
                end;
                if PosTerminal.Puerto_DXR = Blank.Puerto_DXR then begin
                    PosTerminal.Puerto_DXR := PosTerminal.Puerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Proveedor_DXR = Blank.Proveedor_DXR then begin
                    PosTerminal.Proveedor_DXR := PosTerminal.Proveedor_Old;
                    RecordChanged := true;
                end;
                if PosTerminal."Imprime Ticket_DXR" = Blank."Imprime Ticket_DXR" then begin
                    PosTerminal."Imprime Ticket_DXR" := PosTerminal."Imprime Ticket_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Puerto Secundario_DXR" = Blank."Puerto Secundario_DXR" then begin
                    PosTerminal."Puerto Secundario_DXR" := PosTerminal."Puerto Secundario_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Direccion IP Secundaria_DXR" = Blank."Direccion IP Secundaria_DXR" then begin
                    PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."Direccion IP Secundaria_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Direccion IP_DXR" = Blank."Direccion IP_DXR" then begin
                    PosTerminal."Direccion IP_DXR" := PosTerminal."Direccion IP_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Puerto IP_DXR" = Blank."Puerto IP_DXR" then begin
                    PosTerminal."Puerto IP_DXR" := PosTerminal."Puerto IP_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Numero Transaccion_DXR" = Blank."Numero Transaccion_DXR" then begin
                    PosTerminal."Numero Transaccion_DXR" := PosTerminal."Numero Transaccion_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Numero Terminal_DXR" = Blank."Numero Terminal_DXR" then begin
                    PosTerminal."Numero Terminal_DXR" := PosTerminal."Numero Terminal_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Merchant ID_DXR" = Blank."Merchant ID_DXR" then begin
                    PosTerminal."Merchant ID_DXR" := PosTerminal."Merchant ID_Old";
                    RecordChanged := true;
                end;
                if PosTerminal.RutaFirma_DXR = Blank.RutaFirma_DXR then begin
                    PosTerminal.RutaFirma_DXR := PosTerminal.RutaFirma_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Auth1_DXR = Blank.Auth1_DXR then begin
                    PosTerminal.Auth1_DXR := PosTerminal.Auth1_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Auth2_DXR = Blank.Auth2_DXR then begin
                    PosTerminal.Auth2_DXR := PosTerminal.Auth2_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.IpString_DXR = Blank.IpString_DXR then begin
                    PosTerminal.IpString_DXR := PosTerminal.IpString_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Rpuerto_DXR = Blank.Rpuerto_DXR then begin
                    PosTerminal.Rpuerto_DXR := PosTerminal.Rpuerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.LocalIpString_DXR = Blank.LocalIpString_DXR then begin
                    PosTerminal.LocalIpString_DXR := PosTerminal.LocalIpString_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.LPuerto_DXR = Blank.LPuerto_DXR then begin
                    PosTerminal.LPuerto_DXR := PosTerminal.LPuerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal."Cierre Automatico_DXR" = Blank."Cierre Automatico_DXR" then begin
                    PosTerminal."Cierre Automatico_DXR" := PosTerminal."Cierre Automatico_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Visanet IpString_DXR" = Blank."Visanet IpString_DXR" then begin
                    PosTerminal."Visanet IpString_DXR" := PosTerminal."Visanet IpString_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Visanet Puerto_DXR" = Blank."Visanet Puerto_DXR" then begin
                    PosTerminal."Visanet Puerto_DXR" := PosTerminal."Visanet Puerto_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."URLEndPoint_DXR" = Blank."URLEndPoint_DXR" then begin
                    PosTerminal."URLEndPoint_DXR" := PosTerminal."URLEndPoint_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Use Amount In Currency_DXR" = Blank."Use Amount In Currency_DXR" then begin
                    PosTerminal."Use Amount In Currency_DXR" := PosTerminal."Use Amount In Currency_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Local Currency Symbol_DXR" = Blank."Local Currency Symbol_DXR" then begin
                    PosTerminal."Local Currency Symbol_DXR" := PosTerminal."Local Currency Symbol_Old";
                    RecordChanged := true;
                end;
                if RecordChanged then
                    PosTerminal.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until PosTerminal.Next() = 0;
        Commit();
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
        PosTransLineToUpdate: Record "LSC POS Trans. Line";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: FindSet(true) over the WHOLE LSC POS Trans. Line table took an UPDLOCK on
        // every transaction line for the entire run while only a minority of rows change. Now reads
        // without the lock (SetLoadFields + FindSet(false)) and locks a row via Get() only when it
        // really needs a copy; the commit counter advances per MODIFIED row. Same fields, same guards.
        PosTransLine.SetLoadFields(
            "Receipt No.", "Line No.",
            "VP Approved_DXR", "VP Approved_Old",
            "VP Authorization No._DXR", "VP Authorization No._Old",
            "VP Lot No._DXR", "VP Lot No._Old",
            "Cuota Quantity_DXR", "Cuota Quantity_Old");
        if PosTransLine.FindSet(false) then begin
            repeat
                RecordChanged :=
                    (PosTransLine."VP Approved_DXR" <> PosTransLine."VP Approved_Old") or
                    (PosTransLine."VP Authorization No._DXR" <> PosTransLine."VP Authorization No._Old") or
                    (PosTransLine."VP Lot No._DXR" <> PosTransLine."VP Lot No._Old") or
                    (PosTransLine."Cuota Quantity_DXR" <> PosTransLine."Cuota Quantity_Old");
                if RecordChanged then
                    if PosTransLineToUpdate.Get(PosTransLine."Receipt No.", PosTransLine."Line No.") then begin
                        if PosTransLineToUpdate."VP Approved_DXR" <> PosTransLineToUpdate."VP Approved_Old" then
                            PosTransLineToUpdate."VP Approved_DXR" := PosTransLineToUpdate."VP Approved_Old";
                        if PosTransLineToUpdate."VP Authorization No._DXR" <> PosTransLineToUpdate."VP Authorization No._Old" then
                            PosTransLineToUpdate."VP Authorization No._DXR" := PosTransLineToUpdate."VP Authorization No._Old";
                        if PosTransLineToUpdate."VP Lot No._DXR" <> PosTransLineToUpdate."VP Lot No._Old" then
                            PosTransLineToUpdate."VP Lot No._DXR" := PosTransLineToUpdate."VP Lot No._Old";
                        if PosTransLineToUpdate."Cuota Quantity_DXR" <> PosTransLineToUpdate."Cuota Quantity_Old" then
                            PosTransLineToUpdate."Cuota Quantity_DXR" := PosTransLineToUpdate."Cuota Quantity_Old";
                        PosTransLineToUpdate.Modify(false);

                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
            until PosTransLine.Next() = 0;
            if RowsSinceCommit > 0 then
                Commit();
        end;
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
        Blank: Record "LSC Tender Type";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: added SetLoadFields (PK + exactly the fields read/written below) so the
        // server stops joining every LSC Tender Type tableextension companion table for every row.
        TenderType.SetLoadFields(
            "Store No.", "Code",
            "ReqVeriphoneProcessing_DXR", "ReqVeriphoneProcessing_Old",
            tPayment_DXR, tPayment_Old,
            "Cuota Payment_DXR", "Cuota Payment_Old",
            "Use Form For Cuotas_DXR", "Use Form For Cuotas_Old",
            "InfoCode For Cuotas_DXR", "InfoCode For Cuotas_Old");
        if TenderType.FindSet(true) then
            repeat
                RecordChanged := false;
                // Fixed 2026-08-27 (never-overwrite): each guard below used to compare against the
                // "_Old" source field (<>), which only skips a no-op write - it does not stop a
                // re-run from overwriting an already-populated _DXR value with the "_Old" one. Now
                // fill-only-if-blank, same as the rest of this portfolio's tableextension migrations.
                if TenderType."ReqVeriphoneProcessing_DXR" = Blank."ReqVeriphoneProcessing_DXR" then begin
                    TenderType."ReqVeriphoneProcessing_DXR" := TenderType."ReqVeriphoneProcessing_Old";
                    RecordChanged := true;
                end;
                if TenderType.tPayment_DXR = Blank.tPayment_DXR then begin
                    TenderType.tPayment_DXR := TenderType.tPayment_Old;
                    RecordChanged := true;
                end;
                if TenderType."Cuota Payment_DXR" = Blank."Cuota Payment_DXR" then begin
                    TenderType."Cuota Payment_DXR" := TenderType."Cuota Payment_Old";
                    RecordChanged := true;
                end;
                if TenderType."Use Form For Cuotas_DXR" = Blank."Use Form For Cuotas_DXR" then begin
                    TenderType."Use Form For Cuotas_DXR" := TenderType."Use Form For Cuotas_Old";
                    RecordChanged := true;
                end;
                if TenderType."InfoCode For Cuotas_DXR" = Blank."InfoCode For Cuotas_DXR" then begin
                    TenderType."InfoCode For Cuotas_DXR" := TenderType."InfoCode For Cuotas_Old";
                    RecordChanged := true;
                end;
                if RecordChanged then
                    TenderType.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until TenderType.Next() = 0;
        Commit();
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        TransPaymentEntryToUpdate: Record "LSC Trans. Payment Entry";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: same fix as CopyPOSTransLineFields - FindSet(true) took an UPDLOCK on the
        // whole LSC Trans. Payment Entry table for the entire run. Read without the lock
        // (SetLoadFields + FindSet(false)) and lock only the rows that really need a copy via Get();
        // the commit counter advances per MODIFIED row.
        TransPaymentEntry.SetLoadFields(
            "Store No.", "POS Terminal No.", "Transaction No.", "Line No.",
            "VP Approved_DXR", "VP Approved_Old",
            "VP Authorization No._DXR", "VP Authorization No._Old",
            "VP Lot No._DXR", "VP Lot No._Old",
            "Cuota Quantity_DXR", "Cuota Quantity_Old");
        if TransPaymentEntry.FindSet(false) then begin
            repeat
                RecordChanged :=
                    (TransPaymentEntry."VP Approved_DXR" <> TransPaymentEntry."VP Approved_Old") or
                    (TransPaymentEntry."VP Authorization No._DXR" <> TransPaymentEntry."VP Authorization No._Old") or
                    (TransPaymentEntry."VP Lot No._DXR" <> TransPaymentEntry."VP Lot No._Old") or
                    (TransPaymentEntry."Cuota Quantity_DXR" <> TransPaymentEntry."Cuota Quantity_Old");
                if RecordChanged then
                    if TransPaymentEntryToUpdate.Get(
                        TransPaymentEntry."Store No.", TransPaymentEntry."POS Terminal No.",
                        TransPaymentEntry."Transaction No.", TransPaymentEntry."Line No.")
                    then begin
                        if TransPaymentEntryToUpdate."VP Approved_DXR" <> TransPaymentEntryToUpdate."VP Approved_Old" then
                            TransPaymentEntryToUpdate."VP Approved_DXR" := TransPaymentEntryToUpdate."VP Approved_Old";
                        if TransPaymentEntryToUpdate."VP Authorization No._DXR" <> TransPaymentEntryToUpdate."VP Authorization No._Old" then
                            TransPaymentEntryToUpdate."VP Authorization No._DXR" := TransPaymentEntryToUpdate."VP Authorization No._Old";
                        if TransPaymentEntryToUpdate."VP Lot No._DXR" <> TransPaymentEntryToUpdate."VP Lot No._Old" then
                            TransPaymentEntryToUpdate."VP Lot No._DXR" := TransPaymentEntryToUpdate."VP Lot No._Old";
                        if TransPaymentEntryToUpdate."Cuota Quantity_DXR" <> TransPaymentEntryToUpdate."Cuota Quantity_Old" then
                            TransPaymentEntryToUpdate."Cuota Quantity_DXR" := TransPaymentEntryToUpdate."Cuota Quantity_Old";
                        TransPaymentEntryToUpdate.Modify(false);

                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
            until TransPaymentEntry.Next() = 0;
            if RowsSinceCommit > 0 then
                Commit();
        end;
    end;
}

#endif
