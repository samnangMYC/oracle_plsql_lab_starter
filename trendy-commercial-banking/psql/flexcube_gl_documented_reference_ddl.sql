-- ============================================================================
-- FLEXCUBE GL / accounting reference DDL (publicly documented column subset)
-- ============================================================================
-- IMPORTANT
-- 1) This is an executable reference reconstruction for an isolated training
--    schema, NOT Oracle's complete proprietary FCUBS 14.1 vendor DDL.
-- 2) The ACTB_* column lists are based on the publicly available FLEXCUBE
--    Universal Banking Core 11.3 data model; GLTM_GLMASTER / GLTB_CTL columns
--    are from a publicly available Oracle FLEXCUBE data-model reference.
--    Actual definitions may vary by product/release/customization.
-- 3) This script deliberately does NOT invent columns for every GLTM_*/GLTB_*/
--    GLTW_* object in the inventory. Object names alone are not enough to
--    establish exact DDL. See the inventory comments at the end.
-- 4) Run only in a clean, isolated lab schema (e.g., CB_LAB). No DROP statements.
-- 5) Cross-module foreign keys to STTM_*, CYTM_* and CSTB_* parent tables are
--    omitted because those parent schemas are not included here.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- GL master. GLTM_GLMASTER columns based on published FLEXCUBE data model.
-- ---------------------------------------------------------------------------
CREATE TABLE GLTM_GLMASTER (
    FLG_POSITION_AC CHAR(1),
    CCY_POS_GL      CHAR(1),
    GL_CODE         VARCHAR2(9) NOT NULL,
    GL_DESC         VARCHAR2(35),
    PARENT_GL       VARCHAR2(9),
    CCY_RES         CHAR(1),
    RES_CCY         VARCHAR2(3),
    LEAF            CHAR(1),
    TYPE            CHAR(1),
    CUSTOMER        CHAR(1),
    CATEGORY        CHAR(1),
    HO_RES          CHAR(1),
    REVAL           CHAR(1),
    PROFIT_ACC      VARCHAR2(9),
    LOSS_ACC        VARCHAR2(9),
    CBANK_LINE_DR   VARCHAR2(16),
    CBANK_LINE_CR   VARCHAR2(16),
    HO_LINE_DR      VARCHAR2(16),
    HO_LINE_CR      VARCHAR2(16),
    FIRST_AUTH      CHAR(1),
    ULTI_PARENT     VARCHAR2(9),
    BLOCK           CHAR(1),
    POSTING_RES     CHAR(1),
    RECON           CHAR(1),
    RECORD_STAT     CHAR(1),
    ONCE_AUTH       CHAR(1),
    AUTH_STAT       CHAR(1),
    MOD_NO          NUMBER(4),
    MAKER_ID        VARCHAR2(12),
    MAKER_DT_STAMP  DATE,
    CHECKER_ID      VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    CONSTRAINT PK_GLTM_GLMASTER PRIMARY KEY (GL_CODE)
);


-- ---------------------------------------------------------------------------
-- GL control table: published fields BRANCH_CODE, REPORT, TID.
-- ---------------------------------------------------------------------------
CREATE TABLE GLTB_CTL (
    BRANCH_CODE VARCHAR2(3),
    REPORT      VARCHAR2(15),
    TID         VARCHAR2(4)
);

-- ---------------------------------------------------------------------------
-- Daily account balances by booking date. PK as documented in the data model.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_ACCBAL_HISTORY (
    BRANCH_CODE        VARCHAR2(3) NOT NULL,
    ACCOUNT            VARCHAR2(20) NOT NULL,
    BKG_DATE           DATE NOT NULL,
    ACY_OPENING_BAL    NUMBER(24,3),
    LCY_OPENING_BAL    NUMBER(24,3),
    ACY_CLOSING_BAL    NUMBER(24,3),
    LCY_CLOSING_BAL    NUMBER(24,3),
    ACY_DR_TUR          NUMBER(24,3),
    LCY_DR_TUR          NUMBER(24,3),
    ACY_CR_TUR          NUMBER(24,3),
    LCY_CR_TUR          NUMBER(24,3),
    ACC_CCY             VARCHAR2(3) NOT NULL,
    ACY_CLOSING_AVLBAL  NUMBER(24,3),
    ACY_CLOSING_UNCOLL  NUMBER(24,3),
    ACY_CLOSING_BLOCK   NUMBER(24,3),
    CONSTRAINT PK_ACTB_ACCBAL_HISTORY PRIMARY KEY
        (BRANCH_CODE, ACCOUNT, BKG_DATE, ACC_CCY)
);

