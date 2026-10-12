-- ============================================================================
-- FLEXCUBE COMMON SERVICES / COMMON CORE - DOCUMENTED-REFERENCE DDL
-- ============================================================================
-- Purpose:
--   Executable CREATE TABLE reference using FLEXCUBE object names and field
--   names published in publicly available data-model documents.
--
-- CRITICAL ACCURACY / RELEASE NOTICE:
--   This is NOT Oracle's complete licensed FLEXCUBE Universal Banking 14.1 DDL.
--   The columns below are a documented subset/reconstruction based on public
--   FLEXCUBE Core 11.3 data-model material and Oracle-published data-model
--   references. Column sets, constraints, and lengths can differ by release,
--   patch level, country pack, and implementation customizations.
--
--   Only published primary keys and foreign-key relationships that were
--   documented in the source references are added. We deliberately do not
--   invent missing field definitions or foreign keys to omitted modules.
--
-- Use only in a CLEAN, ISOLATED training schema (not your existing CB_LAB if
-- you already ran flexcube_common_services_training.sql). Existing tables from
-- that older training script use incompatible reconstructed columns and will
-- cause ORA-00955 name conflicts. This script contains NO DROP statements and
-- inserts NO data.
--
-- Public references used to build this reference subset:
--   * FLEXCUBE Core 11.3 Data Model (publicly available transcription):
--     https://www.scribd.com/document/445568501/idoc-pub-data-model-flexcube-data-model-pdf
--   * Oracle FLEXCUBE SMS Data Model (includes CYTM_CCY_DEFN, STTM_BANK,
--     STTM_BRANCH, and STTM_DATES field names):
--     https://docs.oracle.com/cd/E86909_02/PDF/Data%20Model/FCIS%20SMS.pdf
--   * Oracle FLEXCUBE Core/GL database practices and setup documentation.
--
-- Suggested run mode: SQL Developer > open script > F5 (Run Script).
-- ============================================================================

SET DEFINE OFF
SET SERVEROUTPUT ON

PROMPT ======================================================================
PROMPT 1. COUNTRY AND CURRENCY MASTER DATA
PROMPT ======================================================================

-- STTM_COUNTRY: primary key and columns from public FLEXCUBE Core data model.
CREATE TABLE STTM_COUNTRY (
    COUNTRY_CODE          VARCHAR2(3) NOT NULL,
    DESCRIPTION           VARCHAR2(105),
    AUTH_STAT             CHAR(1),
    RECORD_STAT           CHAR(1),
    MOD_NO                NUMBER(4),
    CHECKER_DT_STAMP      DATE,
    ONCE_AUTH             CHAR(1),
    MAKER_ID              VARCHAR2(12),
    MAKER_DT_STAMP        DATE,
    CHECKER_ID            VARCHAR2(12),
    ALT_COUNTRY_CODE      VARCHAR2(10),
    BLACKLISTED           VARCHAR2(1),
    OVERALL_LIMIT         NUMBER(24,3),
    LIMIT_CCY             VARCHAR2(3),
    IBAN_CHECK_REQD       CHAR(1),
    INTRA_EUROPEAN        VARCHAR2(1),
    CLR_CODE_BIC          VARCHAR2(1),
    CLEARING_NETWORK      VARCHAR2(6),
    ISO_NUM_COUNTRY_CODE  VARCHAR2(3),
    CONSTRAINT PK_STTM_COUNTRY PRIMARY KEY (COUNTRY_CODE)
);

