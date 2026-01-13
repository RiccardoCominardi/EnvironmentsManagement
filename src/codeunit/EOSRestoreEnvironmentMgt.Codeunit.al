codeunit 70000 "EOS Restore Environment Mgt"
{
    SingleInstance = true;
    trigger OnRun()
    begin

    end;

    #region TokenFunctions
    procedure GetToken(): SecretText
    begin
        exit(GetToken(false));
    end;

    procedure GetToken(ForceNew: Boolean): SecretText
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        ResponseText: Text;
        HttpMethod: Enum "Http Method";
        ContentTypeLbl: Label 'application/x-www-form-urlencoded', Locked = true;
        UriLbl: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
    //Test. Used for testing with a specific tenant
    //TestLbl: Label 'https://login.microsoftonline.com/1f976128-8bbe-4ad7-a713-cbf76c27a7e0/oauth2/v2.0/token', Locked = true;
    begin
        CheckEnvironment();
        CheckSetupForToken();

        if not ForceNew then
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

        if not (Response.HttpStatusCode in [200, 201, 202]) then
            if Response.Content.ReadAs(ResponseText) then
                Error(ResponseText);

        UpdateTokenValue(Response);
        exit(GetExistingToken());
    end;

    local procedure UpdateTokenValue(Response: HttpResponseMessage)
    var
        Property, ResponseText : Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Text000Err: Label 'Invalid Access Token Property %1, Value:  %2', Comment = '%1: Property Name, %2: Property Value';
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
        Text000Err: label 'Field %1 must be filled in.', Comment = '%1: Field Name';
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

        if GetEnvironmentInfo() = Enum::"EOS Environment Status"::Active then
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
        ResponseText: Text;
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

        if not (Response.HttpStatusCode in [200, 201, 202]) then
            if Response.Content.ReadAs(ResponseText) then
                Error(ResponseText);

        InsertLogRecord(Response);
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
        ResponseText: Text;
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

        if not (Response.HttpStatusCode in [200, 201, 202]) then
            if Response.Content.ReadAs(ResponseText) then
                Error(ResponseText);

        InsertLogRecord(Response);
    end;

    procedure GetEnvironmentInfo() Status: Enum "EOS Environment Status"
    var
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        //ResponseText: Text;
        HttpMethod: Enum "Http Method";
        UriLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.21/applications/BusinessCentral/environments/%1', Locked = true;
    begin
        //CheckEnvironment();
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

        //Error not to handle beacause 404 is possible and it means that the environment is not present
        //if not (Response.HttpStatusCode in [200, 201, 202]) then
        //    if Response.Content.ReadAs(ResponseText) then
        //        Error(ResponseText);

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
        JsonBodyLbl: label '{"environmentName": "%1","type": "sandbox"}', Locked = true;
    begin
        JsonBody := StrSubstNo(JsonBodyLbl, RestEnv."EOS New Environment Name");

        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(JsonBody);
    end;

    procedure GetOperationDetails(RequestType: Text; OperationId: Text; RaiseError: Boolean) Response: HttpResponseMessage;
    var
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        HttpMethod: Enum "Http Method";
        UriEnvLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.9/applications/BusinessCentral/environments/%1/operations/%2', Locked = true;
    //UriLbl: Label 'https://api.businesscentral.dynamics.com/admin/v2.9/environments/operations', Locked = true;
    begin
        //CheckEnvironment();
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
        case RequestType of
            'copy':
                Request.SetRequestUri(StrSubstNo(UriEnvLbl, RestEnv."EOS Prod. Environment Name", OperationId));
            else
                exit;
        end;
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            if RaiseError then
                Error(GetLastErrorText());
    end;

    procedure UpdateLogRecords()
    var
        RestRequestsLog, RestRequestsLog2 : Record "EOS Restore Requests Log";
        Response: HttpResponseMessage;
    begin
        RestRequestsLog.Reset();
        RestRequestsLog.SetFilter("EOS Operation Status", '<>%1&<>%2', RestRequestsLog."EOS Operation Status"::Succeeded, RestRequestsLog."EOS Operation Status"::Failed);
        if RestRequestsLog.FindSet() then
            repeat
                Response := GetOperationDetails(RestRequestsLog."EOS Type", RestRequestsLog."EOS Operation Id", false);
                RestRequestsLog2.Get(RestRequestsLog."EOS Entry No.");
                SetLogFields(RestRequestsLog2, Response);
                RestRequestsLog2.Modify();
            until RestRequestsLog.Next() = 0;
    end;

    procedure UpdateLogStatus(RestRequestsLog: Record "EOS Restore Requests Log"; NewStatus: Enum "EOS Operation Status"; MessageText: Text[2048])
    begin
        RestRequestsLog."EOS Operation Status" := NewStatus;
        RestRequestsLog."EOS Operation Details" := MessageText;
        RestRequestsLog.Modify();
    end;

    local procedure InsertLogRecord(Response: HttpResponseMessage)
    var
        RestRequestsLog: Record "EOS Restore Requests Log";
    begin
        RestEnv.Get();
        if not RestEnv."EOS Enable Log" then
            exit;

        RestRequestsLog.Init();
        RestRequestsLog."EOS Entry No." := RestRequestsLog.GetNextEntryNo();
        RestRequestsLog."EOS Session Id" := SessionId();
        RestRequestsLog."EOS User Id" := CopyStr(UserId(), 1, MaxStrLen(RestRequestsLog."EOS User Id"));
        SetLogFields(RestRequestsLog, Response);
        RestRequestsLog.Insert();
    end;

    local procedure SetLogFields(var RestRequestsLog: Record "EOS Restore Requests Log"; Response: HttpResponseMessage)
    var
        Property, ResponseText : Text;
        JObject: JsonObject;
        JToken: JsonToken;
        Text000Lbl: Label 'Operation completed';
    begin
        Response.Content.ReadAs(ResponseText);
        if ResponseText = '' then
            exit;

        JObject.ReadFrom(ResponseText);
        foreach Property in JObject.Keys() do begin
            JObject.Get(Property, JToken);
            case Property of
                'id':
                    if IsNullGuid(RestRequestsLog."EOS Operation Id") then
                        Evaluate(RestRequestsLog."EOS Operation Id", JToken.AsValue().AsText());
                'type':
                    RestRequestsLog."EOS Type" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RestRequestsLog."EOS Type"));
                'status':
                    case JToken.AsValue().AsText() of
                        'scheduled':
                            RestRequestsLog."EOS Operation Status" := RestRequestsLog."EOS Operation Status"::Scheduled;
                        'running':
                            RestRequestsLog."EOS Operation Status" := RestRequestsLog."EOS Operation Status"::Running;
                        'succeeded':
                            begin
                                RestRequestsLog."EOS Operation Status" := RestRequestsLog."EOS Operation Status"::Succeeded;
                                RestRequestsLog."EOS Operation Details" := Text000Lbl;
                                RestRequestsLog.SetBlobFields(RestRequestsLog.FieldNo("EOS Operation Full Details"), Text000Lbl);
                            end;
                        'failed':
                            RestRequestsLog."EOS Operation Status" := RestRequestsLog."EOS Operation Status"::Failed;
                    end;
                'createdOn':
                    RestRequestsLog."EOS Operation Scheduled On" := JToken.AsValue().AsDateTime();
                'startedOn':
                    RestRequestsLog."EOS Operation Started On" := JToken.AsValue().AsDateTime();
                'completedOn':
                    RestRequestsLog."EOS Operation Completed On" := JToken.AsValue().AsDateTime();
                'errorMessage':
                    if JToken.AsValue().AsText() <> '' then begin
                        RestRequestsLog."EOS Operation Details" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RestRequestsLog."EOS Operation Details"));
                        RestRequestsLog.SetBlobFields(RestRequestsLog.FieldNo("EOS Operation Full Details"), JToken.AsValue().AsText());
                    end;
                'environmentName':
                    RestRequestsLog."EOS Environment" := CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RestRequestsLog."EOS Environment"));
            end;
        end;

        //Added beacause Admin Center api did not return the softDeleted operation. So we can't track it properly
        if RestRequestsLog."EOS Type" = 'softDelete' then begin
            RestRequestsLog."EOS Operation Status" := RestRequestsLog."EOS Operation Status"::Succeeded;
            RestRequestsLog."EOS Operation Started On" := RestRequestsLog."EOS Operation Scheduled On";
            RestRequestsLog."EOS Operation Completed On" := RestRequestsLog."EOS Operation Scheduled On";
        end;
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
        Text001Lbl: Label 'Delete Environment,Get Environment Status,Copy Environment';
        Text002Lbl: Label 'Operation Completed. Check the status of the environment in the admincenter or use the function Get Environment Status';
        Text003Lbl: Label 'Operation Completed. Environment %1 is currently in status %2.', Comment = '%1: Environment Name, %2: Status';
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
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", 'OnRefreshAllowedTables', '', true, false)]
    local procedure C3905_RetenPolAllowedTables_OnRefreshAllowedTables()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.AddAllowedTable(Database::"EOS Restore Requests Log");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure T472_OnAfterInsertEvent(var Rec: Record "Job Queue Entry")
    begin
        FindJobQueueInCompanies(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure T472_OnAfterModifyEvent(var Rec: Record "Job Queue Entry")
    begin
        FindJobQueueInCompanies(Rec);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Entries", OnBeforeActionEvent, 'RunInForeground', false, false)]
    local procedure P672_OnBeforeActionEvent(var Rec: Record "Job Queue Entry")
    begin
        SetRunOnce(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Entries", OnAfterActionEvent, 'RunInForeground', false, false)]
    local procedure P672_OnAfterActionEvent(var Rec: Record "Job Queue Entry")
    begin
        SetRunOnce(false);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Entry Card", OnBeforeActionEvent, 'RunInForeground', false, false)]
    local procedure P673_OnBeforeActionEvent(var Rec: Record "Job Queue Entry")
    begin
        SetRunOnce(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Job Queue Entry Card", OnAfterActionEvent, 'RunInForeground', false, false)]
    local procedure P673_OnAfterActionEvent(var Rec: Record "Job Queue Entry")
    begin
        SetRunOnce(false);
    end;

    procedure ShowJobQueueEntry()
    var
        JQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCard: Page "Job Queue Entry Card";
        Text000Lbl: Label 'Restore Environment (ENV)';
    begin
        JQueueEntry.Reset();
        JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
        JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
        JQueueEntry.ReadIsolation := IsolationLevel::ReadUncommitted;
        if JQueueEntry.IsEmpty() then begin
            //Not possible to use this function because automatically it will set the queue to "Ready", raising an error due to missing permission on the Microsoft account
            //JQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(JQueueEntry."Object Type to Run"::Codeunit, Codeunit::"EOS Restore Job Queue", RecId, '', 0, RunDateFormula, 0T);
            JQueueEntry.Init();
            JQueueEntry."Object Type to Run" := JQueueEntry."Object Type to Run"::Codeunit;
            JQueueEntry."Object ID to Run" := Codeunit::"EOS Restore Job Queue";
            JQueueEntry.Description := Text000Lbl;
            JQueueEntry.Status := JQueueEntry.Status::"On Hold";
            Evaluate(JQueueEntry."Next Run Date Formula", '<1D>');
            JQueueEntry.Validate("Next Run Date Formula");
            JQueueEntry.Insert(true);
            Commit();
        end else
            JQueueEntry.FindFirst();

        JobQueueEntryCard.SetTableView(JQueueEntry);
        JobQueueEntryCard.RunModal();
    end;

    local procedure FindJobQueueInCompanies(JobQueueEntry: Record "Job Queue Entry")
    var
        JQueueEntry: Record "Job Queue Entry";
        Company: Record Company;
        Text000Err: Label 'Job Queue %1 is already present in company %2. Open the setup in that specific company or delete and recreate the job queue entry.', Comment = '%1: Job Queue Name, %2: Company Name';
        Text001Err: Label 'Job Queue %1 is already present in the same company. Cannot create another one.', Comment = '%1: Job Queue Name';
    begin
        if (JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Codeunit) or (JobQueueEntry."Object ID to Run" <> Codeunit::"EOS Restore Job Queue") then
            exit;

        if IsRunOnce then
            exit;

        //Check in the current company if the job queue is already present
        JQueueEntry.Reset();
        JQueueEntry.SetFilter(SystemId, '<> %1', JobQueueEntry.SystemId);
        JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
        JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
        if not JQueueEntry.IsEmpty() then
            Error(Text001Err, Codeunit::"EOS Restore Job Queue");

        //Check if the job queue is already present in other companies
        Company.Reset();
        Company.SetFilter(Name, '<> %1', CompanyName);
        if Company.IsEmpty() then
            exit;

        Company.FindSet();
        repeat
            JQueueEntry.Reset();
            JQueueEntry.ChangeCompany(Company.Name);
            JQueueEntry.SetRange("Object Type to Run", JQueueEntry."Object Type to Run"::Codeunit);
            JQueueEntry.SetRange("Object ID to Run", Codeunit::"EOS Restore Job Queue");
            if not JQueueEntry.IsEmpty() then
                Error(Text000Err, Codeunit::"EOS Restore Job Queue", Company.Name);
        until Company.Next() = 0;
    end;

    procedure DeleteRestoreJobQueue()
    var
        Company: Record Company;
        JQueueEntry: Record "Job Queue Entry";
        Counter: Integer;
        Text000Lbl: Label 'Deleted %1 Job Queue Entries', Comment = '%1: Number of Job Queue Entries deleted';
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

    procedure SetRunOnce(RunOnce: Boolean)
    begin
        IsRunOnce := RunOnce;
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
        IsRunOnce: Boolean;

}