-- ---------------------------------------------------------------------------
-- Account statistics: financial-cycle and period-to-date.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_ACCSTATS_FCTD (
    BRANCH      VARCHAR2(3) NOT NULL,
    ACCOUNT     VARCHAR2(20) NOT NULL,
    FIN_CYCLE   VARCHAR2(9) NOT NULL,
    LOW_BALANCE NUMBER(24,3),
    HIGH_BALANCE NUMBER(24,3),
    AVG_CR_BAL  NUMBER(24,3),
    AVG_DR_BAL  NUMBER(24,3),
    CR_DAYS     NUMBER(3),
    EXCESS_DAYS NUMBER(3),
    CR_TOV      NUMBER(24,3),
    DR_TOV      NUMBER(24,3),
    DR_OD_DAYS  NUMBER(3),
    OD_LIMIT    NUMBER(24,3),
    CR_GRADE    VARCHAR2(10),
    AVG_NET_BAL NUMBER(24,3),
    CONSTRAINT PK_ACTB_ACCSTATS_FCTD PRIMARY KEY (BRANCH, ACCOUNT, FIN_CYCLE)
);

CREATE TABLE ACTB_ACCSTATS_PTD (
    BRANCH      VARCHAR2(3) NOT NULL,
    ACCOUNT     VARCHAR2(20) NOT NULL,
    PERIOD_CODE VARCHAR2(3) NOT NULL,
    FIN_CYCLE   VARCHAR2(9) NOT NULL,
    LOW_BALANCE NUMBER(24,3),
    HIGH_BALANCE NUMBER(24,3),
    AVG_CR_BAL  NUMBER(24,3),
    AVG_DR_BAL  NUMBER(24,3),
    CR_DAYS     NUMBER(3),
    EXCESS_DAYS NUMBER(3),
    CR_TOV      NUMBER(24,3),
    DR_TOV      NUMBER(24,3),
    DR_OD_DAYS  NUMBER(3),
    OD_LIMIT    NUMBER(24,3),
    CR_GRADE    VARCHAR2(10),
    AVG_NET_BAL NUMBER(24,3),
    CONSTRAINT PK_ACTB_ACCSTATS_PTD PRIMARY KEY
        (BRANCH, ACCOUNT, FIN_CYCLE, PERIOD_CODE)
);

