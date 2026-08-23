codeunit 60030 "DXR MCC Adapt VP Phase5"
{
    // Typed reference to Vendor Payloads' own migration codeunit - see "DXR MCC Adapt VP Phase1"
    // for the full design rationale.
    trigger OnRun()
    var
        Phase5: Codeunit "DXR_VP Migration Phase5 LogsAP";
        ProgressCount: Integer;
        TotalCount: Integer;
        ErrorText: Text;
    begin
        if not Phase5.Run(ProgressCount, TotalCount, ErrorText) then
            Error(ErrorText);
    end;
}
