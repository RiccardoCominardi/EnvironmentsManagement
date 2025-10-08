page 70001 "EOS Restore Table Mapping List"
{
    Caption = 'Table Mapping List (ENV)';
    CardPageID = "EOS Restore Table Mapping Card";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "EOS Restore Table Mapping";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("EOS Code"; Rec."EOS Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the mapping.';
                }
                field("EOS Description"; Rec."EOS Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the mapping.';
                }
                field("EOS Enabled"; Rec."EOS Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether the mapping is enabled.';
                }
                field("EOS Source Type"; Rec."EOS Source Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the source type for the mapping.';
                }
                field("EOS Source No."; Rec."EOS Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Source No. for the mapping.';
                }
                field("EOS Type"; Rec."EOS Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of operation for the mapping.';
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
                ToolTip = 'Shows detailed information about the mapping.';
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
                ToolTip = 'Executes the replacement of mappings, on the new environment, based on the selected code.';
                Image = "Invoicing-MDL-Send";
                trigger OnAction()
                begin
                    RestMappingMgt.ExecuteReplaceMappingFromAPI(false, Rec."EOS Code");
                end;
            }
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export To Excel';
                ToolTip = 'Exports the selected mappings to an Excel file.';
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
                ToolTip = 'Exports the structure of the mapping to an Excel file.';
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
                ToolTip = 'Imports mapping data from an Excel file for all codes.';
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
        RestMappingMgt: Codeunit "EOS Restore Mapping Mgt.";
}