-- CYTM_CCY_DEFN: public Oracle-published field subset. Some fields such as
-- POSITION_GL refer to GL data; those cross-module FKs are omitted here.
CREATE TABLE CYTM_CCY_DEFN (
    CCY_CODE               VARCHAR2(3) NOT NULL,
    CCY_NAME               VARCHAR2(35),
    COUNTRY                VARCHAR2(3),
    CCY_DECIMALS           NUMBER(2),
    CCY_ROUND_RULE          CHAR(1),
    CCY_ROUND_UNIT          NUMBER(7,3),
    CCY_FORMAT_MASK         CHAR(1),
    CCY_SPOT_DAYS           NUMBER(3),
    CCY_INT_METHOD          NUMBER(1),
    RECORD_STAT             CHAR(1),
    ONCE_AUTH               CHAR(1),
    AUTH_STAT               CHAR(1),
    MOD_NO                  NUMBER(4),
    MAKER_ID                VARCHAR2(12),
    MAKER_DT_STAMP          DATE,
    CHECKER_ID              VARCHAR2(12),
    CHECKER_DT_STAMP        DATE,
    POSITION_GL             VARCHAR2(9),
    POSITION_EQVGL          VARCHAR2(9),
    CCY_EUR_TYPE             CHAR(1),
    CCY_TOL_LIMIT            NUMBER(7,5),
    SETTLEMENT_MSG_DAYS      NUMBER(3),
    INDEX_FLAG               VARCHAR2(1),
    INDEX_BASE_CCY           VARCHAR2(3),
    CUT_OFF_HR               NUMBER(2),
    CUT_OFF_MIN              NUMBER(2),
    ALT_CCY_CODE             VARCHAR2(10),
    EUR_CONVERSION_REQD      CHAR(1),
    CUT_OFF_DAYS             NUMBER(2),
    CR_AUTO_EX_RATE_LMT      NUMBER(22,3),
    DR_AUTO_EX_RATE_LMT      NUMBER(22,3),
    CCY_TYPE                 VARCHAR2(3),
    GEN_103P                 VARCHAR2(1),
    CLS_CCY                  VARCHAR2(1),
    FX_NETTING_DAYS          NUMBER(3),
    CONSTRAINT PK_CYTM_CCY_DEFN PRIMARY KEY (CCY_CODE)
);

PROMPT ======================================================================
PROMPT 2. BANK, BRANCH, AND BRANCH BUSINESS DATE
PROMPT ======================================================================

-- STTM_BANK: fields are the published subset listed in the Oracle FLEXCUBE
-- SMS data model. Some releases include additional columns.
CREATE TABLE STTM_BANK (
    AUTO_GEN_CIF                       CHAR(1),
    INTERFACE_ID                       VARCHAR2(105),
    SPL_FILES_PRG_DAYS                 NUMBER(3),
    CIF_MASK                           VARCHAR2(9),
    BANK_CODE                          VARCHAR2(4) NOT NULL,
    BANK_NAME                          VARCHAR2(105),
    HO_BRANCH                          VARCHAR2(3),
    DISCOUNT_CCY                       VARCHAR2(3),
    REPORTING_CURRENCY                 VARCHAR2(3),
    HO_CURRENCY                        VARCHAR2(3),
    IB_ACCOUNT_SCHEME                  VARCHAR2(6),
    CUSTOMER_ACC_MASK                  VARCHAR2(20),
    GL_MASK                            VARCHAR2(9),
    EX_RATE_COPY                       CHAR(1),
    RECORD_STAT                        CHAR(1),
    AUTH_STAT                          CHAR(1),
    MOD_NO                             NUMBER(4),
    MAKER_ID                           VARCHAR2(12),
    MAKER_DT_STAMP                     DATE,
    CHECKER_ID                         VARCHAR2(12),
    CHECKER_DT_STAMP                   DATE,
    ONCE_AUTH                          CHAR(1),
    ONLINE_GL_UPDATE                   CHAR(1),
    YEAR_END_PNL_TRNCODE               VARCHAR2(3),
    YEAR_END_PNL_GL                    VARCHAR2(9),
    DW_AC_NO                           VARCHAR2(105),
    DW_AC_NO_WIDTH                     NUMBER(22),
    FLG_POSITION_AC                    CHAR(1),
    GL_TAB_PRG_DAYS                    NUMBER(3),
    BANK_LCY                           VARCHAR2(3),
    CHECKSUM_ALGORITHM                 VARCHAR2(30),
    CHQ_NO_CHK_DGT                     VARCHAR2(5),
    CHQ_NUMBERING                      VARCHAR2(1),
    UNIQUE_CHEQUE_NO                   VARCHAR2(1),
    SPREAD_APPLICATION                 CHAR(1),
    DAILY_MIS_REFINANCE                VARCHAR2(1),
    AUTO_GENERATE_BATCH                VARCHAR2(1),
    FL_BR_RATE_PROP                    CHAR(1),
    INTERBRANCH_ENTITY                 VARCHAR2(2),
    ROUTING_MASK                       VARCHAR2(27),
    CLG_BANK_CD                        VARCHAR2(9),
    AUTO_GEN_CCY_MISMATCH_ENTRIES      VARCHAR2(1),
    AUTO_GEN_VD_MISMATCH_ENTRIES       VARCHAR2(1),
    CCY_MISMATCH_ACC                   VARCHAR2(9),
    VDATE_MISMATCH_ACC                 VARCHAR2(9),
    CCY_MISMATCH_CONT_ACC              VARCHAR2(9),
    VDATE_MISMATCH_CONT_ACC            VARCHAR2(9),
    LEAD_DAYS                          NUMBER(2),
    UNIQUE_LODGMENT_NO                 VARCHAR2(1),
    TRS_SORT_CODE                      VARCHAR2(20),
    TRS_ACC_NO                         VARCHAR2(20),
    TRS_SUSPENCE_ACC                   VARCHAR2(20),
    TRS_PC_PROD_CATEGORY               VARCHAR2(4),
    LIMITS_HISTORY_REQUIRED            VARCHAR2(1),
    USER_BATCH_RESTRICTION             VARCHAR2(1),
    BRANCH_WISE_LIMITS                 CHAR(1),
    PROPAGATE_CIF                      VARCHAR2(1),
    PROPAGATE_CUST_ADDR                VARCHAR2(1),
    PROPAGATE_BIC                      VARCHAR2(1),
    CIF_MASK_MAINT                     VARCHAR2(1),
    PAIRWISE_POS_HANDOFF               VARCHAR2(1),
    SSO_INSTALLED                      VARCHAR2(1),
    ALW_INV_TRACK                      VARCHAR2(1),
    EXTERNAL_BANK_CODE                 NUMBER(5),
    TL_EXP_DAY                         NUMBER(2),
    AC_RESTR_APPLY                     VARCHAR2(1),
    MUDARABAH_GL_BALANCE_TYPE          VARCHAR2(1),
    FUND_IB_ACC_SCHEME                 VARCHAR2(6),
    FUND_IB_ENTITY                     VARCHAR2(2),
    AUTO_ACCOUNT_CLOSURE               VARCHAR2(1),
    LIMIT_TRACK_CIF_CORP               VARCHAR2(1),
    LIMIT_TRACK_CIF_BANK               VARCHAR2(1),
    LIMIT_TRACK_CIF_INDL               VARCHAR2(1),
    DRAWER_CHECK_RET_COUNT             NUMBER(4),
    REUSE_CIF_NO                       CHAR(1),
    REUSE_ACC_NO                       CHAR(1),
    CONSTRAINT PK_STTM_BANK PRIMARY KEY (BANK_CODE)
);

