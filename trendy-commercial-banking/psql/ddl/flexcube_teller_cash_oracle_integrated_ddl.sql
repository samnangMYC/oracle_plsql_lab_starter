-- ============================================================================
-- FLEXCUBE TELLER / CASH - ORACLE SQL DDL, INTEGRATED WITH PRIOR MODULE TABLES
-- Target: Oracle Database / SQL Developer (F5 Run Script)
--
-- IMPORTANT ACCURACY NOTE
-- This is an integrated, documented-reference LAB schema, not Oracle's
-- licensed FCUBS 14.1 vendor DDL. The table names below are FLEXCUBE objects
-- found in public FLEXCUBE data-model / database-practices references. Exact
-- vendor columns, partitioning, indexes, FKR constraints, and triggers vary by
-- release/patch/bank. STTB_LOCALTXN_DETAILS uses the published column subset.
-- Other transaction/batch/log columns marked RECONSTRUCTED are explicit lab
-- definitions so the relationships can be exercised in Oracle.
--
-- REQUIRES these parent tables to exist FIRST in this same schema, from the
-- earlier module scripts:
--   STTM_BRANCH (BRANCH_CODE PK)
--   CYTM_CCY_DEFN (CCY_CODE PK)
--   STTM_TRN_CODE (TRN_CODE PK)
--   GLTM_GLMASTER (GL_CODE PK)
--   STTM_CUSTOMER (CUSTOMER_NO PK)                       [for teller txn CIF FK]
--   STTM_CUST_ACCOUNT (BRANCH_CODE,CUST_AC_NO composite PK) [for account FK]
--
-- Suggested dependency order:
--   Common Services -> GL -> Customer -> Account/CASA -> THIS SCRIPT
--
-- Run in a clean / separate lab schema. Do NOT run alongside the old
-- flexcube_teller_module_training.sql because both create DETM_TIL_VLT_MASTER
-- and STTB_LOCALTXN_DETAILS. No DROP statements or production data included.
-- ============================================================================

SET DEFINE OFF;
SET SERVEROUTPUT ON;

PROMPT ======================================================================
PROMPT 0. Parent table preflight
PROMPT ======================================================================
DECLARE
  v_missing VARCHAR2(4000);
  PROCEDURE check_table(p_table VARCHAR2) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM USER_TABLES WHERE TABLE_NAME = UPPER(p_table);
    IF v_count = 0 THEN
      v_missing := v_missing || p_table || ', ';
    END IF;
  END;
BEGIN
  check_table('STTM_BRANCH');
  check_table('CYTM_CCY_DEFN');
  check_table('STTM_TRN_CODE');
  check_table('GLTM_GLMASTER');
  check_table('STTM_CUSTOMER');
  check_table('STTM_CUST_ACCOUNT');
  IF v_missing IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20001,
      'Create prerequisite module tables first: ' || RTRIM(v_missing, ', '));
  END IF;
END;
/

PROMPT ======================================================================
PROMPT 1. DETM_TIL_VLT_MASTER - till and vault master
PROMPT ======================================================================
-- BRANCH_CODE + TILL_ID are the documented parent key used by the published
-- STTB_LOCALTXN_DETAILS data model. Other descriptive fields align to the
-- previously generated lab definition and are not asserted as the complete
-- 14.1 vendor column list.
CREATE TABLE DETM_TIL_VLT_MASTER (
    BRANCH_CODE       VARCHAR2(3)   NOT NULL,
    TILL_ID           VARCHAR2(32)  NOT NULL,
    TILL_TYPE         VARCHAR2(10)  DEFAULT 'TILL' NOT NULL,
    TILL_DESCRIPTION  VARCHAR2(100),
    CASH_GL_NO        VARCHAR2(9),
    HOME_CCY          VARCHAR2(3),
    RECORD_STAT       CHAR(1)       DEFAULT 'O' NOT NULL,
    AUTH_STAT         CHAR(1)       DEFAULT 'U' NOT NULL,
    ASSIGNED_USER     VARCHAR2(20),
    ENABLED_FLAG      CHAR(1)       DEFAULT 'Y' NOT NULL,
    MAKER_ID          VARCHAR2(20),
    MAKER_STAMP       DATE          DEFAULT SYSDATE,
    CHECKER_ID        VARCHAR2(20),
    CHECKER_STAMP     DATE,
    CONSTRAINT PK_DETM_TIL_VLT_MASTER PRIMARY KEY (BRANCH_CODE, TILL_ID),
    CONSTRAINT FK_DETM_TILVLT_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_DETM_TILVLT_CCY FOREIGN KEY (HOME_CCY)
      REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_DETM_TILVLT_GL FOREIGN KEY (CASH_GL_NO)
      REFERENCES GLTM_GLMASTER (GL_CODE),
    CONSTRAINT CK_DETM_TIL_TYPE CHECK (TILL_TYPE IN ('TILL','VAULT')),
    CONSTRAINT CK_DETM_TIL_REC CHECK (RECORD_STAT IN ('O','C')),
    CONSTRAINT CK_DETM_TIL_AUTH CHECK (AUTH_STAT IN ('A','U')),
    CONSTRAINT CK_DETM_TIL_ENABLE CHECK (ENABLED_FLAG IN ('Y','N'))
);

