page 70000 "EOS Restore Environment"
{
    ApplicationArea = All;
    Caption = 'Restore Environment (ENV)';
    AdditionalSearchTerms = 'Restore', Locked = true;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "EOS Restore Environment";
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Connection';
                field("EOS Client Id"; Rec."EOS Client Id")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        Rec."EOS Connection Is Up" := false;
                    end;
                }
                field("EOS Secret Id"; SecretId)
                {
                    ApplicationArea = All;
                    Caption = 'Secret Id', Locked = true;
                    ExtendedDatatype = Masked;
                    trigger OnValidate()
                    var
                        SecretIdValue: SecretText;
                    begin
                        SecretIdValue := SecretId;
                        Rec.SetToken(Rec."EOS Secret Id", SecretIdValue);
                        Rec."EOS Connection Is Up" := false;
                    end;
                }
                field("EOS Secret Due Date"; Rec."EOS Secret Due Date")
                {
                    ApplicationArea = All;
                }
                field("EOS Connection Is Up"; Rec."EOS Connection Is Up")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                group(Token)
                {
                    Caption = 'Token', Locked = true;
                    field(EOSToken; Rec.HasToken(Rec."EOS Token"))
                    {
                        Caption = 'Token Present';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field("EOS Token Authorization Time"; Rec."EOS Token Authorization Time")
                    {
                        Caption = 'Authorization Time';
                        ApplicationArea = All;
                        Editable = false;
                    }
                    field(EOSTokenStatus; TokenStatus)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        StyleExpr = TokenColor;
                    }
                }
            }
            group(Options)
            {
                Caption = 'Options';

                field("EOS Prod. Environment Name"; Rec."EOS Prod. Environment Name")
                {
                    ApplicationArea = All;
                    //Test. Disable "Editable" properties to change the environment name manually
                    Editable = false;
                }
                field("EOS New Environment Name"; Rec."EOS New Environment Name")
                {
                    ApplicationArea = All;
                }
                group(Delete)
                {
                    Caption = 'Delete';
                    field("EOS Waiting Time Type"; Rec."EOS Waiting Time Type")
                    {
                        ApplicationArea = All;
                    }
                    field("EOS Waiting Fixed Time (ms)"; Rec."EOS Waiting Fixed Time (ms)")
                    {
                        ApplicationArea = All;
                        Editable = Rec."EOS Waiting Time Type" = Rec."EOS Waiting Time Type"::"Fixed Time";
                    }
                    field("EOS Wait. Time Attempt (ms)"; Rec."EOS Wait. Time Attempt (ms)")
                    {
                        ApplicationArea = All;
                        Editable = Rec."EOS Waiting Time Type" = Rec."EOS Waiting Time Type"::"After Deletion";
                    }
                    field("EOS Max No. Of Attemps"; Rec."EOS Max No. Of Attemps")
                    {
                        ApplicationArea = All;
                        Editable = Rec."EOS Waiting Time Type" = Rec."EOS Waiting Time Type"::"After Deletion";
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(TryConnection)
            {
                ApplicationArea = All;
                Caption = 'Try Connection';
                Image = Link;
                trigger OnAction()
                begin
                    RestEnvMgt.TryConnection();
                    CurrPage.Update();
                end;
            }
            action(ExecuteFunction)
            {
                ApplicationArea = All;
                Caption = 'Execute Function';
                Image = "Invoicing-MDL-Send";
                trigger OnAction()
                begin
                    RestEnvMgt.ExecuteFunctionsUI();
                end;
            }

            action(ExecuteRestore)
            {
                ApplicationArea = All;
                Caption = 'Execute Restore';
                Image = "Invoicing-MDL-Send";
                trigger OnAction()
                begin
                    RestEnvMgt.RestoreEnvironment();
                end;
            }
            action(OpenFieldsMapping)
            {
                ApplicationArea = All;
                Caption = 'Open Fields Mapping';
                Image = OpenJournal;
                trigger OnAction()
                begin
                    Page.RunModal(Page::"EOS Restore Table Mapping List");
                end;
            }
            action(JobQueueEntryFlow)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Job Queue Entry';
                Image = JobListSetup;

                trigger OnAction()
                begin
                    RestEnvMgt.JobQueueEntry();
                end;
            }
            action(DeleteJobQueueEntryFlow)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete Job Queue Entry';
                Image = Delete;

                trigger OnAction()
                begin
                    RestEnvMgt.DeleteRestoreJobQueue();
                end;
            }
        }

        area(Promoted)
        {
            actionref(TryConnection_Promoted; TryConnection) { }
            actionref(ExecuteFunction_Promoted; ExecuteFunction) { }
            actionref(ExecuteRestore_Promoted; ExecuteRestore) { }
            actionref(OpenFieldsMapping_Promoted; OpenFieldsMapping) { }
            actionref(JobQueueEntryFlow_Promoted; JobQueueEntryFlow) { }
            actionref(DeleteJobQueueEntryFlow_Promoted; DeleteJobQueueEntryFlow) { }
        }
    }

    trigger OnOpenPage()
    begin
        //Test. Disable "CheckConfiguration" for testing in a sandbox environment
        CheckConfiguration();

        SecretId := ' ';

        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec."EOS Prod. Environment Name" := CopyStr(EnvInfo.GetEnvironmentName(), 1, MaxStrLen(Rec."EOS Prod. Environment Name"));
            Rec.Insert();
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        SetTokenFields();
    end;

    local procedure CheckConfiguration()
    var
        Text000Err: Label 'This configuration is allowed only in a production environment.';
    begin
        if not EnvInfo.IsProduction() then
            Error(Text000Err);
    end;

    local procedure SetTokenFields()
    var
        Text000Lbl: Label 'No Token';
        Text001Lbl: Label 'Token Expired';
        Text002Lbl: Label 'Token Available';
    begin
        TokenColor := Format(PageStyle::Standard);
        TokenStatus := Text000Lbl;
        if IsExpiredToken(Rec."EOS Token Authorization Time", Rec."EOS Token Expires In") then begin
            TokenStatus := Text001Lbl;
            TokenColor := Format(PageStyle::Unfavorable);
        end else begin
            TokenStatus := Text002Lbl;
            TokenColor := Format(PageStyle::Favorable);
        end;
    end;

    local procedure IsExpiredToken(ParTokenAuth: DateTime; ParExpireIn: Integer): Boolean
    var
        ElapsedSecs: Integer;
    begin
        if ParTokenAuth = 0DT then
            exit(true);

        ElapsedSecs := Round((CurrentDateTime() - ParTokenAuth) / 1000, 1, '>');
        if (ElapsedSecs < ParExpireIn) and (ElapsedSecs < 3600) then
            exit(false)
        else
            exit(true);
    end;

    var
        RestEnvMgt: Codeunit "EOS Restore Environment Mgt";
        EnvInfo: Codeunit "Environment Information";
        TokenStatus, TokenColor : Text;

    protected var
        SecretId: Text;
}