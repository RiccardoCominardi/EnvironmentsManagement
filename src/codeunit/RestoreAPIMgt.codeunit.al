codeunit 70003 "EOS Restore API Mgt."
{
    trigger OnRun()
    begin

    end;

    var
        RestFieldsMapping: Codeunit "EOS Restore Fields Mapping";
        Text000Lbl: Label 'Operation Completed';

    procedure ExecuteReplaceMapping(HideDialog: Boolean; RestoreCode: Code[20])
    var
        SourceEnv: Enum "Environment Type";
        DestinationEnv: Enum "Environment Type";
    begin
        if RestoreCode <> '' then
            RestFieldsMapping.SetRestoreCode(RestoreCode);

        RestFieldsMapping.ClearCompanyConfigFields(CompanyName(), SourceEnv::Production, DestinationEnv::Sandbox);
        RestFieldsMapping.ClearDatabaseConfigFields(SourceEnv::Production, DestinationEnv::Sandbox);

        if not HideDialog then
            if GuiAllowed() then
                Message(Text000Lbl);
    end;

    procedure ExecuteReplaceMappingFromAPI(HideDialog: Boolean; RestoreCode: Code[20])
    var
        Company: Record Company;
        RestEnv: Record "EOS Restore Environment";
        RestEnvMgt: Codeunit "EOS Restore Environment Mgt";
        AzureADTenant: Codeunit "Azure AD Tenant";
        TempBlob: Codeunit "Temp Blob";
        Headers: HttpHeaders;
        Client: HttpClient;
        Content: HttpContent;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        HttpMethod: Enum "Http Method";
        InStr: InStream;
        ContentTypeLbl: Label 'application/json', Locked = true;
        UriLbl: Label 'https://api.businesscentral.dynamics.com/v2.0/%1/%2/api/eos/eosenv/v2.0/companies(%3)/alignTableMappings', Locked = true;
    //Test. Used for testing with a specific tenant and company
    //UriTestLbl: Label 'https://api.businesscentral.dynamics.com/v2.0/1f976128-8bbe-4ad7-a713-cbf76c27a7e0/%1/api/eos/eosenv/v2.0/companies(121e8c1c-5ae6-ee11-a203-6045bde98bac)/alignTableMappings', Locked = true;
    begin
        RestEnv.Get();
        Company.Get(CompanyName());

        //Authentication
        Headers := Client.DefaultRequestHeaders();
        Headers.Add('Authorization', SecretText.SecretStrSubstNo('Bearer %1', RestEnvMgt.GetToken()));

        //Set Headers
        Content.GetHeaders(Headers);
        if Headers.Contains('Content-Type') then
            Headers.Remove('Content-Type');
        Headers.Add('Content-Type', ContentTypeLbl);

        //Set Body
        CreateAlignJsonToSend(TempBlob, RestoreCode);
        TempBlob.CreateInStream(InStr);
        Content.WriteFrom(InStr);

        //Set Request
        Request.Method := Format(HttpMethod::POST);
        Request.SetRequestUri(StrSubstNo(UriLbl, AzureADTenant.GetAadTenantId(), RestEnv."EOS New Environment Name", GetGuidAsText(Company.Id)));
        //Test. Used this for testing with a specific tenant and company
        //Request.SetRequestUri(StrSubstNo(UriTestLbl, RestEnv."EOS New Environment Name", GetGuidAsText(Company.Id)));
        Request.Content(Content);

        if not Client.Send(Request, Response) then
            Error(GetLastErrorText());

        if not HideDialog then
            if GuiAllowed() then
                Message(Text000Lbl);
    end;

    local procedure CreateAlignJsonToSend(var TempBlob: Codeunit "Temp Blob"; MappingCode: Code[20])
    var
        Base64Convert: Codeunit "Base64 Convert";
        JsonBody: Text;
        JsonBodyLbl: label '{"eosCode": "ENV","payloadBase64": "%1"}', Locked = true;
        OutStr: OutStream;
    begin
        JsonBody := StrSubstNo(JsonBodyLbl, Base64Convert.ToBase64(CreateJsonToAlignTablesMapping(MappingCode)));
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(JsonBody);
    end;

    local procedure CreateJsonToAlignTablesMapping(MappingCode: Code[20]) ResultAsText: Text
    var
        RestTableMapping: Record "EOS Restore Table Mapping";
        RestFieldMapping: Record "EOS Restore Field Mapping";
        JObject, JObjectLine : JsonObject;
        JArray, JArrayLines : JsonArray;
    begin
        RestTableMapping.Get(MappingCode);

        JObject.Add('code', RestTableMapping."EOS Code");
        JObject.Add('description', RestTableMapping."EOS Description");
        JObject.Add('sourceType', RestTableMapping."EOS Source Type".AsInteger());
        JObject.Add('sourceNo', RestTableMapping."EOS Source No.");
        JObject.Add('type', RestTableMapping."EOS Type".AsInteger());
        JObject.Add('tableNo', RestTableMapping."EOS Table No.");
        JObject.Add('tableFilter', RestTableMapping.GetTableFilter());
        JObject.Add('enabled', RestTableMapping."EOS Enabled");

        RestFieldMapping.Reset();
        RestFieldMapping.SetRange("EOS Code", RestTableMapping."EOS Code");
        RestFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestFieldMapping.IsEmpty() then
            exit;

        RestFieldMapping.FindSet();
        repeat
            Clear(JObjectLine);
            JObjectLine.Add('lineNo', RestFieldMapping."EOS Line No.");
            JObjectLine.Add('fieldNo', RestFieldMapping."EOS Field No.");
            JObjectLine.Add('replaceType', RestFieldMapping."EOS Replace Type".AsInteger());
            JObjectLine.Add('replaceValue', RestFieldMapping."EOS Replace Value");
            JArrayLines.Add(JObjectLine);
        until RestFieldMapping.Next() = 0;

        JObject.Add('fields', JArrayLines);
        JArray.Add(JObject);

        JObject.WriteTo(ResultAsText);
    end;

    procedure AlignTablesMapping(payloadBase64: Text; ExecuteReplace: Boolean)
    var
        RestTableMapping: Record "EOS Restore Table Mapping";
        Base64Convert: Codeunit "Base64 Convert";
        JObject: JsonObject;
        JToken: JsonToken;
    begin
        JObject.ReadFrom(Base64Convert.FromBase64(payloadBase64));

        if JObject.Get('code', JToken) then
            if not RestTableMapping.Get(JToken.AsValue().AsCode()) then begin
                RestTableMapping.Init();
                RestTableMapping.Validate("EOS Code", JToken.AsValue().AsCode());
                RestTableMapping.Insert();
            end;
        if JObject.Get('description', JToken) then
            RestTableMapping.Validate("EOS Description", CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RestTableMapping."EOS Description")));
        if JObject.Get('sourceType', JToken) then
            RestTableMapping.Validate("EOS Source Type", Enum::"EOS Source Types".FromInteger(JToken.AsValue().AsInteger()));
        if JObject.Get('sourceNo', JToken) then
            RestTableMapping.Validate("EOS Source No.", CopyStr(JToken.AsValue().AsText(), 1, MaxStrLen(RestTableMapping."EOS Source No.")));
        if JObject.Get('type', JToken) then
            RestTableMapping.Validate("EOS Type", Enum::"EOS Types".FromInteger(JToken.AsValue().AsInteger()));
        if JObject.Get('tableNo', JToken) then
            RestTableMapping.Validate("EOS Table No.", JToken.AsValue().AsInteger());
        if JObject.Get('tableFilter', JToken) then
            RestTableMapping.SetTableFilterNoUI(JToken.AsValue().AsText());
        if JObject.Get('enabled', JToken) then
            RestTableMapping.Validate("EOS Enabled", JToken.AsValue().AsBoolean());
        RestTableMapping.Modify();

        JObject.Get('fields', JToken);
        AlignFieldsMapping(RestTableMapping, JToken.AsArray());

        if ExecuteReplace then
            ExecuteReplaceMapping(true, RestTableMapping."EOS Code");
    end;

    local procedure AlignFieldsMapping(RestTableMapping: Record "EOS Restore Table Mapping"; JArray: JsonArray)
    var
        RestFieldMapping: Record "EOS Restore Field Mapping";
        JToken, JCurrToken : JsonToken;
    begin
        RestFieldMapping.Reset();
        RestFieldMapping.SetRange("EOS Code", RestTableMapping."EOS Code");
        RestFieldMapping.DeleteAll(true);

        foreach JToken in JArray do begin
            RestFieldMapping.Init();
            RestFieldMapping.Validate("EOS Code", RestTableMapping."EOS Code");
            RestFieldMapping.Validate("EOS Table No.", RestTableMapping."EOS Table No.");
            if JToken.AsObject().Get('lineNo', JCurrToken) then
                RestFieldMapping.Validate("EOS Line No.", JCurrToken.AsValue().AsInteger());
            if JToken.AsObject().Get('fieldNo', JCurrToken) then
                RestFieldMapping.Validate("EOS Field No.", JCurrToken.AsValue().AsInteger());
            if JToken.AsObject().Get('replaceType', JCurrToken) then
                RestFieldMapping.Validate("EOS Replace Type", Enum::"EOS Replace Types".FromInteger(JCurrToken.AsValue().AsInteger()));
            if JToken.AsObject().Get('replaceValue', JCurrToken) then
                RestFieldMapping.Validate("EOS Replace Value", CopyStr(JCurrToken.AsValue().AsText(), 1, MaxStrLen(RestFieldMapping."EOS Replace Value")));
            RestFieldMapping.Insert();
        end;
    end;

    procedure GetGuidAsText(GuidToConvert: Guid): Text
    begin
        exit(LowerCase(Format(GuidToConvert, 0, 4)));
    end;
}