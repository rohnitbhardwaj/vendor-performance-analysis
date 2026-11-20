-- VENDOR DASHBOARD VIEW: Deduplicating vendor records, calculating key performance
-- indicators (KPIs) and categorizing vendors for dashboard reporting.



-- Create or update the dashboard view
CREATE OR ALTER VIEW VendorDashboard AS

-- Used later as filter to deduplicate vendor name 
WITH Names AS (
    SELECT
        VendorNumber,
        VendorName,
        ROW_NUMBER() OVER (PARTITION BY VendorNumber
                           ORDER BY SUM(TotalPurchaseAmt) DESC) AS rn
    FROM CleanVendorSummary
    GROUP BY VendorNumber, VendorName
),

-- Calculate vendor-level spending, sales, profitability and inventory metrics
CT AS (
    SELECT
        c.VendorNumber,
        n.VendorName,
        SUM(c.TotalPurchaseAmt) AS Spend,
        SUM(c.TotalSalesAmt) AS Sales,
        SUM(c.TotalSalesAmt - c.TotalPurchaseAmt) AS Profit,

        -- Calculate profit margin as a percentage of sales
        ROUND(SUM(c.TotalSalesAmt - c.TotalPurchaseAmt) * 100.0
              / NULLIF(SUM(c.TotalSalesAmt), 0), 2) AS Margin,

        -- Measure sales quantity against purchase quantity
        ROUND(SUM(c.TotalSalesQty) * 100.0
              / NULLIF(SUM(c.TotalPurchaseQty), 0), 2) AS StockTurnover,

        -- Estimate the value of unsold inventory at purchase cost
        SUM(c.TotalPurchaseAmt) - SUM(c.TotalSalesQty * c.UnitPurchaseCost) AS UnsoldInventoryValue,

        -- Calculate adjusted margin after accounting for estimated inventory cost
        ROUND(CAST(SUM(c.TotalSalesAmt) - SUM(c.TotalSalesQty * c.UnitPurchaseCost) AS FLOAT)
              / NULLIF(SUM(c.TotalSalesAmt), 0) * 100, 2) AS AdjustedMargin

    FROM CleanVendorSummary c

    -- Keep One Vendor Brand Name for each VendorNumber
    JOIN Names n
        ON n.VendorNumber = c.VendorNumber AND n.rn = 1

    GROUP BY c.VendorNumber, n.VendorName
)

-- Calculate purchase contribution, cumulative spending and vendor categorization
SELECT *,
       -- Calculate each vendor's share of total purchases
       ROUND(Spend * 100.0 / SUM(Spend) OVER (), 2) AS PurchasePct,

       -- Calculate cumulative purchase contribution in descending order of spend
       ROUND(SUM(Spend) OVER (ORDER BY Spend DESC)
             * 100.0 / SUM(Spend) OVER (), 2) AS CumulativePct,

       -- Identify vendors with potential for business growth
       CASE WHEN Margin > AVG(Margin) OVER ()
             AND Profit < AVG(Profit) OVER ()
             AND StockTurnover BETWEEN 0.8 AND 1.2
            THEN 'Growth Opportunity' ELSE 'Other' END AS VendorGroup

FROM CT;




-- ORDER SIZE DASHBOARD VIEW: Categorizing vendors into small, medium and large
-- purchase groups based on quantity for dashboard analysis.

-- Create or update the order size dashboard view
CREATE OR ALTER VIEW OrderSizeDashboard AS

SELECT
    VendorNumber,
    VendorName,
    TotalPurchaseQty,
    TotalPurchaseAmt,

    -- Categorize purchase quantities into three groups using NTILE
    CASE NTILE(3) OVER (ORDER BY TotalPurchaseQty)
        WHEN 1 THEN 'Small'
        WHEN 2 THEN 'Medium'
        ELSE 'Large'
    END AS OrderSizeGroup,

    -- Assign numeric sorting order to purchase size categories
    NTILE(3) OVER (ORDER BY TotalPurchaseQty) AS OrderSizeSort

FROM CleanVendorSummary

-- Exclude records with zero or negative purchase quantities
WHERE TotalPurchaseQty > 0;
