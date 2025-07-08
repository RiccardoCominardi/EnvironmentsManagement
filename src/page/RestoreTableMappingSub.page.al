page 70003 "EOS Restore Table Mapping Sub"
{
    AutoSplitKey = true;
    Caption = 'Fields';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "EOS Restore Field Mapping";

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("EOS Line No."; Rec."EOS Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
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
}