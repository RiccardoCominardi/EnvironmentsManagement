table 70003 "EOS Restore Requests Log"
{
    DataClassification = CustomerContent;
    Caption = 'Restore Requests Log (ENV)';
    DataPerCompany = false;

    fields
    {
        field(1; "EOS Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Entry No.';
        }
        field(2; "EOS Session Id"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Session Id';
        }
        field(3; "EOS User Id"; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'User Id';
        }
        field(4; "EOS Type"; Text[30])
        {
            DataClassification = CustomerContent;
            Caption = 'Type';
        }
        field(5; "EOS Environment"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Environment';
        }
        field(6; "EOS Operation Id"; Guid)
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Id';
        }
        field(7; "EOS Operation Status"; Enum "EOS Operation Status")
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Status';
        }
        field(8; "EOS Operation Scheduled On"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Scheduled On';
        }
        field(9; "EOS Operation Started On"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Started On';
        }
        field(10; "EOS Operation Completed On"; DateTime)
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Completed On';
        }
        field(11; "EOS Operation Details"; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Details';
        }
        field(12; "EOS Operation Full Details"; Blob)
        {
            DataClassification = CustomerContent;
            Caption = 'Operation Full Details', Locked = true;
        }
    }

    keys
    {
        key(Key1; "EOS Entry No.") { Clustered = true; }
    }

    [InherentPermissions(PermissionObjectType::TableData, Database::"EOS Restore Requests Log", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(Database::"EOS Restore Requests Log"));
    end;

    procedure SetBlobFields(BlobFieldNo: Integer; NewText: Text)
    var
        OutStr: OutStream;
    begin
        case BlobFieldNo of
            Rec.FieldNo("EOS Operation Full Details"):
                begin
                    Clear(Rec."EOS Operation Full Details");
                    Rec."EOS Operation Full Details".CreateOutStream(OutStr, TextEncoding::UTF8);
                end;
            else
                exit;
        end;

        OutStr.WriteText(NewText);
    end;

    procedure GetBlobFields(BlobFieldNo: Integer): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        case BlobFieldNo of
            Rec.FieldNo("EOS Operation Full Details"):
                begin
                    Rec.CalcFields("EOS Operation Full Details");
                    Rec."EOS Operation Full Details".CreateInStream(InStr, TextEncoding::UTF8);
                    exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStr, TypeHelper.LFSeparator(), Rec.FieldName("EOS Operation Full Details")));
                end;
        end;
    end;
}