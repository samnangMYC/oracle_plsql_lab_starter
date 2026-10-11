SET SERVEROUTPUT ON;

PROMPT === Connection verification ===
SELECT USER AS connected_user,
       SYS_CONTEXT('USERENV', 'CON_NAME') AS container_name,
       SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS service_name
FROM dual;

PROMPT === PL/SQL test ===
DECLARE
    v_amount NUMBER(12,2) := 500;
    v_fee    NUMBER(12,2) := 2;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Oracle PL/SQL is working.');
    DBMS_OUTPUT.PUT_LINE('Transfer amount: ' || TO_CHAR(v_amount, 'FM999999990.00'));
    DBMS_OUTPUT.PUT_LINE('Fee: ' || TO_CHAR(v_fee, 'FM999999990.00'));
    DBMS_OUTPUT.PUT_LINE('Total debit: ' || TO_CHAR(v_amount + v_fee, 'FM999999990.00'));
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Test failed: ' || SQLERRM);
        RAISE;
END;
/
