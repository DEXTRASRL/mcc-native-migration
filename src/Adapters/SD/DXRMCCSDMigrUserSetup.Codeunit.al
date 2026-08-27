#if not ESCUDEA and not BCDX
codeunit 60077 "DXR MCC SD Migr UserSetup"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopyUserSetupInvoicePermission() (field 59000->54747 on
    // its own "DXR_Approval Users Setup Ext" table extension - field names are "Invoice Permission
    // DXR"/"Invoice Permission_DXR" here, unlike the other 7 SD field-copy concepts which share the
    // "Special Dispatch..." name).
    Permissions = tabledata "User Setup" = RM;

    // Fixed 2026-08-27: same whole-table UPDLOCK + missing-SetLoadFields problem, and the same fix,
    // as "DXR MCC SD Migr Customer" - "User Setup" is small but is read on virtually every posting
    // path, so an UPDLOCK over all of it for the whole run blocks unrelated work.
    trigger OnRun()
    var
        UserSetup: Record "User Setup";
        UserSetupToUpdate: Record "User Setup";
    begin
        UserSetup.SetLoadFields("User ID", "Invoice Permission_DXR", "Invoice Permission DXR");
        if not UserSetup.FindSet(false) then
            exit;
        repeat
            if UserSetup."Invoice Permission_DXR" <> UserSetup."Invoice Permission DXR" then
                if UserSetupToUpdate.Get(UserSetup."User ID") then begin
                    UserSetupToUpdate."Invoice Permission_DXR" := UserSetupToUpdate."Invoice Permission DXR";
                    UserSetupToUpdate.Modify(false);
                end;
        until UserSetup.Next() = 0;
    end;
}

#endif