-- STTM_BRANCH: publicly documented fields. The documented primary key is
-- BRANCH_CODE. No additional FK is guessed here beyond published constraints.
CREATE TABLE STTM_BRANCH (
    BRANCH_CODE                VARCHAR2(3) NOT NULL,
    BRANCH_NAME                VARCHAR2(105),
    BRANCH_ADDR1               VARCHAR2(105),
    BRANCH_ADDR2               VARCHAR2(105),
    BRANCH_ADDR3               VARCHAR2(105),
    PARENT_BRANCH              VARCHAR2(3),
    REGIONAL_OFFICE            VARCHAR2(3),
    BANK_CODE                  VARCHAR2(4),
    HOST_NAME                  VARCHAR2(105),
    WALKIN_CUSTOMER            VARCHAR2(9),
    NETTING_SUSPENSE_GL        VARCHAR2(9),
    CONTINGENT_SUSPENSE_GLSL   VARCHAR2(9),
    CURRENT_CYCLE              VARCHAR2(9),
    CURRENT_PERIOD             VARCHAR2(3),
    SWIFT_ADDR                 VARCHAR2(12),
    TELEX_ADDR                 VARCHAR2(14),
    END_OF_INPUT               CHAR(1),
    REP_HISTORY_PERIOD         NUMBER(3),
    SUSPENSE_GLSL              VARCHAR2(9),
    GENERATE                   CHAR(1),
    TIME_LEVEL                 NUMBER(1),
    RECORD_STAT                CHAR(1),
    AUTH_STAT                  CHAR(1),
    MOD_NO                     NUMBER(4),
    MAKER_ID                   VARCHAR2(12),
    MAKER_DT_STAMP             DATE,
    CHECKER_ID                 VARCHAR2(12),
    CHECKER_DT_STAMP           DATE,
    ONCE_AUTH                  CHAR(1),
    SUSPENSE_GL_FCY            VARCHAR2(9),
    CONT_SUSPENSE_GL_FCY       VARCHAR2(9),
    CONSTRAINT PK_STTM_BRANCH PRIMARY KEY (BRANCH_CODE)
);

