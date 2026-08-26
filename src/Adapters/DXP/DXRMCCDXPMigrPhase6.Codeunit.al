// codeunit 60085 "DXR MCC DXP Migr Phase6"
// {
//     // Native local migration - ported verbatim from DX-Payments' own "DXR_DXP_Migr_Phase6_Fields"
//     // - copies the 41 renumbered-generation duplicated fields (the "..._Old" renamed field ->
//     // current field, same 5 LS Central tableextensions Phase 2 also touches) via direct typed
//     // field assignments (DXP-P6 concepts, seq 10/39-42).
//     Permissions = tabledata "LSC Infocode" = RM,
//                   tabledata "LSC POS Terminal" = RM,
//                   tabledata "LSC POS Trans. Line" = RM,
//                   tabledata "LSC Tender Type" = RM,
//                   tabledata "LSC Trans. Payment Entry" = RM;

//     trigger OnRun()
//     begin
//         RunSetup();
//         RunAccounting();
//     end;

//     procedure RunSetup()
//     begin
//         CopyInfocodeFields();
//         CopyPOSTerminalFields();
//         CopyTenderTypeFields();
//     end;

//     procedure RunMaster()
//     begin
//     end;

//     procedure RunAccounting()
//     begin
//         CopyPOSTransLineFields();
//         CopyTransPaymentEntryFields();
//     end;

//     local procedure CopyInfocodeFields()
//     var
//         Infocode: Record "LSC Infocode";
//     begin
//         if Infocode.FindSet(true) then
//             repeat
//                 Infocode."Refund Card_DXR" := Infocode."Refund Card_Old";
//                 Infocode.Modify(false);
//             until Infocode.Next() = 0;
//     end;

//     local procedure CopyPOSTerminalFields()
//     var
//         PosTerminal: Record "LSC POS Terminal";
//     begin
//         if PosTerminal.FindSet(true) then
//             repeat
//                 PosTerminal."Uses VeriPhone_DXR" := PosTerminal."Uses VeriPhone_Old";
//                 PosTerminal.Puerto_DXR := PosTerminal.Puerto_Old;
//                 PosTerminal.Proveedor_DXR := PosTerminal.Proveedor_Old;
//                 PosTerminal."Imprime Ticket_DXR" := PosTerminal."Imprime Ticket_Old";
//                 PosTerminal."Puerto Secundario_DXR" := PosTerminal."Puerto Secundario_Old";
//                 PosTerminal."Direccion IP Secundaria_DXR" := PosTerminal."Direccion IP Secundaria_Old";
//                 PosTerminal."Direccion IP_DXR" := PosTerminal."Direccion IP_Old";
//                 PosTerminal."Puerto IP_DXR" := PosTerminal."Puerto IP_Old";
//                 PosTerminal."Numero Transaccion_DXR" := PosTerminal."Numero Transaccion_Old";
//                 PosTerminal."Numero Terminal_DXR" := PosTerminal."Numero Terminal_Old";
//                 PosTerminal."Merchant ID_DXR" := PosTerminal."Merchant ID_Old";
//                 PosTerminal.RutaFirma_DXR := PosTerminal.RutaFirma_Old;
//                 PosTerminal.Auth1_DXR := PosTerminal.Auth1_Old;
//                 PosTerminal.Auth2_DXR := PosTerminal.Auth2_Old;
//                 PosTerminal.IpString_DXR := PosTerminal.IpString_Old;
//                 PosTerminal.Rpuerto_DXR := PosTerminal.Rpuerto_Old;
//                 PosTerminal.LocalIpString_DXR := PosTerminal.LocalIpString_Old;
//                 PosTerminal.LPuerto_DXR := PosTerminal.LPuerto_Old;
//                 PosTerminal."Cierre Automatico_DXR" := PosTerminal."Cierre Automatico_Old";
//                 PosTerminal."Visanet IpString_DXR" := PosTerminal."Visanet IpString_Old";
//                 PosTerminal."Visanet Puerto_DXR" := PosTerminal."Visanet Puerto_Old";
//                 PosTerminal."URLEndPoint_DXR" := PosTerminal."URLEndPoint_Old";
//                 PosTerminal."Use Amount In Currency_DXR" := PosTerminal."Use Amount In Currency_Old";
//                 PosTerminal."Local Currency Symbol_DXR" := PosTerminal."Local Currency Symbol_Old";
//                 PosTerminal.Modify(false);
//             until PosTerminal.Next() = 0;
//     end;

//     local procedure CopyPOSTransLineFields()
//     var
//         PosTransLine: Record "LSC POS Trans. Line";
//     begin
//         if PosTransLine.FindSet(true) then
//             repeat
//                 PosTransLine."VP Approved_DXR" := PosTransLine."VP Approved_Old";
//                 PosTransLine."VP Authorization No._DXR" := PosTransLine."VP Authorization No._Old";
//                 PosTransLine."VP Lot No._DXR" := PosTransLine."VP Lot No._Old";
//                 PosTransLine."Cuota Quantity_DXR" := PosTransLine."Cuota Quantity_Old";
//                 PosTransLine.Modify(false);
//             until PosTransLine.Next() = 0;
//     end;

//     local procedure CopyTenderTypeFields()
//     var
//         TenderType: Record "LSC Tender Type";
//     begin
//         if TenderType.FindSet(true) then
//             repeat
//                 TenderType."ReqVeriphoneProcessing_DXR" := TenderType."ReqVeriphoneProcessing_Old";
//                 TenderType.tPayment_DXR := TenderType.tPayment_Old;
//                 TenderType."Cuota Payment_DXR" := TenderType."Cuota Payment_Old";
//                 TenderType."Use Form For Cuotas_DXR" := TenderType."Use Form For Cuotas_Old";
//                 TenderType."InfoCode For Cuotas_DXR" := TenderType."InfoCode For Cuotas_Old";
//                 TenderType.Modify(false);
//             until TenderType.Next() = 0;
//     end;

//     local procedure CopyTransPaymentEntryFields()
//     var
//         TransPaymentEntry: Record "LSC Trans. Payment Entry";
//     begin
//         if TransPaymentEntry.FindSet(true) then
//             repeat
//                 TransPaymentEntry."VP Approved_DXR" := TransPaymentEntry."VP Approved_Old";
//                 TransPaymentEntry."VP Authorization No._DXR" := TransPaymentEntry."VP Authorization No._Old";
//                 TransPaymentEntry."VP Lot No._DXR" := TransPaymentEntry."VP Lot No._Old";
//                 TransPaymentEntry."Cuota Quantity_DXR" := TransPaymentEntry."Cuota Quantity_Old";
//                 TransPaymentEntry.Modify(false);
//             until TransPaymentEntry.Next() = 0;
//     end;
// }
