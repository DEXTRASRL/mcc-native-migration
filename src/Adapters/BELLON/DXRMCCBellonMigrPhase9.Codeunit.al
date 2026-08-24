codeunit 60153 "DXR MCC Bellon Migr Phase9"
{
    // Native local migration - ported verbatim from Bellon Customization's own "Bellon Migr.
    // Phase 9 TransferH" (56126) -> "Bellon Upgrade Process".MigrateTransferHeaderIdRestore283().
    // Restores the 2 "_BE_DXR" fields of TransferHeader.TableExt.al ("Tipo Request"/"Transfer
    // Status", 50011/50012 -> 52787/52788) left out of Phase 7. NOTE (per the real source's own
    // header comment, superseded 2026-08-23): the ID collision this phase originally deferred as
    // "Release 2" work (52787/52788 also used by Transfer Shipment/Receipt Header's "Order User
    // ID_DXR."/"Order Date Created_DXR.", linked via BC's native CopyFromTransferHeader) was
    // subsequently resolved by "Bellon Migr. Phase 14 XCollFix" relocating Transfer Header's side
    // to 58100-58102. This phase's own bridge (50011/50012 -> 52787/52788) still runs first and is
    // still required - Phase 14 bridges FROM 52787/52788 (this phase's target) TO 58100+.
    Permissions =
        tabledata "Transfer Header" = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-TransferHeaderIdRestore283') then
            exit;

        MigrateTableExt_TransferHeaderIdRestore();

        UpgradeTag.SetUpgradeTag('DXR-TransferHeaderIdRestore283');
    end;

    local procedure CopyFieldIfExists(var RecRef: RecordRef; OldFieldNo: Integer; NewFieldNo: Integer)
    begin
        if not RecRef.FieldExist(OldFieldNo) then
            exit;
        if not RecRef.FieldExist(NewFieldNo) then
            exit;
        RecRef.Field(NewFieldNo).Value := RecRef.Field(OldFieldNo).Value;
    end;

    local procedure MigrateTableExt_TransferHeaderIdRestore()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"Transfer Header");
        if RecRef.FindSet(true) then
            repeat
                CopyFieldIfExists(RecRef, 50011, 52787); // Tipo Request_Old
                CopyFieldIfExists(RecRef, 50012, 52788); // Transfer Status_Old
                RecRef.Modify(false);
            until RecRef.Next() = 0;
        RecRef.Close();
    end;
}
