permissionset 70000 "EOS Restore Env."
{
    Caption = 'Restore Environment (ENV)';
    Assignable = true;
    Permissions =
        table "EOS Restore Environment" = X,
        tabledata "EOS Restore Environment" = RIMD,
        table "EOS Restore Table Mapping" = X,
        tabledata "EOS Restore Table Mapping" = RIMD,
        table "EOS Restore Field Mapping" = X,
        tabledata "EOS Restore Field Mapping" = RIMD,
        table "EOS Restore Requests Log" = X,
        tabledata "EOS Restore Requests Log" = RIMD,
        codeunit "EOS Restore Environment Mgt" = X,
        codeunit "EOS Restore Job Queue" = X,
        codeunit "EOS Restore Fields Mapping" = X,
        codeunit "EOS Restore Mapping Mgt." = X,
        page "EOS Restore Environment" = X,
        page "EOS Restore Option Picker" = X,
        page "EOS Restore Requests Log" = X,
        page "EOS Restore Table Mapping Card" = X,
        page "EOS Restore Table Mapping List" = X,
        page "EOS Restore Table Mapping Sub" = X;
}