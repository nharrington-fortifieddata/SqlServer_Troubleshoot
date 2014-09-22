USE [tempdb]
go
/*	Last xx minutes of CPU usage from System Health trace	*/
DECLARE @ts_now BIGINT = ( SELECT   cpu_ticks / ( cpu_ticks / ms_ticks )
                           FROM     [sys].[dm_os_sys_info]
                         );

SELECT TOP ( 240 ) /* Set the number of minutes history that you want here	*/
        @@servername AS [Servername] ,
        DATEADD(ms, -1 * ( @ts_now - [timestamp] ), GETDATE()) AS [Sample Time] ,
        SQLProcessUtilisation
INTO    #Data
FROM    ( SELECT    [R].[sample].[value]('(./Record/@id)[1]', 'int') AS [record_id] ,
                    [R].[sample].[value]('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',
                                 'int') AS [SystemIdle] ,
                    [R].[sample].[value]('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                                 'int') AS [SQLProcessUtilisation] ,
                    [timestamp]
          FROM      ( SELECT    [timestamp] ,
                                CONVERT(XML, record) AS [sample]
                      FROM      [sys].[dm_os_ring_buffers] AS DORB
                      WHERE     [ring_buffer_type] = N'RING_BUFFER_SCHEDULER_MONITOR'
                                AND [record] LIKE N'%<SystemHealth>%'
                    ) AS [R]
        ) AS y
ORDER BY [record_id] DESC;

WITH    datas
          AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY [Sample Time] ) AS r_n ,
                        [SQLProcessUtilisation]
               FROM     [#Data] AS D
             )
    SELECT  10 AS [Last n minutes range] ,
            AVG([SQLProcessUtilisation]) AS [Avg SQL CPU] ,
            MIN([SQLProcessUtilisation]) AS [Min SQL CPU] ,
            MAX([SQLProcessUtilisation]) AS [Max SQL CPU]
    FROM    [datas]
    WHERE   [r_n] < 11
    UNION
    SELECT  30 ,
            AVG([SQLProcessUtilisation]) ,
            MIN([SQLProcessUtilisation]) ,
            MAX([SQLProcessUtilisation])
    FROM    [datas]
    WHERE   [r_n] < 31
    UNION
    SELECT  60 ,
            AVG([SQLProcessUtilisation]) ,
            MIN([SQLProcessUtilisation]) ,
            MAX([SQLProcessUtilisation])
    FROM    [datas]
    WHERE   [r_n] < 61
    UNION
    SELECT  120 ,
            AVG([SQLProcessUtilisation]) ,
            MIN([SQLProcessUtilisation]) ,
            MAX([SQLProcessUtilisation])
    FROM    [datas]
    WHERE   [r_n] < 121
    UNION
    SELECT  240 ,
            AVG([SQLProcessUtilisation]) ,
            MIN([SQLProcessUtilisation]) ,
            MAX([SQLProcessUtilisation])
    FROM    [datas];

DROP TABLE [#Data];