-- STTM_DATES: exact published key/field names; FK to STTM_BRANCH is documented.
CREATE TABLE STTM_DATES (
    BRANCH_CODE       VARCHAR2(3) NOT NULL,
    TODAY             DATE,
    PREV_WORKING_DAY  DATE,
    NEXT_WORKING_DAY  DATE,
    RECORD_STAT       CHAR(1),
    AUTH_STAT         CHAR(1),
    MOD_NO            NUMBER(4),
    MAKER_ID          VARCHAR2(12),
    MAKER_DT_STAMP    DATE,
    CHECKER_ID        VARCHAR2(12),
    CHECKER_DT_STAMP  DATE,
    ONCE_AUTH         CHAR(1),
    CONSTRAINT PK_STTM_DATES PRIMARY KEY (BRANCH_CODE),
    CONSTRAINT FK_STTM_DATES_BRANCH FOREIGN KEY (BRANCH_CODE)
        REFERENCES STTM_BRANCH (BRANCH_CODE)
);

PROMPT ======================================================================
PROMPT 3. LOCAL, CURRENCY, AND CLEARING HOLIDAY CALENDARS
PROMPT ======================================================================

CREATE TABLE STTM_LCL_HOL_MASTER (
    AUTH_STAT        CHAR(1),
    BRANCH_CODE      VARCHAR2(3) NOT NULL,
    YEAR             NUMBER(4) NOT NULL,
    MOD_NO           NUMBER(4),
    RECORD_STAT      CHAR(1),
    WEEKLY_HOLIDAYS  VARCHAR2(7),
    CHECKER_DT_STAMP DATE,
    CHECKER_ID       VARCHAR2(12),
    MAKER_DT_STAMP   DATE,
    MAKER_ID         VARCHAR2(12),
    ONCE_AUTH        CHAR(1),
    UNEXP_HOL        VARCHAR2(1),
    CONSTRAINT PK_STTM_LCL_HOL_MASTER PRIMARY KEY (BRANCH_CODE, YEAR),
    CONSTRAINT FK_STTM_LCL_HM_BRANCH FOREIGN KEY (BRANCH_CODE)
        REFERENCES STTM_BRANCH (BRANCH_CODE)
);

CREATE TABLE STTM_LCL_HOLIDAY (
    BRANCH_CODE  VARCHAR2(3) NOT NULL,
    YEAR         NUMBER(4) NOT NULL,
    MONTH        NUMBER(2) NOT NULL,
    HOLIDAY_LIST VARCHAR2(31),
    CONSTRAINT PK_STTM_LCL_HOLIDAY PRIMARY KEY (BRANCH_CODE, YEAR, MONTH),
    CONSTRAINT FK_STTM_LCL_HOLIDAY_MASTER FOREIGN KEY (BRANCH_CODE, YEAR)
        REFERENCES STTM_LCL_HOL_MASTER (BRANCH_CODE, YEAR)
);

CREATE TABLE STTM_CCY_HOL_MASTER (
    CCY              VARCHAR2(3) NOT NULL,
    YEAR             NUMBER(4) NOT NULL,
    MAKER_ID         VARCHAR2(12),
    ONCE_AUTH        CHAR(1),
    AUTH_STAT        CHAR(1),
    MOD_NO           NUMBER(4),
    RECORD_STAT      CHAR(1),
    MAKER_DT_STAMP   DATE,
    WEEKLY_HOLIDAYS  VARCHAR2(7),
    CHECKER_DT_STAMP DATE,
    CHECKER_ID       VARCHAR2(12),
    CONSTRAINT PK_STTM_CCY_HOL_MASTER PRIMARY KEY (CCY, YEAR)
);

CREATE TABLE STTM_CCY_HOLIDAY (
    CCY          VARCHAR2(3) NOT NULL,
    YEAR         NUMBER(4) NOT NULL,
    MONTH        NUMBER(2) NOT NULL,
    HOLIDAY_LIST VARCHAR2(31),
    CONSTRAINT PK_STTM_CCY_HOLIDAY PRIMARY KEY (CCY, YEAR, MONTH),
    CONSTRAINT FK_STTM_CCY_HOLIDAY_MASTER FOREIGN KEY (CCY, YEAR)
        REFERENCES STTM_CCY_HOL_MASTER (CCY, YEAR)
);

