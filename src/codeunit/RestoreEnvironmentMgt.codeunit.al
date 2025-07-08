codeunit 70000 "EOS Restore Environment Mgt"
{
    trigger OnRun()
    begin

    end;

    #region TokenFunctions
    procedure GetToken() Token: SecretText
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        HttpMethod: Enum "Http Method";
        ContentTypeLbl: Label 'application/x-www-form-urlencoded', Locked = true;
        UriLbl: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        //Test. Used for testing with a specific tenant
        TestLbl: Label 'https://login.microsoftonline.com/907e8cf0-8ecd-4057-97be-64f486e792ff/oauth2/v2.0/token', Locked = true;
    begin
        CheckEnvironment();
        CheckSetupForToken();

        if HasValidToken() then
            exit(GetExistingToken());

        //Authentication
        Headers := Client.DefaultRequestHeaders();

        //Init Headers
        Content.GetHeaders(Headers);

        //Set Body
        Content.WriteFrom(CreateBodyContentForToken());

        //Set Headers
        Headers.Clear();
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', ContentTypeLbl);

        //Set Request
        Request.Method := Format(HttpMethod::GET);
        Request.SetRequestUri(StrSubstNo(UriLbl, AzureADTenant.GetAadTenantId()));
        //Test. Used this for testing with a specific tenant
        //Request.SetRequestUri(TestLbl);
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            Error(GetLastErrorText());

        UpdateTokenValue(Response);
        exit(GetExistingToken());
    end;

    local procedure UpdateTokenValue(Response: HttpResponseMessage)
    var
        Property, ResponseText : Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Text000Err: Label 'Invalid Access Token Property %1, Value:  %2';
    begin
        Response.Content.ReadAs(ResponseText);

        JObject.ReadFrom(ResponseText);
        foreach Property in JObject.Keys() do begin
            JObject.Get(Property, JToken);
            case Property of
                'token_type',
                'scope',
                'expires_on',
                'not_before',
                'resource',
                'id_token':
                    ;
                'expires_in':
                    RestEnv."EOS Token Expires In" := JToken.AsValue().AsInteger();
                'ext_expires_in':
                    ;
                'access_token':
                    RestEnv.SetTokenForceNoEncryption(RestEnv."EOS Token", JToken.AsValue().AsText());
                'refresh_token':
                    ;
                else
                    Error(Text000Err, Property, JToken.AsValue().AsText());
            end;
        end;
        RestEnv."EOS Token Authorization Time" := CurrentDateTime();
        RestEnv.Modify();
    end;

    local procedure HasValidToken(): Boolean;
    var
        ElapsedSecs: Integer;
    begin
        if RestEnv."EOS Token Authorization Time" = 0DT then
            exit;

        ElapsedSecs := Round((CurrentDateTime() - RestEnv."EOS Token Authorization Time") / 1000, 1, '>');
        if (ElapsedSecs < RestEnv."EOS Token Expires In") and (ElapsedSecs < 3600) then
            exit(true);
    end;

    local procedure GetExistingToken() Token: SecretText
    begin
        Token := RestEnv.GetTokenAsSecretText(RestEnv."EOS Token");
    end;

    [NonDebuggable]
    local procedure CreateBodyContentForToken() Body: SecretText
    var
        SecretTextLbl: Label '%1&%2&client_secret=%3&%4', Locked = true;
        ClientIdLbl: Label 'client_id=%1', Locked = true;
        GrantTypeLbl: Label 'grant_type=client_credentials', Locked = true;
        ScopeLbl: Label 'scope=https://api.businesscentral.dynamics.com/.default', Locked = true;
    begin
        Body := SecretText.SecretStrSubstNo(SecretTextLbl,
                                            Format(GrantTypeLbl),
                                            StrSubstNo(ClientIdLbl, RestEnv."EOS Client Id"),
                                            RestEnv.GetTokenAsSecretText(RestEnv."EOS Secret Id"),
                                            Format(ScopeLbl));
    end;

    local procedure CheckSetupForToken()
    var
        Text000Err: label 'Field %1 must be filled in.';
    begin
        RestEnv.Get();
        RestEnv.TestField("EOS Client Id");
        if not RestEnv.HasToken(RestEnv."EOS Secret Id") then
            Error(Text000Err, RestEnv.FieldCaption("EOS Secret Id"));
    end;

    #endregion TokenFunctions

    procedure RestoreEnvironment()
    var
        Counter: Integer;
        Status: Enum "EOS Environment Status";
        Text000Err: Label 'Environment cannot be restored beacuse is already present in Active status. Please delete first and try again later.';
        Text001Err: Label 'Maximum number of attempts reached. Please try again later.';
        Text002Lbl: Label 'Operation Completed. Check the status of the environment in the admincenter or use the function Get Environment Status';
    begin
        CheckEnvironment();
        CheckSetup();

        //Delete the environment first
        DeleteEnvironment();

        case RestEnv."EOS Waiting Time Type" of
            "EOS Waiting Time Types"::"Fixed Time":
                Sleep(RestEnv."EOS Waiting Fixed Time (ms)");
            "EOS Waiting Time Types"::"After Deletion":
                begin
                    if RestEnv."EOS Max No. Of Attemps" = 0 then
                        RestEnv."EOS Max No. Of Attemps" := 10;

                    if RestEnv."EOS Wait. Time Attempt (ms)" = 0 then
                        RestEnv."EOS Wait. Time Attempt (ms)" := 30000; //30 seconds

                    for Counter := 1 to RestEnv."EOS Max No. Of Attemps" do begin
                        Status := GetEnvironmentInfo();
                        case Status of
                            "EOS Environment Status"::Active:
                                Error(Text000Err);
                            "EOS Environment Status"::SoftDeleting:
                                Sleep(RestEnv."EOS Wait. Time Attempt (ms)");
                            "EOS Environment Status"::NotFound:
                                break;
                        end;
                    end;

                    if (Counter = RestEnv."EOS Max No. Of Attemps") and (Status <> Status::NotFound) then
                        Error(Text001Err);
                end;
        end;

        //Copy the environment
        CopyEnvironment();

        if GuiAllowed() then
            Message(Text002Lbl);
    end;

    local procedure DeleteEnvironment()
    var
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        HttpMethod: Enum "Http Method";
        UriLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.21/applications/BusinessCentral/environments/%1', Locked = true;
    begin
        CheckEnvironment();
        CheckSetup();

        //Authentication
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', SecretText.SecretStrSubstNo('Bearer %1', GetToken()));

        //Set Headers
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');

        //Set Request
        Request.Method := Format(HttpMethod::DELETE);
        Request.SetRequestUri(StrSubstNo(UriLbl, RestEnv."EOS New Environment Name"));
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            Error(GetLastErrorText());
    end;

    local procedure CopyEnvironment()
    var
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        HttpMethod: Enum "Http Method";
        ContentTypeLbl: Label 'application/json', Locked = true;
        UriLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.21/applications/BusinessCentral/environments/%1/copy', Locked = true;
    begin
        CheckEnvironment();
        CheckSetup();

        //Authentication
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', SecretText.SecretStrSubstNo('Bearer %1', GetToken()));

        //Set Headers
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', ContentTypeLbl);

        //Set Body
        WriteCopyEnvironmentBody(TempBlob);
        TempBlob.CreateInStream(InStr);
        Content.WriteFrom(InStr);

        //Set Request
        Request.Method := Format(HttpMethod::POST);
        Request.SetRequestUri(StrSubstNo(UriLbl, RestEnv."EOS Prod. Environment Name"));
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            Error(GetLastErrorText());
    end;

    procedure GetEnvironmentInfo() Status: Enum "EOS Environment Status"
    var
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        HttpMethod: Enum "Http Method";
        UriLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.21/applications/BusinessCentral/environments/%1', Locked = true;
    begin
        CheckEnvironment();
        CheckSetup();

        //Authentication
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', SecretText.SecretStrSubstNo('Bearer %1', GetToken()));

        //Set Headers
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');

        //Set Request
        Request.Method := Format(HttpMethod::GET);
        Request.SetRequestUri(StrSubstNo(UriLbl, RestEnv."EOS New Environment Name"));
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            Error(GetLastErrorText());

        Status := GetStatusFromResponse(Response);
    end;

    local procedure GetStatusFromResponse(Response: HttpResponseMessage) Status: Enum "EOS Environment Status"
    var
        Property, ResponseText : Text;
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        if Response.HttpStatusCode() = 404 then
            exit(Status::NotFound);

        Response.Content.ReadAs(ResponseText);

        JObject.ReadFrom(ResponseText);
        foreach Property in JObject.Keys() do begin
            JObject.Get(Property, JToken);
            case Property of
                'status':
                    case JToken.AsValue().AsText() of
                        'Active':
                            exit(Status::Active);
                        'SoftDeleting':
                            exit(Status::SoftDeleting);
                        'Preparing':
                            exit(Status::Preparing);
                        else
                            exit(Status::NotFound);
                    end;
            end;
        end;
    end;

    local procedure WriteCopyEnvironmentBody(var TempBlob: Codeunit "Temp Blob")
    var
        OutStr: OutStream;
        JsonBody: Text;
    begin
        JsonBody := '{"environmentName": "' + RestEnv."EOS New Environment Name" + '","type": "sandbox"}';

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(JsonBody);
    end;

    local procedure CheckSetup()
    begin
        RestEnv.Get();
        RestEnv.TestField("EOS Prod. Environment Name");
        RestEnv.TestField("EOS New Environment Name");
    end;

    procedure ExecuteFunctionsUI()
    var
        Selection: Integer;
        Status: Enum "EOS Environment Status";
        Text000Lbl: Label 'Choose a function to execute';
        Text001Lbl: Label 'Delete Environment,Get Environment Status,Copy Environment,Cancel';
        Text002Lbl: Label 'Operation Completed. Check the status of the environment in the admincenter or use the function Get Environment Status';
        Text003Lbl: Label 'Operation Completed. Environment %1 is currently in status %2.';
    begin
        if not GuiAllowed() then
            exit;

        Selection := StrMenu(Text001Lbl, 1, Text000Lbl);

        case Selection of
            1:
                begin
                    DeleteEnvironment();
                    if GuiAllowed() then
                        Message(Text002Lbl);
                end;
            2:
                begin
                    Status := GetEnvironmentInfo();
                    if GuiAllowed() then
                        Message(Text003Lbl, RestEnv."EOS New Environment Name", Status);
                end;
            3:
                begin
                    CopyEnvironment();
                    if GuiAllowed() then
                        Message(Text002Lbl);
                end;
            4:
                exit;
        end;
    end;

    procedure TryConnection()
    var
        Token: SecretText;
    begin
        Token := GetToken();
        if not Token.IsEmpty() then
            RestEnv."EOS Connection Is Up" := true
        else
            RestEnv."EOS Connection Is Up" := false;

        RestEnv.Modify();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure T472_OnAfterInsertEvent(var Rec: Record "Job Queue Entry")
    begin
        FindJobQueueInCompanies();
    end;

    procedure JobQueueEntry()
    var
        JQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCard: Page "Job Queue Entry Card";
        Text000Lbl: Label 'Restore Environment (ENV)';
    begin
        FindJobQueueInCompanies();

        JQueueEntry.Reset();
        JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
        JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
        JQueueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        if JQueueEntry.IsEmpty() then begin
            JQueueEntry.InitRecurringJob(1440);
            JQueueEntry."Object Type to Run" := JQueueEntry."Object Type to Run"::Codeunit;
            JQueueEntry."Object ID to Run" := Codeunit::"EOS Restore Job Queue";
            JQueueEntry.Description := Text000Lbl;
            JQueueEntry.Status := JQueueEntry.Status::"On Hold";
            JQueueEntry.Insert(true);
            Commit();
        end else
            JQueueEntry.FindFirst();

        JobQueueEntryCard.SetTableView(JQueueEntry);
        JobQueueEntryCard.RunModal();
    end;

    local procedure FindJobQueueInCompanies() CompanyNameList: List of [Text[30]]
    var
        JQueueEntry: Record "Job Queue Entry";
        Company: Record Company;
        Text000Err: Label 'Job Queue is already present in company %1. Open the setup in that specific company or delete and recreate the job queue entry.';
    begin
        Company.Reset();
        Company.FindSet();
        repeat
            JQueueEntry.Reset();
            JQueueEntry.ChangeCompany(Company.Name);
            JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
            JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
            if not JQueueEntry.IsEmpty() then
                CompanyNameList.Add(Company.Name);
        until Company.Next() = 0;

        if not (CompanyNameList.Contains(CopyStr(CompanyName(), 1, 30))) and (CompanyNameList.Count() > 0) then
            Error(Text000Err, CompanyNameList.Get(1));
    end;

    procedure DeleteRestoreJobQueue()
    var
        Company: Record Company;
        JQueueEntry: Record "Job Queue Entry";
        Counter: Integer;
        Text000Lbl: Label 'Deleted %1 Job Queue Entries';
        Text001Lbl: Label 'No Job Queue Entries to delete';
    begin
        Company.Reset();
        Company.FindSet();
        repeat
            JQueueEntry.ChangeCompany(Company.Name);
            JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
            JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
            if not JQueueEntry.IsEmpty() then begin
                Counter += JQueueEntry.Count();
                JQueueEntry.DeleteAll();
            end;
        until Company.Next() = 0;

        if GuiAllowed() then
            if Counter <> 0 then
                Message(Text000Lbl, Counter)
            else
                Message(Text001Lbl);
    end;

    procedure CheckEnvironment()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        Text000Err: Label 'Cannot execute this funcionality in a non-production environment.';
    begin
        //Test. Check if the environment is production or not.
        if not EnvironmentInfo.IsProduction() then
            Error(Text000Err);
    end;

    var
        RestEnv: Record "EOS Restore Environment";
}
