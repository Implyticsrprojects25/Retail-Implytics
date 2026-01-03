# 04_recommendations.R
# Purpose: Translate Step 3 outputs into commercial recommendations

library(readr)
library(dplyr)
library(stringr)

# ---- Load Step 3 outputs ----
segment_summary <- readRDS("02_quantium_chips_case/data_processed/segment_summary.rds")
pack_pref <- readRDS("02_quantium_chips_case/data_processed/pack_pref_by_segment.rds")

# ---- 1) Segment prioritisation ----
top_value_segments <- segment_summary %>%
  arrange(desc(avg_total_spend)) %>%
  mutate(rank_value = row_number()) %>%
  select(rank_value, LIFESTAGE, PREMIUM_CUSTOMER, customers,
         avg_total_spend, avg_units, avg_basket, avg_unit_price)

top_volume_segments <- segment_summary %>%
  arrange(desc(avg_units)) %>%
  mutate(rank_units = row_number()) %>%
  select(rank_units, LIFESTAGE, PREMIUM_CUSTOMER, customers,
         avg_units, avg_total_spend, avg_basket, avg_unit_price)

top_price_segments <- segment_summary %>%
  arrange(desc(avg_unit_price)) %>%
  mutate(rank_price = row_number()) %>%
  select(rank_price, LIFESTAGE, PREMIUM_CUSTOMER, customers,
         avg_unit_price, avg_total_spend, avg_units, avg_basket)

# ---- 2) Pack-size winners per segment ----
pack_winners <- pack_pref %>%
  filter(!is.na(PACK_SIZE_G)) %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER) %>%
  arrange(desc(total_sales), .by_group = TRUE) %>%
  mutate(
    seg_total_sales = sum(total_sales),
    sales_share = total_sales / seg_total_sales,
    pack_rank = row_number()
  ) %>%
  ungroup()

top3_pack_by_segment <- pack_winners %>%
  filter(pack_rank <= 3) %>%
  select(LIFESTAGE, PREMIUM_CUSTOMER, PACK_SIZE_G, total_sales, sales_share, pack_rank) %>%
  arrange(LIFESTAGE, PREMIUM_CUSTOMER, pack_rank)

# ---- 3) Turn into recommendation lines (short, punchy) ----
rec_lines <- top3_pack_by_segment %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER) %>%
  summarise(
    top_packs = paste0(PACK_SIZE_G, "g (", round(sales_share*100, 1), "%)", collapse = ", "),
    .groups = "drop"
  ) %>%
  left_join(
    segment_summary %>%
      select(LIFESTAGE, PREMIUM_CUSTOMER, customers, avg_total_spend, avg_units, avg_unit_price),
    by = c("LIFESTAGE", "PREMIUM_CUSTOMER")
  ) %>%
  mutate(
    recommendation = paste0(
      "Prioritise ", LIFESTAGE, " – ", PREMIUM_CUSTOMER,
      " (customers=", customers,
      ", avg spend=", round(avg_total_spend, 2),
      "). Focus range/facings on top packs: ", top_packs,
      ". Consider targeted promo mechanics aligned to this pack profile."
    )
  ) %>%
  arrange(desc(avg_total_spend))

# ---- Save outputs for reporting ----
saveRDS(top_value_segments,
        "02_quantium_chips_case/data_processed/step4_top_value_segments.rds")
saveRDS(top_volume_segments,
        "02_quantium_chips_case/data_processed/step4_top_volume_segments.rds")
saveRDS(top_price_segments,
        "02_quantium_chips_case/data_processed/step4_top_price_segments.rds")
saveRDS(top3_pack_by_segment,
        "02_quantium_chips_case/data_processed/step4_top3_pack_by_segment.rds")
saveRDS(rec_lines,
        "02_quantium_chips_case/data_processed/step4_recommendation_lines.rds")

cat("\nStep 4 outputs saved in data_processed/.\n")
cat("Next: open step4_recommendation_lines.rds to draft final narrative.\n")


# Confirm the object exists (replace name if different)
ls()

# If you have a segment summary object:
names(segment_summary)

# Confirm avg_basket exists (if Step 4 expects it)
"avg_basket" %in% names(segment_summary)

# ---- Public outputs (safe to commit) ----
out_dir <- "02_quantium_chips_case/output_public"
dir.create(out_dir, showWarnings = FALSE)

write_csv(segment_summary,
          file.path(out_dir, "segment_summary.csv"))

write_csv(commercial_recommendations,
          file.path(out_dir, "commercial_recommendations.csv"))

seg_rds <- "02_quantium_chips_case/data_processed/segment_summary.rds"

if (file.exists(seg_rds)) {
  segment_summary <- readRDS(seg_rds)
} else {
  stop("segment_summary.rds not found. Run 03_customer_segments.R first to generate it.")
}

customer_metrics  <- readRDS("02_quantium_chips_case/data_processed/customer_metrics.rds")
customer_enriched <- readRDS("02_quantium_chips_case/data_processed/customer_enriched.rds")
pack_pref_by_segment <- readRDS("02_quantium_chips_case/data_processed/pack_pref_by_segment.rds")


seg_rds <- "02_quantium_chips_case/data_processed/segment_summary.rds"
stopifnot(file.exists(seg_rds))
segment_summary <- readRDS(seg_rds)

readr::write_csv(segment_summary, "02_quantium_chips_case/output_public/segment_summary.csv")
top10 <- segment_summary %>%
  arrange(desc(avg_total_spend)) %>%
  head(10)

readr::write_csv(top10, "02_quantium_chips_case/output_public/top10_segments_by_avg_spend.csv")
pack_pref <- readRDS("02_quantium_chips_case/data_processed/pack_pref_by_segment.rds")

top_pack <- pack_pref %>%
  filter(!is.na(PACK_SIZE_G)) %>%
  group_by(LIFESTAGE, PREMIUM_CUSTOMER) %>%
  summarise(
    top_pack_size_g = PACK_SIZE_G[which.max(total_sales)],
    top_pack_sales  = max(total_sales),
    .groups = "drop"
  )

readr::write_csv(top_pack, "02_quantium_chips_case/output_public/top_pack_size_by_segment.csv")