CREATE TABLE STTM_CLG_DEFN (
    CLEARING_HOUSE             VARCHAR2(10) NOT NULL,
    CLEARING_HOUSE_DESCRIPTION VARCHAR2(105),
    RECORD_STAT                VARCHAR2(1),
    AUTH_STAT                  VARCHAR2(1),
    ONCE_AUTH                  VARCHAR2(1),
    MOD_NO                     NUMBER(4),
    MAKER_ID                   VARCHAR2(12),
    MAKER_DT_STAMP             DATE,
    CHECKER_ID                 VARCHAR2(12),
    CHECKER_DT_STAMP           DATE,
    SWIFT_CODE                 VARCHAR2(4),
    CONSTRAINT PK_STTM_CLG_DEFN PRIMARY KEY (CLEARING_HOUSE)
);

CREATE TABLE STTM_CLG_HOL_MASTER (
    ONCE_AUTH      CHAR(1),
    MAKER_ID       VARCHAR2(12),
    MAKER_DT_STAMP DATE,
    CHECKER_ID     VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    RECORD_STAT    CHAR(1),
    MOD_NO         NUMBER(4),
    AUTH_STAT      CHAR(1),
    YEAR           NUMBER(4) NOT NULL,
    CLEARING_HOUSE VARCHAR2(3) NOT NULL,
    WEEKLY_HOLIDAYS VARCHAR2(7),
    UNEXP_HOL      VARCHAR2(1),
    CONSTRAINT PK_STTM_CLG_HOL_MASTER PRIMARY KEY (YEAR, CLEARING_HOUSE)
);

CREATE TABLE STTM_CLG_HOLIDAY (
    CLEARING_HOUSE VARCHAR2(3) NOT NULL,
    YEAR           NUMBER(4) NOT NULL,
    MONTH          NUMBER(2) NOT NULL,
    HOLIDAY_LIST   VARCHAR2(31),
    CONSTRAINT PK_STTM_CLG_HOLIDAY PRIMARY KEY (YEAR, CLEARING_HOUSE, MONTH),
    CONSTRAINT FK_STTM_CLG_HOLIDAY_MASTER FOREIGN KEY (YEAR, CLEARING_HOUSE)
        REFERENCES STTM_CLG_HOL_MASTER (YEAR, CLEARING_HOUSE)
);

PROMPT ======================================================================
PROMPT 4. CURRENCY DENOMINATIONS AND CURRENCY PAIR MAINTENANCE
PROMPT ======================================================================

