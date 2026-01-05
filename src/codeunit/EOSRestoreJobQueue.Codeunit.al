codeunit 70001 "EOS Restore Job Queue"
{
    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin
        RestEnvMgt.RestoreEnvironment();

        RestEnvMgt.UpdateLogRecords();
    end;

    var

        RestEnvMgt: Codeunit "EOS Restore Environment Mgt";
}