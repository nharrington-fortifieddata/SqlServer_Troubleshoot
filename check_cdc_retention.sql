SELECT [retention]
  FROM [msdb].[dbo].[cdc_jobs]
  WHERE [database_id] = 15
  AND [job_type] = 'cleanup'