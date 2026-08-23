codeunit 60031 "DXR MCC Adapt VP Phase6"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale.
    trigger OnRun()
    var
        Phase6: Codeunit "DXR_VP Migration Phase6 FldCut";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase6.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
