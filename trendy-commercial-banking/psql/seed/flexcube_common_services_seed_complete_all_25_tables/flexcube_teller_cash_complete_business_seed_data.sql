-- ============================================================================
-- FLEXCUBE TELLER / CASH - COMPLETE CONNECTED BUSINESS SEED DATA
-- Target: Oracle Database / SQL Developer (F5 Run Script)
-- Scenario: ABC Bank training environment, branches 001 and 002
--
-- DATA QUALITY / ACCURACY NOTES
-- 1) These are realistic SYNTHETIC training records, not real bank/customer data.
-- 2) This script is designed for the Teller/Cash lab DDL supplied with the
--    conversation. That DDL itself is a documented-reference reconstruction,
--    not licensed Oracle FLEXCUBE 14.1 vendor DDL.
-- 3) Required execution order:
--      Common Services + GL seed data
--      Customer/CIF seed data
--      CASA DDL and base sample data
--      flexcube_casa_complete_business_seed_data.sql
--      Teller/Cash DDL (the uploaded DDL)
--      THIS SCRIPT
-- 4) Requires these parent master records:
--      Branches: 001, 002
--      Currencies: USD, KHR
--      Transaction codes: CDP (cash deposit), CWD (cash withdrawal)
--      GLTM_GLMASTER: at least one valid GL code; see cash-GL mapping note below
--      CASA accounts listed in the preflight block (from the CASA seed dataset).
-- 5) Cash GL mapping: the script looks for a GL description containing CASH and
--    the currency. If no suitable description is found, it falls back to the
--    lowest existing GL_CODE so that the lab can be exercised. CHECK and replace
--    that fallback with your actual USD/KHR Cash-on-Hand GLs before using the
--    dataset for accounting validation. The script prints the selected codes.
-- 6) This is a one-time seed. It checks for its own reference IDs and stops if
--    they already exist. Do not remove that guard to rerun against populated data.
-- 7) Successful transaction rows include balanced two-line journal examples and
--    update ACY balance/turnover snapshots for the linked CASA accounts. The
--    schema has no FX-rate table, so LCY fields are deliberately not recalculated.
-- 8) No production data, real names, live account numbers, or real credentials.
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT ======================================================================
PROMPT FLEXCUBE TELLER/CASH - BUSINESS SEED DATA PREFLIGHT
PROMPT ======================================================================

DECLARE
    v_count NUMBER;
