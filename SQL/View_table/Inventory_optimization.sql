CREATE OR ALTER VIEW vw_inventory_optimization
AS

WITH DemandStats AS
(
    SELECT
        ProductID,
        WarehouseID,

        AVG(
            CAST(
                UnitsSold + LostSales
                AS DECIMAL(18,4)
            )
        ) AS AverageDailyDemand,

        STDEV(
            CAST(
                UnitsSold + LostSales
                AS DECIMAL(18,4)
            )
        ) AS DemandStdDev

    FROM fact_inventory_daily

    GROUP BY
        ProductID,
        WarehouseID
),

SupplierLeadTime AS
(
    SELECT
        ProductID,
        WarehouseID,

        AVG(
            CAST(
                DATEDIFF(
                    DAY,
                    OrderDate,
                    ActualDeliveryDate
                ) AS DECIMAL(18,4)
            )
        ) AS AverageActualLeadTime

    FROM fact_purchase_orders

    WHERE ActualDeliveryDate IS NOT NULL

    GROUP BY
        ProductID,
        WarehouseID
),

LatestInventory AS
(
    SELECT
        i.ProductID,
        i.WarehouseID,
        i.ClosingStock AS CurrentStock,
        i.Date AS CurrentStockDate

    FROM fact_inventory_daily i

    INNER JOIN
    (
        SELECT
            ProductID,
            WarehouseID,
            MAX(Date) AS LatestDate

        FROM fact_inventory_daily

        GROUP BY
            ProductID,
            WarehouseID

    ) latest

        ON i.ProductID = latest.ProductID
        AND i.WarehouseID = latest.WarehouseID
        AND i.Date = latest.LatestDate
)

SELECT

    /* PRODUCT */

    d.ProductID,

    p.ProductName,

    p.Category,


    /* WAREHOUSE */

    d.WarehouseID,

    w.WarehouseName,


    /*DEMAND */

    d.AverageDailyDemand,

    COALESCE(
        d.DemandStdDev,
        0
    ) AS DemandStdDev,


    /* LEAD TIME */

    COALESCE(
        sl.AverageActualLeadTime,
        s.BaseLeadTimeDays
    ) AS LeadTime,


    /* PARAMETERS */

    param.ServiceLevel,

    param.ZScore,

    param.OrderingCost,


    /* HOLDING COST */

    p.UnitCost
        * param.HoldingCostPercent
        AS HoldingCost,


    /*SAFETY STOCK */

    CEILING(
        param.ZScore
        * COALESCE(
            d.DemandStdDev,
            0
        )
        * SQRT(
            COALESCE(
                sl.AverageActualLeadTime,
                s.BaseLeadTimeDays
            )
        )
    ) AS SafetyStock,


    /*REORDER POINT*/

    CEILING(
        (
            d.AverageDailyDemand
            *
            COALESCE(
                sl.AverageActualLeadTime,
                s.BaseLeadTimeDays
            )
        )
        +
        (
            param.ZScore
            * COALESCE(
                d.DemandStdDev,
                0
            )
            * SQRT(
                COALESCE(
                    sl.AverageActualLeadTime,
                    s.BaseLeadTimeDays
                )
            )
        )
    ) AS ReorderPoint,


    /*ANNUAL DEMAND */

    d.AverageDailyDemand * 365
        AS AnnualDemand,


    /*EOQ */

    CEILING(
        SQRT(
            (
                2
                * (d.AverageDailyDemand * 365)
                * param.OrderingCost
            )
            /
            NULLIF(
                p.UnitCost
                * param.HoldingCostPercent,
                0
            )
        )
    ) AS EOQ,


    /*CURRENT STOCK */

    li.CurrentStock,

    li.CurrentStockDate,


    /*DAYS OF INVENTORY*/

    CAST(
        ROUND(
            CAST(
                li.CurrentStock
                AS DECIMAL(18,4)
            )
            /
            NULLIF(
                d.AverageDailyDemand,
                0
            ),
            2
        )
        AS DECIMAL(18,2)
    ) AS DaysOfInventory,


    /*CURRENT INVENTORY VALUE */

    li.CurrentStock * p.UnitCost
        AS CurrentInventoryValue,

  /*STOCK STATUS*/
    CASE 
       WHEN li.CurrentStock <=
        (
            param.ZScore
            * COALESCE(
                d.DemandStdDev,
                0
            )
            * SQRT(
                COALESCE(
                    sl.AverageActualLeadTime,
                    s.BaseLeadTimeDays
                )
            )
        )
         THEN 'CRITICAL'
         WHEN li.CurrentStock <
        (
            d.AverageDailyDemand
            *
            COALESCE(
                sl.AverageActualLeadTime,
                s.BaseLeadTimeDays
            )
        )
        +
        (
            param.ZScore
            * COALESCE(
                d.DemandStdDev,
                0
            )* SQRT(
                COALESCE(
                    sl.AverageActualLeadTime,
                    s.BaseLeadTimeDays
                )
            )
        )

        THEN 'REORDER'
        WHEN
            li.CurrentStock
            /
            NULLIF(
                d.AverageDailyDemand,
                0
            )
            > param.ExcessDaysThreshold
         THEN 'EXCESS'
      ELSE 'NORMAL'
   END AS StockStatus,

  /*SUGGESTED ORDER*/
    CASE
       WHEN li.CurrentStock <
        (
            d.AverageDailyDemand
            *
            COALESCE(
                sl.AverageActualLeadTime,
                s.BaseLeadTimeDays
            )
        )
        +
        (
            param.ZScore
            * COALESCE(
                d.DemandStdDev,
                0
            )
            * SQRT(
                COALESCE(
                    sl.AverageActualLeadTime,
                    s.BaseLeadTimeDays
                )
            )
        )

        THEN CEILING(
            SQRT(
                (
                    2* (d.AverageDailyDemand * 365)* param.OrderingCost
                )
                /
                NULLIF(
                    p.UnitCost
                    * param.HoldingCostPercent,
                    0)))
           ELSE 0
    END AS SuggestedOrderQty
FROM DemandStats d
INNER JOIN dim_products p
    ON d.ProductID = p.ProductID
INNER JOIN dim_warehouses w
    ON d.WarehouseID = w.WarehouseID
LEFT JOIN dim_suppliers s
    ON p.SupplierID = s.SupplierID
LEFT JOIN SupplierLeadTime sl
    ON d.ProductID = sl.ProductID
    AND d.WarehouseID = sl.WarehouseID
LEFT JOIN LatestInventory li
    ON d.ProductID = li.ProductID
    AND d.WarehouseID = li.WarehouseID
CROSS JOIN dim_inventory_parameters param;
GO

SELECT TOP 50
    ProductID,
    ProductName,
    WarehouseID,
    WarehouseName,
    AverageDailyDemand,
    DemandStdDev,
    LeadTime,
    ServiceLevel,
    SafetyStock,
    ReorderPoint,
    AnnualDemand,
    OrderingCost,
    HoldingCost,
    EOQ,
    CurrentStock,
    DaysOfInventory,
    StockStatus,
    SuggestedOrderQty
FROM vw_inventory_optimization
ORDER BY
    CASE StockStatus
        WHEN 'CRITICAL' THEN 1
        WHEN 'REORDER' THEN 2
        WHEN 'EXCESS' THEN 3
        ELSE 4
    END;