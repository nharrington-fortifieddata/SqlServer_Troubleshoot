-- The following code moves transaction log from D drive to L drive
-- Related Microsoft document is here:		http://technet.microsoft.com/en-us/library/ms345483(v=sql.105).aspx


USE master;
GO
-- Return the logical file name.
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'<database name>')
    AND type_desc = N'LOG';
GO

ALTER DATABASE <database name> SET OFFLINE;
GO


-- Physically move the file to a new location.
-- In the following statement, modify the path specified in FILENAME to
-- the new location of the file on your server.

-- original location:	D:\MSSQL\DATA\xxx_log.ldf
-- new location:	L:\MSSQL\LOGS\xxx_log.ldf

ALTER DATABASE <database name> 
    MODIFY FILE ( NAME = <database name>_log, 
                  FILENAME = '<new log file location>');
GO

ALTER DATABASE <database name> SET ONLINE;
GO

--Verify the new location.
SELECT name, physical_name AS CurrentLocation, state_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'<database name>')
    AND type_desc = N'LOG';