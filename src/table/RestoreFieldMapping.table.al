table 70002 "EOS Restore Field Mapping"
{
    DataClassification = CustomerContent;
    Caption = 'Field Mapping (ENV)';
    DataPerCompany = false;

    fields
    {
        field(1; "EOS Code"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Code';
        }
        field(2; "EOS Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(3; "EOS Table No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Table No.';
        }
        field(4; "EOS Field No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Field No.';
            BlankZero = true;
            trigger OnLookup()
            var
                NewFieldID: Integer;
            begin
                if LookupFieldsID(NewFieldID, Rec."EOS Table No.", Rec."EOS Field No.") then
                    Rec.Validate("EOS Field No.", NewFieldID);
            end;

            trigger OnValidate()
            var
                Field: Record Field;
                ObjNotFoundErr: Label 'There is no field with ID %1 in table %2.';
            begin
                if Rec."EOS Field No." = 0 then
                    exit;

                if not Field.Get(Rec."EOS Table No.", Rec."EOS Field No.") then
                    Error(ObjNotFoundErr, Rec."EOS Table No.", Rec."EOS Field No.");

                CheckDuplicatedField();
            end;
        }
        field(5; "EOS Field Name"; Text[80])
        {
            Caption = 'Field Name';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("EOS Table No."), "No." = field("EOS Field No.")));
            Editable = false;
        }
        field(6; "EOS Replace Type"; Enum "EOS Replace Types")
        {
            DataClassification = CustomerContent;
            Caption = 'Replace Type';
        }
        field(7; "EOS Replace Value"; Text[1024])
        {
            DataClassification = CustomerContent;
            Caption = 'Replace Value';
        }
    }

    keys
    {
        key(Key1; "EOS Code", "EOS Line No.") { Clustered = true; }
    }


    procedure GetNextLineNo()
    var
        RestoreFieldMapping: Record "EOS Restore Field Mapping";
    begin
        RestoreFieldMapping.Reset();
        RestoreFieldMapping.SetRange("EOS Code", Rec."EOS Code");
        RestoreFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if not RestoreFieldMapping.IsEmpty() then
            RestoreFieldMapping.FindLast();

        Rec."EOS Line No." := RestoreFieldMapping."EOS Line No." + 10000;
    end;

    local procedure CheckDuplicatedField()
    var
        RestFieldMapping: Record "EOS Restore Field Mapping";
        Text000Err: Label 'Field No. %1 is already used';
    begin
        RestFieldMapping.Reset();
        RestFieldMapping.SetRange("EOS Code", Rec."EOS Code");
        RestFieldMapping.SetRange("EOS Field No.", Rec."EOS Field No.");
        RestFieldMapping.ReadIsolation := IsolationLevel::ReadUncommitted;
        if RestFieldMapping.IsEmpty() then
            exit;

        Error(Text000Err, Rec."EOS Field No.");
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

    procedure LookupFieldsID(var NewFieldNo: Integer; TableNo: Integer; FieldNo: Integer): Boolean
    var
        Field: Record Field;
        FieldsLookup: Page "Fields Lookup";
    begin
        if Field.Get(TableNo, FieldNo) then;

        Field.FilterGroup(2);
        Field.SetRange(TableNo, TableNo);
        Field.FilterGroup(0);
        FieldsLookup.SetRecord(Field);
        FieldsLookup.SetTableView(Field);
        FieldsLookup.LookupMode := true;
        if FieldsLookup.RunModal() = Action::LookupOK then begin
            FieldsLookup.GetRecord(Field);
            NewFieldNo := Field."No.";
            exit(true);
        end;
        exit(false);
    end;
}