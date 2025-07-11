page 70005 "EOS Restore Option Picker"
{
    PageType = List;
    Caption = 'Pick';
    UsageCategory = None;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Name; Rec.Value)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        txtOption: Text;
        index: Integer;
    begin
        RecRef.Open(TableID, true);
        FldRef := RecRef.Field(FldNo);

        if FldRef.Type <> FldRef.Type::Option then
            exit;

        foreach txtOption in FldRef.OptionCaption.Split(',') do begin
            index += 1;
            Rec.AddNewEntry(Format(index), txtOption);
        end;
    end;

    procedure SetParameter(pTableID: Integer; pFieldNo: Integer)
    begin
        TableID := pTableID;
        FldNo := pFieldNo;
    end;

    var
        TableID, FldNo : Integer;
}