-- ============================================================================
-- Smoke test for STPKS_STDCIFD_MAIN against the uploaded training schema.
-- Uses synthetic data only. Run after the customer training DDL and package.
-- Run in a dedicated training schema, never in production.
-- ============================================================================
SET SERVEROUTPUT ON;

DECLARE
    l_customer  STPKS_STDCIFD_MAIN.t_customer_rec;
    l_personal  STPKS_STDCIFD_MAIN.t_personal_rec;
    l_corporate STPKS_STDCIFD_MAIN.t_corporate_rec;
    l_customer_no STTM_CUSTOMER.CUSTOMER_NO%TYPE;

    l_master_cur    SYS_REFCURSOR;
    l_personal_cur  SYS_REFCURSOR;
    l_corporate_cur SYS_REFCURSOR;
    l_master_row    STTM_CUSTOMER%ROWTYPE;
    l_personal_row  STTM_CUST_PERSONAL%ROWTYPE;
BEGIN
    -- Generate a synthetic 9-digit test CIF number.
    l_customer_no := LPAD(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999))), 9, '0');

    l_customer.customer_no         := l_customer_no;
    l_customer.customer_type       := 'I';
    l_customer.customer_category   := 'RETAIL';
    l_customer.customer_name1      := 'SAMPLE TRAINING CUSTOMER';
    l_customer.full_name           := 'SAMPLE TRAINING CUSTOMER';
    l_customer.short_name          := 'SAMPLE CUSTOMER';
    l_customer.country             := 'KHM';
    l_customer.nationality         := 'KHM';
    l_customer.language            := 'ENG';
    l_customer.local_branch        := '001';
    l_customer.cust_group          := 'RETAIL';
    l_customer.unique_id_name      := 'TRAINING_ID';
    l_customer.unique_id_value     := 'SYN-' || l_customer_no;
    l_customer.cif_status          := 'A';
    l_customer.frozen              := 'N';
    l_customer.deceased            := 'N';
    l_customer.whereabouts_unknown := 'N';

    l_personal.first_name       := 'SAMPLE';
    l_personal.last_name        := 'TRAINING CUSTOMER';
    l_personal.sex              := 'O';
    l_personal.date_of_birth    := DATE '1995-04-15';
    l_personal.birth_country    := 'KHM';
    l_personal.p_national_id    := 'SYN-' || l_customer_no;
    l_personal.resident_status  := 'R';
    l_personal.minor            := 'N';
    l_personal.e_mail           := 'training.' || l_customer_no || '@example.test';
    l_personal.mobile_number    := '012000000';
    l_personal.mob_isd_no       := '+855';
    l_personal.d_address1       := 'Training Street';
    l_personal.d_country        := 'KHM';
    l_personal.p_address1       := 'Training Street';
    l_personal.p_country        := 'KHM';

    STPKS_STDCIFD_MAIN.create_customer(
        p_customer => l_customer,
        p_personal => l_personal,
        p_corporate => l_corporate,
        p_maker_id => 'MAKER01'
    );
    COMMIT;

    -- Separate checker identity; application security must authenticate this
    -- identity in a real deployment. This test only demonstrates package logic.
    STPKS_STDCIFD_MAIN.authorize_customer(
        p_customer_no => l_customer_no,
        p_checker_id => 'CHECKER01'
    );
    COMMIT;

    STPKS_STDCIFD_MAIN.query_customer(
        p_customer_no => l_customer_no,
        p_master_cursor => l_master_cur,
        p_personal_cursor => l_personal_cur,
        p_corporate_cursor => l_corporate_cur
    );

    FETCH l_master_cur INTO l_master_row;
    FETCH l_personal_cur INTO l_personal_row;

    DBMS_OUTPUT.PUT_LINE('Created and authorized synthetic CIF: ' || l_customer_no);
    DBMS_OUTPUT.PUT_LINE('Name: ' || l_master_row.customer_name1);
    DBMS_OUTPUT.PUT_LINE('Record status: ' || l_master_row.record_stat ||
                         ', authorization status: ' || l_master_row.auth_stat);
    DBMS_OUTPUT.PUT_LINE('Personal first name: ' || l_personal_row.first_name);

    CLOSE l_master_cur;
    CLOSE l_personal_cur;
    CLOSE l_corporate_cur;
EXCEPTION
    WHEN OTHERS THEN
        IF l_master_cur%ISOPEN THEN CLOSE l_master_cur; END IF;
        IF l_personal_cur%ISOPEN THEN CLOSE l_personal_cur; END IF;
        IF l_corporate_cur%ISOPEN THEN CLOSE l_corporate_cur; END IF;
        ROLLBACK;
        RAISE;
END;
/
