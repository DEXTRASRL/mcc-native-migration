table 60004 "DXR MCC Migration Lock"
{
    // Ported from DR-Localization's own "DXR_Migration Lock" pattern (Base App DR Localization,
    // src\Base\Codeunits\Uprade\DXR_Migration_Lock.Table.al) - the user explicitly asked for the
    // same cross-company mutual-exclusion design used there ("el patron que tenemos en
    // localizacion base con los dispatches y phases de migracion... su formato multi-tenant"),
    // so this table and DXR MCC Migration Lock Mgt. mirror that design rather than inventing a
    // new one: one fixed "coordinator" company holds the lock row regardless of which company
    // requested it, which is what makes this a true cross-company lock instead of one
    // independent (and therefore ineffective) lock per company.
    Caption = 'DXR MCC Migration Lock';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            DataClassification = SystemMetadata;
        }
        field(2; "Lock Code"; Code[50])
        {
            Caption = 'Lock Code';
            DataClassification = SystemMetadata;
        }
        field(3; "Locked By"; Code[50])
        {
            Caption = 'Locked By';
            DataClassification = SystemMetadata;
        }
        field(4; "Locked At"; DateTime)
        {
            Caption = 'Locked At';
            DataClassification = SystemMetadata;
        }
        field(5; "Expires At"; DateTime)
        {
            Caption = 'Expires At';
            DataClassification = SystemMetadata;
        }
        field(6; "Last Task Id"; Guid)
        {
            Caption = 'Last Task Id';
            DataClassification = SystemMetadata;
        }
        field(7; "Locked For Company"; Text[30])
        {
            Caption = 'Locked For Company';
            DataClassification = SystemMetadata;
        }
        field(8; "Run Request Entry No."; Integer)
        {
            Caption = 'Run Request Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "DXR MCC Run Request"."Entry No.";
        }
    }

    keys
    {
        key(PK; "Company Name", "Lock Code")
        {
            Clustered = true;
        }
    }
}
