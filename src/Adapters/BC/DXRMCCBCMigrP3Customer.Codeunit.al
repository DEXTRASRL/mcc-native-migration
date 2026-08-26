// #if not ESCUDEA and not BCDX
// codeunit 60099 "DXR MCC BC Migr P3 Customer"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
//     // CopyCustomerFields(): 3 renumbered tableextension fields, fills only when the new _DXR
//     // field is still blank/default - never overwrites an already-set value (idempotent).
//     Permissions = tabledata Customer = RIMD;

//     trigger OnRun()
//     var
//         CustomerRec: Record Customer;
//         Modified: Boolean;
//     begin
//         if not CustomerRec.FindSet(true) then
//             exit;
//         repeat
//             Modified := false;

//             if (not CustomerRec."Mandatory Order No._DXR") and CustomerRec."Mandatory Order No._Old" then begin
//                 CustomerRec."Mandatory Order No._DXR" := true;
//                 Modified := true;
//             end;

//             if (CustomerRec."Exp. Exemption Card_DXR" = 0D) and (CustomerRec."Exp. Exemption Card_Old" <> 0D) then begin
//                 CustomerRec."Exp. Exemption Card_DXR" := CustomerRec."Exp. Exemption Card_Old";
//                 Modified := true;
//             end;

//             if (CustomerRec."Reference Address_DXR" = '') and (CustomerRec."Reference Address_Old" <> '') then begin
//                 CustomerRec."Reference Address_DXR" := CustomerRec."Reference Address_Old";
//                 Modified := true;
//             end;

//             if Modified then
//                 CustomerRec.Modify(false);
//         until CustomerRec.Next() = 0;
//     end;
// }

// #endif
