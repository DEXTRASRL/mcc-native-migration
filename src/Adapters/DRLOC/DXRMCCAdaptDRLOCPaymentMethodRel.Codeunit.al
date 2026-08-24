codeunit 60164 "DXR MCC Adapt DRLOC PmtMethod"
{
    // DXR_Payment Method Relation (52180) is Access=Internal in DR-Localization - MCC cannot
    // declare Record "DXR_Payment Method Relation" directly, and its legacy counterpart
    // DXPayment Method Relation (54133) is likewise only meaningfully handled inside DRLOC's own
    // package. This adapter calls DRLOC's own typed public procedure instead (see
    // DR-Localization's own commit, this same task, on "DXR_Migr. Phase 2 Fiscal" (52210) ->
    // RunBootstrap_PaymentMethodRelation() - a fresh, ungated, TransferFields-based copy, distinct
    // from that codeunit's existing Upgrade-Tag-gated per-tenant bootstrap step, which is already
    // set (a no-op) for tenants where DRLOC's own Phase 2 has completed). MCC's side stays
    // zero-RecordRef trivially, since it is a pure single-call wrapper.
    //
    // Reference pattern for every other DRLOC concept (Task A.4/B.1/C.1/D.1), since essentially
    // all of DRLOC's migration targets are Access = Internal per Task 0.2's audit.
    //
    // Typed by numeric ID, not by name: "DXR MCC Adapt DRLOC Dispatch" (60069) found that another
    // MCC dependency (Price Controls Mgt.) independently declares its own, unrelated codeunit also
    // named "DXR_Migr. Phase Dispatcher" (AL0275 ambiguous reference otherwise). No such collision
    // was found for "DXR_Migr. Phase 2 Fiscal" (52210) specifically, but the numeric-ID reference
    // is used here anyway for consistency with that established, already-proven-necessary
    // convention for this family of adapters.
    trigger OnRun()
    var
        Phase2Fiscal: Codeunit 52210;
    begin
        Phase2Fiscal.RunBootstrap_PaymentMethodRelation();
    end;
}
