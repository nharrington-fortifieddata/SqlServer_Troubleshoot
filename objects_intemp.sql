select
OBJECT_NAME(object_id) [Object Name],
SUM (reserved_page_count) * 8192/ 1024 [Reserved_KB],
SUM(used_page_count) * 8192 / 1024 [Used_KB]

from sys.dm_db_partition_stats
group by OBJECT_NAME(object_id)
order by reserved_kb desc;

