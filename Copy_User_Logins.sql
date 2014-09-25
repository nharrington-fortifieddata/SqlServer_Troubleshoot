SET NOCOUNT ON
DECLARE
@errStatement [varchar](8000),
@msgStatement [varchar](8000),
@DatabaseUserName [sysname],
@ServerUserName [sysname],
@DefaultSchema [varchar] (256),
@RoleName [varchar](256),
@MemberName [varchar](256),
@PrivState [varchar] (256),
@PrivGrantee [varchar] (256),
@PrivType [varchar] (256),
@PrivWG [varchar] (256),
@SchState [varchar] (256),
@SchType [varchar] (256),
@SchName [varchar] (256),
@SchWG [varchar] (256),
@SchGrantee [varchar] (256),
@ObjState [varchar] (256),
@ObjType [varchar] (256),
@ObjSchema [varchar] (256),
@ObjName [varchar] (256),
@ObjGrantee [varchar] (256),
@ObjWG [varchar] (256),
@binpwd varbinary (256),
@SID_varbinary varbinary(85),
@SID_string varchar(256),
@login_expired varchar(256),
@login_policy varchar(256),
@login_name varchar (256),
@user_name varchar (256),
@schema_name varchar (256),
@txtpwd sysname,
@default_database varchar (256),
@default_lang varchar (256),
@login_type varchar (256)

SET @msgStatement = '/* copy_user_login script written by Nicole Harrington 7/31/2014'
PRINT @msgStatement
SET @msgStatement = 'You will need stored procedure dbo.sp_hexadecimal to run this.'
PRINT @msgStatement
SET @msgStatement = '  '
PRINT @msgStatement
SET @msgStatement = '1. Run this script against the database that you want to copy logins and users from'
PRINT @msgStatement
SET @msgStatement = '2. Remove all users in the refreshed copy besides dbo, guest, INFORMATION_SCHEMA and sys'
PRINT @msgStatement
SET @msgStatement = '3. Copy the output to a new query window and run section by section (eg. -- CREATE USERS) against the refreshed database after all (excluding dbo, guest, INFORMATION_SCHEMA and sys) have been removed.'
PRINT @msgStatement
SET @msgStatement = '  '
PRINT @msgStatement
SET @msgStatement = '** Generated '
+ CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @msgStatement
PRINT ''
PRINT ''
--
-- Script to CREATE LOGINS for instance
PRINT '-- CREATE LOGINS'
DECLARE @dbname as sysname
DECLARE @query as varchar(2000)
SET @dbname = (select db_name() as dbname)

