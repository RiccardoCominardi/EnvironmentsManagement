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
                    Editable = Rec."EOS Source Type" = Rec."EOS Source Type"::Company;
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
                }
                field("EOS Table No."; Rec."EOS Table No.")
                {
                    ApplicationArea = All;
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
                        Rec.SetTableFilter(TableFilters);
                        CurrPage.Update(true);
                    end;
                }
            }
            part(FieldLines; "EOS Restore Table Mapping Sub")
            {
                ApplicationArea = Basic, Suite;
                Editable = Rec."EOS Type" = Rec."EOS Type"::Modify;
                Enabled = Rec."EOS Type" = Rec."EOS Type"::Modify;
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
                    RestMappingMgt.ExecuteReplaceMappingFromAPI(false, Rec."EOS Code");
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
                    RestoreTableMapping.SetRange("EOS Code", Rec."EOS Code");
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
        TableFiltersLbl: Label 'Show Filters Applied';
}