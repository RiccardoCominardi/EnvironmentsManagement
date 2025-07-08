table 70000 "EOS Restore Environment"
{
    DataClassification = CustomerContent;
    Caption = 'Restore Environment (ENV)';
    DataPerCompany = false;

    fields
    {
        field(1; "EOS Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
        }
        field(2; "EOS Client Id"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Client Id', Locked = true;
        }
        field(3; "EOS Secret Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Secret Id', Locked = true;
        }
        field(4; "EOS Secret Due Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Due Date';
        }
        field(5; "EOS New Environment Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'New Environment Name';
        }
        field(6; "EOS Prod. Environment Name"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Production Environment Name';
        }
        field(7; "EOS Waiting Time Type"; Enum "EOS Waiting Time Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Waiting Time Type';
        }
        field(8; "EOS Waiting Fixed Time (ms)"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Waiting Fixed Time (ms)';
        }
        field(9; "EOS Max No. Of Attemps"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Max No. Of Attemps';
            InitValue = 10;
        }
        field(10; "EOS Connection Is Up"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Connection Is Up';
        }
        field(11; "EOS Token"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Token', Locked = true;
        }
        field(12; "EOS Token Authorization Time"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Token Authorization Time';
        }
        field(13; "EOS Token Expires In"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Token Expires In', Locked = true;
        }
        field(14; "EOS Wait. Time Attempt (ms)"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Waiting Time After Attempt (ms)';
            InitValue = 30000;
        }
        field(15; "EOS Info Mapping Message Shown"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Info Mapping Message Shown', Locked = true;
        }
    }

    keys
    {
        key(Key1; "EOS Code") { Clustered = true; }
    }

    [NonDebuggable]
    procedure SetToken(var TokenKey: Guid; TokenValue: SecretText)
    begin
        if IsNullGuid(TokenKey) then
            TokenKey := CreateGuid();

        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(TokenKey, TokenValue, DataScope::Company)
        else
            IsolatedStorage.Set(TokenKey, TokenValue, DataScope::Company);
    end;

    [NonDebuggable]
    internal procedure SetTokenForceNoEncryption(var TokenKey: Guid; TokenValue: SecretText) NewToken: Boolean
    begin
        if IsNullGuid(TokenKey) then
            NewToken := true;
        if NewToken then
            TokenKey := CreateGuid();

        IsolatedStorage.Set(TokenKey, TokenValue, DataScope::Company);
    end;

    [NonDebuggable]
    procedure GetTokenAsSecretText(TokenKey: Guid) TokenValue: SecretText
    begin
        if not HasToken(TokenKey) then
            exit(TokenValue);

        IsolatedStorage.Get(TokenKey, DataScope::Company, TokenValue);
    end;

    [NonDebuggable]
    procedure DeleteToken(TokenKey: Guid)
    begin
        if not HasToken(TokenKey) then
            exit;

        IsolatedStorage.Delete(TokenKey, DataScope::Company);
    end;

    [NonDebuggable]
    procedure HasToken(TokenKey: Guid): Boolean
    begin
        exit(not IsNullGuid(TokenKey) and IsolatedStorage.Contains(TokenKey, DataScope::Company));
    end;
}