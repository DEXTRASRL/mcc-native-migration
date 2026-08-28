codeunit 60450 "DXR MCC Master Customer"
{
    // Motor por tabla (piloto) - reemplaza 7 recorridos independientes de Customer (BELLON, BC,
    // DESB, DRLOC, PCM, SD, TU) por uno solo. Ver docs/superpowers/specs/2026-08-27-master-by-
    // table-design.md. El codigo de cada bloque se MOVIO (no se duplico) desde su origen; el
    // procedimiento origen queda como no-op documentado porque otras rutas (RunMaster/RunConcept/
    // dispatchers por extension) todavia lo invocan.
    //
    // ApplyTU NO se movio en este piloto (ver task-3-report.md): su fuente,
    // "DXR MCC TU Migr Dispatcher".MigrateOriginalCustomerFields(), (a) tenia trabajo sin
    // commitear ajeno a esta tarea en ese mismo archivo y en "DXR MCC TU Category Workers"
    // (fix de tag de produccion, no relacionado a Customer) al momento de esta tarea, y (b) usa
    // RecordRef + "DXR MCC Master Field Resolver".CopyFirstPopulatedField (tambien con cambios
    // sin commitear ajenos), no asignacion tipada campo a campo - no encaja en el contrato
    // ApplyXXX(var Customer: Record Customer): Boolean sin rediseñar esa llamada. El propio scan
    // de TU sobre Customer sigue corriendo por separado hasta una tarea de seguimiento.
    //
    // ADVERTENCIA para las 58 tablas restantes de este patron (fix 2026-08-27, ronda 1/5 de
    // revision): al vaciar un procedimiento origen a no-op, revisa si ese procedimiento fijaba un
    // upgrade tag INTERNO (UpgradeTag.SetUpgradeTag(...) dentro de su propio cuerpo, no el de un
    // llamador externo) y si ese literal esta seedeado en "DXR MCC Upgrade Tag Seed"
    // (src/DXRMCCUpgradeTagSeed.Codeunit.al) - un SeedIfBlank apuntando a un tag que ya nadie fija
    // deja "Force Rerun" de esa fila del dashboard buscando un tag muerto: no rompe nada al
    // ejecutarse, pero la entrada queda huerfana y engañosa para el operador. Si esta seedeado,
    // reapunta el seed al tag nuevo del motor por tabla (p.ej. DXR-MCC-MASTER-<TABLA>-20260827) con
    // un comentario que explique el porque; si no esta seedeado, basta con dejar constancia (no
    // hay nada colgando en el dashboard). Verificalo con grep sobre el literal exacto en TODO el
    // repo, no de memoria - un guard EXTERNO (en el llamador, no dentro del procedimiento vaciado)
    // sigue corriendo igual y no necesita este tratamiento.
    Permissions = tabledata Customer = RM;

    trigger OnRun()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(MasterTag()) then
            exit;
        MigrateCustomer();
        UpgradeTag.SetUpgradeTag(MasterTag());
    end;

    local procedure MasterTag(): Code[250]
    begin
        exit('DXR-MCC-MASTER-CUSTOMER-20260827');
    end;

    local procedure MigrateCustomer()
    var
        Customer: Record Customer;
        CustomerToUpdate: Record Customer;
        RowsSinceCommit: Integer;
    begin
        Customer.SetLoadFields("No.", "Tipo NCF_DXR",
            "DxTipo NCF", "Utiliza NCF_DXR", "DxUtiliza NCF", "Tipo Identificacion_DXR", "DXTipo Identificacion",
            "Razon Social_DXR", "DxRazon Social", "Nombre Comercial_DXR", "DxNombre Comercial", "Tipo Negocio_DXR",
            "DxTipo Negocio", "Fecha Constitucion_DXR", "DxFecha Constitucion", "Estatus_DXR", "DxEstatus",
            "Fecha Act. DGII_DXR", "DxFecha Act. DGII", "Tax Identification Type_DXR", "DxTax Identification Type",
            "Proveedor Tarjeta Cr._DXR", "DxProveedor Tarjeta Cr.", "International Customer_DXR",
            "DX International Customer", "Uses Withholding_DXR", "DX Uses Withholding", "Bank Commission_DXR",
            "DX Bank Commission", "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS", "Cod. Retencion ISR_DXR",
            "DXCod. Retencion ISR", "Bank Commission Account_DXR", "DX Bank Commission Account",
            "Def ITBIS Withhold_DXR", "DXDefault ITBIS Withholding", "Default ISR Withholding_DXR",
            "DXDefault ISR Withholding", "Apply Cust Withhold_DXR", "DX Apply Customer Withholding");
        if not Customer.FindSet(false) then
            exit;
        repeat
            if RowNeedsWork(Customer) then
                if CustomerToUpdate.Get(Customer."No.") then
                    if RowNeedsWork(CustomerToUpdate) then begin
                        CustomerToUpdate.Modify(false);
                        RowsSinceCommit += 1;
                        if RowsSinceCommit >= 500 then begin
                            Commit();
                            RowsSinceCommit := 0;
                        end;
                    end;
        until Customer.Next() = 0;

        if RowsSinceCommit > 0 then
            Commit();
    end;

    local procedure RowNeedsWork(var Customer: Record Customer): Boolean
    var
        Changed: Boolean;
    begin
        Changed := ApplyDRLOC(Customer) or Changed;
        exit(Changed);
    end;

    local procedure ApplyDRLOC(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if
            (Customer."Tipo NCF_DXR" <> Customer."DxTipo NCF") or
           (Customer."Utiliza NCF_DXR" <> Customer."DxUtiliza NCF") or
           (Customer."Tipo Identificacion_DXR" <> Customer."DXTipo Identificacion") or
           (Customer."Razon Social_DXR" <> Customer."DxRazon Social") or
           (Customer."Nombre Comercial_DXR" <> Customer."DxNombre Comercial") or
           (Customer."Tipo Negocio_DXR" <> Customer."DxTipo Negocio") or
           (Customer."Fecha Constitucion_DXR" <> Customer."DxFecha Constitucion") or
           (Customer."Estatus_DXR" <> Customer."DxEstatus") or
           (Customer."Fecha Act. DGII_DXR" <> Customer."DxFecha Act. DGII") or
           (Customer."Tax Identification Type_DXR" <> Customer."DxTax Identification Type") or
           (Customer."Proveedor Tarjeta Cr._DXR" <> Customer."DxProveedor Tarjeta Cr.") or
           (Customer."International Customer_DXR" <> Customer."DX International Customer") or
           (Customer."Uses Withholding_DXR" <> Customer."DX Uses Withholding") or
           (Customer."Bank Commission_DXR" <> Customer."DX Bank Commission") or
           (Customer."Cod. Retencion ITBIS_DXR" <> Customer."DXCod. Retencion ITBIS") or
           (Customer."Cod. Retencion ISR_DXR" <> Customer."DXCod. Retencion ISR") or
           (Customer."Bank Commission Account_DXR" <> Customer."DX Bank Commission Account") or
           (Customer."Def ITBIS Withhold_DXR" <> Customer."DXDefault ITBIS Withholding") or
           (Customer."Default ISR Withholding_DXR" <> Customer."DXDefault ISR Withholding") or
           (Customer."Apply Cust Withhold_DXR" <> Customer."DX Apply Customer Withholding")
        then begin
            if Customer."Tipo NCF_DXR" = Blank."Tipo NCF_DXR" then begin
                Customer."Tipo NCF_DXR" := Customer."DxTipo NCF";
                Changed := true;
            end;
            if Customer."Utiliza NCF_DXR" = Blank."Utiliza NCF_DXR" then begin
                Customer."Utiliza NCF_DXR" := Customer."DxUtiliza NCF";
                Changed := true;
            end;
            if Customer."Tipo Identificacion_DXR" = Blank."Tipo Identificacion_DXR" then begin
                Customer."Tipo Identificacion_DXR" := Customer."DXTipo Identificacion";
                Changed := true;
            end;
            if Customer."Razon Social_DXR" = Blank."Razon Social_DXR" then begin
                Customer."Razon Social_DXR" := Customer."DxRazon Social";
                Changed := true;
            end;
            if Customer."Nombre Comercial_DXR" = Blank."Nombre Comercial_DXR" then begin
                Customer."Nombre Comercial_DXR" := Customer."DxNombre Comercial";
                Changed := true;
            end;
            if Customer."Tipo Negocio_DXR" = Blank."Tipo Negocio_DXR" then begin
                Customer."Tipo Negocio_DXR" := Customer."DxTipo Negocio";
                Changed := true;
            end;
            if Customer."Fecha Constitucion_DXR" = Blank."Fecha Constitucion_DXR" then begin
                Customer."Fecha Constitucion_DXR" := Customer."DxFecha Constitucion";
                Changed := true;
            end;
            if Customer."Estatus_DXR" = Blank."Estatus_DXR" then begin
                Customer."Estatus_DXR" := Customer."DxEstatus";
                Changed := true;
            end;
            if Customer."Fecha Act. DGII_DXR" = Blank."Fecha Act. DGII_DXR" then begin
                Customer."Fecha Act. DGII_DXR" := Customer."DxFecha Act. DGII";
                Changed := true;
            end;
            if Customer."Tax Identification Type_DXR" = Blank."Tax Identification Type_DXR" then begin
                Customer."Tax Identification Type_DXR" := Customer."DxTax Identification Type";
                Changed := true;
            end;
            if Customer."Proveedor Tarjeta Cr._DXR" = Blank."Proveedor Tarjeta Cr._DXR" then begin
                Customer."Proveedor Tarjeta Cr._DXR" := Customer."DxProveedor Tarjeta Cr.";
                Changed := true;
            end;
            if Customer."International Customer_DXR" = Blank."International Customer_DXR" then begin
                Customer."International Customer_DXR" := Customer."DX International Customer";
                Changed := true;
            end;
            if Customer."Uses Withholding_DXR" = Blank."Uses Withholding_DXR" then begin
                Customer."Uses Withholding_DXR" := Customer."DX Uses Withholding";
                Changed := true;
            end;
            if Customer."Bank Commission_DXR" = Blank."Bank Commission_DXR" then begin
                Customer."Bank Commission_DXR" := Customer."DX Bank Commission";
                Changed := true;
            end;
            if Customer."Cod. Retencion ITBIS_DXR" = Blank."Cod. Retencion ITBIS_DXR" then begin
                Customer."Cod. Retencion ITBIS_DXR" := Customer."DXCod. Retencion ITBIS";
                Changed := true;
            end;
            if Customer."Cod. Retencion ISR_DXR" = Blank."Cod. Retencion ISR_DXR" then begin
                Customer."Cod. Retencion ISR_DXR" := Customer."DXCod. Retencion ISR";
                Changed := true;
            end;
            if Customer."Bank Commission Account_DXR" = Blank."Bank Commission Account_DXR" then begin
                Customer."Bank Commission Account_DXR" := Customer."DX Bank Commission Account";
                Changed := true;
            end;
            if Customer."Def ITBIS Withhold_DXR" = Blank."Def ITBIS Withhold_DXR" then begin
                Customer."Def ITBIS Withhold_DXR" := Customer."DXDefault ITBIS Withholding";
                Changed := true;
            end;
            if Customer."Default ISR Withholding_DXR" = Blank."Default ISR Withholding_DXR" then begin
                Customer."Default ISR Withholding_DXR" := Customer."DXDefault ISR Withholding";
                Changed := true;
            end;
            if Customer."Apply Cust Withhold_DXR" = Blank."Apply Cust Withhold_DXR" then begin
                Customer."Apply Cust Withhold_DXR" :=
                    "Apply Cust Withhold_DXR".FromInteger(Customer."DX Apply Customer Withholding".AsInteger());
                Changed := true;
            end;
        end;
        exit(Changed);
    end;
}
