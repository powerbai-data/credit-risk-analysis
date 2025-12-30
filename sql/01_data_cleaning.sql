-- Import our data

TRUNCATE TABLE accepted_raw;

SELECT *
FROM accepted_raw;

LOAD DATA LOCAL INFILE '/Users/powerbai/Desktop/Power Bai/Data Analyst Bootcamp/Portfolio Projects/Credit Risk & Portfolio Performance Dashboard/accepted_2007_to_2018Q4.csv'
INTO TABLE accepted_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Check basic info

SELECT COUNT(*) AS n_rows FROM accepted_raw;

SELECT loan_status, COUNT(*) AS n
FROM accepted_raw
GROUP BY loan_status
ORDER BY n DESC;

SELECT MIN(issue_d) AS min_issue, MAX(issue_d) AS max_issue
FROM accepted_raw;

SELECT COUNT(*) AS n_null_id
FROM accepted_raw
WHERE id IS NULL OR id = '';

SELECT column_name
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'accepted_raw'
ORDER BY ordinal_position;

SELECT COUNT(*)
FROM accepted_raw
WHERE issue_d = '';

-- Create a staging table to manipulate data

DROP TABLE IF EXISTS accepted_staging;

CREATE TABLE accepted_staging AS
SELECT
    -- key / status
    id,
    loan_status,

    -- time
    issue_d,

    -- loan structure
    loan_amnt,
    term,
    int_rate,
    installment,

    -- platform risk grades
    grade,
    sub_grade,

    -- borrower profile (dashboard slices)
    emp_length,
    home_ownership,
    annual_inc,
    verification_status,
    purpose,
    addr_state,
    application_type,
    initial_list_status,

    -- credit / utilization
    dti,
    delinq_2yrs,
    earliest_cr_line,
    inq_last_6mths,
    open_acc,
    total_acc,
    pub_rec,
    revol_bal,
    revol_util,
    mort_acc,
    pub_rec_bankruptcies,
    fico_range_low,
    fico_range_high
FROM accepted_raw;

-- Check basic info of staging table

SELECT *
FROM accepted_staging
LIMIT 50;

SELECT COUNT(*) AS n_rows FROM accepted_staging;

SELECT COUNT(*) AS n_cols
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'accepted_staging';

-- Deal with empty values

DROP TABLE IF EXISTS accepted_staging_v2;

CREATE TABLE accepted_staging_v2 AS
SELECT
    NULLIF(id,'') AS id,
    NULLIF(loan_status,'') AS loan_status,
    NULLIF(issue_d,'') AS issue_d,
    NULLIF(loan_amnt,'') AS loan_amnt,
    NULLIF(term,'') AS term,
    NULLIF(int_rate,'') AS int_rate,
    NULLIF(installment,'') AS installment,
    NULLIF(grade,'') AS grade,
    NULLIF(sub_grade,'') AS sub_grade,
    NULLIF(emp_length,'') AS emp_length,
    NULLIF(home_ownership,'') AS home_ownership,
    NULLIF(annual_inc,'') AS annual_inc,
    NULLIF(verification_status,'') AS verification_status,
    NULLIF(purpose,'') AS purpose,
    NULLIF(addr_state,'') AS addr_state,
    NULLIF(application_type,'') AS application_type,
    NULLIF(initial_list_status,'') AS initial_list_status,
    NULLIF(dti,'') AS dti,
    NULLIF(delinq_2yrs,'') AS delinq_2yrs,
    NULLIF(earliest_cr_line,'') AS earliest_cr_line,
    NULLIF(inq_last_6mths,'') AS inq_last_6mths,
    NULLIF(open_acc,'') AS open_acc,
    NULLIF(total_acc,'') AS total_acc,
    NULLIF(pub_rec,'') AS pub_rec,
    NULLIF(revol_bal,'') AS revol_bal,
    NULLIF(revol_util,'') AS revol_util,
    NULLIF(mort_acc,'') AS mort_acc,
    NULLIF(pub_rec_bankruptcies,'') AS pub_rec_bankruptcies,
    NULLIF(fico_range_low,'') AS fico_range_low,
    NULLIF(fico_range_high,'') AS fico_range_high
