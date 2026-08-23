codeunit 60027 "DXR MCC Adapt VP Phase2"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale, including why this calls the phase directly rather than
    // going through "DXR_VP Migration Dispatcher".
    trigger OnRun()
    var
        Phase2: Codeunit "DXR_VP Migration Phase2 PayldC";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase2.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
