codeunit 60226 "DXR MCC PCM P2 Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P2-SETUP-20260825.');
    end;
}

codeunit 60227 "DXR MCC PCM P2 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P2-MA-20260825.');
    end;
}

codeunit 60228 "DXR MCC PCM P3 Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase3";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P3-SETUP-20260825.');
    end;
}

codeunit 60229 "DXR MCC PCM P3 Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase3";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunOther();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P3-OTHER-20260825.');
    end;
}

codeunit 60230 "DXR MCC PCM P5 Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase5";
        Phase2Worker: Codeunit "DXR MCC PCM Migr Phase2";
        Phase3Worker: Codeunit "DXR MCC PCM Migr Phase3";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase2Worker.RunSetup();
        Phase3Worker.RunSetup();
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P5-SETUP-20260825.');
    end;
}

codeunit 60231 "DXR MCC PCM P5 Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase5";
        Phase2Worker: Codeunit "DXR MCC PCM Migr Phase2";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase2Worker.RunMaster();
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P5-MA-20260825.');
    end;
}

codeunit 60232 "DXR MCC PCM P5 Historic"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase5";
        Phase3Worker: Codeunit "DXR MCC PCM Migr Phase3";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunHistoric();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P5-HIST-20260825.');
    end;
}

codeunit 60233 "DXR MCC PCM P5 Other"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase5";
        Phase3Worker: Codeunit "DXR MCC PCM Migr Phase3";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase3Worker.RunOther();
        Worker.RunOther();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P5-OTHER-20260825.');
    end;
}

codeunit 60428 "DXR MCC PCM P4 Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase4";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.Run();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P4-ACCOUNTING-20260825.');
    end;
}

codeunit 60429 "DXR MCC PCM P5 Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC PCM Migr Phase5";
        Phase4Worker: Codeunit "DXR MCC PCM Migr Phase4";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Phase4Worker.Run();
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-PCM-P5-ACCOUNTING-20260825.');
    end;
}
