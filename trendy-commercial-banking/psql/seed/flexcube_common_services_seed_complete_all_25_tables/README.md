# FLEXCUBE Common Services — Complete Seed Data

## What's included

`flexcube_common_services_seed_complete_all_25_tables.sql` is a rerunnable Oracle SQL*Plus / SQL Developer script for the companion `flexcube_common_services_documented_reference_ddl.sql` schema subset. It now has explicit seed operations for **all 25 tables**:

- Country, currency, bank, branch, and branch business date
- Local, currency, and clearing holidays
- Currency denomination master and details
- Currency-pair setup and currency-pair working table
- Exchange-rate type and rate-master rows
- Historical rates, the upload/staging table, and currency/cash/accrual positions
- Transaction codes and monthly tax cycles

## Business data and provenance

- Country and currency identifiers use standard ISO codes. The ISO 4217 standard describes internationally recognized currency codes: https://www.iso.org/iso-4217-currency-codes.html
- Cambodia's 2026 holiday entries follow the National Bank of Cambodia's public-holiday calendar: https://www.nbc.gov.kh/english./news_and_events/official_holiday.php
- The sample USD/KHR official reference rate and AUD/CNY/EUR buying/selling values are a **historical NBC snapshot dated 11 May 2026**, not the current FX rate. The NBC's published page for that date showed 4,012 KHR/USD; AUD buying/selling 2,899/2,928; CNY 590/596; EUR 4,713/4,760: https://www.nbc.gov.kh/english/index.php/publications/cbs/download_files/booklet/economic_research/download_files/economic_research/off_ex_rate_eng/oer_27-04-26.pdf (the NBC page also indexed the 11 May 2026 rate snapshot).
- USD holidays use the Federal Reserve Financial Services 2026 holiday schedule: https://www.frbservices.org/about/holiday-schedules/
- THB holidays use Bank of Thailand's 2026 Financial Institutions Holiday schedule: https://www.bot.or.th/en/financial-institutions-holiday.html
- `ABCB` / “ABC Bank” and the three branch records are **synthetic** training configuration—not a representation of a real licensed bank's operational setup. Transaction codes, denomination setup, and tax-cycle IDs are also training configuration.
- Opening currency/cash/accrual positions are intentionally zeroed for the lab; they are not real balances.

## Important accuracy note

The companion DDL is a **documented-reference training reconstruction using FLEXCUBE object names**, not a vendor-exact export of your licensed FLEXCUBE release. Holiday bitmaps and upload status values can vary by release and implementation. The `CYTA_RATES` examples are staging records and leave `STATUS` and `INT_AUTH_STAT` as `NULL` rather than guessing your release's code values.

## Run instructions

1. Create the matching Common Services DDL in a clean, isolated Oracle training schema first.
2. Open the SQL file in SQL Developer and run with **F5 (Run Script)**, or execute it from SQL*Plus/SQLcl.
3. Review the row-count report at the end. The `MERGE` statements insert only missing keys; they do not update records that already exist.
4. Do not run this script against a production or bank-owned FLEXCUBE schema.

The script ends with `COMMIT` and a row-count report for each of the 25 tables.
