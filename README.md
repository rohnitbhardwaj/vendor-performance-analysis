# Vendor Performance Analysis

Python · SQL Server · Power BI

📊 [View Dashboard Screenshots](https://github.com/rohnitbhardwaj/vendor-performance-analysis/blob/main/dashboard)

## Business Problem

Which vendors earn the most, where is purchase money concentrated, and which vendors should be protected, renegotiated or grown? The goal is to help a wine and spirits distributor decide where its buying budget earns the most.

## Dataset

Wine and spirits distributor data covering vendor purchases, sales and invoices: [N] vendors and about 321.90M in total purchase spend, with 129.72M gross profit (28.72% overall margin).

[Dataset source -- add name and link here]

## Methodology

1. **Data ingestion (Python):** Wrote a script that reads every CSV file in the source folder with pandas and loads each one into SQL Server as its own table, using SQLAlchemy and `pyodbc` with `fast_executemany` and 10,000-row chunks. Added logging that records each file ingested and the total load time.
2. **Transformation (SQL):** Cleaned and integrated the tables into one vendor summary table. Added gross profit, profit margin, unit purchase cost, stock turnover, unsold inventory value, purchase contribution and cumulative contribution. Handled zero-sales rows with `NULLIF`, and merged vendor numbers that appeared under two names using `ROW_NUMBER()`. Margin is total profit divided by total sales, never an average of row-level margins.
3. **Analysis (SQL):** Wrote one query per business question using CTEs and window functions (`SUM() OVER`, `NTILE`). Checked spend against margin, stock turnover and unsold inventory, cumulative purchase share, and unit cost across Small, Medium and Large orders. Checked whether each result was reliable, for example whether high margins came from mismatched purchases and sales.
4. **Visualization (Power BI):** One-page dashboard built on two SQL views, with a vendor slicer: spend concentration, margin by spend, unit cost by order size, unsold inventory, and the vendors worth growing.

## Key Findings

* **Overall:** Total purchase spend is 321.90M with 129.72M gross profit, a 28.72% margin.
* **Concentration:** The top 10 vendors take 65.33% of purchase spend and about 64% of gross profit. The largest, Diageo North America, alone accounts for about 16% of spend.
* **High spend, low margin:** No vendor combines both. 27 vendors had above-average spend and 18 had below-average margin, with no overlap, and the top 10 by spend all earn at or above the company margin.
* **Unsold stock:** The largest unsold values sit with the biggest vendors, whose stock turnover is about 0.97. Vendors with turnover below 0.7 hold only 0.47% of total unsold inventory.
* **Bulk buying:** Large orders cost 9.25 per unit against 27.68 for small orders, about 67% lower overall. The gap also held within the 2-3 large vendors checked.
* **Growth opportunity:** Vendors with balanced turnover (0.8-1.2), above-average margin and below-average profit include Vranken America, Diageo Chateau Estate Wines, Vineyard Brands, Disaronno and Delicato, with margins of about 34% to 39%.

## Recommendations

* Keep strong terms with the top 10 vendors, and build backup suppliers for the most critical ones.
* Consolidate small orders into larger ones where demand and storage allow.
* Test larger orders with the high-margin mid-size vendors.
* Check stock turnover before trusting a vendor's margin.

## Limitations

* The bulk-discount gap may partly reflect product mix, since the order-size groups contain different products.
* Averages were used as cutoffs, so a few vendors with extreme losses pull them down. The scatter plot uses the median margin for this reason.
* Margin looks inflated when a vendor sells more than it bought in the period (one vendor had a stock turnover of about 59), so only vendors with balanced turnover were treated as reliable.
* The data has no date field, so monthly and quarterly vendor trends were not analysed.
* The data cannot show whether demand exists to sell more from the growth vendors.

## Project Files

* `python/` -- Data extraction script
* `sql/` -- Cleaning, derived columns, analysis queries and dashboard views
* `dashboard/vendor_performance.pbix` -- Power BI dashboard
* `dashboard/` -- Dashboard screenshots

Rohnit Bhardwaj
