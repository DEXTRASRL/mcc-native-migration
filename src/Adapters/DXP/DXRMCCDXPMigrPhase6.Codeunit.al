
codeunit 60085 "DXR MCC DXP Migr Phase6"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase6_Fields"
    // - copies the 41 renumbered-generation duplicated fields (the "..." renamed field ->
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
    begin
        if Infocode.FindSet(true) then
            repeat
                Infocode."Refund Card_DXR" := Infocode."DX Refund Card";
                Infocode.Modify(false);
            until Infocode.Next() = 0;
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
    begin
        if PosTerminal.FindSet(true) then
            repeat
                PosTerminal."Uses VeriPhone_DXR" := PosTerminal."DX Uses VeriPhone";
                //PosTerminal.Puerto_DXR := PosTerminal.DXPuerto;
                PosTerminal.Proveedor_DXR := PosTerminal.DXProveedor;
                PosTerminal."Imprime Ticket_DXR" := PosTerminal."DXImprime Ticket";
                //PosTerminal."Puerto Secundario_DXR" := PosTerminal."DXPuerto Secundario";
                PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."DXDireccion IP Secundaria";
                PosTerminal."Direccion IP_DXR" := PosTerminal."DXDireccion IP";
                //PosTerminal."Puerto IP_DXR" := PosTerminal."DXPuerto IP";
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
                PosTerminal."URLEndPoint_DXR" := PosTerminal."DXURLEndPoint";
                PosTerminal."Use Amount In Currency_DXR" := PosTerminal."DX Use Amount In Currency";
                PosTerminal."Local Currency Symbol_DXR" := PosTerminal."DX Local Currency Symbol";
                PosTerminal.Modify(false);
            until PosTerminal.Next() = 0;
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
    begin
        if PosTransLine.FindSet(true) then
            repeat
                PosTransLine."VP Approved_DXR" := PosTransLine."DXVP Approved";
                PosTransLine."VP Authorization No._DXR" := PosTransLine."DXVP Authorization No.";
                PosTransLine."VP Lot No._DXR" := PosTransLine."DXVP Lot No.";
                PosTransLine."Cuota Quantity_DXR" := PosTransLine."DXCuota Quantity";
                PosTransLine.Modify(false);
            until PosTransLine.Next() = 0;
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
    begin
        if TenderType.FindSet(true) then
            repeat
                TenderType."ReqVeriphoneProcessing_DXR" := TenderType."DXRequiredVeriphoneProcessing";
                TenderType.tPayment_DXR := TenderType.DXtPayment;
                TenderType."Cuota Payment_DXR" := TenderType."DXCuota Payment";
                TenderType."Use Form For Cuotas_DXR" := TenderType."DXUse Form For Cuotas";
                TenderType."InfoCode For Cuotas_DXR" := TenderType."DXInfoCode For Cuotas";
                TenderType.Modify(false);
            until TenderType.Next() = 0;
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
    begin
        if TransPaymentEntry.FindSet(true) then
            repeat
                TransPaymentEntry."VP Approved_DXR" := TransPaymentEntry."DXVP Approved";
                TransPaymentEntry."VP Authorization No._DXR" := TransPaymentEntry."DXVP Authorization No.";
                TransPaymentEntry."VP Lot No._DXR" := TransPaymentEntry."DXVP Lot No.";
                TransPaymentEntry."Cuota Quantity_DXR" := TransPaymentEntry."DXCuota Quantity";
                TransPaymentEntry.Modify(false);
            until TransPaymentEntry.Next() = 0;
    end;
}
