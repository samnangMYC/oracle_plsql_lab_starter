-- ============================================================================
-- STPKS_STDCIFD_MAIN
-- Training implementation based on the user-provided educational schema.
-- NOT Oracle's proprietary/generated FLEXCUBE 14.1 package.
-- Run only in the dedicated training schema that contains the supplied tables.
-- Caller controls COMMIT/ROLLBACK; this package never commits internally.
-- ============================================================================
CREATE OR REPLACE PACKAGE STPKS_STDCIFD_MAIN AUTHID DEFINER AS
    TYPE t_customer_rec IS RECORD (
        customer_no              VARCHAR2(9),
        customer_type            VARCHAR2(1),
        customer_category        VARCHAR2(10),
        customer_name1           VARCHAR2(105),
        customer_name2           VARCHAR2(105),
        full_name                VARCHAR2(255),
        short_name               VARCHAR2(20),
        short_name2              VARCHAR2(20),
        address_line1            VARCHAR2(105),
        address_line2            VARCHAR2(105),
        address_line3            VARCHAR2(105),
        address_line4            VARCHAR2(105),
        country                  VARCHAR2(3),
        nationality              VARCHAR2(3),
        language                 VARCHAR2(3),
        pincode                  VARCHAR2(15),
        local_branch             VARCHAR2(3),
        access_group             VARCHAR2(20),
        cust_classification      VARCHAR2(1),
        cust_group               VARCHAR2(10),
        kyc_details              VARCHAR2(1),
        kyc_ref_no               VARCHAR2(20),
        unique_id_name           VARCHAR2(30),
        unique_id_value          VARCHAR2(50),
        cif_status               VARCHAR2(1),
        frozen                   VARCHAR2(1),
        deceased                 VARCHAR2(1),
        whereabouts_unknown      VARCHAR2(1)
    );

    TYPE t_personal_rec IS RECORD (
        customer_no              VARCHAR2(9),
        customer_prefix          VARCHAR2(10),
        customer_prefix1         VARCHAR2(10),
        customer_prefix2         VARCHAR2(10),
        first_name               VARCHAR2(105),
        middle_name              VARCHAR2(105),
        last_name                VARCHAR2(105),
        sex                      VARCHAR2(1),
        date_of_birth            DATE,
        place_of_birth           VARCHAR2(105),
        birth_country            VARCHAR2(3),
        passport_no              VARCHAR2(30),
        ppt_iss_date             DATE,
        ppt_exp_date             DATE,
        p_national_id            VARCHAR2(30),
        resident_status          VARCHAR2(1),
        us_res_status            VARCHAR2(1),
        vst_us_prev              VARCHAR2(1),
        mother_maiden_name       VARCHAR2(105),
        marital_status           VARCHAR2(1),
        spouse_name              VARCHAR2(105),
        spouse_emp_status        VARCHAR2(1),
        dependent_children       NUMBER(3),
        dependent_others         NUMBER(3),
        educational_status       VARCHAR2(10),
        accomodation             VARCHAR2(10),
        legal_guardian           VARCHAR2(105),
        minor                    VARCHAR2(1),
        cust_comm_mode           VARCHAR2(10),
        e_mail                   VARCHAR2(254),
        mobile_number            VARCHAR2(20),
        mob_isd_no               VARCHAR2(5),
        telephone                VARCHAR2(20),
        tel_isd_no               VARCHAR2(5),
        home_tel_no              VARCHAR2(20),
        home_tel_isd             VARCHAR2(5),
        fax                      VARCHAR2(20),
        fax_isd_no               VARCHAR2(5),
        d_address1               VARCHAR2(105),
        d_address2               VARCHAR2(105),
        d_address3               VARCHAR2(105),
        d_address4               VARCHAR2(105),
        d_country                VARCHAR2(3),
        d_pincode                VARCHAR2(15),
        p_address1               VARCHAR2(105),
        p_address2               VARCHAR2(105),
        p_address3               VARCHAR2(105),
        p_address4               VARCHAR2(105),
        p_country                VARCHAR2(3),
        p_pincode                VARCHAR2(15)
    );

    TYPE t_corporate_rec IS RECORD (
        customer_no              VARCHAR2(9),
        company_type             VARCHAR2(10),
        business_nature          VARCHAR2(10),
        group_name               VARCHAR2(105),
        employee_number          NUMBER(10),
        annual_turnover          NUMBER(20,2),
        parent_cmpny_country     VARCHAR2(3),
        othr_company_type        VARCHAR2(105),
        incorporation_no         VARCHAR2(50),
        incorporation_date       DATE,
        incorporation_country    VARCHAR2(3),
        registered_address1      VARCHAR2(105),
        registered_address2      VARCHAR2(105),
        registered_address3      VARCHAR2(105),
        registered_address4      VARCHAR2(105),
        kyc_comments             VARCHAR2(4000),
        kyc_nxt_review_date      DATE
    );

    PROCEDURE validate_customer(p_customer IN t_customer_rec);

    PROCEDURE create_customer(
        p_customer IN t_customer_rec,
        p_personal IN t_personal_rec,
        p_corporate IN t_corporate_rec,
        p_maker_id IN VARCHAR2
    );

    -- This training schema has a single-row model, not a separate authorized
    -- version plus pending amendment version. Therefore amendments are allowed
    -- only while the master record is still unauthorized and never authorized.
    PROCEDURE amend_pending_customer(
        p_customer IN t_customer_rec,
        p_personal IN t_personal_rec,
        p_corporate IN t_corporate_rec,
        p_maker_id IN VARCHAR2
    );

    PROCEDURE authorize_customer(
        p_customer_no IN STTM_CUSTOMER.CUSTOMER_NO%TYPE,
        p_checker_id IN VARCHAR2
    );

    PROCEDURE query_customer(
        p_customer_no IN STTM_CUSTOMER.CUSTOMER_NO%TYPE,
        p_master_cursor OUT SYS_REFCURSOR,
        p_personal_cursor OUT SYS_REFCURSOR,
        p_corporate_cursor OUT SYS_REFCURSOR
    );
