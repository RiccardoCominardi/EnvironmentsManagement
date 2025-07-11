page 70004 "EOS Align Table Mapping"
{
    PageType = API;
    APIPublisher = 'eos';
    APIGroup = 'eosenv';
    APIVersion = 'v2.0';
    Caption = 'Align Table Mapping', Locked = true;
    EntityName = 'alignTableMapping';
    EntitySetName = 'alignTableMappings';
    SourceTable = "EOS Restore Table Mapping";
    Permissions = tabledata "EOS Restore Table Mapping" = RIMD,
                  tabledata "EOS Restore Environment" = RIMD;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(eosCode; Rec."EOS Code") { }
                field(payloadBase64; payloadBase64) { }
                field(executeReplace; executeReplace) { }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        RestMappingMgt.AlignTablesMapping(payloadBase64, executeReplace);
        exit(false) // Prevent the record from being inserted into the table
    end;

    var
        RestMappingMgt: Codeunit "EOS Restore Mapping Mgt.";
        payloadBase64: Text;
        executeReplace: Boolean;
}