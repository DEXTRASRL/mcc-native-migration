codeunit 60029 "DXR MCC Adapt VP Phase4"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale.
    trigger OnRun()
    var
        Phase4: Codeunit "DXR_VP Migration Phase4 Benef";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase4.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