-- ---------------------------------------------------------------------------
-- ACTB_DAILY_LOG: current-day accounting entries. Column types are from a
-- publicly available FLEXCUBE Universal Banking Core data model (11.3).
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_DAILY_LOG (
    MODULE                VARCHAR2(2),
    TRN_REF_NO            VARCHAR2(16),
    EVENT_SR_NO           NUMBER,
    EVENT                 VARCHAR2(4),
    AC_ENTRY_SR_NO        NUMBER(10) NOT NULL,
    AC_BRANCH             VARCHAR2(3),
    AC_NO                 VARCHAR2(20),
    AC_CCY                VARCHAR2(3),
    DRCR_IND              CHAR(1),
    TRN_CODE              VARCHAR2(3),
    AMOUNT_TAG            VARCHAR2(35),
    FCY_AMOUNT            NUMBER(22,3),
    EXCH_RATE             NUMBER(24,12),
    LCY_AMOUNT            NUMBER(22,3),
    RELATED_CUSTOMER      VARCHAR2(9),
    RELATED_ACCOUNT       VARCHAR2(20),
    RELATED_REFERENCE     VARCHAR2(16),
    MIS_FLAG              CHAR(1),
    MIS_HEAD              VARCHAR2(9),
    TRN_DT                DATE,
    VALUE_DT              DATE,
    TXN_INIT_DATE         DATE,
    FINANCIAL_CYCLE       VARCHAR2(9),
    PERIOD_CODE           VARCHAR2(3),
    INSTRUMENT_CODE       VARCHAR2(16),
    BATCH_NO              VARCHAR2(4),
    CURR_NO               NUMBER(6),
    USER_ID               VARCHAR2(12),
    BANK_CODE             VARCHAR2(12),
    AVLDAYS               NUMBER(3),
    AVL_FLAG              CHAR(1), -- type inferred from public transcription; verify against release DDL
    BALANCE_UPD           CHAR(1),
    TYPE                  CHAR(1),
    AUTH_ID               VARCHAR2(12),
    PRINT_STAT            CHAR(1),
    AUTH_STAT             CHAR(1),
    CATEGORY              CHAR(1),
    CUST_GL               CHAR(1),
    DISTRIBUTED           CHAR(1),
    NODE                  VARCHAR2(20),
    DELETE_STAT           CHAR(1),
    ON_LINE               CHAR(1),
    UPDACT                CHAR(1),
    NODE_SR_NO            NUMBER(10),
    NETTING_IND           CHAR(1),
    IB                    CHAR(1),
    FLG_POSITION_STATUS   CHAR(1),
    GLMIS_UPDATE_FLAG     CHAR(1),
    PRODUCT_ACCRUAL       VARCHAR2(1),
    GLMIS_UPDATE_STATUS   VARCHAR2(1),
    VDBAL_UPDATE_FLAG     VARCHAR2(1),
    PRODUCT               VARCHAR2(4),
    GLMIS_VAL_UPD_FLAG    CHAR(1),
    EXTERNAL_REF_NO       VARCHAR2(35),
    PROCESSED_FLAG        CHAR(1),
    MIS_SPREAD            CHAR(1),
    CUST_GL_UPDATE        VARCHAR2(1),
    DONT_SHOWIN_STMT      CHAR(1),
    IC_BAL_INCLUSION      CHAR(1),
    AML_EXCEPTION         VARCHAR2(1),
    ORIG_PNL_GL           VARCHAR2(9),
    STMT_DT               DATE,
    ENTRY_SEQ_NO          NUMBER,
    IL_BVT_PROCESSED      VARCHAR2(1),
    CONSTRAINT PK_ACTB_DAILY_LOG PRIMARY KEY (AC_ENTRY_SR_NO)
);

-- ---------------------------------------------------------------------------
-- ACTB_DAILY_LOG_TBAL: intermediate accounting rows for EOC trial-balance checks.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_DAILY_LOG_TBAL (
    MODULE                VARCHAR2(2),
    TRN_REF_NO            VARCHAR2(16),
    EVENT_SR_NO           NUMBER,
    EVENT                 VARCHAR2(4),
    AC_ENTRY_SR_NO        NUMBER(10) NOT NULL,
    AC_BRANCH             VARCHAR2(3),
    AC_NO                 VARCHAR2(20),
    AC_CCY                VARCHAR2(3),
    DRCR_IND              CHAR(1),
    TRN_CODE              VARCHAR2(3),
    AMOUNT_TAG            VARCHAR2(20),
    FCY_AMOUNT            NUMBER(22,3),
    EXCH_RATE             NUMBER(14,7),
    LCY_AMOUNT            NUMBER(22,3),
    RELATED_CUSTOMER      VARCHAR2(9),
    RELATED_ACCOUNT       VARCHAR2(20),
    RELATED_REFERENCE     VARCHAR2(16),
    MIS_FLAG              CHAR(1),
    MIS_HEAD              VARCHAR2(9),
    TRN_DT                DATE,
    VALUE_DT              DATE,
    TXN_INIT_DATE         DATE,
    FINANCIAL_CYCLE       VARCHAR2(9),
    PERIOD_CODE           VARCHAR2(3),
    INSTRUMENT_CODE       VARCHAR2(16),
    BANK_CODE             VARCHAR2(12),
    TYPE                  CHAR(1),
    CATEGORY              CHAR(1),
    CUST_GL               CHAR(1),
    IB                    CHAR(1),
    FLG_POSITION_STATUS   CHAR(1),
    GLMIS_UPDATE_FLAG     CHAR(1),
    USER_ID               VARCHAR2(12),
    CURR_NO               NUMBER(4),
    BATCH_NO              VARCHAR2(4),
    PRINT_STAT            CHAR(1),
    PRODUCT_ACCRUAL       VARCHAR2(1),
    AUTH_ID               VARCHAR2(12),
    PRODUCT               VARCHAR2(4),
    GLMIS_VAL_UPD_FLAG    CHAR(1),
    EXTERNAL_REF_NO       VARCHAR2(35),
    DONT_SHOWIN_STMT      CHAR(1),
    IC_BAL_INCLUSION      CHAR(1),
    AML_EXCEPTION         VARCHAR2(1),
    ORIG_PNL_GL           VARCHAR2(9),
    ENTRY_SEQ_NO          NUMBER,
    CONSTRAINT PK_ACTB_DAILY_LOG_TBAL PRIMARY KEY (AC_ENTRY_SR_NO)
);

