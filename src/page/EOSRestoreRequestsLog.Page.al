page 70006 "EOS Restore Requests Log"
{
    Caption = 'Restore Requests Log (WSC)';
    PageType = List;
    UsageCategory = None;
    SourceTable = "EOS Restore Requests Log";
    SourceTableView = sorting("EOS Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(GroupName)
            {
                field("EOS Entry No."; Rec."EOS Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Entry No. of the request.';
                }
                field("EOS Session Id"; Rec."EOS Session Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Session Id associated with the request.';
                }
                field("EOS User Id"; Rec."EOS User Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the User Id who made the request.';
                }
                field("EOS Request Type"; Rec."EOS Request Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Request Type that has been requested.';
                }
                field("EOS Environment"; Rec."EOS Environment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Environment where the request has been made.';
                }
                field("EOS Operation Status"; Rec."EOS Operation Status")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Status present in the Admin Center.';
                    StyleExpr = FieldColor;
                }
                field("EOS Operation Scheduled On"; Rec."EOS Operation Scheduled On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Scheduled On date present in the Admin Center.';
                    StyleExpr = FieldColor;
                }
                field("EOS Operation Started On"; Rec."EOS Operation Started On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Started On date present in the Admin Center.';
                    StyleExpr = FieldColor;
                }
                field("EOS Operation Completed On"; Rec."EOS Operation Completed On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Completed On date present in the Admin Center.';
                    StyleExpr = FieldColor;
                }
                field("EOS Operation Details"; Rec."EOS Operation Details")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Details present in the Admin Center.';
                    StyleExpr = FieldColor;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(UpdateStatus)
            {
                ApplicationArea = All;
                Caption = 'Update Status';
                Image = Refresh;
                trigger OnAction()
                begin
                    RestEnvMgt.UpdateLogRecords();
                end;
            }
            action(ShowFullMessage)
            {
                ApplicationArea = All;
                Caption = 'Show Full Message';
                Image = Text;

                trigger OnAction()
                begin
                    Message(Rec.GetBlobFields(Rec.FieldNo("EOS Operation Full Details")));
                end;
            }
        }
        area(Promoted)
        {
            actionref(UpdateStatus_Promoted; UpdateStatus) { }
            actionref(ShowFullMessage_Promoted; ShowFullMessage) { }
        }
    }

    trigger OnOpenPage()
    begin
        RestEnvMgt.UpdateLogRecords();
    end;

    trigger OnAfterGetRecord()
    begin
        SetLineColors();
    end;

    local procedure SetLineColors()
    begin
        FieldColor := Format(PageStyle::Standard);

        case Rec."EOS Operation Status" of
            Rec."EOS Operation Status"::Succeeded:
                FieldColor := Format(PageStyle::Favorable);
            Rec."EOS Operation Status"::Failed:
                FieldColor := Format(PageStyle::Unfavorable);
        end;
    end;

    var
        RestEnvMgt: Codeunit "EOS Restore Environment Mgt";
        FieldColor: Text;

}