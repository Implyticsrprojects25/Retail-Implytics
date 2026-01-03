# Public Outputs — Quantium Chips Case

These files are derived, non-sensitive summaries generated from the analysis scripts in `02_quantium_chips_case/R/`.
Raw and processed data are intentionally excluded from GitHub.

## Files

- **segment_summary.csv**
  - Segment-level KPIs by `LIFESTAGE × PREMIUM_CUSTOMER`:
  - customers, average spend, average units, average basket value, average unit price.

- **top10_segments_by_avg_spend.csv**
  - The top 10 customer segments ranked by average spend per customer.
  - Used to prioritise high-value segments for category actions.

- **step4_top3_pack_by_segment.csv**
  - For each segment, the top 3 pack sizes (grams) by sales contribution.
  - Used to inform range/facing allocation and targeted promotions.

- **step4_recommendation_lines.csv**
  - Short commercial recommendation statements per segment, linking value + pack-size preference.
  - Intended as the basis for an exec summary or slide narrative.