BEGIN
    -- Required parent tables.
    FOR r IN (
        SELECT 'STTM_BRANCH' table_name FROM dual UNION ALL
        SELECT 'CYTM_CCY_DEFN' FROM dual UNION ALL
        SELECT 'STTM_TRN_CODE' FROM dual UNION ALL
        SELECT 'GLTM_GLMASTER' FROM dual UNION ALL
        SELECT 'STTM_CUSTOMER' FROM dual UNION ALL
        SELECT 'STTM_CUST_ACCOUNT' FROM dual UNION ALL
        SELECT 'DETM_TIL_VLT_MASTER' FROM dual UNION ALL
        SELECT 'STTB_LOCALTXN_DETAILS' FROM dual UNION ALL
        SELECT 'DETB_BATCH_MASTER' FROM dual UNION ALL
        SELECT 'DETB_RTL_TELLER' FROM dual UNION ALL
        SELECT 'DETB_JRNL_LOG' FROM dual UNION ALL
        SELECT 'DETB_PCTRN' FROM dual UNION ALL
        SELECT 'FBTB_TXNLOG_MASTER' FROM dual UNION ALL
        SELECT 'FBTB_TXNLOG_DETAILS' FROM dual UNION ALL
        SELECT 'FBTB_OVD' FROM dual
    ) LOOP
        SELECT COUNT(*) INTO v_count
          FROM USER_TABLES
         WHERE TABLE_NAME = r.table_name;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20100,
                'Missing required table ' || r.table_name ||
                '. Run the Common Services/GL/Customer/CASA and Teller DDL scripts first.');
        END IF;
    END LOOP;

    -- Required branch masters.
    SELECT COUNT(*) INTO v_count
      FROM STTM_BRANCH
     WHERE BRANCH_CODE IN ('001', '002');
    IF v_count <> 2 THEN
        RAISE_APPLICATION_ERROR(-20101,
            'Branch master rows 001 and 002 are required in STTM_BRANCH.');
    END IF;

    -- Required currency masters.
    SELECT COUNT(*) INTO v_count
      FROM CYTM_CCY_DEFN
     WHERE CCY_CODE IN ('USD', 'KHR');
    IF v_count <> 2 THEN
        RAISE_APPLICATION_ERROR(-20102,
            'Currency master rows USD and KHR are required in CYTM_CCY_DEFN.');
    END IF;

    -- Required transaction codes referenced by this teller dataset.
    SELECT COUNT(*) INTO v_count
      FROM STTM_TRN_CODE
     WHERE TRN_CODE IN ('CDP', 'CWD');
    IF v_count <> 2 THEN
        RAISE_APPLICATION_ERROR(-20103,
            'STTM_TRN_CODE must contain CDP (cash deposit) and CWD (cash withdrawal).');
    END IF;

    SELECT COUNT(*) INTO v_count FROM GLTM_GLMASTER;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20104,
            'GLTM_GLMASTER has no rows. Seed the Chart of Accounts before Teller/Cash.');
    END IF;

    -- The complete dataset below uses these known synthetic CASA account IDs.
    SELECT COUNT(*) INTO v_count
      FROM STTM_CUST_ACCOUNT
     WHERE (BRANCH_CODE = '001' AND CUST_AC_NO IN (
                '000000000000010001', -- Dara Sok, USD savings
                '000000000000010002', -- Mekong Trading, USD current
                '000000000000010003', -- Dara Sok, KHR savings
                '000000000000010004', -- Dara Sok, instant KHR (CIRD01)
                '000000000000010005', -- Dara Sok, dormant USD
                '000000000000020001', -- Mekong Trading, operating USD
                '000000000000020002', -- Mekong Trading, payroll KHR
                '000000000000020004'  -- Mekong Trading, frozen USD
            ))
        OR (BRANCH_CODE = '002' AND CUST_AC_NO IN (
                '000000000000010006', -- Dara Sok, USD current
                '000000000000020003'  -- Mekong Trading, USD collection
            ));
    IF v_count <> 10 THEN
        RAISE_APPLICATION_ERROR(-20105,
            'Expected 10 CASA accounts were not found. Run the base CASA seed and '
            || 'flexcube_casa_complete_business_seed_data.sql first.');
    END IF;

    -- Stop if this seed was already run.
    SELECT COUNT(*) INTO v_count
      FROM DETB_RTL_TELLER
     WHERE TRN_REF_NO LIKE 'LAB001260%'
        OR TRN_REF_NO LIKE 'LAB002260%';
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20106,
            'Teller seed references already exist. This is a one-time seed script.');
    END IF;

    SELECT COUNT(*) INTO v_count
      FROM DETM_TIL_VLT_MASTER
     WHERE TILL_ID IN (
        'T001-USD-01','T001-KHR-01','V001-USD-01','V001-KHR-01',
        'T002-USD-01','T002-KHR-01'
     );
    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20107,
            'One or more Teller seed till IDs already exist. Check before proceeding.');
    END IF;
END;
/

PROMPT ======================================================================
PROMPT INSERTING TILLS, VAULTS, BATCHES, TELLER TRANSACTIONS AND JOURNALS
PROMPT ======================================================================

