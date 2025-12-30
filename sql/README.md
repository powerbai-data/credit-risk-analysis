# SQL Workflow

This directory contains the SQL pipeline used to clean the data, engineer risk-related features, and perform descriptive portfolio analysis for the Power BI dashboard.

## Execution Order

1. `01_data_cleaning.sql`  
   - Cleans and standardizes raw LendingClub loan data  
   - Handles missing values, data types, and loan status normalization  

2. `02_analysis.sql`  
   - Constructs an analysis-ready dataset with engineered risk features  
   - Performs sanity checks and descriptive portfolio-level analysis  

## Notes on Feature Engineering

Feature engineering is implemented inline within `02_analysis.sql`.  
Given the limited scope of the project and the single downstream consumer (Power BI), engineered features are not separated into a standalone feature layer.

The final output table used for reporting is:
- `accepted_analytics_final`
