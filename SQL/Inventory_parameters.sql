CREATE TABLE dim_inventory_parameters
(
    ParameterID INT PRIMARY KEY,
    ServiceLevel DECIMAL(5,4),
    ZScore DECIMAL(6,4),
    OrderingCost DECIMAL(18,2),
    HoldingCostPercent DECIMAL(6,4),
    ExcessDaysThreshold INT
);
GO
INSERT INTO dim_inventory_parameters
(
    ParameterID,
    ServiceLevel,
    ZScore,
    OrderingCost,
    HoldingCostPercent,
    ExcessDaysThreshold
)
VALUES
(
    1,
    0.95,
    1.645,
    500.00,
    0.20,
    90
);
GO

SELECT * FROM dim_inventory_parameters