# Quantium Chips Case (Decision-Support Portfolio)

## Purpose
Produce a strategic, data-backed recommendation for the Category Manager (Julia) by analysing chip purchasing trends and customer segments.  
Focus: decision-support insight (not pure data science), with clear metrics, assumptions, and commercial implications.

## Data inputs (raw)
Location: `data_raw/`
- `Purchase_behaviour.csv`  
  Customer attributes: `LYLTY_CARD_NBR`, `LIFESTAGE`, `PREMIUM_CUSTOMER`
- `Transaction_data.xlsx`  
  Transaction-level records (e.g., date, product, quantity, sales) for chip purchases

## Reproducible workflow
### Step 1 — Load & persist
Script: `R/01_load_raw_data.R`  
Outputs (saved for fast reload): `data_processed/`
- `purchase_behaviour.rds`
- `transaction_data.rds`

### Step 2 — Data quality checks (next)
Planned script: `R/02_data_quality_checks.R`
- Schema and type checks
- Missing values and duplicates
- Key integrity checks (`LYLTY_CARD_NBR`, transaction date/product fields)
- Outliers and basic sanity summaries

### Step 3 — Feature engineering & segmentation (planned)
- Pack size + brand extraction from product name
- Customer-level metrics:
  - total spend, total units, transactions, avg basket, avg price per unit
  - segment comparisons by `LIFESTAGE` × `PREMIUM_CUSTOMER`

### Step 4 — Recommendation (planned)
Translate insights into actions:
- range/pack-size optimisation
- targeted promotions by segment
- store/category performance levers supported by evidence

## Notes
- Raw data is never modified; all outputs are derived and saved under `data_processed/`.
- Aim: demonstrate transferable performance analysis and decision-support discipline (public sector analogue: service performance metrics, segmentation of user cohorts, and intervention evaluation).
