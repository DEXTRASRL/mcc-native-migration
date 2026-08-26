#if not ESCUDEA and not BCDX
codeunit 60072 "DXR MCC SD Migr SalesHeader"
{
    // Native local migration - see "DXR MCC SD Migr Customer" for the full design rationale. Ported
    // from Special Dispatch's own Phase1.CopySalesHeaderSpecialDispatch() (field 59000->54747 on
    // its own "DXR_Sales Header Ext" table extension).
    Permissions = tabledata "Sales Header" = RM;

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.FindSet(true) then
            repeat
                SalesHeader."Special Dispatch_DXR" := SalesHeader."Special Dispatch DXR";
                SalesHeader.Modify(false);
            until SalesHeader.Next() = 0;
    end;
}

#endif
