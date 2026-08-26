// #if not ESCUDEA and not BCDX
// codeunit 60111 "DXR MCC RBPD Migr DocsPend"
// {
//     // Native local migration - ported from Recaudo BPD's own
//     // "DXR_Recaudo Migr Phase1 Migr".MigrateRecaudoDocsPendientes().
//     Permissions = tabledata "DXR-IB Recaudo Docs Pendientes" = R,
//                   tabledata "DXR_Recaudo Docs Pendientes" = RIM;

//     trigger OnRun()
//     var
//         OldRec: Record "DXR-IB Recaudo Docs Pendientes";
//         NewRec: Record "DXR_Recaudo Docs Pendientes";
//     begin
//         if OldRec.FindSet() then
//             repeat
//                 if not NewRec.Get(OldRec."id DXR-IB") then begin
//                     NewRec.Init();
//                     NewRec."id DXR-IB" := OldRec."id DXR-IB";
//                     NewRec."Numeroreferencia DXR-IB" := OldRec."Numeroreferencia DXR-IB";
//                     NewRec."Fecha DXR-IB" := OldRec."Fecha DXR-IB";
//                     NewRec."Valorpagado DXR-IB" := OldRec."Valorpagado DXR-IB";
//                     NewRec."Idtransaccionbanco DXR-IB" := OldRec."Idtransaccionbanco DXR-IB";
//                     NewRec."Numeroautorizacion DXR-IB" := OldRec."Numeroautorizacion DXR-IB";
//                     NewRec.Insert(true);
//                 end;
//             until OldRec.Next() = 0;
//     end;
// }

// #endif
