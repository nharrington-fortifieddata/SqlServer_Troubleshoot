SELECT SUM(size)*1.0/128 AS [size in MB]
FROM tempdb.sys.database_files

