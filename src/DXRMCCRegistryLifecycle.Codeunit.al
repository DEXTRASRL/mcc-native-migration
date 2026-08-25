codeunit 60019 "DXR MCC Registry Install"
{
    Subtype = Install;
    Permissions =
        tabledata "DXR MCC Extension" = RIMD,
        tabledata "DXR MCC Concept" = RIMD;

    trigger OnInstallAppPerCompany()
    var
        RegistryLoader: Codeunit "DXR MCC Registry Loader";
    begin
        RegistryLoader.Run();
    end;
}

codeunit 60020 "DXR MCC Registry Upgrade"
{
    Subtype = Upgrade;
    Permissions =
        tabledata "DXR MCC Extension" = RIMD,
        tabledata "DXR MCC Concept" = RIMD;

    trigger OnUpgradePerCompany()
    var
        RegistryLoader: Codeunit "DXR MCC Registry Loader";
    begin
        RegistryLoader.Run();
    end;
}
