// #if not ESCUDEA and not BCDX
// codeunit 60078 "DXR MCC SD Migr LSCStore"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopyLSCStorePrintHeaderDoc() (field 59000->54747 on its
//     // own "DXR_Store Ext" table extension). Both fields are the same Option type with identical
//     // OptionMembers order (Documentos,Usuarios), confirmed by reading both field declarations
//     // directly - a plain typed assignment is safe (no re-mapping needed).
//     Permissions = tabledata "LSC Store" = RM;
// 
//     trigger OnRun()
//     var
//         LSCStore: Record "LSC Store";
//     begin
//         if LSCStore.FindSet(true) then
//             repeat
//                 if LSCStore."Print Header Doc._DXR" <> LSCStore."PE Print Header Doc. DXR" then begin
//                     LSCStore."Print Header Doc._DXR" := LSCStore."PE Print Header Doc. DXR";
//                     LSCStore.Modify(false);
//                 end;
//             until LSCStore.Next() = 0;
//     end;
// }
// 
// #endif
// 
