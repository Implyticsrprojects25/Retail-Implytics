# 01_load_raw_data.R
# Purpose: Load raw Quantium datasets

library(readr)
library(readxl)

purchase_behaviour <- read_csv(
  "02_quantium_chips_case/data_raw/Purchase_behaviour.csv",
  show_col_types = FALSE
)

transaction_data <- read_excel(
  "02_quantium_chips_case/data_raw/Transaction_data.xlsx"
)

dim(purchase_behaviour)
dim(transaction_data)
