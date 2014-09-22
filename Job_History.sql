USE msdb
GO

EXEC dbo.sp_help_jobhistory
@run_status=0;