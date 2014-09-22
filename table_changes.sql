select	name,create_date,modify_date from sys.tables
WHERE	create_date <> modify_date
ORDER BY modify_Date