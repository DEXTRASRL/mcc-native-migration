codeunit 60028 "DXR MCC Adapt VP Phase3"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale.
    trigger OnRun()
    var
        Phase3: Codeunit "DXR_VP Migration Phase3 PayldH";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase3.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
