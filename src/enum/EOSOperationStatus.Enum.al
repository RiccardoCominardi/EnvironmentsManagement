enum 70006 "EOS Operation Status"
{
    Extensible = false;
    value(0; Queued)
    {
        Caption = 'Queued', Locked = true;
    }
    value(1; Scheduled)
    {
        Caption = 'Scheduled', Locked = true;
    }
    value(2; Running)
    {
        Caption = 'Running', Locked = true;
    }
    value(3; Succeeded)
    {
        Caption = 'Succeeded', Locked = true;
    }
    value(4; Failed)
    {
        Caption = 'Failed', Locked = true;
    }
    value(5; Canceled)
    {
        Caption = 'Canceled', Locked = true;
    }
    value(6; Skipped)
    {
        Caption = 'Skipped', Locked = true;
    }
}