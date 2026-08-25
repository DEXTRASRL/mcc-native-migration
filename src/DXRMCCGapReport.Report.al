report 60040 "DXR MCC Extension Gap Report"
{
    Caption = 'DXR MCC Extension Gap Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Extension; "DXR MCC Extension")
        {
            RequestFilterFields = Code;

            trigger OnAfterGetRecord()
            var
                Concept: Record "DXR MCC Concept";
                SumOld: Integer;
                SumMigrated: Integer;
                SumGap: Integer;
                TotalConcepts2: Integer;
                NotRunCount: Integer;
                ErrorCount: Integer;
                GapCount: Integer;
                Line: Text;
            begin
                Concept.SetRange("Extension Code", Extension.Code);
                Concept.SetRange(Retired, false);
                if Concept.FindSet() then
                    repeat
                        TotalConcepts2 += 1;
                        SumOld += Concept."Old Record Count";
                        SumMigrated += Concept."Migrated Record Count";
                        SumGap += Concept.Gap;
                        case Concept.Status of
                            Concept.Status::"Not Counted", Concept.Status::Pending:
                                NotRunCount += 1;
                            Concept.Status::Error:
                                ErrorCount += 1;
                            Concept.Status::"Completed With Gaps":
                                GapCount += 1;
                        end;
                    until Concept.Next() = 0;

                Line := StrSubstNo(
                    '%1 (%2) | Order %3 | Concepts: %4 | Old: %5 | Migrated: %6 | Gap: %7 | Not Run: %8 | Gaps: %9 | Errors: %10%11',
                    Extension.Name, Extension.Code, Extension."Order No.", TotalConcepts2, SumOld, SumMigrated, SumGap,
                    NotRunCount, GapCount, ErrorCount,
                    '');
                if Extension.Notes <> '' then
                    Line += '\Notes: ' + Extension.Notes;

                ReportLines += Line + '\-----';
            end;

            trigger OnPostDataItem()
            begin
                if ReportLines <> '' then
                    Message(ReportLines);
            end;
        }
    }

    var
        ReportLines: Text;
}
