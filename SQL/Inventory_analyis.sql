/* What is the total inventory value?*/
SELECT
    SUM(InventoryValue) AS TotalInventoryValue
FROM vw_inventory_analysis;

/** latest inventory value*/
WITH LatestInventory AS
(
    SELECT
        ProductID,
        WarehouseID,
        MAX(Date) AS LatestDate
    FROM vw_inventory_analysis
    GROUP BY
        ProductID,
        WarehouseID
)

SELECT
    SUM(i.InventoryValue) AS TotalInventoryValue
FROM vw_inventory_analysis i
INNER JOIN LatestInventory l
    ON i.ProductID = l.ProductID
    AND i.WarehouseID = l.WarehouseID
    AND i.Date = l.LatestDate;

/* 2. Which TOP products have the highest inventory value? */
WITH LatestInventory AS
(
    SELECT
        ProductID,
        WarehouseID,
        MAX(Date) AS LatestDate
    FROM vw_inventory_analysis
    GROUP BY
        ProductID,
        WarehouseID
)

SELECT TOP 10
    i.ProductID,
    i.ProductName,
    i.Category,
    SUM(i.InventoryValue) AS InventoryValue
FROM vw_inventory_analysis i
INNER JOIN LatestInventory l
    ON i.ProductID = l.ProductID
    AND i.WarehouseID = l.WarehouseID
    AND i.Date = l.LatestDate
GROUP BY
    i.ProductID,
    i.ProductName,
    i.Category
ORDER BY
    InventoryValue DESC;

/* 3. Which warehouses hold the most inventory?*/
WITH LatestInventory AS
(
    SELECT
        ProductID,
        WarehouseID,
        MAX(Date) AS LatestDate
    FROM vw_inventory_analysis
    GROUP BY
        ProductID,
        WarehouseID
)

SELECT
    i.WarehouseID,
    i.WarehouseName,
    SUM(i.InventoryValue) AS InventoryValue
FROM vw_inventory_analysis i
INNER JOIN LatestInventory l
    ON i.ProductID = l.ProductID
    AND i.WarehouseID = l.WarehouseID
    AND i.Date = l.LatestDate
GROUP BY
    i.WarehouseID,
    i.WarehouseName
ORDER BY
    InventoryValue DESC;

