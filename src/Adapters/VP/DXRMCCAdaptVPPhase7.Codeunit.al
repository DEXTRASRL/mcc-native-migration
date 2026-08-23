codeunit 60032 "DXR MCC Adapt VP Phase7"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale. Phase 7's own merge logic is table-level "fill gaps, never
    // overwrite" (Discovery, confirmed already correct/safe) - restores the same 23 destination
    // tables as Phase 1-6 (gen-1) from a newer legacy generation, safe to run in either order
    // relative to them.
    trigger OnRun()
    var
        Phase7: Codeunit "DXR_VP Migration Phase7 IdCut";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase7.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
