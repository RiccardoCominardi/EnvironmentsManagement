page 70001 "EOS Restore Table Mapping List"
{
    Caption = 'Table Mapping List (ENV)';
    CardPageID = "EOS Restore Table Mapping Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS Restore Table Mapping";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("EOS Code"; Rec."EOS Code")
                {
                    ApplicationArea = All;
                }
                field("EOS Description"; Rec."EOS Description")
                {
                    ApplicationArea = All;
                }
                field("EOS Enabled"; Rec."EOS Enabled")
                {
                    ApplicationArea = All;
                }
                field("EOS Source Type"; Rec."EOS Source Type")
                {
                    ApplicationArea = All;
                }
                field("EOS Source No."; Rec."EOS Source No.")
                {
                    ApplicationArea = All;
                }
                field("EOS Type"; Rec."EOS Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(InfoMapping)
            {
                ApplicationArea = All;
                Caption = 'Info Mapping', Locked = true;
                Image = Info;
                trigger OnAction()
                begin
                    RestFieldsMapping.ShowInfoMapping();
                end;
            }
            action(ExecuteReplaceMapping)
            {
                ApplicationArea = All;
                Caption = 'Execute Replace Mapping';
                Image = "Invoicing-MDL-Send";
                trigger OnAction()
                begin
                    RestoreAPIMgt.ExecuteReplaceMappingFromAPI(false, Rec."EOS Code");
                end;
            }
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export To Excel';
                Image = ExportToExcel;
                trigger OnAction()
                var
                    RestoreTableMapping: Record "EOS Restore Table Mapping";
                begin
                    RestoreTableMapping.Reset();
                    CurrPage.SetSelectionFilter(RestoreTableMapping);
                    RestFieldsMapping.ExportExcel(RestoreTableMapping);
                end;
            }
            action(ExportExcelStructure)
            {
                ApplicationArea = All;
                Caption = 'Export Excel Structure';
                Image = ExportToExcel;
                trigger OnAction()
                begin
                    RestFieldsMapping.ExportExcelStructure();
                end;
            }
            action(ImportFromExcel)
            {
                ApplicationArea = All;
                Caption = 'Import From Excel';
                Image = ImportExcel;
                trigger OnAction()
                begin
                    RestFieldsMapping.ImportExcel();
                end;
            }
        }
        area(Promoted)
        {
            actionref(InfoMapping_Promoted; InfoMapping) { }
            actionref(ExecuteReplaceMapping_Promoted; ExecuteReplaceMapping) { }
            group(ExportExcel)
            {
                Caption = 'Export To Excel';
                ShowAs = SplitButton;
                actionref(ExportToExcel_Promoted; ExportToExcel) { }
                actionref(ExportExcelStructure_Promoted; ExportExcelStructure) { }
            }
            actionref(ImportFromExcel_Promoted; ImportFromExcel) { }
        }
    }

    trigger OnOpenPage()
    var
        RestEnv: Record "EOS Restore Environment";
    begin
        RestEnv.Get();
        if not RestEnv."EOS Info Mapping Message Shown" then begin
            RestFieldsMapping.ShowInfoMapping();
            RestEnv.Get();
        end;
    end;

    var
        RestFieldsMapping: Codeunit "EOS Restore Fields Mapping";
        RestoreAPIMgt: Codeunit "EOS Restore API Mgt.";
}