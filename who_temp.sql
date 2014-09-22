SELECT top 5 * 
FROM sys.dm_db_session_space_usage  
ORDER BY (user_objects_alloc_page_count +
 internal_objects_alloc_page_count) DESC