CREATE INDEX IX_DETM_TILVLT_CCY ON DETM_TIL_VLT_MASTER (HOME_CCY);
CREATE INDEX IX_DETM_TILVLT_GL ON DETM_TIL_VLT_MASTER (CASH_GL_NO);
COMMENT ON TABLE DETM_TIL_VLT_MASTER IS
  'FLEXCUBE till/vault master object name; lab subset with links to Common Services and GL.';

PROMPT ======================================================================
PROMPT 2. STTB_LOCALTXN_DETAILS - open teller till operation details
PROMPT ======================================================================
-- Column subset from a publicly available FLEXCUBE data-model reference.
-- Its published relationships are TXNCCY -> CYTM_CCY_DEFN, BRN -> STTM_BRANCH,
-- and (BRANCHCODE,TILID) -> DETM_TIL_VLT_MASTER.
CREATE TABLE STTB_LOCALTXN_DETAILS (
    XREF          VARCHAR2(20),
    BRN           VARCHAR2(3),
    TXNCCY        VARCHAR2(3),
    TXNAMT        NUMBER(22,3),
    TOTIL         VARCHAR2(32),
    NARRATIVE     VARCHAR2(255),
    MAKERID       VARCHAR2(20),
    MAKERSTAMP    DATE,
    CHECKERID     VARCHAR2(20),
    CHECKERSTAMP  DATE,
    AUTHSTAT      VARCHAR2(1),
    CONTSTAT      VARCHAR2(1),
    MODNO         VARCHAR2(1),
    RECORDSTAT    VARCHAR2(1),
    ONCEAUTH      VARCHAR2(1),
    TILID         VARCHAR2(32),
    ELIGIBLE      VARCHAR2(20),
    ASSIGNTO      VARCHAR2(20),
    ROLE          VARCHAR2(20),
    FUNCTIONID    VARCHAR2(4),
    LOCKEDBY      VARCHAR2(20),
    TXNDATE       DATE,
    BRANCHCODE    VARCHAR2(3),
    USERID        VARCHAR2(20),
    XREF_SE       VARCHAR2(20),
    CONSTRAINT FK_STTB_LTXN_BRN FOREIGN KEY (BRN)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_STTB_LTXN_CCY FOREIGN KEY (TXNCCY)
      REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_STTB_LTXN_TILL FOREIGN KEY (BRANCHCODE, TILID)
      REFERENCES DETM_TIL_VLT_MASTER (BRANCH_CODE, TILL_ID)
);
CREATE INDEX IX_STTB_LTXN_XREF ON STTB_LOCALTXN_DETAILS (XREF);
CREATE INDEX IX_STTB_LTXN_TILL ON STTB_LOCALTXN_DETAILS (BRANCHCODE, TILID);
COMMENT ON TABLE STTB_LOCALTXN_DETAILS IS
  'Published FLEXCUBE object name and documented column subset for Open Teller Till.';

PROMPT ======================================================================
PROMPT 3. DETB_BATCH_MASTER - teller/data-entry batch master
PROMPT ======================================================================
-- Object name appears in Oracle FLEXCUBE database-practices references.
-- Batch payload columns below are a relational lab subset, not full vendor DDL.
CREATE TABLE DETB_BATCH_MASTER (
    BRANCH_CODE       VARCHAR2(3) NOT NULL,
    BATCH_NO          VARCHAR2(4) NOT NULL,
    FUNCTION_ID       VARCHAR2(4),
    BUSINESS_DATE     DATE,
    BATCH_STATUS      VARCHAR2(12) DEFAULT 'OPEN' NOT NULL,
    MAKER_ID          VARCHAR2(12),
    MAKER_DT_STAMP    DATE DEFAULT SYSDATE,
    CHECKER_ID        VARCHAR2(12),
    CHECKER_DT_STAMP  DATE,
    CONSTRAINT PK_DETB_BATCH_MASTER PRIMARY KEY (BRANCH_CODE, BATCH_NO),
    CONSTRAINT FK_DETB_BATCH_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT CK_DETB_BATCH_STATUS CHECK
      (BATCH_STATUS IN ('OPEN','CLOSED','PROCESSED','REJECTED'))
);
CREATE INDEX IX_DETB_BATCH_DATE ON DETB_BATCH_MASTER (BRANCH_CODE, BUSINESS_DATE);

