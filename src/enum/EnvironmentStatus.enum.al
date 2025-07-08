enum 70001 "EOS Environment Status"
{
    Extensible = true;

    value(0; Active)
    {
        Caption = 'Active', Locked = true;
    }
    value(1; SoftDeleting)
    {
        Caption = 'Soft Deleting', Locked = true;
    }
    value(2; NotFound)
    {
        Caption = 'Not Found', Locked = true;
    }
    value(3; Preparing)
    {
        Caption = 'Preparing', Locked = true;
    }
}