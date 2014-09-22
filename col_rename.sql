USE <database>;
GO
EXEC sp_rename '<old_name>', '<new_name>', 'COLUMN';
GO
