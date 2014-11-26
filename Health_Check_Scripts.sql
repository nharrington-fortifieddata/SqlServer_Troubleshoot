--How to Perform a SQL Server Health Check
--Scripts to accompany session
--by Brad M McGehee, www.bradmcgehee.com

--Copyright 2012 Brad M. McGehee
--This work is licensed under the Creative Commons Attribution-NoDerivs 3.0 Unported License. To view a copy of 
--this license, visit http://creativecommons.org/licenses/by-nd/3.0/. 
--Work may be used for personal or commercial use, but work may not be republished or resold (in any form) without permission.
--Visit http://www.bradmcgehee.com/contact/ to contact copyright owner.


--SQL Server Instance Health Check Scripts


--Instance-Level Scripts
--The following script will list the name of the host machine and 
--SQL Server instance name (if not a named instance) where this script is being run.

SELECT  SERVERPROPERTY('ServerName') AS HostName ,
        SERVERPROPERTY('InstanceName') AS InstanceName;
GO


--Script lists an instance's Version, Edition, Service Pack Level, Build Number
SELECT @@VERSION AS 'SQL Server Version';
GO 


--Script lists an instance’s language and server level collation.
SELECT  @@LANGUAGE AS Server_Language
SELECT  SERVERPROPERTY('Collation') AS Collation;
GO 


--The following script will list any global trace flags that have been invoked.
DBCC TRACESTATUS(-1);
GO


--Script will tell you if an instance is clustered or not, and if so
--the failover cluster instance name.
SELECT  SERVERPROPERTY('IsClustered') AS IsInstanceClustered ,
        SERVERPROPERTY('MachineName') AS FailoverClusterName;
GO


--Script lists any startup stored procedures, and the related code, if any.
USE master
GO
SELECT  ROUTINE_NAME AS StartupSPName ,
        ROUTINE_DEFINITION AS SPCode
FROM    MASTER.INFORMATION_SCHEMA.ROUTINES
WHERE   OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME), 'ExecIsStartup') = 1;
GO


--Script lists any  instance-level DDL triggers on a SQL Server instance.
USE master
GO
SELECT  NAME AS TriggerName ,
        type_desc AS TypeofTrigger ,
        is_disabled AS Enabled
FROM    sys.server_triggers;
GO


--Script finds the path of SQL Server executables
USE master
GO
DECLARE @rc INT ,
    @dir NVARCHAR(4000)
EXEC @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\Setup', N'SQLPath', @dir OUTPUT,
    'no_output'
SELECT  @dir AS SQLExecutablesPath;
GO


--Script lists all of the system and user database files and their paths
USE master
GO
SELECT  [name] AS DatabaseName ,
        [physical_name] AS PhysicalFilePaths
FROM    sys.master_files;
GO


--Script finds the path where backups are stored by default
USE master
GO
DECLARE @rc INT ,
    @dir NVARCHAR(4000)
EXEC @rc = master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory',
    @dir OUTPUT, 'no_output'
SELECT  @dir AS DefaultBackupPath;
GO


--Script lists the last 10 backups files and their actual paths
USE msdb
GO	
SELECT TOP 10
        [physical_device_name] AS ActualBackupPath
FROM    [dbo].[backupmediafamily];
GO


--Script lists the number of MDF and LDF files that make up your tempdb,
--their location, and their current size.
SELECT  name AS TempdbFileNames ,
        physical_name AS PhysicalFilePaths ,
        STR(CONVERT(dec(15), size) * 8192 / 1048576, 10, 2) + N' MB' AS Size
FROM    sys.master_files
WHERE   name LIKE 'temp%';
GO


--Script lists any databases on an instance that have been encrypted using TDE
USE master
GO
SELECT  Name AS DatabaseName
FROM    sys.databases
WHERE   is_encrypted = 1 ;
GO


--Script lists any linked servers for an instance
SELECT  name AS ServerName ,
        is_linked AS LinkedServerName
FROM    sys.servers
WHERE   server_id > 0;
GO


--Script to tell you if the Full Text Service is turned on,
--but it does not tell you if it is actually being used,
--0 is off, 1 is on.
SELECT  SERVERPROPERTY('ServerName') AS HostName ,
        SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;
GO


--Script to tell you if a particular database plays any replication role.
--0 is off, 1 is on.
USE master
GO
SELECT  name AS 'Database Name' ,
        is_published AS 'Is Publisher' ,
        is_distributor AS 'Is Distributor' ,
        is_subscribed AS 'Is Subscriber'