-- ---------------------------------------------------------------------------
-- ACTB_HISTORY: archived accounting entries. Publicly documented fields.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_HISTORY (
    MODULE                VARCHAR2(2),
    TRN_REF_NO            VARCHAR2(16),
    EVENT_SR_NO           NUMBER,
    EVENT                 VARCHAR2(4),
    AC_ENTRY_SR_NO        NUMBER(10) NOT NULL,
    AC_BRANCH             VARCHAR2(3),
    AC_NO                 VARCHAR2(20),
    AC_CCY                VARCHAR2(3),
    DRCR_IND              CHAR(1),
    TRN_CODE              VARCHAR2(3),
    AMOUNT_TAG            VARCHAR2(35),
    FCY_AMOUNT            NUMBER(22,3),
    EXCH_RATE             NUMBER(24,12),
    LCY_AMOUNT            NUMBER(22,3),
    RELATED_CUSTOMER      VARCHAR2(9),
    RELATED_ACCOUNT       VARCHAR2(20),
    RELATED_REFERENCE     VARCHAR2(16),
    MIS_FLAG              CHAR(1),
    MIS_HEAD              VARCHAR2(9),
    TRN_DT                DATE,
    VALUE_DT              DATE,
    TXN_INIT_DATE         DATE,
    FINANCIAL_CYCLE       VARCHAR2(9),
    PERIOD_CODE           VARCHAR2(3),
    INSTRUMENT_CODE       VARCHAR2(16),
    BANK_CODE             VARCHAR2(12),
    TYPE                  CHAR(1),
    CATEGORY              CHAR(1),
    CUST_GL               CHAR(1),
    IB                    CHAR(1),
    FLG_POSITION_STATUS   CHAR(1),
    GLMIS_UPDATE_FLAG     CHAR(1),
    USER_ID               VARCHAR2(12),
    CURR_NO               NUMBER(4),
    BATCH_NO              VARCHAR2(4),
    PRINT_STAT            CHAR(1),
    PRODUCT_ACCRUAL       VARCHAR2(1),
    AUTH_ID               VARCHAR2(12),
    PRODUCT               VARCHAR2(4),
    GLMIS_VAL_UPD_FLAG    CHAR(1),
    EXTERNAL_REF_NO       VARCHAR2(35),
    DONT_SHOWIN_STMT      CHAR(1),
    IC_BAL_INCLUSION      CHAR(1),
    AML_EXCEPTION         VARCHAR2(1),
    ORIG_PNL_GL           VARCHAR2(9),
    STMT_DT               DATE,
    ENTRY_SEQ_NO          NUMBER,
    CONSTRAINT PK_ACTB_HISTORY PRIMARY KEY (AC_ENTRY_SR_NO)
);