FROM accepted_staging;

SELECT COUNT(*) FROM accepted_staging_v2;

SELECT COUNT(*) FROM accepted_staging_v2 WHERE issue_d IS NULL;

-- Deal with datatypes(str to date)

ALTER TABLE accepted_staging_v2
ADD COLUMN issue_date DATE;

UPDATE accepted_staging_v2
SET issue_date =
  STR_TO_DATE(
    CONCAT(
      RIGHT(issue_d, 4), '-',
      CASE LEFT(issue_d, 3)
        WHEN 'Jan' THEN '01'
        WHEN 'Feb' THEN '02'
        WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04'
        WHEN 'May' THEN '05'
        WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07'
        WHEN 'Aug' THEN '08'
        WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10'
        WHEN 'Nov' THEN '11'
        WHEN 'Dec' THEN '12'
        ELSE NULL
      END,
      '-01'
    ),
    '%Y-%m-%d'
  )
WHERE issue_d IS NOT NULL;

SELECT 
  MIN(issue_date) AS min_issue_date,
  MAX(issue_date) AS max_issue_date,
  SUM(issue_date IS NULL) AS n_null_issue_date
FROM accepted_staging_v2;

ALTER TABLE accepted_staging_v2
DROP COLUMN issue_d;

-- Deal with datatypes(str to decimal)
DROP TABLE IF EXISTS accepted_staging_v3;

CREATE TABLE accepted_staging_v3 AS
SELECT
  t.*,
  CAST(REPLACE(t.int_rate, '%', '') AS DECIMAL(6,3))   AS int_rate_num,
  CAST(REPLACE(t.revol_util, '%', '') AS DECIMAL(6,3)) AS revol_util_num
FROM accepted_staging_v2 t;

SELECT
  MIN(int_rate_num) AS min_int_rate,
  MAX(int_rate_num) AS max_int_rate,
  AVG(int_rate_num) AS avg_int_rate,
  SUM(int_rate_num IS NULL) AS n_null_int_rate,
  SUM(revol_util_num IS NULL) AS n_null_revol_util
FROM accepted_staging_v3;

ALTER TABLE accepted_staging_v3
DROP COLUMN int_rate;

ALTER TABLE accepted_staging_v3
DROP COLUMN revol_util;

DROP TABLE IF EXISTS accepted_staging_v4;

CREATE TABLE accepted_staging_v4 AS
SELECT
  t.*,
  CAST(t.loan_amnt   AS DECIMAL(14,2)) AS loan_amnt_num,
  CAST(t.annual_inc  AS DECIMAL(14,2)) AS annual_inc_num,
  CAST(t.dti         AS DECIMAL(8,3))  AS dti_num
FROM accepted_staging_v3 t;

SELECT
  MIN(loan_amnt_num) AS min_loan,
  MAX(loan_amnt_num) AS max_loan,
  AVG(loan_amnt_num) AS avg_loan,

  MIN(annual_inc_num) AS min_inc,
  MAX(annual_inc_num) AS max_inc,
  AVG(annual_inc_num) AS avg_inc,

  MIN(dti_num) AS min_dti,
  MAX(dti_num) AS max_dti,
  AVG(dti_num) AS avg_dti,

  SUM(loan_amnt_num IS NULL)  AS n_null_loan,
  SUM(annual_inc_num IS NULL) AS n_null_inc,
  SUM(dti_num IS NULL)        AS n_null_dti
FROM accepted_staging_v4;

ALTER TABLE accepted_staging_v4
DROP COLUMN loan_amnt,
DROP COLUMN annual_inc,
DROP COLUMN dti;

SELECT *
FROM accepted_staging_v4;

DROP TABLE IF EXISTS accepted_staging_v5;

