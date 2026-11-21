# Vendor Performance Analysis

Python · SQL Server · Power BI

📊 [View Dashboard Screenshots](https://github.com/rohnitbhardwaj/vendor-performance-analysis/blob/main/dashboard)

## Business Problem

Which vendors earn the most, where is purchase money concentrated, and which vendors should be protected, renegotiated or grown? The goal is to help a wine and spirits distributor decide where its buying budget earns the most.

## Dataset

Bibitor LLC, a fictional wine and spirits retail company with about 80 stores, used in accounting and data-analytics case studies. The data includes purchases, sales, inventory, prices and vendor invoices.

## Methodology

1. **Data ingestion (Python):** Wrote a script that reads every CSV file in the source folder with pandas and loads each one into SQL Server as its own table, using SQLAlchemy and `pyodbc` with `fast_executemany` and 10,000-row chunks. Added logging that records each file ingested and the total load time.
2. **Transformation (SQL):** Cleaned and integrated the tables into one vendor summary table. Added gross profit, profit margin, unit purchase cost, stock turnover, unsold inventory value, purchase contribution and cumulative contribution. Handled zero-sales rows with `NULLIF`, and merged vendor numbers that appeared under two names using `ROW_NUMBER()`. Margin is total profit divided by total sales, never an average of row-level margins.
3. **Analysis (SQL):** Wrote one query per business question using CTEs and window functions (`SUM() OVER`, `NTILE`). Checked spend against margin, stock turnover and unsold inventory, cumulative purchase share, and unit cost across Small, Medium and Large orders, then compared the same product and vendor across order sizes to separate price from product mix. Checked whether each result was reliable, for example whether high margins came from mismatched purchases and sales.
4. **Visualization (Power BI):** One-page dashboard built on two SQL views, with a vendor slicer: spend concentration, margin by spend, unit cost by order size, unsold inventory, and the vendors worth growing.

## Key Findings

* **Overall:** Total purchase spend is $321.90M with $129.72M gross profit, a 28.72% margin.
* **Concentration:** The top 10 vendors take 65.33% of purchase spend and about 64% of gross profit. The largest, Diageo North America, alone accounts for about 16% of spend.
* **High spend, low margin:** No vendor combines both. 27 vendors had above-average spend and 18 had below-average margin, with no overlap, and the top 10 by spend all earn at or above the company margin.
* **Unsold stock:** The largest unsold values sit with the biggest vendors, whose stock turnover is about 0.97. Vendors with turnover below 0.7 hold only 0.47% of total unsold inventory.
* **No bulk discount:** Large orders look 67% cheaper per unit overall ($9.25 vs $27.68), but that gap is product mix. Comparing small and large order lines for the same product and vendor (4,918 products), the large order was cheaper for 41%, the same price for 21% and more expensive for 38%, with no net difference in weighted unit cost.
* **Growth opportunity:** Vendors with balanced turnover (0.8-1.2), above-average margin and below-average profit include Vranken America, Diageo Chateau Estate Wines, Vineyard Brands, Disaronno and Delicato, with margins of about 34% to 39%.

## Business Impact

* Purchase spend is concentrated: the top 10 vendors take 65.33% of the $321.90M budget (about $210M) and Diageo North America alone about 16%. A disruption at a single top supplier would put a large share of purchasing at risk, so backup sourcing is a risk control.
* No high-spend vendor earns a below-average margin, so the largest suppliers are not draining the budget, and margins give no reason to squeeze them.
* Large orders look 67% cheaper, but like for like there is no net discount, so ordering more from the same vendors is not a reliable saving. Negotiating volume-tier pricing is the lever, because current prices do not fall with order size.
* Five mid-size vendors (Vranken America, Diageo Chateau Estate Wines, Vineyard Brands, Disaronno and Delicato) earn margins of about 34% to 39%, roughly 5 to 10 points above the 28.72% company margin, and are the best candidates for a larger share of spend.

## Recommendations

* Keep strong terms with the top 10 vendors, and build backup suppliers for the most critical ones.
* Don't expect savings from simply ordering more. Negotiate volume-tier pricing with the top vendors instead, since current prices don't fall with order size.
* Test larger orders with the high-margin mid-size vendors.
* Check stock turnover before trusting a vendor's margin.

## Limitations

* The order-size comparison covers one year of data, so price changes over time are not separated from order size.
* Averages were used as cutoffs, so a few vendors with extreme losses pull them down. The scatter plot uses the median margin for this reason.
* Margin looks inflated when a vendor sells more than it bought in the period (one vendor had a stock turnover of about 59), so only vendors with balanced turnover were treated as reliable.
* The data has no date field, so monthly and quarterly vendor trends were not analysed.
* The data cannot show whether demand exists to sell more from the growth vendors.
* Synthetic dataset, so real-world factors such as store operations and supplier contracts aren't captured.

## Project Files

* `python/` -- Data extraction script
* `sql/` -- Cleaning, derived columns, analysis queries and dashboard views
* `dashboard/vendor_performance.pbix` -- Power BI dashboard
* `dashboard/` -- Dashboard screenshots

Rohnit Bhardwaj