/* 4. Which top products have the highest stockout rate?*/
SELECT TOP 10
    ProductID,
    ProductName,
    Category,
    CAST(SUM(
            CASE
                WHEN StockoutFlag = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS StockoutRatePercent

FROM vw_inventory_analysis

GROUP BY
    ProductID,
    ProductName,
    Category

ORDER BY
    StockoutRatePercent DESC;

/* 5. What is total lost-sales value?*/
/* LATEST VALUE*/
WITH LatestInventory AS
(
    SELECT
        ProductID,
        WarehouseID,
        MAX(Date) AS LatestDate
    FROM vw_inventory_analysis
    GROUP BY
        ProductID,
        WarehouseID
)
SELECT
    SUM(i.LostSalesValue) AS TotalLostSalesValue
FROM vw_inventory_analysis i
INNER JOIN LatestInventory l
    ON i.ProductID = l.ProductID
    AND i.WarehouseID = l.WarehouseID
    AND i.Date = l.LatestDate;
/* TOTAL VALUE*/
SELECT
    SUM(LostSalesValue) AS TotalLostSalesValue
FROM vw_inventory_analysis;

/* 6. Which suppliers have the longest lead times?*/
SELECT 
    SupplierID,
    SupplierName,
    AVG(
        CAST(ActualLeadTimeDays AS DECIMAL(18,2))
    ) AS AverageLeadTimeDays
FROM vw_supplier_analysis
WHERE ActualLeadTimeDays IS NOT NULL
GROUP BY
    SupplierID,
    SupplierName
ORDER BY
    AverageLeadTimeDays DESC;

/* 7. Which suppliers have the worst on-time delivery?*/
SELECT
    SupplierID,
    SupplierName,

    COUNT(*) AS TotalOrders,

    SUM(OnTimeFlag) AS OnTimeOrders,

    CAST(
        SUM(OnTimeFlag) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS OnTimeDeliveryPercent

FROM vw_supplier_analysis

GROUP BY
    SupplierID,
    SupplierName

ORDER BY
    OnTimeDeliveryPercent ASC;

/*8. Which suppliers have the highest purchase value?*/
SELECT
    SupplierID,
    SupplierName,
    SUM(TotalCost) AS TotalPurchaseValue,
    COUNT(DISTINCT PO_ID) AS NumberOfPurchaseOrders,
    SUM(QuantityOrdered) AS TotalQuantityOrdered
FROM vw_supplier_analysis
GROUP BY
    SupplierID,
    SupplierName
ORDER BY
    TotalPurchaseValue DESC;

 /* 9. Which warehouses have the highest stockout rate?*/
 SELECT
    WarehouseID,
    WarehouseName,
    COUNT(*) AS TotalInventoryDays,
    SUM(
        CASE
            WHEN StockoutFlag = 1 THEN 1
            ELSE 0
        END
    ) AS StockoutDays,
    CAST(
        SUM(
            CASE
                WHEN StockoutFlag = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*)
        AS DECIMAL(10,2)
    ) AS StockoutRatePercent
FROM vw_inventory_analysis
GROUP BY
    WarehouseID,
    WarehouseName
ORDER BY
    StockoutRatePercent DESC;
/*10. Which products have high demand but low inventory?*/
WITH ProductMetrics AS
(
  SELECT
      ProductID,
      ProductName,
      Category,
        AVG(CAST(ObservedDemand AS DECIMAL(18,2))
        ) AS AvgDailyDemand,

        AVG(CAST(ClosingStock AS DECIMAL(18,2))
        ) AS AvgInventory,
        MAX(Date) AS LatestDate
        FROM vw_inventory_analysis
    GROUP BY
        ProductID,
        ProductName,
        Category
 )
SELECT
    ProductID,
    ProductName,
    Category,
    AvgDailyDemand,
    AvgInventory,
    CASE
        WHEN AvgDailyDemand = 0 THEN NULL
        ELSE
            AvgInventory / AvgDailyDemand
    END AS ApproxDaysOfInventory
FROM ProductMetrics
ORDER BY
    AvgDailyDemand DESC,
    AvgInventory ASC;

/* 11. Create a more useful "High Demand + Low Inventory" query*/
WITH ProductMetrics AS
(
    SELECT
        ProductID,
        ProductName,
        Category,

        AVG(
            CAST(ObservedDemand AS DECIMAL(18,4))
        ) AS AvgDailyDemand,

        AVG(
            CAST(ClosingStock AS DECIMAL(18,4))
        ) AS AvgInventory

    FROM vw_inventory_analysis

    GROUP BY
        ProductID,
        ProductName,
        Category
),

Benchmarks AS
(
    SELECT
        AVG(AvgDailyDemand) AS OverallAvgDemand,
        AVG(AvgInventory) AS OverallAvgInventory

    FROM ProductMetrics
)

SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    p.AvgDailyDemand,
    p.AvgInventory,

    CASE
        WHEN p.AvgDailyDemand > b.OverallAvgDemand
             AND p.AvgInventory < b.OverallAvgInventory
        THEN 'HIGH DEMAND - LOW INVENTORY'

        WHEN p.AvgDailyDemand > b.OverallAvgDemand
             AND p.AvgInventory >= b.OverallAvgInventory
        THEN 'HIGH DEMAND - HIGH INVENTORY'

        WHEN p.AvgDailyDemand <= b.OverallAvgDemand
             AND p.AvgInventory < b.OverallAvgInventory
        THEN 'LOW DEMAND - LOW INVENTORY'

        ELSE 'LOW DEMAND - HIGH INVENTORY'
    END AS InventoryDemandSegment

FROM ProductMetrics p
CROSS JOIN Benchmarks b

ORDER BY
    CASE
        WHEN p.AvgDailyDemand > b.OverallAvgDemand
             AND p.AvgInventory < b.OverallAvgInventory
        THEN 1
        ELSE 2
    END,
    p.AvgDailyDemand DESC;


/* 12  Which products generate the most lost sales?*/
   SELECT TOP 10
    ProductID,
    ProductName,
    Category,

    SUM(LostSales) AS TotalLostUnits,

    SUM(LostSalesValue) AS TotalLostSalesValue

FROM vw_inventory_analysis

GROUP BY
    ProductID,
    ProductName,
    Category

ORDER BY
    TotalLostSalesValue DESC;

/* 13 Which warehouse is losing the most potential revenue due to stockouts?*/
   SELECT
    WarehouseID,
    WarehouseName,

    SUM(LostSales) AS LostUnits,

    SUM(LostSalesValue) AS LostSalesValue

FROM vw_inventory_analysis

GROUP BY
    WarehouseID,
    WarehouseName

ORDER BY
    LostSalesValue DESC;

/* category analysis*/
SELECT
    Category,

    SUM(InventoryValue) AS InventoryValue,

    SUM(SalesValue) AS SalesValue,

    SUM(LostSalesValue) AS LostSalesValue,

    SUM(UnitsSold) AS UnitsSold,

    SUM(LostSales) AS LostUnits

FROM vw_inventory_analysis

GROUP BY
    Category

ORDER BY
    InventoryValue DESC;