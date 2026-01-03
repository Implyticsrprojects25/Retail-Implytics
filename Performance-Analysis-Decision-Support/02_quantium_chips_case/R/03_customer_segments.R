# 03_feature_engineering_segmentation.R
# Purpose: Build customer-level metrics + segment comparisons for Quantium chips case

library(dplyr)
library(stringr)

# ---- Load (prefer .rds) ----
pb_rds <- "02_quantium_chips_case/data_processed/purchase_behaviour.rds"
tx_rds <- "02_quantium_chips_case/data_processed/transaction_data.rds"

stopifnot(file.exists(pb_rds), file.exists(tx_rds))

purchase_behaviour <- readRDS(pb_rds)
transaction_data   <- readRDS(tx_rds)

# ---- 0) Pack size extraction (grams) from PROD_NAME ----
# e.g., "Kettle Tortilla ... 150g" -> 150
transaction_data <- transaction_data %>%
  mutate(
    PACK_SIZE_G = as.numeric(str_extract(PROD_NAME, "\\d+(?=g)"))
  )

cat("\n--- PACK SIZE CHECK ---\n")
print(summary(transaction_data$PACK_SIZE_G))
cat("Missing pack size (NA):", sum(is.na(transaction_data$PACK_SIZE_G)), "\n")

# ---- 1) Customer-level metrics ----
customer_metrics <- transaction_data %>%
  group_by(LYLTY_CARD_NBR) %>%
  summarise(
    total_spend = sum(TOT_SALES, na.rm = TRUE),
    total_units = sum(PROD_QTY, na.rm = TRUE),
    n_transactions = n_distinct(TXN_ID),
    n_lines = n(),  # transaction lines (can be > transactions)
    avg_basket_value = total_spend / n_transactions,
    avg_unit_price = total_spend / total_units,
    avg_units_per_trip = total_units / n_transactions,
    .groups = "drop"
  )

cat("\n--- CUSTOMER METRICS (SUMMARY) ---\n")
print(summary(customer_metrics$total_spend))
print(summary(customer_metrics$n_transactions))

# ---- 2) Join customer attributes ----
cust_enriched <- customer_metrics %>%
  left_join(
    purchase_behaviour %>% select(LYLTY_CARD_NBR, LIFESTAGE, PREMIUM_CUSTOMER),
    by = "LYLTY_CARD_NBR"
  )

cat("\n--- JOIN CHECK ---\n")
cat("Rows in customer_metrics:", nrow(customer_metrics), "\n")
cat("Rows in cust_enriched:", nrow(cust_enriched), "\n")
cat("Missing LIFESTAGE:", sum(is.na(cust_enriched$LIFESTAGE)), "\n")
cat("Missing PREMIUM_CUSTOMER:", sum(is.na(cust_enriched$PREMIUM_CUSTOMER)), "\n")

# ---- 3) Segment comparisons: LIFESTAGE x PREMIUM_CUSTOMER ----
segment_summary <- cust_enriched %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER) %>%
  summarise(
    customers = n(),
    avg_total_spend = mean(total_spend, na.rm = TRUE),
    avg_units = mean(total_units, na.rm = TRUE),
    avg_transactions = mean(n_transactions, na.rm = TRUE),
    avg_basket_value = mean(avg_basket_value, na.rm = TRUE),
    avg_unit_price = mean(avg_unit_price, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_total_spend))

cat("\n--- SEGMENT SUMMARY (TOP 10 by avg_total_spend) ---\n")
print(head(segment_summary, 10))

# ---- 4) Save outputs (do NOT push to Git if you choose to keep processed private) ----
out_dir <- "02_quantium_chips_case/data_processed"
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

saveRDS(customer_metrics, file.path(out_dir, "customer_metrics.rds"))
saveRDS(cust_enriched, file.path(out_dir, "customer_enriched.rds"))
saveRDS(segment_summary, file.path(out_dir, "segment_summary.rds"))

transaction_data <- transaction_data %>%
  mutate(
    PACK_SIZE_G = as.numeric(str_extract(PROD_NAME, "\\d+(?=g)"))
  )
summary(transaction_data$PACK_SIZE_G)


customer_metrics <- transaction_data %>%
  group_by(LYLTY_CARD_NBR) %>%
  summarise(
    total_spend   = sum(TOT_SALES, na.rm = TRUE),
    total_units   = sum(PROD_QTY, na.rm = TRUE),
    transactions  = n(),
    avg_basket    = total_spend / transactions,
    avg_unit_price = total_spend / total_units,
    .groups = "drop"
  )


summary(customer_metrics$total_spend)


customer_enriched <- customer_metrics %>%
  left_join(
    purchase_behaviour,
    by = "LYLTY_CARD_NBR"
  )

sum(is.na(customer_enriched$LIFESTAGE))

segment_summary <- customer_enriched %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER) %>%
  summarise(
    customers        = n(),
    avg_total_spend  = mean(total_spend),
    avg_units        = mean(total_units),
    avg_basket       = mean(avg_basket),
    avg_unit_price   = mean(avg_unit_price),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_total_spend))
head(segment_summary, 10)



pack_pref_by_segment <- transaction_data %>%
  left_join(purchase_behaviour, by = "LYLTY_CARD_NBR") %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER, PACK_SIZE_G) %>%
  summarise(
    total_sales = sum(TOT_SALES),
    .groups = "drop"
  ) %>%
  arrange(LIFESTAGE, PREMIUM_CUSTOMER, desc(total_sales))

saveRDS(segment_summary,
        "02_quantium_chips_case/data_processed/segment_summary.rds")

saveRDS(pack_pref_by_segment,
        "02_quantium_chips_case/data_processed/pack_pref_by_segment.rds")

