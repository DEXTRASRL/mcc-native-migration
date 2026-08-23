codeunit 60022 "DXR MCC Adapt BC Phase2"
{
    // Typed reference to Base Controls' own migration codeunit - see "DXR MCC Adapt BC Phase1"
    // for the full design rationale (dependency+typed-reference pattern, no runtime permission
    // effect, compile-time safety only). Requires Base Controls' app.json to grant MCC
    // internalsVisibleTo (56415 is Access = Internal).
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_BC Migr Phase 2";
    begin
        Phase2.Run();
    end;
}
