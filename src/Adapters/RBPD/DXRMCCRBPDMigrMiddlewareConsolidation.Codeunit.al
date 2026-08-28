// #if not ESCUDEA and not BCDX
// codeunit 60114 "DXR MCC RBPD Migr MidwareCons"
// {
//     // Native local migration - ported from Recaudo BPD's own
//     // "DXR_Recaudo Migr Phase2 Middle".MigrateMiddlewareConfiguration() - consolidates
//     // middleware fields from "DXR_IbankingSetup" into "DXR_MiddlewareSetup". Depends on
//     // both tables already being populated (RBPD-P2 seq3/seq9) - the registry's own
//     // Sequence No. (this row is seq10, after seq3 and seq9) already guarantees that
//     // ordering in a whole-extension run; quietly does nothing yet on a fresh
//     // single-concept run before those tables have data, same as the original.
//     Permissions = tabledata "DXR_IbankingSetup" = R,
//                   tabledata "DXR_MiddlewareSetup" = RIM;
// 
//     trigger OnRun()
//     var
//         IBSetup: Record "DXR_IbankingSetup";
//         MiddlewareSetup: Record "DXR_MiddlewareSetup";
//     begin
//         if not IBSetup.FindFirst() then
//             exit;
// 
//         if (IBSetup."Middleware URL DXR-IB" = '') and
//            (IBSetup."Middleware User DXR-IB" = '') and
//            (IBSetup."Middleware Password DXR-IB" = '')
//         then
//             exit;
// 
//         MiddlewareSetup := MiddlewareSetup.GetSetup();
// 
//         // Do not overwrite configuration already entered directly in the new table.
//         if (MiddlewareSetup."Middleware URL" <> '') or
//            (MiddlewareSetup."Middleware Username" <> '') or
//            (MiddlewareSetup."Middleware Password" <> '')
//         then
//             exit;
// 
//         MiddlewareSetup."Middleware URL" := IBSetup."Middleware URL DXR-IB";
//         MiddlewareSetup."Middleware Username" := IBSetup."Middleware User DXR-IB";
//         MiddlewareSetup."Middleware Password" := IBSetup."Middleware Password DXR-IB";
//         MiddlewareSetup."Auto Process Pending" := IBSetup."Auto Process Pending DXR-IB";
//         MiddlewareSetup.Active := true;
// 
//         if MiddlewareSetup."Connection Timeout" = 0 then
//             MiddlewareSetup."Connection Timeout" := 30;
//         if MiddlewareSetup."Request Timeout" = 0 then
//             MiddlewareSetup."Request Timeout" := 60;
//         if MiddlewareSetup."Auto Process Interval" = 0 then
//             MiddlewareSetup."Auto Process Interval" := 15;
// 
//         MiddlewareSetup."Enable Logging" := true;
//         MiddlewareSetup."Log Level" := MiddlewareSetup."Log Level"::Information;
// 
//         MiddlewareSetup.Modify(true);
//     end;
// }
// 
// #endif
// 