-- ---------------------------------------------------------------------------
-- Value-dated balances. PK documented as ACC, BRN, CCY, VAL_DT.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_VD_BAL (
    BRN         VARCHAR2(3) NOT NULL,
    ACC         VARCHAR2(20) NOT NULL,
    VAL_DT      DATE NOT NULL,
    BAL         NUMBER(24,3),
    DR_TUR      NUMBER(24,3),
    CR_TUR      NUMBER(24,3),
    CCY         VARCHAR2(3) NOT NULL,
    LCY_BAL     NUMBER(24,3),
    HAS_TOV     CHAR(1),
    IC_BAL      NUMBER(24,3),
    IC_LCY_BAL  NUMBER(24,3),
    CONSTRAINT PK_ACTB_VD_BAL PRIMARY KEY (ACC, BRN, CCY, VAL_DT)
);

-- ---------------------------------------------------------------------------
-- Miscellaneous debit/credit reconciliation tables.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_RECON_MASTER (
    BRANCH          VARCHAR2(3) NOT NULL,
    ACCOUNT         VARCHAR2(20) NOT NULL,
    CCY             VARCHAR2(3),
    RECONNO          VARCHAR2(16) NOT NULL,
    REF_NO           VARCHAR2(16),
    EVENT_SEQ_NO     NUMBER,
    AMOUNT           NUMBER(22,3),
    AMOUNT_TO_RECON  NUMBER(22,3),
    ENTRYDATE        DATE,
    STATUS           VARCHAR2(4),
    CONSTRAINT PK_ACTB_RECON_MASTER PRIMARY KEY (BRANCH, ACCOUNT, RECONNO)
);

CREATE TABLE ACTB_RECON_DETAILS (
    BRANCH       VARCHAR2(3) NOT NULL,
    ACCOUNT      VARCHAR2(20) NOT NULL,
    CCY          VARCHAR2(3) NOT NULL,
    SERNO        NUMBER(10) NOT NULL,
    RECONNO      VARCHAR2(16) NOT NULL,
    REF_NO       VARCHAR2(16),
    EVENT_SEQ_NO NUMBER,
    AMOUNT       NUMBER(22,3),
    ENTRYDATE    DATE,
    CONSTRAINT PK_ACTB_RECON_DETAILS PRIMARY KEY
        (BRANCH, ACCOUNT, CCY, RECONNO, SERNO),
    CONSTRAINT FK_ACTB_RECON_DETAILS FOREIGN KEY (BRANCH, ACCOUNT, RECONNO)
        REFERENCES ACTB_RECON_MASTER (BRANCH, ACCOUNT, RECONNO)
);

-- ---------------------------------------------------------------------------
-- Statement field configuration.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTB_STMT_COLS (
    MODULE_CODE VARCHAR2(2) NOT NULL,
    COL_NO      NUMBER(2) NOT NULL,
    PROMPT_CODE VARCHAR2(12) NOT NULL,
    CONSTRAINT PK_ACTB_STMT_COLS PRIMARY KEY (MODULE_CODE, COL_NO, PROMPT_CODE)
);

CREATE TABLE ACTB_STMT_COLS_DETAIL (
    MODULE_CODE VARCHAR2(2) NOT NULL,
    PROMPT_CODE VARCHAR2(12) NOT NULL,
    AMOUNT_TAG  VARCHAR2(25) NOT NULL,
    CONSTRAINT PK_ACTB_STMT_COLS_DETAIL PRIMARY KEY
        (MODULE_CODE, PROMPT_CODE, AMOUNT_TAG)
);

