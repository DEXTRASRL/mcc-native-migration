// #if not ESCUDEA and not BCDX
// codeunit 60107 "DXR MCC RBPD Migr IBSetup"
// {
//     // Native local migration - ported from Recaudo BPD's own
//     // "DXR_Recaudo Migr Phase1 Migr".MigrateSetup(). Also ports the Dispatcher's own
//     // Update_Setup() pre-cleanup (deduplicates a blank-Code row on the LEGACY
//     // "DXR-IB IbankingSetup" table, a genuine data-quality prerequisite Phase1 depends on
//     // - Recaudo BPD's own RunManually() always runs it immediately before Phase1).
//     Permissions = tabledata "DXR-IB IbankingSetup" = RIMD,
//                   tabledata "DXR_IbankingSetup" = RIM;
// 
//     trigger OnRun()
//     begin
//         DeduplicateLegacySetup();
//         MigrateSetup();
//     end;
// 
//     local procedure DeduplicateLegacySetup()
//     var
//         IbankingSetup: Record "DXR-IB IbankingSetup";
//         IbankingSetup2: Record "DXR-IB IbankingSetup";
//     begin
//         if IbankingSetup.FindFirst() then begin
//             IbankingSetup2.Init();
//             IbankingSetup2.Code := ' ';
//             IbankingSetup2."User Active DXR-IB" := IbankingSetup."User Active DXR-IB";
//             IbankingSetup2."User Name DXR-IB" := IbankingSetup."User Name DXR-IB";
//             IbankingSetup2."Local Currency DXR-IB" := IbankingSetup."Local Currency DXR-IB";
//             IbankingSetup2."Journal Template Name DXR-IB" := IbankingSetup."Journal Template Name DXR-IB";
//             IbankingSetup2."Journal Batch Name DXR-IB" := IbankingSetup."Journal Batch Name DXR-IB";
//             IbankingSetup2."Description DXR-IB" := IbankingSetup."Description DXR-IB";
//             IbankingSetup2."Bal. Account Type DXR-IB" := IbankingSetup."Bal. Account Type DXR-IB";
//             IbankingSetup2."Bal. Account No. DXR-IB" := IbankingSetup."Bal. Account No. DXR-IB";
//             IbankingSetup2."No. Series DXR-IB" := IbankingSetup."No. Series DXR-IB";
//             IbankingSetup2."Recibo Ingreso DXR-IB" := IbankingSetup."Recibo Ingreso DXR-IB";
//             IbankingSetup2."Starting No. DXR-IB" := IbankingSetup."Starting No. DXR-IB";
//             IbankingSetup2."Ending No. DXR-IB" := IbankingSetup."Ending No. DXR-IB";
//             IbankingSetup2."Default Nos. DXR-IB" := IbankingSetup."Default Nos. DXR-IB";
//             IbankingSetup2."Line No. DXR-IB" := IbankingSetup."Line No. DXR-IB";
//             IbankingSetup2."Template Type DXR-IB" := IbankingSetup."Template Type DXR-IB";
//             IbankingSetup2."Document Type DXR-IB" := IbankingSetup."Document Type DXR-IB";
//             IbankingSetup2."Account Type DXR-IB" := IbankingSetup."Account Type DXR-IB";
//             IbankingSetup2."User Password DXR-IB" := IbankingSetup."User Password DXR-IB";
//             IbankingSetup2."AutoPosteo DXR-IB" := IbankingSetup."AutoPosteo DXR-IB";
//             IbankingSetup2."PagoExcedente DXR-IB" := IbankingSetup."PagoExcedente DXR-IB";
//             IbankingSetup2."Posting No. Series DXR-IB" := IbankingSetup."Posting No. Series DXR-IB";
//             IbankingSetup2."JnlBatchNamePendientes DXR-IB" := IbankingSetup."JnlBatchNamePendientes DXR-IB";
//             IbankingSetup2."open DXR-IB" := IbankingSetup."open DXR-IB";
//             IbankingSetup2."Middleware URL DXR-IB" := IbankingSetup."Middleware URL DXR-IB";
//             IbankingSetup2."Middleware User DXR-IB" := IbankingSetup."Middleware User DXR-IB";
//             IbankingSetup2."Middleware Password DXR-IB" := IbankingSetup."Middleware Password DXR-IB";
//             IbankingSetup2."Auto Process Pending DXR-IB" := IbankingSetup."Auto Process Pending DXR-IB";
//             IbankingSetup2.Insert();
//             IbankingSetup.Delete(true);
//         end;
//     end;
// 
//     local procedure MigrateSetup()
//     var
//         OldRec: Record "DXR-IB IbankingSetup";
//         NewRec: Record "DXR_IbankingSetup";
//     begin
//         if OldRec.FindSet() then
//             repeat
//                 if not NewRec.Get(OldRec.Code) then begin
//                     NewRec.Init();
//                     NewRec."User Active DXR-IB" := OldRec."User Active DXR-IB";
//                     NewRec."User Name DXR-IB" := OldRec."User Name DXR-IB";
//                     NewRec."Local Currency DXR-IB" := OldRec."Local Currency DXR-IB";
//                     NewRec."Journal Template Name DXR-IB" := OldRec."Journal Template Name DXR-IB";
//                     NewRec."Journal Batch Name DXR-IB" := OldRec."Journal Batch Name DXR-IB";
//                     NewRec."Description DXR-IB" := OldRec."Description DXR-IB";
//                     NewRec."Bal. Account Type DXR-IB" := OldRec."Bal. Account Type DXR-IB";
//                     NewRec."Bal. Account No. DXR-IB" := OldRec."Bal. Account No. DXR-IB";
//                     NewRec."No. Series DXR-IB" := OldRec."No. Series DXR-IB";
//                     NewRec."Recibo Ingreso DXR-IB" := OldRec."Recibo Ingreso DXR-IB";
//                     NewRec."Starting No. DXR-IB" := OldRec."Starting No. DXR-IB";
//                     NewRec."Ending No. DXR-IB" := OldRec."Ending No. DXR-IB";
//                     NewRec."Default Nos. DXR-IB" := OldRec."Default Nos. DXR-IB";
//                     NewRec."Line No. DXR-IB" := OldRec."Line No. DXR-IB";
//                     NewRec."Template Type DXR-IB" := OldRec."Template Type DXR-IB";
//                     NewRec."Document Type DXR-IB" := OldRec."Document Type DXR-IB";
//                     NewRec."Account Type DXR-IB" := OldRec."Account Type DXR-IB";
//                     NewRec."User Password DXR-IB" := OldRec."User Password DXR-IB";
//                     NewRec."AutoPosteo DXR-IB" := OldRec."AutoPosteo DXR-IB";
//                     NewRec."PagoExcedente DXR-IB" := OldRec."PagoExcedente DXR-IB";
//                     NewRec."Posting No. Series DXR-IB" := OldRec."Posting No. Series DXR-IB";
//                     NewRec."JnlBatchNamePendientes DXR-IB" := OldRec."JnlBatchNamePendientes DXR-IB";
//                     NewRec."open DXR-IB" := OldRec."open DXR-IB";
//                     NewRec."Middleware URL DXR-IB" := OldRec."Middleware URL DXR-IB";
//                     NewRec."Middleware User DXR-IB" := OldRec."Middleware User DXR-IB";
//                     NewRec."Middleware Password DXR-IB" := OldRec."Middleware Password DXR-IB";
//                     NewRec."Auto Process Pending DXR-IB" := OldRec."Auto Process Pending DXR-IB";
//                     NewRec.Code := OldRec.Code;
//                     NewRec.Insert(true);
//                 end;
//             until OldRec.Next() = 0;
//     end;
// }
// 
// #endif
// 
