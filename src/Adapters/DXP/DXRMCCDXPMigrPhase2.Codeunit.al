codeunit 60081 "DXR MCC DXP Migr Phase2"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase2_Fields"
    // - copies 38 duplicated fields across 5 LS Central tableextensions (DXP-P2 concepts) via
    // RecordRef/FieldRef reflection over field-number pairs, same-table (no clone object exists
    // for tableextension fields). See "DXR MCC DXP Migr Phase1" for the dropped-bookkeeping note.
    Permissions = tabledata "LSC Infocode" = RM,
                  tabledata "LSC POS Terminal" = RM,
                  tabledata "LSC POS Trans. Line" = RM,
                  tabledata "LSC Tender Type" = RM,
                  tabledata "LSC Trans. Payment Entry" = RM;

    trigger OnRun()
    begin
        CopyInfocodeFields();
        CopyPOSTerminalFields();
        CopyPOSTransLineFields();
        CopyTenderTypeFields();
        CopyTransPaymentEntryFields();
    end;

    local procedure CopyTableFields(TableNo: Integer; var SourceFieldNos: List of [Integer]; var DestFieldNos: List of [Integer])
    var
        RecRef: RecordRef;
        SourceField: FieldRef;
        DestField: FieldRef;
        Index: Integer;
    begin
        RecRef.Open(TableNo);
        if RecRef.FindSet(true) then
            repeat
                for Index := 1 to SourceFieldNos.Count() do begin
                    SourceField := RecRef.Field(SourceFieldNos.Get(Index));
                    DestField := RecRef.Field(DestFieldNos.Get(Index));
                    DestField.Value := SourceField.Value;
                end;
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;

    local procedure CopyInfocodeFields()
    var
        Infocode: Record "LSC Infocode";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, Infocode.FieldNo("DX Refund Card"), Infocode.FieldNo("Refund Card_DXR"));
        CopyTableFields(Database::"LSC Infocode", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DX Uses VeriPhone"), PosTerminal.FieldNo("Uses VeriPhone_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXPuerto), PosTerminal.FieldNo(Puerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXProveedor), PosTerminal.FieldNo(Proveedor_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXImprime Ticket"), PosTerminal.FieldNo("Imprime Ticket_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXPuerto Secundario"), PosTerminal.FieldNo("Puerto Secundario_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXDireccion IP Secundaria"), PosTerminal.FieldNo("Direccion IP Secundaria_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXDireccion IP"), PosTerminal.FieldNo("Direccion IP_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXPuerto IP"), PosTerminal.FieldNo("Puerto IP_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXNumero Transaccion"), PosTerminal.FieldNo("Numero Transaccion_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXNumero Terminal"), PosTerminal.FieldNo("Numero Terminal_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXMerchant ID"), PosTerminal.FieldNo("Merchant ID_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXRutaFirma), PosTerminal.FieldNo(RutaFirma_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXAuth1), PosTerminal.FieldNo(Auth1_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXAuth2), PosTerminal.FieldNo(Auth2_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXIpString), PosTerminal.FieldNo(IpString_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXRpuerto), PosTerminal.FieldNo(Rpuerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXLocalIpString), PosTerminal.FieldNo(LocalIpString_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXLPuerto), PosTerminal.FieldNo(LPuerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DXCierre Automatico"), PosTerminal.FieldNo("Cierre Automatico_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DX Visanet IpString"), PosTerminal.FieldNo("Visanet IpString_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DX Visanet Puerto"), PosTerminal.FieldNo("Visanet Puerto_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXURLEndPoint), PosTerminal.FieldNo(URLEndPoint_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DX Use Amount In Currency"), PosTerminal.FieldNo("Use Amount In Currency_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("DX Local Currency Symbol"), PosTerminal.FieldNo("Local Currency Symbol_DXR"));
        CopyTableFields(Database::"LSC POS Terminal", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("DXVP Approved"), PosTransLine.FieldNo("VP Approved_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("DXVP Authorization No."), PosTransLine.FieldNo("VP Authorization No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("DXVP Lot No."), PosTransLine.FieldNo("VP Lot No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("DXCuota Quantity"), PosTransLine.FieldNo("Cuota Quantity_DXR"));
        CopyTableFields(Database::"LSC POS Trans. Line", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("DXRequiredVeriphoneProcessing"), TenderType.FieldNo("ReqVeriphoneProcessing_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo(DXtPayment), TenderType.FieldNo(tPayment_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("DXCuota Payment"), TenderType.FieldNo("Cuota Payment_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("DXUse Form For Cuotas"), TenderType.FieldNo("Use Form For Cuotas_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("DXInfoCode For Cuotas"), TenderType.FieldNo("InfoCode For Cuotas_DXR"));
        CopyTableFields(Database::"LSC Tender Type", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("DXVP Approved"), TransPaymentEntry.FieldNo("VP Approved_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("DXVP Authorization No."), TransPaymentEntry.FieldNo("VP Authorization No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("DXVP Lot No."), TransPaymentEntry.FieldNo("VP Lot No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("DXCuota Quantity"), TransPaymentEntry.FieldNo("Cuota Quantity_DXR"));
        CopyTableFields(Database::"LSC Trans. Payment Entry", SourceFieldNos, DestFieldNos);
    end;

    local procedure AddFieldPair(var SourceFieldNos: List of [Integer]; var DestFieldNos: List of [Integer]; SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        SourceFieldNos.Add(SourceFieldNo);
        DestFieldNos.Add(DestFieldNo);
    end;
}
