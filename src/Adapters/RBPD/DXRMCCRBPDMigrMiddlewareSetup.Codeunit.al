/*
codeunit 60113 "DXR MCC RBPD Migr MidwareSet"
{
    // Native local migration - ported from Recaudo BPD's own
    // "DXR_Recaudo Migr Phase1 Migr".MigrateMiddlewareSetup().
    Permissions = tabledata "DXR-IB MiddlewareSetup" = R,
                  tabledata "DXR_MiddlewareSetup" = RIM;

    trigger OnRun()
    var
        OldRec: Record "DXR-IB MiddlewareSetup";
        NewRec: Record "DXR_MiddlewareSetup";
    begin
        if OldRec.FindSet() then
            repeat
                if not NewRec.Get(OldRec."Primary Key") then begin
                    NewRec.Init();
                    NewRec."Primary Key" := OldRec."Primary Key";
                    NewRec."Middleware URL" := OldRec."Middleware URL";
                    NewRec."Middleware Username" := OldRec."Middleware Username";
                    NewRec."Middleware Password" := OldRec."Middleware Password";
                    NewRec."Connection Timeout" := OldRec."Connection Timeout";
                    NewRec."Request Timeout" := OldRec."Request Timeout";
                    NewRec."Auto Process Pending" := OldRec."Auto Process Pending";
                    NewRec."Auto Process Interval" := OldRec."Auto Process Interval";
                    NewRec."Enable Logging" := OldRec."Enable Logging";
                    NewRec."Log Level" := OldRec."Log Level";
                    NewRec."Last Connection Test" := OldRec."Last Connection Test";
                    NewRec."Last Connection Result" := OldRec."Last Connection Result";
                    NewRec."Last Processing" := OldRec."Last Processing";
                    NewRec."Last Processing Result" := OldRec."Last Processing Result";
                    NewRec.Active := OldRec.Active;
                    NewRec.Insert(true);
                end;
            until OldRec.Next() = 0;
    end;
}

*/
