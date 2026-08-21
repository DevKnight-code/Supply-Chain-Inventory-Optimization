CREATE OR ALTER VIEW vw_supplier_analysis
AS
SELECT
    po.PO_ID,

    -- Supplier
    po.SupplierID,
    s.SupplierName,
    s.Region,
    s.ReliabilityTier,

    -- Product
    po.ProductID,
    p.ProductName,
    p.Category,

    -- Warehouse
    po.WarehouseID,
    w.WarehouseName,

    -- Purchase order dates
    po.OrderDate,
    po.ExpectedDeliveryDate,
    po.ActualDeliveryDate,

    -- Quantities
    po.QuantityOrdered,
    po.QuantityReceived,

    -- Shortage
    po.QuantityOrdered - po.QuantityReceived AS ShortageQuantity,

    -- Supplier performance
    po.UnitCost,
    po.TotalCost,

    -- Lead time
    CASE
        WHEN po.ActualDeliveryDate IS NULL THEN NULL
        ELSE DATEDIFF(
            DAY,
            po.OrderDate,
            po.ActualDeliveryDate
        )
    END AS ActualLeadTimeDays,

    -- Expected lead time
    CASE
        WHEN po.ExpectedDeliveryDate IS NULL THEN NULL
        ELSE DATEDIFF(
            DAY,
            po.OrderDate,
            po.ExpectedDeliveryDate
        )
    END AS ExpectedLeadTimeDays,

    -- Delay
    po.DelayDays,

    -- On-time delivery flag
    CASE
        WHEN po.ActualDeliveryDate IS NOT NULL
             AND po.ActualDeliveryDate <= po.ExpectedDeliveryDate
        THEN 1
        ELSE 0
    END AS OnTimeFlag,

    -- Fill rate
    CASE
        WHEN po.QuantityOrdered = 0 THEN 0
        ELSE
            CAST(po.QuantityReceived AS DECIMAL(18,4))
            / po.QuantityOrdered
    END AS FillRate,

    -- Shortage rate
    CASE
        WHEN po.QuantityOrdered = 0 THEN 0
        ELSE
            CAST(
                po.QuantityOrdered - po.QuantityReceived
                AS DECIMAL(18,4)
            )
            / po.QuantityOrdered
    END AS ShortageRate,

    -- Supplier master metrics
    s.OnTimeDeliveryRate,
    s.DefectRatePct,
    s.BaseLeadTimeDays,
    s.PaymentTerms,

    -- Status
    po.Status

FROM fact_purchase_orders po

INNER JOIN dim_suppliers s
    ON po.SupplierID = s.SupplierID

INNER JOIN dim_products p
    ON po.ProductID = p.ProductID

INNER JOIN dim_warehouses w
    ON po.WarehouseID = w.WarehouseID;
GO