-- VENDOR DATA CONSOLIDATION: Combining purchase, freight and sales data
-- to create a consolidated vendor-level summary for analysis.



-- Aggregate purchase details at vendor and brand level
WITH PurchaseSummary AS(
    SELECT 
        p.VendorNumber,
        p.VendorName,
        p.Brand,
        p.Description,
        pp.Volume,
        pp.Price AS ActualPrice,
        p.PurchasePrice, 
        SUM(p.Quantity) AS TotalPurchaseQty,
        SUM(p.Dollars) AS TotalPurchaseAmt
    FROM purchases p
    JOIN purchase_prices pp
        ON p.Brand = pp.Brand
    WHERE p.PurchasePrice > 0
    GROUP BY p.VendorNumber, p.VendorName, p.Brand, p.Description,
             p.PurchasePrice, pp.Price, pp.Volume
),

-- Calculate total freight incurred by each vendor
FreightSummary AS(
    SELECT
        VendorNumber,
        SUM(Freight) AS TotalFreight
    FROM vendor_invoice
    GROUP BY VendorNumber
),

-- Aggregate sales metrics for each vendor and brand
SalesSummary AS(
    SELECT
        VendorNo,
        Brand,
        SUM(SalesQuantity) AS TotalSalesQty,
        SUM(SalesDollars) AS TotalSalesAmt,
        SUM(ExciseTax) AS TotalExcTax
    FROM sales
    GROUP BY VendorNo, Brand
)

-- Combine purchase, freight and sales summaries into the final table
SELECT
    ps.VendorNumber,
    ps.VendorName,
    ps.Brand,
    ps.Description,
    ps.Volume,
    ps.ActualPrice,
    ps.PurchasePrice, 
    ROUND(ps.TotalPurchaseQty, 1) AS TotalPurchaseQty,
    ROUND(ps.TotalPurchaseAmt, 1) AS TotalPurchaseAmt,
    ROUND(fs.TotalFreight, 1) AS TotalFreight,
    ROUND(ss.TotalSalesQty, 1) AS TotalSalesQty,
    ROUND(ss.TotalSalesAmt, 1) AS TotalSalesAmt,
    ROUND(ss.TotalExcTax, 1) AS TotalExcTax
INTO VendorSalesSummary
FROM PurchaseSummary ps

-- Join vendor-level freight details
LEFT JOIN FreightSummary fs
    ON ps.VendorNumber = fs.VendorNumber

-- Join sales details using vendor number and brand
LEFT JOIN SalesSummary ss
    ON ps.VendorNumber = ss.VendorNo
    AND ps.Brand = ss.Brand

-- Sort records by highest purchase amount
ORDER BY ps.TotalPurchaseAmt DESC;


-- DATA CLEANING & TRANSFORMATION: Cleaning consolidated vendor data,
-- handling NULL values and calculating key profitability and inventory metrics.


CREATE OR ALTER PROCEDURE CleanSummary AS
BEGIN 

    -- Declare variables to track procedure execution time
    DECLARE @StartTime DATETIME, @EndTime DATETIME 

    SET @StartTime = GETDATE();

    -- Drop existing table before recreating it
    DROP TABLE IF EXISTS CleanVendorSummary;

    -- Calculate key business metrics and store cleaned data
    SELECT
        *,
        ROUND(TotalSalesAmt - TotalPurchaseAmt, 2) AS GrossProfit,
        ROUND(CAST(TotalSalesAmt - TotalPurchaseAmt AS FLOAT) / NULLIF(TotalSalesAmt, 0) * 100, 2) AS ProfitMargin,
        ROUND(TotalPurchaseAmt / TotalPurchaseQty, 2) AS UnitPurchaseCost,
        TotalSalesQty / TotalPurchaseQty AS StockTurnover,
        ROUND(TotalSalesAmt / TotalPurchaseAmt, 2) AS SaleToPurchaseRatio
    INTO CleanVendorSummary
    FROM
        (
            -- Clean text columns and handle NULL values in sales metrics
            SELECT
                VendorNumber,
                TRIM(VendorName) AS VendorName,
                Brand,
                TRIM(Description) AS Description,
                Volume,
                PurchasePrice,
                TotalPurchaseQty,
                TotalPurchaseAmt,
                TotalFreight,
                ActualPrice,
                ISNULL(TotalSalesQty, 0) AS TotalSalesQty,
                ISNULL(TotalSalesAmt, 0) AS TotalSalesAmt,
                ISNULL(TotalExcTax, 0) AS TotalExcTax
            FROM VendorSalesSummary
        ) t;

    -- Calculate and display total execution time in seconds
    SET @EndTime = GETDATE();

    PRINT 'Time Taken: ' + CAST(DATEDIFF(second, @StartTime, @EndTime) AS NVARCHAR) + ' Seconds';

END;
