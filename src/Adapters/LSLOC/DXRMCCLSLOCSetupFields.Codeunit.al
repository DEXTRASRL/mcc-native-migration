codeunit 60172 "DXR MCC LSLOC Hospitality"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC LSLOC Migr ToDXRLS";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag('DXR-MCC-LSLOC-HOSPITALITY-20260825.') then
            exit;
        Worker.RunHospitalityTypeFields();
        UpgradeTag.SetUpgradeTag('DXR-MCC-LSLOC-HOSPITALITY-20260825.');
    end;
}
