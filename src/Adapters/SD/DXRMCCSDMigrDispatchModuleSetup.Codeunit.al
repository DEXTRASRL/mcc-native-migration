// codeunit 60071 "DXR MCC SD Migr DispModSetup"
// {
//     // Native local migration - ported from Special Dispatch's own
//     // "DXR_SD_Migr_Phase2_LegacyTable".Execute(), which used generic RecordRef/FieldRef reflection
//     // (GetCommonCompatibleFieldNos) to copy every common field between the two tables. Written here
//     // as a typed field-by-field upsert: both tables (legacy 59114 "Dispatch Module Setup" and
//     // active 54778 "DXR_Dispatch Module Setup") share the same logical field layout and "Key" PK.
//     Permissions = tabledata "Dispatch Module Setup" = R,
//                   tabledata "DXR_Dispatch Module Setup" = RIM;

//     trigger OnRun()
//     var
//         Old: Record "Dispatch Module Setup";
//         New: Record "DXR_Dispatch Module Setup";
//     begin
//         if Old.FindSet() then
//             repeat
//                 if New.Get(Old."Key") then begin
//                     CopyFields(Old, New);
//                     New.Modify(false);
//                 end else begin
//                     New.Init();
//                     New."Key" := Old."Key";
//                     CopyFields(Old, New);
//                     New.Insert(false);
//                 end;
//             until Old.Next() = 0;
//     end;

//     local procedure CopyFields(Old: Record "Dispatch Module Setup"; var New: Record "DXR_Dispatch Module Setup")
//     begin
//         New."Dispatch Control" := Old."Dispatch Control";
//         New."Dispatch Validation" := Old."Dispatch Validation";
//         New."Block Invoice in Shipment" := Old."Block Invoice in Shipment";
//         New."Allow Edit Dispatch Order" := Old."Allow Edit Dispatch Order";
//         New."Allow Edit Dispatch Quote" := Old."Allow Edit Dispatch Quote";
//         New."Show ProForma Action" := Old."Show ProForma Action";
//         New."Show Special Dispatch Action" := Old."Show Special Dispatch Action";
//     end;
// }
