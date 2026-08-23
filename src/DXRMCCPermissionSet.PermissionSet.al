permissionset 60000 "DXR MCC"
{
    Caption = 'DXR Migration Control Center';
    Assignable = true;
    Access = Public;

    Permissions =
        table "DXR MCC Extension" = X,
        table "DXR MCC Concept" = X,
        table "DXR MCC Run Log" = X,
        table "DXR MCC Run Request" = X,
        table "DXR MCC Migration Lock" = X,
        tabledata "DXR MCC Extension" = RIMD,
        tabledata "DXR MCC Concept" = RIMD,
        tabledata "DXR MCC Run Log" = RIMD,
        tabledata "DXR MCC Run Request" = RIMD,
        tabledata "DXR MCC Migration Lock" = RIMD,
        codeunit "DXR MCC Counter" = X,
        codeunit "DXR MCC Executor" = X,
        codeunit "DXR MCC Registry Loader" = X,
        codeunit "DXR MCC Background Runner" = X,
        codeunit "DXR MCC Upgrade Tag Mgt" = X,
        codeunit "DXR MCC Fallback Migrator" = X,
        codeunit "DXR MCC Migration Lock Mgt." = X,
        codeunit "DXR MCC Completion Notify" = X,
        codeunit "DXR MCC Upgrade Tag Seed" = X,
        page "DXR Migration Control Center" = X,
        page "DXR MCC Concept Subform" = X,
        page "DXR MCC Run Log" = X,
        page "DXR MCC Run Requests" = X,
        page "DXR MCC Table Map" = X,
        report "DXR MCC Extension Gap Report" = X;
}
