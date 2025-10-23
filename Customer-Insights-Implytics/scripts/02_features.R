# scripts/02_features.R
suppressPackageStartupMessages({
  library(tidyverse); library(lubridate); library(janitor); library(readr)
})

# Example: feature engineering pipeline (replace with real file names)
# tx <- read_csv('data/processed/transactions_clean.csv')

# RFM skeleton (placeholder)
# rfm <- tx %>%
#   group_by(customer_id) %>%
#   summarise(
#     recency_days   = as.integer(max(tx_date) - max(tx_date[customer_id == customer_id])),
#     frequency      = n_distinct(order_id),
#     monetary       = sum(amount, na.rm = TRUE)
#   )
# write_csv(rfm, 'data/processed/rfm.csv')