END STPKS_STDCIFD_MAIN;
/

CREATE OR REPLACE PACKAGE BODY STPKS_STDCIFD_MAIN AS

    PROCEDURE validate_customer(p_customer IN t_customer_rec) IS
        l_count PLS_INTEGER;
    BEGIN
        IF TRIM(p_customer.customer_no) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Customer number is required.');
        END IF;
        IF LENGTH(TRIM(p_customer.customer_no)) > 9 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Customer number cannot exceed 9 characters.');
        END IF;
        IF p_customer.customer_no <> TRIM(p_customer.customer_no) THEN
            RAISE_APPLICATION_ERROR(-20003, 'Customer number cannot contain leading or trailing spaces.');
        END IF;
        IF p_customer.customer_type IS NULL OR UPPER(p_customer.customer_type) NOT IN ('I','C') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Customer type must be I (Individual) or C (Corporate).');
        END IF;
        IF TRIM(p_customer.customer_category) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20005, 'Customer category is required.');
        END IF;
        IF TRIM(p_customer.customer_name1) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20006, 'Customer name is required.');
        END IF;
        IF TRIM(p_customer.short_name) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20007, 'Short name is required.');
        END IF;
        IF TRIM(p_customer.local_branch) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20008, 'Local branch is required.');
        END IF;
        IF p_customer.cif_status IS NOT NULL
           AND UPPER(p_customer.cif_status) NOT IN ('A','S','D') THEN
            RAISE_APPLICATION_ERROR(-20009, 'CIF status must be A, S or D.');
        END IF;
        IF p_customer.frozen IS NOT NULL AND UPPER(p_customer.frozen) NOT IN ('Y','N') THEN
            RAISE_APPLICATION_ERROR(-20010, 'FROZEN must be Y or N.');
        END IF;
        IF p_customer.deceased IS NOT NULL AND UPPER(p_customer.deceased) NOT IN ('Y','N') THEN
            RAISE_APPLICATION_ERROR(-20011, 'DECEASED must be Y or N.');
        END IF;
        IF p_customer.whereabouts_unknown IS NOT NULL
           AND UPPER(p_customer.whereabouts_unknown) NOT IN ('Y','N') THEN
            RAISE_APPLICATION_ERROR(-20012, 'WHEREABOUTS_UNKNOWN must be Y or N.');
        END IF;
        IF (p_customer.unique_id_name IS NULL AND p_customer.unique_id_value IS NOT NULL)
           OR (p_customer.unique_id_name IS NOT NULL AND p_customer.unique_id_value IS NULL) THEN
            RAISE_APPLICATION_ERROR(-20013, 'Unique ID name and value must both be supplied.');
        END IF;

        IF p_customer.cust_group IS NOT NULL THEN
            SELECT COUNT(*) INTO l_count
              FROM STTM_CUST_GROUP
             WHERE CUST_GROUP = p_customer.cust_group
               AND RECORD_STAT = 'O'
               AND AUTH_STAT = 'A';
            IF l_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20014, 'Customer group does not exist or is not authorized.');
            END IF;
        END IF;

        IF p_customer.unique_id_name IS NOT NULL THEN
            SELECT COUNT(*) INTO l_count
              FROM STTM_CUSTOMER
             WHERE UPPER(UNIQUE_ID_NAME) = UPPER(p_customer.unique_id_name)
               AND UPPER(UNIQUE_ID_VALUE) = UPPER(p_customer.unique_id_value)
               AND CUSTOMER_NO <> p_customer.customer_no;
            IF l_count > 0 THEN
                RAISE_APPLICATION_ERROR(-20015, 'The supplied unique identification already belongs to another customer.');
            END IF;
        END IF;
    END validate_customer;

    PROCEDURE create_customer(
        p_customer IN t_customer_rec,
        p_personal IN t_personal_rec,
        p_corporate IN t_corporate_rec,
        p_maker_id IN VARCHAR2
    ) IS
        l_maker_id VARCHAR2(12) := UPPER(TRIM(p_maker_id));
        l_count PLS_INTEGER;
    BEGIN
        SAVEPOINT sp_stdcifd_create;
        IF l_maker_id IS NULL OR LENGTH(l_maker_id) > 12 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Maker ID is required and cannot exceed 12 characters.');
        END IF;
        validate_customer(p_customer);

        SELECT COUNT(*) INTO l_count
          FROM STTM_CUSTOMER
         WHERE CUSTOMER_NO = p_customer.customer_no;
        IF l_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20021, 'Customer number already exists.');
        END IF;

        IF UPPER(p_customer.customer_type) = 'I' THEN
            IF p_personal.customer_no IS NOT NULL
               AND p_personal.customer_no <> p_customer.customer_no THEN
                RAISE_APPLICATION_ERROR(-20022, 'Personal detail customer number does not match master.');
            END IF;
            IF p_personal.date_of_birth IS NOT NULL
               AND p_personal.date_of_birth > TRUNC(SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20023, 'Date of birth cannot be in the future.');
            END IF;
            IF p_personal.ppt_exp_date IS NOT NULL AND p_personal.ppt_iss_date IS NOT NULL
               AND p_personal.ppt_exp_date < p_personal.ppt_iss_date THEN
                RAISE_APPLICATION_ERROR(-20024, 'Passport expiry date cannot precede issue date.');
            END IF;
        ELSE
            IF p_corporate.customer_no IS NOT NULL
               AND p_corporate.customer_no <> p_customer.customer_no THEN
                RAISE_APPLICATION_ERROR(-20025, 'Corporate detail customer number does not match master.');
            END IF;
            IF p_corporate.incorporation_date IS NOT NULL
               AND p_corporate.incorporation_date > TRUNC(SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20026, 'Incorporation date cannot be in the future.');
            END IF;
        END IF;

        INSERT INTO STTM_CUSTOMER (
            CUSTOMER_NO,
            CUSTOMER_TYPE,
            CUSTOMER_CATEGORY,
            CUSTOMER_NAME1,
            CUSTOMER_NAME2,
            FULL_NAME,
            SHORT_NAME,
            SHORT_NAME2,
            ADDRESS_LINE1,
            ADDRESS_LINE2,
            ADDRESS_LINE3,
            ADDRESS_LINE4,
            COUNTRY,
            NATIONALITY,
            LANGUAGE,
            PINCODE,
            LOCAL_BRANCH,
            ACCESS_GROUP,
            CUST_CLASSIFICATION,
            CUST_GROUP,
            KYC_DETAILS,
            KYC_REF_NO,
            UNIQUE_ID_NAME,
            UNIQUE_ID_VALUE,
            CIF_STATUS,
            FROZEN,
            DECEASED,
            WHEREABOUTS_UNKNOWN,
            RECORD_STAT, AUTH_STAT, MOD_NO, MAKER_ID, MAKER_DT_STAMP,
            CHECKER_ID, CHECKER_DT_STAMP, ONCE_AUTH
        ) VALUES (
            p_customer.customer_no,
            UPPER(p_customer.customer_type),
            p_customer.customer_category,
            p_customer.customer_name1,
            p_customer.customer_name2,
            p_customer.full_name,
            p_customer.short_name,
            p_customer.short_name2,
            p_customer.address_line1,
            p_customer.address_line2,
            p_customer.address_line3,
            p_customer.address_line4,
            p_customer.country,
            p_customer.nationality,
            p_customer.language,
            p_customer.pincode,
            p_customer.local_branch,
            p_customer.access_group,
            p_customer.cust_classification,
            p_customer.cust_group,
            p_customer.kyc_details,
            p_customer.kyc_ref_no,
            p_customer.unique_id_name,
            p_customer.unique_id_value,
            NVL(UPPER(p_customer.cif_status), 'A'),
            NVL(UPPER(p_customer.frozen), 'N'),
            NVL(UPPER(p_customer.deceased), 'N'),
            NVL(UPPER(p_customer.whereabouts_unknown), 'N'),
            'O', 'U', 1, l_maker_id, SYSDATE, NULL, NULL, 'N'
        );

        IF UPPER(p_customer.customer_type) = 'I' THEN
        INSERT INTO STTM_CUST_PERSONAL (
            CUSTOMER_NO,
            CUSTOMER_PREFIX,
            CUSTOMER_PREFIX1,
            CUSTOMER_PREFIX2,
            FIRST_NAME,
            MIDDLE_NAME,
            LAST_NAME,
            SEX,
            DATE_OF_BIRTH,
            PLACE_OF_BIRTH,
            BIRTH_COUNTRY,
            PASSPORT_NO,
            PPT_ISS_DATE,
            PPT_EXP_DATE,
            P_NATIONAL_ID,
            RESIDENT_STATUS,
            US_RES_STATUS,
            VST_US_PREV,
            MOTHER_MAIDEN_NAME,
            MARITAL_STATUS,
            SPOUSE_NAME,
            SPOUSE_EMP_STATUS,
            DEPENDENT_CHILDREN,
            DEPENDENT_OTHERS,
            EDUCATIONAL_STATUS,
            ACCOMODATION,
            LEGAL_GUARDIAN,
            MINOR,
            CUST_COMM_MODE,
            E_MAIL,
            MOBILE_NUMBER,
            MOB_ISD_NO,
            TELEPHONE,
            TEL_ISD_NO,
            HOME_TEL_NO,
            HOME_TEL_ISD,
            FAX,
            FAX_ISD_NO,
            D_ADDRESS1,
            D_ADDRESS2,
            D_ADDRESS3,
            D_ADDRESS4,
            D_COUNTRY,
            D_PINCODE,
            P_ADDRESS1,
            P_ADDRESS2,
            P_ADDRESS3,
            P_ADDRESS4,
            P_COUNTRY,
            P_PINCODE, RECORD_STAT, AUTH_STAT, MOD_NO,
            MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP, ONCE_AUTH
        ) VALUES (
            p_customer.customer_no,
            p_personal.customer_prefix,
            p_personal.customer_prefix1,
            p_personal.customer_prefix2,
            p_personal.first_name,
            p_personal.middle_name,
            p_personal.last_name,
            UPPER(p_personal.sex),
            p_personal.date_of_birth,
            p_personal.place_of_birth,
            p_personal.birth_country,
            p_personal.passport_no,
            p_personal.ppt_iss_date,
            p_personal.ppt_exp_date,
            p_personal.p_national_id,
            p_personal.resident_status,
            p_personal.us_res_status,
            p_personal.vst_us_prev,
            p_personal.mother_maiden_name,
            p_personal.marital_status,
            p_personal.spouse_name,
            p_personal.spouse_emp_status,
            p_personal.dependent_children,
            p_personal.dependent_others,
            p_personal.educational_status,
            p_personal.accomodation,
            p_personal.legal_guardian,
            NVL(UPPER(p_personal.minor), 'N'),
            p_personal.cust_comm_mode,
            p_personal.e_mail,
            p_personal.mobile_number,
            p_personal.mob_isd_no,
            p_personal.telephone,
            p_personal.tel_isd_no,
            p_personal.home_tel_no,
            p_personal.home_tel_isd,
            p_personal.fax,
            p_personal.fax_isd_no,
            p_personal.d_address1,
            p_personal.d_address2,
            p_personal.d_address3,
            p_personal.d_address4,
            p_personal.d_country,
            p_personal.d_pincode,
            p_personal.p_address1,
            p_personal.p_address2,
            p_personal.p_address3,
            p_personal.p_address4,
            p_personal.p_country,
            p_personal.p_pincode, 'O', 'U', 1,
            l_maker_id, SYSDATE, NULL, NULL, 'N'
        );
        ELSE
        INSERT INTO STTM_CUST_CORPORATE (
            CUSTOMER_NO,
            COMPANY_TYPE,
            BUSINESS_NATURE,
            GROUP_NAME,
            EMPLOYEE_NUMBER,
            ANNUAL_TURNOVER,
            PARENT_CMPNY_COUNTRY,
            OTHR_COMPANY_TYPE,
            INCORPORATION_NO,
            INCORPORATION_DATE,
            INCORPORATION_COUNTRY,
            REGISTERED_ADDRESS1,
            REGISTERED_ADDRESS2,
            REGISTERED_ADDRESS3,
            REGISTERED_ADDRESS4,
            KYC_COMMENTS,
            KYC_NXT_REVIEW_DATE, RECORD_STAT, AUTH_STAT, MOD_NO,
            MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP, ONCE_AUTH
        ) VALUES (
            p_customer.customer_no,
            p_corporate.company_type,
            p_corporate.business_nature,
            p_corporate.group_name,
            p_corporate.employee_number,
            p_corporate.annual_turnover,
            p_corporate.parent_cmpny_country,
            p_corporate.othr_company_type,
            p_corporate.incorporation_no,
            p_corporate.incorporation_date,
            p_corporate.incorporation_country,
            p_corporate.registered_address1,
            p_corporate.registered_address2,
            p_corporate.registered_address3,
            p_corporate.registered_address4,
            p_corporate.kyc_comments,
            p_corporate.kyc_nxt_review_date, 'O', 'U', 1,
            l_maker_id, SYSDATE, NULL, NULL, 'N'
        );
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_stdcifd_create;
            RAISE;
    END create_customer;

    PROCEDURE amend_pending_customer(
        p_customer IN t_customer_rec,
        p_personal IN t_personal_rec,
        p_corporate IN t_corporate_rec,
        p_maker_id IN VARCHAR2
    ) IS
        l_maker_id VARCHAR2(12) := UPPER(TRIM(p_maker_id));
        l_old_type STTM_CUSTOMER.CUSTOMER_TYPE%TYPE;
        l_auth_stat STTM_CUSTOMER.AUTH_STAT%TYPE;
        l_once_auth STTM_CUSTOMER.ONCE_AUTH%TYPE;
    BEGIN
        SAVEPOINT sp_stdcifd_amend;
        IF l_maker_id IS NULL OR LENGTH(l_maker_id) > 12 THEN
            RAISE_APPLICATION_ERROR(-20030, 'Maker ID is required and cannot exceed 12 characters.');
        END IF;
        validate_customer(p_customer);

        BEGIN
            SELECT CUSTOMER_TYPE, AUTH_STAT, ONCE_AUTH
              INTO l_old_type, l_auth_stat, l_once_auth
              FROM STTM_CUSTOMER
             WHERE CUSTOMER_NO = p_customer.customer_no
             FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20031, 'Customer does not exist.');
        END;

        IF l_auth_stat <> 'U' OR NVL(l_once_auth,'N') = 'Y' THEN
            RAISE_APPLICATION_ERROR(-20032,
                'This training schema cannot safely amend an authorized CIF. Use an authorized-version/pending-version model first.');
        END IF;
        IF l_old_type <> UPPER(p_customer.customer_type) THEN
            RAISE_APPLICATION_ERROR(-20033, 'Changing customer type is not supported. Create the correct customer type instead.');
        END IF;

        UPDATE STTM_CUSTOMER
           SET CUSTOMER_TYPE = UPPER(p_customer.customer_type),
            CUSTOMER_CATEGORY = p_customer.customer_category,
            CUSTOMER_NAME1 = p_customer.customer_name1,
            CUSTOMER_NAME2 = p_customer.customer_name2,
            FULL_NAME = p_customer.full_name,
            SHORT_NAME = p_customer.short_name,
            SHORT_NAME2 = p_customer.short_name2,
            ADDRESS_LINE1 = p_customer.address_line1,
            ADDRESS_LINE2 = p_customer.address_line2,
            ADDRESS_LINE3 = p_customer.address_line3,
            ADDRESS_LINE4 = p_customer.address_line4,
            COUNTRY = p_customer.country,
            NATIONALITY = p_customer.nationality,
            LANGUAGE = p_customer.language,
            PINCODE = p_customer.pincode,
            LOCAL_BRANCH = p_customer.local_branch,
            ACCESS_GROUP = p_customer.access_group,
            CUST_CLASSIFICATION = p_customer.cust_classification,
            CUST_GROUP = p_customer.cust_group,
            KYC_DETAILS = p_customer.kyc_details,
            KYC_REF_NO = p_customer.kyc_ref_no,
            UNIQUE_ID_NAME = p_customer.unique_id_name,
            UNIQUE_ID_VALUE = p_customer.unique_id_value,
               CIF_STATUS = NVL(UPPER(p_customer.cif_status), 'A'),
               FROZEN = NVL(UPPER(p_customer.frozen), 'N'),
               DECEASED = NVL(UPPER(p_customer.deceased), 'N'),
               WHEREABOUTS_UNKNOWN = NVL(UPPER(p_customer.whereabouts_unknown), 'N'),
               RECORD_STAT = 'O', AUTH_STAT = 'U', MOD_NO = MOD_NO + 1,
               MAKER_ID = l_maker_id, MAKER_DT_STAMP = SYSDATE,
               CHECKER_ID = NULL, CHECKER_DT_STAMP = NULL, ONCE_AUTH = 'N'
         WHERE CUSTOMER_NO = p_customer.customer_no;

        IF UPPER(p_customer.customer_type) = 'I' THEN
            IF p_personal.date_of_birth IS NOT NULL
               AND p_personal.date_of_birth > TRUNC(SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20034, 'Date of birth cannot be in the future.');
            END IF;
        UPDATE STTM_CUST_PERSONAL
        SET CUSTOMER_PREFIX = p_personal.customer_prefix,
            CUSTOMER_PREFIX1 = p_personal.customer_prefix1,
            CUSTOMER_PREFIX2 = p_personal.customer_prefix2,
            FIRST_NAME = p_personal.first_name,
            MIDDLE_NAME = p_personal.middle_name,
            LAST_NAME = p_personal.last_name,
            SEX = UPPER(p_personal.sex),
            DATE_OF_BIRTH = p_personal.date_of_birth,
            PLACE_OF_BIRTH = p_personal.place_of_birth,
            BIRTH_COUNTRY = p_personal.birth_country,
            PASSPORT_NO = p_personal.passport_no,
            PPT_ISS_DATE = p_personal.ppt_iss_date,
            PPT_EXP_DATE = p_personal.ppt_exp_date,
            P_NATIONAL_ID = p_personal.p_national_id,
            RESIDENT_STATUS = p_personal.resident_status,
            US_RES_STATUS = p_personal.us_res_status,
            VST_US_PREV = p_personal.vst_us_prev,
            MOTHER_MAIDEN_NAME = p_personal.mother_maiden_name,
            MARITAL_STATUS = p_personal.marital_status,
            SPOUSE_NAME = p_personal.spouse_name,
            SPOUSE_EMP_STATUS = p_personal.spouse_emp_status,
            DEPENDENT_CHILDREN = p_personal.dependent_children,
            DEPENDENT_OTHERS = p_personal.dependent_others,
            EDUCATIONAL_STATUS = p_personal.educational_status,
            ACCOMODATION = p_personal.accomodation,
            LEGAL_GUARDIAN = p_personal.legal_guardian,
            MINOR = NVL(UPPER(p_personal.minor), 'N'),
            CUST_COMM_MODE = p_personal.cust_comm_mode,
            E_MAIL = p_personal.e_mail,
            MOBILE_NUMBER = p_personal.mobile_number,
            MOB_ISD_NO = p_personal.mob_isd_no,
            TELEPHONE = p_personal.telephone,
            TEL_ISD_NO = p_personal.tel_isd_no,
            HOME_TEL_NO = p_personal.home_tel_no,
            HOME_TEL_ISD = p_personal.home_tel_isd,
            FAX = p_personal.fax,
            FAX_ISD_NO = p_personal.fax_isd_no,
            D_ADDRESS1 = p_personal.d_address1,
            D_ADDRESS2 = p_personal.d_address2,
            D_ADDRESS3 = p_personal.d_address3,
            D_ADDRESS4 = p_personal.d_address4,
            D_COUNTRY = p_personal.d_country,
            D_PINCODE = p_personal.d_pincode,
            P_ADDRESS1 = p_personal.p_address1,
            P_ADDRESS2 = p_personal.p_address2,
            P_ADDRESS3 = p_personal.p_address3,
            P_ADDRESS4 = p_personal.p_address4,
            P_COUNTRY = p_personal.p_country,
            P_PINCODE = p_personal.p_pincode,
            RECORD_STAT = 'O',
            AUTH_STAT = 'U',
            MOD_NO = MOD_NO + 1,
            MAKER_ID = l_maker_id,
            MAKER_DT_STAMP = SYSDATE,
            CHECKER_ID = NULL,
            CHECKER_DT_STAMP = NULL,
            ONCE_AUTH = 'N'
        WHERE CUSTOMER_NO = p_customer.customer_no;

        IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO STTM_CUST_PERSONAL (
            CUSTOMER_NO,
            CUSTOMER_PREFIX,
            CUSTOMER_PREFIX1,
            CUSTOMER_PREFIX2,
            FIRST_NAME,
            MIDDLE_NAME,
            LAST_NAME,
            SEX,
            DATE_OF_BIRTH,
            PLACE_OF_BIRTH,
            BIRTH_COUNTRY,
            PASSPORT_NO,
            PPT_ISS_DATE,
            PPT_EXP_DATE,
            P_NATIONAL_ID,
            RESIDENT_STATUS,
            US_RES_STATUS,
            VST_US_PREV,
            MOTHER_MAIDEN_NAME,
            MARITAL_STATUS,
            SPOUSE_NAME,
            SPOUSE_EMP_STATUS,
            DEPENDENT_CHILDREN,
            DEPENDENT_OTHERS,
            EDUCATIONAL_STATUS,
            ACCOMODATION,
            LEGAL_GUARDIAN,
            MINOR,
            CUST_COMM_MODE,
            E_MAIL,
            MOBILE_NUMBER,
            MOB_ISD_NO,
            TELEPHONE,
            TEL_ISD_NO,
            HOME_TEL_NO,
            HOME_TEL_ISD,
            FAX,
            FAX_ISD_NO,
            D_ADDRESS1,
            D_ADDRESS2,
            D_ADDRESS3,
            D_ADDRESS4,
            D_COUNTRY,
            D_PINCODE,
            P_ADDRESS1,
            P_ADDRESS2,
            P_ADDRESS3,
            P_ADDRESS4,
            P_COUNTRY,
            P_PINCODE, RECORD_STAT, AUTH_STAT, MOD_NO,
            MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP, ONCE_AUTH
        ) VALUES (
            p_customer.customer_no,
            p_personal.customer_prefix,
            p_personal.customer_prefix1,
            p_personal.customer_prefix2,
            p_personal.first_name,
            p_personal.middle_name,
            p_personal.last_name,
            UPPER(p_personal.sex),
            p_personal.date_of_birth,
            p_personal.place_of_birth,
            p_personal.birth_country,
            p_personal.passport_no,
            p_personal.ppt_iss_date,
            p_personal.ppt_exp_date,
            p_personal.p_national_id,
            p_personal.resident_status,
            p_personal.us_res_status,
            p_personal.vst_us_prev,
            p_personal.mother_maiden_name,
            p_personal.marital_status,
            p_personal.spouse_name,
            p_personal.spouse_emp_status,
            p_personal.dependent_children,
            p_personal.dependent_others,
            p_personal.educational_status,
            p_personal.accomodation,
            p_personal.legal_guardian,
            NVL(UPPER(p_personal.minor), 'N'),
            p_personal.cust_comm_mode,
            p_personal.e_mail,
            p_personal.mobile_number,
            p_personal.mob_isd_no,
            p_personal.telephone,
            p_personal.tel_isd_no,
            p_personal.home_tel_no,
            p_personal.home_tel_isd,
            p_personal.fax,
            p_personal.fax_isd_no,
            p_personal.d_address1,
            p_personal.d_address2,
            p_personal.d_address3,
            p_personal.d_address4,
            p_personal.d_country,
            p_personal.d_pincode,
            p_personal.p_address1,
            p_personal.p_address2,
            p_personal.p_address3,
            p_personal.p_address4,
            p_personal.p_country,
            p_personal.p_pincode, 'O', 'U', 1,
            l_maker_id, SYSDATE, NULL, NULL, 'N'
        );
        END IF;
        ELSE
            IF p_corporate.incorporation_date IS NOT NULL
               AND p_corporate.incorporation_date > TRUNC(SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20035, 'Incorporation date cannot be in the future.');
            END IF;
        UPDATE STTM_CUST_CORPORATE
        SET COMPANY_TYPE = p_corporate.company_type,
            BUSINESS_NATURE = p_corporate.business_nature,
            GROUP_NAME = p_corporate.group_name,
            EMPLOYEE_NUMBER = p_corporate.employee_number,
            ANNUAL_TURNOVER = p_corporate.annual_turnover,
            PARENT_CMPNY_COUNTRY = p_corporate.parent_cmpny_country,
            OTHR_COMPANY_TYPE = p_corporate.othr_company_type,
            INCORPORATION_NO = p_corporate.incorporation_no,
            INCORPORATION_DATE = p_corporate.incorporation_date,
            INCORPORATION_COUNTRY = p_corporate.incorporation_country,
            REGISTERED_ADDRESS1 = p_corporate.registered_address1,
            REGISTERED_ADDRESS2 = p_corporate.registered_address2,
            REGISTERED_ADDRESS3 = p_corporate.registered_address3,
            REGISTERED_ADDRESS4 = p_corporate.registered_address4,
            KYC_COMMENTS = p_corporate.kyc_comments,
            KYC_NXT_REVIEW_DATE = p_corporate.kyc_nxt_review_date,
            RECORD_STAT = 'O',
            AUTH_STAT = 'U',
            MOD_NO = MOD_NO + 1,
            MAKER_ID = l_maker_id,
            MAKER_DT_STAMP = SYSDATE,
            CHECKER_ID = NULL,
            CHECKER_DT_STAMP = NULL,
            ONCE_AUTH = 'N'
        WHERE CUSTOMER_NO = p_customer.customer_no;

        IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO STTM_CUST_CORPORATE (
            CUSTOMER_NO,
            COMPANY_TYPE,
            BUSINESS_NATURE,
            GROUP_NAME,
            EMPLOYEE_NUMBER,
            ANNUAL_TURNOVER,
            PARENT_CMPNY_COUNTRY,
            OTHR_COMPANY_TYPE,
            INCORPORATION_NO,
            INCORPORATION_DATE,
            INCORPORATION_COUNTRY,
            REGISTERED_ADDRESS1,
            REGISTERED_ADDRESS2,
            REGISTERED_ADDRESS3,
            REGISTERED_ADDRESS4,
            KYC_COMMENTS,
            KYC_NXT_REVIEW_DATE, RECORD_STAT, AUTH_STAT, MOD_NO,
            MAKER_ID, MAKER_DT_STAMP, CHECKER_ID, CHECKER_DT_STAMP, ONCE_AUTH
        ) VALUES (
            p_customer.customer_no,
            p_corporate.company_type,
            p_corporate.business_nature,
            p_corporate.group_name,
            p_corporate.employee_number,
            p_corporate.annual_turnover,
            p_corporate.parent_cmpny_country,
            p_corporate.othr_company_type,
            p_corporate.incorporation_no,
            p_corporate.incorporation_date,
            p_corporate.incorporation_country,
            p_corporate.registered_address1,
            p_corporate.registered_address2,
            p_corporate.registered_address3,
            p_corporate.registered_address4,
            p_corporate.kyc_comments,
            p_corporate.kyc_nxt_review_date, 'O', 'U', 1,
            l_maker_id, SYSDATE, NULL, NULL, 'N'
        );
        END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_stdcifd_amend;
            RAISE;
    END amend_pending_customer;

    PROCEDURE authorize_child(
        p_table_name IN VARCHAR2,
        p_customer_no IN VARCHAR2,
        p_checker_id IN VARCHAR2
    ) IS
    BEGIN
        -- p_table_name is supplied only through the hard-coded allowlist below.
        EXECUTE IMMEDIATE
            'UPDATE ' || DBMS_ASSERT.SIMPLE_SQL_NAME(p_table_name) ||
            ' SET AUTH_STAT = ''A'', CHECKER_ID = :1, CHECKER_DT_STAMP = SYSDATE, ONCE_AUTH = ''Y'' ' ||
            ' WHERE CUSTOMER_NO = :2 AND AUTH_STAT = ''U'''
            USING p_checker_id, p_customer_no;
    END authorize_child;

    PROCEDURE authorize_customer(
        p_customer_no IN STTM_CUSTOMER.CUSTOMER_NO%TYPE,
        p_checker_id IN VARCHAR2
    ) IS
        l_checker_id VARCHAR2(12) := UPPER(TRIM(p_checker_id));
        l_maker_id STTM_CUSTOMER.MAKER_ID%TYPE;
        l_auth_stat STTM_CUSTOMER.AUTH_STAT%TYPE;
        l_record_stat STTM_CUSTOMER.RECORD_STAT%TYPE;
        l_customer_type STTM_CUSTOMER.CUSTOMER_TYPE%TYPE;
        l_count PLS_INTEGER;
    BEGIN
        SAVEPOINT sp_stdcifd_auth;
        IF TRIM(p_customer_no) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20040, 'Customer number is required.');
        END IF;
        IF l_checker_id IS NULL OR LENGTH(l_checker_id) > 12 THEN
            RAISE_APPLICATION_ERROR(-20041, 'Checker ID is required and cannot exceed 12 characters.');
        END IF;

        BEGIN
            SELECT MAKER_ID, AUTH_STAT, RECORD_STAT, CUSTOMER_TYPE
              INTO l_maker_id, l_auth_stat, l_record_stat, l_customer_type
              FROM STTM_CUSTOMER
             WHERE CUSTOMER_NO = p_customer_no
             FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20042, 'Customer does not exist.');
        END;

        IF l_auth_stat <> 'U' THEN
            RAISE_APPLICATION_ERROR(-20043, 'Customer is not pending authorization.');
        END IF;
        IF l_record_stat <> 'O' THEN
            RAISE_APPLICATION_ERROR(-20044, 'Only open customer records can be authorized.');
        END IF;
        IF UPPER(l_maker_id) = l_checker_id THEN
            RAISE_APPLICATION_ERROR(-20045, 'Maker and checker must be different users.');
        END IF;

        IF l_customer_type = 'I' THEN
            SELECT COUNT(*) INTO l_count FROM STTM_CUST_PERSONAL
             WHERE CUSTOMER_NO = p_customer_no AND AUTH_STAT = 'U';
            IF l_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20046, 'Pending personal details are missing.');
            END IF;
        ELSIF l_customer_type = 'C' THEN
            SELECT COUNT(*) INTO l_count FROM STTM_CUST_CORPORATE
             WHERE CUSTOMER_NO = p_customer_no AND AUTH_STAT = 'U';
            IF l_count = 0 THEN
                RAISE_APPLICATION_ERROR(-20047, 'Pending corporate details are missing.');
            END IF;
        END IF;

        UPDATE STTM_CUSTOMER
           SET AUTH_STAT = 'A',
               CHECKER_ID = l_checker_id,
               CHECKER_DT_STAMP = SYSDATE,
               ONCE_AUTH = 'Y'
         WHERE CUSTOMER_NO = p_customer_no
           AND AUTH_STAT = 'U';

        authorize_child('STTM_CUST_PERSONAL', p_customer_no, l_checker_id);
        authorize_child('STTM_CUST_CORPORATE', p_customer_no, l_checker_id);
        authorize_child('STTM_CUST_PROFESSIONAL', p_customer_no, l_checker_id);
        authorize_child('STTM_CUST_RELATION', p_customer_no, l_checker_id);
        authorize_child('STTM_CUST_SHAREHOLDER', p_customer_no, l_checker_id);
        authorize_child('STTM_CORP_DIRECTORS', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_RETAIL', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_CORPORATE', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_CORP_KEYPERSONS', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_SHARE_HOLDERS', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_TXN_DETAILS', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_TXN_PRODUCTS', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_FINANCIAL', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_CORP_CLIENT', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_CORP_SUPPLIER', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_MGMNT_DTL', p_customer_no, l_checker_id);
        authorize_child('STTM_KYC_COMPL_AUDIT_DTL', p_customer_no, l_checker_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_stdcifd_auth;
            RAISE;
    END authorize_customer;

    PROCEDURE query_customer(
        p_customer_no IN STTM_CUSTOMER.CUSTOMER_NO%TYPE,
        p_master_cursor OUT SYS_REFCURSOR,
        p_personal_cursor OUT SYS_REFCURSOR,
        p_corporate_cursor OUT SYS_REFCURSOR
    ) IS
        l_count PLS_INTEGER;
    BEGIN
        IF TRIM(p_customer_no) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20050, 'Customer number is required.');
        END IF;
        SELECT COUNT(*) INTO l_count FROM STTM_CUSTOMER
         WHERE CUSTOMER_NO = p_customer_no;
        IF l_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'Customer not found: ' || p_customer_no);
        END IF;

        OPEN p_master_cursor FOR
            SELECT * FROM STTM_CUSTOMER WHERE CUSTOMER_NO = p_customer_no;
        OPEN p_personal_cursor FOR
            SELECT * FROM STTM_CUST_PERSONAL WHERE CUSTOMER_NO = p_customer_no;
        OPEN p_corporate_cursor FOR
            SELECT * FROM STTM_CUST_CORPORATE WHERE CUSTOMER_NO = p_customer_no;
    END query_customer;

END STPKS_STDCIFD_MAIN;
/

-- Compilation diagnostics
SHOW ERRORS PACKAGE STPKS_STDCIFD_MAIN;
SHOW ERRORS PACKAGE BODY STPKS_STDCIFD_MAIN;

-- Verify package status after compilation
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME = 'STPKS_STDCIFD_MAIN'
 ORDER BY OBJECT_TYPE;
