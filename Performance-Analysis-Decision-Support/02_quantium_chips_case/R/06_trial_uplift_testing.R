# 06_trial_uplift_testing.R
# Purpose: Task 2 — Select controls and measure trial uplift (DiD + bootstrap CI)
# Trial stores: 77, 86, 88

library(dplyr)
library(readr)
library(ggplot2)

# -----------------------------
# 0) Parameters (edit if needed)
# -----------------------------
trial_stores <- c(77, 86, 88)

# Standard Quantium trial windows used in this case study:
# Pre-trial: Jul 2018 to Jan 2019
# Trial: Feb 2019 to Apr 2019
pre_months   <- c(201807, 201808, 201809, 201810, 201811, 201812, 201901)
trial_months <- c(201902, 201903, 201904)

# Outputs (public)
out_dir <- "02_quantium_chips_case/output_public"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# -----------------------------
# 1) Load data
# -----------------------------
qvi <- readRDS("02_quantium_chips_case/data_processed/qvi_data.rds")

# -----------------------------
# 2) Ensure YEARMONTH exists
# -----------------------------
# Some QVI datasets already have YEARMONTH. If not, attempt to derive it.
if (!("YEARMONTH" %in% names(qvi))) {
  if ("DATE" %in% names(qvi)) {
    # DATE may be yyyymmdd integer/character. Convert to Date then to YYYYMM integer.
    qvi <- qvi %>%
      mutate(
        DATE = as.character(DATE),
        YEARMONTH = as.integer(substr(DATE, 1, 6))
      )
  } else {
    stop("Cannot find YEARMONTH or DATE in qvi. Please check column names with names(qvi).")
  }
}

# -----------------------------
# 3) Build store-month metrics (pre + trial)
# -----------------------------
# We need TOT_SALES and a customer identifier for customer counts.
# In this case study, LYLTY_CARD_NBR is typically present.
if (!("TOT_SALES" %in% names(qvi))) stop("TOT_SALES column not found in qvi.")
if (!("STORE_NBR" %in% names(qvi))) stop("STORE_NBR column not found in qvi.")
if (!("LYLTY_CARD_NBR" %in% names(qvi))) stop("LYLTY_CARD_NBR column not found in qvi.")

store_month <- qvi %>%
  filter(YEARMONTH %in% c(pre_months, trial_months)) %>%
  group_by(STORE_NBR, YEARMONTH) %>%
  summarise(
    total_sales  = sum(TOT_SALES, na.rm = TRUE),
    customers    = n_distinct(LYLTY_CARD_NBR),
    transactions = n(),  # each row is a transaction line in this dataset
    avg_txn_value = total_sales / transactions,
    .groups = "drop"
  )

# Save a public-friendly metrics table (no customer IDs)
readr::write_csv(store_month, file.path(out_dir, "task2_store_month_metrics.csv"))

# -----------------------------
# 4) Select control stores
# -----------------------------
# Approach: For each trial store, find stores that are most similar in PRE period
# using standardised Euclidean distance across:
# - total_sales (monthly)
# - customers (monthly)

pre_tbl <- store_month %>%
  filter(YEARMONTH %in% pre_months)

# Helper: standardise within pre-period across all stores for fair distance
pre_stats <- pre_tbl %>%
  summarise(
    sales_mu = mean(total_sales), sales_sd = sd(total_sales),
    cust_mu  = mean(customers),   cust_sd  = sd(customers)
  )

pre_tbl_std <- pre_tbl %>%
  mutate(
    sales_z = (total_sales - pre_stats$sales_mu) / pre_stats$sales_sd,
    cust_z  = (customers   - pre_stats$cust_mu)  / pre_stats$cust_sd
  )

# Build wide vectors per store (concatenate month values) for distance
to_vector <- function(df) {
  # Order months consistently
  df <- df %>% arrange(YEARMONTH)
  c(df$sales_z, df$cust_z)
}

store_vectors <- pre_tbl_std %>%
  group_by(STORE_NBR) %>%
  group_map(~ to_vector(.x), .keep = TRUE)

store_ids <- pre_tbl_std %>%
  distinct(STORE_NBR) %>%
  arrange(STORE_NBR) %>%
  pull(STORE_NBR)

names(store_vectors) <- store_ids

candidate_stores <- setdiff(store_ids, trial_stores)

pick_control <- function(trial_store) {
  trial_vec <- store_vectors[[as.character(trial_store)]]
  # Compute distance to each candidate store
  dists <- sapply(candidate_stores, function(s) {
    vec <- store_vectors[[as.character(s)]]
    sqrt(sum((trial_vec - vec)^2, na.rm = TRUE))
  })
  best <- candidate_stores[which.min(dists)]
  tibble(trial_store = trial_store, control_store = best, distance = min(dists))
}

control_map <- bind_rows(lapply(trial_stores, pick_control))

readr::write_csv(control_map, file.path(out_dir, "task2_control_store_selection.csv"))

# -----------------------------
# 5) Trial vs Control comparison (Difference-in-Differences)
# -----------------------------
add_group <- function(df, trial_store, control_store) {
  df %>%
    filter(STORE_NBR %in% c(trial_store, control_store)) %>%
    mutate(
      group = ifelse(STORE_NBR == trial_store, "TRIAL", "CONTROL"),
      trial_store = trial_store,
      control_store = control_store
    )
}

paired_data <- bind_rows(
  lapply(seq_len(nrow(control_map)), function(i) {
    add_group(store_month, control_map$trial_store[i], control_map$control_store[i])
  })
)

