# 02_data_quality_checks.R
# Purpose: Basic quality checks for Quantium datasets

library(readr)
library(readxl)
library(dplyr)

# ---- Load (prefer .rds if already created) ----
pb_rds <- "02_quantium_chips_case/data_processed/purchase_behaviour.rds"
tx_rds <- "02_quantium_chips_case/data_processed/transaction_data.rds"

if (file.exists(pb_rds) && file.exists(tx_rds)) {
  purchase_behaviour <- readRDS(pb_rds)
  transaction_data   <- readRDS(tx_rds)
} else {
  purchase_behaviour <- read_csv(
    "02_quantium_chips_case/data_raw/Purchase_behaviour.csv",
    show_col_types = FALSE
  )
  transaction_data <- read_excel("02_quantium_chips_case/data_raw/Transaction_data.xlsx")
}

# ---- 1) Shape + structure ----
cat("\n--- DIMENSIONS ---\n")
cat("purchase_behaviour:", paste(dim(purchase_behaviour), collapse = " x "), "\n")
cat("transaction_data:  ", paste(dim(transaction_data), collapse = " x "), "\n")

cat("\n--- COLUMN NAMES ---\n")
print(names(purchase_behaviour))
print(names(transaction_data))

cat("\n--- GLIMPSE ---\n")
print(dplyr::glimpse(purchase_behaviour))
print(dplyr::glimpse(transaction_data))

# ---- 2) Missing values ----
cat("\n--- MISSING VALUES (count per column) ---\n")
pb_na <- sapply(purchase_behaviour, \(x) sum(is.na(x)))
tx_na <- sapply(transaction_data,   \(x) sum(is.na(x)))
print(pb_na)
print(tx_na)

# ---- 3) Duplicates ----
cat("\n--- DUPLICATES ---\n")

cat("purchase_behaviour duplicate LYLTY_CARD_NBR: ",
    sum(duplicated(purchase_behaviour$LYLTY_CARD_NBR)), "\n")

tx_dups_n <- sum(duplicated(transaction_data))
cat("transaction_data fully duplicated rows (before): ", tx_dups_n, "\n")

if (tx_dups_n > 0) {
  transaction_data <- transaction_data %>% distinct()
}

tx_dups_n_after <- sum(duplicated(transaction_data))
cat("transaction_data fully duplicated rows (after):  ", tx_dups_n_after, "\n")

# ---- 4) Key integrity: LYLTY_CARD_NBR ----
cat("\n--- KEY INTEGRITY (LYLTY_CARD_NBR) ---\n")
cat("Unique cards in purchase_behaviour: ",
    n_distinct(purchase_behaviour$LYLTY_CARD_NBR), "\n")
cat("Unique cards in transaction_data:   ",
    n_distinct(transaction_data$LYLTY_CARD_NBR), "\n")

cards_missing_in_pb <- setdiff(
  unique(transaction_data$LYLTY_CARD_NBR),
  unique(purchase_behaviour$LYLTY_CARD_NBR)
)
cat("Cards in transactions but not in purchase_behaviour: ",
    length(cards_missing_in_pb), "\n")

# ---- 5) Basic sanity summaries ----
cat("\n--- BASIC SANITY SUMMARIES ---\n")
if ("TOT_SALES" %in% names(transaction_data)) print(summary(transaction_data$TOT_SALES))
if ("PROD_QTY"  %in% names(transaction_data)) print(summary(transaction_data$PROD_QTY))

cat("\nDone: Data quality checks completed.\n")
