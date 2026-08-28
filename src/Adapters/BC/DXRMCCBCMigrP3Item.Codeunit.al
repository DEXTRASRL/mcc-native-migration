// #if not ESCUDEA and not BCDX
// codeunit 60100 "DXR MCC BC Migr P3 Item"
// {
//     // Native local migration - ported from Base Controls' own "DXR_BC Migr Phase 3".
//     // CopyItemFields(): 2 renumbered tableextension fields, fill-only-if-blank (idempotent).
//     Permissions = tabledata Item = RIMD;
// 
//     trigger OnRun()
//     var
//         ItemRec: Record Item;
//         Modified: Boolean;
//         RowsSinceCommit: Integer;
//     begin
//         if not ItemRec.FindSet(true) then
//             exit;
//         repeat
//             Modified := false;
// 
//             if (ItemRec."Payment Terms Code_DXR" = '') and (ItemRec."Payment Terms Code_Old" <> '') then begin
//                 ItemRec."Payment Terms Code_DXR" := ItemRec."Payment Terms Code_Old";
//                 Modified := true;
//             end;
// 
//             if (not ItemRec."Allow Decimals_DXR") and ItemRec."Allow Decimals_Old" then begin
//                 ItemRec."Allow Decimals_DXR" := true;
//                 Modified := true;
//             end;
// 
//             if Modified then
//                 ItemRec.Modify(false);
// 
//             RowsSinceCommit += 1;
//             if RowsSinceCommit >= 500 then begin
//                 Commit();
//                 RowsSinceCommit := 0;
//             end;
//         until ItemRec.Next() = 0;
//         Commit();
//     end;
// }
// 
// #endif
// 
