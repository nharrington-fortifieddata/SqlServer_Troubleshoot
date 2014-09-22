SELECT SP1.[name] AS 'Login', SP2.[name] AS 'ServerRole' 
FROM sys.server_principals SP1 
  JOIN sys.server_role_members SRM 
    ON SP1.principal_id = SRM.member_principal_id 
  JOIN sys.server_principals SP2 
    ON SRM.role_principal_id = SP2.principal_id 
ORDER BY SP1.[name], SP2.[name];