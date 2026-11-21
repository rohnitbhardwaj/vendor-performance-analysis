-- VENDOR PERFORMANCE ANALYSIS: Evaluating profit contribution, purchase spending,
-- bulk buying efficiency, inventory turnover and vendor profitability.



-- Calculate the percentage of total profit contributed by the top 10 vendors
WITH CT AS(
    SELECT
        VendorNumber,
        VendorName,
        SUM(GrossProfit) AS TotalProfit
    FROM CleanVendorSummary
    GROUP BY VendorNumber, VendorName
)

-- Rank vendors by profit and calculate the top 10 profit contribution
SELECT
    SUM(CASE
        WHEN rn <= 10 THEN TotalProfit END) * 100.0 / SUM(TotalProfit) AS Top10ProfitShare
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER(ORDER BY TotalProfit DESC) AS rn
    FROM CT
)t;

-- =============================================================================

-- Analyze vendor purchase contribution and cumulative spending percentage
WITH CT AS(
    SELECT
        VendorNumber,
        VendorName,
        SUM(TotalPurchaseAmt) AS VendorSpend
    FROM CleanVendorSummary
    GROUP BY VendorNumber, VendorName
)

-- Calculate individual purchase share and cumulative contribution for top 10 vendors
SELECT TOP 10
    VendorNumber,
    VendorName,
    VendorSpend,
    ROUND(PurchasePct, 2) AS PurchasePct,
    ROUND(SUM(PurchasePct) OVER(ORDER BY VendorSpend DESC), 2) AS CumPct
FROM
(
    SELECT
        *,
        VendorSpend * 100.0 / SUM(VendorSpend) OVER() AS PurchasePct
    FROM CT
)t;

-- =============================================================================

-- Analyze average unit cost across order sizes to identify potential bulk purchase discounts
WITH Bucketed AS (
    SELECT
        VendorNumber,
        TotalPurchaseQty,
        TotalPurchaseAmt,
        NTILE(3) OVER (ORDER BY TotalPurchaseQty) AS OrderSize
    FROM CleanVendorSummary
    WHERE TotalPurchaseQty > 0
)

-- Group orders into small, medium and large buckets and compare average unit costs
SELECT
    CASE OrderSize WHEN 1 THEN 'Small' WHEN 2 THEN 'Medium' ELSE 'Large' END AS OrderSizeGroup,
    MIN(TotalPurchaseQty) AS MinQty,
    MAX(TotalPurchaseQty) AS MaxQty,
    ROUND(SUM(TotalPurchaseAmt) / SUM(TotalPurchaseQty), 2) AS AvgUnitCost
FROM Bucketed
GROUP BY OrderSize
ORDER BY OrderSize;
)T

-- =============================================================================

-- Comparing small and large order unit costs across products to identify potential bulk purchasing discounts.


-- Divide purchase records into three quantity groups for each product and vendor
WITH Lines AS (
    SELECT
        Brand,
        VendorNumber,
        Quantity,
        Dollars,
        NTILE(3) OVER (PARTITION BY Brand, VendorNumber ORDER BY Quantity) AS Grp
    FROM purchases
    WHERE Quantity > 0
),

-- Calculate total product spending and unit costs for small and large orders
PerProduct AS (
    SELECT
        Brand,
        VendorNumber,
        SUM(Dollars) AS ProductSpend,

        -- Calculate weighted average unit cost for small orders
        SUM(CASE WHEN Grp = 1 THEN Dollars END) * 1.0
            / NULLIF(SUM(CASE WHEN Grp = 1 THEN Quantity END), 0) AS SmallUnitCost,

        -- Calculate weighted average unit cost for large orders
        SUM(CASE WHEN Grp = 3 THEN Dollars END) * 1.0
            / NULLIF(SUM(CASE WHEN Grp = 3 THEN Quantity END), 0) AS LargeUnitCost

    FROM Lines
    GROUP BY Brand, VendorNumber

    -- Retain products with at least 30 purchase records
    HAVING COUNT(*) >= 30
)

-- Compare bulk and small-order costs across products
SELECT
    COUNT(*) AS Products,
    SUM(CASE WHEN LargeUnitCost < SmallUnitCost THEN 1 ELSE 0 END) AS LargeCheaper,
    SUM(CASE WHEN LargeUnitCost = SmallUnitCost THEN 1 ELSE 0 END) AS SamePrice,

    -- Calculate spend-weighted percentage difference in unit costs
    ROUND(SUM(ProductSpend * (SmallUnitCost - LargeUnitCost) / SmallUnitCost)
          * 100.0 / SUM(ProductSpend), 2) AS WeightedPctDiff

FROM PerProduct

-- Exclude invalid or unavailable unit cost comparisons
WHERE SmallUnitCost > 0 AND LargeUnitCost IS NOT NULL;

-- =============================================================================

-- Analyze inventory turnover, sales efficiency and estimated unsold inventory value
SELECT
    VendorNumber,
    VendorName,
    SUM(TotalPurchaseQty) AS PurchaseQty,
    SUM(TotalSalesQty) AS SalesQty,
    ROUND(CAST(SUM(TotalSalesQty) AS FLOAT)
          / NULLIF(SUM(TotalPurchaseQty), 0), 2) AS StockTurnover,
    SUM(TotalPurchaseAmt) - SUM(TotalSalesQty * UnitPurchaseCost) AS UnsoldInventoryValue,
    (SUM(TotalPurchaseAmt) - SUM(TotalSalesQty * UnitPurchaseCost)) * 100.0
    / NULLIF(SUM(TotalPurchaseAmt), 0) AS UnsoldPct
FROM CleanVendorSummary
GROUP BY VendorNumber, VendorName
ORDER BY UnsoldInventoryValue DESC;

-- =============================================================================

-- Compare vendor profit margins and identify high-margin vendors with growth potential
WITH CT AS (
    SELECT
        VendorNumber,
        VendorName,
        SUM(TotalPurchaseAmt) AS Spend,
        SUM(TotalSalesAmt) AS Sales,
        SUM(GrossProfit) AS TotalProfit,
        ROUND(CAST(SUM(TotalSalesAmt - TotalPurchaseAmt) AS FLOAT)
              / NULLIF(SUM(TotalSalesAmt), 0) * 100, 2) AS Margin
    FROM CleanVendorSummary
    GROUP BY VendorNumber, VendorName
)

-- Retrieve top 10 vendors by profit and compare their margins with the overall company margin
SELECT TOP 10
    *,
    (SELECT ROUND(SUM(TotalSalesAmt - TotalPurchaseAmt) * 100.0
                  / NULLIF(SUM(TotalSalesAmt), 0), 2)
     FROM CleanVendorSummary) AS CompanyMargin
FROM CT
ORDER BY TotalProfit DESC;

-- =============================================================================



