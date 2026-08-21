USE SupplyChainAnalytics;
GO

CREATE OR ALTER VIEW vw_inventory_analysis
AS 
SELECT
    -- Date
    i.Date,

    -- Product information
    i.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,

    -- Supplier
    p.SupplierID,

    -- Warehouse
    i.WarehouseID,
    w.WarehouseName,

    -- Inventory movement
    i.OpeningStock,
    i.UnitsReceived,
    i.UnitsSold,
    i.LostSales,
    i.ClosingStock,

    -- Demand
    i.UnitsSold AS FulfilledDemand,
    i.LostSales AS LostDemand,
    i.UnitsSold + i.LostSales AS ObservedDemand,

    -- Inventory status
    i.StockoutFlag,
    i.Promotion,

    -- Product economics
    p.UnitCost,
    p.UnitPrice,

    -- Inventory value
    i.ClosingStock * p.UnitCost AS InventoryValue,

    -- Actual sales value
    i.UnitsSold * p.UnitPrice AS SalesValue,

    -- Lost sales value
    i.LostSales * p.UnitPrice AS LostSalesValue,

    -- COGS
    i.UnitsSold * p.UnitCost AS COGS,

    -- Gross profit
    i.UnitsSold * (p.UnitPrice - p.UnitCost) AS GrossProfit,

    -- Gross margin %
    CASE
        WHEN p.UnitPrice = 0 THEN 0
        ELSE
            ((p.UnitPrice - p.UnitCost) / p.UnitPrice) * 100
    END AS GrossMarginPercent

FROM fact_inventory_daily i

INNER JOIN dim_products p
    ON i.ProductID = p.ProductID

INNER JOIN dim_warehouses w
    ON i.WarehouseID = w.WarehouseID;
GO


