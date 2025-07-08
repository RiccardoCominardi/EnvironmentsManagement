page 70004 "EOS Table Mapping API List"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eosenv';
    APIVersion = 'v2.0';
    Caption = 'Table Mapping List', Locked = true;
    EntityName = 'tableMapping';
    EntitySetName = 'tableMappings';
    SourceTable = "EOS Restore Table Mapping";
    Permissions = tabledata "EOS Restore Table Mapping" = RIMD,
                  tabledata "EOS Restore Environment" = RIMD;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataAccessIntent = ReadOnly;
    ODataKeyFields = systemId;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(systemId; Rec.SystemId) { }
                field(eosCode; Rec."EOS Code") { }
            }
        }
    }

    [ServiceEnabled]
    procedure executeAllReplaceMappings(var actionContext: WebServiceActionContext)
    begin
        RestFieldsMapping.ExecuteReplaceMappingUI();
        actionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    [ServiceEnabled]
    procedure executeReplaceMapping(var actionContext: WebServiceActionContext)
    var
        RestTableMapping: Record "EOS Restore Table Mapping";
    begin
        GetMapping(RestTableMapping);
        RestFieldsMapping.ExecuteReplaceMappingUI(RestTableMapping."EOS Code");
        actionContext.SetResultCode(WebServiceActionResultCode::Updated);
    end;

    local procedure GetMapping(var RestTableMapping: Record "EOS Restore Table Mapping")
    begin
        if not RestTableMapping.GetBySystemId(Rec.SystemId) then
            Error(CannotFindMappingErr);
    end;

    var
        RestFieldsMapping: Codeunit "EOS Restore Fields Mapping";
        CannotFindMappingErr: Label 'The mapping cannot be found.';

}