SELECT top 1000 s.host_name, su.[session_id], d.name [DBName], su.[database_id],
 su.[user_objects_alloc_page_count] [Usr_Pg_Alloc], su.[user_objects_dealloc_page_count] [Usr_Pg_DeAlloc],
 su.[internal_objects_alloc_page_count] [Int_Pg_Alloc], su.[internal_objects_dealloc_page_count] [Int_Pg_DeAlloc],
 (su.[user_objects_alloc_page_count]*1.0/128) [Usr_Alloc_MB], (su.[user_objects_dealloc_page_count]*1.0/128)
 [Usr_DeAlloc_MB],
 (su.[internal_objects_alloc_page_count]*1.0/128) [Int_Alloc_MB], (su.[internal_objects_dealloc_page_count]*1.0/128)
 [Int_DeAlloc_MB]
 FROM [sys].[dm_db_session_space_usage] su
 inner join sys.databases d on su.database_id = d.database_id
 inner join sys.dm_exec_sessions s on su.session_id = s.session_id
 where (su.user_objects_dealloc_page_count > 0 or
 su.internal_objects_dealloc_page_count > 0)
 order by case when su.user_objects_dealloc_page_count > su.internal_objects_dealloc_page_count then
 su.user_objects_dealloc_page_count else su.internal_objects_dealloc_page_count end desc