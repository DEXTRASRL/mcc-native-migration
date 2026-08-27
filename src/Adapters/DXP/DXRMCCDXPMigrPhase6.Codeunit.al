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
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        if PosTerminal.FindSet(true) then
            repeat
                RecordChanged := false;
                if PosTerminal."Uses VeriPhone_DXR" <> PosTerminal."Uses VeriPhone_Old" then begin
                    PosTerminal."Uses VeriPhone_DXR" := PosTerminal."Uses VeriPhone_Old";
                    RecordChanged := true;
                end;
                if PosTerminal.Puerto_DXR <> PosTerminal.Puerto_Old then begin
                    PosTerminal.Puerto_DXR := PosTerminal.Puerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Proveedor_DXR <> PosTerminal.Proveedor_Old then begin
                    PosTerminal.Proveedor_DXR := PosTerminal.Proveedor_Old;
                    RecordChanged := true;
                end;
                if PosTerminal."Imprime Ticket_DXR" <> PosTerminal."Imprime Ticket_Old" then begin
                    PosTerminal."Imprime Ticket_DXR" := PosTerminal."Imprime Ticket_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Puerto Secundario_DXR" <> PosTerminal."Puerto Secundario_Old" then begin
                    PosTerminal."Puerto Secundario_DXR" := PosTerminal."Puerto Secundario_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Direccion IP Secundaria_DXR" <> PosTerminal."Direccion IP Secundaria_Old" then begin
                    PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."Direccion IP Secundaria_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Direccion IP_DXR" <> PosTerminal."Direccion IP_Old" then begin
                    PosTerminal."Direccion IP_DXR" := PosTerminal."Direccion IP_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Puerto IP_DXR" <> PosTerminal."Puerto IP_Old" then begin
                    PosTerminal."Puerto IP_DXR" := PosTerminal."Puerto IP_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Numero Transaccion_DXR" <> PosTerminal."Numero Transaccion_Old" then begin
                    PosTerminal."Numero Transaccion_DXR" := PosTerminal."Numero Transaccion_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Numero Terminal_DXR" <> PosTerminal."Numero Terminal_Old" then begin
                    PosTerminal."Numero Terminal_DXR" := PosTerminal."Numero Terminal_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Merchant ID_DXR" <> PosTerminal."Merchant ID_Old" then begin
                    PosTerminal."Merchant ID_DXR" := PosTerminal."Merchant ID_Old";
                    RecordChanged := true;
                end;
                if PosTerminal.RutaFirma_DXR <> PosTerminal.RutaFirma_Old then begin
                    PosTerminal.RutaFirma_DXR := PosTerminal.RutaFirma_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Auth1_DXR <> PosTerminal.Auth1_Old then begin
                    PosTerminal.Auth1_DXR := PosTerminal.Auth1_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Auth2_DXR <> PosTerminal.Auth2_Old then begin
                    PosTerminal.Auth2_DXR := PosTerminal.Auth2_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.IpString_DXR <> PosTerminal.IpString_Old then begin
                    PosTerminal.IpString_DXR := PosTerminal.IpString_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.Rpuerto_DXR <> PosTerminal.Rpuerto_Old then begin
                    PosTerminal.Rpuerto_DXR := PosTerminal.Rpuerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.LocalIpString_DXR <> PosTerminal.LocalIpString_Old then begin
                    PosTerminal.LocalIpString_DXR := PosTerminal.LocalIpString_Old;
                    RecordChanged := true;
                end;
                if PosTerminal.LPuerto_DXR <> PosTerminal.LPuerto_Old then begin
                    PosTerminal.LPuerto_DXR := PosTerminal.LPuerto_Old;
                    RecordChanged := true;
                end;
                if PosTerminal."Cierre Automatico_DXR" <> PosTerminal."Cierre Automatico_Old" then begin
                    PosTerminal."Cierre Automatico_DXR" := PosTerminal."Cierre Automatico_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Visanet IpString_DXR" <> PosTerminal."Visanet IpString_Old" then begin
                    PosTerminal."Visanet IpString_DXR" := PosTerminal."Visanet IpString_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Visanet Puerto_DXR" <> PosTerminal."Visanet Puerto_Old" then begin
                    PosTerminal."Visanet Puerto_DXR" := PosTerminal."Visanet Puerto_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."URLEndPoint_DXR" <> PosTerminal."URLEndPoint_Old" then begin
                    PosTerminal."URLEndPoint_DXR" := PosTerminal."URLEndPoint_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Use Amount In Currency_DXR" <> PosTerminal."Use Amount In Currency_Old" then begin
                    PosTerminal."Use Amount In Currency_DXR" := PosTerminal."Use Amount In Currency_Old";
                    RecordChanged := true;
                end;
                if PosTerminal."Local Currency Symbol_DXR" <> PosTerminal."Local Currency Symbol_Old" then begin
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
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        if PosTransLine.FindSet(true) then
            repeat
                RecordChanged := false;
                if PosTransLine."VP Approved_DXR" <> PosTransLine."VP Approved_Old" then begin
                    PosTransLine."VP Approved_DXR" := PosTransLine."VP Approved_Old";
                    RecordChanged := true;
                end;
                if PosTransLine."VP Authorization No._DXR" <> PosTransLine."VP Authorization No._Old" then begin
                    PosTransLine."VP Authorization No._DXR" := PosTransLine."VP Authorization No._Old";
                    RecordChanged := true;
                end;
                if PosTransLine."VP Lot No._DXR" <> PosTransLine."VP Lot No._Old" then begin
                    PosTransLine."VP Lot No._DXR" := PosTransLine."VP Lot No._Old";
                    RecordChanged := true;
                end;
                if PosTransLine."Cuota Quantity_DXR" <> PosTransLine."Cuota Quantity_Old" then begin
                    PosTransLine."Cuota Quantity_DXR" := PosTransLine."Cuota Quantity_Old";
                    RecordChanged := true;
                end;
                if RecordChanged then
                    PosTransLine.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until PosTransLine.Next() = 0;
        Commit();
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        if TenderType.FindSet(true) then
            repeat
                RecordChanged := false;
                if TenderType."ReqVeriphoneProcessing_DXR" <> TenderType."ReqVeriphoneProcessing_Old" then begin
                    TenderType."ReqVeriphoneProcessing_DXR" := TenderType."ReqVeriphoneProcessing_Old";
                    RecordChanged := true;
                end;
                if TenderType.tPayment_DXR <> TenderType.tPayment_Old then begin
                    TenderType.tPayment_DXR := TenderType.tPayment_Old;
                    RecordChanged := true;
                end;
                if TenderType."Cuota Payment_DXR" <> TenderType."Cuota Payment_Old" then begin
                    TenderType."Cuota Payment_DXR" := TenderType."Cuota Payment_Old";
                    RecordChanged := true;
                end;
                if TenderType."Use Form For Cuotas_DXR" <> TenderType."Use Form For Cuotas_Old" then begin
                    TenderType."Use Form For Cuotas_DXR" := TenderType."Use Form For Cuotas_Old";
                    RecordChanged := true;
                end;
                if TenderType."InfoCode For Cuotas_DXR" <> TenderType."InfoCode For Cuotas_Old" then begin
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
        RowsSinceCommit: Integer;
        RecordChanged: Boolean;
    begin
        if TransPaymentEntry.FindSet(true) then
            repeat
                RecordChanged := false;
                if TransPaymentEntry."VP Approved_DXR" <> TransPaymentEntry."VP Approved_Old" then begin
                    TransPaymentEntry."VP Approved_DXR" := TransPaymentEntry."VP Approved_Old";
                    RecordChanged := true;
                end;
                if TransPaymentEntry."VP Authorization No._DXR" <> TransPaymentEntry."VP Authorization No._Old" then begin
                    TransPaymentEntry."VP Authorization No._DXR" := TransPaymentEntry."VP Authorization No._Old";
                    RecordChanged := true;
                end;
                if TransPaymentEntry."VP Lot No._DXR" <> TransPaymentEntry."VP Lot No._Old" then begin
                    TransPaymentEntry."VP Lot No._DXR" := TransPaymentEntry."VP Lot No._Old";
                    RecordChanged := true;
                end;
                if TransPaymentEntry."Cuota Quantity_DXR" <> TransPaymentEntry."Cuota Quantity_Old" then begin
                    TransPaymentEntry."Cuota Quantity_DXR" := TransPaymentEntry."Cuota Quantity_Old";
                    RecordChanged := true;
                end;
                if RecordChanged then
                    TransPaymentEntry.Modify(false);
                RowsSinceCommit += 1;
                if RowsSinceCommit >= 500 then begin
                    Commit();
                    RowsSinceCommit := 0;
                end;
            until TransPaymentEntry.Next() = 0;
        Commit();
    end;
}

#endif
