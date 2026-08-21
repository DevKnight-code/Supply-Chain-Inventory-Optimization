CREATE OR ALTER VIEW vw_supplier_summary
AS
SELECT
    s.SupplierID,
    s.SupplierName,
    s.Region,
    s.ReliabilityTier,

    COUNT(po.PO_ID) AS PurchaseOrderCount,

    COALESCE(SUM(po.TotalCost), 0) AS TotalPurchaseValue,

    COALESCE(SUM(po.QuantityOrdered), 0) AS TotalQuantityOrdered,

    COALESCE(SUM(po.QuantityReceived), 0) AS TotalQuantityReceived,

    CASE
        WHEN COUNT(po.PO_ID) = 0 THEN NULL
        ELSE
            SUM(
                CASE
                    WHEN po.ActualDeliveryDate IS NOT NULL
                     AND po.ExpectedDeliveryDate IS NOT NULL
                     AND po.ActualDeliveryDate <= po.ExpectedDeliveryDate
                    THEN 1
                    ELSE 0
                END
            ) * 100.0 / COUNT(po.PO_ID)
    END AS OnTimeDeliveryPercent

FROM dim_suppliers s

LEFT JOIN fact_purchase_orders po
    ON s.SupplierID = po.SupplierID

GROUP BY
    s.SupplierID,
    s.SupplierName,
    s.Region,
    s.ReliabilityTier;
GO

