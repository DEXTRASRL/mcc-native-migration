codeunit 60173 "DXR MCC LSLOC Setup Rel."
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-SETUPRELATIONS-20260825.') then
            exit;
        Worker.RunSetupRelations();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-SETUPRELATIONS-20260825.');
    end;
}
