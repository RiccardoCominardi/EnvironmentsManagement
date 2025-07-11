page 70003 "EOS Restore Table Mapping Sub"
{
    AutoSplitKey = true;
    Caption = 'Fields';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "EOS Restore Field Mapping";
    SourceTableView = sorting("EOS Table No.", "EOS Field No.");
    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("EOS Field No."; Rec."EOS Field No.")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("EOS Field Name"; Rec."EOS Field Name")
                {
                    ApplicationArea = All;
                }
                field("EOS Replace Type"; Rec."EOS Replace Type")
                {
                    ApplicationArea = All;
                }
                field("EOS Replace Value"; Rec."EOS Replace Value")
                {
                    ApplicationArea = All;
                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if LookupFieldValue(Text) then
                            Rec.Validate("EOS Replace Value", CopyStr(Text, 1, MaxStrLen(Rec."EOS Replace Value")));
                    end;
                }
            }
        }
    }
    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetDefaultFields();
    end;

    local procedure SetDefaultFields()
    var
        RestTableMapping: Record "EOS Restore Table Mapping";
    begin
        if RestTableMapping.Get(Rec."EOS Code") then
            Rec."EOS Table No." := RestTableMapping."EOS Table No.";
    end;

    local procedure LookupFieldValue(var FieldValue: Text): Boolean
    var
        RestFieldsMapping: Codeunit "EOS Restore Fields Mapping";
    begin
        if Rec."EOS Field No." = 0 then
            exit(false);

        if RestFieldsMapping.LookupFieldValueFromLine(Rec, FieldValue) then
            exit(true)
        else
            exit(RestFieldsMapping.LookupFieldOptionFromLine(Rec, FieldValue));
    end;
}