-- ---------------------------------------------------------------------------
-- Interbranch settlement setup and derived route table.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTM_IB_SETUP (
    BRANCH_1          VARCHAR2(3) NOT NULL,
    BRANCH_2          VARCHAR2(3) NOT NULL,
    DUE_TO_BRANCH2    VARCHAR2(9),
    DUE_FROM_BRANCH2  VARCHAR2(9),
    DUE_TO_BRANCH1    VARCHAR2(9),
    DUE_FROM_BRANCH1  VARCHAR2(9),
    MAKER_ID          VARCHAR2(12),
    MAKER_DT_STAMP    DATE,
    CHECKER_ID        VARCHAR2(12),
    CHECKER_DT_STAMP  DATE,
    RECORD_STAT       CHAR(1),
    AUTH_STAT         CHAR(1),
    ONCE_AUTH         CHAR(1),
    MOD_NO            NUMBER(4),
    DUE_TO_BRANCH2_MIS   VARCHAR2(27),
    DUE_FROM_BRANCH2_MIS VARCHAR2(27),
    DUE_TO_BRANCH1_MIS   VARCHAR2(27),
    DUE_FROM_BRANCH1_MIS VARCHAR2(27),
    TRANS_CCY_BRANCH1 CHAR(1),
    TRANS_CCY_BRANCH2 CHAR(1),
    FUND_ID           VARCHAR2(16),
    FUND_BRANCH       VARCHAR2(1),
    CONSTRAINT PK_ACTM_IB_SETUP PRIMARY KEY (BRANCH_1, BRANCH_2)
);

CREATE TABLE ACTB_IB_ROUTE (
    BRANCH1       VARCHAR2(3) NOT NULL,
    BRANCH2       VARCHAR2(3) NOT NULL,
    DUETOBR2      VARCHAR2(20),
    DUEFRBR2      VARCHAR2(20),
    DUETOBR1      VARCHAR2(20),
    DUEFRBR1      VARCHAR2(20),
    AUTH_STAT     CHAR(1),
    DUETOBR2_MIS  VARCHAR2(27),
    DUEFRBR2_MIS  VARCHAR2(27),
    DUETOBR1_MIS  VARCHAR2(27),
    DUEFRBR1_MIS  VARCHAR2(27),
    CCY_CODE      VARCHAR2(3) NOT NULL,
    BR_TRAN_CCY   VARCHAR2(1),
    FUND_ID       VARCHAR2(16),
    FUND_BRANCH   VARCHAR2(1) NOT NULL,
    CONSTRAINT PK_ACTB_IB_ROUTE PRIMARY KEY
        (BRANCH1, BRANCH2, CCY_CODE, FUND_BRANCH)
);

-- ---------------------------------------------------------------------------
-- Account statement format maintenance.
-- ---------------------------------------------------------------------------
CREATE TABLE ACTM_STMT_FORMAT_MASTER (
    FORMATNAME     VARCHAR2(25) NOT NULL,
    LINESPERPAGE   NUMBER(3),
    COLSPERPAGE    NUMBER(3),
    AUTH_STAT      VARCHAR2(1),
    RECORD_STAT    VARCHAR2(1),
    MOD_NO         NUMBER(4),
    MAKER_ID       VARCHAR2(12),
    MAKER_DT_STAMP DATE,
    CHECKER_ID     VARCHAR2(12),
    CHECKER_DT_STAMP DATE,
    LANG           VARCHAR2(3) NOT NULL,
    ONCE_AUTH      CHAR(1),
    CONSTRAINT PK_ACTM_STMT_FORMAT_MASTER PRIMARY KEY (FORMATNAME, LANG)
);

CREATE TABLE ACTM_STMT_FORMAT_DETAIL (
    FORMATNAME VARCHAR2(25) NOT NULL,
    TAGNAME    VARCHAR2(25),
    TAGPOS     VARCHAR2(2),
    TAGHEADING VARCHAR2(132),
    LINENUM    NUMBER(3) NOT NULL,
    COLNUM     NUMBER(3) NOT NULL,
    BOLDFONT   CHAR(1),
    JUSTIFY    CHAR(1),
    LANG       VARCHAR2(3) NOT NULL,
    CONSTRAINT PK_ACTM_STMT_FORMAT_DETAIL PRIMARY KEY
        (FORMATNAME, LANG, LINENUM, COLNUM),
    CONSTRAINT FK_ACTM_STMT_FORMAT_DETAIL FOREIGN KEY (FORMATNAME, LANG)
        REFERENCES ACTM_STMT_FORMAT_MASTER (FORMATNAME, LANG)
);

