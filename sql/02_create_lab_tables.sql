-- Run as CB_LAB only after 00_create_cb_lab_user.sql has succeeded.
-- This is a tiny smoke-test schema, not the full banking project schema.

CREATE TABLE lab_customer (
    customer_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_no VARCHAR2(30) NOT NULL UNIQUE,
    full_name   VARCHAR2(100) NOT NULL,
    created_at  TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL
);

CREATE TABLE lab_account (
    account_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_no     VARCHAR2(30) NOT NULL UNIQUE,
    customer_id    NUMBER NOT NULL REFERENCES lab_customer(customer_id),
    currency_code  CHAR(3) NOT NULL,
    balance        NUMBER(19,2) DEFAULT 0 NOT NULL,
    account_status VARCHAR2(10) DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT chk_lab_account_balance CHECK (balance >= 0),
    CONSTRAINT chk_lab_account_status CHECK (account_status IN ('ACTIVE', 'FROZEN', 'CLOSED'))
);

INSERT INTO lab_customer (customer_no, full_name)
VALUES ('CUST0001', 'Demo Customer One');

INSERT INTO lab_account (account_no, customer_id, currency_code, balance)
SELECT 'ACCT0001', customer_id, 'USD', 1000.00
FROM lab_customer
WHERE customer_no = 'CUST0001';

COMMIT;

SELECT c.customer_no, c.full_name, a.account_no, a.currency_code, a.balance, a.account_status
FROM lab_customer c
JOIN lab_account a ON a.customer_id = c.customer_id;
