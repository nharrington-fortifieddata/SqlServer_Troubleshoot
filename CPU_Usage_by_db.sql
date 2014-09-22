/******************* #1 **********************/
SELECT
      dbs.name
    , cacheobjtype
    , total_cpu_time
    , total_execution_count
FROM
      (
        SELECT TOP 10
            SUM(qs.total_worker_time) AS total_cpu_time
          , SUM(qs.execution_count) AS total_execution_count
          , COUNT(*) AS number_of_statements
          , qs.plan_handle
        FROM
            sys.dm_exec_query_stats qs
        GROUP BY
            qs.plan_handle
        ORDER BY
            SUM(qs.total_worker_time) DESC
      ) a
      INNER JOIN (
                   SELECT
                        plan_handle
                      , pvt.dbid
                      , cacheobjtype
                   FROM
                        (
                          SELECT
                              plan_handle
                            , epa.attribute
                            , epa.value
                            , cacheobjtype
                          FROM
                              sys.dm_exec_cached_plans
                              OUTER APPLY sys.dm_exec_plan_attributes(plan_handle) AS epa
     /* WHERE cacheobjtype = 'Compiled Plan' AND objtype = 'adhoc' */
                        ) AS ecpa PIVOT ( MAX(ecpa.value) FOR ecpa.attribute IN ( "dbid" , "sql_handle" ) ) AS pvt
                 ) b
            ON a.plan_handle = b.plan_handle
      INNER JOIN sys.databases dbs
            ON dbid = dbs.database_id;


/******************* #2 **********************/
WITH  DB_CPU_Stats
        AS (
             SELECT
                  DatabaseID
                , DB_NAME(DatabaseID) AS [DatabaseName]
                , SUM(total_worker_time) AS [CPU_Time_Ms]
             FROM
                  sys.dm_exec_query_stats AS qs
                  CROSS APPLY (
                                SELECT
                                    CONVERT(INT , value) AS [DatabaseID]
                                FROM
                                    sys.dm_exec_plan_attributes(qs.plan_handle)
                                WHERE
                                    attribute = N'dbid'
                              ) AS F_DB
             GROUP BY
                  DatabaseID
           )
      SELECT
            ROW_NUMBER() OVER ( ORDER BY [CPU_Time_Ms] DESC ) AS [row_num]
          , DatabaseName
          , [CPU_Time_Ms]
          , CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER ( ) * 100.0 AS DECIMAL(5 , 2)) AS [CPUPercent]
      FROM
            DB_CPU_Stats
      WHERE
            DatabaseID > 4 -- system databases
            AND DatabaseID <> 32767 -- ResourceDB
ORDER BY
            row_num
OPTION
            ( RECOMPILE );



/******************* #3 **********************/
-- Get CPU Utilization History for last 144 minutes (in one minute intervals)
-- This version works with SQL Server 2008 and SQL Server 2008 R2 only
DECLARE @ts_now BIGINT = (
                           SELECT
                              cpu_ticks / ( cpu_ticks / ms_ticks )
                           FROM
                              sys.dm_os_sys_info
                         ); 

SELECT TOP ( 144 )
      SQLProcessUtilization AS [SQL Server Process CPU Utilization]
    , SystemIdle AS [System Idle Process]
    , 100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization]
    , DATEADD(ms , -1 * ( @ts_now - [timestamp] ) , GETDATE()) AS [Event Time]
FROM
      (
        SELECT
            record.value('(./Record/@id)[1]' , 'int') AS record_id
          , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]' , 'int') AS [SystemIdle]
          , record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]' , 'int') AS [SQLProcessUtilization]
          , [timestamp]
        FROM
            (
              SELECT
                  [timestamp]
                , CONVERT(XML , record) AS [record]
              FROM
                  sys.dm_os_ring_buffers
              WHERE
                  ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
                  AND record LIKE N'%<SystemHealth>%'
            ) AS x
      ) AS y
ORDER BY
      record_id DESC
OPTION
      ( RECOMPILE );