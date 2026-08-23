codeunit 60037 "DXR MCC Adapt TU Dispatcher"
{
    // Typed reference to TransUnion's own migration dispatcher (2026-08-23, portfolio-wide
    // dependency + typed-reference design pattern - see SD/DXP adapters for the full rationale;
    // compile-time safety only, no runtime permission effect). Requires TransUnion's app.json to
    // grant MCC internalsVisibleTo (53605 is Access = Internal).
    trigger OnRun()
    var
        Dispatcher: Codeunit "DXR_TU Migr Dispatcher";
    begin
        Dispatcher.Run();
    end;
}