summ_period <- paired_data %>%
  mutate(period = case_when(
    YEARMONTH %in% pre_months ~ "PRE",
    YEARMONTH %in% trial_months ~ "TRIAL",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(period)) %>%
  group_by(trial_store, control_store, group, period) %>%
  summarise(
    total_sales = sum(total_sales),
    customers   = sum(customers),
    transactions = sum(transactions),
    avg_txn_value = total_sales / transactions,
    .groups = "drop"
  )

did <- summ_period %>%
  select(trial_store, control_store, group, period, total_sales, customers, transactions, avg_txn_value) %>%
  tidyr::pivot_wider(names_from = c(group, period),
                     values_from = c(total_sales, customers, transactions, avg_txn_value))

# Compute DiD uplift
did_results <- did %>%
  mutate(
    sales_did = (total_sales_TRIAL_TRIAL - total_sales_TRIAL_PRE) -
                (total_sales_CONTROL_TRIAL - total_sales_CONTROL_PRE),

    cust_did  = (customers_TRIAL_TRIAL - customers_TRIAL_PRE) -
                (customers_CONTROL_TRIAL - customers_CONTROL_PRE),

    txn_did   = (transactions_TRIAL_TRIAL - transactions_TRIAL_PRE) -
                (transactions_CONTROL_TRIAL - transactions_CONTROL_PRE),

    atv_did   = (avg_txn_value_TRIAL_TRIAL - avg_txn_value_TRIAL_PRE) -
                (avg_txn_value_CONTROL_TRIAL - avg_txn_value_CONTROL_PRE),

    # % uplift vs trial PRE baseline (useful for business)
    sales_uplift_pct = sales_did / total_sales_TRIAL_PRE * 100,
    cust_uplift_pct  = cust_did  / customers_TRIAL_PRE   * 100,
    txn_uplift_pct   = txn_did   / transactions_TRIAL_PRE * 100
  )

readr::write_csv(did_results, file.path(out_dir, "task2_did_uplift_results.csv"))

# -----------------------------
# 6) Simple statistical check: bootstrap CI over trial months
# -----------------------------
# We estimate uplift month-by-month then bootstrap the mean uplift across trial months.
monthly_did <- paired_data %>%
  filter(YEARMONTH %in% c(pre_months, trial_months)) %>%
  mutate(period = ifelse(YEARMONTH %in% pre_months, "PRE", "TRIAL")) %>%
  group_by(trial_store, control_store, group, period, YEARMONTH) %>%
  summarise(
    sales = sum(total_sales),
    .groups = "drop"
  ) %>%
  tidyr::pivot_wider(names_from = c(group, period), values_from = sales) %>%
  filter(!is.na(TRIAL_TRIAL), !is.na(CONTROL_TRIAL))  # ensure trial months present

# We need PRE baseline per store pair: use average monthly PRE sales
pre_baseline <- paired_data %>%
  filter(YEARMONTH %in% pre_months) %>%
  group_by(trial_store, control_store, group) %>%
  summarise(pre_avg_sales = mean(total_sales), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = group, values_from = pre_avg_sales)

monthly_uplift <- monthly_did %>%
  left_join(pre_baseline, by = c("trial_store", "control_store")) %>%
  mutate(
    # month-level DiD uplift in sales
    sales_did_month = (TRIAL_TRIAL - TRIAL_PRE) - (CONTROL_TRIAL - CONTROL_PRE)
  )

bootstrap_ci <- function(x, n = 2000) {
  # returns mean and 95% CI
  set.seed(42)
  means <- replicate(n, mean(sample(x, replace = TRUE), na.rm = TRUE))
  tibble(
    mean = mean(x, na.rm = TRUE),
    ci_low = quantile(means, 0.025, na.rm = TRUE),
    ci_high = quantile(means, 0.975, na.rm = TRUE)
  )
}

ci_table <- monthly_uplift %>%
  group_by(trial_store, control_store) %>%
  summarise(
    n_months = n(),
    ci = list(bootstrap_ci(sales_did_month)),
    .groups = "drop"
  ) %>%
  tidyr::unnest(ci)

readr::write_csv(ci_table, file.path(out_dir, "task2_sales_uplift_bootstrap_ci.csv"))

# -----------------------------
# 7) Visuals (public PNGs)
# -----------------------------
# Sales trend plot: Trial vs Control over time for each pair
plot_tbl <- paired_data %>%
  filter(YEARMONTH %in% c(pre_months, trial_months)) %>%
  group_by(trial_store, control_store, group, YEARMONTH) %>%
  summarise(total_sales = sum(total_sales), .groups = "drop") %>%
  mutate(period = ifelse(YEARMONTH %in% pre_months, "PRE", "TRIAL"))

p <- ggplot(plot_tbl, aes(x = YEARMONTH, y = total_sales)) +
  geom_line() +
  geom_point() +
  facet_grid(trial_store ~ group, scales = "free_y") +
  labs(
    title = "Task 2: Trial vs Control — Monthly Sales Trend",
    x = "YearMonth",
    y = "Total Sales"
  )

ggsave(filename = file.path(out_dir, "task2_sales_trend_trial_vs_control.png"),
       plot = p, width = 11, height = 7, dpi = 160)

# -----------------------------
# Done
# -----------------------------
cat("\nTask 2 complete: control selection + DiD uplift + bootstrap CI + public outputs saved to output_public.\n")
cat("Next: interpret results and write recommendations for each trial store.\n")

list.files("02_quantium_chips_case/output_public", pattern = "task2", full.names = TRUE)
