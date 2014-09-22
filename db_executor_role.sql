/* Create a new role for executing stored
   procedures */
CREATE ROLE db_executor
 
/* Grant stored procedure execute rights
   to the role */
GRANT EXECUTE TO db_executor