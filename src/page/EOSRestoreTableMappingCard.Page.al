page 70002 "EOS Restore Table Mapping Card"
{
    Caption = 'Table Mapping (ENV)';
    PageType = Document;
    UsageCategory = None;
    RefreshOnActivate = true;
    SourceTable = "EOS Restore Table Mapping";
    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("EOS Code"; Rec."EOS Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the mapping.';
                    Editable = not Rec."EOS Enabled";
                }
                field("EOS Description"; Rec."EOS Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the mapping.';
                    Editable = not Rec."EOS Enabled";
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
                    Editable = not Rec."EOS Enabled";
                }
                field("EOS Source No."; Rec."EOS Source No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Source No. for the mapping.';
                    Editable = (Rec."EOS Source Type" = Rec."EOS Source Type"::Company) and not Rec."EOS Enabled";
                    Lookup = true;
                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Company: Record Company;
                        Companies: Page Companies;
                    begin
                        if Rec."EOS Source Type" <> Rec."EOS Source Type"::Company then
                            exit;

                        Company.Reset();
                        Companies.SetTableView(Company);
                        Companies.LookupMode(true);
                        if Companies.RunModal() <> Action::LookupOK then
                            exit;

                        Companies.GetRecord(Company);
                        Rec.Validate("EOS Source No.", Company.Name);
                    end;

                    trigger OnValidate()
                    var
                        Company: Record Company;
                    begin
                        if Rec."EOS Source Type" <> Rec."EOS Source Type"::Company then
                            exit;

                        Company.Get(Rec."EOS Source No.");
                    end;
                }
                field("EOS Type"; Rec."EOS Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of operation for the mapping.';
                    Editable = not Rec."EOS Enabled";
                }
                field("EOS Table No."; Rec."EOS Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table number for the mapping.';
                    Editable = not Rec."EOS Enabled";
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("EOS Table Name"; Rec."EOS Table Name")
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    StyleExpr = FieldColor;
                }
                field("EOS TableFilters"; TableFiltersLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    StyleExpr = FieldColor;
                    trigger OnDrillDown()
                    begin
                        if Rec."EOS Enabled" then
                            exit;

                        Rec.SetTableFilter(TableFilters);
                        CurrPage.Update(true);
                    end;
                }
            }
            part(FieldLines; "EOS Restore Table Mapping Sub")
            {
                ApplicationArea = Basic, Suite;
                Editable = not Rec."EOS Enabled";
                Visible = Rec."EOS Type" = Rec."EOS Type"::Modify;
                SubPageLink = "EOS Code" = field("EOS Code");
                UpdatePropagation = Both;
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
                ToolTip = 'Exports the current mapping to an Excel file.';
                Image = ExportToExcel;
                trigger OnAction()
                var
                    RestoreTableMapping: Record "EOS Restore Table Mapping";
                begin
                    RestoreTableMapping.Reset();
                    RestoreTableMapping.SetRange("EOS Code", Rec."EOS Code");
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
                ToolTip = 'Imports mapping data from an Excel file for the specified code.';
                Image = ImportExcel;
                trigger OnAction()
                begin
                    RestFieldsMapping.ImportExcelForSpecifCode(Rec."EOS Code");
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
    begin
        TableFilters := Rec.GetTableFilter();
        FieldColor := Format(PageStyle::StrongAccent);
    end;

    var
        RestFieldsMapping: Codeunit "EOS Restore Fields Mapping";
        RestMappingMgt: Codeunit "EOS Restore Mapping Mgt.";
        FieldColor, TableFilters : Text;
        TableFiltersLbl: Label 'Show filters applied';
}