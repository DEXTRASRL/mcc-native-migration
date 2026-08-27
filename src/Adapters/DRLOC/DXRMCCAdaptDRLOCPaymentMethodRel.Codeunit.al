codeunit 60164 "DXR MCC Adapt DRLOC PmtMethod"
{
    // Native Direct pattern - DR-Localization now grants MCC internalsVisibleTo, so MCC declares
    // both "DXR_Payment Method Relation" (52180, Access=Internal) and "DXPayment Method Relation"
    // (54133, Access=Internal) directly instead of calling DRLOC's own codeunit 52210
    // ("DXR_Migr. Phase 2 Fiscal") -> RunBootstrap_PaymentMethodRelation() as a cross-app bridge.
    // Replicates that procedure's exact fill-semantics inline: a fresh, ungated, per-tenant copy
    // for every legacy row whose (Code, Payment Method Code) key does not already exist on the
    // target - zero RecordRef/FieldRef/TransferFields, explicit per-field typed assignment
    // (both tables share the same 3-field shape: Code, Description, Payment Method Code).
    // DRLOC's own RunBootstrap_PaymentMethodRelation() procedure is left in place, unmodified,
    // now orphaned/unused (harmless - established safe default this session).
    Permissions =
        tabledata "DXPayment Method Relation" = R,
        tabledata "DXR_Payment Method Relation" = RI;

    trigger OnRun()
    begin
        Execute();
    end;

    local procedure Execute()
    var
        Legacy: Record "DXPayment Method Relation";
        New: Record "DXR_Payment Method Relation";
    begin
        // Fixed 2026-08-27: A1 - added the partial-record hint the scan was missing, so the read no
        // longer joins the companion table of every tableextension on the legacy table per row.
        // FindSet() (ForUpdate = false) was already correct here - the legacy side is only read.
        Legacy.SetLoadFields(Code, Description, "Payment Method Code");
        if Legacy.FindSet() then
            repeat
                if not New.Get(Legacy.Code, Legacy."Payment Method Code") then begin
                    New.Init();
                    New.Code := Legacy.Code;
                    New.Description := Legacy.Description;
                    New."Payment Method Code" := Legacy."Payment Method Code";
                    New.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;
}
