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
        Customer.SetLoadFields("No.", "Dirección Representante_DXR", "Dirección Representante",
            "Sector Representante_DXR", "Sector Representante", "Cédula Representante_DXR", "Cédula Representante",
            "Cumpl Representante_DXR", "Cumpleaños Representante", "Celular Representante_DXR",
            "Celular Representante", "E-Mail Representante_DXR.", "E-Mail Representante", "Código Cobrador_DXR",
            "Código Cobrador", "Requiere OC_DXR", "Requiere OC", "Tipo de Cliente_DXR", "Tipo de Cliente",
            "Frecuencia Visita_DXR", "Frecuencia Visita", "Secuencia Visita_DXR", "Secuencia Visita",
            "Días Visita_DXR", "Días Visita", "Carnet DGII_DXR", "Carnet DGII", "Cobrar Interés_DXR",
            "Cobrar Interés", "% Interés_DXR", "% Interés", "Carnet Exención ITBIS_DXR", "Carnet Exención ITBIS",
            "Vencimiento Carnet_DXR", "Vencimiento Carnet", "Enc. Compras Nombre_DXR", "Enc. Compras Nombre",
            "Enc. Compras Email_DXR.", "Enc. Compras email", "Enc. Compras celular_DXR", "Enc. Compras celular",
            "Enc. Compras Cumpleaños_DXR", "Enc. Compras Cumpleaños", "Enc. Pagos Nombre_DXR", "Enc. Pagos Nombre",
            "Enc. Pagos Email_DXR.", "Enc. Pagos email", "Enc. Pagos celular_DXR", "Enc. Pagos celular",
            "Enc. Pagos Cumpleaños_DXR", "Enc. Pagos Cumpleaños", "Frecuencia de Pago_DXR", "Frecuencia de Pago",
            "Apartado Postal_DXR", "Apartado Postal", "Sector_DXR", "Municipio_DXR", "Provincia_DXR",
            "Comision_Tipo_ID_DXR.", "Deuda Pico_DXR", "Deuda Pico", "Fecha Deuda Pico_DXR", "Fecha Deuda Pico",
            "Gestor_ID_DXR.", "Fecha envio edo cuenta_DXR", "Fecha envio estado cuenta",
            "Invoice Expiration Days_DXR", "Invoice Expiration Days", "Enc. Recepcion Email_DXR.",
            "Enc. Recepcion Email", "StoreID_DXR.", "Tipo Segmento_DXR", "Tipo Segmento",
            "Monto Deposito Cilindr_DXR", "Monto Deposito - Cilindros", "Cant asig - Cilindros_DXR",
            "Cantidad asignar - Cilindros", "Cliente Cilindros_DXR", "Cliente Cilindros", "Fecha Exp Reg Merc_DXR",
            "Fecha Expiracion Reg Mercantil", "B2C Customer_DXR", "B2C Customer", "Last Date/Time Modified_DXR",
            "Last Date/Time Modified", "Req Fecha Reg Merc_DXR", "Requiere Fecha Reg. Mercantil",
            "Mandatory Order No._DXR", "Mandatory Order No._Old", "Exp. Exemption Card_DXR",
            "Exp. Exemption Card_Old", "Reference Address_DXR", "Reference Address_Old",
            "Clasific. Cliente ABC_DXR", "DXR-DE Clasific. Cliente ABC", "Ruta_DXR", "DXR-DE Ruta", "Tipo NCF_DXR",
            "DxTipo NCF", "Utiliza NCF_DXR", "DxUtiliza NCF", "Tipo Identificacion_DXR", "DXTipo Identificacion",
            "Razon Social_DXR", "DxRazon Social", "Nombre Comercial_DXR", "DxNombre Comercial", "Tipo Negocio_DXR",
            "DxTipo Negocio", "Fecha Constitucion_DXR", "DxFecha Constitucion", "Estatus_DXR", "DxEstatus",
            "Fecha Act. DGII_DXR", "DxFecha Act. DGII", "Tax Identification Type_DXR", "DxTax Identification Type",
            "Proveedor Tarjeta Cr._DXR", "DxProveedor Tarjeta Cr.", "International Customer_DXR",
            "DX International Customer", "Uses Withholding_DXR", "DX Uses Withholding", "Bank Commission_DXR",
            "DX Bank Commission", "Cod. Retencion ITBIS_DXR", "DXCod. Retencion ITBIS", "Cod. Retencion ISR_DXR",
            "DXCod. Retencion ISR", "Bank Commission Account_DXR", "DX Bank Commission Account",
            "Def ITBIS Withhold_DXR", "DXDefault ITBIS Withholding", "Default ISR Withholding_DXR",
            "DXDefault ISR Withholding", "Apply Cust Withhold_DXR", "DX Apply Customer Withholding", "PRC Store",
            "PRC Store_DXR", "Special Dispatch_DXR", "Special Dispatch DXR", Sector, Municipio, Provincia,
            Comision_Tipo_ID, Gestor_ID, StoreId);
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
        Changed := ApplyBELLON(Customer) or Changed;
        Changed := ApplyBC(Customer) or Changed;
        Changed := ApplyDESB(Customer) or Changed;
        Changed := ApplyDRLOC(Customer) or Changed;
        Changed := ApplyPCM(Customer) or Changed;
        Changed := ApplySD(Customer) or Changed;
        exit(Changed);
    end;

    local procedure ApplyBELLON(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if
            (Customer."Dirección Representante_DXR" <> Customer."Dirección Representante") or
           (Customer."Sector Representante_DXR" <> Customer."Sector Representante") or
           (Customer."Cédula Representante_DXR" <> Customer."Cédula Representante") or
           (Customer."Cumpl Representante_DXR" <> Customer."Cumpleaños Representante") or
           (Customer."Celular Representante_DXR" <> Customer."Celular Representante") or
           (Customer."E-Mail Representante_DXR." <> Customer."E-Mail Representante") or
           (Customer."Código Cobrador_DXR" <> Customer."Código Cobrador") or
           (Customer."Requiere OC_DXR" <> Customer."Requiere OC") or
           (Customer."Tipo de Cliente_DXR" <> Customer."Tipo de Cliente") or
           (Customer."Frecuencia Visita_DXR" <> Customer."Frecuencia Visita") or
           (Customer."Secuencia Visita_DXR" <> Customer."Secuencia Visita") or
           (Customer."Días Visita_DXR" <> Customer."Días Visita") or
           (Customer."Carnet DGII_DXR" <> Customer."Carnet DGII") or
           (Customer."Cobrar Interés_DXR" <> Customer."Cobrar Interés") or
           (Customer."% Interés_DXR" <> Customer."% Interés") or
           (Customer."Carnet Exención ITBIS_DXR" <> Customer."Carnet Exención ITBIS") or
           (Customer."Vencimiento Carnet_DXR" <> Customer."Vencimiento Carnet") or
           (Customer."Enc. Compras Nombre_DXR" <> Customer."Enc. Compras Nombre") or
           (Customer."Enc. Compras Email_DXR." <> Customer."Enc. Compras email") or
           (Customer."Enc. Compras celular_DXR" <> Customer."Enc. Compras celular") or
           (Customer."Enc. Compras Cumpleaños_DXR" <> Customer."Enc. Compras Cumpleaños") or
           (Customer."Enc. Pagos Nombre_DXR" <> Customer."Enc. Pagos Nombre") or
           (Customer."Enc. Pagos Email_DXR." <> Customer."Enc. Pagos email") or
           (Customer."Enc. Pagos celular_DXR" <> Customer."Enc. Pagos celular") or
           (Customer."Enc. Pagos Cumpleaños_DXR" <> Customer."Enc. Pagos Cumpleaños") or
           (Customer."Frecuencia de Pago_DXR" <> Customer."Frecuencia de Pago") or
           (Customer."Apartado Postal_DXR" <> Customer."Apartado Postal") or
           (Customer."Sector_DXR" <> Customer.Sector) or
           (Customer."Municipio_DXR" <> Customer.Municipio) or
           (Customer."Provincia_DXR" <> Customer.Provincia) or
           (Customer."Comision_Tipo_ID_DXR." <> Customer.Comision_Tipo_ID) or
           (Customer."Deuda Pico_DXR" <> Customer."Deuda Pico") or
           (Customer."Fecha Deuda Pico_DXR" <> Customer."Fecha Deuda Pico") or
           (Customer."Gestor_ID_DXR." <> Customer.Gestor_ID) or
           (Customer."Fecha envio edo cuenta_DXR" <> Customer."Fecha envio estado cuenta") or
           (Customer."Invoice Expiration Days_DXR" <> Customer."Invoice Expiration Days") or
           (Customer."Enc. Recepcion Email_DXR." <> Customer."Enc. Recepcion Email") or
           (Customer."StoreID_DXR." <> Customer.StoreId) or
           (Customer."Tipo Segmento_DXR" <> Customer."Tipo Segmento") or
           (Customer."Monto Deposito Cilindr_DXR" <> Customer."Monto Deposito - Cilindros") or
           (Customer."Cant asig - Cilindros_DXR" <> Customer."Cantidad asignar - Cilindros") or
           (Customer."Cliente Cilindros_DXR" <> Customer."Cliente Cilindros") or
           (Customer."Fecha Exp Reg Merc_DXR" <> Customer."Fecha Expiracion Reg Mercantil") or
           (Customer."B2C Customer_DXR" <> Customer."B2C Customer") or
           (Customer."Last Date/Time Modified_DXR" <> Customer."Last Date/Time Modified") or
           (Customer."Req Fecha Reg Merc_DXR" <> Customer."Requiere Fecha Reg. Mercantil")
        then begin
            if Customer."Dirección Representante_DXR" = Blank."Dirección Representante_DXR" then begin
                Customer."Dirección Representante_DXR" := Customer."Dirección Representante";
                Changed := true;
            end;
            if Customer."Sector Representante_DXR" = Blank."Sector Representante_DXR" then begin
                Customer."Sector Representante_DXR" := Customer."Sector Representante";
                Changed := true;
            end;
            if Customer."Cédula Representante_DXR" = Blank."Cédula Representante_DXR" then begin
                Customer."Cédula Representante_DXR" := Customer."Cédula Representante";
                Changed := true;
            end;
            if Customer."Cumpl Representante_DXR" = Blank."Cumpl Representante_DXR" then begin
                Customer."Cumpl Representante_DXR" := Customer."Cumpleaños Representante";
                Changed := true;
            end;
            if Customer."Celular Representante_DXR" = Blank."Celular Representante_DXR" then begin
                Customer."Celular Representante_DXR" := Customer."Celular Representante";
                Changed := true;
            end;
            if Customer."E-Mail Representante_DXR." = Blank."E-Mail Representante_DXR." then begin
                Customer."E-Mail Representante_DXR." := Customer."E-Mail Representante";
                Changed := true;
            end;
            if Customer."Código Cobrador_DXR" = Blank."Código Cobrador_DXR" then begin
                Customer."Código Cobrador_DXR" := Customer."Código Cobrador";
                Changed := true;
            end;
            if Customer."Requiere OC_DXR" = Blank."Requiere OC_DXR" then begin
                Customer."Requiere OC_DXR" := Customer."Requiere OC";
                Changed := true;
            end;
            if Customer."Tipo de Cliente_DXR" = Blank."Tipo de Cliente_DXR" then begin
                Customer."Tipo de Cliente_DXR" := Customer."Tipo de Cliente";
                Changed := true;
            end;
            if Customer."Frecuencia Visita_DXR" = Blank."Frecuencia Visita_DXR" then begin
                Customer."Frecuencia Visita_DXR" := Customer."Frecuencia Visita";
                Changed := true;
            end;
            if Customer."Secuencia Visita_DXR" = Blank."Secuencia Visita_DXR" then begin
                Customer."Secuencia Visita_DXR" := Customer."Secuencia Visita";
                Changed := true;
            end;
            if Customer."Días Visita_DXR" = Blank."Días Visita_DXR" then begin
                Customer."Días Visita_DXR" := Customer."Días Visita";
                Changed := true;
            end;
            if Customer."Carnet DGII_DXR" = Blank."Carnet DGII_DXR" then begin
                Customer."Carnet DGII_DXR" := Customer."Carnet DGII";
                Changed := true;
            end;
            if Customer."Cobrar Interés_DXR" = Blank."Cobrar Interés_DXR" then begin
                Customer."Cobrar Interés_DXR" := Customer."Cobrar Interés";
                Changed := true;
            end;
            if Customer."% Interés_DXR" = Blank."% Interés_DXR" then begin
                Customer."% Interés_DXR" := Customer."% Interés";
                Changed := true;
            end;
            if Customer."Carnet Exención ITBIS_DXR" = Blank."Carnet Exención ITBIS_DXR" then begin
                Customer."Carnet Exención ITBIS_DXR" := Customer."Carnet Exención ITBIS";
                Changed := true;
            end;
            if Customer."Vencimiento Carnet_DXR" = Blank."Vencimiento Carnet_DXR" then begin
                Customer."Vencimiento Carnet_DXR" := Customer."Vencimiento Carnet";
                Changed := true;
            end;
            if Customer."Enc. Compras Nombre_DXR" = Blank."Enc. Compras Nombre_DXR" then begin
                Customer."Enc. Compras Nombre_DXR" := Customer."Enc. Compras Nombre";
                Changed := true;
            end;
            if Customer."Enc. Compras Email_DXR." = Blank."Enc. Compras Email_DXR." then begin
                Customer."Enc. Compras Email_DXR." := Customer."Enc. Compras email";
                Changed := true;
            end;
            if Customer."Enc. Compras celular_DXR" = Blank."Enc. Compras celular_DXR" then begin
                Customer."Enc. Compras celular_DXR" := Customer."Enc. Compras celular";
                Changed := true;
            end;
            if Customer."Enc. Compras Cumpleaños_DXR" = Blank."Enc. Compras Cumpleaños_DXR" then begin
                Customer."Enc. Compras Cumpleaños_DXR" := Customer."Enc. Compras Cumpleaños";
                Changed := true;
            end;
            if Customer."Enc. Pagos Nombre_DXR" = Blank."Enc. Pagos Nombre_DXR" then begin
                Customer."Enc. Pagos Nombre_DXR" := Customer."Enc. Pagos Nombre";
                Changed := true;
            end;
            if Customer."Enc. Pagos Email_DXR." = Blank."Enc. Pagos Email_DXR." then begin
                Customer."Enc. Pagos Email_DXR." := Customer."Enc. Pagos email";
                Changed := true;
            end;
            if Customer."Enc. Pagos celular_DXR" = Blank."Enc. Pagos celular_DXR" then begin
                Customer."Enc. Pagos celular_DXR" := Customer."Enc. Pagos celular";
                Changed := true;
            end;
            if Customer."Enc. Pagos Cumpleaños_DXR" = Blank."Enc. Pagos Cumpleaños_DXR" then begin
                Customer."Enc. Pagos Cumpleaños_DXR" := Customer."Enc. Pagos Cumpleaños";
                Changed := true;
            end;
            if Customer."Frecuencia de Pago_DXR" = Blank."Frecuencia de Pago_DXR" then begin
                Customer."Frecuencia de Pago_DXR" := Customer."Frecuencia de Pago";
                Changed := true;
            end;
            if Customer."Apartado Postal_DXR" = Blank."Apartado Postal_DXR" then begin
                Customer."Apartado Postal_DXR" := Customer."Apartado Postal";
                Changed := true;
            end;
            if Customer."Sector_DXR" = Blank."Sector_DXR" then begin
                Customer."Sector_DXR" := Customer.Sector;
                Changed := true;
            end;
            if Customer."Municipio_DXR" = Blank."Municipio_DXR" then begin
                Customer."Municipio_DXR" := Customer.Municipio;
                Changed := true;
            end;
            if Customer."Provincia_DXR" = Blank."Provincia_DXR" then begin
                Customer."Provincia_DXR" := Customer.Provincia;
                Changed := true;
            end;
            if Customer."Comision_Tipo_ID_DXR." = Blank."Comision_Tipo_ID_DXR." then begin
                Customer."Comision_Tipo_ID_DXR." := Customer.Comision_Tipo_ID;
                Changed := true;
            end;
            if Customer."Deuda Pico_DXR" = Blank."Deuda Pico_DXR" then begin
                Customer."Deuda Pico_DXR" := Customer."Deuda Pico";
                Changed := true;
            end;
            if Customer."Fecha Deuda Pico_DXR" = Blank."Fecha Deuda Pico_DXR" then begin
                Customer."Fecha Deuda Pico_DXR" := Customer."Fecha Deuda Pico";
                Changed := true;
            end;
            if Customer."Gestor_ID_DXR." = Blank."Gestor_ID_DXR." then begin
                Customer."Gestor_ID_DXR." := Customer.Gestor_ID;
                Changed := true;
            end;
            if Customer."Fecha envio edo cuenta_DXR" = Blank."Fecha envio edo cuenta_DXR" then begin
                Customer."Fecha envio edo cuenta_DXR" := Customer."Fecha envio estado cuenta";
                Changed := true;
            end;
            if Customer."Invoice Expiration Days_DXR" = Blank."Invoice Expiration Days_DXR" then begin
                Customer."Invoice Expiration Days_DXR" := Customer."Invoice Expiration Days";
                Changed := true;
            end;
            if Customer."Enc. Recepcion Email_DXR." = Blank."Enc. Recepcion Email_DXR." then begin
                Customer."Enc. Recepcion Email_DXR." := Customer."Enc. Recepcion Email";
                Changed := true;
            end;
            if Customer."StoreID_DXR." = Blank."StoreID_DXR." then begin
                Customer."StoreID_DXR." := Customer.StoreId;
                Changed := true;
            end;
            if Customer."Tipo Segmento_DXR" = Blank."Tipo Segmento_DXR" then begin
                Customer."Tipo Segmento_DXR" := Customer."Tipo Segmento";
                Changed := true;
            end;
            if Customer."Monto Deposito Cilindr_DXR" = Blank."Monto Deposito Cilindr_DXR" then begin
                Customer."Monto Deposito Cilindr_DXR" := Customer."Monto Deposito - Cilindros";
                Changed := true;
            end;
            if Customer."Cant asig - Cilindros_DXR" = Blank."Cant asig - Cilindros_DXR" then begin
                Customer."Cant asig - Cilindros_DXR" := Customer."Cantidad asignar - Cilindros";
                Changed := true;
            end;
            if Customer."Cliente Cilindros_DXR" = Blank."Cliente Cilindros_DXR" then begin
                Customer."Cliente Cilindros_DXR" := Customer."Cliente Cilindros";
                Changed := true;
            end;
            if Customer."Fecha Exp Reg Merc_DXR" = Blank."Fecha Exp Reg Merc_DXR" then begin
                Customer."Fecha Exp Reg Merc_DXR" := Customer."Fecha Expiracion Reg Mercantil";
                Changed := true;
            end;
            if Customer."B2C Customer_DXR" = Blank."B2C Customer_DXR" then begin
                Customer."B2C Customer_DXR" := Customer."B2C Customer";
                Changed := true;
            end;
            if Customer."Last Date/Time Modified_DXR" = Blank."Last Date/Time Modified_DXR" then begin
                Customer."Last Date/Time Modified_DXR" := Customer."Last Date/Time Modified";
                Changed := true;
            end;
            if Customer."Req Fecha Reg Merc_DXR" = Blank."Req Fecha Reg Merc_DXR" then begin
                Customer."Req Fecha Reg Merc_DXR" := Customer."Requiere Fecha Reg. Mercantil";
                Changed := true;
            end;
        end;
        exit(Changed);
    end;

    local procedure ApplyBC(var Customer: Record Customer): Boolean
    var
        Changed: Boolean;
    begin
        if (not Customer."Mandatory Order No._DXR") and Customer."Mandatory Order No._Old" then begin
            Customer."Mandatory Order No._DXR" := true;
            Changed := true;
        end;
        if (Customer."Exp. Exemption Card_DXR" = 0D) and (Customer."Exp. Exemption Card_Old" <> 0D) then begin
            Customer."Exp. Exemption Card_DXR" := Customer."Exp. Exemption Card_Old";
            Changed := true;
        end;
        if (Customer."Reference Address_DXR" = '') and (Customer."Reference Address_Old" <> '') then begin
            Customer."Reference Address_DXR" := Customer."Reference Address_Old";
            Changed := true;
        end;
        exit(Changed);
    end;

    local procedure ApplyDESB(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if (Customer."Clasific. Cliente ABC_DXR" <> Customer."DXR-DE Clasific. Cliente ABC") or
           (Customer."Ruta_DXR" <> Customer."DXR-DE Ruta")
        then begin
            if Customer."Clasific. Cliente ABC_DXR" = Blank."Clasific. Cliente ABC_DXR" then begin
                Customer."Clasific. Cliente ABC_DXR" := Customer."DXR-DE Clasific. Cliente ABC";
                Changed := true;
            end;
            if Customer."Ruta_DXR" = Blank."Ruta_DXR" then begin
                Customer."Ruta_DXR" := Customer."DXR-DE Ruta";
                Changed := true;
            end;
        end;
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

    local procedure ApplyPCM(var Customer: Record Customer): Boolean
    var
        Changed: Boolean;
    begin
        // Fuente: "DXR MCC PCM Migr Phase2".MigrateCustomerFields() (RunMaster). El SetFilter("PRC
        // Store", '<>%1', '') del origen (solo filas con PRC Store no vacio entran al scan) se
        // preserva aqui como guarda equivalente por fila, porque el motor unico no filtra el scan
        // por bloque.
        if Customer."PRC Store" = '' then
            exit(false);
        if Customer."PRC Store_DXR" = '' then begin
            Customer."PRC Store_DXR" := Customer."PRC Store";
            Changed := true;
        end;
        exit(Changed);
    end;

    local procedure ApplySD(var Customer: Record Customer): Boolean
    var
        Blank: Record Customer;
        Changed: Boolean;
    begin
        if Customer."Special Dispatch_DXR" <> Customer."Special Dispatch DXR" then
            if Customer."Special Dispatch_DXR" = Blank."Special Dispatch_DXR" then begin
                Customer."Special Dispatch_DXR" := Customer."Special Dispatch DXR";
                Changed := true;
            end;
        exit(Changed);
    end;
}
