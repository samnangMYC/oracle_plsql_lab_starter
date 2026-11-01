# Database install order

Run only in a dedicated empty training/clone schema. The first script creates the supplied educational tables and synthetic sample data.

1. Compile `00_training_customer_schema.sql` (the user's uploaded educational training schema and synthetic test data).
2. Compile `STPKS_STDCIFD_MAIN-training.sql` (the clone-owned training MAIN package included here for reference/re-installation).
3. Compile `STPKS_STDCIFD_WS.sql` (WebLogic XML/JDBC adapter).
4. Run the `USER_OBJECTS` and `USER_ERRORS` checks from the project README.
5. Do not run these scripts in the Oracle-delivered FLEXCUBE application owner or production environment.

The training MAIN source is an educational package, not Oracle's RAD-generated STDCIF MAIN package. If your existing training schema already has a valid `STPKS_STDCIFD_MAIN`, compare before running the included copy so you do not overwrite local work.
