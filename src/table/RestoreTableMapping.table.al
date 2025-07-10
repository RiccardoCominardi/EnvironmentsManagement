table 70001 "EOS Restore Table Mapping"
{
    DataClassification = CustomerContent;
    Caption = 'Table Mapping (ENV)';
    DataPerCompany = false;

    fields
    {
        field(1; "EOS Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "EOS Description"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Description';
        }
        field(3; "EOS Source Type"; Enum "EOS Source Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Source Type';
            trigger OnValidate()
            begin
                if Rec."EOS Source Type" = Rec."EOS Source Type"::"Database" then
                    Validate("EOS Source No.", '');
            end;
        }
        field(4; "EOS Source No."; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Source No.';
        }
        field(5; "EOS Type"; Enum "EOS Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
        }
        field(6; "EOS Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Table No.';
            BlankZero = true;
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnLookup()
            var
                NewObjectID: Integer;
                ObjType: option "TableData","Table",,"Report",,"Codeunit";
            begin
                if LookupObjectID(NewObjectID, ObjType::Table, Rec."EOS Table No.") then
                    Rec.Validate("EOS Table No.", NewObjectID);
            end;

            trigger OnValidate()
            var
                AllObj: Record AllObj;
                ObjType: option "TableData","Table",,"Report",,"Codeunit";
                ObjNotFoundErr: Label 'There is no Table with ID %1';
            begin
                if Rec."EOS Table No." = 0 then
                    exit;

                if not AllObj.Get(ObjType::Table, Rec."EOS Table No.") then
                    Error(ObjNotFoundErr, Rec."EOS Table No.");
            end;
        }
        field(7; "EOS Table Name"; Text[249])
        {
            Caption = 'Table Name';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = filter(Table), "Object ID" = field("EOS Table No.")));
            Editable = false;
        }
        field(8; "EOS Table Filter"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Table Filter';
        }
        field(9; "EOS Enabled"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Enabled';
        }
    }

    keys
    {
        key(Key1; "EOS Code") { Clustered = true; }
    }

    trigger OnDelete()
    var
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
    begin
        RestoreFieldMapping.Reset();
        RestoreFieldMapping.SetRange("EOS Code", Rec."EOS Code");
        RestoreFieldMapping.DeleteAll(true);
    end;

    procedure GetTableFilter() ValueAsText: Text
    var
        InStr: InStream;
    begin
        Rec.CalcFields("EOS Table Filter");
        Rec."EOS Table Filter".CreateInStream(InStr);
        InStr.Read(ValueAsText);
    end;

    procedure SetTableFilter(var Filters: Text)
    var
        RecRef: RecordRef;
        PageFilterBuilder: FilterPageBuilder;
        OutStr: outstream;
    begin
        RecRef.Open(Rec."EOS Table No.");

        PageFilterBuilder.AddTable(RecRef.Caption, RecRef.Number);
        if Filters <> '' then
            PageFilterBuilder.SetView(RecRef.Caption, Filters);
        if PageFilterBuilder.RunModal() then begin
            Filters := PageFilterBuilder.GetView(RecRef.Caption, true);
            Rec."EOS Table Filter".CreateOutStream(OutStr);
            OutStr.Write(Filters);
        end;
    end;

    procedure SetTableFilterNoUI(Filters: Text)
    var
        OutStr: outstream;
    begin
        Rec."EOS Table Filter".CreateOutStream(OutStr);
        OutStr.Write(Filters);
    end;

    procedure LookupObjectID(var NewObjectID: Integer; ObjType: option ,,,"Report",,"Codeunit"; ObjectId: Integer): Boolean
    var
        AllObjWithCaption: Record AllObjWithCaption;
        Objects: Page Objects;
    begin
        if AllObjWithCaption.Get(ObjType, ObjectId) then;

        AllObjWithCaption.FilterGroup(2);
        AllObjWithCaption.SetRange("Object Type", ObjType);
        AllObjWithCaption.FilterGroup(0);
        Objects.SetRecord(AllObjWithCaption);
        Objects.SetTableView(AllObjWithCaption);
        Objects.LookupMode := true;
        if Objects.RunModal() = Action::LookupOK then begin
            Objects.GetRecord(AllObjWithCaption);
            NewObjectID := AllObjWithCaption."Object ID";
            exit(true);
        end;

        exit(false);
    end;

}