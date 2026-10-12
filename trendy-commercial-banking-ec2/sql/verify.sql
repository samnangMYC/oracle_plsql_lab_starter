-- Connect to service FREEPDB1 as TRENDY or an administrator.
SELECT SYS_CONTEXT('USERENV', 'DB_NAME') AS database_name,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name
FROM dual;

SELECT USER FROM dual;
