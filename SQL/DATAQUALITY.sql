/* CHECK THE ALL THE DATA ADDED*/
SELECT COUNT(*) AS TotalProducts
FROM dim_products

SELECT COUNT(*) AS TotalSuppliers
FROM dim_suppliers

SELECT COUNT(*) AS TotalWarehouses
FROM dim_warehouses

SELECT COUNT(*) AS TotalInventoryRecords
FROM fact_inventory_daily

SELECT COUNT(*) AS TotalInventoryRecords
FROM fact_purchase_orders

/* duplicate primary keys*/
 SELECT ProductID, COUNT(*) AS Duplicatecount
 FROM dim_products
 GROUP BY ProductID
 HAVING COUNT(*) > 1;

 SELECT SupplierID, COUNT(*) AS Duplicatecount
 FROM dim_suppliers
 GROUP BY SupplierID
 HAVING COUNT(*) > 1;

 SELECT WarehouseID, COUNT(*) AS Duplicatecount
 FROM dim_warehouses
 GROUP BY WarehouseID
 HAVING COUNT(*) > 1;

 /* NULL CHECKS*/
 SELECT * FROM dim_products
 WHERE ProductID IS NULL;

 SELECT * FROM dim_suppliers
 WHERE SupplierID IS NULL;

 SELECT * FROM fact_inventory_daily
 WHERE ProductID IS NULL OR WarehouseID IS NULL OR Date IS NULL;

 SELECT * FROM fact_purchase_orders
 WHERE ProductID IS NULL OR WarehouseID IS NULL OR SupplierID IS NULL;

 /* Negative invventory values*/
 SELECT * FROM fact_inventory_daily
 WHERE OpeningStock < 0
       OR ClosingStock < 0
       OR UnitsSold < 0
       OR LostSales < 0;

/*Checking Stock Calculation*/
SELECT *,
       OpeningStock
       + UnitsReceived
       - UnitsSold
       - LostSales AS CalculatedClosingStock
FROM fact_inventory_daily
WHERE ClosingStock <>
      OpeningStock
      + UnitsReceived
      - UnitsSold
      - LostSales;

/* Check flag values*/
SELECT *
FROM fact_inventory_daily
WHERE Promotion NOT IN (0,1)
   OR StockoutFlag NOT IN (0,1);
/* check foriegn keys */
   /* inventory record*/
   SELECT f.*
   FROM fact_inventory_daily f
   LEFT JOIN dim_products p
        ON f.ProductID = p.ProductID
        WHERE p.ProductID IS NULL;
   /* warehouse record*/
   SELECT f.*
   FROM fact_inventory_daily f
   LEFT JOIN dim_warehouses w
        ON f.WarehouseID = w.WarehouseID
        WHERE w.WarehouseID IS NULL;

 /*  DATE RANGE CHECK */

SELECT
    MIN(Date) AS MinimumDate,
    MAX(Date) AS MaximumDate
FROM fact_inventory_daily;
