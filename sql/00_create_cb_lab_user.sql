-- Run this script as an administrator (SYSDBA or another authorized admin)
-- while connected to the FREEPDB1 service, not the FREE container database.
-- Change the password before use. This is a local training schema only.

CREATE USER CB_LAB IDENTIFIED BY "ReplaceWithYourOwnStrongPassword2026";

GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE TYPE,
      CREATE SYNONYM
TO CB_LAB;

ALTER USER CB_LAB QUOTA UNLIMITED ON USERS;

-- Verify that the user was created and has the expected status.
SELECT username, account_status, default_tablespace
FROM dba_users
WHERE username = 'CB_LAB';
