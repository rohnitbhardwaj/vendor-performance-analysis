-- DATA QUALITY VALIDATION: Checking calculation accuracy, invalid values,
-- duplicate records and out-of-range dates in purchase data.

-- Verify calculation consistency between PurchasePrice, Quantity and Dollars
SELECT 
    COUNT(*) AS mismatched_rows
FROM purchases
WHERE ABS(PurchasePrice * Quantity - Dollars) > 0.01;


-- Identify negative or invalid price values
SELECT
    *
FROM purchase_prices
WHERE price < 0 OR PurchasePrice < 0;


-- Identify duplicate brands in purchase_prices
SELECT 
    Brand,
    COUNT(*)
FROM purchase_prices
GROUP BY Brand
HAVING COUNT(*) > 1;


-- Identify future dates in purchase records
SELECT
    *
FROM purchases
WHERE 
    ReceivingDate > GETDATE() OR 
    InvoiceDate > GETDATE() OR 
    PayDate > GETDATE();



-- CONSOLIDATED DATA VALIDATION: Verifying column data types, correcting
-- data types and identifying unwanted spaces and NULL values.

-- Verify column names and data types in the consolidated table
SELECT 
    name AS COLUMN_NAME, 
    TYPE_NAME(user_type_id) AS DATA_TYPE
FROM sys.columns 
WHERE object_id = OBJECT_ID('VendorSalesSummary');


-- Change Volume column data type to FLOAT
ALTER TABLE VendorSalesSummary
ALTER COLUMN Volume FLOAT;


-- Identify records with unwanted leading or trailing spaces
SELECT
    COUNT(*)
FROM VendorSalesSummary
WHERE Description != TRIM(Description);


-- Count NULL values in TotalSalesQty column
SELECT
    COUNT(*)
FROM VendorSalesSummary
WHERE TotalSalesQty IS NULL;
