codeunit 70002 "EOS Restore Fields Mapping"
{
    trigger OnRun()
    begin

    end;

    var
        GlobalRestoreCode: Code[20];


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearCompanyConfig', '', false, false)]
    local procedure C1886_OnClearCompanyConfig(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        //First to be executed
        ClearCompanyConfigFields(CompanyName, SourceEnv, DestinationEnv);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Cleanup", 'OnClearDatabaseConfig', '', false, false)]
    local procedure C1886_OnClearDatabaseConfig(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        //Second to be executed
        ClearDatabaseConfigFields(SourceEnv, DestinationEnv);
    end;

    internal procedure ClearCompanyConfigFields(CompanyName: Text; SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        if not CheckIsFromProduction(SourceEnv, DestinationEnv) then
            exit;

        ClearCompanyConfigFields_Delete(CompanyName);
        ClearCompanyConfigFields_Modify(CompanyName);
    end;

    local procedure ClearCompanyConfigFields_Modify(CompanyName: Text)
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
    begin
        RestoreTableMapping.Reset();
        if GlobalRestoreCode <> '' then
            RestoreTableMapping.SetRange("EOS Code", GlobalRestoreCode);
        RestoreTableMapping.SetRange("EOS Source Type", RestoreTableMapping."EOS Source Type"::Company);
        RestoreTableMapping.SetRange("EOS Source No.", CompanyName);
        RestoreTableMapping.SetRange("EOS Type", RestoreTableMapping."EOS Type"::Modify);
        RestoreTableMapping.SetRange("EOS Enabled", true);
        RestoreTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestoreTableMapping.IsEmpty() then
            exit;

        RestoreTableMapping.FindSet();
        repeat
            ClearFromRestoreFieldsMapping(RestoreTableMapping);
        until RestoreTableMapping.Next() = 0;
    end;

    local procedure ClearCompanyConfigFields_Delete(CompanyName: Text)
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
    begin
        RestoreTableMapping.Reset();
        if GlobalRestoreCode <> '' then
            RestoreTableMapping.SetRange("EOS Code", GlobalRestoreCode);
        RestoreTableMapping.SetRange("EOS Source Type", RestoreTableMapping."EOS Source Type"::Company);
        RestoreTableMapping.SetRange("EOS Source No.", CompanyName);
        RestoreTableMapping.SetRange("EOS Type", RestoreTableMapping."EOS Type"::Delete);
        RestoreTableMapping.SetRange("EOS Enabled", true);
        RestoreTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestoreTableMapping.IsEmpty() then
            exit;

        RestoreTableMapping.FindSet();
        repeat
            DeleteFromRestoreTableMapping(CompanyName, RestoreTableMapping);
        until RestoreTableMapping.Next() = 0;
    end;

    internal procedure ClearDatabaseConfigFields(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type")
    begin
        if not CheckIsFromProduction(SourceEnv, DestinationEnv) then
            exit;

        ClearDatabaseConfigFields_Delete();
        ClearDatabaseConfigFields_Modify();
    end;

    local procedure ClearDatabaseConfigFields_Delete()
    var
        Company: Record Company;
        RestoreTableMapping: Record "EOS Restore Table Mapping";
    begin
        RestoreTableMapping.Reset();
        if GlobalRestoreCode <> '' then
            RestoreTableMapping.SetRange("EOS Code", GlobalRestoreCode);
        RestoreTableMapping.SetRange("EOS Source Type", RestoreTableMapping."EOS Source Type"::Database);
        RestoreTableMapping.SetRange("EOS Type", RestoreTableMapping."EOS Type"::Delete);
        RestoreTableMapping.SetRange("EOS Enabled", true);
        RestoreTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestoreTableMapping.IsEmpty() then
            exit;

        RestoreTableMapping.FindSet();
        repeat
            Company.Reset();
            Company.FindSet();
            repeat
                DeleteFromRestoreTableMapping(Company.Name, RestoreTableMapping);
            until Company.Next() = 0;
        until RestoreTableMapping.Next() = 0;
    end;

    local procedure ClearDatabaseConfigFields_Modify()
    var
        Company: Record Company;
        RestoreTableMapping: Record "EOS Restore Table Mapping";
    begin
        RestoreTableMapping.Reset();
        if GlobalRestoreCode <> '' then
            RestoreTableMapping.SetRange("EOS Code", GlobalRestoreCode);
        RestoreTableMapping.SetRange("EOS Source Type", RestoreTableMapping."EOS Source Type"::Database);
        RestoreTableMapping.SetRange("EOS Type", RestoreTableMapping."EOS Type"::Modify);
        RestoreTableMapping.SetRange("EOS Enabled", true);
        RestoreTableMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestoreTableMapping.IsEmpty() then
            exit;

        RestoreTableMapping.FindSet();
        repeat
            Company.Reset();
            Company.FindSet();
            repeat
                ClearFromRestoreFieldsMapping(Company.Name, RestoreTableMapping);
            until Company.Next() = 0;
        until RestoreTableMapping.Next() = 0;
    end;

    local procedure DeleteFromRestoreTableMapping(CompanyName: Text; RestoreTableMapping: Record "EOS Restore Table Mapping")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(RestoreTableMapping."EOS Table No.");
        RecRef.ChangeCompany(CompanyName);
        RecRef.Reset();
        if RestoreTableMapping.GetTableFilter() <> '' then
            RecRef.SetView(RestoreTableMapping.GetTableFilter());
        RecRef.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not RecRef.IsEmpty() then
            RecRef.DeleteAll(true);
    end;

    local procedure ClearFromRestoreFieldsMapping(CompanyName: Text; RestoreTableMapping: Record "EOS Restore Table Mapping")
    var
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
    begin
        RestoreFieldMapping.Reset();
        RestoreFieldMapping.SetRange("EOS Code", RestoreTableMapping."EOS Code");
        RestoreFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not RestoreFieldMapping.IsEmpty() then begin
            RestoreFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
            RestoreFieldMapping.FindSet();
            repeat
                UpdateValueFromRestore(CompanyName, RestoreTableMapping.GetTableFilter(), RestoreFieldMapping);
            until RestoreFieldMapping.Next() = 0;
        end
    end;

    local procedure ClearFromRestoreFieldsMapping(RestoreTableMapping: Record "EOS Restore Table Mapping")
    begin
        RestoreTableMapping.TestField("EOS Source Type", RestoreTableMapping."EOS Source Type"::Company);
        ClearFromRestoreFieldsMapping(RestoreTableMapping."EOS Source No.", RestoreTableMapping);
    end;

    local procedure UpdateValueFromRestore(CompanyName: Text; TableFilters: Text; RestoreFieldMapping: Record "EOS Restore Field Mapping")
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(RestoreFieldMapping."EOS Table No.");
        RecRef.ChangeCompany(CompanyName);
        RecRef.Reset();
        if TableFilters <> '' then
            RecRef.SetView(TableFilters);
        RecRef.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not RecRef.IsEmpty() then begin
            RecRef.FindSet();
            repeat
                FldRef := RecRef.Field(RestoreFieldMapping."EOS Field No.");
                if FldRef.Class <> FldRef.Class::Normal then
                    continue;

                UpdateFieldRefValue(FldRef, RestoreFieldMapping."EOS Replace Type", RestoreFieldMapping."EOS Replace Value");
                RecRef.Modify();
            until RecRef.Next() = 0;
        end;
    end;

    local procedure UpdateFieldRefValue(var FldRef: FieldRef; ReplaceTypes: Enum "EOS Replace Types"; ValueAsText: Text)
    var
        ConfigValidateMgt: Codeunit "Config. Validate Management";
        ValueAsVariant: Variant;
    begin
        case ReplaceTypes of
            ReplaceTypes::Assignee:
                ConfigValidateMgt.EvaluateValue(FldRef, ValueAsText, false);
            ReplaceTypes::"Assignee (With Validation)":
                ConfigValidateMgt.EvaluateValueWithValidate(FldRef, ValueAsText, true);
        end;
    end;

    procedure LookupFieldValueFromLine(RestFieldMapping: Record "EOS Restore Field Mapping"; var FieldValue: Text): Boolean
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        RecVar: Variant;
        LookupTableId, LookupPageId, LookupFieldId : Integer;
    begin
        GetLookupParameters(RestFieldMapping, LookupTableId, LookupPageId, LookupFieldId);
        if (LookupTableId = 0) or (LookupPageId = 0) or (LookupFieldId = 0) then
            exit(false);

        RecRef.Open(LookupTableId);
        RecVar := RecRef;
        if Page.RunModal(LookupPageId, RecVar) = Action::LookupOK then begin
            RecRef.GetTable(RecVar);
            FldRef := RecRef.Field(LookupFieldId);
            FieldValue := Format(FldRef.Value);
            exit(true);
        end;

        exit(false);
    end;

    local procedure GetLookupParameters(RestFieldMapping: Record "EOS Restore Field Mapping"; var LookupTableId: Integer; var LookupPageId: Integer; var LookupFieldId: Integer)
    var
        TableMetadata: Record "Table Metadata";
        TableRelationsMetadata: Record "Table Relations Metadata";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        TableRelationsMetadata.Reset();
        TableRelationsMetadata.SetRange("Table ID", RestFieldMapping."EOS Table No.");
        TableRelationsMetadata.SetRange("Field No.", RestFieldMapping."EOS Field No.");
        TableRelationsMetadata.ReadIsolation := IsolationLevel::ReadUncommitted;
        if TableRelationsMetadata.IsEmpty() then
            exit;

        RecRef.Open(RestFieldMapping."EOS Table No.");
        FldRef := RecRef.Field(RestFieldMapping."EOS Field No.");
        if not TableMetadata.Get(FldRef.Relation) then
            exit;

        LookupTableId := TableMetadata.ID;
        LookupPageId := TableMetadata.LookupPageID;

        TableRelationsMetadata.SetRange("Related Table ID", TableMetadata.ID);
        if not TableRelationsMetadata.FindFirst() then
            exit;

        LookupFieldId := TableRelationsMetadata."Related Field No.";
    end;

    procedure LookupFieldOptionFromLine(RestFieldMapping: Record "EOS Restore Field Mapping"; var FieldValue: Text): Boolean
    var
        TempNameValBuf: Record "Name/Value Buffer" temporary;
        RestOptionPicker: Page "EOS Restore Option Picker";
    begin
        RestOptionPicker.LookupMode := true;
        RestOptionPicker.SetParameter(RestFieldMapping."EOS Table No.", RestFieldMapping."EOS Field No.");
        if RestOptionPicker.RunModal() = Action::LookupOK then begin
            RestOptionPicker.GetRecord(TempNameValBuf);
            FieldValue := TempNameValBuf.Value;
            exit(true);
        end;
    end;

    local procedure CheckIsFromProduction(SourceEnv: Enum "Environment Type"; DestinationEnv: Enum "Environment Type"): Boolean
    begin
        if SourceEnv <> SourceEnv::Production then
            exit;

        if DestinationEnv <> DestinationEnv::Sandbox then
            exit;

        exit(true);
    end;

    procedure ExportExcelStructure()
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileNameLbl: Label 'Restore Mapping', Locked = true;
        SheetLbl: Label 'Mapping', Locked = true;
    begin
        if not TempExcelBuffer.IsTemporary then
            exit;

        InsertExcelHeader(TempExcelBuffer);

        //Download a file
        TempExcelBuffer.CreateNewBook(SheetLbl);
        TempExcelBuffer.WriteSheet('', CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(FileNameLbl);
        TempExcelBuffer.OpenExcel()
    end;

    procedure ExportExcel(var RestoreTableMapping: Record "EOS Restore Table Mapping")
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        FileNameLbl: Label 'Restore Mapping', Locked = true;
        SheetLbl: Label 'Mapping', Locked = true;
    begin
        if not TempExcelBuffer.IsTemporary then
            exit;

        if RestoreTableMapping.IsEmpty() then
            exit;

        RestoreTableMapping.FindSet();
        InsertExcelHeader(TempExcelBuffer);
        repeat
            InsertExcelLines(RestoreTableMapping, TempExcelBuffer);
        until RestoreTableMapping.Next() = 0;

        //Download a file
        TempExcelBuffer.CreateNewBook(SheetLbl);
        TempExcelBuffer.WriteSheet('', CompanyName, UserId);
        TempExcelBuffer.CloseBook();
        TempExcelBuffer.SetFriendlyFilename(FileNameLbl);
        TempExcelBuffer.OpenExcel()
    end;

    local procedure InsertExcelHeader(var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
    begin
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Code"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Description"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Source Type"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Source No."), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Type"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Table No."), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Table Name"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Table Filter"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.FieldCaption("EOS Enabled"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreFieldMapping.FieldCaption("EOS Field No."), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreFieldMapping.FieldCaption("EOS Field Name"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreFieldMapping.FieldCaption("EOS Replace Type"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreFieldMapping.FieldCaption("EOS Replace Value"), false, '', true, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure InsertExcelLines(RestoreTableMapping: Record "EOS Restore Table Mapping"; var TempExcelBuffer: Record "Excel Buffer" temporary)
    begin
        case RestoreTableMapping."EOS Type" of
            RestoreTableMapping."EOS Type"::Delete:
                InsertExcelLineDelete(RestoreTableMapping, TempExcelBuffer);
            RestoreTableMapping."EOS Type"::Modify:
                InsertExcelLinesModify(RestoreTableMapping, TempExcelBuffer);
        end;
    end;

    local procedure InsertExcelLineDelete(RestoreTableMapping: Record "EOS Restore Table Mapping"; var TempExcelBuffer: Record "Excel Buffer" temporary)
    begin
        TempExcelBuffer.NewRow();
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Description", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Source Type", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Source No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Type", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Table No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Table Name", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping.GetTableFilter(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Enabled", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        TempExcelBuffer.AddColumn('', false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
    end;

    local procedure InsertExcelLinesModify(RestoreTableMapping: Record "EOS Restore Table Mapping"; var TempExcelBuffer: Record "Excel Buffer" temporary)
    var
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
    begin
        RestoreFieldMapping.Reset();
        RestoreFieldMapping.SetRange("EOS Code", RestoreTableMapping."EOS Code");
        RestoreFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestoreFieldMapping.IsEmpty() then
            exit;

        RestoreFieldMapping.FindSet();
        repeat
            TempExcelBuffer.NewRow();
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Code", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Description", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Source Type", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Source No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Type", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Table No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Table Name", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping.GetTableFilter(), false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreTableMapping."EOS Enabled", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreFieldMapping."EOS Field No.", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreFieldMapping."EOS Field Name", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreFieldMapping."EOS Replace Type", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
            TempExcelBuffer.AddColumn(RestoreFieldMapping."EOS Replace Value", false, '', false, false, false, '', TempExcelBuffer."Cell Type"::Text);
        until RestoreFieldMapping.Next() = 0;
    end;

    procedure ImportExcel()
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        InStr: InStream;
        Result: Boolean;
        Text000Qst: Label 'This action will delete and recreate all lines based on Excel files. Continue?';
        Text000Lbl: Label 'Invalid File';
        Text001Lbl: Label 'Import Completed';
    begin
        if GuiAllowed() then
            if not RestoreTableMapping.IsEmpty() then
                if not Confirm(Text000Qst, true) then
                    exit;

        TempBlob.CreateInStream(InStr);
        FileName := FileManagement.BLOBImport(TempBlob, FileName);

        RestoreTableMapping.Reset();
        RestoreTableMapping.DeleteAll(true);
        Result := ProcessExcelFile(InStr);

        if not Result then
            Message(Text000Lbl)
        else
            Message(Text001Lbl);
    end;

    procedure ImportExcelForSpecifCode(RestoreCode: Code[20])
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
        InStr: InStream;
        Result: Boolean;
        Text000Qst: Label 'This action will delete and recreate code %1 based on Excel files. Continue?';
        Text000Lbl: Label 'Invalid File';
        Text001Lbl: Label 'Import Completed';
    begin
        if GuiAllowed() then
            if not Confirm(StrSubstNo(Text000Qst, RestoreCode), true) then
                exit;

        TempBlob.CreateInStream(InStr);
        FileName := FileManagement.BLOBImport(TempBlob, FileName);

        RestoreTableMapping.Reset();
        RestoreTableMapping.SetRange("EOS Code", RestoreCode);
        RestoreTableMapping.DeleteAll(true);
        Result := ProcessExcelFile(InStr);

        if not Result then
            Message(Text000Lbl)
        else
            Message(Text001Lbl);
    end;

    local procedure ProcessExcelFile(var InStr: InStream): Boolean
    var
        RestoreTableMapping: Record "EOS Restore Table Mapping";
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
        TempExcelBuffer: Record "Excel Buffer" temporary;
        CurrExcelRow, NoOfRecords : Integer;
        Window: Dialog;
        Text000Lbl: Label 'Import Records: #1########';
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        TempExcelBuffer.OpenBookStream(InStr, TempExcelBuffer.SelectSheetsNameStream(InStr));
        TempExcelBuffer.ReadSheet();
        TempExcelBuffer.SetFilter("Row No.", '>%1', 1);
        if TempExcelBuffer.IsEmpty() then
            exit(false);

        CurrExcelRow := 0;

        TempExcelBuffer.FindSet();
        if GuiAllowed() then
            Window.Open(Text000Lbl);
        repeat
            if (CurrExcelRow <> TempExcelBuffer."Row No.") or (CurrExcelRow = 0) then begin
                NoOfRecords += 1;
                if GuiAllowed() then
                    Window.Update(1, NoOfRecords);

                //Modify the record before create a new one
                if RestoreTableMapping."EOS Code" <> '' then
                    RestoreTableMapping.Modify();

                if RestoreFieldMapping."EOS Code" <> '' then
                    RestoreFieldMapping.Modify();
            end;

            CurrExcelRow := TempExcelBuffer."Row No.";

            case TempExcelBuffer."Column No." of
                1:
                    if not RestoreTableMapping.Get(TempExcelBuffer."Cell Value as Text") then begin
                        RestoreTableMapping.Init();
                        RestoreTableMapping."EOS Code" := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(RestoreTableMapping."EOS Code"));
                        RestoreTableMapping.Insert();
                    end;
                2:
                    RestoreTableMapping."EOS Description" := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(RestoreTableMapping."EOS Description"));
                3:
                    RestoreTableMapping."EOS Source Type" := EvaluateSourceTypeEnum(TempExcelBuffer."Cell Value as Text");
                4:
                    RestoreTableMapping."EOS Source No." := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(RestoreTableMapping."EOS Source No."));
                5:
                    RestoreTableMapping."EOS Type" := EvaluateTypeEnum(TempExcelBuffer."Cell Value as Text");
                6:
                    Evaluate(RestoreTableMapping."EOS Table No.", TempExcelBuffer."Cell Value as Text");
                7:
                    ;//Table Name not used. Only for information
                8:
                    RestoreTableMapping.SetTableFilterNoUI(TempExcelBuffer."Cell Value as Text");
                9:
                    RestoreTableMapping."EOS Enabled" := GetBooleanFromText(TempExcelBuffer."Cell Value as Text");
                10:
                    begin
                        RestoreFieldMapping.Init();
                        RestoreFieldMapping."EOS Code" := RestoreTableMapping."EOS Code";
                        RestoreFieldMapping.GetNextLineNo();
                        RestoreFieldMapping."EOS Table No." := RestoreTableMapping."EOS Table No.";
                        Evaluate(RestoreFieldMapping."EOS Field No.", TempExcelBuffer."Cell Value as Text");
                        RestoreFieldMapping.Insert(true);
                    end;
                11:
                    ;//Field Name not used. Only for information
                12:
                    RestoreFieldMapping."EOS Replace Type" := EvaluateReplaceTypeEnum(TempExcelBuffer."Cell Value as Text");
                13:
                    RestoreFieldMapping."EOS Replace Value" := CopyStr(TempExcelBuffer."Cell Value as Text", 1, MaxStrLen(RestoreFieldMapping."EOS Replace Value"));
            end;
        until TempExcelBuffer.Next() = 0;

        //Modify last record of the file
        if RestoreTableMapping."EOS Code" <> '' then
            RestoreTableMapping.Modify();

        if RestoreFieldMapping."EOS Code" <> '' then
            RestoreFieldMapping.Modify();

        if GuiAllowed() then
            Window.Close();

        exit(true);
    end;

    procedure EvaluateSourceTypeEnum(EnumAsText: Text) SourceType: Enum "EOS Source Types"
    var
        Index, OrdinalValue : Integer;
    begin
        Index := SourceType.Names.IndexOf(EnumAsText);
        OrdinalValue := SourceType.Ordinals.Get(Index);
        SourceType := Enum::"EOS Source Types".FromInteger(OrdinalValue);
    end;

    procedure EvaluateReplaceTypeEnum(EnumAsText: Text) ReplaceType: Enum "EOS Replace Types"
    var
        Index, OrdinalValue : Integer;
    begin
        Index := ReplaceType.Names.IndexOf(EnumAsText);
        OrdinalValue := ReplaceType.Ordinals.Get(Index);
        ReplaceType := Enum::"EOS Replace Types".FromInteger(OrdinalValue);
    end;

    procedure EvaluateTypeEnum(EnumAsText: Text) Types: Enum "EOS Types"
    var
        Index, OrdinalValue : Integer;
    begin
        Index := Types.Names.IndexOf(EnumAsText);
        OrdinalValue := Types.Ordinals.Get(Index);
        Types := Enum::"EOS Types".FromInteger(OrdinalValue);
    end;

    local procedure GetBooleanFromText(BooleanAsText: Text): Boolean
    begin
        if UpperCase(CopyStr(BooleanAsText, 1, 1)) in ['T', 'Y', '1', 'S'] then
            exit(true)
        else
            exit(false);
    end;

    internal procedure SetRestoreCode(RestoreCode: Code[20])
    begin
        GlobalRestoreCode := RestoreCode;
    end;

    procedure ShowInfoMapping()
    var
        RestEnv: Record "EOS Restore Environment";
        Text000Lbl: Label 'General information for mapping \\1. Codes with "Source Type" field equal to Company will be executed before Database\\2. Codes with "Type" field equal to Delete will be executed before Modify\\3. Export Excel will export all the mapping details, include the non necessary fields (Table Name - Field Name) only for better comprehension\\4. Import Excel will import the mapping details deleting and recreating everythings. The structure must be the same generated from the export action. The unecessary fields (Table Name - Field Name) will not be considered in import functionality. You can leave it blanks but must be in the file.\\5. Executing the "Import From Excel" action from the card will delete only the specific code. From the list will clean every codes.';
    begin
        RestEnv.Get();
        if not RestEnv."EOS Info Mapping Message Shown" then begin
            RestEnv."EOS Info Mapping Message Shown" := true;
            RestEnv.Modify();
        end;

        Message(Text000Lbl);
    end;
}