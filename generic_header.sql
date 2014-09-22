SELECT 
	@@servername as ServerName, db_name() as DBName, c.session_id as SessionID, c.connect_time Connection_Time, getDate() as Execution_Time,
	c.net_transport, c.protocol_type, s.login_name, s.host_name, s.host_process_id, s.program_name
FROM sys.dm_exec_connections AS c
JOIN sys.dm_exec_sessions AS s
    ON c.session_id = s.session_id
WHERE c.session_id = @@SPID
go