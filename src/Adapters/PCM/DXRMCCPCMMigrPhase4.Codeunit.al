#if not ESCUDEA and not BCDX
codeunit 60124 "DXR MCC PCM Migr Phase4"
{
    // Native local migration - ported verbatim from Price Controls Mgt.'s own
    // "DXR_Migr. Phase 4 Sales Docs".Run() - see "DXR MCC PCM Migr Phase2" for the full rationale.
    Permissions =
        tabledata "Sales Header" = RM,
        tabledata "Sales Line" = RM;

    trigger OnRun()
    begin
        MigrateSalesHeaderFields();
        MigrateSalesLineFields();
    end;

    local procedure MigrateSalesHeaderFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        SalesHeader: Record "Sales Header";
        Modified: Boolean;
        AttemptNo: Integer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(SalesHeaderFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields with exactly the fields this loop reads/writes (the
        // primary key is always loaded). Sales Header carries many tableextensions in this portfolio
        // and without a partial record the server joined every companion table for every row. Also
        // added a bounded Commit - the loop previously ran entirely in one unbounded transaction.
        SalesHeader.SetLoadFields(
            "PRC Snapshot Enabled", "PRC Snapshot Enabled_DXR",
            "PRC Source Quote No.", "PRC Src Quote No._DXR",
            "PRC Snapshot Timestamp", "PRC Snap Timestamp_DXR",
            "PRC Snapshot Line Count", "PRC Snap Line Count_DXR",
            "PRC Team Code", "PRC Team Code_DXR",
            "PRC Team Name", "PRC Team Name_DXR",
            "PRC Snapshot Quote Doc Date", "PRC Snap Quote DocDt_DXR",
            "PRC Snapshot Quote Post Date", "PRC Snap Quote PostDt_DXR",
            "PRC Snap MakeOrder WorkDate", "PRC Snap MkOrd WD_DXR",
            "PRC Snap MakeOrder Today", "PRC Snap MkOrd Today_DXR");
        if not SalesHeader.FindSet() then begin
            UpgradeTag.SetUpgradeTag(SalesHeaderFieldsMigratedTag());
            exit;
        end;

        repeat
            Modified := false;

            if SalesHeader."PRC Snapshot Enabled" and not SalesHeader."PRC Snapshot Enabled_DXR" then begin
                SalesHeader."PRC Snapshot Enabled_DXR" := true;
                Modified := true;
            end;

            if (SalesHeader."PRC Source Quote No." <> '') and (SalesHeader."PRC Src Quote No._DXR" = '') then begin
                SalesHeader."PRC Src Quote No._DXR" := SalesHeader."PRC Source Quote No.";
                Modified := true;
            end;

            if (SalesHeader."PRC Snapshot Timestamp" <> 0DT) and (SalesHeader."PRC Snap Timestamp_DXR" = 0DT) then begin
                SalesHeader."PRC Snap Timestamp_DXR" := SalesHeader."PRC Snapshot Timestamp";
                Modified := true;
            end;

            if (SalesHeader."PRC Snapshot Line Count" <> 0) and (SalesHeader."PRC Snap Line Count_DXR" = 0) then begin
                SalesHeader."PRC Snap Line Count_DXR" := SalesHeader."PRC Snapshot Line Count";
                Modified := true;
            end;

            if (SalesHeader."PRC Team Code" <> '') and (SalesHeader."PRC Team Code_DXR" = '') then begin
                SalesHeader."PRC Team Code_DXR" := SalesHeader."PRC Team Code";
                Modified := true;
            end;

            if (SalesHeader."PRC Team Name" <> '') and (SalesHeader."PRC Team Name_DXR" = '') then begin
                SalesHeader."PRC Team Name_DXR" := SalesHeader."PRC Team Name";
                Modified := true;
            end;

            if (SalesHeader."PRC Snapshot Quote Doc Date" <> 0D) and (SalesHeader."PRC Snap Quote DocDt_DXR" = 0D) then begin
                SalesHeader."PRC Snap Quote DocDt_DXR" := SalesHeader."PRC Snapshot Quote Doc Date";
                Modified := true;
            end;

            if (SalesHeader."PRC Snapshot Quote Post Date" <> 0D) and (SalesHeader."PRC Snap Quote PostDt_DXR" = 0D) then begin
                SalesHeader."PRC Snap Quote PostDt_DXR" := SalesHeader."PRC Snapshot Quote Post Date";
                Modified := true;
            end;

            if (SalesHeader."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesHeader."PRC Snap MkOrd WD_DXR" = 0D) then begin
                SalesHeader."PRC Snap MkOrd WD_DXR" := SalesHeader."PRC Snap MakeOrder WorkDate";
                Modified := true;
            end;

            if (SalesHeader."PRC Snap MakeOrder Today" <> 0D) and (SalesHeader."PRC Snap MkOrd Today_DXR" = 0D) then begin
                SalesHeader."PRC Snap MkOrd Today_DXR" := SalesHeader."PRC Snap MakeOrder Today";
                Modified := true;
            end;

            if Modified then begin
                AttemptNo := 0;
                while not TryModifySalesHeader(SalesHeader) do begin
                    AttemptNo += 1;
                    if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                        Error(GetLastErrorText());
                end;

                // Only reached once the retry-on-lock loop above has fully resolved, never mid-retry;
                // counter advances per MODIFIED row.
                RowCounter += 1;
                if RowCounter >= BatchSize() then begin
                    Commit();
                    RowCounter := 0;
                end;
            end;
        until SalesHeader.Next() = 0;

        if RowCounter > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(SalesHeaderFieldsMigratedTag());
    end;

    [TryFunction]
    local procedure TryModifySalesHeader(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Modify(false);
    end;

    local procedure MigrateSalesLineFields()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        RetryMgt: Codeunit 54617;
        SalesLine: Record "Sales Line";
        Modified: Boolean;
        AttemptNo: Integer;
        RowCounter: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(SalesLineFieldsMigratedTag()) then
            exit;

        // Fixed 2026-08-27: added SetLoadFields with exactly the fields this loop reads/writes (the
        // primary key is always loaded). Sales Line is the widest table in this portfolio and carries
        // many tableextensions - without a partial record every companion table was joined per row.
        // Also added a bounded Commit - the loop previously ran in one unbounded transaction.
        SalesLine.SetLoadFields(
            "Precio Menor A PrecioFijado", "PrecMenorFijado_DXR",
            "PRC Exempt Price", "PRC Exempt Price_DXR",
            "PRC Store From Customer", "PRC StoreFrmCust_DXR",
            "PRC Line Style", "PRC Line Style_DXR",
            "PRC Requires Price Approval", "PRC ReqPrcAppr_DXR",
            "PRC Customer Price Applied", "PRC CustPrcAppl_DXR",
            "PRC Store Price Applied", "PRC StorePrcAppl_DXR",
            "PRC LSC Original Unit Price", "PRC LSC OrigUP_DXR",
            "PRC LSC Price Manual Change", "PRC LSC Price Man Chg_DXR",
            "PRC LSC Disc Manual Change", "PRC LSC Disc Man Chg_DXR",
            "PRC Approval Reason", "PRC Approval Reason_DXR",
            "PRC VAT Exempt", "PRC VAT Exempt_DXR",
            "PRC Original Item No.", "PRC Orig Item No._DXR",
            "PRC Original Quantity", "PRC Orig Quantity_DXR",
            "PRC Original Unit Price", "PRC Orig Unit Price_DXR",
            "PRC Original Amount Incl VAT", "PRC Orig AmtInclVAT_DXR",
            "PRC Original VAT Percent", "PRC Orig VAT Pct_DXR",
            "PRC Snapshot Customer Price", "PRC Snap Cust Price_DXR",
            "PRC Snapshot Store Price", "PRC Snap Store Price_DXR",
            "PRC Snapshot Line Approved", "PRC Snap Line Appr_DXR",
            "PRC Source Quote No.", "PRC Src Quote No._DXR",
            "PRC Snapshot Timestamp", "PRC Snap Timestamp_DXR",
            "PRC Snapshot Line Count", "PRC Snap Line Count_DXR",
            "PRC Snapshot Quote Doc Date", "PRC Snap QuoteDocDt_DXR",
            "PRC Snapshot Quote Post Date", "PRC Snap QuotePostDt_DXR",
            "PRC Snap MakeOrder WorkDate", "PRC Snap MkOrd WD_DXR",
            "PRC Snap MakeOrder Today", "PRC Snap MkOrdToday_DXR",
            "PRC Original Net Amount", "PRC Orig Net Amt_DXR",
            "PRC Original Line Disc. %", "PRC Orig LinDisc %_DXR",
            "PRC Original Line Disc. Amt", "PRC Orig LinDisc Amt_DXR",
            "PRC Snapshot VAT Exempt", "PRC Snap VAT Exempt_DXR",
            "PRC Snapshot Exempt Price", "PRC Snap ExemptPrc_DXR");
        if not SalesLine.FindSet() then begin
            UpgradeTag.SetUpgradeTag(SalesLineFieldsMigratedTag());
            exit;
        end;

        repeat
            Modified := false;

            if SalesLine."Precio Menor A PrecioFijado" and not SalesLine."PrecMenorFijado_DXR" then begin
                SalesLine."PrecMenorFijado_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC Exempt Price" <> 0) and (SalesLine."PRC Exempt Price_DXR" = 0) then begin
                SalesLine."PRC Exempt Price_DXR" := SalesLine."PRC Exempt Price";
                Modified := true;
            end;

            if (SalesLine."PRC Store From Customer" <> '') and (SalesLine."PRC StoreFrmCust_DXR" = '') then begin
                SalesLine."PRC StoreFrmCust_DXR" := SalesLine."PRC Store From Customer";
                Modified := true;
            end;

            if (SalesLine."PRC Line Style" <> '') and (SalesLine."PRC Line Style_DXR" = '') then begin
                SalesLine."PRC Line Style_DXR" := SalesLine."PRC Line Style";
                Modified := true;
            end;

            if SalesLine."PRC Requires Price Approval" and not SalesLine."PRC ReqPrcAppr_DXR" then begin
                SalesLine."PRC ReqPrcAppr_DXR" := true;
                Modified := true;
            end;

            if SalesLine."PRC Customer Price Applied" and not SalesLine."PRC CustPrcAppl_DXR" then begin
                SalesLine."PRC CustPrcAppl_DXR" := true;
                Modified := true;
            end;

            if SalesLine."PRC Store Price Applied" and not SalesLine."PRC StorePrcAppl_DXR" then begin
                SalesLine."PRC StorePrcAppl_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC LSC Original Unit Price" <> 0) and (SalesLine."PRC LSC OrigUP_DXR" = 0) then begin
                SalesLine."PRC LSC OrigUP_DXR" := SalesLine."PRC LSC Original Unit Price";
                Modified := true;
            end;

            if SalesLine."PRC LSC Price Manual Change" and not SalesLine."PRC LSC Price Man Chg_DXR" then begin
                SalesLine."PRC LSC Price Man Chg_DXR" := true;
                Modified := true;
            end;

            if SalesLine."PRC LSC Disc Manual Change" and not SalesLine."PRC LSC Disc Man Chg_DXR" then begin
                SalesLine."PRC LSC Disc Man Chg_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC Approval Reason" <> '') and (SalesLine."PRC Approval Reason_DXR" = '') then begin
                SalesLine."PRC Approval Reason_DXR" := SalesLine."PRC Approval Reason";
                Modified := true;
            end;

            if SalesLine."PRC VAT Exempt" and not SalesLine."PRC VAT Exempt_DXR" then begin
                SalesLine."PRC VAT Exempt_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC Original Item No." <> '') and (SalesLine."PRC Orig Item No._DXR" = '') then begin
                SalesLine."PRC Orig Item No._DXR" := SalesLine."PRC Original Item No.";
                Modified := true;
            end;

            if (SalesLine."PRC Original Quantity" <> 0) and (SalesLine."PRC Orig Quantity_DXR" = 0) then begin
                SalesLine."PRC Orig Quantity_DXR" := SalesLine."PRC Original Quantity";
                Modified := true;
            end;

            if (SalesLine."PRC Original Unit Price" <> 0) and (SalesLine."PRC Orig Unit Price_DXR" = 0) then begin
                SalesLine."PRC Orig Unit Price_DXR" := SalesLine."PRC Original Unit Price";
                Modified := true;
            end;

            if (SalesLine."PRC Original Amount Incl VAT" <> 0) and (SalesLine."PRC Orig AmtInclVAT_DXR" = 0) then begin
                SalesLine."PRC Orig AmtInclVAT_DXR" := SalesLine."PRC Original Amount Incl VAT";
                Modified := true;
            end;

            if (SalesLine."PRC Original VAT Percent" <> 0) and (SalesLine."PRC Orig VAT Pct_DXR" = 0) then begin
                SalesLine."PRC Orig VAT Pct_DXR" := SalesLine."PRC Original VAT Percent";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Customer Price" <> 0) and (SalesLine."PRC Snap Cust Price_DXR" = 0) then begin
                SalesLine."PRC Snap Cust Price_DXR" := SalesLine."PRC Snapshot Customer Price";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Store Price" <> 0) and (SalesLine."PRC Snap Store Price_DXR" = 0) then begin
                SalesLine."PRC Snap Store Price_DXR" := SalesLine."PRC Snapshot Store Price";
                Modified := true;
            end;

            if SalesLine."PRC Snapshot Line Approved" and not SalesLine."PRC Snap Line Appr_DXR" then begin
                SalesLine."PRC Snap Line Appr_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC Source Quote No." <> '') and (SalesLine."PRC Src Quote No._DXR" = '') then begin
                SalesLine."PRC Src Quote No._DXR" := SalesLine."PRC Source Quote No.";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Timestamp" <> 0DT) and (SalesLine."PRC Snap Timestamp_DXR" = 0DT) then begin
                SalesLine."PRC Snap Timestamp_DXR" := SalesLine."PRC Snapshot Timestamp";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Line Count" <> 0) and (SalesLine."PRC Snap Line Count_DXR" = 0) then begin
                SalesLine."PRC Snap Line Count_DXR" := SalesLine."PRC Snapshot Line Count";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Quote Doc Date" <> 0D) and (SalesLine."PRC Snap QuoteDocDt_DXR" = 0D) then begin
                SalesLine."PRC Snap QuoteDocDt_DXR" := SalesLine."PRC Snapshot Quote Doc Date";
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Quote Post Date" <> 0D) and (SalesLine."PRC Snap QuotePostDt_DXR" = 0D) then begin
                SalesLine."PRC Snap QuotePostDt_DXR" := SalesLine."PRC Snapshot Quote Post Date";
                Modified := true;
            end;

            if (SalesLine."PRC Snap MakeOrder WorkDate" <> 0D) and (SalesLine."PRC Snap MkOrd WD_DXR" = 0D) then begin
                SalesLine."PRC Snap MkOrd WD_DXR" := SalesLine."PRC Snap MakeOrder WorkDate";
                Modified := true;
            end;

            if (SalesLine."PRC Snap MakeOrder Today" <> 0D) and (SalesLine."PRC Snap MkOrdToday_DXR" = 0D) then begin
                SalesLine."PRC Snap MkOrdToday_DXR" := SalesLine."PRC Snap MakeOrder Today";
                Modified := true;
            end;

            if (SalesLine."PRC Original Net Amount" <> 0) and (SalesLine."PRC Orig Net Amt_DXR" = 0) then begin
                SalesLine."PRC Orig Net Amt_DXR" := SalesLine."PRC Original Net Amount";
                Modified := true;
            end;

            if (SalesLine."PRC Original Line Disc. %" <> 0) and (SalesLine."PRC Orig LinDisc %_DXR" = 0) then begin
                SalesLine."PRC Orig LinDisc %_DXR" := SalesLine."PRC Original Line Disc. %";
                Modified := true;
            end;

            if (SalesLine."PRC Original Line Disc. Amt" <> 0) and (SalesLine."PRC Orig LinDisc Amt_DXR" = 0) then begin
                SalesLine."PRC Orig LinDisc Amt_DXR" := SalesLine."PRC Original Line Disc. Amt";
                Modified := true;
            end;

            if SalesLine."PRC Snapshot VAT Exempt" and not SalesLine."PRC Snap VAT Exempt_DXR" then begin
                SalesLine."PRC Snap VAT Exempt_DXR" := true;
                Modified := true;
            end;

            if (SalesLine."PRC Snapshot Exempt Price" <> 0) and (SalesLine."PRC Snap ExemptPrc_DXR" = 0) then begin
                SalesLine."PRC Snap ExemptPrc_DXR" := SalesLine."PRC Snapshot Exempt Price";
                Modified := true;
            end;

            if Modified then begin
                AttemptNo := 0;
                while not TryModifySalesLine(SalesLine) do begin
                    AttemptNo += 1;
                    if not RetryMgt.ShouldRetry(AttemptNo, GetLastErrorText()) then
                        Error(GetLastErrorText());
                end;

                // Only reached once the retry-on-lock loop above has fully resolved, never mid-retry;
                // counter advances per MODIFIED row.
                RowCounter += 1;
                if RowCounter >= BatchSize() then begin
                    Commit();
                    RowCounter := 0;
                end;
            end;
        until SalesLine.Next() = 0;

        if RowCounter > 0 then
            Commit();

        UpgradeTag.SetUpgradeTag(SalesLineFieldsMigratedTag());
    end;

    local procedure BatchSize(): Integer
    begin
        exit(500);
    end;

    [TryFunction]
    local procedure TryModifySalesLine(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Modify(false);
    end;

    local procedure SalesHeaderFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-SalesHeaderFieldsMigrated-28.3.0.0');
    end;

    local procedure SalesLineFieldsMigratedTag(): Code[250]
    begin
        exit('DXR-SalesLineFieldsMigrated-28.3.0.0');
    end;
}

#endif
