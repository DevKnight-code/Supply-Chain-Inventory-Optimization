USE SupplyChainAnalytics;
GO

CREATE OR ALTER VIEW vw_product_analysis
AS
SELECT
    p.ProductID,
    p.ProductName,
    p.Category,
    p.SubCategory,

    -- Supplier
    p.SupplierID,
    s.SupplierName,

    -- Product economics
    p.UnitCost,
    p.UnitPrice,

    -- Margin per unit
    p.UnitPrice - p.UnitCost AS GrossMarginPerUnit,

    -- Margin %
    CASE
        WHEN p.UnitPrice = 0 THEN 0
        ELSE
            (
                (p.UnitPrice - p.UnitCost)
                / p.UnitPrice
            ) * 100
    END AS MarginPercent,

    -- Product characteristics
    p.Perishable,

    -- Demand characteristics
    p.AvgDailyDemand_Est,
    p.DemandVariability_CV,

    -- Estimated annual demand
    p.AvgDailyDemand_Est * 365 AS EstimatedAnnualDemand,

    -- Estimated annual consumption value
    p.AvgDailyDemand_Est
        * 365
        * p.UnitCost AS EstimatedAnnualCOGS,

    -- Estimated annual revenue
    p.AvgDailyDemand_Est
        * 365
        * p.UnitPrice AS EstimatedAnnualRevenue,

    -- Estimated annual gross profit
    p.AvgDailyDemand_Est
        * 365
        * (p.UnitPrice - p.UnitCost)
        AS EstimatedAnnualGrossProfit

FROM dim_products p

LEFT JOIN dim_suppliers s
    ON p.SupplierID = s.SupplierID;
GO

