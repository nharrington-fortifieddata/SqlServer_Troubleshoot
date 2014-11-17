/*
Referenced scripts that are required:
sp_whoisactive - If this stored procedure is not there, go to http://sqlblog.com/files/folders/beta/entry42453.aspx
triage_waits
Adapted from 'SQL Server First Responder Kit' by Brent Ozar
*/

Instance Name:
Triaged By:
Date and Time:

1) Can you connect?
	YES!
		RUN: SELECT name, user_access_desc, state_desc, log_reuse_wait_desc from sys.databases;
		TYPICAL OUTPUT: 
			name		user_access_desc	state_desc	log_reuse_wait_desc
			master		MULTI_USER			ONLINE		NOTHING
			tempdb		MULTI_USER			ONLINE		ACTIVE_TRANSACTION
			model		MULTI_USER			ONLINE		NOTHING
			msdb		MULTI_USER			ONLINE		NOTHING
			IvaluaCSCS	MULTI_USER			ONLINE		NOTHING
			
		What was your output? Anything stand out?
	No.
		Try connecting via DAC or Dedicated Admin Connection
			In Management Studio, prefix the instance name with "Admin:"
			Via command line and sqlcmd.exe interface. Use "-A" option.
	
2) Who is running stuff?
	RUN: EXEC dbo.sp_whoisactive
		(This should be in the master database. If this stored procedure is not there, go to http://sqlblog.com/files/folders/beta/entry42453.aspx)
	
	How many rows were returned?
	Was blocking present? Look at the blocking_session_id column.
	If so.
		a) Identify root cause of blocking.
			i) Copy the output from sp_whoisactive to excel to reference later.
			ii) Dig in further with the following perfmon counters:
				* SQL Server:General Statistics - Processes Blocked
				* SQL Server:Locks - Lock Wait Time (ms)
				* SQL Server:Locks - Number of Deadlocks/sec
				
3) What scheduled tasks are running?
	a) From SQL Server
		DO: In Management Studio, click on 'SQL Server Agent'. Right-click on jobs and select 'Job History'
	b) From the host
		DO: Connect to the server. Via Server Manager, click 'Task Scheduler' under 'Configuration'. Review the history under 'Task Scheduler Library'.
		
4) What does SQL Server's Error Log tell you?
	DO: In Management Studio, click on 'Management' and go to 'SQL Server Logs'
	    Via T-SQL, RUN: EXEC xp_readerrorlog @p1=0 @p2=1
				The extended stored procedure accepts at least 7 of the following parameters:

				Value of error log file you want to read: 0 = current, 1 = Archive #1, 2 = Archive #2, etc...
				Log file type: 1 or NULL = error log, 2 = SQL Agent log
				Search string 1: String one you want to search for
				Search string 2: String two you want to search for to further refine the results
				Search from start time  
				Search to end time
				Sort order for results: N'asc' = ascending, N'desc' = descending
				
	Are there recent errors/login failures?
	When was the last startup?
	Was the last restart planned?
	
5) What does the Windows Event Log say?
	Are there events in the windows logs at the same time or just before the problem periods? Be sure to look at everything not just errors.
	Check the following logs:
		a) System Log
		b) Application Log
		c) Security Log
		
6) Capture SQL Server Overall Waits
	RUN: script triage_waits
	Find the top three SQL Server waits from the result of the script.
	
7) Review Performance Counters
	DO: Use performance monitor and review the following counters:
		*Memory – Available MBytes
		*Paging File – % Usage
		*Physical Disk – Avg. Disk sec/Read
		*Physical Disk – Avg. Disk sec/Write
		*Physical Disk – Disk Reads/sec
		*Physical Disk – Disk Writes/sec
		*Processor – % Processor Time
		*SQLServer: Buffer Manager – Page life expectancy
		*SQLServer: General Statistics – User Connections
		*SQLServer: Memory Manager – Memory Grants Pending
		*SQLServer: SQL Statistics – Batch Requests/sec
		*SQLServer: SQL Statistics – Compilations/sec
		*SQLServer: SQL Statistics – Recompilations/sec
		*System – Processor Queue Length
	
8) Check current utilization of the following major areas. Can you identify a bottleneck specific to one of these?
	a) CPU
	b) Memory
	c) Network
	d) Disk
	
9) Identify recent changes:
	Have there been ANY changes in the following areas?
		a) App Tier
		b) Stored procedures
		c) Schema changes
		d) Index changes
		e) Major data changes
		f) Infrastructure changes
		g) Maintenance changes
		h) SQL config changes
		i) Windows config changes