CREATE TABLE accepted_staging_v5 AS
SELECT
    *,
    CAST(installment AS DECIMAL(12,2)) AS installment_num,
    CAST(ROUND(CAST(NULLIF(delinq_2yrs,'')          AS DECIMAL(20,2))) AS SIGNED) AS delinq_2yrs_num,
    CAST(ROUND(CAST(NULLIF(inq_last_6mths,'')       AS DECIMAL(20,2))) AS SIGNED) AS inq_last_6mths_num,
    CAST(ROUND(CAST(NULLIF(open_acc,'')             AS DECIMAL(20,2))) AS SIGNED) AS open_acc_num,
    CAST(ROUND(CAST(NULLIF(total_acc,'')            AS DECIMAL(20,2))) AS SIGNED) AS total_acc_num,
    CAST(ROUND(CAST(NULLIF(pub_rec,'')              AS DECIMAL(20,2))) AS SIGNED) AS pub_rec_num,
    CAST(revol_bal AS DECIMAL(14,2)) AS revol_bal_num,
    CAST(ROUND(CAST(NULLIF(mort_acc,'')             AS DECIMAL(20,2))) AS SIGNED) AS mort_acc_num,
    CAST(ROUND(CAST(NULLIF(pub_rec_bankruptcies,'') AS DECIMAL(20,2))) AS SIGNED) AS pub_rec_bankruptcies_num,
    CAST(ROUND(CAST(NULLIF(fico_range_low,'')       AS DECIMAL(20,2))) AS SIGNED) AS fico_range_low_num,
    CAST(ROUND(CAST(NULLIF(fico_range_high,'')      AS DECIMAL(20,2))) AS SIGNED) AS fico_range_high_num
FROM accepted_staging_v4;

SELECT
  MIN(delinq_2yrs_num), MAX(delinq_2yrs_num),
  MIN(inq_last_6mths_num), MAX(inq_last_6mths_num),
  MIN(open_acc_num), MAX(open_acc_num),
  MIN(total_acc_num), MAX(total_acc_num)
FROM accepted_staging_v5;

SELECT
  MIN(fico_range_low_num), MAX(fico_range_low_num),
  MIN(fico_range_high_num), MAX(fico_range_high_num)
FROM accepted_staging_v5;

ALTER TABLE accepted_staging_v5
DROP COLUMN installment,
DROP COLUMN delinq_2yrs,
DROP COLUMN inq_last_6mths,
DROP COLUMN open_acc,
DROP COLUMN total_acc,
DROP COLUMN pub_rec,
DROP COLUMN revol_bal,
DROP COLUMN mort_acc,
DROP COLUMN pub_rec_bankruptcies,
DROP COLUMN fico_range_low,
DROP COLUMN fico_range_high;

-- Deal with another date

ALTER TABLE accepted_staging_v5
ADD COLUMN earliest_cr_line_date DATE;

UPDATE accepted_staging_v5
SET earliest_cr_line_date =
  STR_TO_DATE(
    CONCAT(
      RIGHT(earliest_cr_line, 4), '-',
      CASE LEFT(earliest_cr_line, 3)
        WHEN 'Jan' THEN '01'
        WHEN 'Feb' THEN '02'
        WHEN 'Mar' THEN '03'
        WHEN 'Apr' THEN '04'
        WHEN 'May' THEN '05'
        WHEN 'Jun' THEN '06'
        WHEN 'Jul' THEN '07'
        WHEN 'Aug' THEN '08'
        WHEN 'Sep' THEN '09'
        WHEN 'Oct' THEN '10'
        WHEN 'Nov' THEN '11'
        WHEN 'Dec' THEN '12'
        ELSE NULL
      END,
      '-01'
    ),
    '%Y-%m-%d'
  )
WHERE earliest_cr_line IS NOT NULL;

ALTER TABLE accepted_staging_v5
DROP COLUMN earliest_cr_line;

SELECT *
FROM accepted_staging_v5;