CREATE TABLE CYTM_CCY_DENO_MASTER (
    CCY_CODE         VARCHAR2(3) NOT NULL,
    ONCE_AUTH        CHAR(1),
    AUTH_STAT        CHAR(1),
    RECORD_STAT      CHAR(1),
    MOD_NO           NUMBER(4),
    MAKER_ID         VARCHAR2(12),
    MAKER_DT_STAMP   DATE,
    CHECKER_ID       VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    CONSTRAINT PK_CYTM_CCY_DENO_MASTER PRIMARY KEY (CCY_CODE),
    CONSTRAINT FK_CYTM_CCY_DENO_CCY FOREIGN KEY (CCY_CODE)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

CREATE TABLE CYTM_CCY_DENO_DETAIL (
    CCY_CODE            VARCHAR2(3) NOT NULL,
    DENOMINATION_CODE   VARCHAR2(9) NOT NULL,
    DESCRIPTION         VARCHAR2(20),
    DENOMINATION_VALUE  NUMBER(22,3),
    TYPE                CHAR(1),
    SEQ_NO              NUMBER(2),
    CONSTRAINT PK_CYTM_CCY_DENO_DETAIL PRIMARY KEY
        (CCY_CODE, DENOMINATION_CODE),
    CONSTRAINT FK_CYTM_CCY_DENO_DETAIL FOREIGN KEY (CCY_CODE)
        REFERENCES CYTM_CCY_DENO_MASTER (CCY_CODE)
);

CREATE TABLE CYTM_CCY_PAIR_DEFN (
    CCY1             VARCHAR2(3) NOT NULL,
    CCY2             VARCHAR2(3) NOT NULL,
    THROUGH_CCY      VARCHAR2(3),
    QUOTATION        CHAR(1),
    NO_OF_UNITS      NUMBER(1),
    SPREAD_DEFN      CHAR(1),
    POINTS_MULTIPLIER NUMBER(5,4),
    RECORD_STAT      CHAR(1),
    ONCE_AUTH        CHAR(1),
    AUTH_STAT        CHAR(1),
    MOD_NO           NUMBER(4),
    MAKER_ID         VARCHAR2(12),
    MAKER_DT_STAMP   DATE,
    CHECKER_ID       VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    CONSTRAINT PK_CYTM_CCY_PAIR_DEFN PRIMARY KEY (CCY1, CCY2),
    CONSTRAINT FK_CYTM_CCY_PAIR_CCY1 FOREIGN KEY (CCY1)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTM_CCY_PAIR_CCY2 FOREIGN KEY (CCY2)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTM_CCY_PAIR_THROUGH FOREIGN KEY (THROUGH_CCY)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

-- CYTB_CCY_PAIR is a working table for the pair definition (Core 11.3 model).
CREATE TABLE CYTB_CCY_PAIR (
    CCY1              VARCHAR2(3) NOT NULL,
    CCY2              VARCHAR2(3) NOT NULL,
    THROUGH_CCY       VARCHAR2(3),
    QUOTATION         CHAR(1),
    NO_OF_UNITS       NUMBER(1),
    SPREAD_DEFN       CHAR(1),
    POINTS_MULTIPLIER NUMBER(10,5),
    AUTH_STAT         CHAR(1),
    OFFSET_RECORD     CHAR(1),
    CONSTRAINT PK_CYTB_CCY_PAIR PRIMARY KEY (CCY1, CCY2)
);

PROMPT ======================================================================
PROMPT 5. EXCHANGE RATE TYPES, RATE MAINTENANCE, HISTORY, AND POSITIONS
PROMPT ======================================================================

CREATE TABLE CYTM_RATE_TYPE (
    CCY_RATE_TYPE      VARCHAR2(8) NOT NULL,
    CCY_RATE_TYPE_DESC VARCHAR2(105),
    RECORD_STAT        CHAR(1),
    AUTH_STAT          CHAR(1),
    MOD_NO             NUMBER(4),
    MAKER_ID           VARCHAR2(12),
    MAKER_DT_STAMP     DATE,
    CHECKER_ID         VARCHAR2(12),
    CHECKER_DT_STAMP   DATE,
    ONCE_AUTH          CHAR(1),
    CONSTRAINT PK_CYTM_RATE_TYPE PRIMARY KEY (CCY_RATE_TYPE)
);

CREATE TABLE CYTM_RATES_MASTER (
    BRANCH_CODE      VARCHAR2(3) NOT NULL,
    CCY1             VARCHAR2(3) NOT NULL,
    CCY2             VARCHAR2(3) NOT NULL,
    AUTH_STAT        CHAR(1),
    MAKER_ID         VARCHAR2(12),
    MAKER_DT_STAMP   DATE,
    CHECKER_ID       VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    MOD_NO           NUMBER(4),
    RECORD_STAT      VARCHAR2(1),
    ONCE_AUTH        CHAR(1),
    CONSTRAINT PK_CYTM_RATES_MASTER PRIMARY KEY (BRANCH_CODE, CCY1, CCY2),
    CONSTRAINT FK_CYTM_RATES_MASTER_BRANCH FOREIGN KEY (BRANCH_CODE)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTM_RATES_MASTER_CCY1 FOREIGN KEY (CCY1)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTM_RATES_MASTER_CCY2 FOREIGN KEY (CCY2)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

CREATE TABLE CYTB_RATES_HISTORY (
    BRANCH_CODE  VARCHAR2(3) NOT NULL,
    CCY1         VARCHAR2(3) NOT NULL,
    CCY2         VARCHAR2(3) NOT NULL,
    RATE_TYPE    VARCHAR2(8) NOT NULL,
    RATE_DT_STAMP DATE NOT NULL,
    MID_RATE     NUMBER(24,12),
    BUY_RATE     NUMBER(24,12),
    SALE_RATE    NUMBER(24,12),
    MULT_FACTOR  NUMBER(14,7),
    POWER_FACTOR NUMBER(10,5),
    RATE_FLAG    CHAR(1),
    RATE_DATE    DATE,
    RATE_SERIAL  NUMBER(4),
    CONSTRAINT PK_CYTB_RATES_HISTORY PRIMARY KEY
        (BRANCH_CODE, CCY1, CCY2, RATE_TYPE, RATE_DT_STAMP),
    CONSTRAINT FK_CYTB_RATES_HIST_BRANCH FOREIGN KEY (BRANCH_CODE)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTB_RATES_HIST_CCY1 FOREIGN KEY (CCY1)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTB_RATES_HIST_CCY2 FOREIGN KEY (CCY2)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTB_RATES_HIST_TYPE FOREIGN KEY (RATE_TYPE)
        REFERENCES CYTM_RATE_TYPE (CCY_RATE_TYPE)
);

CREATE TABLE CYTB_CCY_POSITION (
    BRANCH         VARCHAR2(3) NOT NULL,
    CCY            VARCHAR2(3) NOT NULL,
    REAL_CCY_POSN  NUMBER(24,3),
    CONT_CCY_POSN  NUMBER(24,3),
    REAL_LCY_POSN  NUMBER(24,3),
    CONT_LCY_POSN  NUMBER(24,3),
    CONSTRAINT PK_CYTB_CCY_POSITION PRIMARY KEY (BRANCH, CCY),
    CONSTRAINT FK_CYTB_CCY_POS_BRANCH FOREIGN KEY (BRANCH)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTB_CCY_POS_CCY FOREIGN KEY (CCY)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

CREATE TABLE CYTB_CASH_POSITION (
    BRN           VARCHAR2(3) NOT NULL,
    CCY           VARCHAR2(3) NOT NULL,
    CASH_POSITION NUMBER(22,3),
    CONSTRAINT PK_CYTB_CASH_POSITION PRIMARY KEY (BRN, CCY),
    CONSTRAINT FK_CYTB_CASH_POS_BRANCH FOREIGN KEY (BRN)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTB_CASH_POS_CCY FOREIGN KEY (CCY)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

CREATE TABLE CYTB_ACCR_POSITION (
    BRN           VARCHAR2(3) NOT NULL,
    CCY           VARCHAR2(3) NOT NULL,
    ACCR_POSITION NUMBER(22,3),
    CONSTRAINT PK_CYTB_ACCR_POSITION PRIMARY KEY (BRN, CCY),
    CONSTRAINT FK_CYTB_ACCR_POS_BRANCH FOREIGN KEY (BRN)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTB_ACCR_POS_CCY FOREIGN KEY (CCY)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

-- CYTA_RATES: upload/extract staging structure; all included field names/types
-- are from the public Core data model. Sequence/business processing is omitted.
CREATE TABLE CYTA_RATES (
    ID              NUMBER(20) NOT NULL,
    BRANCH_CODE     VARCHAR2(3),
    CCY1            VARCHAR2(3),
    CCY2            VARCHAR2(3),
    RATE_TYPE       VARCHAR2(8),
    MID_RATE        NUMBER(24,12),
    BUY_SPREAD      NUMBER,
    SALE_SPREAD     NUMBER,
    BUY_RATE        NUMBER(24,12),
    SALE_RATE       NUMBER(24,12),
    INT_AUTH_STAT   CHAR(1),
    RATE_SERIAL     NUMBER(4),
    USER_REFNO      VARCHAR2(50),
    SOURCE          VARCHAR2(50),
    FILE_NAME       VARCHAR2(50),
    UPLOAD_DATE     DATE,
    STATUS          VARCHAR2(1),
    ERROR           VARCHAR2(50),
    ERROR_PARAM     VARCHAR2(255),
    ARCHIVE_DATE    DATE,
    CONSTRAINT PK_CYTA_RATES PRIMARY KEY (ID),
    CONSTRAINT FK_CYTA_RATES_BRANCH FOREIGN KEY (BRANCH_CODE)
        REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_CYTA_RATES_CCY1 FOREIGN KEY (CCY1)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_CYTA_RATES_CCY2 FOREIGN KEY (CCY2)
        REFERENCES CYTM_CCY_DEFN (CCY_CODE)
);

PROMPT ======================================================================
PROMPT 6. TRANSACTION CODES AND TAX CYCLE REFERENCE DATA
PROMPT ======================================================================

CREATE TABLE STTM_TRN_CODE (
    TRN_CODE                 VARCHAR2(3) NOT NULL,
    TRN_DESC                 VARCHAR2(105),
    TRN_SWIFT_CODE           VARCHAR2(3),
    AVL_INFO                 CHAR(1),
    CHEQUE_MANDATORY         CHAR(1),
    IC_TXN_COUNT             CHAR(1),
    IC_TOVER_INCLUSION       CHAR(1),
    CONSIDER_FOR_ACTIVITY    CHAR(1),
    MIS_HEAD                 VARCHAR2(9),
    MOD_NO                   NUMBER(4),
    MAKER_DT_STAMP           DATE,
    RECORD_STAT              CHAR(1),
    AUTH_STAT                CHAR(1),
    ONCE_AUTH                CHAR(1),
    MAKER_ID                 VARCHAR2(12),
    NEW_VAL_DATE             CHAR(1),
    AVL_DAYS                 NUMBER(2),
    CHECKER_DT_STAMP         DATE,
    CHECKER_ID               VARCHAR2(12),
    IC_TXN_COUNT_NUMBER      NUMBER(3),
    CONSTRAINT PK_STTM_TRN_CODE PRIMARY KEY (TRN_CODE)
);

CREATE TABLE STTM_TAX_CYCLE (
    TAX_CYCLE       VARCHAR2(9) NOT NULL,
    DESCRIPTION     VARCHAR2(105),
    TC_START_DATE   DATE,
    TC_END_DATE     DATE,
    RECORD_STAT     VARCHAR2(1),
    AUTH_STAT       VARCHAR2(1),
    MOD_NO          NUMBER(4),
    MAKER_ID        VARCHAR2(12),
    MAKER_DT_STAMP  DATE,
    CHECKER_ID      VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    ONCE_AUTH       VARCHAR2(1),
    CONSTRAINT PK_STTM_TAX_CYCLE PRIMARY KEY (TAX_CYCLE)
);

PROMPT ======================================================================
PROMPT DDL REFERENCE SUBSET COMPLETE
PROMPT ======================================================================
PROMPT This script creates documented-reference tables only; it adds no sample data.
PROMPT Review compilation errors before proceeding.

-- Objects known by FLEXCUBE name but deliberately not given CREATE TABLE DDL in
-- this file because a complete, release-matched column definition was not
-- established from the public sources used here:
--   CYTM_RATES (current rate table; verify exact version-specific shape)
--   STTM_SECTORS
--   STTM_FLOAT_DAYS_MASTER / STTM_FLOAT_DAYS_DETAIL (also depend on CSTM_PRODUCT
--       and STTM_SECTORS parent objects)
--   STTM_UNEXP_HOL / STTM_UNEXP_HOL_DET
--   STTM_FIN_CYCLE / STTM_PERIOD_CODES (consult release-matched Core DDL)
--   STTM charge-maintenance objects (do not assume STTM_CHARGE_CD_MASTER exists)
--
-- Check object creation in SQL Developer after execution:
SELECT TABLE_NAME
FROM USER_TABLES
WHERE TABLE_NAME IN (
    'STTM_COUNTRY', 'CYTM_CCY_DEFN', 'STTM_BANK', 'STTM_BRANCH',
    'STTM_DATES', 'STTM_LCL_HOL_MASTER', 'STTM_LCL_HOLIDAY',
    'STTM_CCY_HOL_MASTER', 'STTM_CCY_HOLIDAY', 'STTM_CLG_DEFN',
    'STTM_CLG_HOL_MASTER', 'STTM_CLG_HOLIDAY', 'CYTM_CCY_DENO_MASTER',
    'CYTM_CCY_DENO_DETAIL', 'CYTM_CCY_PAIR_DEFN', 'CYTB_CCY_PAIR',
    'CYTM_RATE_TYPE', 'CYTM_RATES_MASTER', 'CYTB_RATES_HISTORY',
    'CYTB_CCY_POSITION', 'CYTB_CASH_POSITION', 'CYTB_ACCR_POSITION',
    'CYTA_RATES', 'STTM_TRN_CODE', 'STTM_TAX_CYCLE'
)
ORDER BY TABLE_NAME;
