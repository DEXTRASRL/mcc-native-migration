#if not ESCUDEA and not BCDX
codeunit 60234 "DXR MCC TU Setup"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC TU Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunSetup();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-TU-SETUP-20260825.');
    end;
}

codeunit 60235 "DXR MCC TU Master"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC TU Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunMaster();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    /// <summary>
    /// Fixed 2026-08-27 (CONFIRMADO en produccion, corrida de 59 minutos que termino en Error):
    /// este worker de categoria reutilizaba el MISMO tag que "DXR MCC TU Migr Dispatcher" usa
    /// internamente en RunMaster() (MasterOriginalFieldsMigrationTag). Secuencia real: el worker
    /// comprueba el tag -> falso -> llama RunMaster() -> RunMaster comprueba el mismo tag -> falso
    /// -> migra -> PONE el tag -> vuelve aqui -> este SetUpgradeTag lo pone OTRA VEZ y la plataforma
    /// lanza "The record in table Upgrade Tags already exists".
    /// Es decir: la migracion se completaba y despues reventaba en el insert redundante, la corrida
    /// se reportaba Failed y volvia a repetirse entera en cada intento.
    /// Ahora tiene tag propio, igual que sus hermanos "DXR MCC TU Setup" y "DXR MCC TU Accounting",
    /// que si lo tenian distinto. En un tenant donde el tag interno ya quedo puesto, este worker
    /// vuelve a llamar RunMaster(), la guarda interna salta, y se pone este tag nuevo: rapido y
    /// sin reescribir nada.
    /// </summary>
    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-TU-MASTER-20260827.');
    end;
}

codeunit 60430 "DXR MCC TU Accounting"
{
    trigger OnRun()
    var
        Worker: Codeunit "DXR MCC TU Migr Dispatcher";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(Tag()) then
            exit;
        Worker.RunAccounting();
        UpgradeTag.SetUpgradeTag(Tag());
    end;

    local procedure Tag(): Code[250]
    begin
        exit('DXR-MCC-TU-ACCOUNTING-20260825.');
    end;
}

#endif
