codeunit 60216 "DXR MCC VP P1 Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P1-SETUP-20260825.');
    end;
}

codeunit 60217 "DXR MCC VP P1 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P1-MA-20260825.');
    end;
}

codeunit 60218 "DXR MCC VP P2 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P2-MA-20260825.');
    end;
}

codeunit 60219 "DXR MCC VP P2 Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P2-HIST-20260825.');
    end;
}

codeunit 60220 "DXR MCC VP P4 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase4";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P4-MA-20260825.');
    end;
}

codeunit 60221 "DXR MCC VP P4 Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase4";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P4-HIST-20260825.');
    end;
}

codeunit 60222 "DXR MCC VP P7 Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase7";
        Phase1Worker: Codeunit "DXR MCC VP Migr Phase1";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase1Worker.RunSetup();
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P7-SETUP-20260825.');
    end;
}

codeunit 60223 "DXR MCC VP P7 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase7";
        Phase1Worker: Codeunit "DXR MCC VP Migr Phase1";
        Phase2Worker: Codeunit "DXR MCC VP Migr Phase2";
        Phase4Worker: Codeunit "DXR MCC VP Migr Phase4";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase1Worker.RunMaster();
        Phase2Worker.RunMaster();
        Phase4Worker.RunMaster();
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P7-MA-20260825.');
    end;
}

codeunit 60224 "DXR MCC VP P7 Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase7";
        Phase2Worker: Codeunit "DXR MCC VP Migr Phase2";
        Phase3Worker: Codeunit "DXR MCC VP Migr Phase3";
        Phase4Worker: Codeunit "DXR MCC VP Migr Phase4";
        Phase5Worker: Codeunit "DXR MCC VP Migr Phase5";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase2Worker.RunHistoric();
        Phase3Worker.Run();
        Phase4Worker.RunHistoric();
        Phase5Worker.Run();
        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P7-HIST-20260825.');
    end;
}

codeunit 60225 "DXR MCC VP P7 Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase7";
        Phase6Worker: Codeunit "DXR MCC VP Migr Phase6";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase6Worker.Run();
        Worker.RunOther();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P7-OTHER-20260825.');
    end;
}

codeunit 60426 "DXR MCC VP P2 Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P2-ACCOUNTING-20260825.');
    end;
}

codeunit 60427 "DXR MCC VP P7 Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC VP Migr Phase7";
        Phase2Worker: Codeunit "DXR MCC VP Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase2Worker.RunAccounting();
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-VP-P7-ACCOUNTING-20260825.');
    end;
}
