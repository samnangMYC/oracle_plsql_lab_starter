-- ============================================================================
-- Smoke test for corporate CIF creation and authorization.
-- Synthetic training data only. Requires STTM_CUST_GROUP.SME to be authorized.
-- ============================================================================
SET SERVEROUTPUT ON;

DECLARE
    l_customer  STPKS_STDCIFD_MAIN.t_customer_rec;
    l_personal  STPKS_STDCIFD_MAIN.t_personal_rec;
    l_corporate STPKS_STDCIFD_MAIN.t_corporate_rec;
    l_customer_no STTM_CUSTOMER.CUSTOMER_NO%TYPE;
BEGIN
    l_customer_no := LPAD(TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(100000000, 999999999))), 9, '0');

    l_customer.customer_no         := l_customer_no;
    l_customer.customer_type       := 'C';
    l_customer.customer_category   := 'CORPORATE';
    l_customer.customer_name1      := 'SAMPLE TRAINING TRADING CO';
    l_customer.full_name           := 'SAMPLE TRAINING TRADING CO';
    l_customer.short_name          := 'SAMPLE TRADING';
    l_customer.country             := 'KHM';
    l_customer.language            := 'ENG';
    l_customer.local_branch        := '001';
    l_customer.cust_group          := 'SME';
    l_customer.unique_id_name      := 'TRAINING_REG_NO';
    l_customer.unique_id_value     := 'SYN-' || l_customer_no;
    l_customer.cif_status          := 'A';
    l_customer.frozen              := 'N';
    l_customer.deceased            := 'N';
    l_customer.whereabouts_unknown := 'N';

    l_corporate.customer_no          := l_customer_no;
    l_corporate.company_type         := 'LIMITED';
    l_corporate.business_nature      := 'TRADING';
    l_corporate.incorporation_no     := 'SYN-' || l_customer_no;
    l_corporate.incorporation_date   := DATE '2021-05-20';
    l_corporate.incorporation_country := 'KHM';
    l_corporate.registered_address1  := 'Training Business Street';
    l_corporate.registered_address2  := 'Phnom Penh';

    STPKS_STDCIFD_MAIN.create_customer(
        p_customer => l_customer,
        p_personal => l_personal,
        p_corporate => l_corporate,
        p_maker_id => 'MAKER01'
    );
    COMMIT;

    STPKS_STDCIFD_MAIN.authorize_customer(
        p_customer_no => l_customer_no,
        p_checker_id => 'CHECKER01'
    );
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Created and authorized synthetic corporate CIF: ' || l_customer_no);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