PROMPT ======================================================================
PROMPT 4. DETB_RTL_TELLER - retail teller transaction header
PROMPT ======================================================================
-- Table name is present in Oracle FLEXCUBE database-practices material; XREF
-- and TRN_REF_NO are publicly visible index columns. Remaining columns are a
-- compatible lab representation and must be compared with your 14.1 DDL.
CREATE TABLE DETB_RTL_TELLER (
    TRN_REF_NO       VARCHAR2(16) NOT NULL,
    XREF             VARCHAR2(20) NOT NULL,
    BRANCH_CODE      VARCHAR2(3)  NOT NULL,
    BATCH_NO         VARCHAR2(4),
    TILL_ID          VARCHAR2(32),
    TRN_CODE         VARCHAR2(3),
    TRN_DT           DATE,
    VALUE_DT         DATE,
    CCY              VARCHAR2(3),
    TXN_AMOUNT       NUMBER(22,3),
    CUSTOMER_NO      VARCHAR2(9),
    ACCOUNT_BRANCH   VARCHAR2(3),
    ACCOUNT_NO       VARCHAR2(20),
    GL_CODE          VARCHAR2(9),
    USER_ID          VARCHAR2(20),
    AUTH_STAT        CHAR(1),
    RECORD_STAT      CHAR(1),
    REVERSED_FLAG    CHAR(1) DEFAULT 'N' NOT NULL,
    CONSTRAINT PK_DETB_RTL_TELLER PRIMARY KEY (BRANCH_CODE, TRN_REF_NO),
    CONSTRAINT UK_DETB_RTL_TELLER_TRNREF UNIQUE (TRN_REF_NO),
    CONSTRAINT FK_DETB_RTL_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_DETB_RTL_BATCH FOREIGN KEY (BRANCH_CODE, BATCH_NO)
      REFERENCES DETB_BATCH_MASTER (BRANCH_CODE, BATCH_NO),
    CONSTRAINT FK_DETB_RTL_TILL FOREIGN KEY (BRANCH_CODE, TILL_ID)
      REFERENCES DETM_TIL_VLT_MASTER (BRANCH_CODE, TILL_ID),
    CONSTRAINT FK_DETB_RTL_TRNCODE FOREIGN KEY (TRN_CODE)
      REFERENCES STTM_TRN_CODE (TRN_CODE),
    CONSTRAINT FK_DETB_RTL_CCY FOREIGN KEY (CCY)
      REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_DETB_RTL_CUST FOREIGN KEY (CUSTOMER_NO)
      REFERENCES STTM_CUSTOMER (CUSTOMER_NO),
    CONSTRAINT FK_DETB_RTL_ACCOUNT FOREIGN KEY (ACCOUNT_BRANCH, ACCOUNT_NO)
      REFERENCES STTM_CUST_ACCOUNT (BRANCH_CODE, CUST_AC_NO),
    CONSTRAINT FK_DETB_RTL_GL FOREIGN KEY (GL_CODE)
      REFERENCES GLTM_GLMASTER (GL_CODE),
    CONSTRAINT CK_DETB_RTL_REVERSED CHECK (REVERSED_FLAG IN ('Y','N'))
);
CREATE INDEX IX_DETB_RTL_TELLER_XREF ON DETB_RTL_TELLER (XREF);
CREATE INDEX IX_DETB_RTL_TELLER_ACCT ON DETB_RTL_TELLER (ACCOUNT_BRANCH, ACCOUNT_NO);
CREATE INDEX IX_DETB_RTL_TELLER_TILL ON DETB_RTL_TELLER (BRANCH_CODE, TILL_ID, TRN_DT);

