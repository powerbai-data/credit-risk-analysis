# Credit Risk & Loan Portfolio Analysis

This project analyzes historical loan-level data to evaluate credit default risk across loan grades, borrower credit profiles, and loan structures. The objective is to understand portfolio risk exposure and risk–return trade-offs, and to present actionable insights via an interactive Power BI dashboard.

## Business Questions
- How does default risk vary across loan grades and loan terms?
- What is the relationship between interest rates and default rates (risk–return trade-off)?
- Which borrower segments contribute disproportionately to portfolio-level risk?

## Data
- Dataset: LendingClub loan-level data (2007–2018)
- Unit of analysis: Loan-level observations
- Notes: Raw data is stored under `data/raw/`; analysis-ready outputs can be stored under `data/processed/` (depending on file size constraints).

## Methodology
1. **Data cleaning (SQL):** standardize loan status, handle missing values, and create analysis-ready tables.
2. **Feature engineering (SQL):** derive risk flags (e.g., default indicator), term buckets, and segment attributes for reporting.
3. **Risk analysis (SQL + Power BI):** compute default rates, exposure distributions, and segment comparisons.
4. **Dashboarding (Power BI):** build interactive visuals for portfolio monitoring and drill-down.

## Dashboard Preview
![Dashboard](assets/dashboard_preview.png)

## Repository Structure
- `sql/` — SQL scripts for cleaning, feature engineering, and analysis
- `powerbi/` — Power BI report file (`.pbix`) and supporting notes
- `data/` — raw and processed data (or samples, depending on size)
- `assets/` — images used in documentation

## Tools
- MySQL
- Power BI