FROM    sys.databases;
GO


--Script to tell you if Policy-Based Management in SQL Server 2008 and higher is enabled.
USE msdb
GO
SELECT  name AS PBM_Setting ,
        current_value AS Enabled
FROM    syspolicy_configuration
WHERE   name = 'ENABLED' ;
GO

--If the above script returns a “1” for enabled, then Policy-Based Management has been enabled.
--If you run the following script, and no rows are returned, the no policies have been created,
--otherwise each row returned will be a policy found on the instance.
USE msdb
GO
SELECT  name AS PolicyName ,
        description AS Policy_Description
FROM    syspolicy_policies
WHERE   is_enabled = 1 ;
GO


--Script to tell you if the Resource Governor is enabled.
--A 1 will be returned if it is.
USE master
GO
SELECT  is_enabled AS ResourceGovernorEnabled
FROM    sys.resource_governor_configuration;
GO


--If the Resource Governor is enabled, the following script will return resource pool settings
USE msdb
GO
SELECT  NAME AS ResourcePoolName ,
        min_cpu_percent AS MinimumCPUPercent ,
        max_cpu_percent AS MaxCPUPercent ,
        min_cpu_percent AS MinimumMemoryPercent ,
        max_memory_percent AS MaximumMemoryPercent
FROM    sys.resource_governor_resource_pools;
GO


--If the Resource Governor is enabled, the following script will return workload group properties
USE msdb
GO
SELECT  g.name AS GroupName ,
        g.importance AS Importance ,
        g.request_max_memory_grant_percent AS MaxMemoryGrantRequested ,
        g.request_max_cpu_time_sec AS MaxCPUTimeRequested ,
        g.request_memory_grant_timeout_sec AS MemoryGrantTimeOutSec ,
        g.max_dop AS MaxDop ,
        p.name AS PoolNameGroupBelongsTo
FROM    sys.resource_governor_resource_pools AS p
        INNER JOIN sys.resource_governor_workload_groups AS g ON p.pool_id = g.pool_id;
GO


--Script to tell you if the Data Collector is enabled
USE msdb
GO
SELECT  parameter_name AS MDWConfig ,
        parameter_value AS MDWValues
FROM    dbo.syscollector_config_store
WHERE   parameter_name LIKE 'mdw%'
        OR parameter_name = 'CollectorEnabled';
GO


--Script to tell you if SQL Server Audit has been turned on at either the
--server or database level
USE master
GO
SELECT  *
FROM    sys.server_audits;
GO
SELECT  *
FROM    sys.database_audit_specification_details;
GO


--Script to identify all of the instance-level settings in a SQL Server instance
USE master
GO
SELECT  name ,
        description ,
        value_in_use ,
        value ,
        minimum ,
        maximum
FROM    sys.configurations
ORDER BY name;
GO 