SET @query =N'select [master].[sys].[server_principals].[name] COLLATE LATIN1_General_CI_AI  as login_name,
         [' + @dbname + '].[sys].[database_principals].[name] as user_name, ISNULL (['+ @dbname +'].[sys].[database_principals].[default_schema_name],'''') as schema_name,
         [master].[sys].[server_principals].[default_database_name] as default_database,
         [master].[sys].[server_principals].[default_language_name] as default_lang,
         [master].[sys].[server_principals].[type] as login_type,
         [master].[sys].[sql_logins].[password_hash] as binpwd,
         [master].[sys].[sql_logins].[sid] as login_sid,
         [master].[sys].[sql_logins].[is_disabled] as login_expired,
         [master].[sys].[sql_logins].[is_policy_checked] as login_policy
         into ##users
from ['+ @dbname + '].[sys].[database_principals] RIGHT OUTER JOIN [master].[sys].[server_principals] 
on ['+ @dbname + '].[sys].[database_principals].[name]=[master].[sys].[server_principals].[name] COLLATE LATIN1_General_CI_AI
LEFT OUTER JOIN [master].[sys].[sql_logins] 
on [master].[sys].[server_principals].[name] = [master].[sys].[sql_logins].[name] COLLATE LATIN1_General_CI_AI
where [master].[sys].[server_principals].[type] in (''U'', ''G'', ''S'')
AND [master].[sys].[server_principals].name NOT LIKE ''##%''
AND [master].[sys].[server_principals].name NOT LIKE ''NT%''
AND [master].[sys].[server_principals].name <> ''sa''
AND [' + @dbname +'].[sys].[database_principals].[name] IS NOT NULL'
exec (@query)
DECLARE _logins
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR 
select * from ##users
 
OPEN _logins FETCH NEXT FROM _logins INTO @login_name, @user_name, @schema_name, @default_database, @default_lang, @login_type, @binpwd, @SID_varbinary, @login_expired, @login_policy
WHILE @@FETCH_STATUS = 0
	BEGIN	
		EXEC sp_hexadecimal @SID_varbinary, @SID_string OUT
		SET @SID_string = ', SID=' + @SID_string
					
		IF (@binpwd IS NOT NULL)
			-- Non-null password
			EXEC master.dbo.sp_hexadecimal @binpwd, @txtpwd OUT
		ELSE
			-- Null password
			SET @txtpwd = ''	
			
		
		IF (@login_expired IS NOT NULL)
			IF (@login_expired = 0)
				SET @login_expired = ', CHECK_EXPIRATION=OFF'	
			ELSE
				SET @login_expired = ', CHECK_EXPIRATION=ON'
		ELSE
			SET @login_expired = ''

		IF (@login_policy IS NOT NULL)			
			IF (@login_policy = 0)
				SET @login_policy = ', CHECK_POLICY=OFF'
			ELSE
				SET @login_policy = ', CHECK_POLICY=ON'
		ELSE
			SET @login_policy = ''
						
		SET @msgStatement =
		(CASE 
			WHEN @login_type = 'U' OR @login_type = 'G'
				THEN 'CREATE LOGIN ' + @login_name + ' FROM WINDOWS WITH DEFAULT_DATABASE=' + @default_database + ', DEFAULT_LANGUAGE=' + @default_lang + @login_expired + @login_policy
			WHEN @login_type = 'S'
				THEN 'CREATE LOGIN ' + @login_name + ' WITH PASSWORD=' + @txtpwd + ' HASHED, DEFAULT_LANGUAGE=' + @default_lang + @login_expired + @login_policy + @SID_string
			ELSE
			'None available'
		END)

PRINT @msgStatement
FETCH NEXT FROM _logins INTO @login_name, @user_name, @schema_name, @default_database, @default_lang, @login_type, @binpwd, @SID_varbinary, @login_expired, @login_policy
END

CLOSE _logins 
DEALLOCATE _logins --cleanup cursor
DROP TABLE ##users

--Script CREATE USERS for current database
PRINT ' '
PRINT '-- CREATE USERS'
DECLARE _users
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR 
select [master].[sys].[server_principals].[name] COLLATE LATIN1_General_CI_AI ,
         [sys].[database_principals].[name], ISNULL ([sys].[database_principals].[default_schema_name],'')
from [sys].[database_principals] INNER JOIN [master].[sys].[server_principals] 
on [sys].[database_principals].[name]=[master].[sys].[server_principals].[name] COLLATE LATIN1_General_CI_AI
where [master].[sys].[server_principals].[type] in ('U', 'G', 'S')

OPEN _users FETCH NEXT FROM _users INTO @ServerUserName, @DatabaseUserName, @DefaultSchema
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN
	If (@DefaultSchema = '')
		BEGIN
			SET @DefaultSchema = ''
		END
	ELSE
		BEGIN
			SET @DefaultSchema = ' WITH DEFAULT_SCHEMA=[' + @DefaultSchema + ']'
		END
	END
SET @msgStatement = 'CREATE USER ['        ---example: CREATE USER [mlapenna] FOR LOGIN [mlapenna]
 + @DatabaseUserName + ']' + ' FOR LOGIN [' + @ServerUserName + ']' + @DefaultSchema
PRINT @msgStatement
FETCH NEXT FROM _users INTO @ServerUserName, @DatabaseUserName, @DefaultSchema
END

CLOSE _users 
DEALLOCATE _users --cleanup cursor

--Script CREATE Database Roles for current database
PRINT ' '
PRINT '-- CREATE DB ROLES'
DECLARE _roles
CURSOR LOCAL FORWARD_ONLY READ_ONLY 
FOR
select [NAME] from [sys].[database_principals] where type='R' and is_fixed_role != 1 and name not like 'public'
OPEN _roles FETCH NEXT FROM _roles INTO @RoleName
WHILE @@FETCH_STATUS=0
BEGIN
SET @msgStatement ='if not exists(SELECT 1 from sys.database_principals where type=''R'' and name ='''
+@RoleName+''' ) '+ CHAR(13) +
'BEGIN '+ CHAR(13) +
'CREATE ROLE  ['+ @RoleName + ']'+CHAR(13) +
'END'
PRINT @msgStatement
FETCH NEXT FROM _roles INTO @RoleName
END

CLOSE _roles
DEALLOCATE _roles --cleanup cursor

-- Script to Add Role Members to Users for current database
PRINT ' '
PRINT '-- ADD ROLE MEMBERS'
DECLARE _role_members
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR 
SELECT a.name , b.name 
from sys.database_role_members d INNER JOIN sys.database_principals  a
                                on  d.role_principal_id=a.principal_id 
                                 INNER JOIN sys.database_principals  b
                                on d.member_principal_id=b.principal_id
                                where    b.name <> 'dbo'
                                order by 1,2
 
OPEN _role_members FETCH NEXT FROM _role_members INTO @RoleName, @MemberName
WHILE @@FETCH_STATUS = 0
BEGIN
SET @msgStatement = 'EXEC [sp_addrolemember] ' + '@rolename = [' + @RoleName + '], ' + '@membername = [' + @MemberName + ']'
PRINT @msgStatement
FETCH NEXT FROM _role_members INTO @RoleName, @MemberName
END

CLOSE _role_members 
DEALLOCATE _role_members --cleanup cursor

-- Script GRANTS for Database Privileges on current database
PRINT ' '
PRINT '-- GRANTS for Database Privileges'
DECLARE _grant_privs
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR 
SELECT a.state_desc,a.permission_name, b.name, a.state COLLATE LATIN1_General_CI_AI
FROM sys.database_permissions a inner join sys.database_principals b
ON a.grantee_principal_id = b.principal_id 
WHERE b.principal_id not in (0,1,2) and a.type not in ('CO') and a.class = 0
                                
OPEN _grant_privs FETCH NEXT FROM _grant_privs INTO @PrivState,@PrivType,@PrivGrantee,@PrivWG
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN
	If (@PrivWG = 'W')
		BEGIN
			SET @PrivWG = 'WITH GRANT OPTION'
			SET @PrivState = 'GRANT'
		END
	ELSE
		BEGIN
			SET @PrivWG = ''
		END
	END
SET @msgStatement = @PrivState +' ' + @PrivType + ' to "' + @PrivGrantee +'" '+@PrivWG
PRINT @msgStatement
FETCH NEXT FROM _grant_privs INTO @PrivState,@PrivType,@PrivGrantee,@PrivWG
END

CLOSE _grant_privs 
DEALLOCATE _grant_privs --cleanup cursor
                              
-- Script GRANTS for Schema Privileges on current database
PRINT ' '
PRINT '-- GRANTS for Schema Privileges'
DECLARE _grant_schprivs
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR 
SELECT a.state_desc, permission_name, b.name, a.state, c.name COLLATE LATIN1_General_CI_AI
FROM sys.database_permissions  a INNER JOIN sys.schemas b
ON  a.major_id = b.schema_id INNER JOIN sys.database_principals c ON a.grantee_principal_id = c.principal_id

OPEN _grant_schprivs FETCH NEXT FROM _grant_schprivs INTO @SchState,@SchType,@SchName,@SchWG, @SchGrantee
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN
	If (@SchWG = 'W')
		BEGIN
			SET @SchWG = 'WITH GRANT OPTION'
			SET @SchState = 'GRANT'
		END
	ELSE
		BEGIN
			SET @SchWG = ''
		END
	END
SET @msgStatement = @SchState +' ' + @SchType +' ON SCHEMA::[' + @SchName+ '] TO ' + @SchGrantee + ' ' + @SchWG
PRINT @msgStatement
FETCH NEXT FROM _grant_schprivs INTO @SchState,@SchType,@SchName,@SchWG,@SchGrantee
END

CLOSE _grant_schprivs
DEALLOCATE _grant_schprivs --cleanup cursor

--Script GRANTS for Objects Level Privilegs
PRINT ' '
PRINT '-- GRANTS for Object Privileges'
DECLARE _grant_objprivs
CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
SELECT a.state_desc, a.permission_name, c.name, b.name,e.name, a.state COLLATE LATIN1_General_CI_AI
from sys.database_permissions a
join sys.objects b on a.major_id = b.object_id
join sys.schemas c on b.schema_id = c.schema_id
join sys.database_principals e on a.grantee_principal_id = e.principal_id
where e.name not in ( 'public', 'guest')

OPEN _grant_objprivs FETCH NEXT FROM _grant_objprivs INTO @ObjState,@ObjType,@ObjSchema,@ObjName, @ObjGrantee,@ObjWG
WHILE @@FETCH_STATUS = 0
BEGIN
	BEGIN
	If (@ObjWG = 'W')
		BEGIN
			SET @ObjWG = 'WITH GRANT OPTION'
			SET @ObjState = 'GRANT'
		END
	ELSE
		BEGIN
			SET @ObjWG = ''
		END
	END
SET @msgStatement = @ObjState +' ' + @ObjType +' ON ' + @ObjSchema + '.'+ @ObjName + ' TO ' + @ObjGrantee + ' ' + @ObjWG
PRINT @msgStatement
FETCH NEXT FROM _grant_objprivs INTO @ObjState,@ObjType,@ObjSchema,@ObjName, @ObjGrantee,@ObjWG
END

CLOSE _grant_objprivs
DEALLOCATE _grant_objprivs --cleanup cursor
