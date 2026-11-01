# STPKS_STDCIFD_MAIN — training implementation

This package is an executable PL/SQL implementation based on the **educational training schema** uploaded in this conversation. The schema itself explicitly states that it is a reconstruction, not Oracle's complete/licensed FLEXCUBE 14.1 production DDL.

It is **not** Oracle's proprietary RAD-generated `STPKS_STDCIFD_MAIN` package and must not be deployed into a production FLEXCUBE schema or treated as a drop-in replacement for the native MAIN package.

## Included functionality

- `VALIDATE_CUSTOMER`: mandatory-field, type, status, group and duplicate-identity checks.
- `CREATE_CUSTOMER`: inserts the CIF master plus the matching personal or corporate detail row in pending status.
- `AMEND_PENDING_CUSTOMER`: updates an unauthorized, never-authorized record and its personal/corporate detail row.
- `AUTHORIZE_CUSTOMER`: maker/checker separation and authorization of the master plus customer-keyed child/KYC records defined in the uploaded schema.
- `QUERY_CUSTOMER`: returns three ref cursors for the customer master, personal details and corporate details.
- Savepoints and rollback-on-error protect each DML procedure; the package does not commit.

## Important lifecycle limitation

The uploaded training schema stores one row per CIF and does not provide a separate authorized snapshot and pending amendment version. For that reason, `AMEND_PENDING_CUSTOMER` intentionally refuses to amend a previously authorized customer (`ONCE_AUTH = 'Y'`). This prevents silently overwriting the last authorized record. A production-grade maker/checker amendment model needs a proper pending/authorization copy architecture.

## Prerequisites

1. Create a dedicated Oracle training schema.
2. Run the uploaded customer training DDL successfully in that schema.
3. Ensure `STTM_CUST_GROUP` contains authorized `RETAIL` and `SME` rows (the uploaded seed script creates these).
4. Run `STPKS_STDCIFD_MAIN.sql` with SQL Developer **F5 / Run Script** or SQL*Plus.

## Verify compilation

```sql
SELECT line, position, text
FROM user_errors
WHERE name = 'STPKS_STDCIFD_MAIN'
ORDER BY sequence;

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name = 'STPKS_STDCIFD_MAIN'
ORDER BY object_type;
```

Both PACKAGE and PACKAGE BODY should be `VALID`; `USER_ERRORS` should return no rows.

## Smoke test

Run `02_smoke_test_individual.sql` after successful compilation. It inserts a synthetic individual CIF, authorizes it using a different checker ID, reads it back, and commits the test data. It uses `example.test` email addresses and synthetic identity values only.

## Transaction and security notes

- The package does not issue `COMMIT`; the calling application controls the transaction.
- `p_maker_id` and `p_checker_id` are caller-supplied identifiers in this training implementation. They are **not authentication**. A deployed application must derive these IDs from a trusted, authenticated FLEXCUBE session and enforce role/branch/authorization controls server-side.
- The package assumes the table names and columns from the supplied training DDL. Reconcile them against `ALL_TAB_COLUMNS` before adapting it to any other schema.
- This implementation focuses on customer master plus individual/corporate detail maintenance. Other KYC and relationship tables are included in authorization propagation, but dedicated capture/update APIs for every KYC sub-block are outside this MAIN package starter.
