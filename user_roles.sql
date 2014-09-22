SELECT
    USER_NAME(memberuid), USER_NAME(groupuid)
FROM
    sys.sysmembers
WHERE
    USER_NAME(groupuid) IN ('db_datawriter')