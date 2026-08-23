codeunit 60014 "DXR MCC Upgrade Tag Mgt"
{
    // Backs "Force Rerun" (see DXR MCC Concept Subform). Every migration codeunit across this
    // portfolio gates its real work behind `if not UpgradeTag.HasUpgradeTag(X) then ... ;
    // UpgradeTag.SetUpgradeTag(X)` - once set, re-invoking the dispatcher is a no-op. There is
    // no supported "clear"/"delete" method on the standard system codeunit "Upgrade Tag" (9999)
    // - HasUpgradeTag/SetUpgradeTag/SetAllUpgradeTags is the whole public surface (confirmed
    // against Microsoft Learn). Forcing a re-run means deleting the row directly from the
    // platform's own "Upgrade Tags" table (9999), same as this repo's own (currently disabled)
    // test fixture DxMigrationOrchestrationTests.Codeunit.al already does - reused its exact
    // field numbers here (1 = Tag, 3 = Company Name) rather than re-guessing them, and its same
    // RecordRef.Open(9999) approach, since table 9999 is Access=Internal in BC 28 and can't be
    // referenced by name from another extension.
    //
    // This is deliberately NOT a self-service one-click action: SetAllUpgradeTags exists
    // specifically so upgrade tags aren't meant to be user-clearable, and Microsoft's own docs
    // only sanction direct tag manipulation for "fixing a broken upgrade" - not routine replay.
    // Every caller must supply the exact tag text (see "Upgrade Tags" field on DXR MCC Concept,
    // operator-maintained, never auto-populated) and the page confirms before calling this.
    //
    // No Permissions property for table 9999 here: "Table System.Upgrade.'Upgrade Tags' is
    // inaccessible due to its protection level" at compile time (confirmed - it's Access=Internal
    // to the System Application, can't be named in a Permissions clause from another extension,
    // same reason the repo's own disabled test fixture uses RecordRef.Open(9999) instead of
    // `Record "Upgrade Tags"`). That means MCC's own permission set (60000) cannot grant Delete
    // on this table - whoever runs "Force Rerun" needs a permission set that already includes
    // Upgrade Tags = D (e.g. SUPER) independently of anything MCC declares. Document this for
    // the operator rather than silently failing at runtime with a permission error.

    /// <summary>
    /// Deletes every Upgrade Tags row (this company only) whose Tag matches one of the
    /// semicolon-separated codes in TagList. Returns how many rows were actually found and
    /// deleted, and appends any tag that had no matching row to NotFoundList (surfaced by the
    /// caller so a typo in the operator-entered tag reads as "0 cleared, tag not found" instead
    /// of silently doing nothing).
    /// </summary>
    procedure ClearUpgradeTags(TagList: Text[250]; var NotFoundList: List of [Text]): Integer
    var
        Tag: Text;
        ClearedCount: Integer;
    begin
        foreach Tag in TagList.Split(';') do begin
            Tag := Tag.Trim();
            if Tag = '' then
                continue;

            if ClearUpgradeTag(Tag) then
                ClearedCount += 1
            else
                NotFoundList.Add(Tag);
        end;
        exit(ClearedCount);
    end;

    local procedure ClearUpgradeTag(Tag: Text): Boolean
    var
        UpgradeTagsRef: RecordRef;
        TagField: FieldRef;
        CompanyField: FieldRef;
        Found: Boolean;
    begin
        UpgradeTagsRef.Open(9999);
        TagField := UpgradeTagsRef.Field(1);
        TagField.SetRange(Tag);
        CompanyField := UpgradeTagsRef.Field(3);
        CompanyField.SetRange(CompanyName());
        Found := UpgradeTagsRef.FindFirst();
        if Found then
            UpgradeTagsRef.Delete(false);
        UpgradeTagsRef.Close();
        exit(Found);
    end;
}
