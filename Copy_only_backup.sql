BACKUP DATABASE [database] TO 
 DISK = N'<location>.bak'
  WITH COPY_ONLY, NOFORMAT, NOINIT,  NAME = N'<name of backup>', SKIP, REWIND, NOUNLOAD,  STATS = 10
GO