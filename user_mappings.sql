CREATE TABLE #tempww (
    LoginName nvarchar(max),
    DBname nvarchar(max),
    Username nvarchar(max), 
    AliasName nvarchar(max)
)

INSERT INTO #tempww 
EXEC master..sp_msloginmappings 

-- display results
SELECT * 
FROM   #tempww 
ORDER BY dbname, username

-- cleanup
DROP TABLE #tempww