-- ---------------------------------------------------------------------------
-- Additional genuine FLEXCUBE object names found in public references.
-- They are intentionally NOT created here: complete release-matched columns
-- were not confirmed from the public references used to build this script.
-- Obtain their DDL from the matching FCUBS installation media.
-- ---------------------------------------------------------------------------
-- GLTB_GL_BAL
-- GLTB_CUST_ACCBREAKUP
-- GLTB_AVGBAL
-- GLTB_AVGBALS_FYTD
-- GLTB_AVGBALS_PTD
-- GLTB_BALINT_ERR
-- GLTB_BUDGET_BAL
-- GLTB_CBCONS
-- GLTB_CBREPORT
-- GLTB_CUBE_HANDOFF
-- GLTB_FMS_DETAILS
-- GLTB_FMS_ENTRIES
-- GLTB_FMS_HANDOFF
-- GLTB_FMS_MASTER
-- GLTB_FUNCTION_STATUS
-- GLTB_FUNCTION_STATUS_DW
-- GLTB_GLHISTORY
-- GLTB_GLRPTBAL
-- GLTB_GLRPTBAL_ACC
-- GLTB_GLSEQ
-- GLTB_GL_STMT
-- GLTB_HOCONS
-- GLTB_HOREPORT
-- GLTB_JOB_CTL
-- GLTB_MISAVGBAL
-- GLTB_MISBAL
-- GLTB_MISMATCH
-- GLTB_MISMATCH_MOV
-- GLTB_MIS_AVGBAL
-- GLTB_MIS_DELTA_VDBAL
-- GLTB_MIS_VDBAL
-- GLTB_MOVEMENT_INQUIRY_CUBE
-- GLTB_TEMP_CCY
-- GLTB_TEMP_GL
-- GLTB_TRIAL_BALANCE_LOG
-- GLTB_TXN_INQUIRY_CUBE
-- GLTEMP
-- GLTEMP_CONS
-- GLTM_BRANCH_PARAMETERS
-- GLTM_BUDGET_MAST
-- GLTM_CFLOW_DET
-- GLTM_CFLOW_MAST
-- GLTM_FMS_MAPPING
-- GLTM_GLCBLINE
-- GLTM_GLMIS_DETAIL
-- GLTM_GLMIS_MASTER
-- GLTM_GL_CLASS
-- GLTM_GL_CLASS_DTL
-- GLTM_GL_MIS_GROUP
-- GLTM_MIS_CLASS
-- GLTM_MIS_CODE
-- GLTM_MIS_CLASS_UPLOAD
-- GLTM_MIS_CODE_UPLOAD
-- GLTM_POS_DETAIL
-- GLTM_REPLINES
-- GLTM_UPLOAD_GLMASTER
-- GLTM_UPLOAD_GL_MIS_GROUP
-- GLTW_CBORDER
-- GLTW_CCYPOS
-- GLTW_CCYPOSCONS
-- GLTW_CCYPOSPAST
-- GLTW_CFLOW
-- GLTW_GL
-- GLTW_GLCONS
-- GLTW_GLORDER
-- GLTW_GLPAST
-- GLTW_GLUNC
-- GLTW_GLUNCCONS
-- GLTW_GLUNCPAST
-- GLTW_HOORDER
-- GLTW_MIS_MISMATCH
-- GLTW_ORDER
-- GLTW_PLCCY
-- GLTW_PLCCYCONS
-- GLTW_PLCCYPAST
-- GLTW_PLGL
-- GLTW_PLGLCONS

-- Optional sequence name seen in the public FLEXCUBE Core 11.3 data model.
-- Create it only if your lab requires sequence-generated AC_ENTRY_SR_NO values.
-- CREATE SEQUENCE ACSQ_ENTRY_SR_NO START WITH 1 INCREMENT BY 1 NOCACHE;

-- Quick verification after successful execution:
-- SELECT TABLE_NAME FROM USER_TABLES
--  WHERE TABLE_NAME IN ('GLTM_GLMASTER','GLTB_CTL','ACTB_DAILY_LOG',
--    'ACTB_HISTORY','ACTB_VD_BAL','ACTB_ACCBAL_HISTORY','ACTB_RECON_MASTER',
--    'ACTB_RECON_DETAILS') ORDER BY TABLE_NAME;