PROMPT ======================================================================
PROMPT 5. DETB_JRNL_LOG - teller journal/accounting lines
PROMPT ======================================================================
-- FLEXCUBE object name confirmed in public database-practices references.
-- Field list is a lab subset, with relationships to prior GL/accounting masters.
CREATE TABLE DETB_JRNL_LOG (
    BRANCH_CODE      VARCHAR2(3)  NOT NULL,
    TRN_REF_NO       VARCHAR2(16) NOT NULL,
    LINE_NO          NUMBER(4)    NOT NULL,
    TRN_CODE         VARCHAR2(3),
    ACCOUNT_BRANCH   VARCHAR2(3),
    ACCOUNT_NO       VARCHAR2(20),
    GL_CODE          VARCHAR2(9),
    CCY              VARCHAR2(3),
    DR_CR            CHAR(1)      NOT NULL,
    TXN_AMOUNT       NUMBER(22,3) NOT NULL,
    NARRATIVE        VARCHAR2(255),
    POSTING_DATE     DATE,
    CONSTRAINT PK_DETB_JRNL_LOG PRIMARY KEY (BRANCH_CODE, TRN_REF_NO, LINE_NO),
    CONSTRAINT FK_DETB_JRNL_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_DETB_JRNL_TELLER FOREIGN KEY (BRANCH_CODE, TRN_REF_NO)
      REFERENCES DETB_RTL_TELLER (BRANCH_CODE, TRN_REF_NO),
    CONSTRAINT FK_DETB_JRNL_TRN_CODE FOREIGN KEY (TRN_CODE)
      REFERENCES STTM_TRN_CODE (TRN_CODE),
    CONSTRAINT FK_DETB_JRNL_CCY FOREIGN KEY (CCY)
      REFERENCES CYTM_CCY_DEFN (CCY_CODE),
    CONSTRAINT FK_DETB_JRNL_GL FOREIGN KEY (GL_CODE)
      REFERENCES GLTM_GLMASTER (GL_CODE),
    CONSTRAINT FK_DETB_JRNL_ACCOUNT FOREIGN KEY (ACCOUNT_BRANCH, ACCOUNT_NO)
      REFERENCES STTM_CUST_ACCOUNT (BRANCH_CODE, CUST_AC_NO),
    CONSTRAINT CK_DETB_JRNL_DRCR CHECK (DR_CR IN ('D','C')),
    CONSTRAINT CK_DETB_JRNL_AMT CHECK (TXN_AMOUNT >= 0)
);
CREATE INDEX IX_DETB_JRNL_TRN ON DETB_JRNL_LOG (BRANCH_CODE, TRN_REF_NO);

PROMPT ======================================================================
PROMPT 6. DETB_PCTRN - transaction processing control
PROMPT ======================================================================
-- The object name and BRANCH column are documented. Additional status fields
-- are a compact lab subset for maintaining the transaction lifecycle.
CREATE TABLE DETB_PCTRN (
    BRANCH           VARCHAR2(3)  NOT NULL,
    TRN_REF_NO        VARCHAR2(16) NOT NULL,
    XREF              VARCHAR2(20),
    FUNCTION_ID       VARCHAR2(4),
    PROCESS_STATUS    VARCHAR2(12) DEFAULT 'NEW' NOT NULL,
    MAKER_ID          VARCHAR2(20),
    MAKER_DT_STAMP    DATE DEFAULT SYSDATE,
    LAST_ERROR_CODE   VARCHAR2(30),
    LAST_ERROR_PARAM  VARCHAR2(255),
    CONSTRAINT PK_DETB_PCTRN PRIMARY KEY (BRANCH, TRN_REF_NO),
    CONSTRAINT FK_DETB_PCTRN_BRANCH FOREIGN KEY (BRANCH)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT FK_DETB_PCTRN_TELLER FOREIGN KEY (BRANCH, TRN_REF_NO)
      REFERENCES DETB_RTL_TELLER (BRANCH_CODE, TRN_REF_NO),
    CONSTRAINT CK_DETB_PCTRN_STATUS CHECK
      (PROCESS_STATUS IN ('NEW','PROCESSING','SUCCESS','ERROR','REVERSED'))
);
CREATE INDEX IX_DETB_PCTRN_XREF ON DETB_PCTRN (XREF);

