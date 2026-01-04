# 01b_load_qvi_data.R
# Purpose: Load QVI data and save as RDS (processed layer)

library(readr)

qvi <- read_csv(
  "02_quantium_chips_case/data_raw/QVI_data.csv",
  show_col_types = FALSE
)

saveRDS(
  qvi,
  "02_quantium_chips_case/data_processed/qvi_data.rds"
)

rm(qvi)
gc()

cat("QVI data loaded and saved to data_processed.\n")




