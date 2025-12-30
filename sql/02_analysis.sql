/*
Purpose:
- Construct analysis-ready dataset with engineered risk features
- Perform descriptive portfolio analysis and sanity checks

Output:
- accepted_analytics_final (used as Power BI data source)
*/

SELECT *
FROM accepted_staging_v5;

DROP TABLE IF EXISTS accepted_analytics;

CREATE TABLE accepted_analytics AS
SELECT
    *,
    CASE
        WHEN loan_status IN (
            'Charged Off',
            'Default',
            'Late (31-120 days)',
            'Does not meet the credit policy. Status:Charged Off'
        ) THEN 1
        WHEN loan_status IN (
            'Fully Paid',
            'Does not meet the credit policy. Status:Fully Paid'
        ) THEN 0
        ELSE NULL
    END AS is_default,

    CASE
        WHEN loan_status IN (
            'Charged Off',
            'Default',
            'Late (31-120 days)',
            'Does not meet the credit policy. Status:Charged Off'
        ) THEN 'Bad'
        WHEN loan_status IN (
            'Fully Paid',
            'Does not meet the credit policy. Status:Fully Paid'
        ) THEN 'Good'
        ELSE 'Exclude'
    END AS loan_outcome
FROM accepted_staging_v5;

SELECT loan_outcome, COUNT(*) 
FROM accepted_analytics
GROUP BY loan_outcome;

SELECT AVG(is_default) AS default_rate
FROM accepted_analytics
WHERE is_default IS NOT NULL;

SELECT loan_status
FROM accepted_analytics
GROUP BY loan_status;

-- Another version
#CASE
  #WHEN loan_status IN ('Charged Off', 'Default',
      # 'Does not meet the credit policy. Status:Charged Off')
  #THEN 1
  #WHEN loan_status IN ('Fully Paid',
   #    'Does not meet the credit policy. Status:Fully Paid')
  #THEN 0
  #ELSE NULL
#END AS is_default_strict

-- Final analytics table
DROP TABLE IF EXISTS accepted_analytics_final;

CREATE TABLE accepted_analytics_final AS
SELECT
    *,
    CASE
      WHEN term LIKE '%36%' THEN 36
      WHEN term LIKE '%60%' THEN 60
      ELSE NULL
    END AS term_months,

    (fico_range_low_num + fico_range_high_num) / 2 AS fico_mid,

    TIMESTAMPDIFF(
      MONTH,
      earliest_cr_line_date,
      issue_date
    ) AS credit_history_months,

    loan_amnt_num / NULLIF(annual_inc_num, 0) AS loan_to_income
FROM accepted_analytics;

SELECT *
FROM accepted_analytics_final;

SELECT
  MIN(term_months), MAX(term_months),
  MIN(fico_mid), MAX(fico_mid),
  MIN(credit_history_months), MAX(credit_history_months),
  MIN(loan_to_income), MAX(loan_to_income)
FROM accepted_analytics_final;

-- Check for loan to income
SELECT
  annual_inc_num,
  loan_amnt_num,
  loan_to_income
FROM accepted_analytics_final
WHERE annual_inc_num IS NOT NULL AND annual_inc_num != 0
ORDER BY annual_inc_num ASC
LIMIT 200;

ALTER TABLE accepted_analytics_final
ADD COLUMN annual_inc_valid DECIMAL(14,2);

UPDATE accepted_analytics_final
SET annual_inc_valid =
  CASE
    WHEN annual_inc_num IS NULL THEN NULL
    WHEN annual_inc_num < 1000 THEN NULL
    ELSE annual_inc_num
  END;
  
ALTER TABLE accepted_analytics_final
ADD COLUMN loan_to_income_valid DECIMAL(18,6);

UPDATE accepted_analytics_final
SET loan_to_income_valid =
  CASE
    WHEN annual_inc_valid IS NULL THEN NULL
    ELSE loan_amnt_num / annual_inc_valid
  END;
  
ALTER TABLE accepted_analytics_final
ADD COLUMN loan_to_income_capped DECIMAL(12,6);

UPDATE accepted_analytics_final
SET loan_to_income_capped =
  CASE
    WHEN loan_to_income_valid IS NULL THEN NULL
    WHEN loan_to_income_valid > 10 THEN 10
    ELSE loan_to_income_valid
  END;

SELECT *
FROM accepted_analytics_final;

SELECT
  COUNT(*) AS n_total,
  SUM(annual_inc_num < 1000) AS n_inc_lt_1000,
  SUM(annual_inc_num < 1000) / COUNT(*) AS pct_inc_lt_1000
FROM accepted_analytics_final;

SELECT
  MIN(loan_to_income_valid), MAX(loan_to_income_valid),
  MIN(loan_to_income_capped), MAX(loan_to_income_capped),
  AVG(loan_to_income_capped) AS avg_lti_capped
FROM accepted_analytics_final;










