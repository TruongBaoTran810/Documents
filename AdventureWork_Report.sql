--SALE REPORT
--- Using the FactInternetSales table, calculate the monthly revenue report for the Sales department. The output includes the following columns:
--- The reporting month is named ReportMonth
--- Total revenue (using the SalesAmount column) for each month is named TotalRev
--- Total cumulative revenue for each month in the year is named RunningTotalRev
--- Total revenue for the previous month as TotalRevLastMonth
--- Growth % compared to total revenue for the previous month is named PctGrowthLM
--- Total revenue for the same period last year (For example, in the January 2020 record, take the revenue for January 2019) is named Rev_YOY
--- Growth % compared to total revenue for the same period last year is named PctGrowthYoY
WITH SalesByMonth AS (
    SELECT 
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        SUM(SalesAmount) AS TotalRev
    FROM FactInternetSales
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
),

AddReportMonth AS (
    SELECT 
        OrderYear,
        OrderMonth,
        CONCAT(OrderYear, '-', RIGHT('0' + CAST(OrderMonth AS VARCHAR(2)), 2)) AS ReportMonth,
        TotalRev
    FROM SalesByMonth
),

RunningTotal AS (
    SELECT 
        *,
        SUM(TotalRev) OVER (PARTITION BY OrderYear ORDER BY OrderMonth) AS RunningTotalRev
    FROM AddReportMonth
),

AddLagAndYoY AS (
    SELECT 
        *,
        LAG(TotalRev) OVER (PARTITION BY OrderYear ORDER BY OrderMonth) AS TotalRevLastMonth,
        LAG(TotalRev) OVER (PARTITION BY OrderMonth ORDER BY OrderYear) AS Rev_YOY
    FROM RunningTotal
)
SELECT 
    ReportMonth,
    TotalRev,
    RunningTotalRev,
    COALESCE(TotalRevLastMonth, 0) AS TotalRevLastMonth,
    COALESCE(CASE 
            WHEN TotalRevLastMonth = 0 THEN NULL 
            ELSE ROUND(((TotalRev - TotalRevLastMonth) / TotalRevLastMonth) * 100, 2) END , 
            0) AS PctGrowthLM,
    COALESCE(Rev_YOY, 0) AS Rev_YOY,
    COALESCE(CASE 
             WHEN Rev_YOY = 0 THEN NULL 
             ELSE ROUND(((TotalRev - Rev_YOY) / Rev_YOY) * 100, 2) END , 
            0) AS PctGrowthYoY
FROM AddLagAndYoY
ORDER BY OrderYear, OrderMonth

--MARKETING REPORT
--- Using the AdventureWorksDW2019 dataset, answer the questions below.
--- Using the FactInternetSales table, calculate a monthly report summarizing the number of customers for the Marketing department. The output includes the following columns:
--- The reporting month is named ReportMonth
--- The total number of customers who made a purchase that month is named NumberofActiveCustomer
--- The total number of new customers who made a purchase for the first time in that month is named NumberofNewCustomer
--- The total number of returning customers in that month (old customers, who have made orders in the past) is named NumberofReturnCustomer
WITH SalesByMonth AS (
    SELECT 
        CustomerKey,
        YEAR(OrderDate) AS OrderYear,
        MONTH(OrderDate) AS OrderMonth,
        OrderDate
    FROM FactInternetSales
),

FirstPurchase AS (
    SELECT 
        CustomerKey,
        MIN(OrderDate) AS FirstOrderDate
    FROM FactInternetSales
    GROUP BY CustomerKey
),

CustomerMonthStatus AS (
    SELECT 
        s.OrderYear,
        s.OrderMonth,
        s.CustomerKey,
        CASE 
            WHEN YEAR(f.FirstOrderDate) = s.OrderYear 
                 AND MONTH(f.FirstOrderDate) = s.OrderMonth
                THEN 1 ELSE 0
        END AS IsNewCustomer
    FROM SalesByMonth s
    JOIN FirstPurchase f ON s.CustomerKey = f.CustomerKey
    GROUP BY s.OrderYear, s.OrderMonth, s.CustomerKey, f.FirstOrderDate
)

SELECT
    CONCAT(OrderYear, '-', RIGHT('0' + CAST(OrderMonth AS VARCHAR(2)), 2)) AS ReportMonth,
    COUNT(DISTINCT CustomerKey) AS NumberofActiveCustomer,
    SUM(IsNewCustomer) AS NumberofNewCustomer,
    COUNT(DISTINCT CustomerKey) - SUM(IsNewCustomer) AS NumberofReturnCustomer
FROM CustomerMonthStatus
GROUP BY OrderYear, OrderMonth
ORDER BY OrderYear, OrderMonth

-- Use the DimGeography, DimCustomer, DimReseller tables. Get a list of locations (including City, EnglishCountryRegionName information) that have at least one Customer and one Reseller of the company residing at the same time. The returned results include the following columns: City, EnglishCountryRegionName
SELECT DISTINCT 
    g.City,
    g.EnglishCountryRegionName
FROM DimGeography g
WHERE g.GeographyKey IN (
    SELECT c.GeographyKey 
    FROM DimCustomer c
    INTERSECT
    SELECT r.GeographyKey 
    FROM DimReseller r
)
ORDER BY g.EnglishCountryRegionName, g.City


SELECT DISTINCT 
    g.City,
    g.EnglishCountryRegionName
FROM DimGeography g
WHERE g.GeographyKey IN (
    SELECT c.GeographyKey 
    FROM DimCustomer c
    INTERSECT
    SELECT r.GeographyKey 
    FROM DimReseller r
)
ORDER BY g.EnglishCountryRegionName, g.City