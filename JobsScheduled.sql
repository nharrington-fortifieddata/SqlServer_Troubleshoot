SELECT DISTINCT substring( a.name ,1, 100) AS [Job Name],
        'Enabled'=case
        WHEN a. enabled = 0 THEN 'No'
        WHEN a. enabled = 1 THEN 'Yes'
        end,
        substring(b .name, 1,30 ) AS [Name of the schedule],
        'Frequency'=case
        WHEN b. freq_type = 1 THEN 'Once'
        WHEN b. freq_type = 4 THEN 'Daily'
        WHEN b. freq_type = 8 THEN 'Weekly'
        WHEN b. freq_type = 16 THEN 'Monthly'
        WHEN b. freq_type = 32 THEN 'Monthly relative'    
        WHEN b. freq_type = 32 THEN 'Execute when SQL Server Agent starts'
        END,   
		'Day of the Week'=case
		WHEN (b. freq_type = 1 and b. freq_interval = 1) THEN 'Once'
		WHEN (b. freq_type = 4 and b. freq_interval = 1) THEN 'Every Day'
		WHEN (b. freq_type = 4 and b. freq_interval = 2) THEN 'Every Other Day'
        WHEN (b. freq_type = 8 or b. freq_type = 32) and b.freq_interval = 1 THEN 'Sunday'
		WHEN (b. freq_type = 8 or b. freq_type = 32) and b.freq_interval = 2 THEN 'Monday'
		WHEN (b. freq_type = 8 and b.freq_interval = 4) or (b. freq_type = 32 and b.freq_interval = 3)  THEN 'Tuesday'
		WHEN (b. freq_type = 8 and b.freq_interval = 8) or (b. freq_type = 32 and b.freq_interval = 4) THEN 'Wednesday'
        WHEN (b. freq_type = 8 and b.freq_interval = 16) or (b. freq_type = 32 and b.freq_interval = 5) THEN 'Thursday'
		WHEN (b. freq_type = 8 and b.freq_interval = 32) or (b. freq_type = 32 and b.freq_interval = 6) THEN 'Friday'
		WHEN (b. freq_type = 8 and b.freq_interval = 64) or (b. freq_type = 32 and b.freq_interval = 7) THEN 'Saturday'
		WHEN (b. freq_type = 8 and b.freq_interval = 62) THEN 'M-F'
        WHEN (b. freq_type = 32 and b.freq_interval = 8) THEN 'Day'
        WHEN (b. freq_type = 32 and b.freq_interval = 9) THEN 'Weekday'
        WHEN (b. freq_type = 32 and b.freq_interval = 10) THEN 'Weekend Day' 
		ELSE 'Error'
        END,
		'Monthly Interval'=case
        WHEN (b. freq_type = 32 and b.freq_relative_interval = 1) THEN 'First'
		WHEN (b. freq_type = 32 and b.freq_relative_interval = 2) THEN 'Second'
		WHEN (b. freq_type = 32 and b.freq_relative_interval = 4) THEN 'Third'
		WHEN (b. freq_type = 32 and b.freq_relative_interval = 8) THEN 'Fourth'
		WHEN (b. freq_type = 32 and b.freq_relative_interval = 16) THEN 'Last'
		Else 'N/A'   
        END,
		'Number'=case
		WHEN b. freq_subday_type = 1 THEN NULL
		ELSE b.freq_subday_interval
		END,
        'Interval'=case
        WHEN b. freq_subday_type = 1 THEN 'At the specified time'
        WHEN b. freq_subday_type = 2 THEN 'Seconds'
        WHEN b. freq_subday_type = 4 THEN 'Minutes'
        WHEN b. freq_subday_type = 8 THEN 'Hours'
        END,   
		Stuff(Stuff (right('000000'+ Cast(c .next_run_time as Varchar),6 ),3, 0,':' ),6, 0,':' ) as Run_Time, 
        cast(cast (b. active_start_date as varchar(15 )) as datetime) as active_start_date,   
        cast(cast (b. active_end_date as varchar(15 )) as datetime) as active_end_date,         
        convert(varchar (24), b.date_created ) as Created_Date
       
FROM  msdb. dbo.sysjobs a
INNER JOIN msdb.dbo .sysJobschedules c ON a.job_id = c. job_id
INNER JOIN msdb.dbo .SysSchedules b on b.Schedule_id =c. Schedule_id
GO
  