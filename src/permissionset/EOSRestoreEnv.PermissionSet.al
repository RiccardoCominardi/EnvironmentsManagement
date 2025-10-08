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
        codeunit "EOS Restore Environment Mgt" = X,
        codeunit "EOS Restore Job Queue" = X,
        codeunit "EOS Restore Fields Mapping" = X,
        codeunit "EOS Restore Mapping Mgt." = X;
}