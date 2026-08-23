codeunit 60085 "DXR MCC DXP Migr Phase6"
{
    // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase6_Fields"
    // - copies the 41 renumbered-generation duplicated fields (the "..._Old" renamed field ->
    // current field, same 5 LS Central tableextensions Phase 2 also touches) via RecordRef/FieldRef
    // reflection (DXP-P6 concepts, seq 10/39-42).
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
        AddFieldPair(SourceFieldNos, DestFieldNos, Infocode.FieldNo("Refund Card_Old"), Infocode.FieldNo("Refund Card_DXR"));
        CopyTableFields(Database::"LSC Infocode", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyPOSTerminalFields()
    var
        PosTerminal: Record "LSC POS Terminal";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXRutaFirma_Old), PosTerminal.FieldNo(DXRutaFirma));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(DXRpuerto_Old), PosTerminal.FieldNo(DXRpuerto));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Uses VeriPhone_Old"), PosTerminal.FieldNo("Uses VeriPhone_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(Puerto_Old), PosTerminal.FieldNo(Puerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(Proveedor_Old), PosTerminal.FieldNo(Proveedor_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Imprime Ticket_Old"), PosTerminal.FieldNo("Imprime Ticket_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Puerto Secundario_Old"), PosTerminal.FieldNo("Puerto Secundario_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Direccion IP Secundaria_Old"), PosTerminal.FieldNo("Direccion IP Secundaria_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Direccion IP_Old"), PosTerminal.FieldNo("Direccion IP_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Puerto IP_Old"), PosTerminal.FieldNo("Puerto IP_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Numero Transaccion_Old"), PosTerminal.FieldNo("Numero Transaccion_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Numero Terminal_Old"), PosTerminal.FieldNo("Numero Terminal_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Merchant ID_Old"), PosTerminal.FieldNo("Merchant ID_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(RutaFirma_Old), PosTerminal.FieldNo(RutaFirma_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(Auth1_Old), PosTerminal.FieldNo(Auth1_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(Auth2_Old), PosTerminal.FieldNo(Auth2_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(IpString_Old), PosTerminal.FieldNo(IpString_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(Rpuerto_Old), PosTerminal.FieldNo(Rpuerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(LocalIpString_Old), PosTerminal.FieldNo(LocalIpString_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo(LPuerto_Old), PosTerminal.FieldNo(LPuerto_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Cierre Automatico_Old"), PosTerminal.FieldNo("Cierre Automatico_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Visanet IpString_Old"), PosTerminal.FieldNo("Visanet IpString_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Visanet Puerto_Old"), PosTerminal.FieldNo("Visanet Puerto_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("URLEndPoint_Old"), PosTerminal.FieldNo("URLEndPoint_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Use Amount In Currency_Old"), PosTerminal.FieldNo("Use Amount In Currency_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTerminal.FieldNo("Local Currency Symbol_Old"), PosTerminal.FieldNo("Local Currency Symbol_DXR"));
        CopyTableFields(Database::"LSC POS Terminal", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyPOSTransLineFields()
    var
        PosTransLine: Record "LSC POS Trans. Line";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("VP Approved_Old"), PosTransLine.FieldNo("VP Approved_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("VP Authorization No._Old"), PosTransLine.FieldNo("VP Authorization No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("VP Lot No._Old"), PosTransLine.FieldNo("VP Lot No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, PosTransLine.FieldNo("Cuota Quantity_Old"), PosTransLine.FieldNo("Cuota Quantity_DXR"));
        CopyTableFields(Database::"LSC POS Trans. Line", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyTenderTypeFields()
    var
        TenderType: Record "LSC Tender Type";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("DXRequiredVeriphoneProcess_Old"), TenderType.FieldNo("DXRequiredVeriphoneProcessing"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("ReqVeriphoneProcessing_Old"), TenderType.FieldNo("ReqVeriphoneProcessing_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo(tPayment_Old), TenderType.FieldNo(tPayment_DXR));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("Cuota Payment_Old"), TenderType.FieldNo("Cuota Payment_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("Use Form For Cuotas_Old"), TenderType.FieldNo("Use Form For Cuotas_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TenderType.FieldNo("InfoCode For Cuotas_Old"), TenderType.FieldNo("InfoCode For Cuotas_DXR"));
        CopyTableFields(Database::"LSC Tender Type", SourceFieldNos, DestFieldNos);
    end;

    local procedure CopyTransPaymentEntryFields()
    var
        TransPaymentEntry: Record "LSC Trans. Payment Entry";
        SourceFieldNos: List of [Integer];
        DestFieldNos: List of [Integer];
    begin
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("VP Approved_Old"), TransPaymentEntry.FieldNo("VP Approved_DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("VP Authorization No._Old"), TransPaymentEntry.FieldNo("VP Authorization No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("VP Lot No._Old"), TransPaymentEntry.FieldNo("VP Lot No._DXR"));
        AddFieldPair(SourceFieldNos, DestFieldNos, TransPaymentEntry.FieldNo("Cuota Quantity_Old"), TransPaymentEntry.FieldNo("Cuota Quantity_DXR"));
        CopyTableFields(Database::"LSC Trans. Payment Entry", SourceFieldNos, DestFieldNos);
    end;

    local procedure AddFieldPair(var SourceFieldNos: List of [Integer]; var DestFieldNos: List of [Integer]; SourceFieldNo: Integer; DestFieldNo: Integer)
    begin
        SourceFieldNos.Add(SourceFieldNo);
        DestFieldNos.Add(DestFieldNo);
    end;
}