DECLARE
    v_cash_gl_usd GLTM_GLMASTER.GL_CODE%TYPE;
    v_cash_gl_khr GLTM_GLMASTER.GL_CODE%TYPE;

    -- Find a cash GL from a recognized description column if one exists.
    -- Fallback is a valid existing GL_CODE and is explicitly printed as a
    -- lab placeholder: replace with the bank's actual Cash-on-Hand GL mapping.
    FUNCTION find_cash_gl(p_ccy IN VARCHAR2) RETURN VARCHAR2 IS
        v_gl  VARCHAR2(9);
        v_sql VARCHAR2(4000);
    BEGIN
        FOR c IN (
            SELECT column_name
              FROM USER_TAB_COLUMNS
             WHERE table_name = 'GLTM_GLMASTER'
               AND column_name IN (
                    'GL_DESC','GL_NAME','DESCRIPTION','GL_DESCRIPTION',
                    'GL_DESC1','GL_LONG_DESC'
               )
             ORDER BY CASE column_name
                        WHEN 'GL_DESC' THEN 1
                        WHEN 'GL_NAME' THEN 2
                        WHEN 'DESCRIPTION' THEN 3
                        WHEN 'GL_DESCRIPTION' THEN 4
                        WHEN 'GL_DESC1' THEN 5
                        ELSE 6
                      END
        ) LOOP
            BEGIN
                v_sql := 'SELECT MIN(GL_CODE) FROM GLTM_GLMASTER ' ||
                         'WHERE UPPER(' || c.column_name ||
                         ') LIKE ''%CASH%'' AND UPPER(' ||
                         c.column_name ||
                         ') LIKE ''%' || REPLACE(UPPER(p_ccy), '''', '''''') || '%''';
                EXECUTE IMMEDIATE v_sql INTO v_gl;
                IF v_gl IS NOT NULL THEN
                    RETURN v_gl;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END LOOP;

        -- A cash-named GL code may be used where descriptions are unavailable.
        BEGIN
            SELECT MIN(GL_CODE) INTO v_gl
              FROM GLTM_GLMASTER
             WHERE UPPER(GL_CODE) LIKE '%CASH%';
            IF v_gl IS NOT NULL THEN
                RETURN v_gl;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN NULL;
        END;

        SELECT MIN(GL_CODE) INTO v_gl FROM GLTM_GLMASTER;
        IF v_gl IS NULL THEN
            RAISE_APPLICATION_ERROR(-20110, 'No usable GL_CODE found in GLTM_GLMASTER.');
        END IF;
        DBMS_OUTPUT.PUT_LINE(
            'WARNING: no currency-specific Cash GL description found for ' || p_ccy ||
            '; using fallback GL_CODE ' || v_gl ||
            '. Replace with the actual Cash-on-Hand GL before accounting validation.');
        RETURN v_gl;
    END find_cash_gl;

    PROCEDURE add_till(
        p_branch       IN VARCHAR2,
        p_till_id      IN VARCHAR2,
        p_till_type    IN VARCHAR2,
        p_description  IN VARCHAR2,
        p_ccy          IN VARCHAR2,
        p_cash_gl      IN VARCHAR2,
        p_user         IN VARCHAR2,
        p_open_xref    IN VARCHAR2,
        p_open_float   IN NUMBER
    ) IS
    BEGIN
        INSERT INTO DETM_TIL_VLT_MASTER (
            BRANCH_CODE, TILL_ID, TILL_TYPE, TILL_DESCRIPTION,
            CASH_GL_NO, HOME_CCY, RECORD_STAT, AUTH_STAT,
            ASSIGNED_USER, ENABLED_FLAG, MAKER_ID, MAKER_STAMP,
            CHECKER_ID, CHECKER_STAMP
        ) VALUES (
            p_branch, p_till_id, p_till_type, p_description,
            p_cash_gl, p_ccy, 'O', 'A', p_user, 'Y',
            'LABMAKER', SYSDATE, 'LABCHECKER', SYSDATE
        );

        INSERT INTO FBTB_TXNLOG_MASTER (
            XREFID, BRANCH_CODE, FUNCTION_ID, USER_ID,
            LOG_DATE, LOG_STATUS, ERROR_CODE, ERROR_PARAM
        ) VALUES (
            p_open_xref, p_branch, NULL, p_user,
            SYSDATE, 'SUCCESS', NULL, NULL
        );

        INSERT INTO FBTB_TXNLOG_DETAILS (
            XREFID, SEQUENCE_NO, DETAIL_TYPE, DETAIL_VALUE
        ) VALUES (
            p_open_xref, 1, 'TILL_OPEN',
            'TILL=' || p_till_id || ';CCY=' || p_ccy ||
            ';OPENING_FLOAT=' || TO_CHAR(p_open_float) ||
            ';USER=' || p_user
        );

        INSERT INTO STTB_LOCALTXN_DETAILS (
            XREF, BRN, TXNCCY, TXNAMT, TOTIL, NARRATIVE,
            MAKERID, MAKERSTAMP, CHECKERID, CHECKERSTAMP,
            AUTHSTAT, CONTSTAT, MODNO, RECORDSTAT, ONCEAUTH,
            TILID, ELIGIBLE, ASSIGNTO, ROLE, FUNCTIONID,
            LOCKEDBY, TXNDATE, BRANCHCODE, USERID, XREF_SE
        ) VALUES (
            p_open_xref, p_branch, p_ccy, p_open_float, NULL,
            'Opening cash float for ' || p_till_id,
            'LABMAKER', SYSDATE, 'LABCHECKER', SYSDATE,
            'A', 'Y', '1', 'O', 'Y',
            p_till_id, 'Y', p_user, p_till_type, NULL,
            NULL, TRUNC(SYSDATE), p_branch, p_user, p_open_xref
        );
    END add_till;

    PROCEDURE add_teller_txn(
        p_branch         IN VARCHAR2,
        p_batch          IN VARCHAR2,
        p_till           IN VARCHAR2,
        p_trn_ref        IN VARCHAR2,
        p_xref           IN VARCHAR2,
        p_trn_code       IN VARCHAR2,
        p_function_id    IN VARCHAR2,
        p_ccy            IN VARCHAR2,
        p_amount         IN NUMBER,
        p_customer_ac_br IN VARCHAR2,
        p_customer_ac_no IN VARCHAR2,
        p_user           IN VARCHAR2,
        p_is_success     IN CHAR,
        p_error_code     IN VARCHAR2 DEFAULT NULL,
        p_error_param    IN VARCHAR2 DEFAULT NULL
    ) IS
        v_customer_no STTM_CUST_ACCOUNT.CUST_NO%TYPE;
        v_account_ccy  STTM_CUST_ACCOUNT.CCY%TYPE;
        v_cash_gl      GLTM_GLMASTER.GL_CODE%TYPE;
        v_result       VARCHAR2(12);
        v_log_detail   VARCHAR2(2000);
    BEGIN
        SELECT CUST_NO, CCY
          INTO v_customer_no, v_account_ccy
          FROM STTM_CUST_ACCOUNT
         WHERE BRANCH_CODE = p_customer_ac_br
           AND CUST_AC_NO = p_customer_ac_no;

        IF v_account_ccy <> p_ccy THEN
            RAISE_APPLICATION_ERROR(-20111,
                'Currency mismatch for account ' || p_customer_ac_no ||
                ': account=' || v_account_ccy || ', transaction=' || p_ccy);
        END IF;

        v_cash_gl := CASE p_ccy WHEN 'USD' THEN v_cash_gl_usd ELSE v_cash_gl_khr END;
        v_result  := CASE p_is_success WHEN 'Y' THEN 'SUCCESS' ELSE 'ERROR' END;

        INSERT INTO DETB_RTL_TELLER (
            TRN_REF_NO, XREF, BRANCH_CODE, BATCH_NO, TILL_ID,
            TRN_CODE, TRN_DT, VALUE_DT, CCY, TXN_AMOUNT,
            CUSTOMER_NO, ACCOUNT_BRANCH, ACCOUNT_NO, GL_CODE,
            USER_ID, AUTH_STAT, RECORD_STAT, REVERSED_FLAG
        ) VALUES (
            p_trn_ref, p_xref, p_branch, p_batch, p_till,
            p_trn_code, TRUNC(SYSDATE) + (9/24), TRUNC(SYSDATE),
            p_ccy, p_amount, v_customer_no,
            p_customer_ac_br, p_customer_ac_no, v_cash_gl,
            p_user, CASE p_is_success WHEN 'Y' THEN 'A' ELSE 'U' END,
            'O', 'N'
        );

        INSERT INTO FBTB_TXNLOG_MASTER (
            XREFID, BRANCH_CODE, FUNCTION_ID, USER_ID,
            LOG_DATE, LOG_STATUS, ERROR_CODE, ERROR_PARAM
        ) VALUES (
            p_xref, p_branch, p_function_id, p_user,
            SYSDATE, v_result, p_error_code, p_error_param
        );

        v_log_detail := 'BRANCH=' || p_branch ||
                        ';FUNCTION_ID=' || p_function_id ||
                        ';TRN_CODE=' || p_trn_code ||
                        ';ACCOUNT=' || p_customer_ac_no ||
                        ';CUSTOMER=' || v_customer_no ||
                        ';CCY=' || p_ccy ||
                        ';AMOUNT=' || TO_CHAR(p_amount);

        INSERT INTO FBTB_TXNLOG_DETAILS (
            XREFID, SEQUENCE_NO, DETAIL_TYPE, DETAIL_VALUE
        ) VALUES (
            p_xref, 1, 'REQUEST', v_log_detail
        );

        IF p_is_success = 'Y' THEN
            INSERT INTO FBTB_TXNLOG_DETAILS (
                XREFID, SEQUENCE_NO, DETAIL_TYPE, DETAIL_VALUE
            ) VALUES (
                p_xref, 2, 'ACCOUNT_VALIDATION',
                'STATUS=PASS;ACCOUNT_STATUS=NORM_OR_ACTIVE;AUTHORIZATION=APPROVED'
            );

            INSERT INTO FBTB_TXNLOG_DETAILS (
                XREFID, SEQUENCE_NO, DETAIL_TYPE, DETAIL_VALUE
            ) VALUES (
                p_xref, 3, 'POSTING_RESULT',
                'STATUS=SUCCESS;JOURNAL_LINES=2;BALANCED=Y'
            );

            -- Double-entry teller accounting:
            -- CDP = Dr Cash GL / Cr Customer CASA account.
            -- CWD = Dr Customer CASA account / Cr Cash GL.
            IF p_trn_code = 'CDP' THEN
                INSERT INTO DETB_JRNL_LOG (
                    BRANCH_CODE, TRN_REF_NO, LINE_NO, TRN_CODE,
                    ACCOUNT_BRANCH, ACCOUNT_NO, GL_CODE, CCY,
                    DR_CR, TXN_AMOUNT, NARRATIVE, POSTING_DATE
                ) VALUES (
                    p_branch, p_trn_ref, 1, p_trn_code,
                    NULL, NULL, v_cash_gl, p_ccy,
                    'D', p_amount, 'Cash received at teller', TRUNC(SYSDATE)
                );

                INSERT INTO DETB_JRNL_LOG (
                    BRANCH_CODE, TRN_REF_NO, LINE_NO, TRN_CODE,
                    ACCOUNT_BRANCH, ACCOUNT_NO, GL_CODE, CCY,
                    DR_CR, TXN_AMOUNT, NARRATIVE, POSTING_DATE
                ) VALUES (
                    p_branch, p_trn_ref, 2, p_trn_code,
                    p_customer_ac_br, p_customer_ac_no, NULL, p_ccy,
                    'C', p_amount, 'Customer deposit liability', TRUNC(SYSDATE)
                );
            ELSIF p_trn_code = 'CWD' THEN
                INSERT INTO DETB_JRNL_LOG (
                    BRANCH_CODE, TRN_REF_NO, LINE_NO, TRN_CODE,
                    ACCOUNT_BRANCH, ACCOUNT_NO, GL_CODE, CCY,
                    DR_CR, TXN_AMOUNT, NARRATIVE, POSTING_DATE
                ) VALUES (
                    p_branch, p_trn_ref, 1, p_trn_code,
                    p_customer_ac_br, p_customer_ac_no, NULL, p_ccy,
                    'D', p_amount, 'Customer cash withdrawal', TRUNC(SYSDATE)
                );

                INSERT INTO DETB_JRNL_LOG (
                    BRANCH_CODE, TRN_REF_NO, LINE_NO, TRN_CODE,
                    ACCOUNT_BRANCH, ACCOUNT_NO, GL_CODE, CCY,
                    DR_CR, TXN_AMOUNT, NARRATIVE, POSTING_DATE
                ) VALUES (
                    p_branch, p_trn_ref, 2, p_trn_code,
                    NULL, NULL, v_cash_gl, p_ccy,
                    'C', p_amount, 'Cash paid out by teller', TRUNC(SYSDATE)
                );
            ELSE
                RAISE_APPLICATION_ERROR(-20112,
                    'Only CDP and CWD are supported by this sample posting routine.');
            END IF;
        ELSE
            INSERT INTO FBTB_TXNLOG_DETAILS (
                XREFID, SEQUENCE_NO, DETAIL_TYPE, DETAIL_VALUE
            ) VALUES (
                p_xref, 2, 'VALIDATION_ERROR',
                'STATUS=REJECTED;ERROR_CODE=' || p_error_code ||
                ';DETAIL=' || p_error_param
            );

            INSERT INTO FBTB_OVD (
                XREF, SEQ_NO, BRANCH_CODE, ERROR_CODE,
                ERROR_PARAM, RESOLVED_FLAG
            ) VALUES (
                p_xref, 1, p_branch, p_error_code,
                p_error_param, 'N'
            );
        END IF;

        INSERT INTO DETB_PCTRN (
            BRANCH, TRN_REF_NO, XREF, FUNCTION_ID, PROCESS_STATUS,
            MAKER_ID, MAKER_DT_STAMP, LAST_ERROR_CODE, LAST_ERROR_PARAM
        ) VALUES (
            p_branch, p_trn_ref, p_xref, p_function_id, v_result,
            p_user, SYSDATE, p_error_code, p_error_param
        );
    END add_teller_txn;

BEGIN
    v_cash_gl_usd := find_cash_gl('USD');
    v_cash_gl_khr := find_cash_gl('KHR');

    DBMS_OUTPUT.PUT_LINE('Selected USD Cash GL: ' || v_cash_gl_usd);
    DBMS_OUTPUT.PUT_LINE('Selected KHR Cash GL: ' || v_cash_gl_khr);
    IF v_cash_gl_usd = v_cash_gl_khr THEN
        DBMS_OUTPUT.PUT_LINE(
            'NOTICE: USD and KHR mapped to the same GL. Review and use currency-specific Cash GLs if your COA defines them.');
    END IF;

    -- ------------------------------------------------------------------------
    -- 1. Teller tills and vaults.
    -- ------------------------------------------------------------------------
    add_till('001','T001-USD-01','TILL','Phnom Penh Main Branch - USD Teller 01',
             'USD',v_cash_gl_usd,'LABTELLER1','OPEN001USD01',10000);
    add_till('001','T001-KHR-01','TILL','Phnom Penh Main Branch - KHR Teller 01',
             'KHR',v_cash_gl_khr,'LABTELLER1','OPEN001KHR01',40000000);
    add_till('001','V001-USD-01','VAULT','Phnom Penh Main Branch - USD Vault',
             'USD',v_cash_gl_usd,'LABVAULT1','OPEN001USDV1',150000);
    add_till('001','V001-KHR-01','VAULT','Phnom Penh Main Branch - KHR Vault',
             'KHR',v_cash_gl_khr,'LABVAULT1','OPEN001KHRV1',600000000);
    add_till('002','T002-USD-01','TILL','Riverside Branch - USD Teller 01',
             'USD',v_cash_gl_usd,'LABTELLER2','OPEN002USD01',8000);
    add_till('002','T002-KHR-01','TILL','Riverside Branch - KHR Teller 01',
             'KHR',v_cash_gl_khr,'LABTELLER2','OPEN002KHR01',25000000);

    -- ------------------------------------------------------------------------
    -- 2. Teller batches.
    -- ------------------------------------------------------------------------
    INSERT INTO DETB_BATCH_MASTER (
        BRANCH_CODE, BATCH_NO, FUNCTION_ID, BUSINESS_DATE, BATCH_STATUS,
        MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP
    ) VALUES (
        '001','0001','1401',TRUNC(SYSDATE),'PROCESSED',
        'LABTELLER1',SYSDATE,'LABCHECKER',SYSDATE
    );

    INSERT INTO DETB_BATCH_MASTER (
        BRANCH_CODE, BATCH_NO, FUNCTION_ID, BUSINESS_DATE, BATCH_STATUS,
        MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP
    ) VALUES (
        '001','0002','1001',TRUNC(SYSDATE),'REJECTED',
        'LABTELLER1',SYSDATE,'LABCHECKER',SYSDATE
    );

    INSERT INTO DETB_BATCH_MASTER (
        BRANCH_CODE, BATCH_NO, FUNCTION_ID, BUSINESS_DATE, BATCH_STATUS,
        MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP
    ) VALUES (
        '002','0001','1401',TRUNC(SYSDATE),'PROCESSED',
        'LABTELLER2',SYSDATE,'LABCHECKER',SYSDATE
    );

    -- ------------------------------------------------------------------------
    -- 3. Successful transactions - Branch 001 (USD and KHR).
    --    Function 1401 = Cash Deposit; function 1001 = Cash Withdrawal.
    -- ------------------------------------------------------------------------
    add_teller_txn('001','0001','T001-USD-01','LAB001260001','XREF-LAB-001-260001',
        'CDP','1401','USD',750,'001','000000000000010001','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-USD-01','LAB001260002','XREF-LAB-001-260002',
        'CWD','1001','USD',120,'001','000000000000010001','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-USD-01','LAB001260003','XREF-LAB-001-260003',
        'CDP','1401','USD',2500,'001','000000000000010002','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-KHR-01','LAB001260004','XREF-LAB-001-260004',
        'CDP','1401','KHR',2500000,'001','000000000000010003','LABTELLER1','Y');

    -- Instant Account CIRD01: included as the custom KYC-alert test case.
    -- This row represents an approved training transaction after the alert check.
    add_teller_txn('001','0001','T001-KHR-01','LAB001260005','XREF-LAB-001-260005',
        'CDP','1401','KHR',450000,'001','000000000000010004','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-KHR-01','LAB001260006','XREF-LAB-001-260006',
        'CWD','1001','KHR',100000,'001','000000000000010004','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-USD-01','LAB001260007','XREF-LAB-001-260007',
        'CDP','1401','USD',12500,'001','000000000000020001','LABTELLER1','Y');

    add_teller_txn('001','0001','T001-KHR-01','LAB001260008','XREF-LAB-001-260008',
        'CWD','1001','KHR',3000000,'001','000000000000020002','LABTELLER1','Y');

    -- ------------------------------------------------------------------------
    -- 4. Rejected transactions for exception/override testing.
    --    No journal is created and no CASA balance is changed for these rows.
    -- ------------------------------------------------------------------------
    add_teller_txn('001','0002','T001-USD-01','LAB001260009','XREF-LAB-001-260009',
        'CWD','1001','USD',100,'001','000000000000010005','LABTELLER1','N',
        'AC_DORMANT','Debit blocked: customer account is dormant.');

    add_teller_txn('001','0002','T001-USD-01','LAB001260010','XREF-LAB-001-260010',
        'CWD','1001','USD',500,'002','000000000000020004','LABTELLER1','N',
        'AC_FROZEN','Debit blocked: customer account is frozen/restricted.');

    -- ------------------------------------------------------------------------
    -- 5. Successful transactions - Branch 002.
    -- ------------------------------------------------------------------------
    add_teller_txn('002','0001','T002-USD-01','LAB002260011','XREF-LAB-002-260011',
        'CDP','1401','USD',7500,'002','000000000000020003','LABTELLER2','Y');

    add_teller_txn('002','0001','T002-USD-01','LAB002260012','XREF-LAB-002-260012',
        'CDP','1401','USD',350,'002','000000000000010006','LABTELLER2','Y');

    -- ------------------------------------------------------------------------
    -- 6. Update ACY balance and turnover snapshots to agree with successful
    --    teller journals. LCY is not recalculated because this lab has no FX rate.
    -- ------------------------------------------------------------------------
    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 630,
           ACY_AVL_BAL = ACY_AVL_BAL + 630,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 750,
           ACY_TODAY_TOVER_DR = ACY_TODAY_TOVER_DR + 120
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000010001';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 2500,
           ACY_AVL_BAL = ACY_AVL_BAL + 2500,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 2500
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000010002';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 2500000,
           ACY_AVL_BAL = ACY_AVL_BAL + 2500000,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 2500000
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000010003';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 350000,
           ACY_AVL_BAL = ACY_AVL_BAL + 350000,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 450000,
           ACY_TODAY_TOVER_DR = ACY_TODAY_TOVER_DR + 100000
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000010004';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 12500,
           ACY_AVL_BAL = ACY_AVL_BAL + 12500,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 12500
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000020001';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE - 3000000,
           ACY_AVL_BAL = ACY_AVL_BAL - 3000000,
           ACY_TODAY_TOVER_DR = ACY_TODAY_TOVER_DR + 3000000
     WHERE BRANCH_CODE='001' AND CUST_AC_NO='000000000000020002';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 7500,
           ACY_AVL_BAL = ACY_AVL_BAL + 7500,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 7500
     WHERE BRANCH_CODE='002' AND CUST_AC_NO='000000000000020003';

    UPDATE STTM_CUST_ACCOUNT
       SET ACY_CURR_BALANCE = ACY_CURR_BALANCE + 350,
           ACY_AVL_BAL = ACY_AVL_BAL + 350,
           ACY_TODAY_TOVER_CR = ACY_TODAY_TOVER_CR + 350
     WHERE BRANCH_CODE='002' AND CUST_AC_NO='000000000000010006';

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Teller/Cash synthetic business seed data committed successfully.');
    DBMS_OUTPUT.PUT_LINE('Created 6 tills/vaults, 3 batches, 12 teller transactions,');
    DBMS_OUTPUT.PUT_LINE('20 journal lines, 18 transaction/till log masters and 2 overrides.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Seed failed; transaction rolled back: ' || SQLERRM);
        RAISE;
END;
/

PROMPT ======================================================================
PROMPT VERIFICATION 1 - TELLER TRANSACTION AND PROCESSING STATUS
PROMPT ======================================================================
SELECT T.BRANCH_CODE,
       T.TRN_REF_NO,
       T.TRN_CODE,
       T.CCY,
       T.TXN_AMOUNT,
       T.CUSTOMER_NO,
       T.ACCOUNT_NO,
       T.USER_ID,
       P.PROCESS_STATUS,
       T.AUTH_STAT,
       T.REVERSED_FLAG
  FROM DETB_RTL_TELLER T
  JOIN DETB_PCTRN P
    ON P.BRANCH = T.BRANCH_CODE
   AND P.TRN_REF_NO = T.TRN_REF_NO
 WHERE T.TRN_REF_NO LIKE 'LAB001260%'
    OR T.TRN_REF_NO LIKE 'LAB002260%'
 ORDER BY T.BRANCH_CODE, T.TRN_REF_NO;

PROMPT ======================================================================
PROMPT VERIFICATION 2 - DEBIT/CREDIT BALANCE BY TELLER TRANSACTION
PROMPT ======================================================================
SELECT BRANCH_CODE,
       TRN_REF_NO,
       SUM(CASE WHEN DR_CR='D' THEN TXN_AMOUNT ELSE 0 END) AS TOTAL_DEBIT,
       SUM(CASE WHEN DR_CR='C' THEN TXN_AMOUNT ELSE 0 END) AS TOTAL_CREDIT,
       CASE
         WHEN SUM(CASE WHEN DR_CR='D' THEN TXN_AMOUNT ELSE 0 END) =
              SUM(CASE WHEN DR_CR='C' THEN TXN_AMOUNT ELSE 0 END)
         THEN 'BALANCED' ELSE 'UNBALANCED'
       END AS JOURNAL_STATUS
  FROM DETB_JRNL_LOG
 WHERE TRN_REF_NO LIKE 'LAB001260%'
    OR TRN_REF_NO LIKE 'LAB002260%'
 GROUP BY BRANCH_CODE, TRN_REF_NO
 ORDER BY BRANCH_CODE, TRN_REF_NO;

PROMPT ======================================================================
PROMPT VERIFICATION 3 - OVERRIDE / REJECTED TRANSACTIONS
PROMPT ======================================================================
SELECT O.BRANCH_CODE, O.XREF, O.ERROR_CODE, O.ERROR_PARAM,
       O.RESOLVED_FLAG, L.LOG_STATUS
  FROM FBTB_OVD O
  JOIN FBTB_TXNLOG_MASTER L ON L.XREFID = O.XREF
 WHERE O.XREF LIKE 'XREF-LAB-%'
 ORDER BY O.BRANCH_CODE, O.XREF;

PROMPT ======================================================================
PROMPT VERIFICATION 4 - TILL / VAULT MASTER AND OPENING FLOAT
PROMPT ======================================================================
SELECT T.BRANCH_CODE, T.TILL_ID, T.TILL_TYPE, T.HOME_CCY,
       T.CASH_GL_NO, T.ASSIGNED_USER, T.ENABLED_FLAG,
       L.TXNAMT AS OPENING_FLOAT, L.AUTHSTAT
  FROM DETM_TIL_VLT_MASTER T
  LEFT JOIN STTB_LOCALTXN_DETAILS L
    ON L.BRANCHCODE = T.BRANCH_CODE
   AND L.TILID = T.TILL_ID
 WHERE T.TILL_ID IN (
    'T001-USD-01','T001-KHR-01','V001-USD-01','V001-KHR-01',
    'T002-USD-01','T002-KHR-01'
 )
 ORDER BY T.BRANCH_CODE, T.TILL_ID;

PROMPT ======================================================================
PROMPT VERIFICATION 5 - CASA BALANCE SNAPSHOTS AFTER SUCCESSFUL POSTINGS
PROMPT ======================================================================
SELECT BRANCH_CODE, CUST_AC_NO, CUST_NO, CCY, ACCOUNT_CLASS,
       ACY_CURR_BALANCE, ACY_AVL_BAL,
       ACY_TODAY_TOVER_CR, ACY_TODAY_TOVER_DR,
       ACC_STATUS, AC_STAT_DORMANT, AC_STAT_FROZEN
  FROM STTM_CUST_ACCOUNT
 WHERE CUST_AC_NO IN (
    '000000000000010001','000000000000010002','000000000000010003',
    '000000000000010004','000000000000010005','000000000000010006',
    '000000000000020001','000000000000020002','000000000000020003',
    '000000000000020004'
 )
 ORDER BY BRANCH_CODE, CUST_AC_NO;

PROMPT ======================================================================
PROMPT END OF TELLER/CASH BUSINESS SEED DATA
PROMPT ======================================================================
