// #if not ESCUDEA and not BCDX
// codeunit 60077 "DXR MCC SD Migr UserSetup"
// {
//     // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
//     // from Special Dispatch's own Phase1.CopyUserSetupInvoicePermission() (field 59000->54747 on
//     // its own "DXR_Approval Users Setup Ext" table extension - field names are "Invoice Permission
//     // DXR"/"Invoice Permission_DXR" here, unlike the other 7 SD field-copy concepts which share the
//     // "Special Dispatch..." name).
//     Permissions = tabledata "User Setup" = RM;
// 
//     trigger OnRun()
//     var
//         UserSetup: Record "User Setup";
//     begin
//         if UserSetup.FindSet(true) then
//             repeat
//                 if UserSetup."Invoice Permission_DXR" <> UserSetup."Invoice Permission DXR" then begin
//                     UserSetup."Invoice Permission_DXR" := UserSetup."Invoice Permission DXR";
//                     UserSetup.Modify(false);
//                 end;
//             until UserSetup.Next() = 0;
//     end;
// }
// 
// #endif
// 