PROMPT ======================================================================
PROMPT 7. FBTB_TXNLOG_MASTER - transaction log master
PROMPT ======================================================================
-- XREFID is the published identifying/index field in database-practices
-- references. Additional operational columns are a lab subset.
CREATE TABLE FBTB_TXNLOG_MASTER (
    XREFID            VARCHAR2(20) NOT NULL,
    BRANCH_CODE       VARCHAR2(3),
    FUNCTION_ID       VARCHAR2(4),
    USER_ID           VARCHAR2(20),
    LOG_DATE          DATE DEFAULT SYSDATE,
    LOG_STATUS        VARCHAR2(12),
    ERROR_CODE        VARCHAR2(30),
    ERROR_PARAM       VARCHAR2(255),
    CONSTRAINT PK_FBTB_TXNLOG_MASTER PRIMARY KEY (XREFID),
    CONSTRAINT FK_FBTB_TXNLOG_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE)
);
CREATE INDEX IDX_FBTB_TXNLOG_MASTER_BRN ON FBTB_TXNLOG_MASTER (BRANCH_CODE, LOG_DATE);

-- Published data-model notation associates STTB_LOCALTXN_DETAILS.XREF_SE
-- with FBTB_TXNLOG_MASTER. XREFID is used as the referenced lab key.
ALTER TABLE STTB_LOCALTXN_DETAILS ADD CONSTRAINT FK_STTB_LTXN_LOG
  FOREIGN KEY (XREF_SE) REFERENCES FBTB_TXNLOG_MASTER (XREFID);

PROMPT ======================================================================
PROMPT 8. FBTB_TXNLOG_DETAILS - transaction log details
PROMPT ======================================================================
-- XREFID and SEQUENCE_NO align with public index metadata. Detail payload is
-- generic because exact release-specific payload columns require the vendor DDL.
CREATE TABLE FBTB_TXNLOG_DETAILS (
    XREFID          VARCHAR2(20) NOT NULL,
    SEQUENCE_NO     NUMBER(10)   NOT NULL,
    DETAIL_TYPE     VARCHAR2(30),
    DETAIL_VALUE    VARCHAR2(2000),
    CONSTRAINT PK_FBTB_TXNLOG_DETAILS PRIMARY KEY (XREFID, SEQUENCE_NO),
    CONSTRAINT FK_FBTB_TXNLOG_DETAIL_MASTER FOREIGN KEY (XREFID)
      REFERENCES FBTB_TXNLOG_MASTER (XREFID)
);

PROMPT ======================================================================
PROMPT 9. FBTB_OVD - transaction error/override details
PROMPT ======================================================================
-- XREF + SEQ_NO are the documented object/index fields; payload columns are
-- lab-only fields pending comparison with the real installed DDL.
CREATE TABLE FBTB_OVD (
    XREF            VARCHAR2(20) NOT NULL,
    SEQ_NO          NUMBER(10)   NOT NULL,
    BRANCH_CODE     VARCHAR2(3),
    ERROR_CODE      VARCHAR2(30),
    ERROR_PARAM     VARCHAR2(255),
    RESOLVED_FLAG   CHAR(1) DEFAULT 'N' NOT NULL,
    CONSTRAINT PK_FBTB_OVD PRIMARY KEY (XREF, SEQ_NO),
    CONSTRAINT FK_FBTB_OVD_TXNLOG FOREIGN KEY (XREF)
      REFERENCES FBTB_TXNLOG_MASTER (XREFID),
    CONSTRAINT FK_FBTB_OVD_BRANCH FOREIGN KEY (BRANCH_CODE)
      REFERENCES STTM_BRANCH (BRANCH_CODE),
    CONSTRAINT CK_FBTB_OVD_RESOLVED CHECK (RESOLVED_FLAG IN ('Y','N'))
);

PROMPT ======================================================================
PROMPT 10. RELATIONSHIP CHECK - show the generated foreign-key links
PROMPT ======================================================================
SELECT c.table_name, c.constraint_name, c.r_constraint_name,
       c.status
FROM user_constraints c
WHERE c.constraint_type = 'R'
  AND c.table_name IN (
    'DETM_TIL_VLT_MASTER','STTB_LOCALTXN_DETAILS','DETB_BATCH_MASTER',
    'DETB_RTL_TELLER','DETB_JRNL_LOG','DETB_PCTRN',
    'FBTB_TXNLOG_MASTER','FBTB_TXNLOG_DETAILS','FBTB_OVD'
  )
ORDER BY c.table_name, c.constraint_name;

PROMPT ======================================================================
PROMPT End of Teller/Cash integrated Oracle lab DDL.
PROMPT Compare reconstructed columns with the installed FCUBS 14.1 data model
PROMPT and replace the lab subsets with licensed vendor DDL before production.
PROMPT ======================================================================
