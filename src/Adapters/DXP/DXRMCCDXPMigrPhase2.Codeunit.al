#if not ESCUDEA and not BCDX
codeunit 60081 "DXR MCC DXP Migr Phase2"
{
    // Converted 2026-08-24: previously routed 38 field copies across 5 tables through a generic
    // RecordRef/FieldRef CopyTableFields helper (field names were already known via FieldNo() calls
    // - only the copy mechanism was untyped). Direct typed Record assignment, zero RecordRef.
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
    begin
        // Fixed 2026-08-27: added SetLoadFields (only the PK + the 2 fields this loop touches) so the
        // server stops joining every tableextension companion table of LSC Infocode for every row, and
        // added a bounded Commit so the loop is not one single unbounded transaction.
        Infocode.SetLoadFields("Code", "Refund Card_DXR", "DX Refund Card");
        if Infocode.FindSet(true) then begin
            repeat
                Infocode."Refund Card_DXR" := Infocode."DX Refund Card";
                Infocode.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until Infocode.Next() = 0;
            if RowsSinceCommit > 0 then
                Commit();
        end;
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
        RowsSinceCommit: Integer;
    begin
        // Fixed 2026-08-27: added SetLoadFields (PK + exactly the fields read/written below) to avoid
        // the per-row companion-table joins of every LSC POS Terminal tableextension, plus a bounded
        // Commit so the loop is not one single unbounded transaction.
        PosTerminal.SetLoadFields(
            "No.",
            "Uses VeriPhone_DXR", "DX Uses VeriPhone",
            Puerto_DXR, DXPuerto,
            Proveedor_DXR, DXProveedor,
            "Imprime Ticket_DXR", "DXImprime Ticket",
            "Puerto Secundario_DXR", "DXPuerto Secundario",
            "Direccion IP Secundaria_DXR", "DXDireccion IP Secundaria",
            "Direccion IP_DXR", "DXDireccion IP",
            "Puerto IP_DXR", "DXPuerto IP",
            "Numero Transaccion_DXR", "DXNumero Transaccion",
            "Numero Terminal_DXR", "DXNumero Terminal",
            "Merchant ID_DXR", "DXMerchant ID",
            RutaFirma_DXR, DXRutaFirma,
            Auth1_DXR, DXAuth1,
            Auth2_DXR, DXAuth2,
            IpString_DXR, DXIpString,
            Rpuerto_DXR, DXRpuerto,
            LocalIpString_DXR, DXLocalIpString,
            LPuerto_DXR, DXLPuerto,
            "Cierre Automatico_DXR", "DXCierre Automatico",
            "Visanet IpString_DXR", "DX Visanet IpString",
            "Visanet Puerto_DXR", "DX Visanet Puerto",
            URLEndPoint_DXR, DXURLEndPoint,
            "Use Amount In Currency_DXR", "DX Use Amount In Currency",
            "Local Currency Symbol_DXR", "DX Local Currency Symbol");
        if PosTerminal.FindSet(true) then begin
            repeat
                PosTerminal."Uses VeriPhone_DXR" := PosTerminal."DX Uses VeriPhone";
                // Cross-enum-type conversion: DXPuerto (enum "DX Port") → Puerto_DXR (enum DXR_Port)
                // Ordinal values verified identical before .AsInteger() conversion (Port: {0:COM1..9:COM10}).
                // WARNING: Do not copy this pattern to other fields without re-verifying both enums' ordinals match exactly.
                PosTerminal.Puerto_DXR := (PosTerminal.DXPuerto.AsInteger());
                // Cross-enum-type conversion: DXProveedor (enum "DX Provider") → Proveedor_DXR (enum DXR_Provider)
                // Ordinal values verified identical before .AsInteger() conversion (Provider: {0:" ",1:Azul,2:Cardnet,3:Visanet,4:"Azul Com"}).
                // WARNING: Do not copy this pattern to other fields without re-verifying both enums' ordinals match exactly.
                PosTerminal.Proveedor_DXR := (PosTerminal.DXProveedor.AsInteger());
                PosTerminal."Imprime Ticket_DXR" := PosTerminal."DXImprime Ticket";
                PosTerminal."Puerto Secundario_DXR" := PosTerminal."DXPuerto Secundario";
                PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."DXDireccion IP Secundaria";
                PosTerminal."Direccion IP_DXR" := PosTerminal."DXDireccion IP";
                PosTerminal."Puerto IP_DXR" := PosTerminal."DXPuerto IP";
                PosTerminal."Numero Transaccion_DXR" := PosTerminal."DXNumero Transaccion";
                PosTerminal."Numero Terminal_DXR" := PosTerminal."DXNumero Terminal";
                PosTerminal."Merchant ID_DXR" := PosTerminal."DXMerchant ID";
                PosTerminal.RutaFirma_DXR := PosTerminal.DXRutaFirma;
                PosTerminal.Auth1_DXR := PosTerminal.DXAuth1;
                PosTerminal.Auth2_DXR := PosTerminal.DXAuth2;
                PosTerminal.IpString_DXR := PosTerminal.DXIpString;
                PosTerminal.Rpuerto_DXR := PosTerminal.DXRpuerto;
                PosTerminal.LocalIpString_DXR := PosTerminal.DXLocalIpString;
                PosTerminal.LPuerto_DXR := PosTerminal.DXLPuerto;
                PosTerminal."Cierre Automatico_DXR" := PosTerminal."DXCierre Automatico";
                PosTerminal."Visanet IpString_DXR" := PosTerminal."DX Visanet IpString";
                PosTerminal."Visanet Puerto_DXR" := PosTerminal."DX Visanet Puerto";
                PosTerminal.URLEndPoint_DXR := PosTerminal.DXURLEndPoint;
                PosTerminal."Use Amount In Currency_DXR" := PosTerminal."DX Use Amount In Currency";
                PosTerminal."Local Currency Symbol_DXR" := PosTerminal."DX Local Currency Symbol";
                PosTerminal.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until PosTerminal.Next() = 0;
            if RowsSinceCommit > 0 then
                Commit();
        end;
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
        PosTransLineToUpdate: Record "LSC POS Trans. Line";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: this scanned the WHOLE LSC POS Trans. Line table with FindSet(true), i.e.
        // an UPDLOCK on every transaction line held for the entire run, while only a minority of rows
        // actually change. Now: SetLoadFields (PK + the 8 fields touched) + FindSet(false) (no UPDLOCK)
        // and the row is re-read with Get() and locked only when it really needs a copy; the commit
        // counter advances per MODIFIED row instead of per scanned row. Same fields, same guards.
        PosTransLine.SetLoadFields(
            "Receipt No.", "Line No.",
            "VP Approved_DXR", "DXVP Approved",
            "VP Authorization No._DXR", "DXVP Authorization No.",
            "VP Lot No._DXR", "DXVP Lot No.",
            "Cuota Quantity_DXR", "DXCuota Quantity");
        if PosTransLine.FindSet(false) then begin
            repeat
                RecordChanged :=
                    (PosTransLine."VP Approved_DXR" <> PosTransLine."DXVP Approved") or
                    (PosTransLine."VP Authorization No._DXR" <> PosTransLine."DXVP Authorization No.") or
                    (PosTransLine."VP Lot No._DXR" <> PosTransLine."DXVP Lot No.") or
                    (PosTransLine."Cuota Quantity_DXR" <> PosTransLine."DXCuota Quantity");
                if RecordChanged then
                    if PosTransLineToUpdate.Get(PosTransLine."Receipt No.", PosTransLine."Line No.") then begin
                        if PosTransLineToUpdate."VP Approved_DXR" <> PosTransLineToUpdate."DXVP Approved" then
                            PosTransLineToUpdate."VP Approved_DXR" := PosTransLineToUpdate."DXVP Approved";
                        if PosTransLineToUpdate."VP Authorization No._DXR" <> PosTransLineToUpdate."DXVP Authorization No." then
                            PosTransLineToUpdate."VP Authorization No._DXR" := PosTransLineToUpdate."DXVP Authorization No.";
                        if PosTransLineToUpdate."VP Lot No._DXR" <> PosTransLineToUpdate."DXVP Lot No." then
                            PosTransLineToUpdate."VP Lot No._DXR" := PosTransLineToUpdate."DXVP Lot No.";
                        if PosTransLineToUpdate."Cuota Quantity_DXR" <> PosTransLineToUpdate."DXCuota Quantity" then
                            PosTransLineToUpdate."Cuota Quantity_DXR" := PosTransLineToUpdate."DXCuota Quantity";
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
        RowsSinceCommit: Integer;
    begin
        // Fixed 2026-08-27: added SetLoadFields (PK + exactly the fields read/written below) to avoid
        // the per-row companion-table joins of every LSC Tender Type tableextension, plus a bounded
        // Commit so the loop is not one single unbounded transaction.
        TenderType.SetLoadFields(
            "Store No.", "Code",
            "ReqVeriphoneProcessing_DXR", "DXRequiredVeriphoneProcessing",
            tPayment_DXR, DXtPayment,
            "Cuota Payment_DXR", "DXCuota Payment",
            "Use Form For Cuotas_DXR", "DXUse Form For Cuotas",
            "InfoCode For Cuotas_DXR", "DXInfoCode For Cuotas");
        if TenderType.FindSet(true) then begin
            repeat
                TenderType."ReqVeriphoneProcessing_DXR" := TenderType."DXRequiredVeriphoneProcessing";
                TenderType.tPayment_DXR := TenderType.DXtPayment;
                TenderType."Cuota Payment_DXR" := TenderType."DXCuota Payment";
                TenderType."Use Form For Cuotas_DXR" := TenderType."DXUse Form For Cuotas";
                TenderType."InfoCode For Cuotas_DXR" := TenderType."DXInfoCode For Cuotas";
                TenderType.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until TenderType.Next() = 0;
            if RowsSinceCommit > 0 then
                Commit();
        end;
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        TransPaymentEntryToUpdate: Record "LSC Trans. Payment Entry";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        // Fixed 2026-08-27: same fix as CopyPOSTransLineFields - FindSet(true) took an UPDLOCK on the
        // entire LSC Trans. Payment Entry table for the whole run even though only a minority of rows
        // change. Read without the lock (SetLoadFields + FindSet(false)) and lock only the rows that
        // really need a copy via Get(); commit counter per MODIFIED row.
        TransPaymentEntry.SetLoadFields(
            "Store No.", "POS Terminal No.", "Transaction No.", "Line No.",
            "VP Approved_DXR", "DXVP Approved",
            "VP Authorization No._DXR", "DXVP Authorization No.",
            "VP Lot No._DXR", "DXVP Lot No.",
            "Cuota Quantity_DXR", "DXCuota Quantity");
        if TransPaymentEntry.FindSet(false) then begin
            repeat
                RecordChanged :=
                    (TransPaymentEntry."VP Approved_DXR" <> TransPaymentEntry."DXVP Approved") or
                    (TransPaymentEntry."VP Authorization No._DXR" <> TransPaymentEntry."DXVP Authorization No.") or
                    (TransPaymentEntry."VP Lot No._DXR" <> TransPaymentEntry."DXVP Lot No.") or
                    (TransPaymentEntry."Cuota Quantity_DXR" <> TransPaymentEntry."DXCuota Quantity");
                if RecordChanged then
                    if TransPaymentEntryToUpdate.Get(
                        TransPaymentEntry."Store No.", TransPaymentEntry."POS Terminal No.",
                        TransPaymentEntry."Transaction No.", TransPaymentEntry."Line No.")
                    then begin
                        if TransPaymentEntryToUpdate."VP Approved_DXR" <> TransPaymentEntryToUpdate."DXVP Approved" then
                            TransPaymentEntryToUpdate."VP Approved_DXR" := TransPaymentEntryToUpdate."DXVP Approved";
                        if TransPaymentEntryToUpdate."VP Authorization No._DXR" <> TransPaymentEntryToUpdate."DXVP Authorization No." then
                            TransPaymentEntryToUpdate."VP Authorization No._DXR" := TransPaymentEntryToUpdate."DXVP Authorization No.";
                        if TransPaymentEntryToUpdate."VP Lot No._DXR" <> TransPaymentEntryToUpdate."DXVP Lot No." then
                            TransPaymentEntryToUpdate."VP Lot No._DXR" := TransPaymentEntryToUpdate."DXVP Lot No.";
                        if TransPaymentEntryToUpdate."Cuota Quantity_DXR" <> TransPaymentEntryToUpdate."DXCuota Quantity" then
                            TransPaymentEntryToUpdate."Cuota Quantity_DXR" := TransPaymentEntryToUpdate."DXCuota Quantity";
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
