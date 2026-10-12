-- Connect to service TRENDYDB as TRENDY.
SELECT SYS_CONTEXT('USERENV', 'DB_NAME') AS cdb_name,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS pdb_name
FROM dual;

SELECT USER FROM dual;