--Counts ad hoc queries that only have run 1 time
SELECT  SUM(CASE WHEN usecounts = 1 THEN 1
                 ELSE 0
            END) AS [Adhoc Plans Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype


--Measures the amount of memory (in MB) used for storing adhoc plans in the plan cache
SELECT  SUM(CAST(( CASE WHEN usecounts = 1 THEN size_in_bytes
                        ELSE 0
                   END ) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs Used by Adhoc Plans With Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype




--Database Level Options

--Script to return the state of all databases on an instance.
USE master
GO
SELECT  name AS 'Database_Name' ,
        state_desc AS 'State'
FROM    sys.databases;
GO


--Script to return recovery model of all databases on an instance.
USE master
GO
SELECT  name AS 'Database_Name' ,
        recovery_model_desc AS 'Recovery Model'
FROM    sys.databases;
GO


--Script to return the compatability level for all databases on an instance.
USE master
GO
SELECT  name AS 'Database_Name' ,
        compatibility_level AS 'Compatibility Level'
FROM    sys.databases;
GO


--Script to return the collation for all the databases on an instance.
USE master
GO
SELECT  name AS 'Database_Name' ,
        collation_name AS 'Database Collation'
FROM    sys.databases;
GO


--Determine database file (MDF and LDF) names, sizes, and properties
SELECT  name AS LogicalName ,
        database_id AS DatabaseID ,
        file_id AS FileID ,
        physical_name AS Path_Plus_FileName ,
        max_size AS Maximum_Size ,
        growth AS AutoGrowth_Amount ,
        is_percent_growth AS Fixed_or_Percent_Growth ,
        STR(CONVERT(dec(15), size) * 8192 / 1048576, 10, 2) + N' MB' AS Size
FROM    sys.master_files
ORDER BY name
GO


--Script to determine number of virtual logs in the transaction log.
--Each row represents one virtual log. Database name must be specified.
USE master
GO
DBCC LOGINFO (AdventureWorks);
GO


--Script to tell you if a particular database plays any replication role.
--0 is off, 1 is on.
USE master
GO
SELECT  name AS 'Database Name' ,
        is_published AS 'Is Publisher' ,
        is_distributor AS 'Is Distributor' ,
        is_subscribed AS 'Is Subscriber'
FROM    sys.databases;
GO


--Script to display any compressed objects, and their compression types.
USE master
GO
SELECT  OBJECT_NAME(object_id) AS 'ObjectName' ,
        data_compression_desc AS 'Compression Type' ,
        index_id AS 'Index ID'
FROM    sys.partitions
WHERE   data_compression <> 0
ORDER BY ObjectName;
GO


--Script to display any databases using FileStream.
USE master
GO
SELECT  name AS DatabaseName ,
        type_desc AS 'Filegroup Type' ,
        physical_name AS PhysicalFilePaths
FROM    sys.master_files
WHERE   type_desc = 'filestream';
GO


--Script to display any database that use TDE.
USE master
GO
SELECT  Name AS DatabaseName
FROM    sys.databases
WHERE   is_encrypted = 1;
GO


--Script to Identify Current Database Options for All Databases on an Instance
USE master
GO 
SELECT  name AS 'Database_Name' ,
        compatibility_level AS 'Compatability Level' ,
        recovery_model_desc AS 'Recovery Model' ,
        snapshot_isolation_state AS 'Allow Snapshot Isolation' ,
        is_ansi_null_default_on AS 'ANSI NULL Default' ,
        is_ansi_nulls_on AS 'ANSI NULLS Enabled' ,
        is_ansi_padding_on AS 'ANSI Paddings Enabled' ,
        is_ansi_warnings_on AS 'ANSI Warnings Enabled' ,
        is_arithabort_on AS 'Arithmetic Abort Enabled' ,
        is_auto_close_on AS 'Auto CLOSE' ,
        is_auto_create_stats_on AS 'Auto Create Statistics' ,
        is_auto_shrink_on AS 'Auto Shrink' ,
        is_auto_update_stats_async_on AS 'Auto Update Statistics Asynchronously' ,
        is_auto_update_stats_on AS 'Auto Update Statistics' ,
        is_cursor_close_on_commit_on AS 'Close Cursor on Commit Enabled' ,
        is_concat_null_yields_null_on AS 'Concatenate Null Yields Null' ,
        is_db_chaining_on AS 'Cross-Database Ownership Chaining Enabled' ,
        is_date_correlation_on AS 'Data Correlation Optimization Enabled' ,
        is_read_only AS 'Database Read-Only' ,
        is_local_cursor_default AS 'Default Cursor' ,
        is_encrypted AS 'Encryption Enabled' ,
        is_arithabort_on AS 'Numeric Round-Abort' ,
        page_verify_option_desc AS 'Page Verify' ,
        is_parameterization_forced AS 'Parameterization' ,
        is_quoted_identifier_on AS 'Quoted Identifiers Enabled' ,
        is_read_committed_snapshot_on AS 'Read Committed Snapshot' ,
        is_recursive_triggers_on AS 'Recursive Triggers Enabled' ,
        user_access_desc AS 'Restrict Access' ,
        is_broker_enabled AS 'Service Broker Enabled' ,
        is_trustworthy_on AS 'Trustworthy'
FROM    sys.databases;



--Security Health Check

--Script that tells you which authentication mode is being used by an instance.
USE master
GO
DECLARE @AuthenticationMode INT
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode',
    @AuthenticationMode OUTPUT
SELECT  CASE @AuthenticationMode
          WHEN 1 THEN 'Windows Authentication Mode Used'
          WHEN 2 THEN 'Windows and SQL Server Authentication Mode Used'
        END


--Script tells you what level of login auditing is being used by an instance.
USE master
GO
DECLARE @LoginAuditingMode INT
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel',
    @LoginAuditingMode OUTPUT
SELECT  CASE @LoginAuditingMode
          WHEN 0 THEN 'No Login Auditing Turned On'
          WHEN 1 THEN 'Successful Login Auditing Only'
          WHEN 2 THEN 'Failed Login Auditing Only--Default Setting'
          WHEN 3 THEN 'Both Failed and Successful Auditing Turned On'
        END


--Script to display current status of the 'server proxy account'.
USE master
GO
DECLARE @SysAdminOnly INT
SET @SysAdminOnly = ( SELECT    COUNT(*)
                      FROM      sys.credentials c
                      WHERE     c.name = N'##xp_cmdshell_proxy_account##'
                    )
			

DECLARE @account_name NVARCHAR(4000)
SET @account_name = ( SELECT TOP 1
                                credential_identity
                      FROM      sys.credentials c
                      WHERE     c.name = N'##xp_cmdshell_proxy_account##'
                    )
IF ( @account_name IS NULL ) 
    BEGIN
        SET @account_name = N''
    END
			
SELECT  CASE CAST(@SysAdminOnly AS BIT)
          WHEN 0 THEN 'Proxy Account is Turned Off'
          WHEN 1 THEN 'Proxy Account is Turned On'
        END AS [Proxy Account Status];


--Script that tells you the status of the 'Common Criteria Compliance' setting.        
USE master
GO        
SELECT  CASE value_in_use
          WHEN 0 THEN 'Common Criteria Compliance is Turned Off'
          WHEN 1 THEN 'Common Criteria Compliance is Turned On'
        END AS [Common Criteria Compliance Status]
FROM    sys.configurations
WHERE   name = 'common criteria compliance enabled';
GO


--Script that tells you the status of the 'C2 Audit Mode' setting.
USE master
GO 
SELECT  CASE value_in_use
          WHEN 0 THEN 'C2 Audit Mode is Turned Off'
          WHEN 1 THEN 'C2 Audit Mode is Turned On'
        END AS [C2 Audit Mode Status]
FROM    sys.configurations
WHERE   name = 'c2 audit mode';
GO


--Performance Health Check

--Identifies the top 10 most expensive queries in the existing plan cache, which may
--or may not be truly representative of the expensive queries for this instance.
USE master
GO
SELECT TOP 10
        SUBSTRING(eqt.TEXT, ( eqs.statement_start_offset / 2 ) + 1,
                  ( ( CASE eqs.statement_end_offset
                        WHEN -1 THEN DATALENGTH(eqt.TEXT)
                        ELSE eqs.statement_end_offset
                      END - eqs.statement_start_offset ) / 2 ) + 1) ,
        eqs.execution_count AS 'Number of Executions',
        eqs.total_logical_reads AS 'Total Logical Reads',
        eqs.total_logical_writes AS 'Total Logical Writes',
        eqs.last_logical_writes ,
        eqs.total_worker_time ,
        eqs.last_execution_time ,
        eqp.query_plan
FROM    sys.dm_exec_query_stats eqs
        CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) eqt
        CROSS APPLY sys.dm_exec_query_plan(eqs.plan_handle) eqp
ORDER BY eqs.total_worker_time DESC -- CPU time     
--ORDER BY eqs.total_logical_reads DESC -- logical reads
--ORDER BY eqs.total_logical_writes DESC -- logical writes ;

 
--Script from Paul Randal, based on a script from Glenn Berry
--Helps to identify problematic wait states
--http://www.sqlskills.com/BLOGS/PAUL/post/Wait-statistics-or-please-tell-me-where-it-hurts.aspx  
 WITH   Waits
          AS ( SELECT   wait_type ,
                        wait_time_ms / 1000.0 AS WaitS ,
                        ( wait_time_ms - signal_wait_time_ms ) / 1000.0 AS ResourceS ,
                        signal_wait_time_ms / 1000.0 AS SignalS ,
                        waiting_tasks_count AS WaitCount ,
                        100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( ) AS Percentage ,
                                                              ROW_NUMBER() OVER ( ORDER BY wait_time_ms DESC ) AS RowNum
               FROM                                           sys.dm_os_wait_stats
               WHERE                                          wait_type NOT IN (
                                                              'CLR_SEMAPHORE',
                                                              'LAZYWRITER_SLEEP',
                                                              'RESOURCE_QUEUE',
                                                              'SLEEP_TASK',
                                                              'SLEEP_SYSTEMTASK',
                                                              'SQLTRACE_BUFFER_FLUSH',
                                                              'WAITFOR',
                                                              'LOGMGR_QUEUE',
                                                              'CHECKPOINT_QUEUE',
                                                              'REQUEST_FOR_DEADLOCK_SEARCH',
                                                              'XE_TIMER_EVENT',
                                                              'BROKER_TO_FLUSH',
                                                              'BROKER_TASK_STOP',
                                                              'CLR_MANUAL_EVENT',
                                                              'CLR_AUTO_EVENT',
                                                              'DISPATCHER_QUEUE_SEMAPHORE',
                                                              'FT_IFTS_SCHEDULER_IDLE_WAIT',
                                                              'XE_DISPATCHER_WAIT',
                                                              'XE_DISPATCHER_JOIN',
                                                              'BROKER_EVENTHANDLER',
                                                              'TRACEWRITE',
                                                              'FT_IFTSHC_MUTEX',
                                                              'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
                                                              'BROKER_RECEIVE_WAITFOR',
                                                              'ONDEMAND_TASK_QUEUE',
                                                              'DBMIRROR_EVENTS_QUEUE',
                                                              'DBMIRRORING_CMD',
                                                              'BROKER_TRANSMITTER',
                                                              'SQLTRACE_WAIT_ENTRIES',
                                                              'SLEEP_BPOOL_FLUSH',
                                                              'SQLTRACE_LOCK' )
             )
    SELECT  W1.wait_type AS WaitType ,
            CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S ,
            CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Resource_S ,
            CAST (W1.SignalS AS DECIMAL(14, 2)) AS Signal_S ,
            W1.WaitCount AS WaitCount ,
            CAST (W1.Percentage AS DECIMAL(4, 2)) AS Percentage ,
            CAST (( W1.WaitS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgWait_S ,
            CAST (( W1.ResourceS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgRes_S ,
            CAST (( W1.SignalS / W1.WaitCount ) AS DECIMAL(14, 4)) AS AvgSig_S
    FROM    Waits AS W1
            INNER JOIN Waits AS W2 ON W2.RowNum <= W1.RowNum
    GROUP BY W1.RowNum ,
            W1.wait_type ,
            W1.WaitS ,
            W1.ResourceS ,
            W1.SignalS ,
            W1.WaitCount ,
            W1.Percentage
    HAVING  SUM(W2.Percentage) - W1.Percentage < 95; -- percentage threshold ;
 GO 
 
 
 --Counts ad hoc queries that only have run 1 time
SELECT  SUM(CASE WHEN usecounts = 1 THEN 1
                 ELSE 0
            END) AS [Adhoc Plans Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype


--Measures the amount of memory (in MB) used for storing adhoc plans in the plan cache
SELECT  SUM(CAST(( CASE WHEN usecounts = 1 THEN size_in_bytes
                        ELSE 0
                   END ) AS DECIMAL(18, 2))) / 1024 / 1024 AS [Total MBs Used by Adhoc Plans With Use Count of 1]
FROM    sys.dm_exec_cached_plans
WHERE   objtype = 'Adhoc'
GROUP BY objtype
 
 
 
--High Availability Health Check Scripts

--Script to display log-shipping properties for each database involved in log shipping.
USE msdb
GO
SELECT  *
FROM    log_shipping_monitor_primary
SELECT  *
FROM    log_shipping_monitor_secondary ;
GO


--Script to display mirroring-related database properties.
USE master
GO
SELECT  d.name AS 'Database Name' ,
        m.mirroring_role_desc AS 'Mirroring Role' ,
        m.mirroring_safety_level AS 'Mirroring Safety Level' ,
        m.mirroring_state_desc AS 'Mirroring State' ,
        m.mirroring_partner_name AS 'Instance Mirroring Partner' ,
        m.mirroring_witness_name AS 'Witness Instance Name' ,
        m.mirroring_witness_state_desc AS 'Witness Mirroring State'
FROM    sys.database_mirroring m
        JOIN sys.databases d ON m.database_id = d.database_id
WHERE   m.mirroring_role_desc IS NOT NULL;
GO


--Script to display change tracking properties per database.
USE master
GO
SELECT  d.name AS 'Database Name' ,
        m.is_auto_cleanup_on AS 'Auto CleanUp On' ,
        m.retention_period AS 'Retention Period' ,
        m.retention_period_units_desc AS 'Retention Period Units'
FROM    sys.change_tracking_databases m
        JOIN sys.databases d ON m.database_id = d.database_id;
GO

