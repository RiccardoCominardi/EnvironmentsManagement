page 70006 "EOS Restore Requests Log"
{
    Caption = 'Restore Requests Log (ENV)';
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
            repeater(Control1)
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
                field("EOS Type"; Rec."EOS Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies Request Type that has been requested.';
                }
                field("EOS Environment"; Rec."EOS Environment")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Environment where the request has been made.';
                }
                field("EOS Operation Id"; Rec."EOS Operation Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Operation Id present in the Admin Center.';
                    StyleExpr = FieldColor;
                    trigger OnDrillDown()
                    begin
                        CopyText(Rec."EOS Operation Id".ToText().TrimStart('{').TrimEnd('}'));
                    end;
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
                    trigger OnDrillDown()
                    begin
                        Message(Rec.GetBlobFields(Rec.FieldNo("EOS Operation Full Details")));
                        CurrPage.Update();
                    end;
                }
            }
            group(Control)
            {
                ShowCaption = false;
                usercontrol(CopyClipboard; "EOS Restore Copy Clipboard")
                {
                    ApplicationArea = All;
                    trigger OnControlReady()
                    begin
                        IsControlReady := true;
                    end;

                    trigger OnCopyCompleted()
                    begin
                        // Optional: Handle copy completed event if needed
                    end;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(AdminCenter)
            {
                ApplicationArea = All;
                Caption = 'Admin Center', Locked = true;
                ToolTip = 'Open the Admin Center';
                Image = Administration;
                trigger OnAction()
                var
                    AzureADTenant: Codeunit "Azure AD Tenant";
                    Text000Lbl: Label 'https://businesscentral.dynamics.com/%1/admin', Locked = true;
                begin
                    Hyperlink(StrSubstNo(Text000Lbl, AzureADTenant.GetAadTenantId()));
                end;
            }
            action(CopyOperationId)
            {
                ApplicationArea = All;
                Caption = 'Copy Operation Id';
                ToolTip = 'Copy the Operation Id to clipboard';
                Image = Copy;
                trigger OnAction()
                begin
                    CopyText(Rec."EOS Operation Id".ToText().TrimStart('{').TrimEnd('}'));
                end;
            }
        }
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
            action(SetAsSkipped)
            {
                ApplicationArea = All;
                Caption = 'Set As Skipped';
                ToolTip = 'Manually set the selected log entry as Skipped. The status will not be updated any further.';
                Image = ChangeStatus;
                trigger OnAction()
                var
                    Text000Lbl: Label 'Manually Skipped';
                begin
                    RestEnvMgt.UpdateLogStatus(Rec, Rec."EOS Operation Status"::Skipped, Text000Lbl);
                end;
            }
        }
        area(Promoted)
        {
            group(AdminCenterGroup)
            {
                Caption = 'Admin Center', Locked = true;
                ShowAs = SplitButton;
                actionref(AdminCenter_Promoted; AdminCenter) { }
                actionref(CopyOperationId_Promoted; CopyOperationId) { }
            }
            actionref(UpdateStatus_Promoted; UpdateStatus) { }
            actionref(SetAsSkipped_Promoted; SetAsSkipped) { }
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
            Rec."EOS Operation Status"::Running:
                FieldColor := Format(PageStyle::Ambiguous);
            Rec."EOS Operation Status"::Skipped:
                FieldColor := Format(PageStyle::AttentionAccent);
            Rec."EOS Operation Status"::Succeeded:
                FieldColor := Format(PageStyle::Favorable);
            Rec."EOS Operation Status"::Failed:
                FieldColor := Format(PageStyle::Unfavorable);
        end;
    end;

    procedure CopyText(TextToCopy: Text)
    begin
        if IsControlReady then
            CurrPage.CopyClipboard.CopyToClipboard(TextToCopy);
    end;

    var
        RestEnvMgt: Codeunit "EOS Restore Environment Mgt";
        FieldColor: Text;
        IsControlReady: Boolean;
}